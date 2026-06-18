-- FabriSync final calculation cleanup.
--
-- Old orders were removed and the active order flow now stores all calculated
-- department hours in ordersmain.estimated_dept_hours via OrderCalculationService.
-- Workflow functions must not query master_time_config or master_cost_config.

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

  expected_hours := nullif(new.estimated_dept_hours ->> first_dept, '')::numeric;

  if expected_hours is null then
    raise notice 'No stored expected hours found for order %, department %; using 0.', new.order_id, first_dept;
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
      else pk_now::date + greatest(ceil(coalesce(expected_hours, 0) / 8.0)::integer - 1, 0)
    end
  );

  update public.ordersmain
  set current_department = first_dept
  where order_id = new.order_id;

  return new;
end;
$function$;

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
      select nullif(o.estimated_dept_hours ->> next_dept, '')::numeric
        into expected_hours
      from public.ordersmain o
      where o.order_id = new.order_id;

      if expected_hours is null then
        raise notice 'No stored expected hours found for order %, department %; using 0.', new.order_id, next_dept;
      end if;

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

    if expected_hours is null then
      raise notice 'No stored expected hours found for order %, department %; using 0.', new.order_id, first_dept;
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

drop table if exists public.master_cost_config;
drop table if exists public.master_cost_config_archive;
drop table if exists public.master_time_config;

notify pgrst, 'reload schema';

commit;
