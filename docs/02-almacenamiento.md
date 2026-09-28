# 2. Almacenamiento (ZFS)

## Pools

| Pool | Disposición | Discos | Capacidad útil | Ocupación (sep. 2026) | Uso |
|---|---|---|---|---|---|
| `HDD_RAID5` | RAIDZ1 (3 discos) | 3 × 4 TB HDD | 7,14 TiB | ~60 % | Multimedia, galería, libros y réplicas |
| `SSD_M2` | Disco único | NVMe 512 GB | 457 GiB | 25,6 % | Datos de las apps y archivos de uso diario |
| `boot-pool` | Disco único | SSD SATA 120 GB | 111 GiB | ~35 % | Solo el sistema operativo |

- **RAIDZ1** es el equivalente en ZFS a RAID 5 (de ahí el nombre del pool): tolera el fallo de un disco.
- **`SSD_M2` no tiene redundancia.** Se compensa replicándolo cada día a `HDD_RAID5` y enviando lo importante a otro equipo (ver [Copias de seguridad](05-copias-de-seguridad.md)). Tiene Auto TRIM activado.
- Por encima del 80 % de ocupación ZFS fragmenta más y pierde rendimiento, así que vigilo sobre todo `HDD_RAID5`.

## Datasets

### HDD_RAID5

| Dataset | SMB | Contenido |
|---|---|---|
| `Books` | — | Libros |
| `Gallery` | ✅ | Galería de fotos (independiente de Immich) |
| `Media` | ✅ | Películas y series para Jellyfin, con las miniaturas *trickplay* junto a cada vídeo |
| `Replicas` | — | Destino de la replicación de `SSD_M2/Apps_data` (solo lectura) |

### SSD_M2

| Dataset | Contenido |
|---|---|
| `Apps_data` | Un sub-dataset por aplicación con su configuración y datos |
| `Files` | Archivos de uso diario, carpeta centralizada de copias (`Backups/`) y scripts (`Scripts/`) |
| `Minecraft` | Datos de Minecraft |
| `ix-apps` | Gestionado por TrueNAS: contenedores e imágenes de Docker de las apps |

Tener un dataset por app permite hacer snapshots, replicar y restaurar cada app por separado.

## Snapshots automáticos

Todas las tareas tienen una retención de **1 semana** y el esquema de nombres `auto-%Y-%m-%d_%H-%M`.

| Dataset | Frecuencia | Recursivo |
|---|---|---|
| `SSD_M2/Apps_data` | Cada hora | Sí |
| `SSD_M2/Files` | Diario, 00:00 | No |
| `HDD_RAID5/Gallery` | Diario, 00:00 | Sí |
| `HDD_RAID5/Media` | Diario, 00:00 | Sí |

> La tarea de `Files` no es recursiva: si algún día se crea un dataset hijo, necesitará su propia tarea.

## Scrubs

| Pool | Programación |
|---|---|
| `HDD_RAID5` | Sábados, 00:00 |
| `SSD_M2` | Domingos, 00:00 |
| `boot-pool` | Manual (*Sistema › Boot › Scrub Boot Pool*) |

Las tareas tienen un umbral de 35 días (*Threshold Days*): aunque estén programadas cada semana, en la práctica cada pool pasa un scrub cada ~5 semanas. El último scrub de `SSD_M2` (30/08/2026) duró 29 minutos y terminó con 0 errores.

## Gestión del espacio

### Espacio retenido por snapshots

Un dataset puede ocupar mucho más que sus datos vivos si se han borrado o movido muchos archivos: lo borrado sigue en los snapshots hasta que caducan. Se revisa con la columna `USEDSNAP`:

```bash
sudo zfs list -o space -r SSD_M2
```

Caso conocido y aceptado: la base de datos PostgreSQL de Joplin (~580 MiB) retiene ~12 GiB en snapshots por la escritura continua de Postgres (~25 MB por snapshot horario). Está acotado por la retención de una semana y no crece; además, la replicación depende de esos snapshots horarios, así que se deja como está.

### Imágenes de Docker

TrueNAS guarda las imágenes de las apps en `ix-apps`, y las versiones antiguas se acumulan con cada actualización. En septiembre de 2026 había 268 imágenes (solo 20 en uso) ocupando 99 GiB. Desde entonces `docker-prune.sh` las limpia cada mes (ver [Automatización](07-automatizacion.md)).

```bash
sudo docker system df   # espacio recuperable
```

Análisis completo: [SSD_M2 al 65 % por snapshots e imágenes de Docker](incidencias/ssd-m2-espacio-snapshots-docker.md).

## Boot environments

Tras cada actualización de TrueNAS se conservan solo los tres últimos entornos de arranque (el activo y los dos anteriores): permiten volver a una versión anterior sin llenar el `boot-pool`.
