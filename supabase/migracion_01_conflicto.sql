-- Arregla el control de concurrencia de viaje_guardar().
-- El raise de conflicto usaba SQLSTATE 40001 (serialization_failure), que en la
-- cadena PostgREST/Postgres significa "error transitorio, reintenta": el pedido se
-- quedaba reintentando hasta morir con 504 en vez de devolver el conflicto.
-- Con PT409 devuelve HTTP 409 y el mensaje "conflicto", que es lo que la pagina espera.
-- Correr en: Supabase -> SQL Editor -> New query -> Run.

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
