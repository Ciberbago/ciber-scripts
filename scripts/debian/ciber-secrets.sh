#!/bin/bash
#
# ciber-secrets - dice que credenciales faltan por poner.
#
# Los tokens no viven en el repo: viven en archivos .env de la maquina, que
# Ansible crea VACIOS y no vuelve a tocar. Este comando responde de un vistazo a
# "¿ya los puse?", sin tener que acordarse de las rutas.
#
#   ciber-secrets         revisa los del usuario y avisa de los de root
#   sudo ciber-secrets    revisa TODOS (los de /etc son 0600 root:root)
#
# Sale con codigo 1 si falta algo, para poder encadenarlo.
set -u

ESTADO=0

revisar() {
    local f="$1" vacias
    if [ ! -e "$f" ]; then
        printf '  %-38s NO EXISTE  -> ciber-apply --tags secrets\n' "$f"
        ESTADO=1
        return
    fi
    if [ ! -r "$f" ]; then
        printf '  %-38s sin permiso de lectura -> repite con sudo\n' "$f"
        ESTADO=1
        return
    fi
    vacias=$(grep -cE '^[A-Za-z_][A-Za-z0-9_]*=[[:space:]]*$' "$f" || true)
    if [ "${vacias:-0}" -gt 0 ]; then
        printf '  %-38s FALTAN %s valor(es)\n' "$f" "$vacias"
        grep -nE '^[A-Za-z_][A-Za-z0-9_]*=[[:space:]]*$' "$f" |
            sed 's/^/        linea /'
        ESTADO=1
    else
        printf '  %-38s ok\n' "$f"
    fi
}

# Con sudo, $HOME es /root: hay que preguntar por el usuario real para no
# revisar los .env equivocados.
USUARIO="${SUDO_USER:-$USER}"
HOME_USUARIO="$(getent passwd "$USUARIO" | cut -d: -f6)"

echo "Credenciales de ciber-scripts"
echo

echo " Sistema (las lee backup.service, corre como root):"
encontrado=0
for f in /etc/ciber/*.env; do
    [ -e "$f" ] || continue
    encontrado=1
    revisar "$f"
done
[ "$encontrado" -eq 0 ] && {
    printf '  %-38s NO EXISTE  -> ciber-apply --tags secrets\n' "/etc/ciber/*.env"
    ESTADO=1
}

echo
echo " Usuario ${USUARIO} (las lee todoist-precise.service):"
encontrado=0
for f in "${HOME_USUARIO}"/.config/ciber/*.env; do
    [ -e "$f" ] || continue
    encontrado=1
    revisar "$f"
done
[ "$encontrado" -eq 0 ] && {
    printf '  %-38s NO EXISTE  -> ciber-apply --tags secrets\n' "~/.config/ciber/*.env"
    ESTADO=1
}

echo
if [ "$ESTADO" -eq 0 ]; then
    echo "Todo puesto."
else
    echo "Falta rellenar credenciales."
    echo
    echo "Los scripts abortan si una variable esta vacia, asi que backup.service"
    echo "y todoist-precise.service FALLAN al arrancar. Es decir: no hay"
    echo "respaldo ni notificaciones hasta que las pongas."
    echo
    echo "Revisa el detalle con:  systemctl --failed"
fi
exit "$ESTADO"
