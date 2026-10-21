<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.it.md">Italiano</a> ·
  <b>Español</b> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt-BR.md">Português</a> ·
  <a href="README.zh-Hans.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.ru.md">Русский</a>
</p>

<p align="center">
  <img src="assets/readme/hero.svg" width="100%" alt="Porter lleva las sesiones de Claude Code desde una cuenta que ha llegado a su límite de uso a otra que aún tiene margen">
</p>

<p align="center">
  <img alt="macOS 14+" src="https://img.shields.io/badge/macOS-14%2B-2B2522?logo=apple&logoColor=white">
  <img alt="Swift" src="https://img.shields.io/badge/Swift-5.9-C96442?logo=swift&logoColor=white">
  <img alt="10 languages" src="https://img.shields.io/badge/languages-10-433053">
  <a href="LICENSE"><img alt="MIT License" src="https://img.shields.io/badge/license-MIT-4F8A5B"></a>
  <a href="https://github.com/sponsors/matteogilioli"><img alt="Sponsor" src="https://img.shields.io/badge/sponsor-♥-E8906A"></a>
</p>

**Porter** es una pequeña app de la barra de menús de macOS para la pestaña **Code** de Claude Desktop. Cuando una cuenta llega a su límite de uso, Porter lleva tus sesiones de Claude Code a otra cuenta, y retomas las mismas conversaciones justo donde se quedaron. También te permite usar **varios Claude Desktop en paralelo**, uno por cuenta, y mantiene tus sesiones en orden: archivar, restaurar, eliminar y mover proyectos enteros.

> [!NOTE]
> No oficial y sin relación con Anthropic. Porter lee y escribe los archivos propios de Claude Desktop, que no están documentados y pueden cambiar con cualquier actualización. Hace una copia de seguridad antes de cada cambio.

## Varios Claude Desktop a la vez

<p align="center">
  <img src="assets/readme/profiles.svg" width="100%" alt="Tres ventanas de Claude Desktop abiertas a la vez, cada una con una cuenta distinta, todas listadas en el panel de Porter">
</p>

Claude Desktop normalmente funciona con una sola cuenta a la vez: para usar otra tienes que cerrar sesión y volver a iniciarla. Con Porter no hace falta.

- **Nuevo perfil…** abre un Claude Desktop independiente, con su propio inicio de sesión, sus ajustes y su lista de sesiones. Inicia sesión allí con otra cuenta y deja ambas ventanas abiertas.
- Crea tantos perfiles como cuentas tengas (trabajo, personal, un cliente…). Todos funcionan **a la vez**, en el Dock y con ⌘-Tab como cualquier app.
- Porter lista cada perfil con su cuenta, su último uso registrado y las sesiones detenidas por un límite. Puede abrirlo o traerlo al frente, renombrarlo o eliminarlo.
- Mover sesiones entre perfiles es cuestión de un clic, y cuando una cuenta se agota sigues trabajando en la ventana siguiente.
- **Abrir enlaces en el perfil correcto** (en las opciones): todos los perfiles son la misma app Claude, así que tras iniciar sesión en el navegador macOS puede devolverte a cualquiera de los abiertos. Con esta opción, Porter pasa los enlaces de Claude al perfil que usaste por última vez.

¿Prefieres un solo Claude Desktop y cambiar de cuenta cerrando e iniciando sesión? Desactiva **Varios perfiles** en las Opciones: Porter listará entonces cuentas en lugar de apps y moverá las sesiones de la cuenta anterior a la que tengas abierta.

## El panel de la barra de menús

<img src="assets/readme/panel.svg" width="44%" align="right" alt="El panel de Porter en la barra de menús: tarjetas de cuenta con barras de uso de 5 horas y 7 días, una insignia para las sesiones detenidas por el límite y un botón para moverlas">

Haz clic en el icono del botones en la barra de menús para ver el estado de todas las cuentas:

- **Uso de 5 horas y 7 días** de cada cuenta: verde mientras hay margen, naranja cerca del límite, rojo al alcanzarlo. Un valor que Claude Desktop registró hace tiempo se muestra atenuado junto con su antigüedad, y una ventana de 5 horas que seguro ya se reinició lo indica.
- **Sesiones detenidas por el límite**, contadas en cada cuenta y con un punto en el icono de la barra de menús.
- **Mover 6 a Personal →**: un clic mueve las sesiones detenidas a la cuenta con más margen.
- **Sesiones ›** abre esa cuenta en la ventana principal.

<br clear="right">

## La ventana principal

<p align="center">
  <img src="assets/readme/window.svg" width="100%" alt="La ventana principal de Porter: cuentas en una barra lateral, sesiones agrupadas por proyecto, tres sesiones seleccionadas y una barra de acciones con Archivar, Eliminar y Mover a">
</p>

Todas las cuentas y sus sesiones de Claude Code, en un solo lugar:

- **Sesiones agrupadas por proyecto**, con filtros (abiertas, detenidas por el límite, archivadas), un menú de proyectos y búsqueda. Una insignia verde marca las sesiones activas ahora mismo, para que no muevas una a mitad de respuesta.
- **Selecciona** con un clic, con ⇧-clic para un rango o con *Seleccionar todas*. Abajo aparece la barra de acciones:
  - **Mover a…**: elige la cuenta de destino. Los originales se archivan, de modo que la misma sesión no continúe en dos sitios.
  - **Copiar**: las sesiones permanecen en ambas cuentas, y cada copia tiene su propia conversación.
  - **Archivar**, **Restaurar** y **Eliminar…** (a la Papelera, así que aún puedes recuperarlas).
- **Arrastra** sesiones a otra cuenta de la barra lateral para moverlas allí.
- **Mueve la carpeta de un proyecto** (o vuelve a enlazarla si la moviste en el Finder): Porter actualiza todas las sesiones que la usan, en todas las cuentas, junto con sus conversaciones y worktrees de git. Los proyectos cuya carpeta ya no existe aparecen marcados como *Carpeta no encontrada*.

## Cómo funciona

<p align="center">
  <img src="assets/readme/how-it-works.svg" width="100%" alt="Diagrama: Porter copia un pequeño archivo de sesión de la lista de sesiones de una cuenta a la de otra; la conversación permanece en ~/.claude/projects, compartida por todas las cuentas; los chats permanecen en los servidores de Anthropic">
</p>

Una conversación de Claude Code vive en la carpeta propia de Claude Code, `~/.claude/projects`, que no pertenece a ninguna cuenta. Lo único que pertenece a una cuenta es la **lista** de sesiones de Claude Desktop:

```
<data folder>/claude-code-sessions/<account>/<organization>/local_<session>.json
```

(la carpeta de datos predeterminada es `~/Library/Application Support/Claude`). Mover una sesión copia ese pequeño archivo a la lista de la otra cuenta, borra el error «You've hit your limit» y lleva consigo los worktrees de git que usa. Un Claude Desktop en ejecución guarda su lista en memoria, así que Porter lo cierra primero y lo vuelve a abrir después.

> [!IMPORTANT]
> Porter trabaja con lo que Claude Desktop guarda **en tu Mac**: las sesiones de la pestaña **Code**. Los chats, incluidos aquellos en los que Claude trabaja con tus archivos, se almacenan en los servidores de Anthropic y permanecen con su cuenta.

## Instalación

Requiere **macOS 14** o posterior y [Claude Desktop](https://claude.ai/download).

**Descarga:** obtén `Porter.dmg` de la [última versión](../../releases/latest), ábrelo y arrastra **Porter for Claude Desktop** a `Applications`. La app no está notarizada, así que macOS la bloquea la primera vez: abre **Ajustes del Sistema → Privacidad y seguridad** y haz clic en **Abrir igualmente**, o ejecuta:

```bash
xattr -dr com.apple.quarantine "/Applications/Porter for Claude Desktop.app"
```

**Compilar desde el código fuente** (Xcode o las Command Line Tools):

```bash
git clone https://github.com/matteogilioli/porter-for-claude-desktop.git
cd porter-for-claude-desktop
./scripts/build-app.sh --install
```

Esto compila `dist/Porter for Claude Desktop.app` y lo copia en `~/Applications`. Activa **Abrir al iniciar sesión** en las Opciones para tener Porter siempre a mano.

Porter habla English, Italiano, Español, Français, Deutsch, Português, 简体中文, 日本語, 한국어 y Русский, según el idioma de tu Mac.

## Línea de comandos

La misma app mueve sesiones desde scripts:

```bash
PORTER="/Applications/Porter for Claude Desktop.app/Contents/MacOS/Porter"
"$PORTER" --list                                        # cuentas, perfiles y sus listas de sesiones
"$PORTER" --move --from STORE --to STORE --dry-run      # qué pasaría
"$PORTER" --move --from STORE --to STORE --restart      # mover (originales archivados)
"$PORTER" --move --from STORE --to STORE --copy         # copiar en lugar de mover
```

`STORE` es una ruta que imprime `--list`. Añade `--session local_…` (repetible) para sesiones concretas, `--include-archived` para incluir también las archivadas y `--data-dir PATH` para una carpeta de datos de Claude que Porter aún no conoce.

Porter solo cierra un Claude Desktop abierto con `--restart` (después lo vuelve a abrir, y reinicia o abre el destino para que cargue las sesiones); sin él, un traslado que necesita cerrar una app se detiene e indica cuál. `--dry-run` lista las apps que cerraría.

## Conviene saber

- **Deshacer:** cada cambio empieza con una copia de seguridad en `~/Library/Application Support/Porter/backups`. Para deshacer un movimiento, cierra Claude Desktop y copia los archivos guardados a la ruta indicada en el `README.txt` de la copia.
- **Los datos de uso** provienen de lo que Claude Desktop registra, algo que hace de vez en cuando mientras usas una cuenta. Porter muestra la antigüedad de cada valor.
- **Un lugar a la vez:** no sigas trabajando en la misma sesión desde dos cuentas a la vez. Por eso mover archiva el original; usa Copiar cuando de verdad quieras dos sesiones independientes.
- Usa solo cuentas que sean tuyas y respeta las condiciones de tu plan de Claude.

## Apoyo

Porter es gratuito y de código abierto. Si te ahorra algo de espera, puedes [patrocinarlo en GitHub](https://github.com/sponsors/matteogilioli).

## Licencia

[MIT](LICENSE). Claude es una marca registrada de Anthropic, PBC. Porter es un proyecto independiente y no está afiliado a Anthropic ni cuenta con su respaldo.
