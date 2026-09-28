# Incidencias

Problemas reales encontrados en el NAS, con el diagnóstico, la causa y la solución aplicada. Cada informe sigue la misma estructura: síntomas, investigación, causa, solución y lecciones aprendidas.

| Incidencia | Área | Resultado |
|---|---|---|
| [Falso positivo S.M.A.R.T. en el SSD de arranque](ssd-arranque-falso-positivo-smart.md) | Monitorización | Disco excluido de los autotests y vigilado por contadores |
| [Error de integridad histórico en el NVMe](nvme-error-integridad.md) | Almacenamiento | Sin impacto en los datos; valor de referencia en el script |
| [SSD_M2 al 65 % por snapshots e imágenes de Docker](ssd-m2-espacio-snapshots-docker.md) | Almacenamiento | De 296 a 117 GiB usados y limpieza mensual automatizada |
| [Jellyfin: error -17 con QSV en AV1 HDR](jellyfin-qsv-av1-hdr.md) | Transcodificación | Cambio a VA-API |
| [Tirones con AV1 en una tablet Android](tablet-av1-tirones.md) | Reproducción | Transcodificación forzada desde el cliente |
