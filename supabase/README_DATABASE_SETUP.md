# FabriSync Database Setup

This folder contains manual Supabase database upgrade SQL for the FabriSync
Order Module.

## 1. Why This Migration Is Needed

The current database supports a simple order flow:

- Flutter inserts a row into `ordersmain`.
- The `trg_first_department` trigger calls `insert_first_department()`.
- Supabase creates the first `department_orders` row.
- Managers complete department rows.
- The `trg_next_department` trigger calls `move_to_next_department()`.
- Supabase creates the next department row until the order is completed.

The upgraded Order Module needs product-based order creation, dynamic product
specifications, delivery dates, quality grade, priority, detailed cost
breakdown, and department production schedule fields.

The migration is additive and backward compatible. It does not drop old tables,
drop columns, rename columns, or require old orders to be rewritten.

## 2. Tables Changed

### `ordersmain`

The migration adds nullable or safely defaulted columns:

- `product_category`
- `product_type`
- `product_specifications`
- `required_delivery_date`
- `quality_grade`
- `priority`
- `special_instructions`
- `custom_packaging`
- `estimated_production_hours`
- `estimated_production_days`

Existing Flutter-required columns remain unchanged:

- `order_id`
- `quantity`
- `current_department`
- `status`
- `estimated_total_time`
- `estimated_total_cost`
- `created_at`
- `estimated_dept_hours`

### `department_orders`

The migration adds production schedule fields:

- `sequence_number`
- `planned_start_date`
- `planned_end_date`
- `actual_start_date`
- `actual_end_date`
- `delay_reason`

Existing workflow columns remain unchanged:

- `id`
- `order_id`
- `department`
- `date_in`
- `time_in`
- `expected_hours`
- `date_out`
- `time_out`
- `status`

## 3. New Table Created

### `order_cost_breakdown`

This table stores detailed cost inputs and calculated totals:

- `id`
- `order_id`
- `material_cost_per_unit`
- `labor_cost_per_unit`
- `processing_cost`
- `additional_charges`
- `material_total_cost`
- `labor_total_cost`
- `processing_total_cost`
- `additional_total_cost`
- `rush_charges`
- `estimated_total_cost`
- `created_at`
- `updated_at`

No foreign key is added because the exported schema shows `ordersmain.order_id`
as plain `text`, not as an exported primary key. The app should treat
`order_cost_breakdown.order_id` as a logical reference to `ordersmain.order_id`.

## 4. Triggers and Functions Preserved

The existing workflow triggers are preserved:

- `ordersmain.trg_first_department`
- `department_orders.trg_next_department`
- `profiles.trg_delete_auth_on_profile_delete`

The migration updates these workflow functions safely:

- `insert_first_department()`
- `move_to_next_department()`

The behavior remains the same for normal orders. The first department is still
created automatically after inserting into `ordersmain`, and completing a
department still moves the order to the next department.

The updates add safe support for:

- future draft orders, which should not start production immediately
- new schedule fields on automatically created department rows
- avoiding duplicate next-department rows when completion timestamps are updated

The database now uses `PACKAGING` as the canonical department value for
Packaging. Flutter should display it as `Packaging`.

## 5. Views

`v_department_orders_full` is replaced with a backward-compatible version.

The original columns remain first:

- `id`
- `order_id`
- `department`
- `date_in`
- `time_in`
- `expected_hours`
- `date_out`
- `time_out`
- `status`
- `quantity`
- `manager_name`

New schedule and product fields are appended after the existing columns.

`department_delay_view` is not changed.

## 6. How To Backup Before Applying

Before applying the migration:

1. Open the Supabase project dashboard.
2. Go to `Project Settings`.
3. Open `Database`.
4. Use the available backup/export option for your plan.
5. Also copy the current definitions of these objects from SQL Editor if needed:
   - `ordersmain`
   - `department_orders`
   - `profiles`
   - `v_department_orders_full`
   - `insert_first_department()`
   - `move_to_next_department()`

For an extra manual backup, run read-only `select` exports for important tables
from the Supabase Table Editor or SQL Editor before applying the migration.

## 7. How To Apply Manually In Supabase Dashboard

1. Open Supabase Dashboard.
2. Select the FabriSync project.
3. Open `SQL Editor`.
4. Open `supabase/migrations/20260425_upgrade_order_module.sql` from this repo.
5. Paste the full SQL into the SQL Editor.
6. Review the SQL before running it.
7. Click `Run`.
8. Confirm that the SQL completes without errors.

Do not run this from Flutter. Do not execute it automatically from the app.

## 8. How To Test After Applying

Run these checks in Supabase SQL Editor.

### Check New Columns

```sql
select
  product_category,
  product_type,
  product_specifications,
  required_delivery_date,
  quality_grade,
  priority,
  custom_packaging,
  estimated_production_hours,
  estimated_production_days
from public.ordersmain
limit 1;
```

```sql
select
  sequence_number,
  planned_start_date,
  planned_end_date,
  actual_start_date,
  actual_end_date,
  delay_reason
from public.department_orders
limit 1;
```

### Check Cost Table

```sql
select *
from public.order_cost_breakdown
limit 1;
```

### Check View Compatibility

```sql
select
  id,
  order_id,
  department,
  date_in,
  time_in,
  expected_hours,
  date_out,
  time_out,
  status,
  quantity,
  manager_name
from public.v_department_orders_full
limit 5;
```

### Check Workflow Trigger Still Works

1. Create a test order from the existing Flutter order flow.
2. Confirm a first `department_orders` row is created automatically.
3. Confirm the first department is still the configured `step = 1` department.
4. Mark the active department row as `completed` from the manager panel.
5. Confirm exactly one next department row is created.
6. Continue until the final department.
7. Confirm `ordersmain.status` becomes `completed` after the final department.

### Check Draft Behavior Later

When Flutter adds Save as Draft:

1. Insert or save an order with `status = 'draft'`.
2. Confirm no `department_orders` row is created.
3. When converting draft to production, Flutter or a future function should set
   the order status to a production-starting value and explicitly start the
   workflow.

## 9. RLS Notes

This migration does not create or change RLS policies.

After applying it, review Supabase policies for:

- `ordersmain`
- `department_orders`
- `order_cost_breakdown`
- `v_department_orders_full`

If RLS is enabled, Flutter will need insert/select/update permissions for the
new columns and the new `order_cost_breakdown` table.

## 10. Calculation Cleanup Notes

FabriSync now uses `lib/services/order_calculation_service.dart` as the only
source of truth for order estimates. The Flutter order flow calculates product
time, department split, rush priority, and full cost breakdown once, then stores
the result in:

- `ordersmain`
- `order_cost_breakdown`
- `department_orders`

The final cleanup migration
`supabase/migrations/20260428000100_remove_legacy_calculation_config.sql`
removes the legacy calculation tables:

- `master_time_config`
- `master_cost_config`

These tables are removed because old orders were deleted and the app no longer
uses legacy fallback formulas. Admin dashboard, manager dashboard, and order
details now read stored calculated values only.

Apply migrations with:

```bash
npx supabase db push
```

If using the Supabase Dashboard SQL Editor manually, run the migration files in
timestamp order and review each SQL file before clicking `Run`.
