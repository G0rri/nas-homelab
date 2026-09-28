#!/bin/bash
#
# telegram.sh "mensaje"
# Envía un mensaje al bot de alertas del NAS. Pensado para que lo usen
# otros scripts (backups, SMART...).
#
# Lee TOKEN y CHAT_ID de .telegram.env (propietario root, permisos 600).
# Ese archivo está excluido de Syncthing con un patrón a ignorar.

CONF=/mnt/SSD_M2/Files/Scripts/.telegram.env

if [ ! -r "$CONF" ]; then
    echo "telegram.sh: no puedo leer $CONF (¿ejecutado sin sudo?)" >&2
    exit 1
fi
. "$CONF"

if [ -z "${TOKEN:-}" ] || [ -z "${CHAT_ID:-}" ]; then
    echo "telegram.sh: faltan TOKEN o CHAT_ID en $CONF" >&2
    exit 1
fi

if [ -z "${1:-}" ]; then
    echo "Uso: telegram.sh \"mensaje\"" >&2
    exit 1
fi

curl -fsS --max-time 20 -o /dev/null \
    --data-urlencode "chat_id=$CHAT_ID" \
    --data-urlencode "text=$1" \
    "https://api.telegram.org/bot$TOKEN/sendMessage"
