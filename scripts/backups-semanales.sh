#!/bin/bash
#
# backups-semanales.sh
# Copia a Files/Backups la copia más reciente de Jellyfin y el volcado de
# base de datos más reciente de Immich, con el propietario correcto, y deja
# solo la última de cada una en el destino. Syncthing ("NAS → HDD / Files")
# las lleva al HDD del PC, donde el versionado conserva las de semanas
# anteriores durante 365 días.
#
# Sustituye a jellyfin-backup-sync.sh.
# Cron: root, domingos 05:00 (0 5 * * 0).
# Si algo falla, avisa por Telegram con telegram.sh (el cron de TrueNAS
# manda los errores por correo, que no está configurado).
# Probar a mano siempre con sudo.

set -uo pipefail

BACKUPS=/mnt/SSD_M2/Files/Backups
PROPIETARIO="usuario:apps"   # dueño de las copias: usuario de los datos y grupo apps de TrueNAS
TELEGRAM=/mnt/SSD_M2/Files/Scripts/telegram.sh
ERRORES=0
MENSAJES=""

error() {
    echo "ERROR: $*" >&2
    ERRORES=$((ERRORES + 1))
    MENSAJES="${MENSAJES}
• $*"
}

# Comprueba que el archivo no está dañado, según su extensión.
verificar() {
    case "$1" in
        *.gz)  gzip -t "$1" 2>/dev/null ;;
        *.zip) python3 -c 'import sys, zipfile
sys.exit(1 if zipfile.ZipFile(sys.argv[1]).testzip() else 0)' "$1" 2>/dev/null ;;
        *)     return 0 ;;
    esac
}

# copiar_ultimo NOMBRE ORIGEN PATRÓN DÍAS_MÁX LIMPIAR_ORIGEN
#   NOMBRE:         subcarpeta de destino dentro de $BACKUPS
#   DÍAS_MÁX:       avisa si la copia más reciente es más antigua (0 = no mirar)
#   LIMPIAR_ORIGEN: si/no, borrar también las antiguas en el origen
copiar_ultimo() {
    local nombre="$1" origen="$2" patron="$3" dias="$4" limpiar="$5"
    local destino="$BACKUPS/$nombre" nuevo base

    nuevo=$(ls -1t "$origen"/$patron 2>/dev/null | head -n1)
    if [ -z "$nuevo" ]; then
        error "$nombre: no hay ninguna copia en $origen"
        return
    fi
    base=$(basename "$nuevo")

    if [ "$dias" -gt 0 ] && [ -n "$(find "$nuevo" -mmin +"$((dias * 1440))")" ]; then
        error "$nombre: la copia más reciente ($base) tiene más de $dias días. ¿Se ha parado la copia automática?"
    fi

    if ! verificar "$nuevo"; then
        error "$nombre: $base está dañada en el origen, no se copia"
        return
    fi

    mkdir -p "$destino"
    chown "$PROPIETARIO" "$destino"

    # Solo copia si ha cambiado (evita reescribir lo mismo cada semana)
    if ! cmp -s "$nuevo" "$destino/$base"; then
        if ! cp -f --preserve=timestamps "$nuevo" "$destino/$base"; then
            error "$nombre: ha fallado la copia de $base"
            return
        fi
        if ! verificar "$destino/$base"; then
            rm -f "$destino/$base"
            error "$nombre: la copia de $base ha salido dañada en el destino"
            return
        fi
    fi
    chown "$PROPIETARIO" "$destino/$base"

    # Dejar solo la más reciente en el destino
    find "$destino" -maxdepth 1 -name "$patron" ! -name "$base" -delete

    # Y en el origen, solo si se pide (Jellyfin no deja borrar desde su web;
    # Immich gestiona su propia retención y no se toca)
    if [ "$limpiar" = "si" ]; then
        ls -1t "$origen"/$patron 2>/dev/null | tail -n +2 | xargs -r rm -f
    fi

    echo "$nombre: OK -> $destino/$base"
}

# --------------------------------------------------------------------------
#             NOMBRE    ORIGEN                                        PATRÓN                       DÍAS  LIMPIAR
copiar_ultimo Jellyfin  /mnt/SSD_M2/Apps_data/Jellyfin/config/data/backups 'jellyfin-backup-*.zip'   0     si
copiar_ultimo Immich    /mnt/SSD_M2/Apps_data/Immich/data/backups          'immich-db-backup-*.sql.gz' 2   no
# --------------------------------------------------------------------------

if [ "$ERRORES" -gt 0 ]; then
    "$TELEGRAM" "⚠️ NAS · backups semanales: $ERRORES problema(s)${MENSAJES}" \
        || echo "ERROR: además, no se ha podido avisar por Telegram" >&2
    exit 1
fi
exit 0
