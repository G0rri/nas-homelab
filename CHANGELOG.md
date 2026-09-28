# Changelog

Cambios relevantes en el NAS, del más reciente al más antiguo.

## 2026-09-28

- **Almacenamiento:** confirmado `SSD_M2` al 25,6 % (117 GiB) tras caducar los snapshots; ~179 GiB liberados en total.

## 2026-09-22

- **Jellyfin:** aceleración por hardware cambiada de QSV a VA-API tras los fallos con AV1 HDR ([incidencia](docs/incidencias/jellyfin-qsv-av1-hdr.md)).
- **Docker:** eliminadas 248 imágenes sin uso (~147 GB) y nuevo script mensual `docker-prune.sh` ([incidencia](docs/incidencias/ssd-m2-espacio-snapshots-docker.md)).
- **Almacenamiento:** revisión del espacio retenido por snapshots en `SSD_M2`.
- **HTTPS:** certificado único del NAS para la interfaz de TrueNAS y las apps; procedimiento documentado.

## 2026-09-21

- **Copias:** definida la estrategia en tres niveles, con el HDD del PC como última salvaguarda.
- **Copias:** nuevo `backups-semanales.sh` (Jellyfin + Immich) con verificación de integridad y avisos por Telegram. Sustituye al script anterior, que solo copiaba Jellyfin.
- **Copias:** bundle de configuración de TrueNAS cifrado y exportación cifrada de Vaultwarden.
- **Syncthing:** carpetas renombradas con el criterio `origen → destino / contenido` y versionado escalonado de 365 días en el PC.
- **Syncthing:** originales de Immich sincronizados al PC mediante un montaje de solo lectura.
- **Syncthing:** flujo de la música invertido (se gestiona desde el PC).
- **Monitorización:** nuevo `smart-check.sh` con resumen semanal por Telegram. SSD de arranque excluido de los autotests ([incidencia](docs/incidencias/ssd-arranque-falso-positivo-smart.md)).
- **Jellyfin:** trickplay movido junto a los medios (11 GB liberados en el NVMe).

## 2026-09-19

- **BIOS:** actualizada de F16 a F21d; Resizable BAR activado para la Arc A380.
- **Replicación:** nueva tarea diaria `SSD_M2/Apps_data` → `HDD_RAID5/Replicas`.
- **Jellyfin:** ajuste de la transcodificación por hardware.
- **Sistema:** limpieza de *boot environments* antiguos.

## 2026-08

- **HTTPS:** CA propia y primer certificado del NAS, para Vaultwarden.
