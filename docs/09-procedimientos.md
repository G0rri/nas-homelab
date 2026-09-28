# 9. Procedimientos

Runbooks para tareas poco frecuentes, en las que es fácil olvidar algún paso.

## Actualizar TrueNAS

1. Actualizar TrueNAS.
2. Exportar un nuevo bundle de configuración **con la semilla de cifrado**, cifrarlo con 7-Zip y dejarlo en `Files/Backups`.
3. Conservar solo los tres últimos *boot environments*.

Los scripts no se pierden en la actualización porque viven en un dataset y no en `/root`.

## Actualizar la BIOS

1. Descargar la versión desde la página de soporte de Gigabyte para la placa y copiarla a un pendrive FAT32.
2. Conectar el monitor a la **Arc A380** (el Ryzen no tiene gráfica integrada).
3. Flashear con Q-Flash. Si aparece el aviso del fTPM, aceptar (TrueNAS no lo usa).
4. Revisar los ajustes: **XMP se restablece** tras el flasheo. Comprobar también CSM, Above 4G / ReBAR, AC BACK y RAIDXpert2 (ver [Hardware](01-hardware.md#bios)).
5. Verificar desde la shell el ReBAR, la velocidad de la RAM y el arranque UEFI.

## Renovar el certificado HTTPS

1. Firmar un certificado nuevo con la CA propia en el PC (OpenSSL), con la IP del NAS en el SAN.
2. Importarlo en TrueNAS.
3. Reasignarlo en la interfaz web de TrueNAS (*Sistema › General › GUI*) y en cada app con HTTPS (*Apps › Editar › Certificado*).
4. Si el navegador sigue mostrando el aviso, reiniciarlo.

Hay que hacerlo también si cambia la IP del NAS.

## Restaurar datos de una app

- **Error reciente (menos de una semana):** volver a un snapshot local de `Apps_data/<app>`.
- **Fallo del NVMe:** los datasets replicados son de solo lectura, así que se copian los datos necesarios desde `HDD_RAID5/Replicas/<app>/` a su ubicación en `Apps_data`, con la app detenida.
- **Immich:** hacen falta las dos partes: los originales (`data/upload`, también en el PC) y el volcado más reciente de la base de datos (`Backups/Immich`).

## Liberar espacio en SSD_M2

```bash
sudo zfs list -o space -r SSD_M2   # ¿cuánto retienen los snapshots? (columna USEDSNAP)
sudo docker system df              # ¿cuánto ocupan las imágenes sin uso?
sudo docker image prune -a         # borrar las imágenes sin uso
```

Tras borrar o mover muchos archivos, el espacio no se libera hasta que caducan los snapshots (1 semana).

## Comprobaciones periódicas

- [ ] Llega el resumen S.M.A.R.T. 🟢 cada miércoles.
- [ ] Llega el resumen 🧹 de `docker-prune.sh` cada día 15.
- [ ] La replicación diaria termina en *SUCCESS*.
- [ ] Hay volcados recientes en `Backups/Immich`.
- [ ] Copia manual de Jellyfin tras cambios de configuración.
- [ ] Exportación cifrada de Vaultwarden cada pocos meses.
- [ ] Scrub manual del `boot-pool` de vez en cuando.
- [ ] Ocupación de `HDD_RAID5` por debajo del 80 %.
