#!/bin/bash
#
# Notificador de tareas de Todoist a Telegram. Lo dispara todoist-precise.timer
# cada minuto, como unidad de USUARIO (systemctl --user).
#
# SECRETOS: los tres tokens NO estan en este archivo. Se leen de
# ~/.config/ciber/todoist.env, que Ansible crea vacio con permisos 0600 y que
# nunca entra al repositorio.
#
# El archivo va en el HOME y no en /etc como el de backup.sh porque esta unidad
# corre como usuario, no como root: no podria leer un archivo 0600 de root.
#
# Antes el repo guardaba "todotoken" / "telegramtoken" / "chatidtelegram" como
# marcadores y los valores reales se escribian a mano en la maquina. Eso
# funcionaba hasta que algo volviera a copiar el script del repo encima: el
# notificador se quedaba con los marcadores y dejaba de avisar en silencio.
set -u

# Bajo systemd los inyecta 'EnvironmentFile=' de todoist-precise.service. El
# source es para cuando se ejecuta a mano desde una shell.
[ -r "$HOME/.config/ciber/todoist.env" ] && . "$HOME/.config/ciber/todoist.env"

: "${TODOIST_TOKEN:?falta TODOIST_TOKEN en ~/.config/ciber/todoist.env}"
: "${TELEGRAM_TOKEN:?falta TELEGRAM_TOKEN en ~/.config/ciber/todoist.env}"
: "${TELEGRAM_CHAT_ID:?falta TELEGRAM_CHAT_ID en ~/.config/ciber/todoist.env}"

CHAT_ID="$TELEGRAM_CHAT_ID"
FILE_NOTIFIED="/tmp/todoist_notified.txt"

# Obtener proyectos
projects_json=$(curl -s -X GET "https://api.todoist.com/api/v1/projects" \
    -H "Authorization: Bearer $TODOIST_TOKEN")

# Función para procesar tareas
process_tasks() {
    local response="$1"
    local NOW_TS=$(TZ=America/Los_Angeles date +%s)
    
    echo "$response" | jq -r '.results // . | .[] | select(.due != null and .due.date != null) | [.due.date, .content, .id, (.project_id | tostring)] | join("|")' 2>/dev/null | while IFS='|' read -r due_dt content task_id proj_id; do
        [ -z "$content" ] && continue
        
        # Verificar si ya fue notificada (en los últimos 5 minutos)
        if grep -q "^${task_id}$" "$FILE_NOTIFIED" 2>/dev/null; then
            continue
        fi
        
        # Convertir due_dt a timestamp
        due_ts=$(TZ=America/Los_Angeles date -d "$due_dt" +%s 2>/dev/null || date -d "$due_dt" +%s 2>/dev/null)
        
        if [ -n "$due_ts" ] && [ -n "$NOW_TS" ]; then
            diff=$((due_ts - NOW_TS))
            
            # Notificar si vence en los próximos 120 segundos
            if [ "$diff" -ge 0 ] && [ "$diff" -le 120 ]; then
                # Marcar como notificada
                echo "$task_id" >> "$FILE_NOTIFIED"
                
                pdttime=$(TZ=America/Los_Angeles date -d "@$due_ts" "+%I:%M %p")
                project_name=$(echo "$projects_json" | jq -r --arg pid "$proj_id" '.results // . | .[] | select(.id == $pid) | .name' 2>/dev/null)
                project_name=${project_name:-"Sin proyecto"}
                
                MESSAGE="⏰ *Recordatorio:* $content - 🕐 $pdttime - 📁 $project_name"
                
                curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
                    -d "chat_id=$CHAT_ID" \
                    -d "text=$MESSAGE" \
                    -d "parse_mode=Markdown" > /dev/null
            fi
        fi
    done
}

# Limpiar notificaciones antiguas (más de 5 minutos)
find "$FILE_NOTIFIED" -mmin +5 -delete 2>/dev/null

# Obtener IDs de proyectos "Pendientes" y "Pagos"
project_ids=$(echo "$projects_json" | jq -r '.results // . | .[] | select(.name | test("Pendientes|Pagos"; "i")) | .id' 2>/dev/null)

# Obtener tareas de cada proyecto (secciones)
for proj_id in $project_ids; do
    sections=$(curl -s -X GET "https://api.todoist.com/api/v1/sections?project_id=$proj_id" \
        -H "Authorization: Bearer $TODOIST_TOKEN" | jq -r '.results // . | .[] | .id' 2>/dev/null)
    
    for section_id in $sections; do
        response=$(curl -s -X GET "https://api.todoist.com/api/v1/tasks?section_id=$section_id" \
            -H "Authorization: Bearer $TODOIST_TOKEN")
        process_tasks "$response"
    done
    
    response=$(curl -s -X GET "https://api.todoist.com/api/v1/tasks?project_id=$proj_id" \
        -H "Authorization: Bearer $TODOIST_TOKEN")
    process_tasks "$response"
done

# Tareas generales
response=$(curl -s -X GET "https://api.todoist.com/api/v1/tasks" \
    -H "Authorization: Bearer $TODOIST_TOKEN")
process_tasks "$response"