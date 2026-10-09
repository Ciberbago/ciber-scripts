# Termux

Las herramientas del teléfono: un bootstrap que deja Fish, SSH y ocho
comandos, y la explicación de qué hace cada uno.

Esta es la parte del repo que **no** se instala con Ansible. Los otros sistemas
usan `ciber-apply`; aquí el flujo es otro porque Termux no tiene `sudo`, ni
Ansible, ni `/etc`. El bootstrap clona el repo, los scripts van a `~/bin` con
permisos `700`, y las actualizaciones se juegan con `ciber-update`.

## Instalación

En una instalación nueva de Termux, desde el propio Android:

```bash
bash <(curl -L url.jaimelopez.top/termux)
```

Eso ejecuta [`scripts/termux/bootstrap.sh`](../scripts/termux/bootstrap.sh), que
hace cinco cosas **en este orden**:

1. **Paquetes.** `pkg update`, `pkg upgrade` y luego la lista de
   [`scripts/termux/packages`](../scripts/termux/packages), que es la fuente
   única: la usan tanto el bootstrap como `ciber-update`. La lee del repo, y si
   no hay red cae a una lista de respaldo integrada. En esa lista hay `ffmpeg`,
   `python-yt-dlp` y `yt-dlp-ejs`, que son las dependencias de `ffm-tui` y
   `yt-tui`.
2. **Almacenamiento.** Llama a `termux-setup-storage` y espera hasta 10 segundos
   a que aparezca `~/storage/shared`. Si no aparece, avisa y sigue: se puede
   conceder el permiso después y repetir el script.
3. **Fish.** Lo deja como shell con `chsh -s fish`. Si `chsh` no existe, avisa y
   continúa.
4. **`~/.hushlogin`.** Un archivo vacío que oculta el MOTD de Termux, para que al
   abrir una sesión solo se vea la bienvenida propia.
5. **Los scripts.** Clona el repo con `--depth 1` en un directorio temporal,
   instala los ocho comandos en `~/bin` con modo `700`, y los dos archivos de
   Fish en `~/.config/fish/conf.d/`. Luego borra el clon.

Al terminar dice que **esta sesión sigue en Bash**. Para ver los cambios hay que
abrir una sesión nueva, o ejecutar `exec fish`.

## El detalle que sorprende: el bootstrap no sobrescribe

`bootstrap.sh` es idempotente, pero en el sentido de que **conserva** lo que
encuentra:

```
Conservando existente: /data/data/com.termux/files/home/bin/ffm-tui
```

Vuelve a instalar los paquetes (que sí cambian, porque la lista viene del repo),
pero de los scripts solo pone los que faltan. Eso significa que **actualizar el
bootstrap no actualiza tus scripts**, y por eso existe el comando siguiente.

`ciber-update` hace justo lo contrario: **sobrescribe** los scripts desde GitHub,
según el `manifest`. Es el que se usa para las actualizaciones.

## Comandos

| Comando | Qué hace |
|---|---|
| `ciber-help` | Esta ayuda, en el teléfono. Acepta un filtro: `ciber-help ffm` |
| `ciber-update` | Sincroniza los scripts desde GitHub sin clonar el repo, y asegura los paquetes |
| `ffm-tui` | Vídeos: comprimir, quitar audio, copiar sin recodificar |
| `yt-tui` | Descargas de vídeo o audio con `yt-dlp`, con menú de calidad |
| `yt-share` | Descarga el enlace que compartes a Termux |
| `termux-ssh` | Instala, configura, inicia y detiene el servidor SSH, en el puerto **8022** |
| `net-tui` | Red: resumen, ping, barrido de la red local, Wake-on-LAN, diagnóstico |
| `ssh-tui` | Conexiones SSH guardadas por alias |

`ciber-help`, `ciber-update`, `ffm-tui` y `yt-tui` son menús: se ejecutan sin
argumentos y eligen de una lista. `yt-share` y los dos de red no preguntan
nada: los de red porque sus datos están de serie, y `yt-share` porque Android
lo lanza sin quien pueda contestar. `ciber-help`, `ciber-update` y `yt-share`
leen banderas.

### `ciber-help` y `ciber-update`

```bash
ciber-help             # todo
ciber-help ssh         # filtrado: ffm, yt, ssh, red…

ciber-update           # descarga lo que haya cambiado y pregunta
ciber-update --check   # dice qué habría actualizado, sin tocar nada
ciber-update --yes     # instala todo sin preguntar
ciber-update --version # la versión instalada; para diagnosticar un update atorado
ciber-update --help   # las cuatro banderas, sin hacer nada
```

`ciber-update` descarga el repo entero de una vez desde
`codeload.github.com` y compara por `sha256` antes de instalar, así que volver
a ejecutarlo cuando no hay cambios no hace nada.

Lo de `raw.githubusercontent.com` con un `?t=` al final era un intento de
saltarse la caché del CDN, y **no funcionaba**: esa caché se ha visto servir
un fichero viejo durante horas, con `x-cache: HIT` y el `etag` del contenido
viejo, y pedírselo con parámetros distintos daba exactamente lo mismo. Por eso
la fuente es el tarball de `codeload`, que no usa esa caché. De paso, el
manifest y los ficheros salen de la misma descarga, así que no pueden
desincronizarse: antes iban por separado y podía pasar que el manifest fuera
nuevo y el fichero no.

Cada corrida dice **cuántas entradas trae el manifest y con qué hash**. Eso es
lo que distingue un móvil al día de un origen que sirve una copia vieja: los
dos dicen "todo actualizado", pero solo el segundo repite el mismo hash, y sale
el aviso `es el mismo manifiesto que la ultima vez`. El hash se guarda en
`~/.local/state/ciber-update/manifest.hash`, y solo cuando no había nada que
instalar, para no dar por visto un manifiesto que nunca se aplicó.

El propio `ciber-update` se reinstala **el último de todos**. Va en su propio
manifest, así que está en la lista de cambios, pero se salta en el bucle y se
pone al final cuando todo lo demás ya está en su sitio: un actualizador que se
rompe a sí mismo a media instalación no tiene forma de repararse.

### `ffm-tui`

Sin argumentos busca vídeos en el directorio actual y en
`~/storage/downloads`, y si no encuentra ninguno lo dice. Con un argumento abre
ese archivo concreto. El menú ofrece:

1. Comprimir con el preset (máximo 1080p, H.264, CRF 28)
2. Comprimir sin cambiar la resolución
3. Copiar sin recodificar
4. Quitar audio

El preset del punto 1 es la razón de existir del script: bajar 4K a 1080p con
un CRF concreto, sin tener que recordar el `ffmpeg` de siempre.

### `yt-tui`

Pega la URL (o se la pasa como argumento), elige vídeo o audio, y luego el
formato. Para vídeo ofrece "mejor disponible" y topes de 360p, 480p, 720p y
1080p. Para audio, MP3 a 192 y 320 kbps, o m4a. Guarda en
`~/storage/downloads`.

#### Cookies para los sitios que lo piden

Cuando un sitio responde con "inicia sesión", "confirma que eres humano" o un
429, el script lo detecta en el log y avisa. La salida es
`~/.config/yt-tui/config`, y se carga con `source`, o sea que **es shell** y ahí
pueden acabar cookies, cabeceras o un token. Eso implica tres cosas:

- es un archivo **del teléfono**, fuera del repo, y no se sube a ningún lado
- conviene crearlo con `chmod 600`
- si tiene secretos dentro, no se copia al repo ni a la nube

`yt-dlp-ejs` necesita un runtime de JavaScript. El script busca `deno` y luego
`node`, y los ofrece instalar si faltan.

### `yt-share`

Compartir un enlace desde YouTube con Termux: botón de compartir, elegir
Termux, y ya está descargando. Sin abrir la terminal y sin elegir nada.

**El detalle del shebang**, que no es menor. Los scripts de este directorio
usan `#!/usr/bin/env bash` y funcionan, porque se ejecutan desde una shell de
Termux y ahí `termux-exec` (una librería en `LD_PRELOAD`) reescribe las rutas
por debajo. Al compartir, en cambio, Android lanza el script por un intent y
esa librería **no está cargada**: Termux lee la primera línea del fichero y, si
empieza por `/usr`, la lotraduce a su propio `env`. Con `#!/usr/bin/env bash`
eso deja el bucle

```
<prefix>/bin/env  ~/bin/termux-url-opener  <url>
```

donde `env` vuelve a leer el shebang, busca `/usr/bin/env`, y como **en Android
no existe ni `/usr` ni `/bin`**, muere con `env: ... no such file or directory`
y código 127. Por eso `termux-url-opener` y `yt-share` llevan la ruta absoluta,
igual que `bootstrap.sh`, y no el `env`.

Alternativa que existe y aquí no sirve: `termux-fix-shebang` reescribe el
shebang, pero modifica el fichero en el teléfono y se pierde en la siguiente
actualización.

**El flujo real.** La app de Termux recibe el enlace y llama a
`~/bin/termux-url-opener` con la URL como único argumento. Ese archivo existe
porque Android **no deja elegir el nombre**: si no está, en vez de descargar
sale un diálogo de error en pantalla. El archivo del repo del mismo nombre es
un shim que delega en `yt-share`; todo el trabajo está ahí.

Y aquí está la diferencia con `yt-tui`, que conviene tener clara: **ese flujo no
puede preguntar nada**. No hay menú, no hay `pkg install` que pregunte. Por eso:

- Se descarga **el mejor formato disponible**, sin tope de resolución. Para
  elegir calidad, `yt-tui` a mano.
- Si falta una dependencia, **no se instala**: se avisa por notificación con
  la línea exacta de `pkg install` que hay que correr.
- Los argumentos de `~/.config/yt-tui/config` se leen **después** de los
  valores por defecto del script, así que lo que pongas ahí gana. Cookies,
  cabeceras, tokens: los mismos que usa `yt-tui`.

**La pantalla que sale al compartir.** Android no lo ejecuta en segundo plano
invisible: abre una **terminal nueva** con la descarga dentro, y esa es la que
se ve al compartir. Se queda en negro porque el script no escribía nada hasta
el final, así que ahora escribe:

```
yt-share: descargando
https://youtu.be/abc

Cómo arreglar tu Router en 10 minutos
Guardando en /storage/emulated/0/Download/yt-share

 42.1% ████████░░░░░░░░░░░ 3.10MiB/s ETA 00:18

Descarga completada: /storage/emulated/0/Download/yt-share/....mp4
```

La barra se redibuja **en la misma línea**, con retorno de carro, en vez de
ir sumando líneas. Cuando algo falla, sale el motivo en esa misma pantalla y no
solo en la notificación.

Todo eso se dibuja solo si hay una terminal. Se busca en este orden: `stdout`
si es terminal, y si no, **`/dev/tty`**. Ese segundo caso es el que importaba:
la sesión de compartir puede tener `stdout` redirigido, y ahí `-t 1` da falso,
así que sin el respaldo la pantalla se quedaba igual de negra aunque hubiera
código de dibujo. Sin terminal de ninguna clase no se dibuja nada, porque los
caracteres de control serían ruido en un fichero.

`NO_COLOR` apaga el color pero **no** el retorno de carro: son dos cosas
distintas, y sin el retorno de carro la pantalla se llenaría de scroll.

**Si la pantalla se queda en negro**, `~/bin/termux-url-opener` deja una marca
en `~/.local/state/yt-share/compartido.log` **antes de hacer nada**, aunque no
se vea nada por pantalla. Con ella se distinguen los tres casos de un vistazo:

```bash
cat ~/.local/state/yt-share/compartido.log   # ¿llegó a arrancar el shim?
yt-share --version                          # ¿qué copia hay instalada?
cat ~/.local/state/yt-share/ultimo.log      # ¿qué hizo después?
```

| Lo que ves | Qué significa |
|---|---|
| El log `compartido.log` no existe o está viejo | El teléfono no tiene esta versión. `ciber-update --yes` |
| La marca existe pero `ultimo.log` no se actualiza | `yt-share` está viejo o falló nada más empezar |
| Los dos están al día y aun así negro | La sesión no tiene terminal. Hay que mirarlo con logs de Termux |

Ese último caso es el raro, y por eso los tres datos van en el log: sin ellos,
"pantalla negra" no distingue entre "no se ha actualizado" y "falla al
arrancar".

Banderas:

```bash
yt-share --dry-run 'https://youtu.be/dQw4w9WgXcQ'  # comprueba sin descargar
yt-share --max 1080 'https://youtu.be/dQw4w9WgXcQ'  # con tope de calidad
yt-share --audio 'https://youtu.be/dQw4w9WgXcQ'     # MP3 a 192 kbps
yt-share --dir ~/storage/downloads/videos 'URL'     # otra carpeta
yt-share --help
```

**Dónde queda.** En `~/storage/downloads/yt-share/`, una subcarpeta aparte para
que no se mezcle con lo que bajas a mano. Si Android no concedió el
almacenamiento, `~/storage` no existe y cae a `~/downloads/yt-share/`,
dejando nota en el log.

**Cómo avisa.** En este orden, y siempre al log:

| | |
|---|---|
| Log | `~/.local/state/yt-share/ultimo.log`, sobrescrito en cada corrida, permiso `600` |
| Notificación | Si hay Termux:API: una fija mientras baja con título, porcentaje, velocidad y ETA, y otra al acabar |

El log va a `600` a propósito: lleva la línea de comando completa, y esa puede
llevar cookies de `~/.config/yt-tui/config`.

**Que salga en la galería.** Al terminar, `yt-share` pasa el archivo por
`termux-media-scan`, que es lo que avisa al `MediaStore`. Sin eso el vídeo queda
en disco pero Android no lo muestra en la galería, porque escribir un archivo no
registra nada en el índice.

Dos detalles que no son evidentes:

- El comando se llama **`termux-media-scan`**, no `termux-media-scanner`.
- Hay que darle la **ruta real**, no la del enlace. `~/storage/shared` es un
  symlink a `/storage/emulated/0`, y el scanner corre en el proceso de la app
  Termux:API, no en el nuestro: si le pasas el symlink no lo reconoce. El
  script lo resuelve con `realpath` antes de llamar.

Si `yt-dlp` no consigue la ruta final, escanea la carpeta entera con `-r`, que
en algunos Android funciona cuando escanear el archivo suelto no.

**Sin Termux:API también funciona.** Compartir un enlace **no** necesita esa
app: ni para los avisos ni para el escaneo a la galería. Lo único que se pierde
es el aviso, y que lo descargado aparezca en la galería sin abrir la terminal.
Si no está instalada, el script calla, deja todo en el log y ya está.

**Cuando falla.** Detecta en el log los motivos habituales y los dice en la
notificación: el sitio limitando peticiones (429), un vídeo privado o de
miembros, pidiendo iniciar sesión o el captcha, un problema con el runtime de
JavaScript, o YouTube cortando la petición. En la notificación sale el primero
que encaja; los demás quedan en el log, debajo.

**Si se solapan dos descargas.** No se solapan: el script toma un bloqueo en
`~/.local/state/yt-share/bloqueado` y el segundo enlace dice que ya hay una en
marcha. Si el bloqueo se queda de una descarga que murió (se cerró la app, se
fue la batería), se limpia solo pasado una hora, o a mano con `rm -rf`.

**Las dos limitaciones del flujo de compartir**, que vienen de Termux y no del
script:

- Si la app comparte **texto con la URL dentro** y otras palabras, Android no
  lo reconoce como enlace y ofrece guardar el texto en vez de llamar al
  script. YouTube comparte solo la URL, así que no pasa.
- Si no hay `~/bin/termux-url-opener`, Android muestra un diálogo de error. Es
  el aviso más claro que hay: si ves eso, falta el archivo.

### `termux-ssh` y `ssh-tui`

Son dos cosas distintas y conviene no mezclarlas.

**`termux-ssh`** gestiona el servidor SSH **del teléfono**: instala OpenSSH,
configura la contraseña, arranca y para el servicio, y activa o libera el bloqueo
de suspensión (que es lo que mata las conexiones en un móvil). El puerto es el
**8022**, no el 22.

Desde el PC:

```bash
ssh -p 8022 USUARIO@IP
scp -P 8022 archivo USUARIO@IP:~/storage/downloads/
```

El usuario es el de Termux, y la IP la da el punto 5 del menú. La contraseña es
la del punto 2, no la de Android.

**`ssh-tui`** es para las sesiones que ya tienes guardadas. La primera vez se
elige "Agregar conexión" y se registra cada una; después `ssh-tui alias` entra
directo sin menú. Viven en `~/.config/ssh-tui/hosts`, con permiso `600`, en
formato `alias|usuario|host|puerto`. El alias no puede contener `|`, que es el
separador. **No guarda contraseñas**: las pide `ssh` al conectar.

### `net-tui`

Está diseñado para un sitio concreto: dentro de Termux, `ip` está bloqueado por
Android, así que la IP local se detecta con Python, la puerta de enlace se trata
como no-detectable cuando no hay forma de leerla, y la red local se barre con
`ping` y `nmap`. No necesita nada extra; `nmap` se ofrece instalar desde el menú.

Ocho apartados: resumen de red, ping rápido, ping a un host, equipos en la red
local, barrido, **Wake-on-LAN** (con la MAC escrita al momento, sin lista
guardada), estado de SSH y datos de conexión, y diagnóstico de DNS + internet +
latencia.

## Fish

El shell de Fish trae sustituciones para los comandos de siempre:

| | |
|---|---|
| `ls` | `eza --icons=auto -l -a` |
| `ll` | eza compacto |
| `la` | todo |
| `lt` | árbol de dos niveles |
| `cat` | `bat` con colores y números, y sin paginador cuando va a un pipe |

Viven en `~/.config/fish/conf.d/ciber-aliases.fish`. La bienvenida de colores es
`ciber-greeting.fish`, en la misma carpeta. Los dos los instala el bootstrap y
solo si no existían.

## Dónde vive cada cosa

En el teléfono, todo bajo `$HOME`:

| | |
|---|---|
| Los 8 comandos | `~/bin/`, modo `700` |
| Fish: aliases y bienvenida | `~/.config/fish/conf.d/`, modo `644` |
| Conexiones SSH | `~/.config/ssh-tui/hosts`, modo `600` |
| Config de yt-dlp | `~/.config/yt-tui/config` |
| Descargas de compartir | `~/storage/downloads/yt-share/` |
| Log de compartir | `~/.local/state/yt-share/ultimo.log`, modo `600` |
| Marcas de compartir | `~/.local/state/yt-share/compartido.log`: una línea por enlace compartido |
| Descargas y vídeos | `~/storage/downloads/` (el almacenamiento de Android) |

`scripts/termux/packages` incluye `termux-api`, que pone el comando
`termux-media-scan`. La app Termux:API que hace el trabajo de verdad no está en
ninguna lista, porque es un APK y se instala desde F-Droid o GitHub, no con
`pkg`.

El `manifest` del repo es lo que dice qué archivo va dónde y con qué permisos;
`ciber-update` lo lee, así que para agregar un comando nuevo basta una línea ahí
y el archivo en `scripts/termux/`.

## Problemas frecuentes

| Síntoma | Qué hacer |
|---|---|
| No aparece `~/storage/shared` | El permiso de Android no se concedió. `termux-setup-storage` y acepta el diálogo |
| Los comandos no se encuentran | `~/bin` no está en el PATH de Fish. `fish -c 'fish_add_path "$HOME/bin"'`, y revisa `echo $PATH` |
| Fish no aparece al abrir sesión | Esta sesión seguía en Bash. Abre una nueva, o `exec fish` |
| La conexión SSH se corta sola | El bloqueo de suspensión. `termux-ssh`, opción 6 |
| `yt-tui` avisa de 429 o "confirma que eres humano" | Cookies en `~/.config/yt-tui/config`, con `chmod 600` |
| `yt-tui` dice que falta el runtime de JavaScript | `pkg install deno` o `pkg install nodejs` |
| Al compartir, sale un diálogo de error en vez de descargar | Falta `~/bin/termux-url-opener`. Lo pone `ciber-update`; a mano: `ciber-update --yes` |
| Al compartir, `env: ... no such file or directory`, código 127 | Shebang con `/usr/bin/env`, que en Android no existe. Run y codeload ya lo traen con la ruta absoluta; si reaparece, es que alguien lo editó a mano. Comprobación: `sed -n 1p ~/bin/termux-url-opener` |
| Al compartir, no suena la notificación | Falta la app Termux:API. La descarga funciona igual, y queda en el log |
| El vídeo se descarga pero no sale en la galería | Falta la app Termux:API, que es la que indexa. Con ella puesta, `termux-media-scan ~/storage/downloads/yt-share/` a mano lo resuelve |
| Al compartir, la pantalla se queda en negro sin decir nada | `cat ~/.local/state/yt-share/compartido.log`. Si la marca no aparece, el teléfono no tiene esta versión: `ciber-update --yes` |
| Al compartir, el vídeo sale en `~/downloads` y no en `~/storage` | Android no concedió el almacenamiento. `termux-setup-storage` y acepta el diálogo |
| La IP local no aparece en `net-tui` | Es normal: `ip` está bloqueado por Android dentro de Termux, y por eso se detecta con Python |
| `ciber-update` no ve cambios nuevos | Corre `ciber-update --check`: dice cuántas entradas trae el manifest. Si son menos de 11, el origen está sirviendo una copia vieja. Se comprueba con `curl -fsSL https://codeload.github.com/Ciberbago/ciber-scripts/tar.gz/refs/heads/main \| tar -xzO --wildcards '*/scripts/termux/manifest'` |
| `ciber-update` dice "todo actualizado" y no es verdad | Sale el `Aviso: es el mismo manifiesto que la ultima vez` en la línea siguiente. Ver arriba |
| El bootstrap no actualizó mis scripts | No es un fallo: conserva los que existen. Usa `ciber-update` |
