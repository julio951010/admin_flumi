-- ============================================================
-- LIMPIEZA DE INTERACCIONES DE PRUEBA (RPC)
-- Ejecutar en Supabase SQL Editor para crear la función
-- ============================================================

create or replace function public.limpiar_interacciones_pruebas()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin boolean;
  v_result json;
begin
  -- Verificar que el usuario es admin
  select coalesce(is_admin, false)
    into v_admin
    from public.profiles
   where id = auth.uid()
   limit 1;

  if not v_admin then
    return json_build_object('ok', false, 'error', 'No autorizado: se requiere rol admin');
  end if;

  -- Eliminar interacciones de prueba
  -- Orden importante por foreign keys

  -- 1. Pagos pendientes (pueden referenciar otras tablas)
  delete from public.pagos where estado = 'pendiente';

  -- 2. Usos diarios / contadores
  delete from public.usos_diarios;

  -- 3. Reportes
  delete from public.reportes;

  -- 4. Bloqueos
  delete from public.bloqueos;

  -- 5. Mensajes
  delete from public.messages;

  -- 6. Matches
  delete from public.matches;

  -- 7. Visitas
  delete from public.visitas;

  -- 8. Likes / historial_likes
  delete from public.historial_likes;

  -- 9. Nopes
  delete from public.nopes;

  -- Log de la operación (opcional, si existe tabla de auditoría)
  -- insert into public.admin_log (accion, ejecutado_por, creado_en)
  -- values ('limpiar_interacciones_pruebas', auth.uid(), now());

  v_result := json_build_object(
    'ok', true,
    'mensaje', 'Interacciones de prueba eliminadas correctamente'
  );

  return v_result;

exception when others then
  return json_build_object('ok', false, 'error', sqlerrm);
end;
$$;

revoke all on function public.limpiar_interacciones_pruebas() from public;
grant execute on function public.limpiar_interacciones_pruebas() to authenticated;

-- ============================================================
-- NOTA: Esta función SOLO debe usarse en entornos de DESARROLLO/PRUEBAS.
-- En producción, usar con extrema precaución o no usar.
-- ============================================================