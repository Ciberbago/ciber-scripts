#!/usr/bin/env python3
"""Comprueba que cada clave dconf que declara el repo tenga un esquema detras.

    dconf-validate.py /org/gnome/desktop/interface/gtk-theme ...

Por que existe
--------------
'dconf write' NO valida nada. Escribe la ruta que le des, exista o no un
esquema que la respalde, y devuelve exito. El modulo dconf de Ansible hace lo
mismo: reporta 'ok', el valor queda guardado, y GNOME no se entera.

El caso que lo motivo: el repo declaraba

    /org/gnome/SessionManager/logout-prompt = false

El esquema se llama 'org.gnome.SessionManager', asi que la ruta parecia
evidente. Pero su atributo path es '/org/gnome/gnome-session/'. El id de un
esquema y su ruta dconf NO tienen por que coincidir. El ajuste llevaba meses
sin aplicarse, con el playbook reportando exito en cada corrida.

Que revisa
----------
Para cada argumento:

  - ruta que termina en '/'  -> solo comprueba que algun esquema viva ahi
    (es lo que consume 'dconf load', en gnome_dconf_loads)
  - ruta a una clave         -> comprueba la ruta Y que el esquema declare
    esa clave

Cuando una ruta no existe pero el nombre de la clave si aparece en otro
esquema, lo dice: casi siempre es exactamente la ruta que hacia falta.

Salida vacia = todo correcto. Devuelve 1 si encuentra algo.
"""

import glob
import os
import sys
import xml.etree.ElementTree as ET

PATRONES = [
    "/usr/share/glib-2.0/schemas/*.xml",
    os.path.expanduser("~/.local/share/gnome-shell/extensions/*/schemas/*.xml"),
    os.path.expanduser("~/.local/share/glib-2.0/schemas/*.xml"),
]


def leer_esquemas():
    """Devuelve {ruta_dconf: (id_esquema, {claves})} de todos los XML instalados."""
    mapa = {}
    for patron in PATRONES:
        for archivo in glob.glob(patron):
            try:
                raiz = ET.parse(archivo).getroot()
            except (ET.ParseError, OSError):
                # Un XML roto no debe tumbar la comprobacion de los demas.
                continue
            for esquema in raiz.iter("schema"):
                ruta = esquema.get("path")
                ident = esquema.get("id")
                if not ruta or not ident:
                    # Los esquemas relocalizables no traen path: no se pueden
                    # comprobar asi, y no los usamos.
                    continue
                claves = set()
                for clave in esquema.iter("key"):
                    if clave.get("name"):
                        claves.add(clave.get("name"))
                mapa[ruta] = (ident, claves)
    return mapa


def main(argv):
    if not argv:
        print("Uso: dconf-validate.py <ruta-dconf> [<ruta-dconf> ...]", file=sys.stderr)
        return 64

    mapa = leer_esquemas()
    if not mapa:
        print("!!! No se encontro ningun esquema instalado. "
              "Esta comprobacion solo sirve en la maquina con GNOME.", file=sys.stderr)
        return 0

    problemas = []
    for entrada in argv:
        if entrada.endswith("/"):
            if entrada not in mapa:
                problemas.append("  %s\n      ninguna extension o app tiene un esquema en esa ruta" % entrada)
            continue

        carpeta, _, nombre = entrada.rpartition("/")
        carpeta += "/"

        if carpeta not in mapa:
            # Buscar el nombre de la clave en el resto de esquemas: si aparece,
            # esa es casi seguro la ruta que se queria.
            candidatas = sorted(r for r, (_, ks) in mapa.items() if nombre in ks)
            detalle = "no hay ningun esquema en %s" % carpeta
            if candidatas:
                detalle += "\n      '%s' si existe en: %s" % (nombre, ", ".join(candidatas))
            problemas.append("  %s\n      %s" % (entrada, detalle))
            continue

        ident, claves = mapa[carpeta]
        if nombre not in claves:
            problemas.append("  %s\n      el esquema %s existe pero no declara la clave '%s'"
                             % (entrada, ident, nombre))

    if problemas:
        print("Claves dconf que NO hacen nada (%d de %d):" % (len(problemas), len(argv)))
        print("\n".join(problemas))
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
