# Scripts

Scripts en Bash que automatizan la monitorización y las copias del NAS. Se ejecutan como `root` desde las tareas cron de TrueNAS (*Sistema › Advanced Settings › Cron Jobs*).

| Script | Función | Cron |
|---|---|---|
| [`telegram.sh`](telegram.sh) | Envía un mensaje al bot de alertas. Lo usan todos los demás | — |
| [`smart-check.sh`](smart-check.sh) | Revisa el estado S.M.A.R.T. de todos los discos y avisa si algo va mal. Los miércoles manda un resumen aunque todo esté bien | `30 3 * * *` |
| [`backups-semanales.sh`](backups-semanales.sh) | Copia la última copia de Jellyfin y el último volcado de Immich a la carpeta de copias, verificando que no estén dañados | `0 5 * * 0` |
| [`docker-prune.sh`](docker-prune.sh) | Borra las imágenes de Docker sin uso y manda un resumen con el espacio liberado | `0 6 15 * *` |

La documentación de lo que hace cada uno y por qué está en [Monitorización](../docs/06-monitorizacion.md), [Copias de seguridad](../docs/05-copias-de-seguridad.md) y [Automatización](../docs/07-automatizacion.md).

## Principios de diseño

- **Nunca fallar en silencio.** La salida del cron de TrueNAS se envía por correo, que no está configurado, así que cada script avisa por Telegram de sus propios errores. Los que se ejecutan con poca frecuencia envían además un resumen aunque todo vaya bien: si no llega, algo está roto.
- **Secretos fuera del código.** El token y el chat ID viven en `.telegram.env` (`root:root`, permisos `600`), que no se sincroniza ni se sube al repositorio. Ver [`.telegram.env.example`](.telegram.env.example).
- **Sin depender de nombres que cambian.** `smart-check.sh` identifica los discos por tipo y modelo (`lsblk`), no por `sdX`.
- **Verificar antes de dar algo por copiado.** `backups-semanales.sh` comprueba la integridad del archivo (gzip/zip) en el origen y otra vez en el destino.
- **Umbrales con referencia.** Los valores conocidos de cada disco (un error antiguo del NVMe, la reserva del SSD de arranque) se guardan como referencia y solo se avisa si empeoran.
- **Rutas absolutas** a los binarios y a los datasets, porque el entorno del cron es mínimo.

## Instalación

Probado en TrueNAS Scale 25.10. Requiere `bash`, `curl`, `smartctl`, `python3` y `numfmt`, que ya vienen en el sistema.

1. Copiar los scripts a un dataset, **no a `/root`**: al actualizar TrueNAS cambia el *boot environment* y se perderían. Aquí se usa `/mnt/SSD_M2/Files/Scripts/`.
2. Darles permiso de ejecución: `sudo chmod +x /mnt/SSD_M2/Files/Scripts/*.sh`.
3. Crear `.telegram.env` a partir de la plantilla.
4. Ajustar las rutas y la configuración al principio de cada script (por ejemplo, `PROPIETARIO` en `backups-semanales.sh`).
5. Probarlos a mano con `sudo` antes de programarlos:

   ```bash
   sudo /mnt/SSD_M2/Files/Scripts/telegram.sh "Prueba"
   sudo /mnt/SSD_M2/Files/Scripts/smart-check.sh --resumen
   ```

6. Crear las tareas cron como `root`, con *Hide Standard Output* y *Hide Standard Error* marcados.
