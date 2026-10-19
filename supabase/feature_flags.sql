-- ============================================================
-- FEATURE FLAGS / APP CONFIG (remote config para flumi_app)
-- Ejecutar en el MISMO proyecto Supabase que flumi_app.
-- ============================================================

create table if not exists public.app_config (
  clave          text primary key,
  valor          jsonb not null,
  tipo           text not null check (tipo in ('bool','int','string','json')),
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

-- Índice para consultas rápidas
create index if not exists app_config_tipo_idx on public.app_config (tipo);