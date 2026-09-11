#!/bin/bash

# Verifica si el nombre del archivo fue proporcionado como argumento
if [ "$#" -ne 1 ]; then
    zenity --error --text="Uso: $0 <ruta-al-archivo>"
    exit 1
fi

archivo="$1"

# Verifica si ffprobe y jq están instalados
if ! command -v ffprobe &> /dev/null; then
    zenity --error --text="ffprobe no está instalado. Por favor instálalo antes de ejecutar el script."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    zenity --error --text="jq no está instalado. Por favor instálalo antes de ejecutar el script."
    exit 1
fi

# Extraer información en formato JSON con ffprobe y procesarla con jq
info=$(ffprobe -v error -print_format json -show_format -show_streams "$archivo")

# Extraer resolución
resolucion=$(echo "$info" | jq -r '.streams[] | select(.codec_type == "video") | "\(.width)x\(.height)"')

# Extraer FPS
fps=$(echo "$info" | jq -r '.streams[] | select(.codec_type == "video") | .r_frame_rate' | awk -F'/' '{printf "%.2f", $1/$2}')

# Extraer bitrate
bitrate=$(echo "$info" | jq -r '.format.bit_rate')
if [ -z "$bitrate" ] || [ "$bitrate" == "null" ]; then
    bitrate="No disponible"
else
    bitrate=$(echo "$bitrate" | awk '{print int($1/1000) " kbps"}')
fi

# Extraer codec de video
codec_video=$(echo "$info" | jq -r '.streams[] | select(.codec_type == "video") | .codec_name')

# Extraer codec de audio
codec_audio=$(echo "$info" | jq -r '.streams[] | select(.codec_type == "audio") | .codec_name')

# Extraer la duración
duracion=$(echo "$info" | jq -r '.format.duration')
if [ -z "$duracion" ] || [ "$duracion" == "null" ]; then
    duracion="No disponible"
else
    duracion=$(echo "$duracion" | awk '{printf "%02d:%02d:%02d\n", ($1/3600), ($1%3600)/60, $1%60}')
fi

# Generar mensaje con toda la información
mensaje="Archivo: $archivo\n\n"
mensaje+="Resolución: $resolucion\n"
mensaje+="FPS: $fps\n"
mensaje+="Bitrate: $bitrate\n"
mensaje+="Codec de video: $codec_video\n"
mensaje+="Codec de audio: $codec_audio\n"
mensaje+="Duración: $duracion"

# Mostrar la información en una ventana gráfica con Zenity
zenity --info --title="Información del archivo" --width=300 --height=300 --text="$mensaje"

