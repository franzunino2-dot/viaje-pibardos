# Viaje Pibardos — fondo del viaje

Este repo tiene una foto (snapshot) del tracker del fondo del viaje: `index.html`, un solo archivo con todo adentro (HTML + CSS + JS), sin dependencias externas más que las tipografías de Google Fonts.

## Importante: esto es una copia, no la página en vivo

El archivo `index.html` de este repo **no se autoactualiza**. La página que usás para cargar operaciones y ver los números al día es esta, siempre:

https://claude.ai/code/artifact/f7365ac3-ccc2-4e08-bd72-46b1cbea9f52

Ahí es donde cargás compras, ventas, aportes, etc., y esos cambios se guardan solos. Este repo en cambio queda **congelado** en el momento en que se exportó — si después seguís operando en el link de arriba, este `index.html` no se entera. Es útil si querés que tus amigos vean el código en sí, tengan una copia de respaldo, o quieran levantar su propia página estática con los datos de hoy — pero para el día a día, seguí usando el link de Claude.

Si en algún momento querés "refrescar" este repo con los datos más recientes, pedime el archivo actualizado de nuevo y reemplazá `index.html` acá, o hacé el mismo export vos mismo copiando el HTML de la página en vivo (Ctrl+U / "Ver código fuente" en el navegador, o guardando la página como HTML).

## Cómo subirlo a GitHub

Necesitás tener [git](https://git-scm.com/) instalado y una cuenta de GitHub. Los pasos, desde una terminal parada en esta carpeta:

```bash
git init
git add index.html README.md
git commit -m "Snapshot del tracker del fondo del viaje"
```

Después creá un repositorio nuevo y vacío en GitHub (botón "New repository" en https://github.com/new — no tildes "Add a README", ya tenés uno). Te va a dar dos líneas para conectar tu repo local, algo así (reemplazá `tu-usuario` y `nombre-del-repo` por los tuyos):

```bash
git remote add origin https://github.com/tu-usuario/nombre-del-repo.git
git branch -M main
git push -u origin main
```

## Cómo publicarlo como página web (GitHub Pages)

Para que tus amigos puedan entrar con un link normal, sin clonar nada:

1. En GitHub, andá a tu repo → **Settings** → **Pages** (menú de la izquierda).
2. En "Build and deployment" → "Source", elegí **Deploy from a branch**.
3. En "Branch", elegí **main** y la carpeta **/ (root)**. Guardá.
4. Esperá un minuto y GitHub te va a dar un link tipo `https://tu-usuario.github.io/nombre-del-repo/`.

Ese link va a mostrar el `index.html` tal cual está en el repo — **de solo lectura, sin el botón de autoguardado** (esa parte es específica de las páginas publicadas dentro de Claude). Si algún amigo edita un precio ahí, no pasa nada — no hay backend que lo guarde.

## Usarlo con Claude Code

Si querés seguir iterando sobre este archivo con Claude Code en vez de acá en el chat: abrí esta carpeta como proyecto (`claude` desde la terminal, parado en la carpeta del repo) y pedile que edite `index.html` directamente. Los cambios los vas a tener que commitear y pushear vos (`git add`, `git commit`, `git push`) para que se reflejen en GitHub Pages — Claude Code no te va a hostear nada solo, ni tampoco tenés ahí la capacidad de autoguardado que sí tiene la página en Claude.
