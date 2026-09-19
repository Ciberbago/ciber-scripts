#!/usr/bin/env bash
#
# Explica por que fallo un montaje CIFS y avisa en el escritorio.
#
#   nas-aviso <unidad.mount>
#
# No se ejecuta a mano: lo dispara 'OnFailure=' de la unidad de montaje, a
# traves de ciber-nas-aviso.service.
#
# Existe porque el montaje del NAS fallaba en el peor silencio posible: la
# unidad trae 'nofail' y el automount solo se dispara cuando alguien entra a
# /run/media/nas, asi que el arranque no se queja de nada y el error real queda
# enterrado en el journal, con un mensaje de CIFS que ni menciona el archivo de
# credenciales que falta.
#
# Sin 'set -e' a proposito: esto corre cuando algo YA fallo, y su unico trabajo
# es informar. Que se caiga a la mitad seria peor que un aviso incompleto.
set -uo pipefail

unidad="${1:-}"
if [[ -z "$unidad" ]]; then
    echo "Uso: nas-aviso <unidad.mount>" >&2
    exit 64
fi

# La ruta del archivo de credenciales se saca de la PROPIA unidad, no se
# escribe aqui. Si algun dia cambia en el .mount, este aviso la sigue solo.
cred="$(systemctl show -p Options --value "$unidad" 2>/dev/null |
    tr ',' '\n' | sed -n 's/^credentials=//p' | head -1)"

titulo="No se pudo montar el NAS ($unidad)"

if [[ -z "$cred" ]]; then
    detalle="Revisa: systemctl status $unidad"
elif [[ ! -f "$cred" ]]; then
    detalle="Falta el archivo de credenciales $cred"
elif grep -q 'CAMBIAME' "$cred" 2>/dev/null; then
    detalle="El archivo $cred todavia tiene los valores de ejemplo (CAMBIAME). Ponle el usuario y la contrasena reales del NAS."
else
    detalle="Las credenciales de $cred no funcionaron, o el servidor no responde."
fi

# --- Al journal: esto siempre, sin excepcion ---
#
# La salida estandar de un servicio va al journal, asi que esto queda grabado
# aunque no haya nadie con sesion abierta para ver la notificacion.
echo "!!! ${titulo}"
echo "    ${detalle}"
echo "--- ultimas lineas de ${unidad} ---"
journalctl -u "$unidad" -n 15 --no-pager 2>/dev/null || true

# --- Notificacion de escritorio ---
#
# Con limite de frecuencia: el automount vuelve a intentar el montaje CADA vez
# que alguien toca /run/media/nas, y un gestor de archivos abierto en esa
# carpeta lo toca solo. Sin esto, un NAS caido llena la pantalla de burbujas.
#
# El sello va en /run, que es tmpfs: se limpia en cada arranque, que es justo
# lo que se quiere (despues de reiniciar si conviene volver a avisar).
sello="/run/nas-aviso-$(echo "$unidad" | tr -c 'A-Za-z0-9' '_').stamp"
ahora="$(date +%s)"
if [[ -f "$sello" ]] && (($(cat "$sello" 2>/dev/null || echo 0) + 600 > ahora)); then
    echo "    (notificacion omitida: ya se aviso hace menos de 10 minutos)"
    exit 0
fi
echo "$ahora" >"$sello" 2>/dev/null || true

# Este script corre como root, sin sesion grafica propia. Para que la burbuja
# aparezca hay que hablarle al bus de la sesion del usuario, y para eso hace
# falta saber quien tiene sesion abierta. En vez de dar por hecho el uid 1000,
# se recorren los buses que existan: asi funciona sin importar el usuario.
for bus in /run/user/*/bus; do
    [[ -S "$bus" ]] || continue
    uid="$(basename "$(dirname "$bus")")"
    usuario="$(id -nu "$uid" 2>/dev/null)" || continue
    runuser -u "$usuario" -- env DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
        notify-send -u critical -i folder-remote-symbolic \
        "$titulo" "$detalle" 2>/dev/null || true
done
