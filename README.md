# Viaje Pibardos — fondo del viaje

Tracker del fondo del viaje: caución + trading, aportes de los amigos y bitácora de operaciones.

**La página:** https://franzunino2-dot.github.io/viaje-pibardos/

Ese link es el bueno. Lo abre cualquiera sin cuenta de nada, y muestra siempre los últimos números.

## Cómo se usa

Cualquiera que abra el link **ve** todo: cartera, caución, aportes, bitácora y el simulador de cierre.

Para **cargar** operaciones hay que desbloquear la edición: botón `🔒 Desbloquear edición`, arriba a la derecha, y poner la clave. Queda desbloqueado en ese browser (se guarda en `localStorage`), así que la clave se pone una sola vez por dispositivo.

Con la edición desbloqueada se puede:

- Cargar compras, ventas, tomas de caución y pagos de caución.
- Editar el precio de hoy de cada ticker en la tabla de Cartera.
- Cargar el monto de cada mes de aportes, tildarlos como confirmados y abrir el desglose por amigo.
- Editar o eliminar operaciones mal cargadas desde la bitácora.

Todo lo que se guarda se ve al instante para el resto: las páginas abiertas se refrescan solas cada 15 segundos y al volver a la pestaña.

El **simulador de cierre** es la excepción: el dólar que pruebes ahí es solo tuyo, no se guarda ni lo ven los demás.

## Cómo está armado

- `index.html` — un solo archivo con todo adentro (HTML + CSS + JS), sin build step ni dependencias más que Google Fonts.
- `supabase/schema.sql` — las tablas y funciones. Se corre una vez, es idempotente.
- `supabase/seed.sql` — la carga inicial de datos (foto al 14/09/2026).

El estado del fondo entero (operaciones, precios, aportes) vive como **un solo documento JSON** en la tabla `viaje_estado`, con la misma forma que el bloque `STATE` que la página tiene embebido. Ese bloque embebido sigue ahí a propósito: es el fallback si la base no contesta, y es lo que hace que el archivo siga funcionando solo.

### Quién puede escribir

- **Leer**: cualquiera. La policy de `SELECT` de `viaje_estado` está abierta.
- **Escribir**: nadie directo. `viaje_estado` no tiene policies de `INSERT`/`UPDATE`/`DELETE`, así que la clave publicable que viaja en el browser no alcanza para escribir. La única puerta es la función `viaje_guardar()`, que es `SECURITY DEFINER` y exige la clave de edición; la clave vive en `viaje_config`, que tiene RLS prendido y cero policies (invisible desde el front).

La clave de edición **no está en el repo** y no tiene que estar: el esquema inserta un placeholder y la clave real se pone a mano, con una línea en el SQL Editor de Supabase:

```sql
update public.viaje_config set clave = 'la-nueva' where id = 'principal';
```

Hay que tener presente qué es y qué no es esto: frena que alguien toque los números por accidente o por curiosear, pero la clave viaja en el pedido cada vez que se guarda. No es un secreto fuerte y no protege contra alguien que se ponga a mirar el tráfico en serio. Para el uso que tiene —ocho amigos y un fondo de viaje— alcanza.

### Concurrencia

Cada guardado manda la `version` que leyó. Si alguien guardó entremedio, el guardado falla en vez de pisar los cambios del otro: la página avisa, trae la versión nueva y hay que volver a cargar la operación.

## Conectar la base

El bloque `window.VIAJE_CONFIG`, arriba del script principal en `index.html`, es lo único que hay que completar:

- `SUPABASE_URL` y `SUPABASE_KEY` se sacan de Supabase → Project Settings → API.
- La clave que va ahí es la **publicable** (`sb_publishable_...` o `anon`), pensada para viajar en el browser. La `secret` / `service_role` **nunca** va al archivo.
- Con los dos campos vacíos la página corre sola con el `STATE` embebido, de solo lectura.

El proyecto de Supabase tiene que ser propio del viaje, no el de ningún laburo: acá van los nombres de los amigos y cuánto puso cada uno.

## Deploy

GitHub Pages sobre `main`, carpeta raíz. Push a `main` = queda publicado en un minuto.

## La versión vieja

Antes de esto el tracker era un artifact de Claude que se republicaba a sí mismo:
https://claude.ai/code/artifact/f7365ac3-ccc2-4e08-bd72-46b1cbea9f52

Ese link sigue existiendo pero ya no es el que vale — quedó congelado y los que entraban veían una versión vieja fijada. El código para republicarse sigue en el archivo como camino alternativo: si se vacía `VIAJE_CONFIG`, la página vuelve a guardarse como artifact.
