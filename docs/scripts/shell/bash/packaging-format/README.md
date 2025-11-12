# packaging-format.sh

Package file extension detection utility for OpenDAQ project.

## Overview

The `packaging-format.sh` script provides utilities for detecting package file extensions based on:
- **CPack generators** (NSIS, ZIP, TGZ, DEB)
- **Operating system names** (Windows, Linux, macOS)
- **GitHub runner.os values** (windows-latest, ubuntu-latest, macos-latest)

This enables dynamic package file naming in CI/CD workflows and build scripts.

## Features

- **Dual mode operation**: CLI tool or sourceable library
- **CPack generator detection**: Maps CPack generators to file extensions
- **OS-based detection**: Maps OS names to default package extensions
- **GitHub Actions integration**: Handles both runner names and `${{ runner.os }}` values
- **Customizable defaults**: Override extensions via environment variables
- **Shell compatibility**: Works with bash 3.2+ and zsh
- **Verbose mode**: Optional detailed logging for debugging

## Quick Start

### CLI Usage

```bash
# Detect from CPack generator
./packaging-format.sh detect --cpack-generator NSIS
# Output: exe

./packaging-format.sh detect --cpack-generator DEB
# Output: deb

# Detect from OS name
./packaging-format.sh detect --os-name windows-latest
# Output: exe

./packaging-format.sh detect --os-name ubuntu-latest
# Output: deb

./packaging-format.sh detect --os-name Linux
# Output: deb

# With verbose output
./packaging-format.sh detect --os-name macos-latest --verbose
```

## Package Extensions

### Default Mappings

| OS | CPack Generator | Default Extension | Customization Variable |
|---|---|---|---|
| **Windows** | NSIS | `exe` | `OPENDAQ_PACKAGING_WIN` |
| **Linux** | DEB | `deb` | `OPENDAQ_PACKAGING_LINUX` |
| **macOS** | TGZ | `tar.gz` | `OPENDAQ_PACKAGING_MACOS` |

### CPack Generator Mappings

| Generator | Extension | Description |
|---|---|---|
| **NSIS** | `exe` | Windows NSIS installer |
| **ZIP** | `zip` | ZIP archive |
| **TGZ** | `tar.gz` | Tarball (gzipped) |
| **DEB** | `deb` | Debian package |

## OS Name Handling

The script accepts various OS name formats and normalizes them:

### GitHub Runner Names
```bash
windows-latest    → windows → exe
ubuntu-latest     → linux   → deb
macos-latest      → macos   → tar.gz
ubuntu-22.04      → linux   → deb
```

### GitHub runner.os Values
```bash
Windows           → windows → exe
Linux             → linux   → deb
macOS             → macos   → tar.gz
```

### Pattern Matching

The script uses flexible pattern matching:
- **Windows**: `windows*`, `win*`
- **Linux**: `ubuntu*`, `linux*`, `debian*`
- **macOS**: `macos*`, `mac*`, `osx*`

All matching is case-insensitive.

## CLI Reference

### Commands

```
detect              Detect package file extension
```

### Options

```
--cpack-generator <GENERATOR>
    Detect extension from CPack generator
    Supported: NSIS, ZIP, TGZ, DEB

--os-name <OS_NAME>
    Detect extension from OS name
    Supports: GitHub runner names, runner.os values

--verbose
    Enable verbose output (logs to stderr)

-h, --help
    Show help message
```

### Exit Codes

- `0` - Success
- `1` - Error (invalid input, unsupported generator/OS)

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `OPENDAQ_PACKAGING_WIN` | `exe` | Package extension for Windows |
| `OPENDAQ_PACKAGING_LINUX` | `deb` | Package extension for Linux |
| `OPENDAQ_PACKAGING_MACOS` | `tar.gz` | Package extension for macOS |

## Examples

### Basic Detection

```bash
# CPack generator
./packaging-format.sh detect --cpack-generator NSIS
# Output: exe

# OS name (GitHub runner)
./packaging-format.sh detect --os-name windows-latest
# Output: exe

# OS name (runner.os)
./packaging-format.sh detect --os-name Linux
# Output: deb
```

### Error Handling

```bash
# Unsupported generator
./packaging-format.sh detect --cpack-generator INVALID
# [ERROR] Unsupported CPack generator: INVALID
# [ERROR] Supported generators: NSIS, ZIP, TGZ, DEB
# Exit code: 1

# Unknown OS
./packaging-format.sh detect --os-name unknown-os
# [ERROR] Unknown OS name: unknown-os
# Exit code: 1
```

## Troubleshooting

### Extension Not Detected

**Problem**: Script fails to detect extension

**Solution**: Check input format
```bash
# Use --verbose to see what's happening
./packaging-format.sh detect --os-name myos --verbose
# [INFO] Normalizing OS name: myos
# [ERROR] Unknown OS name: myos
```

### Wrong Extension Returned

**Problem**: Getting wrong extension for OS

**Solution**: Check environment variables
```bash
# Check current values
echo "$OPENDAQ_PACKAGING_LINUX"

# Reset if needed
unset OPENDAQ_PACKAGING_LINUX
```

### Script Not Working When Sourced

**Problem**: Functions not available after sourcing

**Solution**: Check source command
```bash
# Correct
source packaging-format.sh

# Or
. packaging-format.sh

# Verify functions are loaded
type daq_packaging_detect_from_os
```

## Requirements

- **Shell**: bash 3.2+ or zsh
- **Dependencies**: None (uses only shell built-ins)
- **OS**: Linux, macOS, Windows (Git Bash/WSL)

## See Also

- [API.md](./API.md) - Complete API reference
- [CONVENTIONS.md](./../CONVENTIONS.md) - Common naming conventions for OpenDAQ bash scripts.
- [README.md](./../../../../../README.md) - Actions overview
