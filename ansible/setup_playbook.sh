#!/bin/bash

# Variables
PLAYBOOK_PATH="$HOME/playbook.yml"
INVENTORY_NAME="$HOME/hosts"
SUDOERS_FILE="/etc/sudoers.d/ansible"

# Comprobar si el playbook existe
if [[ ! -f $PLAYBOOK_PATH ]]; then
    echo "El archivo $PLAYBOOK_PATH no existe. Asegúrate de que el playbook esté descargado en tu directorio home."
    exit 1
fi

# Instalar Ansible si no está instalado
if ! command -v ansible &> /dev/null; then
    echo "Instalando Ansible..."
    sudo pacman -S --noconfirm ansible
fi

# Configurar sudo para que no pida contraseña para el usuario actual
USER=$(whoami)
echo "Configurando sudo para no pedir contraseña..."
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee $SUDOERS_FILE > /dev/null

# Crear el archivo de inventario
cat <<EOL > $INVENTORY_NAME
[local]
localhost ansible_connection=local
EOL

echo "Inventario creado en $INVENTORY_NAME"

# Ejecutar el playbook
echo "Ejecutando el playbook..."
ansible-playbook -i $INVENTORY_NAME $PLAYBOOK_PATH

# Comprobar el resultado de la ejecución
if [[ $? -eq 0 ]]; then
    echo "El playbook se ejecutó correctamente."
else
    echo "Hubo un error al ejecutar el playbook."
fi

# Revertir la configuración de sudo
echo "Revirtiendo la configuración de sudo..."
sudo rm $SUDOERS_FILE
echo "Configuración de sudo revertida."

# Fin del script
echo "Proceso completo."
