# SSD_M2 al 65 % por snapshots e imágenes de Docker

**Fecha:** 22/09/2026 · **Área:** almacenamiento · **Estado:** resuelto y automatizado

## Síntomas

El pool `SSD_M2` (NVMe de 457 GiB útiles) llegó a **296 GiB usados (64,6 %)**, bastante más de lo que ocupaban los datos.

## Investigación

**1. Espacio retenido por snapshots** (`sudo zfs list -o space -r SSD_M2`, columna `USEDSNAP`):

| Dataset | Datos vivos | En snapshots | Motivo |
|---|---|---|---|
| `Files` | 40,2 GiB | 78,8 GiB | Reorganización grande de carpetas |
| `Apps_data/Jellyfin/config` | 4,9 GiB | 26,4 GiB | Trickplay movido a `Media` y copia completa borrada |
| `Apps_data/Joplin/postgres` | 0,6 GiB | ~12 GiB | Escritura continua de PostgreSQL (normal y acotado) |

**2. Imágenes de Docker** (`sudo docker system df`): el dataset `ix-apps/docker` ocupaba **99 GiB** con **268 imágenes, de las que solo 20 estaban en uso**. Cada actualización de una app deja atrás la imagen anterior.

## Causa

- Lo que se borra o se mueve sigue ocupando espacio mientras existan snapshots que lo referencien.
- TrueNAS no borra las imágenes de Docker antiguas tras actualizar las apps.

## Solución

- `sudo docker image prune -a`: ~147 GB recuperados según Docker.
- Nuevo script mensual `docker-prune.sh` que borra las imágenes sin uso y envía un resumen por Telegram con lo liberado.
- El espacio de los snapshots se libera solo al caducar (retención de una semana), así que no hacía falta borrarlos a mano.

## Resultado

Comprobado el 28/09/2026, una vez caducados los snapshots:

| | Antes (22/09) | Después (28/09) |
|---|---|---|
| Usado | 296 GiB | **117 GiB** |
| Ocupación | 64,6 % | **25,6 %** |
| Disponible | ~161 GiB | **340 GiB** |

**~179 GiB liberados** entre la limpieza de Docker y la caducidad de los snapshots, sin tener que borrar ningún snapshot a mano.

## Lecciones aprendidas

- Después de una reorganización grande hay que contar con que el espacio no se libera hasta que caducan los snapshots.
- `zfs list -o space` es la herramienta para saber dónde está el espacio de verdad.
- Las tareas de limpieza deben estar automatizadas y avisar de que se han ejecutado.
