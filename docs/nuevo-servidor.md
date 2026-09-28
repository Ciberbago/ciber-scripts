# Server nuevo: de formatear a funcionando

Este es el camino completo, en orden, desde una máquina recién formateada hasta
los servicios levantados. Está escrito para leerlo a las tantas de la madrugada
después de un fallo, así que los pasos van numerados y se pueden seguir uno a uno.

## Índice

| Paso | Qué es | Cuándo lo necesitas |
|---|---|---|
| [1. Clave SSH](#1-clave-ssh-en-github) | Copia la clave pública a GitHub | Solo para el repo **privado** de stacks |
| [2. Sistema y Docker](#2-sistema-docker-y-el-respaldo) | `wget -O - url.jaimelopez.top/debian \| bash` | El primero, siempre |
| [3. Credenciales](#3-credenciales-del-respaldo) | Rellenar `/etc/ciber/backup.env` | Antes de las 18:00 |
| [4. Repo de stacks](#4-repo-de-stacks) | `git clone` a `/opt/docker` | Siempre, y **a mano** |
| [5. `.env` de los stacks](#5-env-de-los-stacks) | Los 41 valores, del gestor | Siempre |
| [6. rclone](#6-rclone) | Copiar el `rclone.conf` del servidor viejo | Siempre, o no hay respaldo |
| [7. Restaurar](#7-restaurar-y-arrancar) | `restore.sh` y levantar | Siempre |

Y al final: [qué no vuelve de un respaldo](#qué-no-vuelve-de-un-respaldo) ·
[si algo falla](#si-algo-falla) · [lo que no se ha probado](#lo-que-este-respaldo-todavía-no-ha-demostrado)

---

```
  1. Clave SSH en GitHub          (manual)   ← solo para el repo PRIVADO de stacks
  2. Sistema + Docker              (automático)  ← el bootstrap y el playbook
  3. Credenciales del respaldo    (manual)
  4. Repo de stacks               (manual)   ← a propósito, ver más abajo
  5. .env de los stacks           (manual)
  6. Configuración de rclone      (manual)
  7. Restaurar y arrancar         (manual)
```

## Por qué el paso 4 es manual

Hasta el 2026-09-28 el playbook clonaba el repo de stacks en `/opt/docker`. Se quitó
a propósito, y la razón es la que más caro sale cuando se equivoca.

El clon iba con `failed_when: false`. Sobre un repositorio **privado** eso significa
que, si no hay credenciales de GitHub, `git` falla, la tarea **se traga el error** y
el servidor queda con `/opt/docker` vacío y una sola línea de `debug` en un scroll de
veinte. Es decir: en plena recuperación de desastres, el sistema dice que fue bien
mientras no tiene nada que levantar.

Prefiero que el paso falle a la vista.

## 1. Clave SSH en GitHub

Solo hace falta para el repo **privado** de stacks. El de este repo
(`ciber-scripts`) es público y se clona por HTTPS sin credenciales.

```bash
ssh-keygen -t rsa -b 4096 -C "tu@email.com"
cat ~/.ssh/id_rsa.pub
```

Copia esa línea entera a <https://github.com/settings/keys>. Comprueba que funciona:

```bash
ssh -T git@github.com
```

Debe saludarte sin pedir usuario ni contraseña. Si te pide una passphrase y no la
tienes a mano en un servidor, la clave sirve igual para `git clone` por SSH; lo que
pide es que la tengas disponible.

## 2. Sistema, Docker y el respaldo

```bash
wget -O - url.jaimelopez.top/debian | bash
```

Eso instala Ansible, clona este repo en `~/.local/share/ciber-scripts` y aplica
`site-debian.yml`. Deja:

- El sistema base, fish, neovim, Tailscale, Docker Engine, containerd y compose.
- `/usr/local/bin/backup-datos.sh`, `restore.sh` y `backup-musica.sh`.
- `/etc/ciber/data-map.conf`, que dice qué se respalda.
- `backup.timer` (18:00) y `backup-musica.timer` (04:00).

Dos pasos manuales que te recuerda el propio playbook:

```bash
sudo tailscale up
```

Y **cerrar sesión y volver a entrar**: el grupo `docker` y el shell fish aplican en
el siguiente login, no en el actual.

## 3. Credenciales del respaldo

El playbook crea `/etc/ciber/backup.env` **vacío**. Hasta que lo rellenes,
`backup.service` **falla al arrancar**, y eso es lo correcto: un token vacío no da
error, el `curl` sale con éxito y el aviso simplemente no llega.

```bash
sudo micro /etc/ciber/backup.env
```

Las dos claves, de tu gestor de contraseñas:

```
TELEGRAM_TOKEN=...
TELEGRAM_CHAT_ID=...
```

```bash
sudo ciber-secrets     # dice qué falta, y sale con 1 si queda algo pendiente
```

## 4. Repo de stacks

```bash
git clone git@github.com:Ciberbago/ciber-docker.git /opt/docker
cd /opt/docker
bin/sync-env           # crea los symlinks <stack>/.env -> /opt/docker/.env
```

`bin/sync-env` **necesita que el `.env` del paso 5 exista**. Si lo saltas, los
stacks arrancarán con los `${PORT_*}` vacíos y fallarán con un error poco claro.

## 5. `.env` de los stacks

Este archivo tiene 41 claves: puertos, credenciales de servicios, y las que leen las
apps por `getenv()`. **Nunca va a git ni al respaldo** — es el único sitio donde vive
la configuración sensible de los stacks.

```bash
sudo cp /opt/docker/.env.example /opt/docker/.env
sudo micro /opt/docker/.env
```

`.env.example` ya tiene las 41 claves documentadas, así que es rellenar huecos con
lo que tengas en el gestor. Los puertos son los del servidor viejo; cámbialos si
coinciden con otro equipo en la red.

Todas las variables que leen los compose van con la guarda `${VAR?falta .env}`, así
que si falta alguna Docker avisa con un mensaje claro en vez de arrancar a medias.

## 6. rclone

**La configuración de rclone no sobrevive a un formateo**: vive en
`~/.config/rclone/rclone.conf` y dentro hay un token de Google Drive. Sin ella no se
puede bajar el respaldo.

Cópiala del servidor viejo:

```bash
scp servidor-viejo:/home/USUARIO/.config/rclone/rclone.conf ~/.config/rclone/
chmod 600 ~/.config/rclone/rclone.conf
```

Comprueba que el token sigue vivo (los de Google caducan):

```bash
rclone lsl google:rclone/docker
```

Si falla con `invalid_grant`, hay que reconectar:

```bash
rclone config reconnect google:
```

Si `rclone` no está instalado, lo instala el playbook (`packages.yml`), pero **no**
comprueba que el token siga bueno.

## 7. Restaurar y arrancar

Baja los dos ficheros del último respaldo. **Los dos**: el MANIFEST es lo que
permite verificar el tarball, y sin él el restore avisa y prosigue sin comprobar
nada.

```bash
cd /opt/docker
rclone copy google:rclone/docker/docker-data.tar.gz .
rclone copy google:rclone/docker/MANIFEST.txt .
```

Mira qué va a restaurar antes de hacerlo:

```bash
sudo restore.sh --latest --dry-run
```

Y luego:

```bash
sudo restore.sh --latest
for dir in */; do (cd "$dir" && docker compose up -d); done
```

`restore.sh` **necesita root** y no es opcional: aplica `777` a los directorios y
`666` a los archivos de datos. Sin eso, lo que se restaura queda en 644 de un usuario
que no es el que escribe dentro del contenedor, y las apps fallan con
`attempt to write a readonly database` sin más explicación. Es el modo de fallo del
2026-09-26, que tumbó a la vez tres apps.

Sólo un stack, sin tocar los demás:

```bash
sudo restore.sh --latest --stack finanzas
```

Y para ensayar sin riesgo, a un directorio aparte:

```bash
sudo restore.sh --latest --to /mnt/prueba
ls -ld /mnt/prueba/vibecode/data     # debe decir 777
rm -rf /mnt/prueba
```

## Comprobar que quedó bien

```bash
docker ps --format '{{.Names}}\t{{.Status}}' | grep -v Up    # no debería listar nada
systemctl --failed --no-pager        # sin unidades fallidas
sudo ciber-secrets                   # credenciales completas
```

Y en el navegador, el dashboard y cada app.

## Qué NO vuelve de un respaldo

Nada del código: eso está en git, y es la razón de que el respaldo no lo incluya.
Tampoco:

| | Por qué |
|---|---|
| **El `.env` de los stacks** | A propósito. Va al gestor de contraseñas, no al Drive. |
| **Los puertos y rutas** | Vienen en el `.env`, y cambian de una máquina a otra. |
| **El disco externo** (`EXTERNO`) | Los stacks que lo montan son `deemix`, `jdown2`, `jelly`, `komga`, `navi`, `samba` y `torrent`. Sin el disco montado, Docker crea el punto de montaje vacío **y puede dejar el directorio con permisos de root**. Se ve enseguida, pero conviene saberlo antes. |
| **Los metadatos de Jellyfin** | 825 MB de carátulas, que se reconstruyen reescaneando la biblioteca. Lo que sí se guarda es su base de configuración, usuarios, historial y plugins. El reescaneo de ~780 GB tarda horas. |
| **`webtop`, `uptime-kuma`, `navi`, `torrent`, `scrutiny`** | `data-map.conf` los marca `OFF` con el motivo. `uptime-kuma` en concreto solo vale para las notificaciones mientras vive, no para un restore. |
| **`metube`** | No tiene almacenamiento persistente: su base vive en la capa del contenedor y se pierde al recrearlo. Aceptado a conciencia. |

## Si algo falla

```bash
# ¿Se intentó respaldar de verdad?
systemctl list-timers | grep backup        # el próximo disparo
journalctl -u backup.service -n 50

# ¿Qué se guardó de verdad?
head -30 /var/tmp/MANIFEST.txt             # inventario por stack

# ¿El respaldo estaba completo? Busca el bloque INCOMPLETO.
grep -A10 'INCOMPLETO' /var/tmp/MANIFEST.txt
```

Si el MANIFEST trae un bloque `INCOMPLETO`, a esa corrida le faltaron ficheros.
Casi siempre son `600 root`, y la solución es correr el respaldo con `sudo` en vez
de como tu usuario:

```bash
sudo backup-datos.sh
```

## Lo que este respaldo todavía no ha demostrado

Se probó siempre con `--to` a un directorio temporal: sha256 verificado contra el
MANIFEST, 16 stacks con permisos correctos y las cuatro bases copiadas pasando
`integrity_check`. Lo que **no** se ha probado es un restore completo sobre un
`/opt/docker` recién clonado, con los 37 stacks subiendo después. Si tienes una máquina
de sobra, ese es el ensayo que falta.
