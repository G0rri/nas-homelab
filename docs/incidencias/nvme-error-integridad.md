# Error de integridad histórico en el NVMe

**Fecha:** 21/09/2026 · **Área:** almacenamiento · **Estado:** sin impacto, vigilado

## Síntomas

Al preparar `smart-check.sh`, el NVMe del pool `SSD_M2` mostraba un error acumulado: `Media and Data Integrity Errors: 1`.

## Investigación

Como `SSD_M2` es un disco único sin redundancia, había que confirmar que no hubiera datos afectados:

```bash
sudo zpool status -v SSD_M2       # CKSUM 0 · "No known data errors" · último scrub con 0 B reparados
sudo smartctl -l error /dev/nvme0n1   # "No Errors Logged"
```

## Causa

Error antiguo del propio disco, sin efecto en los datos: ZFS no ha detectado ninguna corrupción en los checksums ni en los scrubs.

## Solución

El script guarda el valor actual como referencia (`NVME_ERRORES_REF=1`) y **solo avisa si el contador sube**.

## Lecciones aprendidas

- En ZFS, los checksums y los scrubs son la prueba definitiva de si los datos están bien, más allá de lo que diga S.M.A.R.T.
- Alertar sobre **cambios respecto a una referencia**, y no sobre valores absolutos, evita la fatiga de alertas sin perder la vigilancia.
