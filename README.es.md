# EPS Finder

[Türkçe](README.md) · [English](README.en.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md)

Miniaturas EPS y previsualizaciones de Vista rápida con la barra espaciadora en el Finder de macOS.

**Universal 2:** Intel (`x86_64`) y Apple Silicon (`arm64`). **macOS 13 o posterior.** Ghostscript está incluido. Para usar la aplicación no se necesita Homebrew, Python, Illustrator ni Rosetta.

## Instalación

1. Descarga `EPS-Finder-1.1.0-universal-unsigned.pkg` desde [Releases](https://github.com/enesdigital/eps-finder/releases/latest). El mismo paquete sirve para Intel y Apple Silicon.
2. Abre el archivo `.pkg` y sigue los pasos del instalador. La aplicación se instala en `/Applications/EPS Finder.app` y requiere autorización de administrador.
3. Abre EPS Finder una vez. Pulsa **Örnek dosyayı göster** («Mostrar archivo de ejemplo») para seleccionar el EPS de ejemplo incluido en el Finder. El cuadro de diálogo de la aplicación está actualmente en turco.

El instalador registra las extensiones de Vista rápida para el usuario que tiene la sesión iniciada. Es posible que los demás usuarios también deban abrir la aplicación una primera vez.

Esta versión **no tiene firma Developer ID ni está notarizada por Apple**. macOS puede pedir autorización antes de abrir el paquete. La firma y la notarización son un paso de distribución independiente.

## Uso

Selecciona un archivo `.eps` en el Finder y pulsa la **barra espaciadora** para previsualizarlo. El Finder también genera miniaturas en la vista de iconos. Activa la previsualización de iconos en las opciones de visualización del Finder para mostrarlas.

## Si no aparecen las previsualizaciones

1. Comprueba que el archivo esté descargado en el Mac y que no sea únicamente un marcador de un archivo en la nube.
2. Abre EPS Finder una vez. Busca **Extensiones / Vista rápida (Quick Look)** en Ajustes del Sistema y activa **EPS Finder — Preview** y **EPS Finder — Thumbnail**. La ubicación exacta cambia según la versión de macOS.
3. Revisa la opción de previsualización de iconos del Finder. Los EPS dañados o que requieren recursos externos pueden no mostrarse.

## Procesamiento y límites

La extensión de Vista rápida convierte el EPS en un PDF temporal dentro de su entorno aislado mediante el modo `SAFER` de Ghostscript. El procesamiento es local. El EPS original no se modifica y los archivos temporales se eliminan. La aplicación no solicita acceso a la red ni permisos amplios de acceso a archivos.

- Entrada máxima: 256 MB. PDF generado máximo: 64 MB.
- Tiempo máximo: 8 segundos para miniaturas y 15 segundos para previsualizaciones.
- Las fuentes no incrustadas pueden cambiar el aspecto; los recursos externos pueden impedir que se genere la imagen.
- La previsualización no sustituye la aprobación de impresión ni una prueba de color.

Para desinstalar, mueve `/Applications/EPS Finder.app` a la Papelera. Elimina también cualquier copia antigua de la carpeta Aplicaciones de tu cuenta.

## Compilación y pruebas

La compilación de la versión Universal requiere un **Mac Apple Silicon, Rosetta 2, Apple Command Line Tools y Python 3.9+**. Estos requisitos son solo para el desarrollo.

```sh
python3 build-engine.py
python3 build.py
python3 package.py
```

Los scripts verifican el SHA-256 del archivo oficial de Ghostscript, compilan ambas arquitecturas, ejecutan las pruebas del motor y generan el instalador, el archivo completo de fuentes y las sumas de comprobación en `dist/`. La [guía en inglés](README.en.md#build) incluye más detalles.

Las pruebas arm64 y x86_64 se completaron correctamente; el código Intel se ejecutó con Rosetta en Apple Silicon. Quedan pendientes las pruebas en un Mac Intel físico, en la versión más antigua de macOS compatible y la instalación completa con autorización de administrador.

## Licencia y descargas

AGPL-3.0-or-later; consulta [LICENSE](LICENSE) y [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Comparte el archivo de fuentes generado junto con el paquete binario.

En [Releases](https://github.com/enesdigital/eps-finder/releases/latest) están el instalador, `EPS-Finder-1.1.0-source.zip` y un archivo `SHA256SUMS`. El archivo de fuentes con este nombre también incluye las fuentes completas de Ghostscript. Los archivos «Source code» que GitHub genera automáticamente no contienen ese archivo adicional.
