# Serpent

[🇺🇸 English](README.md) · [🇨🇳 简体中文](README.zh-Hans.md) · [🇹🇼 繁體中文](README.zh-Hant.md) · [🇯🇵 日本語](README.ja.md) · [🇰🇷 한국어](README.ko.md) · [🇫🇷 Français](README.fr.md) · [🇩🇪 Deutsch](README.de.md) · [🇪🇸 Español](README.es.md)

Un juego Snake nativo y minimalista para Mac con Apple Silicon, creado con SwiftUI, AppKit y AVFoundation. Sin dependencias de terceros en tiempo de ejecución ni solicitudes de red.

## Controles

| Acción | Control |
| --- | --- |
| Mover | Teclas de flecha, WASD o arrastrar/deslizar sobre el tablero |
| Empezar, pausar o continuar | Espacio |
| Nueva partida | R o ⌘N |
| Pausar o cerrar los ajustes/la ayuda | Esc |
| Ajustes | ⌘, |

Recoge comida para que tu serpiente crezca. Chocar contra una pared termina la partida, salvo si Atravesar bordes está activado. Chocar contra tu propio cuerpo siempre termina la partida. Los giros directos de 180° se ignoran, y los giros válidos realizados rápidamente se ponen en cola y se aplican en pasos de movimiento sucesivos.

La partida se pausa automáticamente al cambiar a otra app, minimizar la ventana o poner el Mac en reposo. Pulsa Espacio para continuar cuando vuelvas.

## Características

- Ventana de escritorio nativa con tamaño ajustable, compatibilidad con pantalla completa y renderizado Retina/de alta densidad de píxeles.
- Opciones de apariencia clara, oscura y del sistema. De forma predeterminada, sigue la apariencia de tu Mac.
- Renderizado fluido a 60 Hz, comida que pulsa suavemente y actualizaciones animadas de la puntuación.
- Tres niveles de dificultad, cada uno con su propio récord:

  | Dificultad | Tiempo por movimiento | Puntos por comida |
  | --- | --- | --- |
  | Fácil | 160 ms | 10 |
  | Normal | 105 ms | 20 |
  | Difícil | 70 ms | 30 |

  Los cambios de dificultad se aplican en la siguiente partida.

- El interruptor independiente **Atravesar bordes** está en **Ajustes → Juego** y está desactivado de forma predeterminada. Al activarlo, la serpiente que cruza un borde aparece por el opuesto. Los cambios se aplican a la siguiente partida; chocar contra tu propio cuerpo sigue terminando la partida. Los récords se guardan por separado para cada dificultad y modo, conservando los récords anteriores del modo clásico.

- Sonidos suaves sintetizados, opcionales, al empezar, recoger comida, pausar, terminar una partida y establecer un nuevo récord.
- Los récords, las preferencias y la selección de idioma se guardan localmente.
- Ocho idiomas completamente traducidos, seleccionables mediante banderas en Ajustes:

  | Idioma | Región |
  | --- | --- |
  | 🇺🇸 Inglés | Estados Unidos |
  | 🇨🇳 Chino simplificado | China |
  | 🇹🇼 Chino tradicional | Taiwán |
  | 🇯🇵 Japonés | Japón |
  | 🇰🇷 Coreano | Corea del Sur |
  | 🇫🇷 Francés | Francia |
  | 🇩🇪 Alemán | Alemania |
  | 🇪🇸 Español | España |

  El idioma predeterminado sigue los idiomas preferidos de tu Mac. Puedes cambiarlo en cualquier momento en Ajustes.

## Desarrollo y empaquetado

Requiere Xcode Command Line Tools y Swift 5.9 o posterior.

```sh
swift test
swift run Serpent
./Scripts/build-app.sh
```

El script de empaquetado crea una app arm64 y un archivo ZIP, y después verifica la firma de la app. Ejecuta `BUILD_DMG=1 ./Scripts/build-app.sh` para generar también una imagen de disco.

La compilación local tiene una firma ad hoc y no está notarizada con un Apple Developer ID. Si macOS bloquea la app después de descargarla en otro Mac, sigue las indicaciones del sistema para permitir que se abra.

Las pruebas automatizadas cubren las reglas del juego, la cola de giros, los casos límite, la pausa automática, la correspondencia con los idiomas del sistema y la integridad de las traducciones en los ocho idiomas.

Los archivos de código fuente están en `Sources/Serpent`, las traducciones en `Sources/Serpent/Resources` y el icono y los metadatos de la app en `Support`.
