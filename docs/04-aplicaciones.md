# 4. Aplicaciones

Todas las aplicaciones se instalan desde el **catálogo oficial de TrueNAS** (*Apps › Discover Apps*). Cada una guarda su configuración y datos en su propio dataset dentro de `SSD_M2/Apps_data`, así que hereda los snapshots cada hora y la replicación diaria.

| App | Función | Notas |
|---|---|---|
| **Immich** | Fotos y vídeos del móvil (alternativa a Google Fotos) | v3.2 con PostgreSQL 18 |
| **Jellyfin** | Servidor multimedia | Transcodificación por hardware con Intel Arc → [detalle](08-jellyfin-transcodificacion.md) |
| **Vaultwarden** | Gestor de contraseñas compatible con Bitwarden | HTTPS con CA propia |
| **Joplin Server** | Sincronización de notas | PostgreSQL |
| **Syncthing** | Sincronización NAS ↔ PC ↔ móvil | Pieza central de las [copias de seguridad](05-copias-de-seguridad.md) |
| **WG-Easy** | Servidor WireGuard y gestión de clientes | Única puerta de entrada desde Internet |
| **Kavita** | Biblioteca de libros y cómics | |
| **Filebrowser Quantum** | Explorador de archivos web | Accesos a `Files`, `Gallery`, `Books` y `Minecraft` |
| **Dockge** | Gestor de stacks de Docker Compose | Solo para stacks propios (ver abajo) |

## Dockge y stacks propios

Las apps del catálogo se gestionan desde la interfaz de TrueNAS. Dockge se usa **solo** para dos stacks propios de Docker Compose que no existen en el catálogo:

| Stack | Función |
|---|---|
| `no-ip` | Mantiene actualizado el DNS dinámico con la IP pública de casa |
| `web-local` | Página HTML + CSS para hacer pruebas dentro de la red local |

Dockge también muestra, en solo lectura, los contenedores `ix-*` que TrueNAS crea para sus apps, pero estos se gestionan siempre desde TrueNAS.

## Immich: dónde están los datos

Immich tiene dos sub-datasets, y cada parte se protege de una forma distinta:

| Ruta | Contenido | Tamaño | Protección |
|---|---|---|---|
| `data/upload` | **Originales** de fotos y vídeos | ~12 GiB | Snapshots + réplica + Syncthing al PC |
| `data/encoded-video`, `data/thumbs` | Derivados, regenerables | ~17 GiB | Snapshots + réplica |
| `data/backups` | Volcados diarios automáticos de la BD (se conservan 14) | ~660 MiB | Snapshots + réplica + script semanal al PC |
| `postgres18` | Base de datos viva: álbumes, caras y metadatos | ~511 MiB | Snapshots + réplica |

- La plantilla de almacenamiento no está activada, por eso los originales están en `upload` y `library` está vacía. Syncthing sincroniza la carpeta `data` completa (excluyendo derivados y volcados) para que la copia siga funcionando si algún día se activa.
- **Para restaurar Immich hacen falta las dos partes**: los originales y un volcado de la base de datos. El volcado no contiene fotos, y las fotos sin base de datos pierden álbumes y caras.

## Vaultwarden

Sus datos solo existen en el NAS y en la réplica interna. La copia independiente es una **exportación cifrada con contraseña** que viaja al PC con el resto de copias (ver [Copias de configuración](05-copias-de-seguridad.md#copias-de-configuración)).
