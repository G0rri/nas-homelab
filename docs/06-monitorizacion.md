# 6. Monitorización y alertas

## Canal de alertas: Telegram

- TrueNAS solo ofrece correo o Telegram (no admite ntfy). Uso un **bot de Telegram** configurado como servicio de alertas con nivel *Warning*.
- La salida de los *cron jobs* de TrueNAS **no** llega por ese canal: se envía por correo, que no está configurado. Por eso mis scripts avisan directamente con `telegram.sh`.
- **Resúmenes de "todo bien":** algunos scripts envían un resumen aunque no haya problemas (el de S.M.A.R.T. cada miércoles, el de limpieza de Docker cada mes). **Si un resumen no llega, algo está roto**: el script, el cron o Telegram. Así el silencio nunca se confunde con normalidad.

## S.M.A.R.T.

TrueNAS 25.10 eliminó el servicio `smartd` y la sección de tests S.M.A.R.T., así que los tests y la revisión se hacen con tareas cron propias que llaman a `smartctl`:

| Tarea | Programación | Discos |
|---|---|---|
| Test corto | Miércoles, 03:00 | 3 HDD + NVMe |
| Test largo | Día 1 de cada mes, 02:00 | 3 HDD |
| Revisión (`smart-check.sh`) | Diaria, 03:30 | Todos |

### Qué revisa `smart-check.sh`

| Disco | Comprobaciones | Avisa si… |
|---|---|---|
| HDD | Salud general; atributos 5, 197, 198 y 199; resultado y antigüedad del último autotest; temperatura | Algún atributo ≠ 0 · autotest fallido o de hace más de ~8 días · > 50 °C |
| NVMe | Salud, *Critical Warning*, errores de integridad, reserva, desgaste y temperatura | Errores por encima del valor de referencia · desgaste > 80 % · > 65 °C |
| SSD de arranque | Solo contadores (5, 160, 196, 199 y 161) | Algún contador ≠ 0 · reserva (161) por debajo de 132 |
| Todos | Número de discos detectados | Falta alguno de los 5 |

- Identifica los discos por modelo y tipo, no por `sdX`.
- Solo escribe si hay problemas, salvo el resumen 🟢 de los miércoles.
- Comprobar la antigüedad del último autotest sirve también para detectar que el cron de los tests ha dejado de funcionar.

### Estado de referencia (septiembre de 2026)

| Disco | Salud | Temperatura | Otros |
|---|---|---|---|
| 3 × HDD | PASSED | 34-37 °C | 0 sectores reasignados, pendientes o incorregibles · ~13.450 h encendidos |
| NVMe | PASSED | 56 °C | Desgaste 4 % |
| SSD de arranque | PASSED | 48 °C | Contadores a 0 · reserva 132 |

### Excepciones documentadas

- **SSD de arranque excluido de los tests programados:** su firmware genera un registro de autotests mal formado que provoca alertas falsas en TrueNAS. Se vigila solo por contadores. → [Incidencia](incidencias/ssd-arranque-falso-positivo-smart.md)
- **Un error de integridad histórico en el NVMe:** sin impacto en los datos; el script solo avisa si el contador aumenta. → [Incidencia](incidencias/nvme-error-integridad.md)
