# Tirones con AV1 en una tablet Android

**Área:** reproducción · **Estado:** resuelto

## Síntomas

Una película 4K en AV1 se reproducía a tirones en una tablet Android con Snapdragon 870.

## Investigación

- No era un fallo de transcodificación: **el servidor no estaba transcodificando**, sino haciendo reproducción directa.
- El Snapdragon 870 **no tiene decodificador AV1 por hardware**.
- Aun así, la app de Jellyfin anunciaba soporte de AV1 gracias al decodificador por software de ExoPlayer, así que el servidor le enviaba el archivo original.

## Causa

La tablet decodificaba un AV1 4K por CPU, y su procesador no daba abasto.

## Solución

Bajar manualmente la calidad a 2K en el cliente, lo que obliga al servidor a transcodificar con la Arc A380.

Alternativas documentadas por si hace falta una solución permanente:

- Limitar la tasa de bits de red interna del usuario de Jellyfin (~20-25 Mbps) para forzar siempre la transcodificación.
- Crear un usuario de Jellyfin solo para la tablet, con ese límite.

## Lecciones aprendidas

- La reproducción directa no siempre es la mejor opción: depende de que el cliente pueda decodificar el formato **por hardware**.
- Lo que un cliente anuncia que soporta no equivale a que lo reproduzca bien.
