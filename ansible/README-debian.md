# Playbook de Debian 12

Sistema, Docker, Tailscale y los respaldos de este servidor.

Para los servicios, el otro repo: [cyber-docker](https://github.com/Ciberbago/ciber-docker) ·
[su README de tareas](https://github.com/Ciberbago/ciber-docker/blob/main/README.md)

## Dos trampas antes de nada

- **Nunca `sudo-appscript`.** El propio script lo rechaza: corriendo como root, el
  checkout del repo y los dotfiles acaban en `/root`, y el comando se regenera
  apuntando ahí y deja de funcionar para ti.
- **`appscript` descarta lo que tengas sin comitear** en el clon, porque hace
  `git checkout -qf` contra el remoto. El flujo es: edita en **tu** clon, `git push`,
  y solo entonces aplica. Si editas en el checkout del servidor, el cambio se
  pierde.

## Lo que hago

| Quiero… | |
|---|---|
| Ver qué hay instalado | `ciber-help` |
| Ver una parte de esa lista | `ciber-help docker` |
| Aplicar cambios | `ciber-apply` |
| Ver qué cambiaría sin tocar nada | `ciber-apply --check --diff` |
| Reaplicar solo una parte | `ciber-apply --tags packages` |
| Ver las etiquetas que hay | `ciber-apply --list-tags` |
| Ver el progreso, en otra terminal | `ciber-watch` |
| Poner las credenciales | `nano /etc/ciber/backup.env` y luego `sudo ciber-secrets` |
| Ver si falta alguna credencial | `sudo ciber-secrets` |

Las etiquetas: `packages` `docker` `files` `tools` `systemd` `secrets` `dotfiles`
`fish` `neovim` `tailscale` `apt` `base` `system` `user` `editor` `shell` `red`.

## Instalación en una máquina limpia

```bash
wget -O - url.jaimelopez.top/debian | bash
```

Eso instala Ansible, clona el repo y aplica `site-debian.yml`. Corre sin sesión
gráfica, así que se puede hacer por SSH.

Al terminar quedan **tres** pasos manuales:

1. **Cerrar sesión y volver a entrar.** El grupo `docker` y el shell `fish`
   aplican en el próximo login, no en el actual.
2. **`sudo tailscale up`.** El playbook instala y habilita `tailscaled` pero no lo
   conecta: `tailscale up` abre un navegador para autenticar, y hacerlo sin
   interacción exigiría guardar una *auth key* en el repo.
3. **Rellenar `/etc/ciber/backup.env`** (abajo) y **clonar el repo de stacks en
   `/opt/docker`**, que ya no lo hace este playbook.

A diferencia de Arch, aquí no hay `ciber-session`: ese comando configura GNOME y
en un servidor no hay escritorio.

El camino completo, de formatear hasta los servicios funcionando, está en
[`docs/nuevo-servidor.md`](../docs/nuevo-servidor.md).

## Cambiar algo

Todo se edita en `group_vars/workstations_debian/`. Nunca hace falta tocar un rol
para el mantenimiento normal.

| Quiero… | Edito | Cuánto es |
|---|---|---|
| Agregar/quitar un paquete | `packages.yml` | 1 línea |
| Agregar un dotfile | el archivo en `dotfiles/debian/` + `files.yml` | 1 línea |
| Agregar config a `/etc` | el archivo en el repo + `files.yml` → `system_files` | 1 línea |
| Agregar un comando a `/usr/local/bin` | el script en `scripts/debian/` + `files.yml` | 1 línea |
| Agregar una unidad de systemd | dejo el `.service` en `systemd/debian/` | **0 líneas** |
| Habilitar una unidad en boot | `systemd.yml` | 1 línea |
| Agregar un alias de fish | `shell.yml` (y aparece solo en `ciber-help`) | 1 línea |
| Describir un comando en la ayuda | campo `desc:` en `files.yml` | 1 línea |
| Cambiar la versión de Docker/Tailscale/neovim | `services.yml` | 1 línea |
| Declarar un secreto nuevo | `secrets.yml` (solo el nombre de la clave, **nunca el valor**) | 1 línea |
| Cambiar **qué** se respalda de un stack | `scripts/debian/data-map.conf` | 1 línea |
| Añadir un script o un timer de respaldo | `scripts/debian/` + `files.yml` / `systemd.yml` | 1 línea |
| Desactivar Docker o Tailscale | `services.yml` → `docker_enabled: false` | 1 línea |

Un `.timer` nuevo necesita además su nombre en `systemd.yml`: habilitarlo no lo
arranca, y un timer parado no dispara hasta el reinicio.

## Credenciales

Ningún token está en este repo, que es público. Viven en la máquina:

| Quién lo lee | Dónde | Permisos |
|---|---|---|
| Unidades de sistema (root) | `/etc/ciber/backup.env` | `root:root` `0600` |
| Unidades de usuario | `~/.config/ciber/todoist.env` | usuario, `0600` |

Una unidad `--user` no puede leer un `0600` de root, de ahí que estén separados.

El playbook los crea **vacíos** y avisa de los que queden sin rellenar, en tres
sitios: durante el apply, al final del playbook, y con `ciber-secrets`. Es a
propósito que el respaldo **falle** si falta el token: un token vacío no da error,
el `curl` sale con éxito y el aviso simplemente no llega.

```bash
sudo nano /etc/ciber/backup.env      # TELEGRAM_TOKEN y TELEGRAM_CHAT_ID
nano ~/.config/ciber/todoist.env     # los tres de Todoist
sudo ciber-secrets                    # sale con 1 si queda algo
```

Si acabas de migrar desde la versión con el token dentro del script, rellena esto
**antes de las 18:00** o pierdes el respaldo de esa noche. Para no perder ni una:

```bash
sudo ciber-apply --tags secrets   # solo crea los .env, no toca los scripts
# rellena, luego:  sudo ciber-apply
```

## Si algo va mal

| Síntoma | Dónde mirar |
|---|---|
| El playbook falla a mitad | `~/ciber-debian.log` — el final dice la tarea exacta |
| Un servicio no arranca | `systemctl --failed` |
| Un puerto se pisa con otro | `bin/ports` (en el repo de stacks) |
| Faltan credenciales | `sudo ciber-secrets` |
| El respaldo no avisó | casi siempre es el token: `sudo ciber-secrets` |
| El respaldo falló | `grep INCOMPLETO /var/tmp/MANIFEST.txt` |
| `apt` no lee sus fuentes | `sudo rm -f /etc/apt/sources.list.d/docker.list` y re-aplica |

## Más detalle

- [`docs/por-que-debian.md`](../docs/por-que-debian.md) — las decisiones, la tabla de
  bugs del script de bash, por qué hay dos inventarios, y por qué no `ansible-vault`
- [`docs/nuevo-servidor.md`](../docs/nuevo-servidor.md) — de formatear el disco a los
  servicios funcionando
- [`docs/migracion-backup-2026-09-28.md`](../docs/migracion-backup-2026-09-28.md) —
  bitácora de la migración del respaldo (archivo fechado, del 2026-09-28)
- [cyber-docker](https://github.com/Ciberbago/ciber-docker) — los servicios
