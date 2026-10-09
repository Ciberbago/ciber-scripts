# Bienvenido

Este repositorio deja configurado un equipo desde cero: sistema, paquetes,
unidades, credenciales y respaldos.

**Para lo que haces la mayoría de las veces**, empieza por la tabla de tareas de
tu distro: [Debian](ansible/README-debian.md) · [Arch](ansible/README.md) · [Termux](docs/termux.md)

| Quiero… | |
|---|---|
| Ver qué hay instalado | `ciber-help` |
| Aplicar cambios | `ciber-apply` (nunca con `sudo`) |
| Ver qué cambiaría sin tocar nada | `ciber-apply --check --diff` |
| Reaplicar solo una parte | `ciber-apply --tags packages` |
| Ver el progreso, en otra terminal | `ciber-watch` |
| Poner las credenciales | `nano /etc/ciber/backup.env` + `sudo ciber-secrets` |
| Montar un disco de datos | `sudo ciber-disco` (menú; a mano, no va en el playbook) |

Debajo está el resto, por distro.

## Arch linux

Basicamente tiene lo mismo que windows. Preparado con los drivers de amd, para juegos y herramientas necesarias para mi uso. Con el entorno de esctritorio GNOME minimal edition.

```
bash <(curl -L url.jaimelopez.top/arch)
```

Ahora esto es un **bootstrap de Ansible**: instala ansible, clona el repo y
aplica el playbook. Despues del primer login en GNOME hay que ejecutar
`ciber-session` para la parte que necesita sesion grafica.

La configuracion se edita en `ansible/group_vars/all/` (paquetes, dotfiles,
unidades de systemd, ajustes de GNOME, aliases). Ver
[ansible/README.md](ansible/README.md) para la guia de mantenimiento, y
[docs/por-que-arch.md](docs/por-que-arch.md) para las decisiones que hay detras.

Comandos que quedan instalados:

```
ciber-apply                   # reaplica el sistema
ciber-apply --check --diff    # simulacro, no toca nada
ciber-apply --tags packages   # solo una parte
ciber-session                 # config de GNOME
```

La version anterior en bash puro sigue en `legacy/arch-bash.sh`.

## Windows

Principalmente lo hice para poder instalar la mayoría de programas y configuraciones que necesito en Windows 11 con el siguiente comando:

```
irm url.jaimelopez.top/windows | iex
```

Incluye cosas como:
- Gestores de paquetes
    - Winget
    - Chocolatey
    - Scoop
- Programas
    - Multimedia
    - Monitoreo
    - VM
    - Control remoto
- Debloat
    - Quita aplicaciones incluidas de windows
    - Quita onedrive
    - Quita telemetría
- QOL
    - Quita sticky keys
    - Quita hibernacion
    - Archivos de configuracion para programas
    - Scripts
    - Variables de entorno con utilidades

## Debian

Asi como instalar todos los modulos necesarios en una nueva instalación de debian minimal para cualquier servidor de pruebas o producción que pueda llegar a necesitar con el siguiente comando:

Para debian 12:

```
wget -O - url.jaimelopez.top/debian | bash
```

Ese comando ya no es el script gigante de antes: ahora sólo instala Ansible,
clona el repo y aplica el playbook. La configuración vive en
`ansible/group_vars/workstations_debian/` y se documenta en
[ansible/README-debian.md](ansible/README-debian.md). El script viejo en bash
puro quedó en `legacy/debian-bash.sh`.

Este repo además tiene el **respaldo de los datos** de los servicios, que están
en el otro repo: [cyber-docker](https://github.com/Ciberbago/ciber-docker). El
runbook de montar un servidor nuevo de cero, con los respaldos de por medio, está
en [docs/nuevo-servidor.md](docs/nuevo-servidor.md).


Incluye cosas como:
- Monitoreo
    - btop
    - gdu
    - exa
    - lm-sensors
    - nload
- Software de servidor
    - Docker
    - rClone
- QOL
    - fish shell
    - neovim with plugins
    - git
    - micro
- Red
    - wakeonlan
    - tailscale

## Termux

Lo mismo pero en el teléfono: Fish, servidor SSH y ocho comandos para vídeo,
descargas y red. Es la única parte del repo que **no** se instala con Ansible,
porque Termux no tiene `sudo` ni `/etc`.

```
bash <(curl -L url.jaimelopez.top/termux)
```

El script instala los paquetes, pide el permiso de almacenamiento, deja Fish como
shell y pone los comandos en `~/bin` con permisos `700`. **Conserva** lo que ya
exista, así que para actualizarlos está `ciber-update`, que sí sobrescribe.

Los ocho comandos: `ciber-help` (que es la ayuda en el propio teléfono),
`ciber-update`, `ffm-tui` para vídeo, `yt-tui` para descargas, `yt-share` para
lo que compartes con Termux, `termux-ssh` para el servidor SSH del móvil
(puerto 8022), `net-tui` para red y Wake-on-LAN, y `ssh-tui` para tus conexiones
guardadas por alias.

La guía completa, con lo que hace cada uno, dónde guarda sus cosas y los problemas
que salen, está en [docs/termux.md](docs/termux.md).
