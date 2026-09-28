# Falso positivo S.M.A.R.T. en el SSD de arranque

**Fecha:** 21/09/2026 · **Área:** monitorización · **Estado:** resuelto

## Síntomas

Llegó por Telegram una alerta de TrueNAS indicando que el SSD de arranque (Patriot Burst Elite 120 GB) había fallado un autotest S.M.A.R.T. La alerta desapareció sola en el siguiente sondeo.

## Investigación

- `smartctl -H`: salud general **PASSED**.
- Estado de ejecución del autotest: `0` (terminado sin error).
- `smartctl -l selftest`: *"log structure revision number 0"* (la especificación exige 1) y *"No self-tests have been logged"*.
- `smartctl` no tiene este modelo en su base de datos, por lo que muchos atributos aparecen como `Unknown_Attribute`.

## Causa

El firmware del disco no implementa bien el registro de autotests. Acepta el test y lo termina sin error, pero TrueNAS lee ese registro mal formado y genera una alerta falsa.

## Solución

- El disco se **excluye de los tests programados**.
- `smart-check.sh` lo vigila **solo por contadores**, con valores de referencia documentados.

### Valores de referencia

Los atributos desconocidos siguen el esquema habitual de los controladores Phison (interpretación no confirmada por el fabricante):

| Atributo | Significado | Valor de referencia | Aviso |
|---|---|---|---|
| 5 | Sectores reasignados | 0 | Si sube |
| 160 | Sectores incorregibles | 0 | Si sube |
| 161 | Bloques de reserva disponibles | 132 | Si baja |
| 163 | Bloques defectuosos de fábrica | 37 | Fijo |
| 167 | Media de ciclos de borrado | 111 | Mejor indicador de desgaste |
| 196 | Eventos de reasignación | 0 | Si sube |
| 199 | Errores CRC de la interfaz | 0 | Si sube (revisar primero el cable SATA) |
| 9 | Horas encendido | 7.293 | — |

```bash
sudo smartctl -A /dev/sdX   # tabla de atributos completa
```

> `smartctl -a | head -40` corta la salida antes de la tabla de atributos: mejor usar `-A`.

## Lecciones aprendidas

- Una alerta que desaparece sola merece investigación, pero no todas las alertas indican un fallo real.
- Cuando un disco no reporta bien sus propios tests, hay que vigilarlo por los contadores que sí son fiables.
- Guardar valores de referencia permite distinguir un disco viejo de un disco que se está degradando.
