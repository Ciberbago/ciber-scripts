#!/bin/bash

# Variables
PLAYBOOK_PATH="$HOME/playbook.yml"
INVENTORY_NAME="$HOME/hosts"

# Comprobar si el script se está ejecutando con Bash
if [ -z "$BASH_VERSION" ]; then
    echo "Error: Este script debe ejecutarse en Bash."
    exit 1
fi

# Comprobar si el playbook existe
if [[ ! -f $PLAYBOOK_PATH ]]; then
    echo "El archivo $PLAYBOOK_PATH no existe. Asegúrate de que el playbook esté descargado en tu directorio home."
    exit 1
fi

# Instalar Ansible si no está instalado
if ! command -v ansible &> /dev/null; then
    echo "Instalando Ansible..."
    if ! sudo pacman -S --noconfirm ansible; then
        echo "Error: Falló la instalación de Ansible."
        exit 1
    fi
else
    echo "Ansible ya está instalado."
fi

# Crear el archivo de inventario
echo "Creando el archivo de inventario..."
if ! echo -e "[local]\nlocalhost ansible_connection=local" > $INVENTORY_NAME; then
    echo "Error: No se pudo crear el archivo de inventario en $INVENTORY_NAME."
    exit 1
fi

echo "Inventario creado en $INVENTORY_NAME"

# Ejecutar el playbook
echo "Ejecutando el playbook..."
if ! ansible-playbook -i $INVENTORY_NAME $PLAYBOOK_PATH; then
    echo "Hubo un error al ejecutar el playbook."
    exit 1
fi

echo "Proceso completo."
