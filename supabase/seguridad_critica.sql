-- ============================================================
-- SEGURIDAD (admin_flumi + flumi_app) — v3, mínima y no destructiva
-- Ejecutar en el SQL Editor del MISMO proyecto Supabase.
-- Idempotente. Requiere admin_setup.sql (public.es_admin()).
--
-- NO toca RLS de pagos_config, contenidos_legales, redes_sociales,
-- pagos_qr, pagos, soporte_mensajes, reports ni app_config: flumi_app
-- ya las protege (schema.sql / supabase_migracion_produccion_v1.sql).
-- Sí cubre is_admin: el trigger proteger_is_admin de flumi_app no protege
-- en la práctica (ver parte 1).
-- ============================================================

-- ------------------------------------------------------------
-- 1) Nadie puede darse is_admin ni (des)suspenderse a sí mismo
-- ------------------------------------------------------------
-- BUG que corrige: proteger_is_admin() de flumi_app es SECURITY DEFINER y su
-- primera línea es  if current_user in ('service_role','postgres',...) then
-- return new.  Dentro de una función SECURITY DEFINER current_user es el
-- DUEÑO de la función (postgres), no quien hace la petición, así que esa
-- condición SIEMPRE es verdadera y el trigger nunca bloquea nada: un usuario
-- normal puede ejecutar  update profiles set is_admin = true  sobre su fila.
-- Lo mismo aplica a suspendido (política "usuario_edita_su_propio_perfil",
-- sin límite de columnas).
--
-- Aquí se distingue por quién llama de verdad: auth.uid() es null en el SQL
-- Editor, en service_role y en el trigger de alta de usuarios; es_admin()
-- cubre al panel. Igual que el trigger original NO lanza error: conserva el
-- valor anterior, así ninguna sincronización del cliente puede romperse.
create or replace function public.proteger_columnas_admin()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or public.es_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.is_admin   := false;
    new.suspendido := false;
  else
    new.is_admin   := old.is_admin;
    new.suspendido := old.suspendido;
  end if;
  return new;
end;
$$;

-- Limpia triggers de versiones anteriores de este script.
drop trigger if exists proteger_columnas_admin on public.profiles;
drop trigger if exists proteger_suspendido_trg on public.profiles;
drop trigger if exists proteger_columnas_admin_trg on public.profiles;
create trigger proteger_columnas_admin_trg
  before insert or update on public.profiles
  for each row execute function public.proteger_columnas_admin();

-- ------------------------------------------------------------
-- 2) Rotar y bloquear las cuentas de sistema
-- ------------------------------------------------------------
-- 'cambiar-este-password' estuvo en un repo público: hay que cambiarla en
-- la base (editar el archivo no basta). Estas cuentas solo son remitentes
-- (enviar_mensaje_admin y la bienvenida son SECURITY DEFINER), nadie debe
-- iniciar sesión con ellas, así que se bloquean ~100 años.
-- (No se usa 'infinity': GoTrue puede fallar al leer ese valor.)
update auth.users
   set encrypted_password = crypt(gen_random_uuid()::text, gen_salt('bf')),
       banned_until       = now() + interval '100 years',
       updated_at         = now()
 where id in ('00000000-0000-0000-0000-00000000000a',
              '00000000-0000-0000-0000-00000000000f');

-- Cierra sesiones abiertas con la contraseña anterior (borra sus refresh tokens en cascada).
delete from auth.sessions
 where user_id in ('00000000-0000-0000-0000-00000000000a',
                   '00000000-0000-0000-0000-00000000000f');
