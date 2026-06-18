


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
begin
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
    coalesce(nullif(new.raw_user_meta_data->>'full_name',''), 'Unknown'),
    coalesce(nullif(new.email,''), 'no-email'),
    coalesce(nullif(new.raw_user_meta_data->>'phone_number',''), 'N/A'),
    case
      when lower(coalesce(new.raw_user_meta_data->>'role','manager')) in ('admin','manager')
      then lower(new.raw_user_meta_data->>'role')
      else 'manager'
    end,
    case
      when coalesce(new.raw_user_meta_data->>'department','') = ''
      then null
      else upper(new.raw_user_meta_data->>'department')
    end
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
DECLARE
  first_dept TEXT;
  expected_hours NUMERIC;
BEGIN
  -- get first department from sequence
  SELECT department INTO first_dept
  FROM department_sequence
  WHERE step = 1;

  -- get expected hours
  SELECT estimated_hours INTO expected_hours
  FROM master_time_config
  WHERE department = first_dept;

  -- insert into department_orders
  INSERT INTO department_orders(
    order_id,
    department,
    expected_hours,
    status
  ) VALUES (
    NEW.order_id,
    first_dept,
    COALESCE(expected_hours,0),
    'inprogress'
  );

  -- update ordersmain to reflect current department
  UPDATE ordersmain
  SET current_department = first_dept
  WHERE order_id = NEW.order_id;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."insert_first_department"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."move_to_next_department"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  current_seq INT;
  next_dept TEXT;
  expected_hours NUMERIC;
  pk_now TIMESTAMP;
BEGIN
  pk_now := timezone('Asia/Karachi', now());

  IF NEW.status = 'completed' THEN

    SELECT step INTO current_seq
    FROM department_sequence
    WHERE department = NEW.department;

    SELECT department INTO next_dept
    FROM department_sequence
    WHERE step = current_seq + 1;

    IF next_dept IS NULL THEN
      UPDATE ordersmain
      SET status = 'completed'
      WHERE order_id = NEW.order_id;
    ELSE
      SELECT estimated_hours INTO expected_hours
      FROM master_time_config
      WHERE department = next_dept;

      INSERT INTO department_orders(
        order_id,
        department,
        expected_hours,
        status,
        date_in,
        time_in
      ) VALUES (
        NEW.order_id,
        next_dept,
        COALESCE(expected_hours,0),
        'inprogress',
        pk_now::date,
        pk_now::time
      );

      UPDATE ordersmain
      SET current_department = next_dept
      WHERE order_id = NEW.order_id;
    END IF;

    -- ✅ completion timestamps in PK
    UPDATE department_orders
    SET date_out = pk_now::date,
        time_out = pk_now::time
    WHERE id = NEW.id;

  END IF;

  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."move_to_next_department"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


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
    CONSTRAINT "department_orders_department_uppercase" CHECK (("department" = "upper"("department")))
);


ALTER TABLE "public"."department_orders" OWNER TO "postgres";


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


CREATE TABLE IF NOT EXISTS "public"."master_cost_config" (
    "cost_type" "text" NOT NULL,
    "value" numeric NOT NULL,
    "unit" "text"
);


ALTER TABLE "public"."master_cost_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."master_time_config" (
    "department" "text" NOT NULL,
    "estimated_hours" numeric NOT NULL,
    "allowed_delay_hours" numeric NOT NULL,
    CONSTRAINT "department_uppercase" CHECK (("department" = "upper"("department")))
);


ALTER TABLE "public"."master_time_config" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."ordersmain" (
    "order_id" "text" NOT NULL,
    "quantity" integer NOT NULL,
    "current_department" "text" NOT NULL,
    "status" "text" DEFAULT 'pending'::"text",
    "estimated_total_time" numeric,
    "estimated_total_cost" numeric,
    "created_at" timestamp without time zone DEFAULT "now"(),
    "estimated_dept_hours" "jsonb",
    CONSTRAINT "ordersmain_current_department_uppercase" CHECK (("current_department" = "upper"("current_department")))
);


ALTER TABLE "public"."ordersmain" OWNER TO "postgres";


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
    "p"."full_name" AS "manager_name"
   FROM (("public"."department_orders" "d"
     LEFT JOIN "public"."ordersmain" "o" ON (("o"."order_id" = "d"."order_id")))
     LEFT JOIN "public"."profiles" "p" ON ((("upper"("p"."department") = "d"."department") AND ("lower"("p"."role") = 'manager'::"text"))));


ALTER VIEW "public"."v_department_orders_full" OWNER TO "postgres";


ALTER TABLE ONLY "public"."department_orders"
    ADD CONSTRAINT "department_orders_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."department_sequence"
    ADD CONSTRAINT "department_sequence_pkey" PRIMARY KEY ("step");



ALTER TABLE ONLY "public"."master_cost_config"
    ADD CONSTRAINT "master_cost_config_pkey" PRIMARY KEY ("cost_type");



ALTER TABLE ONLY "public"."master_time_config"
    ADD CONSTRAINT "master_time_config_pkey" PRIMARY KEY ("department");



ALTER TABLE ONLY "public"."ordersmain"
    ADD CONSTRAINT "ordersmain_pkey" PRIMARY KEY ("order_id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_email_key" UNIQUE ("email");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



CREATE UNIQUE INDEX "one_admin_only" ON "public"."profiles" USING "btree" ("role") WHERE ("role" = 'admin'::"text");



CREATE UNIQUE INDEX "uniq_one_manager_per_department" ON "public"."profiles" USING "btree" ("department") WHERE ("role" = 'manager'::"text");



CREATE UNIQUE INDEX "uniq_single_admin" ON "public"."profiles" USING "btree" ("role") WHERE ("role" = 'admin'::"text");



CREATE OR REPLACE TRIGGER "trg_delete_auth_on_profile_delete" AFTER DELETE ON "public"."profiles" FOR EACH ROW EXECUTE FUNCTION "public"."delete_auth_user_on_profile_delete"();



CREATE OR REPLACE TRIGGER "trg_first_department" AFTER INSERT ON "public"."ordersmain" FOR EACH ROW EXECUTE FUNCTION "public"."insert_first_department"();



CREATE OR REPLACE TRIGGER "trg_next_department" AFTER UPDATE ON "public"."department_orders" FOR EACH ROW WHEN (("old"."status" <> "new"."status")) EXECUTE FUNCTION "public"."move_to_next_department"();



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Allow users to create their own profile" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Select policy" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "id"));



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



GRANT ALL ON TABLE "public"."department_orders" TO "anon";
GRANT ALL ON TABLE "public"."department_orders" TO "authenticated";
GRANT ALL ON TABLE "public"."department_orders" TO "service_role";



GRANT ALL ON TABLE "public"."department_delay_view" TO "anon";
GRANT ALL ON TABLE "public"."department_delay_view" TO "authenticated";
GRANT ALL ON TABLE "public"."department_delay_view" TO "service_role";



GRANT ALL ON TABLE "public"."department_sequence" TO "anon";
GRANT ALL ON TABLE "public"."department_sequence" TO "authenticated";
GRANT ALL ON TABLE "public"."department_sequence" TO "service_role";



GRANT ALL ON TABLE "public"."master_cost_config" TO "anon";
GRANT ALL ON TABLE "public"."master_cost_config" TO "authenticated";
GRANT ALL ON TABLE "public"."master_cost_config" TO "service_role";



GRANT ALL ON TABLE "public"."master_time_config" TO "anon";
GRANT ALL ON TABLE "public"."master_time_config" TO "authenticated";
GRANT ALL ON TABLE "public"."master_time_config" TO "service_role";



GRANT ALL ON TABLE "public"."ordersmain" TO "anon";
GRANT ALL ON TABLE "public"."ordersmain" TO "authenticated";
GRANT ALL ON TABLE "public"."ordersmain" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."v_department_orders_full" TO "anon";
GRANT ALL ON TABLE "public"."v_department_orders_full" TO "authenticated";
GRANT ALL ON TABLE "public"."v_department_orders_full" TO "service_role";



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







