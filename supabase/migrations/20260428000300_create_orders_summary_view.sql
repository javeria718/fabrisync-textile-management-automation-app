-- FabriSync admin order summary view.
--
-- One row per ordersmain order for the Admin Existing Orders table.
-- This view does not replace v_department_orders_full, which remains the
-- workflow/detail/manager source.

begin;

create or replace view public.v_orders_summary
with (security_invoker = on) as
select
  o.order_id,
  o.quantity,
  o.product_category,
  o.product_type,
  o.required_delivery_date,
  o.quality_grade,
  o.priority,
  o.current_department,
  o.status as order_status,
  o.created_at,
  o.created_at as updated_at,
  o.estimated_production_hours,
  o.estimated_production_days,
  o.estimated_total_time,
  o.estimated_total_cost,
  c.estimated_total_cost as cost_estimated_total,
  coalesce(p.completed_departments, 0)::integer as completed_departments,
  6::integer as total_departments,
  ((coalesce(p.completed_departments, 0)::numeric / 6.0) * 100.0) as progress_percent,
  coalesce(o.custom_packaging, false) as has_custom_packaging,
  coalesce(nullif(trim(o.special_instructions), ''), '') <> '' as has_special_instructions
from public.ordersmain o
left join lateral (
  select b.estimated_total_cost
  from public.order_cost_breakdown b
  where b.order_id = o.order_id
  order by b.created_at desc
  limit 1
) c on true
left join (
  select
    d.order_id,
    count(*) filter (where lower(coalesce(d.status, '')) = 'completed') as completed_departments
  from public.department_orders d
  group by d.order_id
) p on p.order_id = o.order_id;

notify pgrst, 'reload schema';

commit;
