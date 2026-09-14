-- ===========================================================================
-- Viaje Pibardos — esquema
-- ---------------------------------------------------------------------------
-- Correr una sola vez en: Supabase → SQL Editor → New query → Run.
-- Es idempotente: se puede volver a correr sin romper nada.
--
-- Idea general: todo el estado del fondo (operaciones, precios, aportes) vive
-- en UN solo documento JSON, con la misma forma que el bloque STATE que la
-- página ya tenía adentro. Así no hay que reescribir ningún cálculo.
--
-- Quién puede qué:
--   * leer   → cualquiera con el link (policy de SELECT, abierta)
--   * escribir → NADIE directo. No hay policies de INSERT/UPDATE/DELETE, así
--     que la anon key por sí sola no alcanza para escribir. La única puerta es
--     viaje_guardar(), que es SECURITY DEFINER y exige la clave de edición.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1. El estado del fondo
-- ---------------------------------------------------------------------------
create table if not exists public.viaje_estado (
  id              text        primary key default 'principal',
  estado          jsonb       not null,
  version         bigint      not null default 1,
  actualizado_en  timestamptz not null default now(),
  actualizado_por text
);

alter table public.viaje_estado enable row level security;

-- Lectura abierta: cualquiera con el link ve los números al día.
drop policy if exists "viaje_estado lectura abierta" on public.viaje_estado;
create policy "viaje_estado lectura abierta"
  on public.viaje_estado for select
  using (true);

-- A propósito NO hay policies de insert/update/delete: se escribe solo por RPC.

grant select on public.viaje_estado to anon, authenticated;
revoke insert, update, delete on public.viaje_estado from anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. La clave de edición
-- ---------------------------------------------------------------------------
-- RLS prendido y sin ninguna policy = invisible desde el front, en lectura y
-- en escritura. Solo la llega a ver viaje_guardar(), que corre como dueño.
create table if not exists public.viaje_config (
  id    text primary key default 'principal',
  clave text not null
);

alter table public.viaje_config enable row level security;
revoke all on public.viaje_config from anon, authenticated;

-- Clave inicial. Para cambiarla después, correr solo esta línea con la nueva:
--   update public.viaje_config set clave = 'la-nueva' where id = 'principal';
insert into public.viaje_config (id, clave)
values ('principal', 'pibardos2027')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- 3. La única puerta de escritura
-- ---------------------------------------------------------------------------
-- Guarda el estado nuevo si la clave es correcta. p_version es control de
-- concurrencia optimista: si alguien guardó entremedio, esto falla en vez de
-- pisarle los cambios (la página avisa y recarga).
create or replace function public.viaje_guardar(
  p_estado  jsonb,
  p_clave   text,
  p_version bigint default null,
  p_quien   text default null
)
returns public.viaje_estado
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_clave_ok boolean;
  v_actual   bigint;
  v_row      public.viaje_estado;
begin
  if p_estado is null or jsonb_typeof(p_estado) <> 'object' then
    raise exception 'estado_invalido' using errcode = '22023';
  end if;

  select (clave = p_clave) into v_clave_ok
  from public.viaje_config
  where id = 'principal';

  if not coalesce(v_clave_ok, false) then
    raise exception 'clave_incorrecta' using errcode = '28000';
  end if;

  select version into v_actual
  from public.viaje_estado
  where id = 'principal';

  if p_version is not null and v_actual is not null and v_actual <> p_version then
    -- PT409: PostgREST lo traduce a HTTP 409. NO usar 40001 (serialization_failure):
    -- ese codigo significa 'transitorio, reintentame' y hace que el pedido se cuelgue
    -- reintentando hasta dar timeout en vez de devolver el error.
    raise exception 'conflicto' using errcode = 'PT409';
  end if;

  insert into public.viaje_estado (id, estado, version, actualizado_en, actualizado_por)
  values ('principal', p_estado, 1, now(), p_quien)
  on conflict (id) do update
    set estado          = excluded.estado,
        version         = public.viaje_estado.version + 1,
        actualizado_en  = now(),
        actualizado_por = excluded.actualizado_por
  returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.viaje_guardar(jsonb, text, bigint, text) from public;
grant execute on function public.viaje_guardar(jsonb, text, bigint, text) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Chequeo de clave sin guardar nada (para el botón "desbloquear edición")
-- ---------------------------------------------------------------------------
create or replace function public.viaje_clave_ok(p_clave text)
returns boolean
language sql
security definer
set search_path = public, pg_temp
as $$
  select coalesce((select clave = p_clave from public.viaje_config where id = 'principal'), false);
$$;

revoke all on function public.viaje_clave_ok(text) from public;
grant execute on function public.viaje_clave_ok(text) to anon, authenticated;
