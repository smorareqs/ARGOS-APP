# ARGOS · Design System

Sistema de diseño **atómico** compartido por la app móvil del personal y la web
administradora de ARGOS. Teal profundo como base, dorado como acento de acción.

> Fuente de verdad visual: `ARGOS Design System.dc.html` (proyecto Claude Design).

## Principio: reutiliza siempre la capa inferior

```
tokens → atoms → molecules → organisms → templates → screens (en la app)
```

Cada capa se construye **solo** con piezas de las capas inferiores. Nunca
hardcodees un color, tamaño o estilo: usa siempre un token.

## Capas

### `tokens/` — decisiones de diseño crudas
| Token | Contenido |
|-------|-----------|
| `CustomColors` | Teal `#003841`, Dorado `#C5873C`, apoyos, neutros arena, texto, bordes |
| `CustomTypography` | EB Garamond (display/títulos) + Verdana (cuerpo/UI) y la escala |
| `CustomDimensions` | Espaciado, radios (campo 12 · tarjeta 18 · píldora 9999), alturas |
| `CustomShadows` | Elevación de tarjeta y glow del CTA |
| `CustomIcons` | Catálogo de iconos Material rounded |

### `atoms/` — el elemento más pequeño reutilizable
`PrimaryButton` (CTA dorado), `SecondaryButton` (teal), `TertiaryButton`
(blanco), `AppChip`, `StatusBadge`, `AppTextField`, `ArgosLogo`.

### `molecules/` — combinan átomos + tokens
`LabeledField` (etiqueta + campo), `SectionHeader`, `AppCard`.

### `organisms/` — secciones funcionales completas
`LoginForm`.

### `templates/` — el esqueleto de una pantalla
`ArgosScaffold` (fondo arena + padding estándar).

### `screens/`
Viven en la app (`lib/features/**/presentation/pages`). Componen organisms y
templates; no contienen estilos propios.

## Uso

```dart
import 'package:design_system/design_system.dart';

ArgosScaffold(
  body: Column(
    children: [
      const ArgosLogo(),
      AppCard(
        elevated: true,
        child: PrimaryButton(
          label: 'Iniciar sesión',
          trailingIcon: CustomIcons.arrowForward,
          onPressed: () {},
        ),
      ),
    ],
  ),
);
```

## Cómo añadir un componente

1. ¿Necesitas un valor nuevo (color, tamaño)? → primero un **token**.
2. Elige la capa correcta según con qué se compone.
3. Construye **solo** con la capa inferior.
4. Expórtalo en `lib/design_system.dart`.
