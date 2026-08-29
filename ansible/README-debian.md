# Playbook de Debian 12

## Instalación en una máquina limpia

```bash
wget -O - url.jaimelopez.top/debian | bash
```

Eso instala Ansible, clona el repo y aplica `site-debian.yml`. Todo corre sin
sesión gráfica, así que se puede hacer por SSH.

Al terminar quedan dos pasos manuales:

1. **Cerrar sesión y volver a entrar.** El grupo `docker` y el shell `fish`
   aplican en el próximo login, no en el actual.
2. **`sudo tailscale up`.** El playbook instala y habilita `tailscaled`, pero no
   lo conecta: `tailscale up` abre un navegador para autenticar. Hacerlo sin
   interacción exigiría guardar una *auth key* dentro del repo.

A diferencia de Arch, aquí **no hay `ciber-session`**: ese comando configura
GNOME y en un servidor no hay escritorio.

## Cómo cambiar cosas

Todo se edita en `group_vars/workstations_debian/`. Nunca hace falta tocar un rol
para el mantenimiento normal.

| Quiero… | Edito | Cuánto es |
|---|---|---|
| Agregar/quitar un paquete | `packages.yml` | 1 línea |
| Agregar un dotfile | pongo el archivo en `dotfiles/debian/` + `files.yml` | 1 línea |
| Agregar config a `/etc` | pongo el archivo en el repo + `files.yml` → `system_files` | 1 línea |
| Agregar un comando a `/usr/local/bin` | pongo el script en `scripts/debian/` + `files.yml` | 1 línea |
| Agregar una unidad de systemd | dejo el `.service` en `systemd/debian/` | **0 líneas** |
| Habilitar una unidad en boot | `systemd.yml` | 1 línea |
| Agregar un alias de fish | `shell.yml` (y aparece solo en `ciber-help`) | 1 línea |
| Describir un comando en la ayuda | campo `desc:` en `files.yml` | 1 línea |
| Cambiar la versión de Docker/Tailscale/neovim | `services.yml` | 1 línea |
| Declarar un secreto nuevo | `secrets.yml` (sólo el nombre de la clave, **nunca el valor**) | 1 línea |
| Desactivar Docker o Tailscale por completo | `services.yml` → `docker_enabled: false` | 1 línea |
| Cambiar zona horaria o shell | `group_vars/all/main.yml` | 1 línea |

### Unidades de systemd: por qué son 0 líneas

El rol `systemd_units_debian` hace un glob sobre `systemd/debian/` y copia todo
lo que encuentre a `/etc/systemd/system/`. Las unidades **de usuario**
(`systemctl --user`) van en `systemd/debian/user/` y terminan en
`~/.config/systemd/user/`. No hay lista de archivos que mantener; sólo si la
unidad debe **arrancar en boot** se agrega su nombre a `systemd.yml`.

El rol también ejecuta `loginctl enable-linger`. Sin eso, las unidades `--user`
mueren al cerrar la sesión SSH: el timer de Todoist "funcionaba" mientras
probabas y se detenía al desconectarte.

## Comandos

Lo primero que conviene saber es que **no hace falta memorizar esta lista**:

```bash
ciber-help          # todo lo instalado, con colores y descripciones
ciber-help docker   # filtrado por un termino
```

`ciber-help` **no es un texto escrito a mano**. Se genera en cada `ciber-apply`
recorriendo `cli_tools`, `fish_aliases`, `fish_functions` y `ciber_tags` de los
`group_vars`, así que un alias nuevo aparece solo. Además comprueba que cada
comando exista en el `PATH` antes de anunciarlo: nunca lista algo que no está.

Respeta `NO_COLOR` y desactiva el color al redirigir la salida, así que
`ciber-help | grep foo` funciona sin secuencias de escape.

El resto:

```bash
ciber-apply                     # reaplica todo
ciber-apply --check --diff      # simulacro: dice qué cambiaría, sin tocar nada
ciber-apply --tags packages     # solo paquetes
ciber-apply --tags docker       # solo Docker
ciber-apply --tags systemd      # solo unidades de systemd
ciber-apply --list-tags         # ver todas las etiquetas
ciber-watch                     # progreso en vivo, desde otra sesión SSH
```

## Qué comparte con Arch y qué no

Se **reutilizan sin modificar** los roles que ya eran agnósticos de distro:
`dotfiles`, `system_files`, `user_setup` y `shell_fish`. Se alimentan con los
`group_vars` de Debian y ni se enteran de en qué distro están.

Tienen **gemelo propio** dos roles, y en los dos casos por una razón concreta,
no por gusto:

| Rol de Debian | Por qué no se reutiliza el de Arch |
|---|---|
| `systemd_units_debian` | El de Arch usa `ansible.builtin.systemd_service`, que existe desde ansible-core **2.16**. Debian 12 empaqueta ansible-core **2.14**: con ese módulo el playbook ni arranca. El gemelo usa `ansible.builtin.systemd`, que funciona en las dos. |
| `cli_tools_debian` | El de Arch instala `ciber-session` (configuración de GNOME, inútil en un servidor) y su `ciber-apply` apunta a `site.yml`. |

Son **exclusivos de Debian**: `apt_setup`, `packages_apt`, `docker`, `tailscale`,
`neovim` y `fisher`.

### Otras diferencias por la versión vieja de ansible-core

Además de `systemd_service`, tampoco están disponibles en 2.14:

- `ansible.builtin.deb822_repository` (desde 2.15) → se usa `apt_repository`
  con una llave en `/etc/apt/keyrings` y `signed-by=`.
- El filtro `split` de Jinja → se saca el primer campo con `awk` en la shell.

## Bugs del script de bash que quedan corregidos

| Bug | Efecto que tenía | Cómo queda |
|---|---|---|
| `newgrp docker` a mitad del script | `newgrp` **reemplaza** el shell: el clone de `ciber-docker`, los plugins de neovim, el `chsh` a fish, los timers y los 15 aliases **nunca se ejecutaban** | El grupo se asigna con el módulo `user` y aplica en el próximo login |
| `systemctl --user enable todoist-check.timer` | El archivo descargado se llamaba `todoist-precise.timer`: el enable fallaba **siempre** | El nombre sale de `systemd.yml` y el rol verifica que la unidad exista |
| `funcsave subirrtl88xxau-aircrack-dkms-git` | Un nombre de paquete de Arch pegado por copy/paste: la función `subir` nunca se guardaba | Los aliases se generan desde una lista YAML a `conf.d/ciber.fish` |
| `fisher install …` sin instalar fisher | Los tres plugins fallaban con "Unknown command" | El rol `fisher` corre antes que `shell_fish` |
| `dl … /usr/local/bin/backup.sh` sin sudo | Permiso denegado: `backup.service` apuntaba a un archivo inexistente | El rol `cli_tools_debian` escribe con `become: true` |
| `git clone /opt/docker` sin guarda | Fallaba en la segunda corrida ("directory not empty") | Módulo `git`, idempotente |
| `chown jaime /opt/docker` | Usuario hardcodeado | `owner: {{ ciber_user }}` |
| `sed` sobre `sources.list` | Perdía `contrib`, y reescribía el archivo en cada corrida | `apt_components` declarativo; la segunda corrida sale verde |
| Sin shebang | Ejecutado directamente corría con `dash`, donde sus arrays y `[[ ]]` no existen | `#!/usr/bin/env bash` |
| `Type=oneshot # comentario` en `backup.service` | systemd **no** admite comentarios al final de una directiva, así que descartaba el valor con un warning y aplicaba el default (`Type=simple`). El backup **sí corría**; el efecto era ruido en el journal y un tipo de servicio distinto al pretendido | Comentarios en su propia línea, más `TimeoutStartSec=infinity` (ver nota abajo) |
| Sin `enable-linger` | **No es un bug, es un cambio de comportamiento.** En el servidor `Linger=no`: el timer de Todoist sólo corre mientras hay una sesión abierta | `systemd_user_linger: true` en `systemd.yml`. Ponlo en `false` para dejarlo como está |
| `curl \| sh` para Docker y Tailscale | Quedaban fuera de `apt upgrade`; había que reinstalar a mano | Repos APT oficiales con llave verificada |

### Nota sobre `Type=` en `backup.service`

Corregir el comentario en línea cambia el comportamiento efectivo de la unidad, y
no de forma inocua. Con el valor inválido descartado, la unidad corría como
`Type=simple`: systemd la da por arrancada en cuanto existe el proceso y **no le
aplica ningún límite de tiempo**.

Con `Type=oneshot` la unidad se queda en estado "activando" mientras el script
corre, y ahí **sí** aplica `TimeoutStartSec`, cuyo default son **90 segundos**.

Medido en el servidor el 2026-08-27:

```
ExecMainStartTimestamp = 18:00:01
ExecMainExitTimestamp  = 19:01:16     -> 3675 s
```

3675 segundos contra un límite de 90. Escribir `Type=oneshot` "bien" y nada más
habría matado el respaldo a los 90 segundos, cada noche, sin aviso. De ahí el
`TimeoutStartSec=infinity` explícito.

Efecto secundario a tener presente: con `oneshot`, un `systemctl start
backup.service` a mano **bloquea la terminal una hora**. Usa `--no-block`.

Si prefieres cero cambios respecto a lo que corre hoy, borra las líneas `Type=` y
`TimeoutStartSec=`: sin `Type=` el default es `simple`, que es como ha estado
corriendo desde siempre.

Tampoco se tocó `After=network.target`: cambiarlo a `network-online.target`
arrastra un servicio *wait-online* y puede retrasar el arranque, sin aportar
nada a un timer que dispara a las 18:00. `systemd-analyze verify` confirmó que
lo único que producía esa línea eran warnings de dependencia sobre `#`,
`Opcional:`, `Asegura`, `que`, `la`, `red`… todos ignorados.

## Secretos: por qué no hay ningún token en este repo

`backupdebian.sh` llevaba el token del bot de Telegram escrito dentro, en un
repositorio **público**. `todoist.sh` usaba el enfoque contrario: marcadores
(`todotoken`, `telegramtoken`) en el repo y los valores reales puestos a mano en
la máquina.

El segundo parece más seguro, pero traía su propia trampa: el repo dejaba de
reflejar lo que corría de verdad, y en cuanto algo copiara el script del repo
encima —que es exactamente lo que hace `cli_tools_debian`— el notificador se
quedaba con los marcadores y dejaba de avisar, sin ningún error visible.

La solución es sacar el secreto del repo, no esconderlo dentro:

| Quién lo lee | Dónde vive | Permisos |
|---|---|---|
| Unidad de **sistema** (`backup.service`, corre como root) | `/etc/ciber/backup.env` | `root:root` `0600` |
| Unidad de **usuario** (`todoist-precise.service`) | `~/.config/ciber/todoist.env` | usuario, `0600` |

La separación no es cosmética: una unidad `--user` no puede leer un `0600`
propiedad de root.

Cada unidad lo inyecta con `EnvironmentFile=`, y el script además hace `source`
del archivo para cuando se ejecuta a mano. Los dos scripts abortan con un
mensaje explícito si falta una variable:

```sh
: "${TELEGRAM_TOKEN:?falta TELEGRAM_TOKEN en /etc/ciber/backup.env}"
```

### Qué hace Ansible y qué no

El rol `env_files` crea los archivos **vacíos una sola vez**, con `force: false`.
Esa opción es la línea importante del rol: sin ella, cada `ciber-apply` borraría
el token que escribiste a mano y el respaldo dejaría de notificar esa misma
noche. Ansible nunca conoce los valores, así que no hay nada que cifrar.

Después comprueba si quedan claves sin rellenar y lo avisa durante el apply. Un
token vacío no falla de forma ruidosa —el `curl` sale con éxito y el mensaje
simplemente no llega—, así que conviene enterarse mientras estás mirando la
pantalla y no tres días después.

### El aviso: tres sitios donde no se puede pasar por alto

Un `.env` recién creado está vacío, y los scripts usan la forma
`${VAR:?mensaje}` — con dos puntos, que aborta **también si la variable está
vacía**, no sólo si falta. Así que hasta que pongas los valores,
`backup.service` y `todoist-precise.service` **fallan al arrancar**. Es el
comportamiento deseable (un fallo visible es mejor que un respaldo mudo), pero
hay que enterarse, así que se avisa por triplicado:

1. **Durante el apply**, cuando el rol `env_files` detecta claves vacías.
2. **Al final del playbook**, en un bloque `ACCIÓN REQUERIDA` justo antes del
   resumen — lo último que queda en pantalla.
3. **Cuando quieras**, con el comando `ciber-secrets`, que lista archivo por
   archivo qué falta y sale con código 1 si hay algo pendiente.

Y si aun así se te pasa, `systemctl --failed` lo muestra.

### Puesta en marcha en una máquina nueva

```bash
sudo ciber-apply                    # crea los .env vacíos
sudo micro /etc/ciber/backup.env    # pon TELEGRAM_TOKEN y TELEGRAM_CHAT_ID
micro ~/.config/ciber/todoist.env   # pon los tres de Todoist
sudo ciber-secrets                  # confirma que no falta nada
```

### Migrar una máquina que ya funcionaba

Cuidado con el orden. En el servidor actual los tokens están **dentro** de los
scripts, y el primer `ciber-apply` los sustituye por las versiones que los leen
del `.env`. Entre ese momento y el instante en que rellenas los archivos **no
hay respaldo ni notificaciones**.

El hueco debe durar minutos, no días. Si aplicas por la tarde, rellena los
`.env` antes de las 18:00 o pierdes el respaldo de esa noche.

```bash
sudo ciber-apply --tags secrets      # sólo crea los .env, no toca los scripts
sudo micro /etc/ciber/backup.env     # rellena
micro ~/.config/ciber/todoist.env    # rellena
sudo ciber-secrets                   # confirma
sudo ciber-apply                     # ahora sí, el resto
```

Aplicando `--tags secrets` primero, los scripts viejos con el token dentro
siguen corriendo mientras preparas los archivos, y el hueco es cero.

### Por qué no `ansible-vault`

Es la respuesta canónica de Ansible y es válida, pero obliga a teclear la
contraseña del vault en **cada** `ciber-apply`, o a guardarla en un archivo —que
es el mismo problema movido de sitio—. Para un secreto que se pone una vez por
servidor y no cambia, no compensa.

Tampoco sirve poner el `.env` dentro del repo y añadirlo al `.gitignore`: un
archivo ignorado sigue viviendo en el clon que `ciber-apply` sobrescribe con
`git checkout -qf`, así que se perdería en el primer apply. El `*.env` del
`.gitignore` es una red de seguridad, no el mecanismo.

### El mismo comando en las dos distros

La plantilla vive en `ansible/templates/ciber-help.j2`, **fuera** de los roles,
y la renderizan tanto `cli_tools_debian` como el `cli_tools` de Arch, cada uno
con sus propias variables. Un solo archivo, dos salidas distintas: en Arch
aparecen `ciber-session`, `wallpaper`, `archbootgen` y las etiquetas `aur` y
`boot`; en Debian, `ciber-secrets`, `backup.sh` y las de `docker` y `secrets`.

Detecta en tiempo de ejecución qué comandos existen en el `PATH`, así que
tampoco anuncia nada que no esté instalado en esa máquina concreta.
