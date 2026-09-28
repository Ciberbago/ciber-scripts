# Migración del respaldo: 2026-09-28

Bitácora de una sesión en la que el respaldo diario de `/opt/docker` se rehízo entero.
Está aquí sobre todo para **otra IA o persona que venga con contexto anterior**: si
tú sabías que el playbook clonaba los stacks, o que el backup era un `tar` de todo
`/opt/docker`, lo que hay abajo está desactualizado y este documento lo corrige.

Lo que **no** cambia: la arquitectura de secretos (`/etc/ciber/backup.env`,
`ciber-secrets`, el fallo ruidoso con `${VAR:?}`) ni el resto del playbook. Ese
trabajo se respetó tal cual; los cambios deliberados están abajo.

## Reglas que no hay que deshacer

1. **Este playbook no clona ni escribe en `/opt/docker`.** Ni `git clone`, ni
   `git checkout`, ni un `chown`. Ese es el motivo por el que se quitó el clon, y
   hay una razón de fondo: un `git checkout` reescribe un archivo de datos como
   `jaime:jaime 644`, y el PHP del contenedor corre como `www-data` (uid 82), con lo
   que la app se queda sin poder escribir y responde `attempt to write a readonly
   database`. Pasó en el repo de stacks el 2026-09-26 y tumbó a la vez tres apps. Si
   alguna vez hace falta tocar `/opt/docker`, que sea a mano y con el stack parado.
2. **El respaldo ya no es "un tar de `/opt/docker`".** Es solo datos, y solo los que
   declara `scripts/debian/data-map.conf`. La configuración está en git; duplicarla
   en un tarball solo ocupaba espacio y subía secretos a Drive.
3. **`backupdebian.sh` ya no existe.** Lo sustituyen `backup-datos.sh` y
   `backup-musica.sh`, con scripts y timers separados.
4. **`data-map.conf` es la única fuente** de qué se guarda, y va aquí, no en el repo
   de stacks: la política de respaldo es de esta máquina. Su polaridad es
   **default-include**: entra todo lo que **no** esté listado, así que un stack nuevo
   se respalda sin tocar nada. Solo hace falta una línea para las excepciones.

## Qué cambió y por qué

### El tarball

`backupdebian.sh` hacía `tar -czf docker.tar.gz docker` desde `/opt`: 267 MB de los
que unos 200 eran código ya presente en git (1679 ficheros de `.git/`, 599 de
`node_modules/`), más el `.env` con los 41 secretos, que iban a Google Drive.

Y en ese tar faltaba lo que importaba. Cuatro bugs, en orden de gravedad:

| Bug | Qué pasaba |
|---|---|
| `jellyfin.db` nunca se respaldó | La exclusión `jelly/data/data/data` iba dirigida a saltar `attachments/` y `subtitles/`, pero esa carpeta **también contiene la base de configuración**. Meses de respaldos de Jellyfin sin usuarios, historial ni bibliotecas. |
| Los `.wal` no se respaldaban | Una SQLite en modo WAL no es un archivo: son el `.db` más el `-wal`. Sin el `-wal`, un restore pierde las últimas transacciones **sin avisar**. El script viejo excluía a mano el de Home Assistant. |
| Un `exit 1` de tar abortaba todo | Home Assistant escribe en su base de forma continua, así que había noches sin respaldo de nada. De ahí salía precisamente aquella exclusión del `-wal`: era un parche al síntoma que además dejaba el respaldo incompleto. |
| La lista de `--exclude` se pudrió | Tenía entradas de stacks que ya no existen (`ytmt`, `wikipedia`) y un stack nuevo no se respaldaba hasta que alguien se acordara de añadirlo. |

Ahora: los datos salen de `data-map.conf`, las bases se copian con la API de backup
de SQLite (un `.db` único y checkpointeado, sin `-wal`), y **lo que no se pudo leer
se cuenta y se avisa** en vez de fallar en silencio. Home Assistant guarda 49 MB en
ficheros `600 root`; sin root el respaldo "sale bien" y sin ellos.

### La música

`backupdebian.sh` sincronizaba también `/media/hdd/music` a `google:Music`, y **dejó de
correr el 2026-09-27**. No porque fallara: porque el script entero se sustituyó y ese
pedazo no se llevó por delante. No había ningún síntoma, porque el aviso de Telegram
de las 19:00 lo mandaba el otro script.

Vuelve con su propio script y su propio timer, a las **04:00** y no a las 18:00. A
propósito: 7 GB contra 200 MB, otro remoto, y si la música falla no debe parecer que
falló el respaldo de datos. Con las dos cosas en un script, un error de rclone por
cuota de Drive dejaba el mensaje "falló el backup" sin que hubiera pasado. Y si el
disco no está montado avisa y sale con `0`.

### El repo de stacks

El rol `docker` clonaba `ciber-docker` en `/opt/docker` con el módulo `git`, y sus
variables `docker_stacks_repo` / `docker_stacks_dir` se fueron con él. No porque el
clon fallara, sino porque **tragarse el fallo era peor que no intentar nada**:
`failed_when: false` sobre un repo privado significa que sin credenciales `git`
falla, la tarea lo ignora, y el servidor queda con `/opt/docker` vacío y una línea de
`debug` que nadie lee. Un fallo mudo en la etapa de recuperación de desastres.

## La decisión que cambió de rumbo

La primera versión del script nuevo leía las credenciales del `.env` del repo de
stacks, para tenerlas en un solo sitio. **Se descartó**, y conviene saber por qué
porque el razonamiento no es obvio:

- `cli_tools_debian` copia el script a `/usr/local/bin` en cada `ciber-apply`. Un
  script instalado así que lee un archivo de **otro** repositorio es exactamente el
  patrón que `README-debian.md` ya había rechazado: *"el repo dejaba de reflejar lo
  que corría de verdad, y en cuanto algo copiara el script del repo encima el
  notificador se quedaba con los marcadores y dejaba de avisar, sin ningún error
  visible"*.
- Se habría perdido `ciber-secrets` y el aviso por triplicado.
- Se habría perdido el fallo ruidoso. La primera versión hacía que el respaldo
  siguiera **sin token, sin avisar**. Eso es justo lo contrario de lo que este repo
  quiere: *"un fallo visible es mejor que un respaldo mudo"*.

Así que las credenciales siguen en `/etc/ciber/backup.env`, leídas con `${VAR:?}`.
Hay **dos** copias del mismo token de Telegram —una en cada repo—, y es a
propósito: cada repo es autónomo y cada uno tiene su maquinaria de aviso.

Lo que sí cambió es el nombre de la clave: ahora es `TELEGRAM_TOKEN`, no
`TELEGRAM_BOT_TOKEN`, porque es la que declara `secrets.yml` y por lo tanto la que
valida `ciber-secrets`. Con el otro nombre, `sudo ciber-secrets` daría luz verde con
las claves sin rellenar.

## Detalles que no se ven y conviene conocer

- **El snapshot de SQLite sale del host, no de `docker exec`.** Las bases están en
  bind mounts, así que el host las ve: funciona con el contenedor parado y no
  depende de que la imagen traiga `python3`. Ni la de Jellyfin (que es .NET) ni la
  de nextexplorer (Go) lo tienen, y con `docker exec` el snapshot se caía a copia
  simple sin consolidar.
- **El tar lo lleva el prefijo del stack** (`jelly/data/...`, no `data/...`). Con
  `cd $stack && tar ./data` lo que se guarda se llama `data/...` y al restaurar en
  `/opt/docker` los datos de varios stacks caen todos encima en `./data`.
- **`--exclude='data/logs/'` no excluye nada** en GNU tar; `--exclude='data/logs'`
  sí. Es de los fallos que no dan error: el respaldo sale bien, solo que 35 veces más
  grande de lo que debería.
- **`data-map.conf` separa dos convenciones de rutas**: `incluye` y `excluye` van
  relativos a `datos`, y `snapshot` va relativo al stack. Se notaron al mezclarlo y produjeron un
  respaldo mal, sin ningún error.

## Qué quedó pendiente

- **Probar un restore de verdad.** Siempre se probó con `--to` a un directorio
  temporal: sha256 verificado, 16 stacks con permisos correctos, las cuatro bases
  pasando `integrity_check`. Lo que no se ha probado es un restore completo sobre un
  `/opt/docker` recién clonado con los 37 stacks subiendo después.
- **Rotar los tokens de Telegram.** Los tres que estaban en claro en
  `backupdebian.sh`, `~/scripts/backup.sh` y `/media/hdd/backup.sh` se quitaron de
  disco (ahora los tres delegan en `backup-datos.sh`, que los lee del `.env`), pero
  estuvieron escritos ahí.
- **`metadata/` de Jellyfin (825 MB).** No se purga porque borrarlo dispara un
  reescaneo completo de ~780 GB de media. Está anotado en el README de ese stack.
- **Un script que encadene todo el arranque.** Se empezó a escribir uno
  (`nuevo-servidor`) y no salió: con dos pasos manuales que no se pueden automatizar
  y los scripts de restore y backup ya en la mano, un tercer script que solo los
  encadenara no compensaba el mantenimiento. Si algún día se hace, que viva en el repo
  de stacks, que es donde se está cuando ejecutas el restore.
