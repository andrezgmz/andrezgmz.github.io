-- ════════════════════════════════════════════════════════════
-- RADAR EN VIVO — Esquema Supabase
-- Ejecutar en: Supabase → tu proyecto → SQL Editor → New query → Run
-- Puedes usar el MISMO proyecto Supabase de tu plataforma principal
-- (São Paulo) — estas tablas son independientes de las 11 existentes.
-- ════════════════════════════════════════════════════════════

create table if not exists sesiones_vivo (
  id uuid primary key default gen_random_uuid(),
  pin text unique not null,
  titulo text default 'Radar Digital en Vivo',
  estado text not null default 'lobby' check (estado in ('lobby','activa','finalizada')),
  eje_index int not null default 0,
  pregunta_index int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists respuestas_vivo (
  id uuid primary key default gen_random_uuid(),
  sesion_id uuid not null references sesiones_vivo(id) on delete cascade,
  participante_id text not null,
  eje_index int not null,
  pregunta_index int not null,
  valor int not null check (valor between 1 and 5),
  created_at timestamptz not null default now(),
  unique (sesion_id, participante_id, eje_index, pregunta_index)
);

-- Conteo de "conectados" en el lobby, vía heartbeat (sin WebSockets)
create table if not exists presencia_vivo (
  id uuid primary key default gen_random_uuid(),
  sesion_id uuid not null references sesiones_vivo(id) on delete cascade,
  participante_id text not null,
  last_seen timestamptz not null default now(),
  unique (sesion_id, participante_id)
);

alter table sesiones_vivo enable row level security;
alter table respuestas_vivo enable row level security;
alter table presencia_vivo enable row level security;

-- Acceso abierto (sin login): es una herramienta efímera de conferencia,
-- no guarda datos sensibles de clientes reales. Si más adelante quieres
-- restringir quién puede CREAR sesiones, se agrega un passcode server-side.
drop policy if exists "lectura publica sesiones" on sesiones_vivo;
create policy "lectura publica sesiones" on sesiones_vivo for select using (true);
drop policy if exists "crear sesiones publico" on sesiones_vivo;
create policy "crear sesiones publico" on sesiones_vivo for insert with check (true);
drop policy if exists "actualizar sesiones publico" on sesiones_vivo;
create policy "actualizar sesiones publico" on sesiones_vivo for update using (true);

drop policy if exists "lectura publica respuestas" on respuestas_vivo;
create policy "lectura publica respuestas" on respuestas_vivo for select using (true);
drop policy if exists "insertar respuestas publico" on respuestas_vivo;
create policy "insertar respuestas publico" on respuestas_vivo for insert with check (true);
drop policy if exists "actualizar respuestas publico" on respuestas_vivo;
create policy "actualizar respuestas publico" on respuestas_vivo for update using (true);

drop policy if exists "lectura publica presencia" on presencia_vivo;
create policy "lectura publica presencia" on presencia_vivo for select using (true);
drop policy if exists "insertar presencia publico" on presencia_vivo;
create policy "insertar presencia publico" on presencia_vivo for insert with check (true);
drop policy if exists "actualizar presencia publico" on presencia_vivo;
create policy "actualizar presencia publico" on presencia_vivo for update using (true);

-- A propósito NO se usa Supabase Realtime (WebSockets): esta versión funciona
-- 100% por REST (fetch) igual que radar_diagnostico.html, sondeando cada
-- 2-3 segundos. Es menos "instantáneo" pero muchísimo más robusto en redes
-- de auditorio (proxies/firewalls de hotel suelen bloquear WebSockets).
