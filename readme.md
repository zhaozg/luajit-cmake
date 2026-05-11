# luajit-cmake

A flexible cmake builder for LuaJIT.

## External Dependencies

This project requires several external tools for building and cross-compilation:

### Zig

- **Purpose**: Used as a cross-compilation toolchain for building LuaJIT for various targets.
- **Version**: 0.16.0
- **Toolchain File**: `Utils/zig.toolchain.cmake`
- **Installation**: Install Zig from [ziglang.org](https://ziglang.org/)

### Git

- **Purpose**: Required for cloning the repository and managing source code.
- **Installation**: Usually pre-installed on macOS. For other systems, install from [git-scm.com](https://git-scm.com/)

### Wine

- **Purpose**: Used to run 32-bit Windows executables on non-Windows systems during the build process.
- **Usage**: Referenced in `Utils/Darwin.wine.cmake` for macOS builds.
- **Installation**: Install Wine from [winehq.org](https://www.winehq.org/)

## Build

### make

Use a GNU compatible make.

`make -DLUAJIT_DIR=...` or `mingw32-make -DLUAJIT_DIR=...` or
`gnumake -DLUAJIT_DIR=...`.

_Note_: When use mingw32-make, please change `\\` to `/` in file path on Windows.

### cmake

Use cmake to compile.

```bash
cmake -H. -Bbuild -DLUAJIT_DIR=...
make --build build --config Release
```

### Embed

```cmake
add_subdirectory(luajit-cmake)
target_link_libraries(yourTarget PRIVATE luajit::lib luajit::header)
```

Look samples at [lua-forge](https://github.com/zhaozg/lua-forge/blob/master/CMakeLists.txt)

### CrossCompile

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

The library also supports cross-compilation for HarmonyOS. Please refer to the toolchain files in `Utils/` directory for HarmonyOS specific configurations.

```bash
make OHOS
```

#### Note

_Note_: The i386 architecture is deprecated for macOS (remove from the Xcode
build setting: ARCHS). So I use mingw-w64 and wine to build and run 32 bits
minilua and buildvm.
