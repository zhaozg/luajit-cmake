# luajit-cmake

## Overview

This repository provides a flexible CMake-based build system for LuaJIT, supporting various platforms and cross-compilation scenarios.

## External Dependencies

The project requires several external tools for building and cross-compilation:

### Zig

- **Purpose**: Used as a cross-compilation toolchain for building LuaJIT for various targets.
- **Version**: 0.16.0
- **Toolchain File**: `Utils/zig.toolchain.cmake`
- **Installation**: Install Zig from [ziglang.org](https://ziglang.org/)

### Wine

- **Purpose**: Used to run 32-bit Windows executables on non-Windows systems during the build process.
- **Usage**: Referenced in `Utils/Darwin.wine.cmake` for macOS builds.
- **Installation**: Install Wine from [winehq.org](https://www.winehq.org/)

## Supported Platforms

- Native builds (Linux, macOS, Windows)
- iOS cross-compilation
- Android cross-compilation
- Windows cross-compilation from other platforms
- HarmonyOS support

## Build Instructions

Refer to `readme.md` for detailed build instructions using make or CMake.

## Repository Structure

- Root directory contains main CMake files and build scripts
- `Utils/`: Platform-specific toolchain files including Zig and Wine configurations
- `Modules/`: CMake modules for finding dependencies
- `host/`: Contains subdirectories for host tools (buildvm, minilua)

This analysis identifies all external dependencies and their roles in the build system, providing clear documentation for users who wish to set up their environment for building LuaJIT with this CMake configuration.
