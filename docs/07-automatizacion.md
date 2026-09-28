# 7. Automatización

## Scripts propios

El código está en [`scripts/`](../scripts/README.md).

| Script | Función | Cron |
|---|---|---|
| [`telegram.sh`](../scripts/telegram.sh) | Envía un mensaje al bot de alertas; lo reutilizan el resto de scripts | — |
| [`smart-check.sh`](../scripts/smart-check.sh) | Revisión S.M.A.R.T. de todos los discos ([detalle](06-monitorizacion.md#qué-revisa-smart-checksh)). Con `--resumen` fuerza el envío del resumen | `30 3 * * *` |
| [`backups-semanales.sh`](../scripts/backups-semanales.sh) | Copia y verifica los volcados de Jellyfin e Immich en la carpeta de copias ([detalle](05-copias-de-seguridad.md#script-semanal-de-copias-de-apps)) | `0 5 * * 0` |
| [`docker-prune.sh`](../scripts/docker-prune.sh) | Borra las imágenes de Docker sin uso y envía siempre un resumen 🧹 con el espacio liberado. No toca volúmenes ni contenedores | `0 6 15 * *` |

### Convenciones

- Los scripts viven en un dataset (`Files/Scripts`), **nunca en `/root`**: al actualizar TrueNAS cambia el *boot environment* y se perderían. Además, así entran en los snapshots y en la copia del PC.
- Se ejecutan como `root` desde *Sistema › Advanced Settings › Cron Jobs*, y siempre se prueban antes a mano con `sudo`.
- Los secretos se leen de un `.env` (`root:root`, permisos `600`) excluido de la sincronización.
- Como la salida del cron no llega a ningún sitio, cada script es responsable de avisar de sus propios errores.
- Los discos se identifican por modelo, no por nombre de dispositivo, y las copias se verifican antes y después de moverlas.

## Calendario de tareas programadas

Horarios escalonados para que las tareas pesadas no se solapen:

| Cuándo | Tarea |
|---|---|
| Cada hora | Snapshots de `Apps_data` |
| Diario, 00:00 | Snapshots de `Gallery`, `Media` y `Files` |
| Sábados / domingos, 00:00 | Scrub de `HDD_RAID5` / `SSD_M2` (umbral de 35 días) |
| Diario, 02:00 | Volcado automático de la BD de Immich (lo hace la propia app) |
| Día 1 del mes, 02:00 | Test S.M.A.R.T. largo de los HDD (dura varias horas) |
| Miércoles, 03:00 | Test S.M.A.R.T. corto |
| Diario, 03:30 | `smart-check.sh` (resumen 🟢 los miércoles) |
| Diario, 04:00 | Replicación `Apps_data` → `HDD_RAID5/Replicas` |
| Domingos, 05:00 | `backups-semanales.sh` |
| Día 15 del mes, 06:00 | `docker-prune.sh` |
