


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE OR REPLACE FUNCTION "public"."delete_auth_user_on_profile_delete"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
  delete from auth.users where id = old.id;
  return old;
end;
$$;


ALTER FUNCTION "public"."delete_auth_user_on_profile_delete"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
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
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."insert_first_department"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."insert_first_department"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."move_to_next_department"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."move_to_next_department"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
  new.updated_at := now();
  return new;
end;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."start_department_workflow_for_order"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."start_department_workflow_for_order"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_abaya_cost_config_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_abaya_cost_config_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_bedsheet_cost_config_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_bedsheet_cost_config_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_curtain_cost_config_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_curtain_cost_config_timestamp"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."abaya_cost_config" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "abaya_type" character varying(50) NOT NULL,
    "fabric_type" character varying(50) NOT NULL,
    "quality_grade" character varying(50) NOT NULL,
    "base_labor_hours" numeric(6,2) DEFAULT 1.20 NOT NULL,
    "fabric_rate" numeric(10,2) DEFAULT 850.0 NOT NULL,
    "labor_multiplier" numeric(5,2) DEFAULT 1.00 NOT NULL,
    "processing_rate" numeric(10,2) DEFAULT 250.0 NOT NULL,
    "embellishment_cost" numeric(10,2) DEFAULT 450.0 NOT NULL,
    "wastage_percent" numeric(5,2) DEFAULT 5.0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT "positive_base_labor_hours" CHECK (("base_labor_hours" >= (0)::numeric)),
    CONSTRAINT "positive_embellishment_cost" CHECK (("embellishment_cost" >= (0)::numeric)),
    CONSTRAINT "positive_fabric_rate" CHECK (("fabric_rate" > (0)::numeric)),
    CONSTRAINT "positive_labor_multiplier" CHECK (("labor_multiplier" > (0)::numeric)),
    CONSTRAINT "positive_processing_rate" CHECK (("processing_rate" >= (0)::numeric)),
    CONSTRAINT "valid_wastage" CHECK ((("wastage_percent" >= (0)::numeric) AND ("wastage_percent" <= (100)::numeric)))
);


ALTER TABLE "public"."abaya_cost_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."bedsheet_cost_config" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "bedsheet_type" character varying(50) NOT NULL,
    "fabric_type" character varying(50) NOT NULL,
    "bed_size" character varying(50) NOT NULL,
    "quality_grade" character varying(50) NOT NULL,
    "base_labor_hours" numeric(6,2) DEFAULT 0.80 NOT NULL,
    "material_rate" numeric(10,2) DEFAULT 650.00 NOT NULL,
    "labor_multiplier" numeric(5,2) DEFAULT 1.00 NOT NULL,
    "processing_rate" numeric(10,2) DEFAULT 180.00 NOT NULL,
    "printing_charge" numeric(10,2) DEFAULT 850.00 NOT NULL,
    "wastage_percent" numeric(5,2) DEFAULT 5.00 NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT "positive_base_labor_hours" CHECK (("base_labor_hours" >= (0)::numeric)),
    CONSTRAINT "positive_labor_multiplier" CHECK (("labor_multiplier" > (0)::numeric)),
    CONSTRAINT "positive_material_rate" CHECK (("material_rate" > (0)::numeric)),
    CONSTRAINT "positive_printing_charge" CHECK (("printing_charge" >= (0)::numeric)),
    CONSTRAINT "positive_processing_rate" CHECK (("processing_rate" >= (0)::numeric)),
    CONSTRAINT "valid_wastage" CHECK ((("wastage_percent" >= (0)::numeric) AND ("wastage_percent" <= (100)::numeric)))
);


ALTER TABLE "public"."bedsheet_cost_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."curtain_cost_config" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "curtain_type" character varying(50) NOT NULL,
    "fabric_type" character varying(50) NOT NULL,
    "header_style" character varying(50) NOT NULL,
    "material_rate" numeric(10,2) DEFAULT 450.0 NOT NULL,
    "labor_multiplier" numeric(5,2) DEFAULT 1.0 NOT NULL,
    "complexity_multiplier" numeric(5,2) DEFAULT 1.0 NOT NULL,
    "base_labor_hours" numeric(6,2) DEFAULT 0.8 NOT NULL,
    "processing_cost" numeric(10,2) DEFAULT 200.0 NOT NULL,
    "wastage_percent" numeric(5,2) DEFAULT 5.0 NOT NULL,
    "created_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    "updated_at" timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT "positive_complexity" CHECK (("complexity_multiplier" > (0)::numeric)),
    CONSTRAINT "positive_labor_hours" CHECK (("base_labor_hours" >= (0)::numeric)),
    CONSTRAINT "positive_labor_multiplier" CHECK (("labor_multiplier" > (0)::numeric)),
    CONSTRAINT "positive_material_rate" CHECK (("material_rate" > (0)::numeric)),
    CONSTRAINT "positive_processing" CHECK (("processing_cost" >= (0)::numeric)),
    CONSTRAINT "valid_wastage" CHECK ((("wastage_percent" >= (0)::numeric) AND ("wastage_percent" <= (100)::numeric)))
);


ALTER TABLE "public"."curtain_cost_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."department_orders" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "text",
    "department" "text" NOT NULL,
    "date_in" "date" DEFAULT ("timezone"('Asia/Karachi'::"text", "now"()))::"date",
    "time_in" time without time zone DEFAULT ("timezone"('Asia/Karachi'::"text", "now"()))::time without time zone,
    "expected_hours" numeric NOT NULL,
    "date_out" "date",
    "time_out" time without time zone,
    "status" "text" DEFAULT 'inprogress'::"text",
    "sequence_number" integer,
    "planned_start_date" "date",
    "planned_end_date" "date",
    "actual_start_date" "date",
    "actual_end_date" "date",
    "delay_reason" "text",
    CONSTRAINT "department_orders_department_uppercase" CHECK (("department" = "upper"("department")))
);


ALTER TABLE "public"."department_orders" OWNER TO "postgres";


COMMENT ON COLUMN "public"."department_orders"."sequence_number" IS 'Workflow sequence copied from department_sequence.step when available.';



COMMENT ON COLUMN "public"."department_orders"."planned_start_date" IS 'Planned department start date for the production schedule.';



COMMENT ON COLUMN "public"."department_orders"."planned_end_date" IS 'Planned department end date for the production schedule.';



COMMENT ON COLUMN "public"."department_orders"."actual_start_date" IS 'Actual department start date. Existing date_in remains preserved for old Flutter.';



COMMENT ON COLUMN "public"."department_orders"."actual_end_date" IS 'Actual department end date. Existing date_out remains preserved for old Flutter.';



COMMENT ON COLUMN "public"."department_orders"."delay_reason" IS 'Optional reason entered when department work is delayed.';



CREATE OR REPLACE VIEW "public"."department_delay_view" AS
 SELECT "id",
    "order_id",
    "department",
    "date_in",
    "time_in",
    "expected_hours",
    "date_out",
    "time_out",
    "status"
   FROM "public"."department_orders";


ALTER VIEW "public"."department_delay_view" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."department_sequence" (
    "step" integer NOT NULL,
    "department" "text" NOT NULL,
    CONSTRAINT "department_sequence_uppercase" CHECK (("department" = "upper"("department")))
);


ALTER TABLE "public"."department_sequence" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."item_department_progress" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "item_id" "uuid" NOT NULL,
    "order_id" "text" NOT NULL,
    "department" "text" NOT NULL,
    "sequence_number" integer NOT NULL,
    "department_order_id" "uuid",
    "status" "text" DEFAULT 'pending'::"text" NOT NULL,
    "started_at" timestamp with time zone,
    "completed_at" timestamp with time zone,
    "completed_by" "uuid",
    "delay_reason" "text",
    "remarks" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "item_department_progress_department_check" CHECK (("department" = ANY (ARRAY['CUTTING'::"text", 'STITCHING'::"text", 'THREADING'::"text", 'QUALITY_CONTROL'::"text", 'PACKAGING'::"text", 'INSPECTION'::"text"]))),
    CONSTRAINT "item_department_progress_sequence_positive" CHECK (("sequence_number" > 0)),
    CONSTRAINT "item_department_progress_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'inprogress'::"text", 'completed'::"text"])))
);


ALTER TABLE "public"."item_department_progress" OWNER TO "postgres";


COMMENT ON TABLE "public"."item_department_progress" IS 'Per-item progress for each production department. TODO RLS: admin reads all; manager reads own department only; employee_head reads/updates own department only.';



COMMENT ON COLUMN "public"."item_department_progress"."delay_reason" IS 'Reason captured when a department/item is completed late.';



CREATE TABLE IF NOT EXISTS "public"."item_progress_logs" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "item_id" "uuid",
    "progress_id" "uuid",
    "order_id" "text" NOT NULL,
    "department" "text" NOT NULL,
    "event_type" "text" NOT NULL,
    "from_status" "text",
    "to_status" "text",
    "actor_profile_id" "uuid",
    "remarks" "text",
    "delay_reason" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "item_progress_logs_department_check" CHECK (("department" = ANY (ARRAY['CUTTING'::"text", 'STITCHING'::"text", 'THREADING'::"text", 'QUALITY_CONTROL'::"text", 'PACKAGING'::"text", 'INSPECTION'::"text"]))),
    CONSTRAINT "item_progress_logs_event_type_check" CHECK (("event_type" = ANY (ARRAY['item_created'::"text", 'item_started'::"text", 'item_completed'::"text", 'department_completed'::"text", 'delay_recorded'::"text", 'remark_added'::"text"]))),
    CONSTRAINT "item_progress_logs_from_status_check" CHECK ((("from_status" IS NULL) OR ("from_status" = ANY (ARRAY['pending'::"text", 'inprogress'::"text", 'completed'::"text"])))),
    CONSTRAINT "item_progress_logs_to_status_check" CHECK ((("to_status" IS NULL) OR ("to_status" = ANY (ARRAY['pending'::"text", 'inprogress'::"text", 'completed'::"text"]))))
);


ALTER TABLE "public"."item_progress_logs" OWNER TO "postgres";


COMMENT ON TABLE "public"."item_progress_logs" IS 'Timeline/audit trail for item production progress. TODO RLS: logs should be append-only from the app; no update/delete policies should be granted.';



CREATE TABLE IF NOT EXISTS "public"."order_cost_breakdown" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "text" NOT NULL,
    "material_cost_per_unit" numeric DEFAULT 0,
    "labor_cost_per_unit" numeric DEFAULT 0,
    "processing_cost" numeric DEFAULT 0,
    "additional_charges" numeric DEFAULT 0,
    "material_total_cost" numeric DEFAULT 0,
    "labor_total_cost" numeric DEFAULT 0,
    "processing_total_cost" numeric DEFAULT 0,
    "additional_total_cost" numeric DEFAULT 0,
    "rush_charges" numeric DEFAULT 0,
    "estimated_total_cost" numeric DEFAULT 0,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "updated_at" timestamp without time zone DEFAULT "now"()
);


ALTER TABLE "public"."order_cost_breakdown" OWNER TO "postgres";


COMMENT ON TABLE "public"."order_cost_breakdown" IS 'Detailed cost inputs and calculated totals for the new dynamic order module.';



COMMENT ON COLUMN "public"."order_cost_breakdown"."order_id" IS 'References ordersmain.order_id by convention. No FK is added because existing ordersmain.order_id is exported as plain text, not a declared primary key.';



CREATE TABLE IF NOT EXISTS "public"."order_items" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "order_id" "text" NOT NULL,
    "item_no" integer NOT NULL,
    "item_code" "text" NOT NULL,
    "product_prefix" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    CONSTRAINT "order_items_item_code_not_empty" CHECK (("length"(TRIM(BOTH FROM "item_code")) > 0)),
    CONSTRAINT "order_items_item_no_positive" CHECK (("item_no" > 0)),
    CONSTRAINT "order_items_product_prefix_not_empty" CHECK (("length"(TRIM(BOTH FROM "product_prefix")) > 0))
);


ALTER TABLE "public"."order_items" OWNER TO "postgres";


COMMENT ON TABLE "public"."order_items" IS 'Physical order items/pieces. Flutter will generate rows later from ordersmain.quantity; no auto-generation trigger is added in this migration.';



COMMENT ON COLUMN "public"."order_items"."item_code" IS 'Unique human-readable tracking code, for example FS-1021-ABY-001.';



CREATE TABLE IF NOT EXISTS "public"."ordersmain" (
    "order_id" "text" NOT NULL,
    "quantity" integer NOT NULL,
    "current_department" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text",
    "estimated_total_time" numeric,
    "estimated_total_cost" numeric,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "estimated_dept_hours" "jsonb",
    "product_category" "text",
    "product_type" "text",
    "product_specifications" "jsonb" DEFAULT '{}'::"jsonb",
    "required_delivery_date" "date",
    "quality_grade" "text",
    "priority" "text" DEFAULT 'Normal'::"text",
    "special_instructions" "text",
    "custom_packaging" boolean DEFAULT false,
    "branding_required" boolean DEFAULT false,
    "estimated_production_hours" numeric,
    "estimated_production_days" numeric,
    "draft_created_at" timestamp with time zone,
    "draft_expires_at" timestamp with time zone,
    "is_draft_expired" boolean DEFAULT false NOT NULL,
    CONSTRAINT "ordersmain_current_department_uppercase" CHECK (("current_department" = "upper"("current_department")))
);


ALTER TABLE "public"."ordersmain" OWNER TO "postgres";


COMMENT ON COLUMN "public"."ordersmain"."product_category" IS 'New order module product category, e.g. Bedsheet, Abaya, Curtain.';



COMMENT ON COLUMN "public"."ordersmain"."product_type" IS 'New order module product type selected dynamically from product_category.';



COMMENT ON COLUMN "public"."ordersmain"."product_specifications" IS 'Product-specific order details stored as JSONB for category-specific fields.';



COMMENT ON COLUMN "public"."ordersmain"."required_delivery_date" IS 'Customer/admin required delivery date for production planning.';



COMMENT ON COLUMN "public"."ordersmain"."quality_grade" IS 'Order quality grade, e.g. Economy, Standard, Premium.';



COMMENT ON COLUMN "public"."ordersmain"."priority" IS 'Order priority such as Normal or Rush. Default keeps old inserts safe.';



COMMENT ON COLUMN "public"."ordersmain"."estimated_production_hours" IS 'New module calculated production hours. Existing estimated_total_time is preserved.';



COMMENT ON COLUMN "public"."ordersmain"."estimated_production_days" IS 'New module calculated production days.';



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "full_name" "text" NOT NULL,
    "email" "text" NOT NULL,
    "phone_number" "text" NOT NULL,
    "role" "text" NOT NULL,
    "department" "text",
    CONSTRAINT "manager_department_required" CHECK ((("role" <> 'manager'::"text") OR ("department" IS NOT NULL))),
    CONSTRAINT "profiles_department_uppercase" CHECK ((("department" IS NULL) OR ("department" = "upper"("department"))))
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE OR REPLACE VIEW "public"."v_department_orders_full" WITH ("security_invoker"='on') AS
 SELECT "d"."id",
    "d"."order_id",
    "d"."department",
    "d"."date_in",
    "d"."time_in",
    "d"."expected_hours",
    "d"."date_out",
    "d"."time_out",
    "d"."status",
    "o"."quantity",
    "p"."full_name" AS "manager_name",
    "d"."sequence_number",
    "d"."planned_start_date",
    "d"."planned_end_date",
    "d"."actual_start_date",
    "d"."actual_end_date",
    "d"."delay_reason",
    "o"."product_category",
    "o"."product_type",
    "o"."product_specifications",
    "o"."required_delivery_date",
    "o"."quality_grade",
    "o"."priority",
    "o"."special_instructions",
    "o"."custom_packaging",
    "o"."branding_required",
    "o"."estimated_production_hours",
    "o"."estimated_production_days",
    "o"."estimated_total_time",
    "o"."estimated_total_cost",
    "o"."status" AS "order_status"
   FROM (("public"."department_orders" "d"
     LEFT JOIN "public"."ordersmain" "o" ON (("o"."order_id" = "d"."order_id")))
     LEFT JOIN "public"."profiles" "p" ON ((("upper"("p"."department") = "d"."department") AND ("lower"("p"."role") = 'manager'::"text"))));


ALTER VIEW "public"."v_department_orders_full" OWNER TO "postgres";


COMMENT ON VIEW "public"."v_department_orders_full" IS 'Department orders joined to order quantity and manager. Existing columns are preserved first; new order/schedule fields are appended for the upgraded order module.';



CREATE OR REPLACE VIEW "public"."v_orders_summary" WITH ("security_invoker"='on') AS
 SELECT "o"."order_id",
    "o"."quantity",
    "o"."product_category",
    "o"."product_type",
    "o"."required_delivery_date",
    "o"."quality_grade",
    "o"."priority",
    "o"."current_department",
    "o"."status" AS "order_status",
    "o"."created_at",
    "o"."created_at" AS "updated_at",
    "o"."estimated_production_hours",
    "o"."estimated_production_days",
    "o"."estimated_total_time",
    "o"."estimated_total_cost",
    "c"."estimated_total_cost" AS "cost_estimated_total",
    (COALESCE("p"."completed_departments", (0)::bigint))::integer AS "completed_departments",
    6 AS "total_departments",
    (((COALESCE("p"."completed_departments", (0)::bigint))::numeric / 6.0) * 100.0) AS "progress_percent",
    COALESCE("o"."custom_packaging", false) AS "has_custom_packaging",
    (COALESCE(NULLIF(TRIM(BOTH FROM "o"."special_instructions"), ''::"text"), ''::"text") <> ''::"text") AS "has_special_instructions"
   FROM (("public"."ordersmain" "o"
     LEFT JOIN LATERAL ( SELECT "b"."estimated_total_cost"
           FROM "public"."order_cost_breakdown" "b"
          WHERE ("b"."order_id" = "o"."order_id")
          ORDER BY "b"."created_at" DESC
         LIMIT 1) "c" ON (true))
     LEFT JOIN ( SELECT "d"."order_id",
            "count"(*) FILTER (WHERE ("lower"(COALESCE("d"."status", ''::"text")) = 'completed'::"text")) AS "completed_departments"
           FROM "public"."department_orders" "d"
          GROUP BY "d"."order_id") "p" ON (("p"."order_id" = "o"."order_id")));


ALTER VIEW "public"."v_orders_summary" OWNER TO "postgres";


ALTER TABLE ONLY "public"."abaya_cost_config"
    ADD CONSTRAINT "abaya_cost_config_abaya_type_fabric_type_quality_grade_key" UNIQUE ("abaya_type", "fabric_type", "quality_grade");



ALTER TABLE ONLY "public"."abaya_cost_config"
    ADD CONSTRAINT "abaya_cost_config_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bedsheet_cost_config"
    ADD CONSTRAINT "bedsheet_cost_config_bedsheet_type_fabric_type_bed_size_qua_key" UNIQUE ("bedsheet_type", "fabric_type", "bed_size", "quality_grade");



ALTER TABLE ONLY "public"."bedsheet_cost_config"
    ADD CONSTRAINT "bedsheet_cost_config_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."curtain_cost_config"
    ADD CONSTRAINT "curtain_cost_config_curtain_type_fabric_type_header_style_key" UNIQUE ("curtain_type", "fabric_type", "header_style");



ALTER TABLE ONLY "public"."curtain_cost_config"
    ADD CONSTRAINT "curtain_cost_config_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."department_orders"
    ADD CONSTRAINT "department_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."department_sequence"
    ADD CONSTRAINT "department_sequence_pkey" PRIMARY KEY ("step");



ALTER TABLE ONLY "public"."item_department_progress"
    ADD CONSTRAINT "item_department_progress_item_department_key" UNIQUE ("item_id", "department");



ALTER TABLE ONLY "public"."item_department_progress"
    ADD CONSTRAINT "item_department_progress_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."item_progress_logs"
    ADD CONSTRAINT "item_progress_logs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_cost_breakdown"
    ADD CONSTRAINT "order_cost_breakdown_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_item_code_key" UNIQUE ("item_code");



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_order_id_item_no_key" UNIQUE ("order_id", "item_no");



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."ordersmain"
    ADD CONSTRAINT "ordersmain_pkey" PRIMARY KEY ("order_id");



ALTER TABLE "public"."profiles"
    ADD CONSTRAINT "profiles_department_canonical" CHECK ((("department" IS NULL) OR ("department" = ANY (ARRAY['CUTTING'::"text", 'STITCHING'::"text", 'THREADING'::"text", 'QUALITY_CONTROL'::"text", 'PACKAGING'::"text", 'INSPECTION'::"text"])))) NOT VALID;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE "public"."profiles"
    ADD CONSTRAINT "profiles_role_allowed" CHECK (("role" = ANY (ARRAY['admin'::"text", 'manager'::"text", 'employee_head'::"text"]))) NOT VALID;



ALTER TABLE "public"."profiles"
    ADD CONSTRAINT "profiles_role_department_rule" CHECK (((("role" = 'admin'::"text") AND ("department" IS NULL)) OR (("role" = ANY (ARRAY['manager'::"text", 'employee_head'::"text"])) AND ("department" IS NOT NULL)))) NOT VALID;



CREATE INDEX "idx_abaya_fabric_type" ON "public"."abaya_cost_config" USING "btree" ("fabric_type");



CREATE INDEX "idx_abaya_lookup" ON "public"."abaya_cost_config" USING "btree" ("abaya_type", "fabric_type", "quality_grade");



CREATE INDEX "idx_abaya_quality_grade" ON "public"."abaya_cost_config" USING "btree" ("quality_grade");



CREATE INDEX "idx_abaya_type" ON "public"."abaya_cost_config" USING "btree" ("abaya_type");



CREATE INDEX "idx_abaya_updated_at" ON "public"."abaya_cost_config" USING "btree" ("updated_at" DESC);



CREATE INDEX "idx_bedsheet_bed_size" ON "public"."bedsheet_cost_config" USING "btree" ("bed_size");



CREATE INDEX "idx_bedsheet_fabric_type" ON "public"."bedsheet_cost_config" USING "btree" ("fabric_type");



CREATE INDEX "idx_bedsheet_lookup" ON "public"."bedsheet_cost_config" USING "btree" ("bedsheet_type", "fabric_type", "bed_size", "quality_grade");



CREATE INDEX "idx_bedsheet_quality_grade" ON "public"."bedsheet_cost_config" USING "btree" ("quality_grade");



CREATE INDEX "idx_bedsheet_type" ON "public"."bedsheet_cost_config" USING "btree" ("bedsheet_type");



CREATE INDEX "idx_bedsheet_updated_at" ON "public"."bedsheet_cost_config" USING "btree" ("updated_at" DESC);



CREATE INDEX "idx_curtain_lookup" ON "public"."curtain_cost_config" USING "btree" ("curtain_type", "fabric_type", "header_style");



CREATE INDEX "idx_curtain_type" ON "public"."curtain_cost_config" USING "btree" ("curtain_type");



CREATE INDEX "idx_department_orders_department_status" ON "public"."department_orders" USING "btree" ("department", "status");



CREATE INDEX "idx_department_orders_order_id" ON "public"."department_orders" USING "btree" ("order_id");



CREATE INDEX "idx_department_orders_planned_dates" ON "public"."department_orders" USING "btree" ("planned_start_date", "planned_end_date");



CREATE INDEX "idx_department_orders_sequence_number" ON "public"."department_orders" USING "btree" ("sequence_number");



CREATE INDEX "idx_fabric_type" ON "public"."curtain_cost_config" USING "btree" ("fabric_type");



CREATE INDEX "idx_header_style" ON "public"."curtain_cost_config" USING "btree" ("header_style");



CREATE INDEX "idx_item_department_progress_department" ON "public"."item_department_progress" USING "btree" ("department");



CREATE INDEX "idx_item_department_progress_department_order_id" ON "public"."item_department_progress" USING "btree" ("department_order_id");



CREATE INDEX "idx_item_department_progress_item_id" ON "public"."item_department_progress" USING "btree" ("item_id");



CREATE INDEX "idx_item_department_progress_order_id" ON "public"."item_department_progress" USING "btree" ("order_id");



CREATE INDEX "idx_item_department_progress_status" ON "public"."item_department_progress" USING "btree" ("status");



CREATE INDEX "idx_item_progress_logs_created_at" ON "public"."item_progress_logs" USING "btree" ("created_at");



CREATE INDEX "idx_item_progress_logs_department" ON "public"."item_progress_logs" USING "btree" ("department");



CREATE INDEX "idx_item_progress_logs_item_id" ON "public"."item_progress_logs" USING "btree" ("item_id");



CREATE INDEX "idx_item_progress_logs_order_id" ON "public"."item_progress_logs" USING "btree" ("order_id");



CREATE INDEX "idx_item_progress_logs_progress_id" ON "public"."item_progress_logs" USING "btree" ("progress_id");



CREATE INDEX "idx_order_cost_breakdown_order_id" ON "public"."order_cost_breakdown" USING "btree" ("order_id");



CREATE INDEX "idx_order_items_item_code" ON "public"."order_items" USING "btree" ("item_code");



CREATE INDEX "idx_order_items_order_id" ON "public"."order_items" USING "btree" ("order_id");



CREATE INDEX "idx_ordersmain_draft_created_at" ON "public"."ordersmain" USING "btree" ("draft_created_at") WHERE ("status" = 'draft'::"text");



CREATE INDEX "idx_ordersmain_priority" ON "public"."ordersmain" USING "btree" ("priority");



CREATE INDEX "idx_ordersmain_product_category" ON "public"."ordersmain" USING "btree" ("product_category");



CREATE INDEX "idx_ordersmain_product_type" ON "public"."ordersmain" USING "btree" ("product_type");



CREATE INDEX "idx_ordersmain_required_delivery_date" ON "public"."ordersmain" USING "btree" ("required_delivery_date");



CREATE INDEX "idx_ordersmain_status" ON "public"."ordersmain" USING "btree" ("status");



CREATE INDEX "idx_updated_at" ON "public"."curtain_cost_config" USING "btree" ("updated_at" DESC);



CREATE UNIQUE INDEX "one_admin_only" ON "public"."profiles" USING "btree" ("role") WHERE ("role" = 'admin'::"text");



CREATE UNIQUE INDEX "uniq_one_employee_head_per_department" ON "public"."profiles" USING "btree" ("department") WHERE ("role" = 'employee_head'::"text");



CREATE UNIQUE INDEX "uniq_one_manager_per_department" ON "public"."profiles" USING "btree" ("department") WHERE ("role" = 'manager'::"text");



CREATE UNIQUE INDEX "uniq_single_admin" ON "public"."profiles" USING "btree" ("role") WHERE ("role" = 'admin'::"text");



CREATE OR REPLACE TRIGGER "abaya_cost_config_timestamp" BEFORE UPDATE ON "public"."abaya_cost_config" FOR EACH ROW EXECUTE FUNCTION "public"."update_abaya_cost_config_timestamp"();



CREATE OR REPLACE TRIGGER "bedsheet_cost_config_timestamp" BEFORE UPDATE ON "public"."bedsheet_cost_config" FOR EACH ROW EXECUTE FUNCTION "public"."update_bedsheet_cost_config_timestamp"();



CREATE OR REPLACE TRIGGER "curtain_cost_config_timestamp" BEFORE UPDATE ON "public"."curtain_cost_config" FOR EACH ROW EXECUTE FUNCTION "public"."update_curtain_cost_config_timestamp"();



CREATE OR REPLACE TRIGGER "trg_delete_auth_on_profile_delete" AFTER DELETE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."delete_auth_user_on_profile_delete"();



CREATE OR REPLACE TRIGGER "trg_first_department" AFTER INSERT ON "public"."ordersmain" FOR EACH ROW EXECUTE FUNCTION "public"."insert_first_department"();



CREATE OR REPLACE TRIGGER "trg_item_department_progress_set_updated_at" BEFORE UPDATE ON "public"."item_department_progress" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_next_department" AFTER UPDATE ON "public"."department_orders" FOR EACH ROW WHEN (("old"."status" <> "new"."status")) EXECUTE FUNCTION "public"."move_to_next_department"();



CREATE OR REPLACE TRIGGER "trg_order_cost_breakdown_set_updated_at" BEFORE UPDATE ON "public"."order_cost_breakdown" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_start_workflow_from_draft" AFTER UPDATE OF "status" ON "public"."ordersmain" FOR EACH ROW EXECUTE FUNCTION "public"."start_department_workflow_for_order"();



ALTER TABLE ONLY "public"."item_department_progress"
    ADD CONSTRAINT "item_department_progress_completed_by_fkey" FOREIGN KEY ("completed_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."item_department_progress"
    ADD CONSTRAINT "item_department_progress_department_order_id_fkey" FOREIGN KEY ("department_order_id") REFERENCES "public"."department_orders"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."item_department_progress"
    ADD CONSTRAINT "item_department_progress_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "public"."order_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."item_department_progress"
    ADD CONSTRAINT "item_department_progress_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."ordersmain"("order_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."item_progress_logs"
    ADD CONSTRAINT "item_progress_logs_actor_profile_id_fkey" FOREIGN KEY ("actor_profile_id") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."item_progress_logs"
    ADD CONSTRAINT "item_progress_logs_item_id_fkey" FOREIGN KEY ("item_id") REFERENCES "public"."order_items"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."item_progress_logs"
    ADD CONSTRAINT "item_progress_logs_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."ordersmain"("order_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."item_progress_logs"
    ADD CONSTRAINT "item_progress_logs_progress_id_fkey" FOREIGN KEY ("progress_id") REFERENCES "public"."item_department_progress"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."order_items"
    ADD CONSTRAINT "order_items_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."ordersmain"("order_id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Allow authenticated admin access" ON "public"."abaya_cost_config" TO "authenticated" USING ((("auth"."jwt"() ->> 'role'::"text") = 'admin'::"text"));



CREATE POLICY "Allow authenticated admin access" ON "public"."bedsheet_cost_config" TO "authenticated" USING ((("auth"."jwt"() ->> 'role'::"text") = 'admin'::"text"));



CREATE POLICY "Allow authenticated admin access" ON "public"."curtain_cost_config" TO "authenticated" USING ((("auth"."jwt"() ->> 'role'::"text") = 'admin'::"text"));



CREATE POLICY "Allow authenticated read access" ON "public"."abaya_cost_config" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated read access" ON "public"."bedsheet_cost_config" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated read access" ON "public"."curtain_cost_config" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow users to create their own profile" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Select policy" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



ALTER TABLE "public"."abaya_cost_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."bedsheet_cost_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."curtain_cost_config" ENABLE ROW LEVEL SECURITY;


ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_update_own" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."delete_auth_user_on_profile_delete"() TO "anon";
GRANT ALL ON FUNCTION "public"."delete_auth_user_on_profile_delete"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."delete_auth_user_on_profile_delete"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."insert_first_department"() TO "anon";
GRANT ALL ON FUNCTION "public"."insert_first_department"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."insert_first_department"() TO "service_role";



GRANT ALL ON FUNCTION "public"."move_to_next_department"() TO "anon";
GRANT ALL ON FUNCTION "public"."move_to_next_department"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."move_to_next_department"() TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."start_department_workflow_for_order"() TO "anon";
GRANT ALL ON FUNCTION "public"."start_department_workflow_for_order"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."start_department_workflow_for_order"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_abaya_cost_config_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_abaya_cost_config_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_abaya_cost_config_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_bedsheet_cost_config_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_bedsheet_cost_config_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_bedsheet_cost_config_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_curtain_cost_config_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_curtain_cost_config_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_curtain_cost_config_timestamp"() TO "service_role";



GRANT ALL ON TABLE "public"."abaya_cost_config" TO "anon";
GRANT ALL ON TABLE "public"."abaya_cost_config" TO "authenticated";
GRANT ALL ON TABLE "public"."abaya_cost_config" TO "service_role";



GRANT ALL ON TABLE "public"."bedsheet_cost_config" TO "anon";
GRANT ALL ON TABLE "public"."bedsheet_cost_config" TO "authenticated";
GRANT ALL ON TABLE "public"."bedsheet_cost_config" TO "service_role";



GRANT ALL ON TABLE "public"."curtain_cost_config" TO "anon";
GRANT ALL ON TABLE "public"."curtain_cost_config" TO "authenticated";
GRANT ALL ON TABLE "public"."curtain_cost_config" TO "service_role";



GRANT ALL ON TABLE "public"."department_orders" TO "anon";
GRANT ALL ON TABLE "public"."department_orders" TO "authenticated";
GRANT ALL ON TABLE "public"."department_orders" TO "service_role";



GRANT ALL ON TABLE "public"."department_delay_view" TO "anon";
GRANT ALL ON TABLE "public"."department_delay_view" TO "authenticated";
GRANT ALL ON TABLE "public"."department_delay_view" TO "service_role";



GRANT ALL ON TABLE "public"."department_sequence" TO "anon";
GRANT ALL ON TABLE "public"."department_sequence" TO "authenticated";
GRANT ALL ON TABLE "public"."department_sequence" TO "service_role";



GRANT ALL ON TABLE "public"."item_department_progress" TO "anon";
GRANT ALL ON TABLE "public"."item_department_progress" TO "authenticated";
GRANT ALL ON TABLE "public"."item_department_progress" TO "service_role";



GRANT ALL ON TABLE "public"."item_progress_logs" TO "anon";
GRANT ALL ON TABLE "public"."item_progress_logs" TO "authenticated";
GRANT ALL ON TABLE "public"."item_progress_logs" TO "service_role";



GRANT ALL ON TABLE "public"."order_cost_breakdown" TO "anon";
GRANT ALL ON TABLE "public"."order_cost_breakdown" TO "authenticated";
GRANT ALL ON TABLE "public"."order_cost_breakdown" TO "service_role";



GRANT ALL ON TABLE "public"."order_items" TO "anon";
GRANT ALL ON TABLE "public"."order_items" TO "authenticated";
GRANT ALL ON TABLE "public"."order_items" TO "service_role";



GRANT ALL ON TABLE "public"."ordersmain" TO "anon";
GRANT ALL ON TABLE "public"."ordersmain" TO "authenticated";
GRANT ALL ON TABLE "public"."ordersmain" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."v_department_orders_full" TO "anon";
GRANT ALL ON TABLE "public"."v_department_orders_full" TO "authenticated";
GRANT ALL ON TABLE "public"."v_department_orders_full" TO "service_role";



GRANT ALL ON TABLE "public"."v_orders_summary" TO "anon";
GRANT ALL ON TABLE "public"."v_orders_summary" TO "authenticated";
GRANT ALL ON TABLE "public"."v_orders_summary" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







