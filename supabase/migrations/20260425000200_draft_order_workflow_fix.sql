-- FabriSync draft workflow activation fix.
-- This keeps draft orders out of manager queues and starts the existing
-- department workflow only when a draft becomes an active/pending order.

begin;

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
  end if;

  return new;
end;
$function$;

do $$
begin
  if not exists (
    select 1
    from pg_trigger
    where tgname = 'trg_start_workflow_from_draft'
      and tgrelid = 'public.ordersmain'::regclass
  ) then
    create trigger trg_start_workflow_from_draft
    after update of status on public.ordersmain
    for each row
    execute function public.start_department_workflow_for_order();
  end if;
end $$;

commit;
