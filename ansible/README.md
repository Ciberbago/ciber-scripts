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

## Cómo cambiar cosas

Todo se edita en `group_vars/all/`. Nunca hace falta tocar un rol para el
mantenimiento normal.

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

`--check --diff` es el que más vas a usar: te muestra el diff exacto de cada
archivo que cambiaría antes de tocar nada.

## Etiquetas

| Tag | Qué hace |
|---|---|
| `pacman`, `base` | pacman.conf, makepkg.conf, timezone, shell, grupos |
| `packages` | paquetes de repos oficiales |
| `user` | grupos extra y shell del usuario |
| `files` | dotfiles + config de /etc + comandos de /usr/local/bin |
| `system`, `dotfiles`, `tools` | subconjuntos de `files` |
| `systemd` | unidades |
| `shell`, `fish` | aliases y plugins de fish |
| `aur` | chaotic-aur, yay y paquetes del AUR |
| `appimages` | AM y AppImages |
| `cleanup` | ocultar lanzadores, quitar paquetes y huérfanos |
| `gnome` | (solo en `session.yml`) dconf y extensiones |
| `firefox` | (solo en `session.yml`) perfil de Firefox |

## Estructura

```
ansible/
├── site.yml            playbook de sistema (sin sesión gráfica)
├── session.yml         playbook de GNOME (requiere estar en la sesión)
├── inventory.ini       localhost, conexión local
├── requirements.yml    colecciones de Ansible
├── ansible.cfg
├── group_vars/all/     >>> AQUÍ SE EDITA TODO <<<
│   ├── main.yml        ajustes generales
│   ├── packages.yml    paquetes
│   ├── files.yml       dotfiles, /etc, /usr/local/bin
│   ├── systemd.yml     unidades a habilitar y excluir
│   ├── gnome.yml       dconf, extensiones, apps a ocultar
│   └── shell.yml       aliases y funciones de fish
└── roles/              lógica; casi nunca hay que tocarla
```

Los archivos de configuración salen del repo clonado, no de URLs. Eso elimina la
causa raíz de la mitad de los bugs de la versión en bash: `wget -O` truncaba el
destino antes de saber si la descarga había servido, así que un typo en una URL
dejaba un archivo de 0 bytes y algo se rompía 40 líneas después sin decir por
qué. Ahora, si un archivo referenciado no existe en el repo, los roles fallan al
principio con la lista completa de lo que falta.

## Entradas de systemd-boot

**Vienen apagadas: `boot_entries_enabled: false` en `main.yml`.** El modo de
fallo de esta parte es "la máquina no arranca", así que se activa a mano por
máquina.

Los archivos `systemd/cachyos.conf` y `systemd/lts.conf` del repo tenían
`root=PARTUUID=[UUIDDISCODELKERNELBUENO sudo blkid]` — recordatorios para
editarlos a mano — y un `initrd /amd-ucode.img` fijo. El script de bash los
copiaba tal cual a `/boot/loader/entries/`; un `initrd` inexistente hace que
systemd-boot falle la entrada completa.

Ahora son plantillas en `roles/system_files/templates/` que rellenan:

- el PARTUUID y el fstype de la partición montada en `/` (`findmnt` + `blkid`)
- el microcódigo del CPU, si existe alguna `/boot/*-ucode.img` (y el rol
  `packages` instala `amd-ucode` o `intel-ucode` según el fabricante)

Antes de poner `boot_entries_enabled: true` necesitas:

1. Usar entradas Type #1, no UKI. Si `bootctl list` muestra
   `type: Boot Loader Specification Type #2 (UKI, .efi)`, tu kernel es un
   binario EFI único y agregar entradas Type #1 cambia cómo se elige el default.
2. Tener los kernels instalados. El rol avisa cuáles faltan, pero escribe las
   entradas igual.
3. Poner `boot_default_entry` al id de una entrada que sepas que arranca (velos
   con `bootctl list`). El rol lo exige con un `assert` y escribe la línea
   `default` en `loader.conf` — sin ella, systemd-boot elige por orden de sorteo.

Si tu root está en LVM o LUKS la detección no aplica: déjalo apagado y escribe
las entradas a mano.

Ojo con el espacio de la ESP: con UKI cada kernel son decenas de MB, y tres
kernels pueden llenar una ESP de 512 MB. Revisa con `df -h /boot`.

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
