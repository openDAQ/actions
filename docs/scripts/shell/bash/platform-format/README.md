# platform-format.sh

Platform alias parser, validator, and composer for consistent cross-platform builds.

## Quick Reference

| Command | Purpose | Example |
|---------|---------|---------|
| `detect` | Auto-detect current platform | `./platform-format.sh detect` → `ubuntu20.04-arm64` |
| `validate` | Check platform validity | `./platform-format.sh validate ubuntu20.04-arm64` |
| `parse` | Extract components | `./platform-format.sh parse ubuntu20.04-arm64` → `ubuntu 20.04 arm64` |
| `compose` | Build platform alias | `./platform-format.sh compose --os-name ubuntu --os-version 20.04 --os-arch arm64` |
| `--list-platforms` | List all supported platforms | Shows all 100+ platform combinations |

## Platform Format

### Linux/macOS Format

```
{os}{version}-{arch}
```

**Examples:**
- `ubuntu20.04-arm64`
- `debian11-x86_64`
- `macos14-arm64`

### Windows Format

```
win{arch}
```

**Examples:**
- `win64`
- `win32`

## Supported Platforms

### Ubuntu

| Version | Architectures |
|---------|--------------|
| 20.04 | arm64, x86_64 |
| 22.04 | arm64, x86_64 |
| 24.04 | arm64, x86_64 |

### Debian

| Version | Architectures |
|---------|--------------|
| 8, 9, 10, 11, 12 | arm64, x86_64 |

### macOS

| Version | Architectures |
|---------|--------------|
| 13, 14, 15, 16, 17, 18, 26 | arm64, x86_64 |

**Note:** macOS versions are major versions only (e.g., 14 represents all 14.x releases)

### Windows

| Architecture | Platform Alias |
|-------------|---------------|
| 32-bit | win32 |
| 64-bit | win64 |

## Quick Start

### CLI Usage

```bash
# Detect current platform
./platform-format.sh detect
# Output: ubuntu20.04-arm64

# Validate platform
./platform-format.sh validate ubuntu20.04-arm64
echo $?  # 0 = valid, 1 = invalid

# Check platform type
./platform-format.sh validate ubuntu20.04-arm64 --is-linux
echo $?  # 0 = true, 1 = false

# Parse platform
./platform-format.sh parse ubuntu20.04-arm64
# Output: ubuntu 20.04 arm64

./platform-format.sh parse ubuntu20.04-arm64 --os-name
# Output: ubuntu

# Compose platform
./platform-format.sh compose --os-name ubuntu --os-version 20.04 --os-arch arm64
# Output: ubuntu20.04-arm64

# List all supported platforms
./platform-format.sh --list-platforms
```

## Commands

### detect

Auto-detect current platform from system information.

**Usage:**
```bash
./platform-format.sh detect
```

**Output:** Platform alias (e.g., `ubuntu20.04-arm64`)

**Exit codes:**
- `0` - Successfully detected supported platform
- `1` - Detection failed or platform not supported

**Verbose output:**
```bash
./platform-format.sh --verbose detect
# [VERBOSE] Detected OS: ubuntu
# [VERBOSE] Detected version: 20.04
# [VERBOSE] Detected architecture: arm64
# [VERBOSE] Composed platform: ubuntu20.04-arm64
# [VERBOSE] Platform is supported: ubuntu20.04-arm64
# ubuntu20.04-arm64
```

### validate

Validate a platform alias and optionally check its type.

**Usage:**
```bash
./platform-format.sh validate <platform> [type-check-flags]
```

**Type Check Flags:**
- `--is-unix` - Check if Unix-based (Ubuntu/Debian/macOS)
- `--is-linux` - Check if Linux (Ubuntu/Debian)
- `--is-ubuntu` - Check if Ubuntu
- `--is-debian` - Check if Debian
- `--is-macos` - Check if macOS
- `--is-win` - Check if Windows

**Examples:**
```bash
# Simple validation
./platform-format.sh validate ubuntu20.04-arm64
echo $?  # 0 = valid

./platform-format.sh validate invalid-platform
echo $?  # 1 = invalid

# Type checks
./platform-format.sh validate ubuntu20.04-arm64 --is-linux
echo $?  # 0 = true

./platform-format.sh validate win64 --is-linux
echo $?  # 1 = false

./platform-format.sh validate macos14-arm64 --is-unix
echo $?  # 0 = true
```

### parse / extract

Parse platform alias into its components.

**Usage:**
```bash
./platform-format.sh parse <platform> [component-flags]
./platform-format.sh extract <platform> [component-flags]  # alias
```

**Component Flags:**
- `--os-name` - Extract only OS name
- `--os-version` - Extract only OS version (not available for Windows)
- `--os-arch` - Extract only architecture

**Examples:**
```bash
# Parse all components
./platform-format.sh parse ubuntu20.04-arm64
# Output: ubuntu 20.04 arm64

./platform-format.sh parse win64
# Output: win 64

# Extract specific components
./platform-format.sh parse ubuntu20.04-arm64 --os-name
# Output: ubuntu

./platform-format.sh parse ubuntu20.04-arm64 --os-version
# Output: 20.04

./platform-format.sh parse ubuntu20.04-arm64 --os-arch
# Output: arm64

# Multiple components
./platform-format.sh parse ubuntu20.04-arm64 --os-name --os-arch
# Output: ubuntu arm64

# Windows (no version)
./platform-format.sh parse win64 --os-version
# Output: (empty - Windows has no version)
```

### compose

Compose a platform alias from individual components.

**Usage:**
```bash
./platform-format.sh compose --os-name <name> [--os-version <version>] --os-arch <arch>
```

**Arguments:**
- `--os-name <name>` - OS name: ubuntu, debian, macos, win (required)
- `--os-version <version>` - OS version (required for Linux/macOS, not used for Windows)
- `--os-arch <arch>` - Architecture (required)
  - Linux/macOS: arm64, x86_64
  - Windows: 32, 64

**Examples:**
```bash
# Compose Linux platform
./platform-format.sh compose --os-name ubuntu --os-version 20.04 --os-arch arm64
# Output: ubuntu20.04-arm64

# Compose macOS platform
./platform-format.sh compose --os-name macos --os-version 14 --os-arch arm64
# Output: macos14-arm64

# Compose Windows platform (no version)
./platform-format.sh compose --os-name win --os-arch 64
# Output: win64

# Error: missing required argument
./platform-format.sh compose --os-name ubuntu --os-arch arm64
# Error: --os-version is required for non-Windows platforms
```

### --list-platforms

List all supported platform aliases.

**Usage:**
```bash
./platform-format.sh --list-platforms
```

**Output:** One platform per line
```
ubuntu20.04-arm64
ubuntu20.04-x86_64
ubuntu22.04-arm64
ubuntu22.04-x86_64
...
win32
win64
```

## Global Options

Global options can be placed anywhere in the command line:

- `--verbose` / `-v` - Enable verbose output to stderr
- `--debug` / `-d` - Enable debug output to stderr
- `--quiet` / `-q` - Suppress error messages

**Examples:**
```bash
./platform-format.sh --verbose detect
./platform-format.sh detect --verbose
./platform-format.sh --debug validate ubuntu20.04-arm64
./platform-format.sh compose --verbose --os-name ubuntu --os-version 20.04 --os-arch arm64
```

## Installation

### As CLI Tool

```bash
# Copy to your scripts directory
cp platform-format.sh /usr/local/bin/
chmod +x /usr/local/bin/platform-format.sh

# Or use directly
chmod +x platform-format.sh
./platform-format.sh detect
```

### As Library

```bash
# In your script directory
cp platform-format.sh ./scripts/

# In your script
source ./scripts/platform-format.sh
platform=$(daq_platform_detect)
```

## Common Use Cases

### Cross-Platform Builds

```bash
#!/usr/bin/env bash
source platform-format.sh

platform=$(daq_platform_detect)
echo "Building for: $platform"

# Parse components
read -r os_name os_version os_arch <<< "$(daq_platform_parse "$platform")"

# Platform-specific logic
if daq_platform_validate "$platform" --is-linux; then
    echo "Using Linux build configuration"
    ./build-linux.sh "$os_version" "$os_arch"
elif daq_platform_validate "$platform" --is-macos; then
    echo "Using macOS build configuration"
    ./build-macos.sh "$os_version" "$os_arch"
elif daq_platform_validate "$platform" --is-win; then
    echo "Using Windows build configuration"
    ./build-windows.sh "$os_arch"
fi
```

### Artifact Naming

```bash
#!/usr/bin/env bash
source platform-format.sh

VERSION="1.2.3"
platform=$(daq_platform_detect)

artifact="myapp-${VERSION}-${platform}.tar.gz"
echo "Creating artifact: $artifact"

# Example outputs:
# myapp-1.2.3-ubuntu20.04-arm64.tar.gz
# myapp-1.2.3-win64.tar.gz
```

### Platform Filtering

```bash
#!/usr/bin/env bash
source platform-format.sh

# Get all Linux platforms
daq_platform_list | while read -r platform; do
    if daq_platform_validate "$platform" --is-linux; then
        echo "Linux platform: $platform"
    fi
done
```

## Error Handling

All commands use consistent exit codes:
- `0` - Success / Valid / True
- `1` - Error / Invalid / False

**Examples:**
```bash
# Check if platform is valid
if ./platform-format.sh validate "$platform"; then
    echo "Valid platform: $platform"
else
    echo "Invalid platform: $platform"
    exit 1
fi

# Detect platform with error handling
if platform=$(./platform-format.sh detect 2>/dev/null); then
    echo "Detected: $platform"
else
    echo "Failed to detect platform"
    exit 1
fi

# Quiet mode (suppress errors)
if ./platform-format.sh --quiet validate "$platform"; then
    # Valid
    :
fi
```

## Requirements

- Bash 3.2+ or Zsh
- Standard Unix tools: `uname`, `sed`, `cut`, `grep`, `echo`, `read`
- Linux: `/etc/os-release` file (standard on modern distributions)
- macOS: `sw_vers` command (standard on macOS)
- Windows: Git Bash, MSYS2, or Cygwin environment

## Compatibility

### Shells
- ✅ Bash 3.2+
- ✅ Bash 4.x, 5.x
- ✅ Zsh 5.x

### Operating Systems
- ✅ Ubuntu 20.04+
- ✅ Debian 8+
- ✅ macOS 13+ (Ventura and later)
- ✅ Windows (via Git Bash, MSYS2, Cygwin)

## Limitations

1. **macOS version detection** uses major version only (14.2.1 → 14)
2. **Windows version** is not included in platform alias (only architecture)
3. **32-bit Linux/macOS** is not supported (only arm64 and x86_64)
4. **Requires** `/etc/os-release` on Linux (standard since ~2012)

## Troubleshooting

### Platform not detected

**Symptom:**
```
Error: Detected platform ubuntu18.04-arm64 is not supported
```

**Solution:** Add the version to supported versions in the script:
```bash
__DAQ_PLATFORM_UBUNTU_VERSIONS=("18.04" "20.04" "22.04" "24.04")
```

### Cannot detect OS

**Symptom:**
```
Error: Cannot detect Linux distribution: /etc/os-release not found
```

**Solution:** Ensure `/etc/os-release` exists (standard on modern Linux). For older systems, you may need to add custom detection logic.

### Wrong architecture detected

**Symptom:** On ARM Mac, detects `x86_64` instead of `arm64`

**Solution:** Check if running under Rosetta 2. Use native shell: `arch -arm64 bash`

## See Also

- [API.md](./API.md) - Complete API reference for library usage
- [CONVENTIONS.md](./../CONVENTIONS.md) - Common naming conventions for OpenDAQ bash scripts.
- [README.md](./../../../../../README.md) - Actions overview
