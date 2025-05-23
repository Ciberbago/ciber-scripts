# Bienvenido

Este es un repositorio personal

## Arch linux

Basicamente tiene lo mismo que windows. Preparado con los drivers de amd, para juegos y herramientas necesarias para mi uso. Con el entorno de esctritorio GNOME minimal edition.

```
bash <(curl -L arch.jaimelopez.top)
```

## Windows

Principalmente lo hice para poder instalar la mayoría de programas y configuraciones que necesito en Windows 11 con el siguiente comando:

```
irm windows.jaimelopez.top | iex
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
wget -O - debian.jaimelopez.top | bash
```


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
