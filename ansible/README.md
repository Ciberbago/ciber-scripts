# Playbook de Arch

## Instalación en una máquina limpia

```bash
bash <(curl -L url.jaimelopez.top/arch)
```

Eso instala Ansible, clona el repo y aplica el playbook de sistema. Después:

1. Reinicia y entra a GNOME
2. Abre una terminal y ejecuta `ciber-session`

El segundo paso existe porque `dconf`, `gsettings` y `gext` hablan por DBus con
la sesión del usuario. En un Arch recién instalado esa sesión no existe, así que
si se corrieran junto con el resto fallarían de formas confusas.

Por la misma razón, `session.yml` también instala las **AppImages** (AM registra
sus lanzadores en la rejilla de aplicaciones, y eso sólo prende bien con la
sesión abierta) y **oculta los lanzadores** de `gnome_hide_apps`. En el flujo
original de bash las dos cosas corrían desde `postinstall.sh`, después del
primer login; ponerlas en el playbook de sistema fue una regresión.

## Cómo cambiar cosas

Todo se edita en `group_vars/workstations_arch/`. Nunca hace falta tocar un rol
para el mantenimiento normal.

| Quiero… | Edito | Cuánto es |
|---|---|---|
| Agregar/quitar un paquete | `packages.yml` | 1 línea |
| Agregar un paquete del AUR | `packages.yml` → `aur_packages` | 1 línea |
| Agregar un dotfile | pongo el archivo en `dotfiles/` + `files.yml` | 1 línea |
| Agregar config a `/etc` | pongo el archivo en el repo + `files.yml` | 1 línea |
| Agregar config a `/etc` con variables | plantilla en `roles/system_files/templates/` + `files.yml` → `system_templates` | 1 línea |
| Agregar una unidad de systemd | dejo el `.service` en `systemd/` | **0 líneas** |
| Habilitar una unidad en boot | `systemd.yml` | 1 línea |
| Agregar un comando a `/usr/local/bin` | pongo el script en `scripts/` + `files.yml` | 1 línea |
| Cambiar un ajuste de GNOME | `gnome.yml` | 1 línea |
| Agregar una extensión de GNOME | `gnome.yml` | 1 línea |
| Agregar un alias de fish | `shell.yml` | 1 línea |
| Cambiar zona horaria, shell, timeouts | `main.yml` | 1 línea |

Después de editar, aplicas con `ciber-apply`. Si el cambio ya está en GitHub,
`ciber-apply` lo trae solo (hace `git pull` antes de aplicar).

### Unidades de systemd: por qué son 0 líneas

El rol `systemd_units` hace un glob sobre `systemd/` y copia todo lo que
encuentre (`.service .timer .mount .automount .socket .path .target`). No hay
lista de archivos que mantener. Solo si la unidad debe **arrancar en boot** se
agrega su nombre a `systemd_units_enabled`.

Los `.conf` que viven en `systemd/` (sysctl, zram, entradas de systemd-boot) no
son unidades y el glob no los toca: esos van en `files.yml` → `system_files`.

## Comandos

```bash
ciber-apply                     # reaplica todo el sistema
ciber-apply --check --diff      # simulacro: dice qué cambiaría, sin tocar nada
ciber-apply --tags packages     # solo paquetes
ciber-apply --tags systemd      # solo unidades de systemd
ciber-apply --list-tags         # ver todas las etiquetas
ciber-apply --start-at-task "Instalar paquetes de los repos oficiales"
ciber-session                   # config de GNOME (dentro de la sesión)
```

### Simulacro: `--check --diff`

Es la forma de ver **qué se desviaría del repo sin tocar nada**. Útil cuando
editaste un dotfile a mano y quieres saber en qué difiere del declarado.

```bash
ciber-apply --check --diff --tags dotfiles    # solo los dotfiles del $HOME
ciber-apply --check --diff --tags files       # dotfiles + /etc + /usr/local/bin
ciber-apply --check --diff                    # todo el sistema
ciber-session --check --diff --tags gnome     # dconf y extensiones
```

Por cada archivo que difiera imprime el diff unificado, en el sentido
"tu máquina → lo que dice el repo": las líneas `-` son lo que tienes de más y
las `+` lo que el repo pondría.

Para que esto funcione, las tareas `command` que sólo **consultan** estado
(`pacman -Qq`, `which gext`, `findmnt`…) llevan `check_mode: false`. Sin eso
Ansible las salta en modo check, sus registros quedan sin `rc`, y las
condiciones que dependen de ellos fallan a mitad del simulacro.

Dos cosas que `--check` no puede predecir, y es correcto que no lo haga:

- Lo que hacen los comandos que **sí** modifican (compilar del AUR, `am -i`):
  se saltan, porque ejecutarlos ya no sería un simulacro.
- Los efectos en cadena. Si el simulacro dice que instalaría 20 paquetes, no
  puede saber qué archivos traerían esos paquetes.

## Ver el progreso mientras corre

Ansible captura el stdout de cada módulo y lo imprime **cuando la tarea
termina**. En las tareas largas (pacman bajando paquetes, `makepkg` compilando
del AUR) eso son minutos sin una sola línea. No hay opción de configuración que
lo cambie: es cómo funciona el motor.

### Por qué no se usa `ansible-pull`

`ansible-pull` lanza `ansible-playbook` como subproceso conectado por un
**pipe** y va reenviando lo que lee. Ese hijo, al no ver una terminal, pasa de
line-buffering a block-buffering: la salida se acumula y aparece toda de golpe
al final. Daba igual qué hubiera del lado de afuera, porque el bufferado ocurría
entre `ansible-pull` y su hijo.

Lo único que `ansible-pull` aportaba era clonar o actualizar el checkout, que
son tres líneas de `git`. Tanto `arch.sh` como `ciber-apply` y `ciber-session`
hacen eso a mano y llaman a `ansible-playbook` directo, que sí imprime tarea por
tarea. Van envueltos en `script`, que da un pseudo-terminal: así la salida sale
en vivo **y** queda en `~/ciber.log`.

Ojo con una consecuencia: igual que hacía `ansible-pull`, el checkout se
sincroniza con `git checkout -qf`, o sea que **lo que edites dentro de
`~/.local/share/ciber-scripts` se pierde.** Edita en tu clon de trabajo y haz
push.

### Granularidad dentro de las tareas

Lo que sí ayuda, en orden de utilidad:

1. **`ciber-watch` en otra terminal.** Lee el log de pacman y los procesos de
   compilación en vivo. Es lo único que te dice qué está pasando *dentro* de una
   tarea. En la consola: Ctrl+Alt+F2 para otra TTY, Ctrl+Alt+F1 para volver.
2. **Las tareas "Que sigue - ..."** antes de cada tarea larga. Ansible ya imprime
   el nombre de la siguiente tarea, pero un nombre genérico no dice si va a
   tardar un segundo o nueve minutos. Estos avisos dicen qué va a hacer, cuántos
   elementos, cuánto suele tardar y dónde mirar el avance.
3. **El callback `profile_tasks`** (ya activo en `ansible.cfg`): imprime la
   duración de cada tarea y el acumulado, y al final el ranking de las más
   lentas. Te da el ritmo, no el detalle.
4. **Tareas con `loop` en vez de una llamada con la lista completa.** Cada
   elemento imprime su resultado al completarse. Por eso el rol `aur` instala
   los paquetes de chaotic uno por uno: en una sola llamada eran dos minutos
   mudos.

Si quieres las dos cosas en la misma pantalla, con `tmux`:

```bash
tmux new-session 'ciber-apply' \; split-window -v -p 25 'ciber-watch' \; attach
```

## Etiquetas

| Tag | Qué hace |
|---|---|
| `pacman`, `base` | pacman.conf, makepkg.conf, timezone, shell, grupos |
| `packages` | paquetes de repos oficiales |
| `user` | grupos extra y shell del usuario |
| `files` | dotfiles + config de /etc + comandos de /usr/local/bin |
| `system`, `dotfiles`, `tools` | subconjuntos de `files` |
| `systemd` | unidades |
| `boot` | entradas de systemd-boot (corre después de `aur`) |
| `shell`, `fish` | aliases y plugins de fish |
| `aur` | chaotic-aur, yay y paquetes del AUR |
| `cleanup` | huérfanos (site) / ocultar lanzadores (session) |
| `gnome` | (solo en `session.yml`) dconf y extensiones |
| `appimages` | (solo en `session.yml`) AM y AppImages |
| `hide` | (solo en `session.yml`) ocultar lanzadores |
| `firefox` | (solo en `session.yml`) perfil de Firefox |

## Estructura

```
ansible/
├── site.yml            playbook de sistema (sin sesión gráfica)
├── session.yml         playbook de GNOME (requiere estar en la sesión)
├── inventory.ini       localhost, conexión local
├── requirements.yml    colecciones de Ansible
├── ansible.cfg
├── group_vars/
│   ├── all/            común a cualquier distro (repo, rama, usuario, TZ)
│   └── workstations_arch/     >>> AQUÍ SE EDITA TODO <<<
│       ├── arch.yml     pacman, makepkg, chaotic, boot, AppImages
│       ├── packages.yml paquetes
│       ├── files.yml    dotfiles, /etc, /usr/local/bin
│       ├── systemd.yml  unidades a habilitar
│       ├── gnome.yml    dconf, extensiones, apps a ocultar
│       └── shell.yml    aliases y funciones de fish
└── roles/              lógica; casi nunca hay que tocarla
```

## Separación por distro

El repo aloja Arch y Debian, así que los archivos están separados:

```
dotfiles/{arch,debian,common}
scripts/{arch,debian,common,windows}
systemd/{arch,debian}
```

Y las variables, por grupo del inventario: `group_vars/all/` es lo común a
cualquier distro (de dónde se clona, la rama, el usuario, la zona horaria) y
`group_vars/workstations_arch/` es todo lo que sólo aplica a Arch. Cuando se
porte Debian, será añadir `group_vars/servers_debian/` sin tocar nada de esto.

Eso eliminó un parche: el rol `systemd_units` tenía una lista
`systemd_units_exclude` para que las unidades de Debian (`backup`, `todoist`) no
se instalaran en el Arch, porque todas convivían en `systemd/`. Ahora el glob
apunta a `systemd_units_dir` — `systemd/arch` aquí — y sólo ve lo que le toca.

Los archivos de configuración salen del repo clonado, no de URLs. Eso elimina la
causa raíz de la mitad de los bugs de la versión en bash: `wget -O` truncaba el
destino antes de saber si la descarga había servido, así que un typo en una URL
dejaba un archivo de 0 bytes y algo se rompía 40 líneas después sin decir por
qué. Ahora, si un archivo referenciado no existe en el repo, los roles fallan al
principio con la lista completa de lo que falta.

## Entradas de systemd-boot

El rol `boot_entries` genera **una entrada por kernel instalado**,
descubriéndolos de `/boot/vmlinuz-*`. Corre **después de `aur`** a propósito:
`linux-cachyos` lo instala ese rol desde chaotic, así que antes de él ese kernel
no existe y su entrada no se generaría hasta una segunda corrida. No hay lista ni plantilla que mantener: agregas un kernel a
`packages.yml` y su entrada aparece sola en la siguiente corrida; lo quitas y su
entrada se borra.

Sólo se generan para kernels que tengan `initramfs-<nombre>.img`. Un kernel sin
initramfs clásico está empaquetado como **UKI**, y systemd-boot ya lo encuentra
solo como entrada Type #2 — escribirle una Type #1 lo duplicaría en el menú. Eso
pasa con el kernel `linux` cuando `archinstall` lo configuró como UKI.

Las entradas propias se llaman `ciber-<kernel>.conf`. El prefijo importa: la
limpieza de entradas obsoletas sólo toca archivos que empiezan así, nunca las
que puso `archinstall` ni las que hayas escrito a mano.

Cada entrada rellena sola:

- el PARTUUID y el fstype de la partición montada en `/` (`findmnt` + `blkid`)
- el microcódigo del CPU, si existe alguna `/boot/*-ucode.img` (el rol
  `packages` instala `amd-ucode` o `intel-ucode` según el fabricante)
- el título, de `boot_entry_titles` en `main.yml`; si el kernel no está ahí, usa
  `Arch Linux (<kernel>)`

Y escribe la línea `default` en `loader.conf` con `boot_default_entry`. Sin ella
systemd-boot elige por orden de sorteo, así que agregar entradas cambiaría en
silencio con qué kernel arrancas. Ponla al id de una entrada que sepas que
arranca (`bootctl list`).

Para apagarlo todo: `boot_entries_enabled: false` en `main.yml`. Hazlo si tu
root está en LVM o LUKS, donde la detección del PARTUUID no aplica.

Ojo con el espacio de la ESP: cada kernel son decenas de MB entre `vmlinuz` e
`initramfs`, y con UKI más. Revisa con `df -h /boot`.

## AppImages (AM)

Se instalan en **modo local** (`am -i --user`), no a nivel sistema. Tres razones,
todas descubiertas depurando en una máquina real:

- El instalador de AM se hace dueño de `/opt/am` para el usuario invocante, o sea
  que AM está diseñado para correr como usuario normal. Con `become: true` la
  tarea fallaba con `sudo: a password is required`.
- En modo local los `.desktop` van a `~/.local/share/applications`, que es donde
  GNOME construye la rejilla del usuario. Instalando como root los lanzadores no
  aparecían en Actividades.
- Los enlaces quedan en `~/.local/bin`, que el playbook agrega al PATH de fish
  vía `fish_paths` en `shell.yml`.

Lo que hacía imposible automatizarlo: **la primera vez, `am -i --user` lanza un
asistente interactivo** preguntando dónde instalar. Sin TTY se quedaba colgado.
El rol escribe `~/.config/appman/appman-config` antes de instalar nada, con la
ruta de `appimage_install_path`, y así el asistente nunca aparece.

Ese archivo **no se sobrescribe** si ya existe: AM exige desinstalar todo antes
de mover la ubicación. Si no coincide con `appimage_install_path`, el rol avisa
en lugar de romper las apps instaladas.

Sólo aplican al usuario que corre `ciber-session`. Si alguna app tiene que estar
disponible para todos los usuarios, ésa va aparte con instalación de sistema.

## Orden de instalación y desinstalación

`pacman_remove` se aplica **al principio** del rol `packages`, antes de instalar
nada. No es un detalle: al reemplazar un paquete del AUR por su equivalente
oficial (`headsetcontrol-git` → `headsetcontrol`), pacman aborta la transacción
entera con `unresolvable package conflicts detected`. Si la desinstalación
corriera al final —como estaba— nunca se llegaría a ella.

La limpieza de **huérfanos** sí va al final, en `pkg_cleanup`: sólo entonces se
sabe qué quedó realmente sin usar.

Y antes de instalar, el rol compara la lista declarada contra `pacman -Slq` y
reporta los nombres que no existen en ningún repo configurado, instalando el
resto. Sin eso, un solo nombre mal escrito o renombrado hace fallar la
instalación de los cien restantes.

## Notas sobre partes delicadas

**AUR.** `makepkg` se niega a correr como root, pero necesita sudo para instalar
dependencias, y `ansible-pull` no es una terminal interactiva donde yay pueda
pedir el password. El rol `aur` resuelve esto con un permiso NOPASSWD temporal
limitado a `/usr/bin/pacman` y a tu usuario, que se retira **siempre** al final
(bloque `always`), incluso si la compilación falla.

Antes de agregar algo a `aur_packages`, revisa si está en chaotic-aur: es el
mismo paquete ya compilado, se instala en segundos con pacman en lugar de
minutos compilando, y no necesita nada del permiso temporal.

**`dconf load`.** No hay forma de consultar el estado previo de un volcado
completo, así que esas tareas no son idempotentes de verdad y van marcadas
`changed_when: false` para no ensuciar el resumen. Las teclas individuales de
`gnome_dconf` sí son idempotentes: el módulo lee el valor actual y solo escribe
si difiere.

**Aliases de fish.** Se generan a `~/.config/fish/conf.d/ciber.fish` y no con
`funcsave`. `funcsave` escribe un archivo por función en `functions/` que después
nunca se sincroniza con el repo: si borras un alias de aquí, el de la máquina
seguiría vivo para siempre. Con un solo archivo generado, el repo es la única
verdad. El rol además borra los `functions/*.fish` que dejó el script viejo,
porque si se quedan, las dos definiciones compiten y gana la de `functions/`.

## Fallback

La versión anterior en bash puro está en `legacy/arch-bash.sh`, con sus bugs
corregidos. Si algo del playbook no funciona, sigue siendo usable.
