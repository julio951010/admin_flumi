-- ============================================================
-- ADMIN (app admin_flumi) — rol de administrador
-- Ejecutar en el MISMO proyecto Supabase que flumi_app.
-- ============================================================

-- 1) Columnas de control en profiles
alter table public.profiles
  add column if not exists is_admin    boolean not null default false,
  add column if not exists suspendido  boolean not null default false;

-- 2) Función SECURITY DEFINER para leer el rol sin recursión de RLS
create or replace function public.es_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select coalesce(is_admin, false)
  from public.profiles
  where id = auth.uid()
  limit 1;
$$;

-- 3) Políticas RLS para administradores (select ya lo permite la política
--    "perfiles_visibles_para_autenticados"; estas cubren update/delete y
--    refuerzan el select).
drop policy if exists "admin_lee_todos_perfiles" on public.profiles;
create policy "admin_lee_todos_perfiles"
  on public.profiles for select
  using (public.es_admin());

drop policy if exists "admin_actualiza_perfiles" on public.profiles;
create policy "admin_actualiza_perfiles"
  on public.profiles for update
  using (public.es_admin())
  with check (public.es_admin());

drop policy if exists "admin_borra_perfiles" on public.profiles;
create policy "admin_borra_perfiles"
  on public.profiles for delete
  using (public.es_admin());

-- 4) Crear el PRIMER admin:
--    a) Regístrate en la app admin con email/contraseña (se crea el perfil
--       vía el trigger handle_new_user).
--    b) Reemplaza <UUID> por el id del usuario (Authentication > Users del
--       dashboard, o profiles.id) y ejecuta:
-- update public.profiles set is_admin = true where id = '<UUID>';

-- ============================================================
-- TABLA reportes (módulo de moderación del admin)
-- Ajusta nombres/columnas si tu esquema real difiere.
-- ============================================================
create table if not exists public.reportes (
  id              uuid primary key default gen_random_uuid(),
  reportado_id    uuid not null references public.profiles(id) on delete cascade,
  reportante_id   uuid references public.profiles(id) on delete set null,
  motivo          text not null default 'otro',
  descripcion     text,
  estado          text not null default 'pendiente'
                    check (estado in ('pendiente','revisado','desestimado','resuelto')),
  creado_en       timestamptz not null default now(),
  resuelto_en     timestamptz
);

create index if not exists reportes_estado_idx on public.reportes (estado);
create index if not exists reportes_creado_en_idx on public.reportes (creado_en desc);

-- RLS: solo los administradores pueden ver/gestionar reportes.
alter table public.reportes enable row level security;

drop policy if exists "admin_gestiona_reportes" on public.reportes;
create policy "admin_gestiona_reportes"
  on public.reportes for all
  using (public.es_admin())
  with check (public.es_admin());

-- ============================================================
-- Leer el email de Auth de un usuario (el admin no puede leer
-- auth.users con la key pública). Función SECURITY DEFINER que
-- corre como dueño (postgres) y valida rol de admin.
-- ============================================================
create or replace function public.obtener_email_usuario(p_user_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text;
begin
  if not public.es_admin() then
    return null;
  end if;
  select email into v_email from auth.users where id = p_user_id;
  return v_email;
end;
$$;

revoke all on function public.obtener_email_usuario(uuid) from public;
grant execute on function public.obtener_email_usuario(uuid) to authenticated;

-- ============================================================
-- ENVIAR MENSAJES DESDE EL ADMIN (como Administrador o como Flumi)
-- ============================================================
-- Perfiles de sistema (viven en auth.users + profiles). Se crean una sola
-- vez con UUIDs fijos para poder referenciarlos desde la app admin.
create extension if not exists pgcrypto;

do $$
declare
  v_admin_id uuid := '00000000-0000-0000-0000-00000000000a';
  v_flumi_id uuid := '00000000-0000-0000-0000-00000000000f';
begin
  if not exists (select 1 from auth.users where id = v_admin_id) then
    insert into auth.users (id, email, encrypted_password, email_confirmed_at,
                            raw_app_meta_data, created_at, updated_at)
    values (v_admin_id, 'sistema-administrador@flumi.local',
            crypt('cambiar-este-password', gen_salt('bf')),
            now(), '{"provider":"email"}', now(), now());
  end if;

  if not exists (select 1 from auth.users where id = v_flumi_id) then
    insert into auth.users (id, email, encrypted_password, email_confirmed_at,
                            raw_app_meta_data, created_at, updated_at)
    values (v_flumi_id, 'sistema-flumi@flumi.local',
            crypt('cambiar-este-password', gen_salt('bf')),
            now(), '{"provider":"email"}', now(), now());
  end if;

  insert into public.profiles (id, nombre)
  select v_admin_id, 'Administrador'
  where not exists (select 1 from public.profiles where id = v_admin_id);

  insert into public.profiles (id, nombre)
  select v_flumi_id, 'Flumi'
  where not exists (select 1 from public.profiles where id = v_flumi_id);

  update public.profiles set nombre = 'Administrador'
  where id = v_admin_id and (nombre is null or nombre = '');

  update public.profiles set nombre = 'Flumi'
  where id = v_flumi_id and (nombre is null or nombre = '');
end $$;

-- RPC: inserta un mensaje desde un perfil de sistema, sorteando la RLS de
-- messages (que exige emisor_id = auth.uid()). Solo admins y solo con los
-- dos remitentes autorizados.
create or replace function public.enviar_mensaje_admin(
  p_emisor    uuid,
  p_receptor  uuid,
  p_contenido text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin       boolean;
  v_permitido   boolean;
begin
  select coalesce(is_admin, false)
    into v_admin
    from public.profiles
   where id = auth.uid();

  if not v_admin then
    raise exception 'No autorizado';
  end if;

  select (p_emisor = '00000000-0000-0000-0000-00000000000a'
       or p_emisor = '00000000-0000-0000-0000-00000000000f')
    into v_permitido;

  if not v_permitido then
    raise exception 'Remitente no permitido';
  end if;

  if p_emisor = p_receptor then
    raise exception 'No puedes enviarte un mensaje a ti mismo';
  end if;

  if coalesce(p_contenido, '') = '' then
    raise exception 'El mensaje no puede estar vacio';
  end if;

  insert into public.messages (emisor_id, receptor_id, contenido)
  values (p_emisor, p_receptor, p_contenido);
end;
$$;

revoke all on function public.enviar_mensaje_admin(uuid, uuid, text) from public;
grant execute on function public.enviar_mensaje_admin(uuid, uuid, text) to authenticated;
