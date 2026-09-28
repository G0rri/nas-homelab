# Roadmap

## Próximos pasos

- [ ] **Copia fuera de casa.** Es el principal riesgo sin cubrir (ver [matriz de riesgos](docs/05-copias-de-seguridad.md#matriz-de-riesgos)); ahora mismo no hay discos para ello.
- [ ] **SAI**, pospuesto por coste.
- [ ] Montar `HDD_RAID5/Replicas` en Filebrowser Quantum como almacenamiento de solo lectura, para restaurar archivos desde el navegador.
- [ ] Automatizar la copia de Jellyfin si la app permite programarla (ahora es manual).
- [ ] Convertir `Files/Backups` en un dataset propio (opcional).
- [ ] Renovar el certificado HTTPS del NAS antes de agosto de 2029.

## Tareas recurrentes

- Bundle de configuración de TrueNAS cifrado tras cada actualización.
- Exportación cifrada de Vaultwarden cada pocos meses.
- Vigilar que `HDD_RAID5` se mantenga por debajo del 80 % de ocupación.

Las opciones descartadas y sus motivos están en [Decisiones técnicas](docs/decisiones.md#descartado).
