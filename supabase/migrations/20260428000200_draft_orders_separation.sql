-- FabriSync draft order separation.
--
-- Draft orders are saved form data only. They must not enter the production
-- workflow until their ordersmain.status changes from draft to a real order
-- status such as pending.

begin;

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

  if exists (
    select 1
    from public.department_orders d
    where d.order_id = new.order_id
      and d.department = first_dept
  ) then
    return new;
  end if;

  expected_hours := nullif(new.estimated_dept_hours ->> first_dept, '')::numeric;

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
      else pk_now::date + greatest(ceil(coalesce(expected_hours, 0) / 8.0)::integer - 1, 0)
    end
  );

  update public.ordersmain
  set current_department = first_dept
  where order_id = new.order_id;

  return new;
end;
$function$;

create or replace function public.start_department_workflow_for_order()
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

  if lower(coalesce(old.status, '')) = 'draft'
     and lower(coalesce(new.status, '')) <> 'draft'
     and not exists (
       select 1
       from public.department_orders d
       where d.order_id = new.order_id
     ) then

    select step, department
      into first_step, first_dept
    from public.department_sequence
    where step = 1;

    if first_dept is null then
      return new;
    end if;

    expected_hours := nullif(new.estimated_dept_hours ->> first_dept, '')::numeric;

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
        else pk_now::date + greatest(ceil(coalesce(expected_hours, 0) / 8.0)::integer - 1, 0)
      end
    );

    update public.ordersmain
    set current_department = first_dept
    where order_id = new.order_id;
  end if;

  return new;
end;
$function$;

drop trigger if exists trg_start_workflow_from_draft on public.ordersmain;

create trigger trg_start_workflow_from_draft
after update of status on public.ordersmain
for each row
execute function public.start_department_workflow_for_order();

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
  parent_status text;
begin
  pk_now := timezone('Asia/Karachi', now());

  select lower(coalesce(o.status, ''))
    into parent_status
  from public.ordersmain o
  where o.order_id = new.order_id;

  if parent_status = 'draft' then
    return new;
  end if;

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
      select nullif(o.estimated_dept_hours ->> next_dept, '')::numeric
        into expected_hours
      from public.ordersmain o
      where o.order_id = new.order_id;

      if not exists (
        select 1
        from public.department_orders d
        where d.order_id = new.order_id
          and d.department = next_dept
      ) then
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
            else pk_now::date + greatest(ceil(coalesce(expected_hours, 0) / 8.0)::integer - 1, 0)
          end
        );
      end if;

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

delete from public.department_orders d
using public.ordersmain o
where o.order_id = d.order_id
  and lower(coalesce(o.status, '')) = 'draft';

create or replace view public.v_department_orders_full
with (security_invoker = on) as
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
  o.estimated_total_cost,
  o.status as order_status
from public.department_orders d
left join public.ordersmain o
  on o.order_id = d.order_id
left join public.profiles p
  on upper(p.department) = d.department
 and lower(p.role) = 'manager';

notify pgrst, 'reload schema';

commit;
