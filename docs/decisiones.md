# Decisiones técnicas

Registro de decisiones en formato ADR (*Architecture Decision Record*) simplificado: contexto, decisión y consecuencias.

| # | Decisión | Área |
|---|---|---|
| [01](#adr-01--wireguard-autogestionado-en-lugar-de-tailscale) | WireGuard autogestionado en lugar de Tailscale | Red |
| [02](#adr-02--sin-reverse-proxy) | Sin reverse proxy | Red |
| [03](#adr-03--ca-propia-y-http-para-las-apps-de-android) | CA propia y HTTP para las apps de Android | Seguridad |
| [04](#adr-04--alertas-por-telegram-y-avisos-desde-los-propios-scripts) | Alertas por Telegram y avisos desde los propios scripts | Monitorización |
| [05](#adr-05--smart-con-cron-y-un-script-propio) | S.M.A.R.T. con cron y un script propio | Monitorización |
| [06](#adr-06--excluir-el-ssd-de-arranque-de-los-autotests) | Excluir el SSD de arranque de los autotests | Monitorización |
| [07](#adr-07--el-hdd-del-pc-con-versionado-como-última-salvaguarda) | El HDD del PC con versionado como última salvaguarda | Copias |
| [08](#adr-08--el-contenido-recuperable-no-sale-del-nas) | El contenido recuperable no sale del NAS | Copias |
| [09](#adr-09--sincronizar-la-carpeta-data-completa-de-immich) | Sincronizar la carpeta `data` completa de Immich | Copias |
| [10](#adr-10--exportación-de-vaultwarden-protegida-por-contraseña) | Exportación de Vaultwarden protegida por contraseña | Copias |
| [11](#adr-11--copia-de-jellyfin-solo-de-la-base-de-datos) | Copia de Jellyfin solo de la base de datos | Copias |
| [12](#adr-12--aceptar-el-churn-de-snapshots-de-postgresql) | Aceptar el *churn* de snapshots de PostgreSQL | Almacenamiento |
| [13](#adr-13--va-api-en-lugar-de-qsv-en-jellyfin) | VA-API en lugar de QSV en Jellyfin | Multimedia |
| [14](#adr-14--trickplay-junto-a-los-medios) | Trickplay junto a los medios | Multimedia |
| [15](#adr-15--música-gestionada-desde-el-pc) | Música gestionada desde el PC | Sincronización |
| [—](#descartado) | Opciones descartadas | — |

---

## ADR-01 · WireGuard autogestionado en lugar de Tailscale

- **Contexto:** necesito acceder al NAS desde fuera de casa. Tailscale funcionaba, pero tenía limitaciones de usuarios.
- **Decisión:** servidor WireGuard propio gestionado con WG-Easy, con DNS dinámico mediante No-IP. El cliente oficial de No-IP para la actualización automática es de pago, así que la IP se actualiza con un contenedor propio en Dockge.
- **Consecuencias:** control total y sin límites de usuarios, a cambio de abrir **un único puerto** en el router y mantener el DNS dinámico.

## ADR-02 · Sin reverse proxy

- **Contexto:** todo el acceso externo pasa por la VPN.
- **Decisión:** no usar reverse proxy (Nginx Proxy Manager, Traefik, Caddy…); las apps se usan por IP y puerto.
- **Consecuencias:** menos piezas que mantener y nada expuesto salvo WireGuard. A cambio, el HTTPS se configura app por app con un certificado emitido para la IP del NAS.

## ADR-03 · CA propia y HTTP para las apps de Android

- **Contexto:** TrueNAS 25.10 ya no puede crear CAs ni certificados, y las apps de Android no confían en CAs instaladas por el usuario.
- **Decisión:** CA propia firmada con OpenSSL en el PC para la interfaz de TrueNAS, Vaultwarden y Dockge. Jellyfin y las apps que se usan desde Android se quedan en HTTP.
- **Consecuencias:** HTTPS sin avisos en el PC. El tráfico HTTP solo circula por la red local o dentro del túnel WireGuard, que ya lo cifra. El certificado se renueva a mano cada 3 años.

## ADR-04 · Alertas por Telegram y avisos desde los propios scripts

- **Contexto:** TrueNAS solo ofrece correo o Telegram (no ntfy), y la salida de los *cron jobs* se envía por correo.
- **Decisión:** alertas nativas de TrueNAS por Telegram y un `telegram.sh` reutilizable para que cada script avise de sus propios errores. El correo no se configura.
- **Consecuencias:** un único canal de avisos. Los scripts importantes envían también un resumen periódico aunque todo vaya bien, para que su ausencia delate un fallo.

## ADR-05 · S.M.A.R.T. con cron y un script propio

- **Contexto:** TrueNAS 25.10 eliminó `smartd` y la programación de tests S.M.A.R.T.
- **Decisión:** tests corto y largo programados con cron y `smartctl`, más `smart-check.sh` para revisar los resultados cada día.
- **Consecuencias:** umbrales adaptados a cada disco y detección de que los tests han dejado de ejecutarse, a cambio de mantener el script.

## ADR-06 · Excluir el SSD de arranque de los autotests

- **Contexto:** el firmware del SSD de arranque devuelve un registro de autotests mal formado que TrueNAS interpreta como fallo ([incidencia](incidencias/ssd-arranque-falso-positivo-smart.md)).
- **Decisión:** sacarlo de los tests programados y vigilarlo por sus contadores, con valores de referencia documentados.
- **Consecuencias:** sin falsos positivos. Si falla, el disco solo contiene el sistema y se recupera reinstalando y cargando el bundle de configuración.

## ADR-07 · El HDD del PC con versionado como última salvaguarda

- **Contexto:** no hay más discos para una copia fuera de casa, y Syncthing replica también los borrados.
- **Decisión:** todo lo importante acaba en el HDD del PC con **versionado escalonado de 365 días** en el lado receptor.
- **Consecuencias:** protección frente a borrados, errores y fallos del NAS. Riesgo asumido: un incendio, robo o ransomware que afecte al NAS y al PC a la vez.

## ADR-08 · El contenido recuperable no sale del NAS

- **Contexto:** el HDD del PC tiene 1,5 TB y el pool de datos, 7 TiB.
- **Decisión:** multimedia y libros solo tienen RAIDZ1 y snapshots; se pueden volver a conseguir.
- **Consecuencias:** la copia externa se reserva para lo que no se puede reemplazar.

## ADR-09 · Sincronizar la carpeta `data` completa de Immich

- **Contexto:** los originales están hoy en `upload`, pero si se activa la plantilla de almacenamiento pasarán a `library`.
- **Decisión:** sincronizar `data` entera, excluyendo derivados (`thumbs`, `encoded-video`) y volcados (`backups`), con un montaje de solo lectura.
- **Consecuencias:** la copia sigue funcionando aunque cambie la organización interna de Immich, y Syncthing no puede modificar nada en el origen.

## ADR-10 · Exportación de Vaultwarden protegida por contraseña

- **Contexto:** la exportación cifrada "con cuenta restringida" solo se puede importar en la misma cuenta, y esa cuenta vive en el propio NAS.
- **Decisión:** exportar en `.json` cifrado con contraseña, guardando la contraseña fuera del gestor.
- **Consecuencias:** la copia se puede restaurar aunque se pierda el NAS por completo. No incluye adjuntos.

## ADR-11 · Copia de Jellyfin solo de la base de datos

- **Contexto:** una copia completa ocupa ~14 GB, casi todo regenerable (metadatos, subtítulos, trickplay).
- **Decisión:** copiar solo la base de datos (~29 MB).
- **Consecuencias:** copias ligeras. Tras una restauración, Jellyfin vuelve a generar lo que falte. La copia en la app es manual.

## ADR-12 · Aceptar el *churn* de snapshots de PostgreSQL

- **Contexto:** la base de datos de Joplin (~580 MiB) retiene ~12 GiB en snapshots horarios por la escritura continua de Postgres.
- **Decisión:** dejarlo así.
- **Consecuencias:** el espacio está acotado por la retención de una semana y no crece, y la replicación depende de esos snapshots horarios.

## ADR-13 · VA-API en lugar de QSV en Jellyfin

- **Contexto:** con QSV, la transcodificación de AV1 HDR con mapeo de tonos fallaba con el error -17 ([incidencia](incidencias/jellyfin-qsv-av1-hdr.md)).
- **Decisión:** usar VA-API sobre el mismo dispositivo y mapeo de tonos por OpenCL.
- **Consecuencias:** funciona con todos los formatos probados y un uso de CPU bajo.

## ADR-14 · Trickplay junto a los medios

- **Contexto:** las miniaturas de la línea de tiempo ocupaban 11 GB en la configuración de Jellyfin, en el NVMe.
- **Decisión:** guardarlas junto a cada vídeo, en el pool de HDD.
- **Consecuencias:** NVMe más ligero y snapshots/réplicas de la configuración más pequeños. Jellyfin necesita permiso de escritura en `Media`.

## ADR-15 · Música gestionada desde el PC

- **Contexto:** la música se descarga y organiza en el PC.
- **Decisión:** invertir el flujo: el PC envía y el NAS solo recibe.
- **Consecuencias:** una única fuente de verdad. Los cambios hechos en el NAS no bajan al PC y quedan como cambios locales.

---

## Descartado

| Opción | Motivo |
|---|---|
| Copia fuera de casa | No hay más discos por ahora; es el principal riesgo pendiente (ver [Roadmap](../ROADMAP.md)) |
| `Files/Backups` como dataset propio | Sin copia fuera de casa aporta poco: la retención larga ya la da el versionado del PC |
| SAI | Pospuesto por coste |
| MemTest86 | Riesgo de fallo de RAM asumido |
| Correo para la salida de los cron | Cubierto por los avisos por Telegram de cada script |
