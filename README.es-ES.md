

# luajit-cmake

Un generador de cmake flexible para LuaJIT.

## Dependencias externas

Este proyecto requiere varias herramientas externas para la compilación y la compilación cruzada:

### Zig

- **Propósito**: Se utiliza como cadena de herramientas para la compilación cruzada con el fin de compilar LuaJIT para varias plataformas.
- **Versión**: 0.16.0
- **Archivo de cadena de herramientas**: `Utils/zig.toolchain.cmake`
- **Instalación**: Instale Zig desde [ziglang.org](https://ziglang.org/)

### Git

- **Propósito**: Se requiere para clonar el repositorio y gestionar el código fuente.
- **Instalación**: Por lo general, viene preinstalado en macOS. Para otros sistemas, instálelo desde [git-scm.com](https://git-scm.com/)

### Wine

- **Propósito**: Se utiliza para ejecutar archivos ejecutables de Windows de 32 bits en sistemas que no sean Windows durante el proceso de compilación.
- **Uso**: Se hace referencia en `Utils/Darwin.wine.cmake` para las compilaciones en macOS.
- **Instalación**: Instale Wine desde [winehq.org](https://www.winehq.org/)

## Compilación

### make

Utilice un `make` compatible con GNU.

`make -DLUAJIT_DIR=...` o `mingw32-make -DLUAJIT_DIR=...` o
`gnumake -DLUAJIT_DIR=...`.

_Nota_: Al utilizar `mingw32-make`, cambie `\\` por `/` en la ruta de archivos en Windows.

### cmake

Utilice cmake para compilar.

```bash
cmake -H. -Bbuild -DLUAJIT_DIR=...
make --build build --config Release
```

### Incrustación

```cmake
add_subdirectory(luajit-cmake)
target_link_libraries(yourTarget PRIVATE luajit::lib luajit::header)
```

Consulte los ejemplos en [lua-forge](https://github.com/zhaozg/lua-forge/blob/master/CMakeLists.txt)

### Compilación cruzada

#### iOS

```bash
make iOS
```

#### Android

```bash
make Android
```

#### Windows

```bash
make Windows
```

#### HarmonyOS

La biblioteca también admite la compilación cruzada para HarmonyOS. Consulte los archivos de cadena de herramientas en el directorio `Utils/` para las configuraciones específicas de HarmonyOS.

```bash
make OHOS
```

#### Nota

_Nota_: La arquitectura i386 está obsoleta para macOS (elimínela de la configuración de compilación de Xcode: ARCHS). Por lo tanto, utilizo mingw-w64 y wine para compilar y ejecutar minilua y buildvm de 32 bits.
