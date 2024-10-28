#!/bin/bash

# Variables
PLAYBOOK_PATH="$HOME/playbook.yml"
INVENTORY_NAME="$HOME/hosts"
SUDOERS_FILE="/etc/sudoers.d/ansible"

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

# Configurar sudo para que no pida contraseña para el usuario actual
USER=$(whoami)
echo "Configurando sudo para no pedir contraseña..."
if ! echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee $SUDOERS_FILE > /dev/null; then
    echo "Error: No se pudo configurar sudo para no pedir contraseña."
    exit 1
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

# Revertir la configuración de sudo
echo "Revirtiendo la configuración de sudo..."
if ! sudo rm $SUDOERS_FILE; then
    echo "Error: No se pudo revertir la configuración de sudo."
    exit 1
fi

echo "Configuración de sudo revertida."
echo "Proceso completo."
