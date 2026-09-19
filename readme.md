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
