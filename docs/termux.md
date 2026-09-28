# Termux

Las herramientas del teléfono: un bootstrap que deja Fish, SSH y siete
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
   instala los siete comandos en `~/bin` con modo `700`, y los dos archivos de
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
| `yt-tui` | Descargas de vídeo o audio con `yt-dlp` |
| `termux-ssh` | Instala, configura, inicia y detiene el servidor SSH, en el puerto **8022** |
| `net-tui` | Red: resumen, ping, barrido de la red local, Wake-on-LAN, diagnóstico |
| `ssh-tui` | Conexiones SSH guardadas por alias |

Los cinco primeros son menús: se ejecutan sin argumentos y eligen de una lista.
`ciber-help` y `ciber-update` son los únicos que leen banderas.

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

`ciber-update` compara por `sha256` antes de instalar, así que volver a
ejecutarlo cuando no hay cambios no hace nada. Añade un parámetro aleatorio a
las URLs para no comerse la caché del CDN de GitHub; `CIBER_CACHE_BUST=0` lo
desactiva, que es lo que hay que poner para probar en local.

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
| Los 7 comandos | `~/bin/`, modo `700` |
| Fish: aliases y bienvenida | `~/.config/fish/conf.d/`, modo `644` |
| Conexiones SSH | `~/.config/ssh-tui/hosts`, modo `600` |
| Config de yt-dlp | `~/.config/yt-tui/config` |
| Descargas y vídeos | `~/storage/downloads/` (el almacenamiento de Android) |

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
| La IP local no aparece en `net-tui` | Es normal: `ip` está bloqueado por Android dentro de Termux, y por eso se detecta con Python |
| `ciber-update` no ve cambios nuevos | `CIBER_CACHE_BUST=0` para descartar la caché, o `--version` para ver qué tiene instalado |
| El bootstrap no actualizó mis scripts | No es un fallo: conserva los que existen. Usa `ciber-update` |
