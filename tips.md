###Para cambiar nombre de dispositivos bluetooth

Ir a la carpeta de bluetooth:
    
´´´
cd /var/lib/bluetooth
´´´

De ahi a la carpeta con el nombre de la dirección mac del dispositivo adaptador de bluetooth indicado

Luego buscar la carpeta con el nombre de la mac del dispositivo bluetooth al que quieres cambiar el nombre, luego en el archivo "info", agregar:
    
´´´
Alias=Lala_Lele_Name
´´´