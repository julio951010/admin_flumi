-- ============================================================
-- MENSAJES DEL SISTEMA (Administrador / Flumi)
-- Historial, métricas, plantillas y envío masivo.
--
-- Requiere haber ejecutado antes `admin_setup.sql` (crea `es_admin()`,
-- los perfiles de sistema y la RPC `enviar_mensaje_admin`).
-- Idempotente. Ejecutar en Supabase Dashboard -> SQL Editor.
-- ============================================================

-- ------------------------------------------------------------
-- 0) Índice para el historial (emisor + fecha)
-- ------------------------------------------------------------
create index if not exists messages_sistema_idx
  on public.messages (emisor_id, "timestamp" desc);

-- ------------------------------------------------------------
-- 1) Plantillas de mensajes
-- ------------------------------------------------------------
create table if not exists public.mensajes_plantillas (
  id              uuid primary key default gen_random_uuid(),
  titulo          text not null,
  contenido       text not null,
  creado_en       timestamptz not null default now(),
  actualizado_en  timestamptz not null default now()
);

alter table public.mensajes_plantillas enable row level security;

drop policy if exists "admin_gestiona_plantillas" on public.mensajes_plantillas;
create policy "admin_gestiona_plantillas"
  on public.mensajes_plantillas for all
  using (public.es_admin())
  with check (public.es_admin());

grant select, insert, update, delete
  on public.mensajes_plantillas to authenticated;

-- Plantillas iniciales (solo si la tabla está vacía).
insert into public.mensajes_plantillas (titulo, contenido)
select v.titulo, v.contenido
from (values
  ('Bienvenida',
   '¡Hola {nombre}! 👋 Bienvenido/a a Flumi. Completa tu perfil y añade una foto para tener más oportunidades de match. Si necesitas ayuda, escríbenos desde Soporte.'),
  ('Completa tu perfil',
   'Hola {nombre}, hemos visto que tu perfil aún está incompleto. Añadir una foto y una descripción breve ayuda a que otras personas te conozcan mejor. 💜'),
  ('Aviso importante',
   'Hola {nombre}, te escribimos desde el equipo de Flumi para informarte de un aviso importante. Por favor, revisa la aplicación cuando puedas.'),
  ('Recuperar acceso',
   'Hola {nombre}, hemos recibido tu solicitud de ayuda con el acceso a tu cuenta. Responde a este mensaje desde Soporte y te ayudaremos a recuperarla.')
) as v(titulo, contenido)
where not exists (select 1 from public.mensajes_plantillas);

-- ------------------------------------------------------------
-- 2) Función interna: mensajes enviados por las cuentas de sistema
--    (no se expone como RPC; solo la usan las funciones de abajo)
-- ------------------------------------------------------------
create or replace function public.mensajes_sistema_filtrados(
  p_busqueda  text,
  p_remitente uuid
)
returns table (
  id              uuid,
  emisor_id       uuid,
  receptor_id     uuid,
  contenido       text,
  fecha           timestamptz,
  estado_envio    text,
  receptor_nombre text,
  receptor_foto   text
)
language sql
security definer
set search_path = public
stable
as $$
  select
    m.id,
    m.emisor_id,
    m.receptor_id,
    m.contenido,
    m."timestamp" as fecha,
    coalesce(m.estado_envio, 'enviado') as estado_envio,
    coalesce(p.nombre, 'Usuario eliminado') as receptor_nombre,
    coalesce(p.fotos_urls[1], '') as receptor_foto
  from public.messages m
  left join public.profiles p on p.id = m.receptor_id
  where m.emisor_id in (
      '00000000-0000-0000-0000-00000000000a'::uuid,
      '00000000-0000-0000-0000-00000000000f'::uuid
    )
    and (p_remitente is null or m.emisor_id = p_remitente)
    and (
      coalesce(trim(p_busqueda), '') = ''
      or p.nombre ilike '%' || trim(p_busqueda) || '%'
      or m.contenido ilike '%' || trim(p_busqueda) || '%'
      or m.receptor_id::text = trim(p_busqueda)
    );
$$;

-- Solo uso interno: sin acceso directo para clientes.
revoke all on function public.mensajes_sistema_filtrados(text, uuid)
  from public, anon, authenticated;

-- ------------------------------------------------------------
-- 3) RPC: listar el historial (paginado)
-- ------------------------------------------------------------
create or replace function public.mensajes_sistema_listar(
  p_busqueda  text default '',
  p_remitente uuid default null,
  p_limite    integer default 30,
  p_offset    integer default 0
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total    bigint;
  v_mensajes jsonb;
begin
  if not public.es_admin() then
    raise exception 'No autorizado';
  end if;

  select count(*)
    into v_total
    from public.mensajes_sistema_filtrados(p_busqueda, p_remitente);

  select coalesce(jsonb_agg(to_jsonb(x) order by x.fecha desc), '[]'::jsonb)
    into v_mensajes
    from (
      select *
        from public.mensajes_sistema_filtrados(p_busqueda, p_remitente)
       order by fecha desc
       limit least(greatest(coalesce(p_limite, 30), 1), 100)
      offset greatest(coalesce(p_offset, 0), 0)
    ) x;

  return jsonb_build_object(
    'total', v_total,
    'mensajes', v_mensajes
  );
end;
$$;

revoke all on function public.mensajes_sistema_listar(text, uuid, integer, integer)
  from public, anon;
grant execute on function public.mensajes_sistema_listar(text, uuid, integer, integer)
  to authenticated;

-- ------------------------------------------------------------
-- 4) RPC: métricas de los envíos
-- ------------------------------------------------------------
create or replace function public.mensajes_sistema_stats()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_resultado jsonb;
begin
  if not public.es_admin() then
    raise exception 'No autorizado';
  end if;

  select jsonb_build_object(
    'total', count(*),
    'admin', count(*) filter (
      where m.emisor_id = '00000000-0000-0000-0000-00000000000a'::uuid),
    'flumi', count(*) filter (
      where m.emisor_id = '00000000-0000-0000-0000-00000000000f'::uuid),
    'hoy', count(*) filter (
      where m."timestamp" >= date_trunc('day', now())),
    'ultimos_7d', count(*) filter (
      where m."timestamp" >= now() - interval '7 days'),
    'ultimos_30d', count(*) filter (
      where m."timestamp" >= now() - interval '30 days'),
    'usuarios_alcanzados', count(distinct m.receptor_id),
    'usuarios_totales', (
      select count(*)
        from public.profiles p
       where p.id not in (
               '00000000-0000-0000-0000-00000000000a'::uuid,
               '00000000-0000-0000-0000-00000000000f'::uuid)
         and coalesce(p.is_admin, false) = false
         and coalesce(p.suspendido, false) = false
    ),
    'serie_14d', coalesce((
      select jsonb_agg(
               jsonb_build_object(
                 'fecha', d::date,
                 'total', coalesce(s.total, 0))
               order by d)
        from generate_series(
               current_date - interval '13 days',
               current_date,
               interval '1 day') d
        left join (
          select m2."timestamp"::date as dia, count(*) as total
            from public.messages m2
           where m2.emisor_id in (
                   '00000000-0000-0000-0000-00000000000a'::uuid,
                   '00000000-0000-0000-0000-00000000000f'::uuid)
             and m2."timestamp" >= current_date - interval '13 days'
           group by 1
        ) s on s.dia = d::date
    ), '[]'::jsonb)
  )
  into v_resultado
  from public.messages m
  where m.emisor_id in (
      '00000000-0000-0000-0000-00000000000a'::uuid,
      '00000000-0000-0000-0000-00000000000f'::uuid
    );

  return v_resultado;
end;
$$;

revoke all on function public.mensajes_sistema_stats() from public, anon;
grant execute on function public.mensajes_sistema_stats() to authenticated;

-- ------------------------------------------------------------
-- 5) RPC: eliminar un mensaje del sistema
-- ------------------------------------------------------------
create or replace function public.mensajes_sistema_eliminar(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_borrados integer;
begin
  if not public.es_admin() then
    raise exception 'No autorizado';
  end if;

  delete from public.messages
   where id = p_id
     and emisor_id in (
       '00000000-0000-0000-0000-00000000000a'::uuid,
       '00000000-0000-0000-0000-00000000000f'::uuid);

  get diagnostics v_borrados = row_count;
  if v_borrados = 0 then
    raise exception 'Mensaje no encontrado';
  end if;
end;
$$;

revoke all on function public.mensajes_sistema_eliminar(uuid) from public, anon;
grant execute on function public.mensajes_sistema_eliminar(uuid) to authenticated;

-- ------------------------------------------------------------
-- 6) Destinatarios de un envío masivo (función interna)
-- ------------------------------------------------------------
create or replace function public.mensajes_masivo_destinatarios(
  p_emisor           uuid,
  p_segmento         text,
  p_solo_sin_mensaje boolean default false,
  p_limite           integer default 200
)
returns setof uuid
language sql
security definer
set search_path = public
stable
as $$
  select p.id
    from public.profiles p
   where p.id not in (
           '00000000-0000-0000-0000-00000000000a'::uuid,
           '00000000-0000-0000-0000-00000000000f'::uuid)
     and coalesce(p.is_admin, false) = false
     and coalesce(p.suspendido, false) = false
     and case coalesce(nullif(trim(p_segmento), ''), 'todos')
           when 'todos' then true
           when 'verificados' then coalesce(p.verificado_status, false)
           when 'no_verificados' then not coalesce(p.verificado_status, false)
           when 'perfil_completo' then coalesce(p.perfil_completado, false)
           when 'perfil_incompleto' then not coalesce(p.perfil_completado, false)
           when 'sin_foto' then coalesce(array_length(p.fotos_urls, 1), 0) = 0
           when 'activos_7d' then p.ultima_conexion >= now() - interval '7 days'
           when 'inactivos_30d' then
             p.ultima_conexion is null
             or p.ultima_conexion < now() - interval '30 days'
           else false
         end
     -- No enviar a quien haya bloqueado (o haya sido bloqueado por) el remitente.
     and not exists (
       select 1
         from public.blocks b
        where (b.bloqueador_id = p.id and b.bloqueado_id = p_emisor)
           or (b.bloqueador_id = p_emisor and b.bloqueado_id = p.id))
     -- Opcional: solo quienes nunca recibieron un mensaje de esta cuenta.
     and (not coalesce(p_solo_sin_mensaje, false)
          or not exists (
            select 1
              from public.messages m
             where m.emisor_id = p_emisor
               and m.receptor_id = p.id))
   order by p.ultima_conexion desc nulls last, p.id
   limit least(greatest(coalesce(p_limite, 200), 1), 500);
$$;

revoke all on function public.mensajes_masivo_destinatarios(uuid, text, boolean, integer)
  from public, anon, authenticated;

-- ------------------------------------------------------------
-- 7) RPC: contar destinatarios de un segmento
-- ------------------------------------------------------------
create or replace function public.mensajes_masivo_contar(
  p_emisor           uuid,
  p_segmento         text,
  p_solo_sin_mensaje boolean default false,
  p_limite           integer default 200
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_total integer;
begin
  if not public.es_admin() then
    raise exception 'No autorizado';
  end if;

  if p_emisor not in (
      '00000000-0000-0000-0000-00000000000a'::uuid,
      '00000000-0000-0000-0000-00000000000f'::uuid) then
    raise exception 'Remitente no permitido';
  end if;

  select count(*)::integer
    into v_total
    from public.mensajes_masivo_destinatarios(
           p_emisor, p_segmento, p_solo_sin_mensaje, p_limite);

  return coalesce(v_total, 0);
end;
$$;

revoke all on function public.mensajes_masivo_contar(uuid, text, boolean, integer)
  from public, anon;
grant execute on function public.mensajes_masivo_contar(uuid, text, boolean, integer)
  to authenticated;

-- ------------------------------------------------------------
-- 8) RPC: envío masivo
-- ------------------------------------------------------------
create or replace function public.enviar_mensaje_masivo(
  p_emisor           uuid,
  p_contenido        text,
  p_segmento         text default 'todos',
  p_solo_sin_mensaje boolean default false,
  p_limite           integer default 200
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_destinatarios uuid[];
  v_id            uuid;
  v_enviados      integer := 0;
  v_omitidos      integer := 0;
begin
  if not public.es_admin() then
    raise exception 'No autorizado';
  end if;

  if p_emisor not in (
      '00000000-0000-0000-0000-00000000000a'::uuid,
      '00000000-0000-0000-0000-00000000000f'::uuid) then
    raise exception 'Remitente no permitido';
  end if;

  if coalesce(trim(p_contenido), '') = '' then
    raise exception 'El mensaje no puede estar vacío';
  end if;

  if coalesce(p_limite, 0) < 1 or p_limite > 500 then
    raise exception 'El límite debe estar entre 1 y 500';
  end if;

  select coalesce(array_agg(d), '{}'::uuid[])
    into v_destinatarios
    from public.mensajes_masivo_destinatarios(
           p_emisor, p_segmento, p_solo_sin_mensaje, p_limite) d;

  foreach v_id in array v_destinatarios loop
    begin
      insert into public.messages (emisor_id, receptor_id, contenido)
      values (p_emisor, v_id, trim(p_contenido));
      v_enviados := v_enviados + 1;
    exception when others then
      -- Un usuario bloqueado o eliminado no debe abortar todo el envío.
      v_omitidos := v_omitidos + 1;
    end;
  end loop;

  return jsonb_build_object(
    'enviados', v_enviados,
    'omitidos', v_omitidos,
    'destinatarios', coalesce(array_length(v_destinatarios, 1), 0)
  );
end;
$$;

revoke all on function public.enviar_mensaje_masivo(uuid, text, text, boolean, integer)
  from public, anon;
grant execute on function public.enviar_mensaje_masivo(uuid, text, text, boolean, integer)
  to authenticated;

-- ============================================================
-- Fin. Recuerda ejecutar también `admin_setup.sql` si aún no lo
-- has hecho, y `metricas.sql` para la página de métricas.
-- ============================================================
