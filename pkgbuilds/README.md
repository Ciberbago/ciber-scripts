# pkgbuilds/

Recetas de paquetes de Arch que **no están en el AUR**. Se compilan con
`makepkg` durante `ciber-apply` y quedan instaladas como cualquier otro paquete:
aparecen en `pacman -Qm` (foráneos) igual que los del AUR, y `pacman -Syu` no
las toca.

## Agregar un paquete

1. Crea la carpeta con el **nombre exacto de `pkgname`**:

   ```
   pkgbuilds/mi-paquete/PKGBUILD
   ```

   Junto al `PKGBUILD` puede ir lo que necesite: `.install`, parches, `.desktop`,
   lo que sea. Se copia la carpeta completa al directorio de compilación.

2. Agrégalo a `local_packages` en
   `ansible/group_vars/workstations_arch/packages.yml`:

   ```yaml
   local_packages:
     - mi-paquete
   ```

3. `ciber-apply --tags aur`

Que el nombre de la carpeta sea igual a `pkgname` no es un capricho: es la llave
con la que el rol pregunta `pacman -Q <nombre>` para saber si ya está instalado.

## Actualizar un paquete

Sube `pkgver` o `pkgrel` en el `PKGBUILD` y vuelve a aplicar. El rol compara la
versión declarada contra la instalada y solo recompila cuando difieren.

## Cómo funciona

Vive en el rol `aur`, no en uno propio, porque ahí ya está resuelto el problema
difícil: `makepkg` se niega a correr como root pero necesita `sudo` para
instalar dependencias de compilación, y el rol ya pone y retira un permiso
`NOPASSWD` temporal acotado a `/usr/bin/pacman`. Un rol aparte tendría que
duplicar ese manejo, incluido el `always` que lo retira aunque algo falle.

La compilación ocurre en `/tmp/ciber-pkg-<nombre>`, no aquí. `makepkg` deja
`src/`, `pkg/` y el `.pkg.tar.zst` en el directorio actual, y eso pelearía con
el `git checkout -qf` con el que arranca cada corrida.

## Limitaciones

- **PKGBUILDs tipo `-git` con función `pkgver()`**: ahí la versión se calcula al
  compilar, no al leer el archivo, así que la comparación nunca dirá "al día" y
  el paquete se recompilará en cada corrida. Si necesitas uno así, mejor súbelo
  al AUR o pinea un tag en el `source=`.
- Si el paquete falla al compilar, la corrida **no** se detiene: se reporta al
  final. Para ver el error completo, en la máquina:
  `cd /tmp/ciber-pkg-<nombre> && makepkg -si`.

## Por qué no un repo propio de pacman

La alternativa "correcta" de Arch sería construir una vez, hacer `repo-add` y
agregar el repo a `pacman.conf`. Se descartó: si el servidor que lo sirve no
responde, **`pacman -Sy` falla entero**, no solo para ese repo. Y en una
instalación limpia Tailscale todavía no está autenticado, justo cuando el
playbook hace el `-Syu`. Cambiaría "compilar dos paquetes" por "toda la
instalación depende de que un servidor esté arriba".

Vale la pena reconsiderarlo si algún día son muchos paquetes o alguno tarda
mucho en compilar.
