# Por qué el playbook de Arch está así

El [README](../ansible/README.md) es para hacer cosas. Esto es lo que hay detrás:
las decisiones, el histórico, y las tablas de referencia.

Se separó del README después de escribirlo todo junto. Estaba completo, pero
recorrerlo de arriba abajo no es la forma de encontrar un comando. Nada de lo que
hay aquí se reescribió al moverlo.

Las tablas de referencia (AppImages, systemd-boot, estructura de ficheros) viven
aquí a propósito: son de consulta, no de lectura seguida.

---

## La trampa de dconf: el id del esquema no es la ruta

`dconf write` **no valida nada**. Escribe la ruta que le des, exista o no un
esquema detrás, y devuelve éxito. El módulo `dconf` de Ansible hace lo mismo:
reporta `ok`, el valor queda guardado en la base, y GNOME nunca se entera.

El caso real: el repo declaraba

```yaml
- { key: /org/gnome/SessionManager/logout-prompt, value: "false" }
```

El esquema se llama `org.gnome.SessionManager`, así que la ruta parecía
evidente. No lo era:

```xml
<schema id="org.gnome.SessionManager" path="/org/gnome/gnome-session/">
```

El id y la ruta son cosas distintas y aquí no coinciden. El ajuste estuvo meses
sin aplicarse mientras el playbook informaba éxito en cada corrida. Se detectó
por casualidad, al notar que la confirmación al apagar seguía saliendo.

La señal que lo delata: `dconf read` y `gsettings get` devuelven valores
distintos para la "misma" clave.

```bash
dconf read /org/gnome/SessionManager/logout-prompt    # false
gsettings get org.gnome.SessionManager logout-prompt  # true
```

Para que no vuelva a pasar, el rol `gnome_session` corre
`scripts/common/dconf-validate.py` sobre **todas** las claves de `gnome_dconf` y
las rutas de `gnome_dconf_loads`, y reporta las que no tienen esquema detrás.
Cuando el nombre de la clave sí existe en otro esquema, dice cuál: normalmente
esa es la ruta que hacía falta.

```
Claves dconf que NO hacen nada (1 de 24):
  /org/gnome/SessionManager/logout-prompt
      no hay ningun esquema en /org/gnome/SessionManager/
      'logout-prompt' si existe en: /org/gnome/gnome-session/
```

No falla la corrida y no cambia nada: solo informa. Puede haber claves de
extensiones que aún no estaban instaladas en esa pasada.

Para averiguar a mano la ruta de un esquema:

```bash
grep -rn 'id="org.gnome.LoQueSea"' /usr/share/glib-2.0/schemas/*.xml
```

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

## Config de plugins de fish (tide)

Plugins como **tide** no guardan su configuración en un archivo propio: la
escriben como **variables universales de fish** (`tide_*` y `_tide_*`), que viven en
`~/.config/fish/fish_variables`. Ese archivo no se puede versionar tal cual —
mezcla las de tide con `fish_color_*`, `EDITOR`, la lista de plugins de fisher
y demás.

Para capturar la config desde una máquina que ya la tiene como quieres:

```bash
fish scripts/common/fish-dump-universals.fish > dotfiles/common/tide.fish
```

Sin argumentos captura tide. Se excluye `_tide_prompt_*`: ahí tide cachea el
prompt **ya renderizado**, con el hostname y la hora de la máquina donde se
generó, y lo regenera solo. Para otro plugin se le pasan patrones (glob de
`string match`; los que empiezan con `!` excluyen).

Eso genera un archivo de líneas `set -U` reaplicables. Se declara en
`shell.yml`:

```yaml
fish_universal_files:
  - { src: dotfiles/common/tide.fish, nombre: "tema tide" }
```

Para tide se omite `patron` a propósito, para que el archivo que generas a mano
y el volcado con el que el rol lo compara usen los mismos patrones por defecto.
Con patrones distintos a cada lado, la tarea quedaría marcada como `changed` en
todas las corridas.

El rol `shell_fish` lo aplica **después** de instalar los plugins (si fuera
antes, la instalación de tide sobrescribiría sus propias variables con los
defaults), y sólo cuando el estado actual difiere del declarado: usa el mismo
script para leer la máquina, así que la comparación es exacta.

Sirve para cualquier plugin que use variables universales, cambiando el patrón.

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

---

## Cuando una tarea tarda: cómo ver el progreso

El playbook deja algunos avisos "Que sigue - ..." antes de las tareas largas, y
`ciber-watch` da el progreso en vivo desde otra terminal. Lo que ayuda, en orden:

1. **`ciber-watch` en otra terminal.** Lee el log de pacman y los procesos de
   compilación en vivo. Es lo único que dice qué pasa *dentro* de una tarea. Para
   verla sin salir: `Ctrl+Alt+F2` a otra TTY y `Ctrl+Alt+F1` para volver.
2. **Los avisos "Que sigue - ...".** Ansible ya imprime el nombre de la siguiente
   tarea, pero un nombre genérico no dice si tarda un segundo o nueve minutos.
   Estos dicen qué va a hacer, cuántos elementos y dónde mirar.
3. **El callback `profile_tasks`** (activo en `ansible.cfg`): duración por tarea,
   acumulado, y ranking final. Da el ritmo, no el detalle.
4. **Tareas con `loop`** en vez de una llamada con la lista entera: cada elemento
   imprime su resultado al completarse. Por eso el rol `aur` instala los paquetes
   de chaotic uno por uno: en una sola llamada eran dos minutos mudos.

Las dos cosas en la misma pantalla, con tmux:

```bash
tmux new-session 'ciber-apply' \; split-window -v -p 25 'ciber-watch' \; attach
```

---

