-- FabriSync Employee Head item-level production tracking.
--
-- This migration adds the smallest database surface needed for item/piece
-- tracking by Employee Heads. It intentionally does not auto-generate item
-- rows and does not rewrite the existing ordersmain -> department_orders
-- workflow triggers.

begin;

-- ---------------------------------------------------------------------------
-- 1) Profile role/department rules for admin, manager, and employee_head.
-- ---------------------------------------------------------------------------

-- Normalize safe legacy variants before adding future-facing checks. This keeps
-- display strings such as "Quality Control" from becoming a migration-time
-- surprise, while preserving unknown values for manual cleanup.
update public.profiles
set role = case
  when regexp_replace(lower(trim(role)), '[[:space:]-]+', '_', 'g')
       in ('admin', 'manager', 'employee_head')
    then regexp_replace(lower(trim(role)), '[[:space:]-]+', '_', 'g')
  else role
end
where role is not null;

update public.profiles
set department = case
  when nullif(trim(department), '') is null then null
  when upper(regexp_replace(trim(department), '[[:space:]-]+', '_', 'g')) = 'PACKING'
    then 'PACKAGING'
  else upper(regexp_replace(trim(department), '[[:space:]-]+', '_', 'g'))
end
where department is not null;

update public.department_sequence
set department = 'PACKAGING'
where department = 'PACKING';

update public.department_orders
set department = 'PACKAGING'
where department = 'PACKING';

update public.ordersmain
set current_department = 'PACKAGING'
where current_department = 'PACKING';

update public.profiles
set department = null
where role = 'admin'
  and department is not null;

-- Keep role values explicit for new/updated profile rows. NOT VALID avoids
-- failing the migration if old data needs cleanup; PostgreSQL still enforces
-- the constraint for future inserts/updates.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_role_allowed'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_role_allowed
      check (role in ('admin', 'manager', 'employee_head'))
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_department_canonical'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_department_canonical
      check (
        department is null
        or department in (
          'CUTTING',
          'STITCHING',
          'THREADING',
          'QUALITY_CONTROL',
          'PACKAGING',
          'INSPECTION'
        )
      )
      not valid;
  end if;
end $$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'profiles_role_department_rule'
      and conrelid = 'public.profiles'::regclass
  ) then
    alter table public.profiles
      add constraint profiles_role_department_rule
      check (
        (role = 'admin' and department is null)
        or (role in ('manager', 'employee_head') and department is not null)
      )
      not valid;
  end if;
end $$;

-- Use the existing inspected index names so admin/manager uniqueness is not
-- duplicated when those indexes are already present.
do $$
begin
  if to_regclass('public.one_admin_only') is null
     and to_regclass('public.uniq_single_admin') is null then
    execute '
      create unique index uniq_single_admin
      on public.profiles (role)
      where role = ''admin''
    ';
  end if;
end $$;

do $$
begin
  if to_regclass('public.uniq_one_manager_per_department') is null then
    execute '
      create unique index uniq_one_manager_per_department
      on public.profiles (department)
      where role = ''manager''
    ';
  end if;
end $$;

create unique index if not exists uniq_one_employee_head_per_department
  on public.profiles (department)
  where role = 'employee_head';

-- Minimal profile trigger update: allow employee_head and keep DB departments
-- canonical. This is not part of the order workflow.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
declare
  profile_role text;
  profile_department text;
begin
  profile_role := regexp_replace(
    lower(trim(coalesce(new.raw_user_meta_data->>'role', 'manager'))),
    '[[:space:]-]+',
    '_',
    'g'
  );

  if profile_role not in ('admin', 'manager', 'employee_head') then
    profile_role := 'manager';
  end if;

  profile_department := null;

  if profile_role in ('manager', 'employee_head')
     and coalesce(new.raw_user_meta_data->>'department', '') <> '' then
    profile_department := upper(regexp_replace(
      trim(new.raw_user_meta_data->>'department'),
      '[[:space:]-]+',
      '_',
      'g'
    ));

    -- Convert old DB value to the canonical department key.
    if profile_department = 'PACKING' then
      profile_department := 'PACKAGING';
    end if;
  end if;

  insert into public.profiles (
    id,
    full_name,
    email,
    phone_number,
    role,
    department
  )
  values (
    new.id,
    coalesce(nullif(new.raw_user_meta_data->>'full_name', ''), 'Unknown'),
    coalesce(nullif(new.email, ''), 'no-email'),
    coalesce(nullif(new.raw_user_meta_data->>'phone_number', ''), 'N/A'),
    profile_role,
    profile_department
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    email = excluded.email,
    phone_number = excluded.phone_number,
    role = excluded.role,
    department = excluded.department;

  return new;
end;
$function$;

-- ---------------------------------------------------------------------------
-- 2) One row per physical item/piece in an order.
-- ---------------------------------------------------------------------------

create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id text not null
    references public.ordersmain(order_id) on delete cascade,
  item_no integer not null,
  item_code text not null,
  product_prefix text not null,
  created_at timestamp with time zone not null default now(),
  constraint order_items_item_no_positive check (item_no > 0),
  constraint order_items_item_code_not_empty check (length(trim(item_code)) > 0),
  constraint order_items_product_prefix_not_empty check (length(trim(product_prefix)) > 0),
  constraint order_items_item_code_key unique (item_code),
  constraint order_items_order_id_item_no_key unique (order_id, item_no)
);

comment on table public.order_items is
  'Physical order items/pieces. Flutter will generate rows later from ordersmain.quantity; no auto-generation trigger is added in this migration.';

comment on column public.order_items.item_code is
  'Unique human-readable tracking code, for example FS-1021-ABY-001.';

-- ---------------------------------------------------------------------------
-- 3) Current item status per department.
-- ---------------------------------------------------------------------------

create table if not exists public.item_department_progress (
  id uuid primary key default gen_random_uuid(),
  item_id uuid not null
    references public.order_items(id) on delete cascade,
  order_id text not null
    references public.ordersmain(order_id) on delete cascade,
  department text not null,
  sequence_number integer not null,
  department_order_id uuid
    references public.department_orders(id) on delete set null,
  status text not null default 'pending',
  started_at timestamp with time zone,
  completed_at timestamp with time zone,
  completed_by uuid
    references public.profiles(id) on delete set null,
  delay_reason text,
  remarks text,
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  constraint item_department_progress_item_department_key unique (item_id, department),
  constraint item_department_progress_department_check check (
    department in (
      'CUTTING',
      'STITCHING',
      'THREADING',
      'QUALITY_CONTROL',
      'PACKAGING',
      'INSPECTION'
    )
  ),
  constraint item_department_progress_status_check check (
    status in ('pending', 'inprogress', 'completed')
  ),
  constraint item_department_progress_sequence_positive check (sequence_number > 0)
);

comment on table public.item_department_progress is
  'Per-item progress for each production department. TODO RLS: admin reads all; manager reads own department only; employee_head reads/updates own department only.';

comment on column public.item_department_progress.delay_reason is
  'Reason captured when a department/item is completed late.';

-- ---------------------------------------------------------------------------
-- 4) Append-only timeline/audit history.
-- ---------------------------------------------------------------------------

create table if not exists public.item_progress_logs (
  id uuid primary key default gen_random_uuid(),
  item_id uuid
    references public.order_items(id) on delete cascade,
  progress_id uuid
    references public.item_department_progress(id) on delete set null,
  order_id text not null
    references public.ordersmain(order_id) on delete cascade,
  department text not null,
  event_type text not null,
  from_status text,
  to_status text,
  actor_profile_id uuid
    references public.profiles(id) on delete set null,
  remarks text,
  delay_reason text,
  created_at timestamp with time zone not null default now(),
  constraint item_progress_logs_department_check check (
    department in (
      'CUTTING',
      'STITCHING',
      'THREADING',
      'QUALITY_CONTROL',
      'PACKAGING',
      'INSPECTION'
    )
  ),
  constraint item_progress_logs_event_type_check check (
    event_type in (
      'item_created',
      'item_started',
      'item_completed',
      'department_completed',
      'delay_recorded',
      'remark_added'
    )
  ),
  constraint item_progress_logs_from_status_check check (
    from_status is null or from_status in ('pending', 'inprogress', 'completed')
  ),
  constraint item_progress_logs_to_status_check check (
    to_status is null or to_status in ('pending', 'inprogress', 'completed')
  )
);

comment on table public.item_progress_logs is
  'Timeline/audit trail for item production progress. TODO RLS: logs should be append-only from the app; no update/delete policies should be granted.';

-- ---------------------------------------------------------------------------
-- 5) Query indexes.
-- ---------------------------------------------------------------------------

create index if not exists idx_order_items_order_id
  on public.order_items (order_id);

create index if not exists idx_order_items_item_code
  on public.order_items (item_code);

create index if not exists idx_item_department_progress_order_id
  on public.item_department_progress (order_id);

create index if not exists idx_item_department_progress_item_id
  on public.item_department_progress (item_id);

create index if not exists idx_item_department_progress_department
  on public.item_department_progress (department);

create index if not exists idx_item_department_progress_department_order_id
  on public.item_department_progress (department_order_id);

create index if not exists idx_item_department_progress_status
  on public.item_department_progress (status);

create index if not exists idx_item_progress_logs_order_id
  on public.item_progress_logs (order_id);

create index if not exists idx_item_progress_logs_item_id
  on public.item_progress_logs (item_id);

create index if not exists idx_item_progress_logs_progress_id
  on public.item_progress_logs (progress_id);

create index if not exists idx_item_progress_logs_department
  on public.item_progress_logs (department);

create index if not exists idx_item_progress_logs_created_at
  on public.item_progress_logs (created_at);

-- ---------------------------------------------------------------------------
-- 6) updated_at maintenance for item_department_progress only.
-- ---------------------------------------------------------------------------

drop trigger if exists trg_item_department_progress_set_updated_at
  on public.item_department_progress;

do $do$
begin
  if to_regprocedure('public.set_updated_at()') is not null then
    execute '
      create trigger trg_item_department_progress_set_updated_at
      before update on public.item_department_progress
      for each row
      execute function public.set_updated_at()
    ';
  else
    if to_regprocedure('public.set_item_department_progress_updated_at()') is null then
      execute $sql$
        create function public.set_item_department_progress_updated_at()
        returns trigger
        language plpgsql
        as $function$
        begin
          new.updated_at := now();
          return new;
        end;
        $function$;
      $sql$;
    end if;

    execute '
      create trigger trg_item_department_progress_set_updated_at
      before update on public.item_department_progress
      for each row
      execute function public.set_item_department_progress_updated_at()
    ';
  end if;
end
$do$;

-- ---------------------------------------------------------------------------
-- 7) RLS note.
-- ---------------------------------------------------------------------------
--
-- RLS is intentionally not enabled here because existing workflow tables are
-- broadly granted in the current schema and enabling RLS without complete app
-- policies may break the project. Later policies should enforce:
-- - admin can read all item/progress/log rows
-- - manager can read own department only and cannot update
-- - employee_head can read/update own department only
-- - item_progress_logs is insert-only from application users

notify pgrst, 'reload schema';

commit;
