-- ============================================================
-- MÉTRICAS: estadísticas de instalaciones anónimas
-- Requiere la tabla public.instalaciones (flumi_app, fase 7).
-- Idempotente. Ejecutar en Supabase Dashboard -> SQL Editor.
-- ============================================================

create or replace function public.estadisticas_instalaciones()
returns jsonb
language plpgsql
security definer set search_path = public
as $$
declare
  yo uuid := auth.uid();
  es_admin boolean := false;
begin
  if yo is null then
    raise exception 'No autenticado';
  end if;

  select coalesce(is_admin, false) into es_admin
    from public.profiles where id = yo;

  if not es_admin then
    raise exception 'No autorizado';
  end if;

  return jsonb_build_object(
    'total', (
      select count(*) from public.instalaciones),
    'activas_hoy', (
      select count(*) from public.instalaciones
       where ultima_vez::date = current_date),
    'activas_7d', (
      select count(*) from public.instalaciones
       where ultima_vez >= now() - interval '7 days'),
    'activas_30d', (
      select count(*) from public.instalaciones
       where ultima_vez >= now() - interval '30 days'),
    'nuevas_hoy', (
      select count(*) from public.instalaciones
       where creado_en::date = current_date),
    'nuevas_7d', (
      select count(*) from public.instalaciones
       where creado_en >= now() - interval '7 days'),
    'nuevas_30d', (
      select count(*) from public.instalaciones
       where creado_en >= now() - interval '30 days'),
    'por_version', coalesce((
      select jsonb_agg(
               jsonb_build_object('version', version, 'total', total)
               order by total desc, version asc)
      from (
        select coalesce(nullif(version, ''), 'desconocida') as version,
               count(*) as total
        from public.instalaciones
        group by 1
      ) v
    ), '[]'::jsonb),
    'serie_30d', coalesce((
      select jsonb_agg(
               jsonb_build_object('fecha', fecha, 'instalaciones', instalaciones)
               order by fecha)
      from (
        select d::date as fecha,
               (select count(*) from public.instalaciones i
                 where i.creado_en::date = d::date) as instalaciones
        from generate_series(
               current_date - interval '29 days',
               current_date,
               interval '1 day') d
      ) s
    ), '[]'::jsonb)
  );
end;
$$;

revoke all on function public.estadisticas_instalaciones() from public;
grant execute on function public.estadisticas_instalaciones() to authenticated;
