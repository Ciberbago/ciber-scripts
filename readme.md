# Bienvenido

Este es un repositorio personal

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
[ansible/README.md](ansible/README.md) para la guia de mantenimiento.

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

## Termux / Android

El bootstrap de Termux instala el entorno base, Fish, SSH, FFmpeg, yt-dlp y
los scripts personales para trabajar desde el teléfono o desde un PC por SSH.

En una instalación nueva de Termux, ejecuta:

```fish
bash <(curl -L url.jaimelopez.top/termux)
```

Este comando fue probado después de desinstalar y reinstalar Termux desde cero.
Como alternativa, puedes descargar el script directamente desde GitHub:

```fish
pkg install curl
curl -fL https://raw.githubusercontent.com/Ciberbago/ciber-scripts/main/scripts/termux/bootstrap.sh -o ~/bootstrap.sh
bash ~/bootstrap.sh
```

Durante la instalación Android mostrará una solicitud para acceder al
almacenamiento. Pulsa **Permitir**. El proceso instala estos comandos en
`~/bin`, sin sobrescribir los que ya existan:

```text
ffm-tui       operaciones con FFmpeg
yt-tui        descargas con yt-dlp
termux-ssh    servidor SSH para controlar Termux desde el PC
```

Si Fish no se activa automáticamente al terminar, ejecuta:

```fish
exec fish
```

Para preparar SSH, ejecuta:

```fish
termux-ssh
```

Elige configurar una contraseña y luego iniciar el servidor. Termux usa el
puerto `8022`. El menú mostrará el comando exacto para conectarte desde el PC.

El bootstrap no incluye contraseñas, cookies, API keys, tokens ni claves
privadas. Tampoco sobrescribe configuraciones personales ni scripts que ya
estén en `~/bin`.
