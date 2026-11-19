# EPS Finder

[English](README.md) · [Türkçe](README.tr.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Español](README.es.md)

Miniaturas EPS y previsualizaciones de Vista rápida con la barra espaciadora en el Finder de macOS.

**Universal 2:** Intel (`x86_64`) y Apple Silicon (`arm64`). **macOS 13 o posterior.** Ghostscript está incluido. Para usar la aplicación no se necesita Homebrew, Python, Illustrator ni Rosetta.

La interfaz, los mensajes de error y las páginas de instalación están disponibles en turco, inglés, alemán, francés y español. macOS selecciona automáticamente el idioma que mejor coincide con tus preferencias; si no hay ninguno compatible, se utiliza el inglés.

La versión 1.4.0 añade actualizaciones verificadas dentro de la aplicación con Sparkle. [EPS icon](assets/ICON.md).

## Instalación

1. Descarga `EPS-Finder-1.4.1-universal-unsigned.pkg` desde [Releases](https://github.com/enesdigital/eps-finder/releases/latest). El mismo paquete sirve para Intel y Apple Silicon.
2. Abre el archivo `.pkg` y sigue los pasos del instalador. La aplicación se instala en `/Applications/EPS Finder.app` y requiere autorización de administrador.
3. Abre EPS Finder una vez. Pulsa **Mostrar archivo de ejemplo** para seleccionar el EPS de ejemplo incluido en el Finder.

El instalador registra las extensiones de Vista rápida para el usuario que tiene la sesión iniciada. Es posible que los demás usuarios también deban abrir la aplicación una primera vez.

Esta versión **no tiene firma Developer ID ni está notarizada por Apple**. macOS puede pedir autorización antes de abrir el paquete. La firma y la notarización son un paso de distribución independiente.

## Uso

Selecciona un archivo `.eps` en el Finder y pulsa la **barra espaciadora** para previsualizarlo. El Finder también genera miniaturas en la vista de iconos. Activa la previsualización de iconos en las opciones de visualización del Finder para mostrarlas.

## Actualizaciones

EPS Finder usa Sparkle 2.10.1 para descargar, verificar e instalar actualizaciones dentro de la aplicación. Elige **Buscar actualizaciones**, **Instalar actualización** y después **Instalar y reiniciar**. macOS puede solicitar autorización de administrador; EPS Finder se reinicia automáticamente al terminar. Ya no es necesario abrir el paquete descargado. **Notas de la versión** abre GitHub para descargas manuales.

La lista de actualizaciones y el paquete deben tener firmas Ed25519 válidas que coincidan con la clave pública integrada. Se rechazan actualizaciones modificadas o con firmas inválidas. La clave privada de publicación permanece en el Llavero de macOS. Estas firmas son distintas de Apple Developer ID: el paquete de primera instalación sigue sin firma ni notarización de Apple.

**Desde la versión 1.3.1 o anterior:** instala una vez 1.4.0 desde Releases. El actualizador anterior no puede repararse de forma remota. Las actualizaciones siguientes usan el nuevo instalador integrado.

La comprobación automática se ejecuta al abrir la aplicación y periódicamente mientras está abierta. Desactiva **Buscar actualizaciones automáticamente** para detenerla; sigue disponible la búsqueda manual. Tras instalar, la aplicación se registra para abrirse al iniciar sesión. Puedes cambiarlo en EPS Finder o Ajustes del Sistema → General → Ítems de inicio. Se conservan las preferencias existentes.

Solo la aplicación contacta con GitHub y sus servidores de descarga. Los archivos EPS nunca se suben; las extensiones de Vista rápida no tienen permiso de red. No se instala un asistente privilegiado permanente. Sparkle solicita autorización de administrador al instalar.

El instalador sustituye `/Applications/EPS Finder.app`. Las copias antiguas con el mismo identificador en `/Applications` y `~/Applications` del usuario conectado se envían a la Papelera. Se conservan versiones iguales o posteriores, otras aplicaciones, enlaces simbólicos y archivos EPS. No se revisan otras ubicaciones. Si falla la limpieza, la aplicación pide eliminar la copia antigua manualmente.

## Si no aparecen las previsualizaciones

1. Comprueba que el archivo esté descargado en el Mac y que no sea únicamente un marcador de un archivo en la nube.
2. Abre EPS Finder una vez. Busca **Extensiones / Vista rápida (Quick Look)** en Ajustes del Sistema y activa **EPS Finder — Vista previa** y **EPS Finder — Miniaturas**. La ubicación exacta cambia según la versión de macOS.
3. Revisa la opción de previsualización de iconos del Finder. Los EPS dañados o que requieren recursos externos pueden no mostrarse.

## Procesamiento y límites

La extensión de Vista rápida convierte el EPS en un PDF temporal dentro de su entorno aislado mediante el modo `SAFER` de Ghostscript. El procesamiento es local. El EPS original no se modifica y los archivos temporales se eliminan. Las extensiones de Vista rápida no tienen permiso de red ni acceso amplio a archivos. La aplicación principal solo usa la red para buscar y descargar actualizaciones.

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

Los scripts verifican el SHA-256 del archivo oficial de Ghostscript, compilan ambas arquitecturas, ejecutan las pruebas del motor y generan el instalador, el archivo completo de fuentes y las sumas de comprobación en `dist/`. La [guía en inglés](README.md#build) incluye más detalles.

Las pruebas arm64 y x86_64 se completaron correctamente; el código Intel se ejecutó con Rosetta en Apple Silicon. Quedan pendientes las pruebas en un Mac Intel físico, en la versión más antigua de macOS compatible y la instalación completa con autorización de administrador.

## Licencia y descargas

AGPL-3.0-or-later; consulta [LICENSE](LICENSE) y [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Comparte el archivo de fuentes generado junto con el paquete binario.

En [Releases](https://github.com/enesdigital/eps-finder/releases/latest) están el instalador, `EPS-Finder-1.4.1-source.zip` y un archivo `SHA256SUMS`. El archivo de fuentes con este nombre también incluye las fuentes completas de Ghostscript y Sparkle. Los archivos «Source code» que GitHub genera automáticamente no contienen ese archivo adicional.

[Sparkle 2.10.1 · MIT · Ed25519 · appcast.xml](README.md#updates)
