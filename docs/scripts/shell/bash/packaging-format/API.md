# packaging-format.sh API Reference

Complete API documentation for the packaging format detection module.

## Table of Contents

- [Overview](#overview)
- [Public Functions](#public-functions)
  - [daq_packaging_detect_from_cpack](#daq_packaging_detect_from_cpack)
  - [daq_packaging_detect_from_os](#daq_packaging_detect_from_os)
- [Environment Variables](#environment-variables)
- [Return Values](#return-values)

## Overview

The packaging format module provides a minimal, focused API for detecting package file extensions. All public functions follow the `daq_packaging_*` naming convention.

### Module Prefix

All public functions use the prefix: `daq_packaging_`

## Public Functions

### daq_packaging_detect_from_cpack

Detects package file extension from CPack generator name.

#### Signature

```bash
daq_packaging_detect_from_cpack <generator>
```

#### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `generator` | string | Yes | CPack generator name (case-insensitive) |

#### Supported Generators

| Generator | Extension | Description |
|---|---|---|
| `NSIS` | `exe` | Windows NSIS installer |
| `ZIP` | `zip` | ZIP archive |
| `TGZ` | `tar.gz` | Tarball (gzipped) |
| `DEB` | `deb` | Debian package |

**Note**: Generator names are case-insensitive (`nsis`, `NSIS`, `Nsis` all work)

#### Output

Prints the package file extension to stdout.

#### Return Value

- `0` - Success, extension detected and printed
- `1` - Error (empty input or unsupported generator)

---

### daq_packaging_detect_from_os

Detects package file extension from operating system name.

#### Signature

```bash
daq_packaging_detect_from_os <os_name>
```

#### Parameters

| Parameter | Type | Required | Description |
|---|---|---|---|
| `os_name` | string | Yes | OS name (GitHub runner name or runner.os value) |

#### Supported OS Names

The function accepts various OS name formats:

**GitHub Runner Names:**
```
windows-latest, windows-2022, windows-2019
ubuntu-latest, ubuntu-22.04, ubuntu-20.04
macos-latest, macos-13, macos-12
```

**GitHub runner.os Values:**
```
Windows, Linux, macOS
```

**Pattern Matching:**
- **Windows**: Matches `windows*`, `win*`
- **Linux**: Matches `ubuntu*`, `linux*`, `debian*`
- **macOS**: Matches `macos*`, `mac*`, `osx*`

All matching is case-insensitive.

#### Default Extensions

Default extensions can be customized via environment variables:

| OS | Default Extension | Environment Variable |
|---|---|---|
| Windows | `exe` | `OPENDAQ_PACKAGING_WIN` |
| Linux | `deb` | `OPENDAQ_PACKAGING_LINUX` |
| macOS | `tar.gz` | `OPENDAQ_PACKAGING_MACOS` |

#### Output

Prints the package file extension to stdout.

#### Return Value

- `0` - Success, extension detected and printed
- `1` - Error (empty input or unknown OS)

#### Normalization Process

The function normalizes OS names in two steps:

1. **Convert to lowercase**: `Ubuntu-Latest` → `ubuntu-latest`
2. **Pattern match**: `ubuntu-latest` → `linux` → use `OPENDAQ_PACKAGING_LINUX`

**Normalization Examples:**

```bash
windows-latest  → windows → $OPENDAQ_PACKAGING_WIN
Windows         → windows → $OPENDAQ_PACKAGING_WIN
WIN10           → windows → $OPENDAQ_PACKAGING_WIN

ubuntu-22.04    → linux   → $OPENDAQ_PACKAGING_LINUX
Linux           → linux   → $OPENDAQ_PACKAGING_LINUX
debian-11       → linux   → $OPENDAQ_PACKAGING_LINUX

macos-13        → macos   → $OPENDAQ_PACKAGING_MACOS
macOS           → macos   → $OPENDAQ_PACKAGING_MACOS
osx             → macos   → $OPENDAQ_PACKAGING_MACOS
```

---

## Environment Variables

### OPENDAQ_PACKAGING_WIN

Package extension for Windows.

**Default**: `exe`
**Valid Values**: Any string (typically: `exe`, `zip`, `msi`)

---

### OPENDAQ_PACKAGING_LINUX

Package extension for Linux.

**Default**: `deb`
**Valid Values**: Any string (typically: `deb`, `rpm`, `tar.gz`, `AppImage`)

---

### OPENDAQ_PACKAGING_MACOS

Package extension for macOS.

**Default**: `tar.gz`
**Valid Values**: Any string (typically: `dmg`, `pkg`, `tar.gz`, `zip`)

---

## Return Values

All public functions follow a consistent return value convention:

### Success (0)

Function executed successfully and produced output.

```bash
if daq_packaging_detect_from_cpack "NSIS"; then
    echo "Success"
fi
# Output: exe
#         Success
```

### Error (1)

Function encountered an error (invalid input, unsupported value).

```bash
if ! daq_packaging_detect_from_cpack "INVALID"; then
    echo "Failed"
fi
# Output: [ERROR] Unsupported CPack generator: INVALID
#         [ERROR] Supported generators: NSIS, ZIP, TGZ, DEB
#         Failed
```

---

## Error Handling

### Error Message Format

All error messages are written to stderr with `[ERROR]` prefix:

```
[ERROR] <error description>
```

---

## See Also

- [README.md](./README.md) - Module overview and quick start
- **[CONVENTIONS.md](./../CONVENTIONS.md)** - Common naming conventions for OpenDAQ bash scripts.
