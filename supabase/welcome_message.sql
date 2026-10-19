-- ============================================================
-- MENSAJE DE BIENVENIDA PARA NUEVOS USUARIOS (v2: autosuficiente)
-- Ejecutar en el MISMO proyecto Supabase que flumi_app.
-- Se llama DESPUÉS de verificar el código (ya hay sesión).
-- ============================================================

create or replace function public.enviar_bienvenida_nuevo_usuario(
  p_contenido text default '¡Bienvenido a Flumi! 🎉\n\nAquí puedes conocer gente, hacer matches y chatear. Completa tu perfil para tener más oportunidades.\n\nSi tienes dudas, responde a este mensaje — el equipo de Flumi te ayudará.\n\n¡Disfruta la experiencia!'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_flumi_id uuid := '00000000-0000-0000-0000-00000000000f';
  v_nuevo_usuario uuid := auth.uid();
  v_email text;
begin
  if v_nuevo_usuario is null then
    raise exception 'Usuario no autenticado';
  end if;

  -- Asegura perfil del remitente sistema (por si admin_setup.sql no se ejecutó)
  insert into public.profiles (id, nombre)
  values (v_flumi_id, 'Flumi')
  on conflict (id) do nothing;

  -- Asegura perfil mínimo del receptor (el trigger pudo no existir/correr)
  select email into v_email from auth.users where id = v_nuevo_usuario;
  insert into public.profiles (id, nombre)
  values (v_nuevo_usuario, coalesce(split_part(v_email, '@', 1), 'Nuevo usuario'))
  on conflict (id) do nothing;

  -- Idempotente: no duplica la bienvenida
  if exists (
    select 1 from public.messages
    where emisor_id = v_flumi_id
      and receptor_id = v_nuevo_usuario
      and contenido like '¡Bienvenido a Flumi!%'
  ) then
    return;
  end if;

  insert into public.messages (emisor_id, receptor_id, contenido)
  values (v_flumi_id, v_nuevo_usuario, p_contenido);
end;
$$;

revoke all on function public.enviar_bienvenida_nuevo_usuario(text) from public;
grant execute on function public.enviar_bienvenida_nuevo_usuario(text) to authenticated;
