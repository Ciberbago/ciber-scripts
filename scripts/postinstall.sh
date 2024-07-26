#!/bin/bash
yay -S python-tqdm --noconfirm
# Lista de scripts a ejecutar
scripts=("aur.sh" "ext.sh" "gnomeconfig.sh" "hideapps.sh" "removeapps.sh" "gnome.sh" "appimages.sh")

# Directorio donde se encuentran los scripts
directorio="$HOME"

# Iteramos sobre la lista de scripts
for script in "${scripts[@]}"; do
    # Construimos la ruta completa del script
    ruta="$directorio/$script"

    # Verificamos si el archivo existe y es ejecutable
    if [[ -x "$ruta" ]]; then
        # Si es gnome.sh, ejecutamos con el argumento "restore"
        if [[ "$script" == "gnome.sh" ]]; then
            echo "Ejecutando $script con el argumento 'restore'"
            "$ruta" restore
        else
            echo "Ejecutando $script"
            "$ruta"
        fi
    else
        echo "El script $ruta no existe o no tiene permisos de ejecución."
    fi
done
