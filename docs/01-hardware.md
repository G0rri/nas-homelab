# 1. Hardware

## Componentes

| Componente | Modelo | Notas |
|---|---|---|
| Caja | Nox Tempest Umbra (ATX) | |
| Placa base | Gigabyte A520M S2H (rev 1.x) | BIOS F21d |
| CPU | AMD Ryzen 5 3600 | 6 núcleos / 12 hilos, **sin gráfica integrada** |
| Disipador | Nox Hummer H-212 | |
| RAM | Corsair Vengeance 2 × 8 GB DDR4-3200 CL16 (CMK16GX4M2E3200C16) | Perfil XMP activado |
| GPU | Intel Arc A380 | Transcodificación por hardware (AV1, HEVC, H.264) |
| Fuente | be quiet! System Power 10 450 W | |
| Disco de arranque | Patriot Burst Elite 120 GB (SATA) | Pool `boot-pool` |
| Disco de apps | Patriot P300 512 GB (NVMe M.2) | Pool `SSD_M2` |
| Discos de datos | 3 × Seagate ST4000VN006 4 TB | Pool `HDD_RAID5` (RAIDZ1) |

## Discos en el sistema

| Dispositivo | Modelo | Pool |
|---|---|---|
| `sda`, `sdb`, `sdd` | Seagate ST4000VN006 (3,64 TiB c/u) | `HDD_RAID5` |
| `sdc` | Patriot Burst Elite 120 GB | `boot-pool` |
| `nvme0n1` | Patriot P300 512 GB | `SSD_M2` |

> ⚠️ Los nombres `sdX` pueden cambiar entre arranques. Por eso los scripts de monitorización identifican los discos por **modelo y tipo**, nunca por nombre de dispositivo.

## BIOS

Versión **F21d** (AGESA ComboV2 1.2.0.12), actualizada desde la F16 mediante Q-Flash con un pendrive FAT32.

| Ajuste | Valor | Motivo |
|---|---|---|
| CSM Support | Disabled | Necesario para Resizable BAR; además la Arc A380 no tiene VBIOS legacy |
| Above 4G Decoding | Enabled | Requisito de Resizable BAR |
| Re-Size BAR Support | Enabled | El BAR prefetchable de la Arc pasa de 256 MB a 8 GB |
| XMP | Profile1 | DDR4-3200 16-20-20-38 a 1,35 V |
| AC BACK / ErP | Always On / Disabled | El NAS arranca solo tras un corte de luz |
| AMD RAIDXpert2 | Off | ZFS necesita acceso directo a los discos, sin RAID por firmware |

Notas:

- En esta placa, *Above 4G Decoding* y *Re-Size BAR* están en **Settings › IO Ports**, no en *Miscellaneous*.
- Tras flashear la BIOS el perfil XMP se restablece y hay que volver a activarlo.
- El Ryzen 5 3600 no tiene gráfica integrada: para entrar en la BIOS hay que conectar el monitor a la Arc A380.
- Al actualizar apareció el aviso *"New CPU installed, fTPM/PSP NV corrupted"*. Se aceptó reiniciar el fTPM, porque TrueNAS no lo utiliza.

### Verificación desde la shell

```bash
# Resizable BAR: el BAR prefetchable de la GPU debe mostrar 8G
sudo lspci -v -s 07:00.0 | grep -i "memory at"

# RAM funcionando a 3200 MT/s
sudo dmidecode -t memory | grep -i "configured memory speed"

# Arranque en modo UEFI: el directorio debe existir y tener contenido
ls /sys/firmware/efi
```
