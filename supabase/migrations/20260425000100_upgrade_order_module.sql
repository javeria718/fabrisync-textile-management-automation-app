-- FabriSync database upgrade for the dynamic product-based Order Module.
-- Safe migration style:
-- - Adds only nullable columns or columns with safe defaults.
-- - Does not drop, rename, or remove existing tables/columns.
-- - Preserves the current automatic workflow:
--   ordersmain INSERT -> insert_first_department()
--   department_orders UPDATE to completed -> move_to_next_department()
-- - Keeps department names delegated to department_sequence. Packaging is stored
--   as PACKAGING in newer migrations.

begin;

-- ---------------------------------------------------------------------------
-- 1) Extend ordersmain with product, delivery, priority, and summary fields.
-- ---------------------------------------------------------------------------

alter table public.ordersmain
  add column if not exists product_category text,
  add column if not exists product_type text,
  add column if not exists product_specifications jsonb default '{}'::jsonb,
  add column if not exists required_delivery_date date,
  add column if not exists quality_grade text,
  add column if not exists priority text default 'Normal',
  add column if not exists special_instructions text,
  add column if not exists custom_packaging boolean default false,
  add column if not exists branding_required boolean default false,
  add column if not exists estimated_production_hours numeric,
  add column if not exists estimated_production_days numeric;

comment on column public.ordersmain.product_category is
  'New order module product category, e.g. Bedsheet, Abaya, Curtain.';
comment on column public.ordersmain.product_type is
  'New order module product type selected dynamically from product_category.';
comment on column public.ordersmain.product_specifications is
  'Product-specific order details stored as JSONB for category-specific fields.';
comment on column public.ordersmain.required_delivery_date is
  'Customer/admin required delivery date for production planning.';
comment on column public.ordersmain.quality_grade is
  'Order quality grade, e.g. Economy, Standard, Premium.';
comment on column public.ordersmain.priority is
  'Order priority such as Normal or Rush. Default keeps old inserts safe.';
comment on column public.ordersmain.estimated_production_hours is
  'New module calculated production hours. Existing estimated_total_time is preserved.';
comment on column public.ordersmain.estimated_production_days is
  'New module calculated production days.';

create index if not exists idx_ordersmain_product_category
  on public.ordersmain (product_category);

create index if not exists idx_ordersmain_product_type
  on public.ordersmain (product_type);

create index if not exists idx_ordersmain_required_delivery_date
  on public.ordersmain (required_delivery_date);

create index if not exists idx_ordersmain_priority
  on public.ordersmain (priority);

create index if not exists idx_ordersmain_status
  on public.ordersmain (status);

-- ---------------------------------------------------------------------------
-- 2) Persist detailed cost breakdown separately from ordersmain.
-- ---------------------------------------------------------------------------

create table if not exists public.order_cost_breakdown (
  id uuid primary key default gen_random_uuid(),
  order_id text not null,
  material_cost_per_unit numeric default 0,
  labor_cost_per_unit numeric default 0,
  processing_cost numeric default 0,
  additional_charges numeric default 0,
  material_total_cost numeric default 0,
  labor_total_cost numeric default 0,
  processing_total_cost numeric default 0,
  additional_total_cost numeric default 0,
  rush_charges numeric default 0,
  estimated_total_cost numeric default 0,
  created_at timestamp without time zone default now(),
  updated_at timestamp without time zone default now()
);

comment on table public.order_cost_breakdown is
  'Detailed cost inputs and calculated totals for the new dynamic order module.';
comment on column public.order_cost_breakdown.order_id is
  'References ordersmain.order_id by convention. No FK is added because existing ordersmain.order_id is exported as plain text, not a declared primary key.';

create index if not exists idx_order_cost_breakdown_order_id
  on public.order_cost_breakdown (order_id);

-- Keep updated_at current for the new table. This does not affect old workflow tables.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $function$
begin
  new.updated_at := now();
  return new;
end;
$function$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'trg_order_cost_breakdown_set_updated_at'
      and tgrelid = 'public.order_cost_breakdown'::regclass
  ) then
    create trigger trg_order_cost_breakdown_set_updated_at
    before update on public.order_cost_breakdown
    for each row
    execute function public.set_updated_at();
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 3) Extend department_orders with production schedule fields.
-- ---------------------------------------------------------------------------

alter table public.department_orders
  add column if not exists sequence_number integer,
  add column if not exists planned_start_date date,
  add column if not exists planned_end_date date,
  add column if not exists actual_start_date date,
  add column if not exists actual_end_date date,
  add column if not exists delay_reason text;

comment on column public.department_orders.sequence_number is
  'Workflow sequence copied from department_sequence.step when available.';
comment on column public.department_orders.planned_start_date is
  'Planned department start date for the production schedule.';
comment on column public.department_orders.planned_end_date is
  'Planned department end date for the production schedule.';
comment on column public.department_orders.actual_start_date is
  'Actual department start date. Existing date_in remains preserved for old Flutter.';
comment on column public.department_orders.actual_end_date is
  'Actual department end date. Existing date_out remains preserved for old Flutter.';
comment on column public.department_orders.delay_reason is
  'Optional reason entered when department work is delayed.';

create index if not exists idx_department_orders_order_id
  on public.department_orders (order_id);

create index if not exists idx_department_orders_department_status
  on public.department_orders (department, status);

create index if not exists idx_department_orders_sequence_number
  on public.department_orders (sequence_number);

create index if not exists idx_department_orders_planned_dates
  on public.department_orders (planned_start_date, planned_end_date);

-- ---------------------------------------------------------------------------
-- 4) Preserve and harden workflow functions.
-- ---------------------------------------------------------------------------
-- insert_first_department:
-- - Still creates the first department row after normal order creation.
-- - Skips future draft orders so "Save as Draft" does not start production.
-- - Copies sequence and schedule fields when possible.
-- - Falls back to master_time_config exactly like the current function.

create or replace function public.insert_first_department()
returns trigger
language plpgsql
as $function$
declare
  first_dept text;
  first_step integer;
  expected_hours numeric;
  pk_now timestamp;
begin
  pk_now := timezone('Asia/Karachi', now());

  -- Draft orders are saved but should not enter the production workflow yet.
  if lower(coalesce(new.status, 'pending')) = 'draft' then
    return new;
  end if;

  select step, department
    into first_step, first_dept
  from public.department_sequence
  where step = 1;

  if first_dept is null then
    return new;
  end if;

  -- Prefer per-order department hours from ordersmain.estimated_dept_hours when
  -- the new Flutter module writes them; otherwise keep the old config fallback.
  expected_hours := nullif(new.estimated_dept_hours ->> first_dept, '')::numeric;

  if expected_hours is null then
    select estimated_hours
      into expected_hours
    from public.master_time_config
    where department = first_dept;
  end if;

  insert into public.department_orders (
    order_id,
    department,
    expected_hours,
    status,
    sequence_number,
    date_in,
    time_in,
    actual_start_date,
    planned_start_date,
    planned_end_date
  ) values (
    new.order_id,
    first_dept,
    coalesce(expected_hours, 0),
    'inprogress',
    first_step,
    pk_now::date,
    pk_now::time,
    pk_now::date,
    pk_now::date,
    case
      when coalesce(expected_hours, 0) <= 0 then pk_now::date
      else (pk_now::date + greatest(ceil(coalesce(expected_hours, 0) / 8.0)::integer - 1, 0))
    end
  );

  update public.ordersmain
  set current_department = first_dept
  where order_id = new.order_id;

  return new;
end;
$function$;

-- move_to_next_department:
-- - Still moves completed department rows to the next configured department.
-- - Runs only when status transitions to completed. This avoids duplicate next
--   department rows when the trigger updates date_out/time_out on the same row.
-- - Keeps packaging department naming delegated to existing department_sequence.

create or replace function public.move_to_next_department()
returns trigger
language plpgsql
as $function$
declare
  current_seq integer;
  next_seq integer;
  next_dept text;
  expected_hours numeric;
  pk_now timestamp;
begin
  pk_now := timezone('Asia/Karachi', now());

  if new.status = 'completed'
     and old.status is distinct from new.status then

    select step
      into current_seq
    from public.department_sequence
    where department = new.department;

    select step, department
      into next_seq, next_dept
    from public.department_sequence
    where step = current_seq + 1;

    if next_dept is null then
      update public.ordersmain
      set status = 'completed'
      where order_id = new.order_id;
    else
      -- Prefer per-order department hours when the new Flutter module writes
      -- ordersmain.estimated_dept_hours; otherwise keep the old config fallback.
      select nullif(o.estimated_dept_hours ->> next_dept, '')::numeric
        into expected_hours
      from public.ordersmain o
      where o.order_id = new.order_id;

      if expected_hours is null then
        select estimated_hours
        into expected_hours
        from public.master_time_config
        where department = next_dept;
      end if;

      insert into public.department_orders (
        order_id,
        department,
        expected_hours,
        status,
        date_in,
        time_in,
        sequence_number,
        actual_start_date,
        planned_start_date,
        planned_end_date
      ) values (
        new.order_id,
        next_dept,
        coalesce(expected_hours, 0),
        'inprogress',
        pk_now::date,
        pk_now::time,
        next_seq,
        pk_now::date,
        pk_now::date,
        case
          when coalesce(expected_hours, 0) <= 0 then pk_now::date
          else (pk_now::date + greatest(ceil(coalesce(expected_hours, 0) / 8.0)::integer - 1, 0))
        end
      );

      update public.ordersmain
      set current_department = next_dept
      where order_id = new.order_id;
    end if;

    update public.department_orders
    set date_out = coalesce(new.date_out, pk_now::date),
        time_out = coalesce(new.time_out, pk_now::time),
        actual_end_date = coalesce(new.actual_end_date, new.date_out, pk_now::date)
    where id = new.id;
  end if;

  return new;
end;
$function$;

-- Existing triggers are preserved by name:
-- - ordersmain.trg_first_department -> insert_first_department()
-- - department_orders.trg_next_department -> move_to_next_department()
-- - profiles.trg_delete_auth_on_profile_delete -> delete_auth_user_on_profile_delete()

-- ---------------------------------------------------------------------------
-- 5) Extend admin view without removing existing columns.
-- ---------------------------------------------------------------------------

create or replace view public.v_department_orders_full as
select
  d.id,
  d.order_id,
  d.department,
  d.date_in,
  d.time_in,
  d.expected_hours,
  d.date_out,
  d.time_out,
  d.status,
  o.quantity,
  p.full_name as manager_name,
  d.sequence_number,
  d.planned_start_date,
  d.planned_end_date,
  d.actual_start_date,
  d.actual_end_date,
  d.delay_reason,
  o.product_category,
  o.product_type,
  o.product_specifications,
  o.required_delivery_date,
  o.quality_grade,
  o.priority,
  o.special_instructions,
  o.custom_packaging,
  o.branding_required,
  o.estimated_production_hours,
  o.estimated_production_days,
  o.estimated_total_time,
  o.estimated_total_cost
from public.department_orders d
left join public.ordersmain o
  on o.order_id = d.order_id
left join public.profiles p
  on upper(p.department) = d.department
 and lower(p.role) = 'manager';

comment on view public.v_department_orders_full is
  'Department orders joined to order quantity and manager. Existing columns are preserved first; new order/schedule fields are appended for the upgraded order module.';

-- Ask Supabase/PostgREST to refresh its schema cache so newly added columns
-- such as ordersmain.custom_packaging are visible to API requests promptly.
notify pgrst, 'reload schema';

commit;
