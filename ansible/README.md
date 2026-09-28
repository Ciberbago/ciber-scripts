# Playbook de Arch

Sistema, paquetes, AUR, AppImages y GNOME de la máquina de juegos.

El de Debian, que es el otro servidor, está en
[`README-debian.md`](README-debian.md).

## Dos trampas antes de nada

- **Nunca `sudo-appscript`.** Corriendo como root el checkout y los dotfiles
  acaban en `/root`, y el comando se regenera apuntando ahí.
- **`appscript` descarta lo que tengas sin comitear** en el clon: hace
  `git checkout -qf` contra el remoto. Edita, `git push`, y solo entonces aplica.

## Lo que hago

| Quiero… | |
|---|---|
| Ver qué hay instalado | `ciber-help` |
| Ver una parte de esa lista | `ciber-help aur` |
| Aplicar cambios | `ciber-apply` |
| Ver qué cambiaría sin tocar nada | `ciber-apply --check --diff` |
| Reaplicar solo una parte | `ciber-apply --tags packages` |
| Ver las etiquetas | `ciber-apply --list-tags` |
| Ver el progreso, en otra terminal | `ciber-watch` |
| Terminar la config de GNOME | `ciber-session` (dentro de la sesión) |
| Montar un disco de datos | `sudo ciber-disco` (menú; los discos no van en el playbook) |
| Ver los discos sin tocar nada | `ciber-disco list` |
| Averiguar por qué no monta algo | `sudo disks-diagnostico` (informe de solo lectura) |

## Instalación en una máquina limpia

```bash
bash <(curl -L url.jaimelopez.top/arch)
```

Eso instala Ansible, clona el repo y aplica el playbook de sistema. Después:

1. Reinicia y entra a GNOME
2. Abre una terminal y ejecuta `ciber-session`

El segundo paso existe porque `dconf`, `gsettings` y `gext` hablan por DBus con la
sesión del usuario, que en un Arch recién instalado todavía no existe. Por lo mismo
`session.yml` instala las AppImages y oculta los lanzadores: registration y rejilla
de aplicaciones solo prenden con la sesión abierta.

## Cambiar algo

Todo se edita en `group_vars/workstations_arch/`. Nunca hace falta tocar un rol
para el mantenimiento normal.

## Cómo cambiar cosas

Todo se edita en `group_vars/workstations_arch/`. Nunca hace falta tocar un rol
para el mantenimiento normal.

| Quiero… | Edito | Cuánto es |
|---|---|---|
| Agregar/quitar un paquete | `packages.yml` | 1 línea |
| Agregar un paquete del AUR | `packages.yml` → `aur_packages` | 1 línea |
| Agregar un PKGBUILD propio | carpeta en `pkgbuilds/` + `packages.yml` → `local_packages` | 1 línea |
| Agregar un dotfile | pongo el archivo en `dotfiles/` + `files.yml` | 1 línea |
| Agregar config a `/etc` | pongo el archivo en el repo + `files.yml` | 1 línea |
| Agregar config a `/etc` con variables | plantilla en `roles/system_files/templates/` + `files.yml` → `system_templates` | 1 línea |
| Agregar una unidad de systemd | dejo el `.service` en `systemd/` | **0 líneas** |
| Habilitar una unidad en boot | `systemd.yml` | 1 línea |
| Agregar un comando a `/usr/local/bin` | pongo el script en `scripts/` + `files.yml` | 1 línea |
| **Montar un disco de datos** | **nada: `sudo ciber-disco`** | **a mano, 1 vez** |
| Cambiar un ajuste de GNOME | `gnome.yml` | 1 línea |
| Agregar una extensión de GNOME | `gnome.yml` | 1 línea |
| Agregar un alias de fish | `shell.yml` | 1 línea |
| Guardar la config de un plugin de fish | volcar con `fish-dump-universals.fish` + `shell.yml` | 1 línea |
| Agregar un archivo de credenciales | `credentials.yml` | 1 entrada |
| Cambiar zona horaria, shell, timeouts | `main.yml` | 1 línea |

Después de editar, aplicas con `ciber-apply`. Si el cambio ya está en GitHub,
`ciber-apply` lo trae solo (hace `git pull` antes de aplicar).

### Discos de datos: por qué NO están en el playbook

Es la única cosa del sistema que no se declara en ningún archivo de
configuración, y es deliberado.

`/etc/fstab` no sobrevive a un respaldo: es por máquina, y un UUID escrito en
git acaba siendo el de otro equipo. Peor aún, un UUID que no corresponde al
disco conectado **deja el sistema en emergency shell en cada arranque**,
esperando un disco que no va a aparecer, con una consola de emergencia y
nada más.

Así que el playbook instala el comando y ya:

```bash
sudo ciber-disco        # menú: elige el disco, el punto de montaje, y listo
ciber-disco list        # qué hay declarado, qué falta, qué no está montado
```

El menú escribe `UUID=` (no `/dev/sdX`, que depende del orden de detección) y
`nofail` con `x-systemd.device-timeout=10` (para que un disco desconectado no
espere los 90 segundos por defecto). Antes de dejar la línea puesta compara los
errores de `findmnt --verify` con los que ya había: si el cambio no empeora el
archivo, lo acepta aunque el fstab ya viniera roto.

Lo único que **no** hace es tocar las entradas de `/`, `/boot` y los `swap`:
solo edita líneas suyas, las que marcó con `#ciber-disco`.

### Unidades de systemd: por qué son 0 líneas

El rol `systemd_units` hace un glob sobre `systemd/` y copia todo lo que
encuentre (`.service .timer .mount .automount .socket .path .target`). No hay
lista de archivos que mantener. Solo si la unidad debe **arrancar en boot** se
agrega su nombre a `systemd_units_enabled`.

Los `.conf` que viven en `systemd/` (sysctl, zram, entradas de systemd-boot) no
son unidades y el glob no los toca: esos van en `files.yml` → `system_files`.

## Credenciales

Ningún token está en este repo. En Arch, los de servicios de usuario van en
`~/.config/ciber/*.env` y los installs los leen de ahí. El playbook los crea
vacíos y avisa de los que queden sin rellenar; compruébalo con:

```bash
ciber-secrets
```

La separación de permisos entre unidad de sistema y de usuario está explicada en
[`por-que-debian.md`](../docs/por-que-debian.md), que aplica igual aquí.

## PKGBUILDs propios

Las recetas viven en `pkgbuilds/<pkgname>/PKGBUILD` y se declaran en
`packages.yml` con `local_packages`. Se compilan con `makepkg` y quedan como
cualquier otro paquete (`pacman -Qm`). Para actualizar una: sube `pkgver`/`pkgrel`
y vuelve a aplicar, que el rol solo recompila cuando la versión difiere.

Los detalles y las limitaciones están en
[`pkgbuilds/README.md`](../pkgbuilds/README.md).

## Etiquetas

| Tag | Qué hace |
|---|---|
| `pacman`, `base` | pacman.conf, makepkg.conf, timezone, shell, grupos |
| `packages` | paquetes de repos oficiales |
| `user` | grupos extra y shell del usuario |
| `credentials` | archivos de secretos con valores de ejemplo + aviso si siguen sin rellenar |
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

## Si algo va mal

| Síntoma | Dónde mirar |
|---|---|
| El playbook falla a mitad | el log que indica `ciber-apply` |
| Un servicio no arranca | `systemctl --failed` |
| Faltan credenciales | `ciber-secrets` |
| Un AppImage no aparece en la rejilla | hay que estar dentro de la sesión, no por SSH |

## Más detalle

- [`docs/por-que-arch.md`](../docs/por-que-arch.md) — la trampa de `dconf`, la
  estructura de ficheros, systemd-boot, AppImages, y el histórico de decisiones
- [`pkgbuilds/README.md`](../pkgbuilds/README.md) — tus recetas propias
- El servidor Debian: [`README-debian.md`](README-debian.md)
