#!/bin/bash
#
# smart-check.sh
# Revisa el estado SMART de todos los discos del NAS y avisa por Telegram
# si algo no va bien. Los miércoles manda además un resumen aunque todo
# esté OK, para saber que el sistema de avisos sigue vivo.
#
# Cron: root, todos los días a las 03:30 (30 3 * * *).
#   - Los tests cortos se lanzan los miércoles a las 03:00 y se revisan a las 03:30.
#   - El largo se lanza el día 1 a las 02:00 y dura horas: se revisa el día 2.
#
# Uso manual (siempre con sudo):
#   sudo smart-check.sh            -> solo avisa si hay problemas
#   sudo smart-check.sh --resumen  -> manda el resumen siempre
#
# Los discos se detectan por modelo y tipo, no por nombre: sda, sdb...
# pueden cambiar entre arranques.

set -uo pipefail
export LC_ALL=C

SMARTCTL="${SMARTCTL:-/usr/sbin/smartctl}"
TELEGRAM="${TELEGRAM:-/mnt/SSD_M2/Files/Scripts/telegram.sh}"

DISCOS_ESPERADOS=5          # 3 HDD + Patriot SATA (boot) + NVMe
TEMP_MAX_HDD=50
TEMP_MAX_SSD=65
MAX_HORAS_SIN_TEST=200      # los cortos son semanales (168 h) + margen

# Patriot Burst Elite (boot-pool): su registro de autotests está mal
# formado, así que se juzga solo por sus contadores. Referencia 21/09/2026.
PATRIOT_MODELO="Burst Elite"
PATRIOT_RESERVA_REF=132

# NVMe (SSD_M2): 1 error de integridad acumulado ya existente el 21/09/2026,
# sin rastro en ZFS ni en el registro de errores del disco. Solo se avisa
# si el contador sube.
NVME_ERRORES_REF=1

PROBLEMAS=""
RESUMEN=""
DETECTADOS=0

problema() { PROBLEMAS="${PROBLEMAS}
• $*"; }
linea() { RESUMEN="${RESUMEN}
$*"; }

# Valor bruto de un atributo ATA (primer número de RAW_VALUE)
raw() { awk -v id="$2" '$1==id {print $10; exit}' <<<"$1" | grep -oE '^[0-9]+'; }

mayor_que() { [ -n "$1" ] && [ "$1" -gt "$2" ]; }

salud_general() {
    "$SMARTCTL" -H "$1" 2>/dev/null | grep -oE 'PASSED|FAILED' | head -n1
}

# Línea del autotest más reciente (ATA "# 1 ..." o NVMe " 0 ...")
ultimo_test() {
    "$SMARTCTL" -l selftest "$1" 2>/dev/null | grep -m1 -E '^(# ?1 | +0 )'
}

# ---------------------------------------------------------------------------

revisar_hdd() {
    local dev="$1" nom="$2" mod="$3" salud attrs realloc pend unc crc t poh test estado horas
    salud=$(salud_general "$dev")
    [ "$salud" = "PASSED" ] || problema "$nom ($mod): salud general ${salud:-ilegible}"

    attrs=$("$SMARTCTL" -A "$dev" 2>/dev/null)
    realloc=$(raw "$attrs" 5)
    pend=$(raw "$attrs" 197)
    unc=$(raw "$attrs" 198)
    crc=$(raw "$attrs" 199)
    t=$(raw "$attrs" 194)
    poh=$(raw "$attrs" 9)

    mayor_que "$realloc" 0 && problema "$nom: $realloc sectores reasignados (5)"
    mayor_que "$pend" 0    && problema "$nom: $pend sectores pendientes (197)"
    mayor_que "$unc" 0     && problema "$nom: $unc sectores incorregibles (198)"
    mayor_que "$crc" 0     && problema "$nom: $crc errores CRC (199). Sospechar antes del cable SATA"
    mayor_que "$t" "$TEMP_MAX_HDD" && problema "$nom: temperatura $t °C"

    test=$(ultimo_test "$dev")
    case "$test" in
        *"in progress"*)             estado="test en curso" ;;
        *"Completed without error"*) estado="último test OK" ;;
        "")                          estado="sin tests"
                                     problema "$nom: no hay ningún autotest registrado" ;;
        *)                           estado="ÚLTIMO TEST CON ERROR"
                                     problema "$nom: el último autotest ha fallado: $(tr -s ' ' <<<"$test")" ;;
    esac

    # ¿Se están lanzando los tests? (horas de vida al hacer el último test)
    horas=$(awk '{print $(NF-1)}' <<<"$test" | grep -oE '^[0-9]+')
    if [ -n "$horas" ] && [ -n "$poh" ] && [ $((poh - horas)) -gt "$MAX_HORAS_SIN_TEST" ]; then
        problema "$nom: el último autotest es de hace $(( (poh - horas) / 24 )) días. ¿Funciona el cron de los tests?"
    fi

    linea "$nom · $salud · $estado · ${t:-?} °C · reasig ${realloc:-?} · pend ${pend:-?}"
}

revisar_nvme() {
    local dev="$1" nom="$2" mod="$3" salud info crit media spare spare_min usado t test estado
    salud=$(salud_general "$dev")
    [ "$salud" = "PASSED" ] || problema "$nom ($mod): salud general ${salud:-ilegible}"

    info=$("$SMARTCTL" -A "$dev" 2>/dev/null)
    crit=$(awk -F: '/^Critical Warning/ {gsub(/ /,"",$2); print $2; exit}' <<<"$info")
    media=$(awk -F: '/^Media and Data Integrity Errors/ {gsub(/[ ,]/,"",$2); print $2; exit}' <<<"$info")
    spare=$(grep -m1 '^Available Spare:' <<<"$info" | grep -oE '[0-9]+')
    spare_min=$(grep -m1 '^Available Spare Threshold:' <<<"$info" | grep -oE '[0-9]+')
    usado=$(grep -m1 '^Percentage Used:' <<<"$info" | grep -oE '[0-9]+')
    t=$(grep -m1 '^Temperature:' <<<"$info" | grep -oE '[0-9]+' | head -n1)

    [ -n "$crit" ] && [ "$crit" != "0x00" ] && problema "$nom: aviso crítico NVMe $crit"
    mayor_que "$media" "$NVME_ERRORES_REF" && problema "$nom: errores de integridad de datos: $media (referencia $NVME_ERRORES_REF). Revisar con: zpool status -v SSD_M2"
    if [ -n "$spare" ] && [ -n "$spare_min" ] && [ "$spare" -le $((spare_min + 10)) ]; then
        problema "$nom: reserva disponible al $spare % (mínimo $spare_min %)"
    fi
    mayor_que "$usado" 80 && problema "$nom: desgaste al $usado %"
    mayor_que "$t" "$TEMP_MAX_SSD" && problema "$nom: temperatura $t °C"

    test=$(ultimo_test "$dev")
    case "$test" in
        *"in progress"*)             estado="test en curso" ;;
        *"Completed without error"*) estado="último test OK" ;;
        "")                          estado="sin tests" ;;
        *)                           estado="ÚLTIMO TEST CON ERROR"
                                     problema "$nom: el último autotest ha fallado: $(tr -s ' ' <<<"$test")" ;;
    esac

    linea "$nom · $salud · $estado · ${t:-?} °C · desgaste ${usado:-?} % · reserva ${spare:-?} % · err ${media:-?}"
}

revisar_patriot() {
    local dev="$1" nom="$2" mod="$3" salud attrs id v reserva desgaste t
    salud=$(salud_general "$dev")
    [ "$salud" = "PASSED" ] || problema "$nom ($mod, boot): salud general ${salud:-ilegible}"

    attrs=$("$SMARTCTL" -A "$dev" 2>/dev/null)
    for id in 5 160 196 199; do
        v=$(raw "$attrs" "$id")
        mayor_que "$v" 0 && problema "$nom (boot): atributo $id = $v (debería ser 0)"
    done
    reserva=$(raw "$attrs" 161)
    desgaste=$(raw "$attrs" 167)
    t=$(raw "$attrs" 194)

    if [ -n "$reserva" ] && [ "$reserva" -lt "$PATRIOT_RESERVA_REF" ]; then
        problema "$nom (boot): bloques de reserva (161) han bajado a $reserva (referencia $PATRIOT_RESERVA_REF)"
    fi
    mayor_que "$t" "$TEMP_MAX_SSD" && problema "$nom (boot): temperatura $t °C"

    linea "$nom (boot) · $salud · reserva ${reserva:-?} · desgaste medio ${desgaste:-?} · ${t:-?} °C"
}

# ---------------------------------------------------------------------------

while read -r nombre tran modelo; do
    case "$tran" in
        sata|sas|ata) ;;
        nvme) DETECTADOS=$((DETECTADOS + 1))
              revisar_nvme "/dev/$nombre" "$nombre" "$modelo"
              continue ;;
        *) continue ;;
    esac
    DETECTADOS=$((DETECTADOS + 1))
    if [[ "$modelo" == *"$PATRIOT_MODELO"* ]]; then
        revisar_patriot "/dev/$nombre" "$nombre" "$modelo"
    else
        revisar_hdd "/dev/$nombre" "$nombre" "$modelo"
    fi
done < <(lsblk -dno NAME,TRAN,MODEL)

if [ "$DETECTADOS" -ne "$DISCOS_ESPERADOS" ]; then
    problema "se han detectado $DETECTADOS discos y se esperaban $DISCOS_ESPERADOS"
fi

# ---------------------------------------------------------------------------

if [ -n "$PROBLEMAS" ]; then
    MSG="🔴 NAS · SMART: problemas detectados${PROBLEMAS}

Estado:${RESUMEN}"
    echo "$MSG"
    "$TELEGRAM" "$MSG" || echo "ERROR: no se ha podido avisar por Telegram" >&2
    exit 1
fi

MSG="🟢 NAS · SMART: todo en orden${RESUMEN}"
echo "$MSG"
if [ "${1:-}" = "--resumen" ] || [ "$(date +%u)" = "3" ]; then
    "$TELEGRAM" "$MSG" || echo "ERROR: no se ha podido avisar por Telegram" >&2
fi
exit 0
