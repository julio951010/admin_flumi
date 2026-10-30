-- ============================================================
-- FEATURE FLAGS / APP CONFIG (remote config para flumi_app)
-- Ejecutar en el MISMO proyecto Supabase que flumi_app.
-- ============================================================

create table if not exists public.app_config (
  clave          text primary key,
  valor          jsonb not null,
  tipo           text not null check (tipo in ('bool','int','string','json','feature')),
  descripcion    text,
  actualizado_en timestamptz not null default now(),
  actualizado_por uuid references auth.users(id)
);

-- RLS
alter table public.app_config enable row level security;

drop policy if exists "admin_gestiona_app_config" on public.app_config;
create policy "admin_gestiona_app_config"
  on public.app_config for all
  using (public.es_admin())
  with check (public.es_admin());

-- lectura pública para flumi_app (anon + authenticated) — sin esto flumi_app no ve el flag
drop policy if exists "public_lee_app_config" on public.app_config;
create policy "public_lee_app_config"
  on public.app_config for select using (true);

-- Flag inicial: suscripciones habilitadas (true = requieren plan, false = todo libre)
insert into public.app_config (clave, valor, tipo, descripcion)
values ('suscripciones_habilitadas', 'true', 'bool',
        'Si true, las funciones premium requieren suscripción activa. Si false, todo es gratis y se ocultan planes.')
on conflict (clave) do nothing;

-- Config de mantenimiento y versión mínima
insert into public.app_config (clave, valor, tipo, descripcion)
values ('mantenimiento', 'false', 'feature',
        'Modo mantenimiento: bloquea la app con mensaje personalizado.')
on conflict (clave) do nothing;

insert into public.app_config (clave, valor, tipo, descripcion)
values ('mantenimiento_mensaje', 'La app está en mantenimiento. Vuelve pronto.', 'feature',
        'Mensaje mostrado a los usuarios durante el mantenimiento.')
on conflict (clave) do nothing;

insert into public.app_config (clave, valor, tipo, descripcion)
values ('version_minima_build', '1', 'feature',
        'Build mínimo obligatorio. Apps con build menor verán pantalla de actualización.')
on conflict (clave) do nothing;

insert into public.app_config (clave, valor, tipo, descripcion)
values ('actualizar_url', '', 'feature',
        'URL de descarga del APK (Android) o App Store (iOS).')
on conflict (clave) do nothing;

insert into public.app_config (clave, valor, tipo, descripcion)
values ('actualizar_mensaje', 'Hay una nueva versión disponible. Actualiza para seguir usando la app.', 'feature',
        'Mensaje mostrado cuando la versión es menor a la mínima.')
on conflict (clave) do nothing;

-- Índice para consultas rápidas
create index if not exists app_config_tipo_idx on public.app_config (tipo);