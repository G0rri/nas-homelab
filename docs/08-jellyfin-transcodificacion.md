# 8. Jellyfin y transcodificación por hardware

La GPU **Intel Arc A380** se usa para transcodificar en Jellyfin (el Ryzen 5 3600 no tiene gráfica integrada).

## Configuración

| Ajuste | Valor | Motivo |
|---|---|---|
| Aceleración por hardware | **VA-API** (`/dev/dri/renderD128`) | QSV fallaba con AV1 HDR y mapeo de tonos → [incidencia](incidencias/jellyfin-qsv-av1-hdr.md) |
| Decodificación por hardware | Todos los códecs: H.264, HEVC, MPEG-2, VC-1, VP8, VP9, AV1, HEVC/VP9 10 bits y HEVC RExt | |
| Codificación por hardware | Activada, permitiendo HEVC y AV1 | |
| Codificadores de bajo consumo de Intel | Activados | En las Arc es la ruta de codificación normal; requiere el firmware HuC (verificado) |
| Mapeo de tonos | OpenCL, BT.2390, modo automático | Cubre HDR10, HLG y Dolby Vision |
| Mapeo de tonos por VPP | Desactivado | Solo admite HDR10 |
| Limitar transcodificaciones | Desactivado | Provocaba cortes al saltar por la línea de tiempo |
| Resto | Valores por defecto | CRF 28/23, desentrelazado YADIF, borrado de segmentos |

## Verificación

```bash
# Firmware HuC cargado y autenticado (necesario para los codificadores de bajo consumo)
sudo dmesg | grep -i huc

# Perfiles VA-API disponibles dentro del contenedor de Jellyfin
sudo docker exec ix-jellyfin-jellyfin-1 /usr/lib/jellyfin-ffmpeg/vainfo --display drm --device /dev/dri/renderD128
```

Resultado: driver iHD 26.2.4 con decodificación y codificación por hardware de AV1, HEVC 10 bits, H.264 y VP9, y firmware HuC `dg2_huc_gsc.bin` 7.10.16.

## Prueba real

| Origen | Destino | Uso de CPU |
|---|---|---|
| Película 4K AV1 HDR10 | H.264 1080p | 7-10 % |
| La misma, con subtítulos PGS incrustados | H.264 1080p | 10-17 % |

Los subtítulos de imagen (PGS) se superponen por CPU, de ahí la diferencia.

> Observación: FFmpeg no inicializa VA-API con `driver=iHD` y hace el mapeo de tonos con OpenCL copiando fotogramas a RAM (`hwdownload`/`hwupload`) en lugar de usar la ruta directa. Funciona bien y con poco uso de CPU, así que se ha dejado así.

## Trickplay (miniaturas de la línea de tiempo)

Las miniaturas se guardan **junto a cada vídeo** (carpetas `*.trickplay` en `HDD_RAID5/Media`) en lugar de en la configuración de Jellyfin:

- El trickplay dentro de la configuración, que está en el NVMe, pasó de 11 GB a 24 MB.
- Las miniaturas quedan en el pool de HDD, junto al contenido al que pertenecen.
- Requiere que Jellyfin tenga permiso de escritura en `Media` (verificado).

Ajustes de generación: intervalo de 5000 ms, anchura de 320 px, mosaico de 10 × 10, solo fotogramas clave y prioridad baja.

## Copia de seguridad

Solo se copia la **base de datos** (~29 MB). Metadatos, subtítulos y trickplay (~14 GB) se pueden regenerar. Ver [Copias de seguridad](05-copias-de-seguridad.md#script-semanal-de-copias-de-apps).
