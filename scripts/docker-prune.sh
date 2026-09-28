#!/bin/bash
#
# docker-prune.sh
# Borra las imágenes de Docker que no usa ningún contenedor (restos de las
# actualizaciones de las apps) y manda un resumen por Telegram con lo liberado.
# Solo toca imágenes: ni volúmenes ni contenedores.
#
# Cron: "Limpieza mensual de imágenes Docker", root, día 15 a las 06:00
#       (0 6 15 * *), con Hide Standard Output/Error marcados.

set -uo pipefail

SCRIPTS="/mnt/SSD_M2/Files/Scripts"
TELEGRAM="$SCRIPTS/telegram.sh"
DATASET="SSD_M2/ix-apps/docker"
POOL="SSD_M2"
DOCKER="/usr/bin/docker"
ZFS="/usr/sbin/zfs"
ZPOOL="/usr/sbin/zpool"

avisar()  { "$TELEGRAM" "$1"; }
legible() { numfmt --to=iec-i --suffix=B "$1"; }
num_imagenes() { "$DOCKER" images -q 2>/dev/null | sort -u | wc -l; }

# --- Docker tiene que estar vivo ---------------------------------------------
if ! "$DOCKER" info >/dev/null 2>&1; then
    avisar "🔴 docker-prune: Docker no responde (¿servicio de apps parado?). No se ha limpiado nada."
    exit 1
fi

ANTES=$("$ZFS" list -Hp -o used "$DATASET" 2>/dev/null)
IMG_ANTES=$(num_imagenes)

# --- Limpieza ----------------------------------------------------------------
if ! SALIDA=$("$DOCKER" image prune -a -f 2>&1); then
    avisar "🔴 docker-prune: ha fallado la limpieza.
$(echo "$SALIDA" | tail -n 5)"
    exit 1
fi

# ZFS libera el espacio en segundo plano: esperar a que se refleje
"$ZPOOL" sync "$POOL" 2>/dev/null
sleep 10

DESPUES=$("$ZFS" list -Hp -o used "$DATASET" 2>/dev/null)
IMG_DESPUES=$(num_imagenes)
DOCKER_DICE=$(echo "$SALIDA" | grep -oP 'Total reclaimed space: \K.*')

# --- Resumen -----------------------------------------------------------------
MSG="🧹 Limpieza mensual de Docker
Imágenes: $IMG_ANTES → $IMG_DESPUES
Docker dice: ${DOCKER_DICE:-0B} recuperados"

if [[ -n "$ANTES" && -n "$DESPUES" ]]; then
    LIBERADO=$(( ANTES - DESPUES ))
    (( LIBERADO < 0 )) && LIBERADO=0
    MSG="$MSG
$DATASET: $(legible "$ANTES") → $(legible "$DESPUES") (−$(legible "$LIBERADO"))"
else
    MSG="$MSG
(No se ha podido leer el tamaño de $DATASET)"
fi

avisar "$MSG"
exit 0
