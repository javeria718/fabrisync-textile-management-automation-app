-- FabriSync cleanup after centralizing calculations in OrderCalculationService.
--
-- master_time_config is intentionally kept because workflow functions still use
-- it as a legacy fallback when older orders do not have estimated_dept_hours.
--
-- master_cost_config is no longer used by active Flutter code, workflow
-- triggers, or views. This migration archives its data before dropping it.

begin;

do $$
begin
  if exists (
    select 1
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
      and pg_get_functiondef(p.oid) ilike '%master_cost_config%'
  ) then
    raise exception 'Refusing to drop public.master_cost_config because a public function still references it.';
  end if;

  if exists (
    select 1
    from pg_views
    where schemaname = 'public'
      and definition ilike '%master_cost_config%'
  ) then
    raise exception 'Refusing to drop public.master_cost_config because a public view still references it.';
  end if;
end $$;

do $$
begin
  if to_regclass('public.master_cost_config') is not null
     and to_regclass('public.master_cost_config_archive') is null then
    execute 'create table public.master_cost_config_archive as table public.master_cost_config';
    comment on table public.master_cost_config_archive is
      'Backup copy created before dropping legacy master_cost_config after FabriSync centralized cost calculation in Flutter.';
  end if;
end $$;

drop table if exists public.master_cost_config;

notify pgrst, 'reload schema';

commit;
