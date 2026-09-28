# Jellyfin: error -17 con QSV al transcodificar AV1 HDR

**Fecha:** 22/09/2026 · **Área:** transcodificación · **Estado:** resuelto

## Síntomas

Con la aceleración por hardware en **Intel QuickSync (QSV)**, la transcodificación de vídeos AV1 HDR con mapeo de tonos fallaba con el error `-17`.

## Investigación

- El hardware y el driver admiten AV1: `vainfo` dentro del contenedor muestra decodificación y codificación por hardware de AV1, HEVC 10 bits, H.264 y VP9 (driver iHD 26.2.4).
- El firmware HuC está cargado y autenticado (`dmesg | grep -i huc`).
- El fallo aparecía solo en la combinación AV1 + HDR + mapeo de tonos con QSV.

## Causa

Sin confirmar. Todo apunta a la ruta de QSV en esa combinación concreta, no al hardware ni al driver.

## Solución

Cambiar la aceleración a **VA-API** sobre el mismo dispositivo (`/dev/dri/renderD128`), con mapeo de tonos por **OpenCL** (BT.2390).

**Prueba posterior:** película 4K AV1 HDR10 → H.264 1080p con un **7-10 % de CPU**, y un **10-17 %** con subtítulos PGS incrustados.

## Lecciones aprendidas

- En las Intel Arc bajo Linux, VA-API es una alternativa sólida a QSV.
- Cuando no se puede confirmar la causa exacta, es mejor documentarlo como tal y dejar constancia de la prueba que valida la solución.
