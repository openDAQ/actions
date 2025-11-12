# platform-format.sh API Reference

Complete reference for using `platform-format.sh` as a library in your scripts.

## Table of Contents

- [Quick Start](#quick-start)
- [Public API Functions](#public-api-functions)
  - [daq_platform_detect](#daq_platform_detect)
  - [daq_platform_validate](#daq_platform_validate)
  - [daq_platform_parse](#daq_platform_parse)
  - [daq_platform_extract](#daq_platform_extract)
  - [daq_platform_compose](#daq_platform_compose)
  - [daq_platform_list](#daq_platform_list)
- [Global Configuration](#global-configuration)
- [Exit Codes](#exit-codes)
- [Platform Format Specification](#platform-format-specification)
- [Type Checking](#type-checking)
- [Best Practices](#best-practices)
- [Error Handling](#error-handling)

## Quick Start

```bash
#!/usr/bin/env bash
source platform-format.sh

# Detect current platform
platform=$(daq_platform_detect)

# Parse components
read -r os_name os_version os_arch <<< "$(daq_platform_parse "$platform")"

# Validate and check type
if daq_platform_validate "$platform" --is-linux; then
    echo "Linux platform: $platform"
fi

# Compose custom platform
custom=$(daq_platform_compose --os-name debian --os-version 11 --os-arch arm64)
```

## Public API Functions

### daq_platform_detect

Auto-detect current platform from system information.

**Signature:**
```bash
daq_platform_detect
```

**Arguments:** None

**Output:**
- **stdout**: Platform alias (e.g., `ubuntu20.04-arm64`)

**Exit Codes:**
- `0` - Successfully detected supported platform
- `1` - Detection failed or platform not supported

**Detection Method:**
- **Linux**: Reads `/etc/os-release` for distribution and version
- **macOS**: Uses `sw_vers -productVersion` for version (major only)
- **Windows**: Detects from `uname -s` (MINGW*/MSYS*/CYGWIN*)
- **Architecture**: Uses `uname -m` and normalizes (aarch64→arm64, etc.)

**Examples:**

```bash
# Basic detection
platform=$(daq_platform_detect)
if [ $? -eq 0 ]; then
    echo "Detected platform: $platform"
else
    echo "Failed to detect platform"
    exit 1
fi

# With error handling
if ! platform=$(daq_platform_detect); then
    echo "Unsupported platform"
    exit 1
fi

# Detection in CI
PLATFORM=$(daq_platform_detect)
echo "PLATFORM=$PLATFORM" >> $GITHUB_ENV
```

**Verbose Output:**
```bash
# Set verbose before calling
__DAQ_PLATFORM_VERBOSE=1
platform=$(daq_platform_detect)
# [VERBOSE] Detected OS: ubuntu
# [VERBOSE] Detected version: 20.04
# [VERBOSE] Detected architecture: arm64
# [VERBOSE] Composed platform: ubuntu20.04-arm64
```

**Error Cases:**
```bash
# Unsupported OS
# Error: Unsupported operating system: FreeBSD

# Unsupported version
# Error: Detected platform ubuntu18.04-arm64 is not supported
#   Details: Supported platforms can be listed with: --list-platforms

# Missing /etc/os-release
# Error: Cannot detect Linux distribution: /etc/os-release not found
```

---

### daq_platform_validate

Validate a platform alias and optionally check its type.

**Signature:**
```bash
daq_platform_validate <platform> [type_check_flag]
```

**Arguments:**
- `platform` (required) - Platform alias to validate
- `type_check_flag` (optional) - One of:
  - `--is-unix` - Check if Unix-based (Ubuntu/Debian/macOS)
  - `--is-linux` - Check if Linux (Ubuntu/Debian)
  - `--is-ubuntu` - Check if Ubuntu
  - `--is-debian` - Check if Debian
  - `--is-macos` - Check if macOS
  - `--is-win` - Check if Windows

**Output:** None (uses exit codes only)

**Exit Codes:**
- `0` - Platform is valid / Type check passed
- `1` - Platform is invalid / Type check failed

**Examples:**

```bash
# Simple validation
if daq_platform_validate "ubuntu20.04-arm64"; then
    echo "Valid platform"
fi

# Type checking
platform="ubuntu20.04-arm64"

if daq_platform_validate "$platform" --is-linux; then
    echo "This is a Linux platform"
fi

if daq_platform_validate "$platform" --is-unix; then
    echo "This is a Unix platform"
fi

# Platform-specific logic
case "$platform" in
    *)
        if daq_platform_validate "$platform" --is-ubuntu; then
            echo "Ubuntu-specific logic"
        elif daq_platform_validate "$platform" --is-debian; then
            echo "Debian-specific logic"
        elif daq_platform_validate "$platform" --is-macos; then
            echo "macOS-specific logic"
        elif daq_platform_validate "$platform" --is-win; then
            echo "Windows-specific logic"
        fi
        ;;
esac

# Validation in scripts
validate_platform() {
    local platform="$1"
    
    if ! daq_platform_validate "$platform"; then
        echo "Error: Invalid platform: $platform" >&2
        return 1
    fi
    
    return 0
}
```

**Type Check Matrix:**

| Platform | --is-unix | --is-linux | --is-ubuntu | --is-debian | --is-macos | --is-win |
|----------|-----------|------------|-------------|-------------|------------|----------|
| ubuntu20.04-arm64 | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| debian11-x86_64 | ✅ | ✅ | ❌ | ✅ | ❌ | ❌ |
| macos14-arm64 | ✅ | ❌ | ❌ | ❌ | ✅ | ❌ |
| win64 | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |

---

### daq_platform_parse

Parse platform alias into its components.

**Signature:**
```bash
daq_platform_parse <platform> [component_flags...]
```

**Arguments:**
- `platform` (required) - Platform alias to parse
- `component_flags` (optional) - One or more of:
  - `--os-name` - Extract only OS name
  - `--os-version` - Extract only OS version (not available for Windows)
  - `--os-arch` - Extract only architecture

**Output:**
- Without flags: All components separated by spaces
  - Linux/macOS: `os_name os_version os_arch`
  - Windows: `os_name os_arch` (no version)
- With flags: Requested components separated by spaces

**Exit Codes:**
- `0` - Successfully parsed
- `1` - Invalid platform or parsing error

**Examples:**

```bash
# Parse all components
components=$(daq_platform_parse "ubuntu20.04-arm64")
read -r os_name os_version os_arch <<< "$components"
echo "OS: $os_name $os_version"
echo "Arch: $os_arch"
# Output:
# OS: ubuntu 20.04
# Arch: arm64

# Extract specific components
os_name=$(daq_platform_parse "ubuntu20.04-arm64" --os-name)
# Output: ubuntu

os_version=$(daq_platform_parse "ubuntu20.04-arm64" --os-version)
# Output: 20.04

os_arch=$(daq_platform_parse "ubuntu20.04-arm64" --os-arch)
# Output: arm64

# Multiple components
result=$(daq_platform_parse "ubuntu20.04-arm64" --os-name --os-arch)
read -r os_name os_arch <<< "$result"
# os_name=ubuntu, os_arch=arm64

# Windows (no version)
components=$(daq_platform_parse "win64")
read -r os_name os_arch <<< "$components"
# os_name=win, os_arch=64

version=$(daq_platform_parse "win64" --os-version)
# version="" (empty - Windows has no version)

# Use in conditional
platform="macos14-arm64"
if [ "$(daq_platform_parse "$platform" --os-arch)" = "arm64" ]; then
    echo "ARM64 architecture detected"
fi

# Parse for artifact naming
get_artifact_suffix() {
    local platform="$1"
    local arch
    
    arch=$(daq_platform_parse "$platform" --os-arch)
    
    case "$arch" in
        arm64) echo "aarch64" ;;
        x86_64) echo "x64" ;;
        32) echo "x86" ;;
        64) echo "x64" ;;
    esac
}
```

**Platform-Specific Behavior:**

```bash
# Ubuntu - 3 components
daq_platform_parse "ubuntu20.04-arm64"
# Output: ubuntu 20.04 arm64

# Debian - 3 components
daq_platform_parse "debian11-x86_64"
# Output: debian 11 x86_64

# macOS - 3 components
daq_platform_parse "macos14-arm64"
# Output: macos 14 arm64

# Windows - 2 components (no version)
daq_platform_parse "win64"
# Output: win 64

# Windows version flag returns empty
daq_platform_parse "win64" --os-version
# Output: (empty)
```

---

### daq_platform_extract

Alias for `daq_platform_parse`. See [daq_platform_parse](#daq_platform_parse) for documentation.

**Signature:**
```bash
daq_platform_extract <platform> [component_flags...]
```

**Note:** This is provided as an alias for API consistency with `version-format.sh`, which has `daq_version_extract` for extracting versions from text. In `platform-format.sh`, both `parse` and `extract` do the same thing.

---

### daq_platform_compose

Compose a platform alias from individual components.

**Signature:**
```bash
daq_platform_compose --os-name <name> [--os-version <version>] --os-arch <arch>
```

**Arguments:**
- `--os-name <name>` (required) - OS name
  - Valid values: `ubuntu`, `debian`, `macos`, `win`
- `--os-version <version>` (conditionally required) - OS version
  - Required for: ubuntu, debian, macos
  - Not used for: win
  - Format: version number (e.g., `20.04`, `11`, `14`)
- `--os-arch <arch>` (required) - Architecture
  - For Linux/macOS: `arm64`, `x86_64`
  - For Windows: `32`, `64`

**Output:**
- **stdout**: Composed platform alias

**Exit Codes:**
- `0` - Successfully composed valid platform
- `1` - Missing required arguments or invalid composition

**Examples:**

```bash
# Compose Ubuntu platform
platform=$(daq_platform_compose \
    --os-name ubuntu \
    --os-version 20.04 \
    --os-arch arm64)
# Output: ubuntu20.04-arm64

# Compose Debian platform
platform=$(daq_platform_compose \
    --os-name debian \
    --os-version 11 \
    --os-arch x86_64)
# Output: debian11-x86_64

# Compose macOS platform
platform=$(daq_platform_compose \
    --os-name macos \
    --os-version 14 \
    --os-arch arm64)
# Output: macos14-arm64

# Compose Windows platform (no version)
platform=$(daq_platform_compose \
    --os-name win \
    --os-arch 64)
# Output: win64

# Dynamic composition
build_platform() {
    local os="$1"
    local version="$2"
    local arch="$3"
    
    if [ "$os" = "win" ]; then
        daq_platform_compose --os-name "$os" --os-arch "$arch"
    else
        daq_platform_compose --os-name "$os" --os-version "$version" --os-arch "$arch"
    fi
}

# Use with parsed components
source_platform="ubuntu20.04-arm64"
read -r os_name os_version os_arch <<< "$(daq_platform_parse "$source_platform")"

# Create variant with different arch
alt_platform=$(daq_platform_compose \
    --os-name "$os_name" \
    --os-version "$os_version" \
    --os-arch "x86_64")
# Output: ubuntu20.04-x86_64
```

**Error Cases:**

```bash
# Missing --os-name
daq_platform_compose --os-version 20.04 --os-arch arm64
# Error: --os-name is required

# Missing --os-arch
daq_platform_compose --os-name ubuntu --os-version 20.04
# Error: --os-arch is required

# Missing --os-version for non-Windows
daq_platform_compose --os-name ubuntu --os-arch arm64
# Error: --os-version is required for non-Windows platforms

# Invalid composition (unsupported version)
daq_platform_compose --os-name ubuntu --os-version 18.04 --os-arch arm64
# Error: Invalid platform composition: ubuntu18.04-arm64

# Invalid composition (unsupported architecture)
daq_platform_compose --os-name ubuntu --os-version 20.04 --os-arch i386
# Error: Invalid platform composition: ubuntu20.04-i386
```

**Validation:** The composed platform is automatically validated against the list of supported platforms. If the composition is invalid, an error is returned.

---

### daq_platform_list

List all supported platform aliases.

**Signature:**
```bash
daq_platform_list
```

**Arguments:** None

**Output:**
- **stdout**: All supported platforms, one per line

**Exit Code:** `0` (always succeeds)

**Examples:**

```bash
# List all platforms
daq_platform_list
# Output:
# ubuntu20.04-arm64
# ubuntu20.04-x86_64
# ubuntu22.04-arm64
# ubuntu22.04-x86_64
# ...
# win32
# win64

# Count platforms
count=$(daq_platform_list | wc -l)
echo "Total platforms: $count"
# Output: Total platforms: 104

# Filter platforms
echo "Linux platforms:"
daq_platform_list | while read -r platform; do
    if daq_platform_validate "$platform" --is-linux; then
        echo "  $platform"
    fi
done

# Find ARM64 platforms
echo "ARM64 platforms:"
daq_platform_list | grep -- "-arm64$"

# Check if specific platform is supported
is_platform_supported() {
    local platform="$1"
    daq_platform_list | grep -qx "$platform"
}

if is_platform_supported "ubuntu20.04-arm64"; then
    echo "Platform is supported"
fi

# Generate build matrix
generate_build_matrix() {
    local platforms=()
    
    while IFS= read -r platform; do
        if daq_platform_validate "$platform" --is-linux; then
            platforms+=("$platform")
        fi
    done < <(daq_platform_list)
    
    printf '%s\n' "${platforms[@]}"
}
```

**Platform Count:**
- Ubuntu: 3 versions × 2 architectures = 6 platforms
- Debian: 5 versions × 2 architectures = 10 platforms
- macOS: 7 versions × 2 architectures = 14 platforms
- Windows: 2 architectures = 2 platforms
- **Total: 104 platforms**

---

## Global Configuration

### Runtime Flags

These variables control output behavior. Set them before calling functions:

```bash
# Enable verbose output to stderr
__DAQ_PLATFORM_VERBOSE=1

# Enable debug output to stderr
__DAQ_PLATFORM_DEBUG=1

# Suppress error messages
__DAQ_PLATFORM_QUIET=1
```

**Example:**
```bash
#!/usr/bin/env bash
source platform-format.sh

# Enable verbose mode
__DAQ_PLATFORM_VERBOSE=1

# Now all functions will output verbose information
platform=$(daq_platform_detect)
# [VERBOSE] Detected OS: ubuntu
# [VERBOSE] Detected version: 20.04
# ...
```

### Supported Platforms Configuration

Internal arrays defining supported platforms. These are private implementation details but listed here for reference:

```bash
# Ubuntu versions
__DAQ_PLATFORM_UBUNTU_VERSIONS=("20.04" "22.04" "24.04")

# Debian versions
__DAQ_PLATFORM_DEBIAN_VERSIONS=("8" "9" "10" "11" "12")

# macOS versions
__DAQ_PLATFORM_MACOS_VERSIONS=("13" "14" "15" "16" "17" "18" "26")

# Windows architectures
__DAQ_PLATFORM_WIN_ARCHS=("32" "64")

# Linux/macOS architectures
__DAQ_PLATFORM_LINUX_ARCHS=("arm64" "x86_64")
```

**Note:** These are private variables and should not be modified directly. To extend supported platforms, add versions to these arrays in the script source.

---

## Exit Codes

All functions use consistent exit codes:

| Exit Code | Meaning | Used By |
|-----------|---------|---------|
| `0` | Success / Valid / True | All functions |
| `1` | Error / Invalid / False | All functions |

**Usage:**
```bash
# Check exit code directly
if daq_platform_validate "$platform"; then
    # exit code 0 - valid
    echo "Valid"
else
    # exit code 1 - invalid
    echo "Invalid"
fi

# Capture and check
platform=$(daq_platform_detect)
exit_code=$?

if [ $exit_code -eq 0 ]; then
    echo "Detection succeeded: $platform"
else
    echo "Detection failed"
fi
```

---

## Platform Format Specification

### Linux/macOS Format

```
{os}{version}-{arch}
```

**Components:**
- `{os}` - Operating system name (ubuntu, debian, macos)
- `{version}` - OS version number
  - Ubuntu: Major.Minor (20.04, 22.04, 24.04)
  - Debian: Major (8, 9, 10, 11, 12)
  - macOS: Major (13, 14, 15, 16, 17, 18, 26)
- `{arch}` - Architecture (arm64, x86_64)

**Examples:**
- `ubuntu20.04-arm64`
- `debian11-x86_64`
- `macos14-arm64`

### Windows Format

```
win{arch}
```

**Components:**
- `win` - Literal string "win"
- `{arch}` - Architecture bits (32, 64)

**Examples:**
- `win64`
- `win32`

**Note:** Windows platforms do not include version information in the alias.

---

## Type Checking

Type checking allows platform categorization without parsing:

### Type Hierarchy

```
All Platforms
├── Unix (--is-unix)
│   ├── Linux (--is-linux)
│   │   ├── Ubuntu (--is-ubuntu)
│   │   └── Debian (--is-debian)
│   └── macOS (--is-macos)
└── Windows (--is-win)
```

### Type Check Examples

```bash
platform="ubuntu20.04-arm64"

# Hierarchical checks
daq_platform_validate "$platform" --is-unix     # true (Ubuntu is Unix)
daq_platform_validate "$platform" --is-linux    # true (Ubuntu is Linux)
daq_platform_validate "$platform" --is-ubuntu   # true (exact match)
daq_platform_validate "$platform" --is-debian   # false
daq_platform_validate "$platform" --is-macos    # false
daq_platform_validate "$platform" --is-win      # false

platform="macos14-arm64"
daq_platform_validate "$platform" --is-unix     # true (macOS is Unix)
daq_platform_validate "$platform" --is-linux    # false

platform="win64"
daq_platform_validate "$platform" --is-unix     # false
daq_platform_validate "$platform" --is-win      # true
```

---

## Best Practices

### 1. Always Validate Input

```bash
# ✅ GOOD - validate before use
process_platform() {
    local platform="$1"
    
    if ! daq_platform_validate "$platform"; then
        echo "Error: Invalid platform: $platform" >&2
        return 1
    fi
    
    # Use platform
}

# ❌ BAD - assume input is valid
process_platform() {
    local platform="$1"
    # Parse without validation - might fail silently
    read -r os arch <<< "$(daq_platform_parse "$platform")"
}
```

### 2. Handle Detection Failures

```bash
# ✅ GOOD - handle detection failure
if ! platform=$(daq_platform_detect); then
    echo "Error: Could not detect platform" >&2
    exit 1
fi

# ❌ BAD - assume detection succeeds
platform=$(daq_platform_detect)
# If detection fails, platform is empty
```

### 3. Use Type Checks for Logic

```bash
# ✅ GOOD - use type checks
if daq_platform_validate "$platform" --is-linux; then
    setup_linux_environment
elif daq_platform_validate "$platform" --is-macos; then
    setup_macos_environment
fi

# ❌ BAD - parse and string compare
os_name=$(daq_platform_parse "$platform" --os-name)
if [ "$os_name" = "ubuntu" ] || [ "$os_name" = "debian" ]; then
    setup_linux_environment
fi
```

### 4. Parse Once, Use Multiple Times

```bash
# ✅ GOOD - parse once
read -r os_name os_version os_arch <<< "$(daq_platform_parse "$platform")"
echo "OS: $os_name"
echo "Version: $os_version"
echo "Arch: $os_arch"

# ❌ BAD - parse multiple times
os_name=$(daq_platform_parse "$platform" --os-name)
os_version=$(daq_platform_parse "$platform" --os-version)
os_arch=$(daq_platform_parse "$platform" --os-arch)
```

### 5. Handle Windows Version Absence

```bash
# ✅ GOOD - check OS before using version
read -r os_name os_version os_arch <<< "$(daq_platform_parse "$platform")"

if [ -n "$os_version" ]; then
    echo "Version: $os_version"
else
    echo "Version: N/A (Windows)"
fi

# ❌ BAD - assume version exists
os_version=$(daq_platform_parse "$platform" --os-version)
echo "Version: $os_version"  # Empty for Windows!
```

### 6. Use Composition for Platform Variants

```bash
# ✅ GOOD - compose variants from parsed platform
base_platform=$(daq_platform_detect)
read -r os_name os_version _ <<< "$(daq_platform_parse "$base_platform")"

# Build for both architectures
for arch in arm64 x86_64; do
    target=$(daq_platform_compose \
        --os-name "$os_name" \
        --os-version "$os_version" \
        --os-arch "$arch")
    build_for_platform "$target"
done
```

---

## Error Handling

### Error Message Control

```bash
# Default - errors to stderr
daq_platform_validate "invalid"
# Error: Invalid platform alias: invalid

# Quiet mode - no error messages
__DAQ_PLATFORM_QUIET=1
daq_platform_validate "invalid"
# (no output, only exit code)

# Verbose mode - additional details
__DAQ_PLATFORM_VERBOSE=1
daq_platform_detect
# [VERBOSE] Detected OS: ubuntu
# [VERBOSE] Detected version: 20.04
# [VERBOSE] Detected architecture: arm64
# [VERBOSE] Composed platform: ubuntu20.04-arm64
# [VERBOSE] Platform is supported: ubuntu20.04-arm64
# ubuntu20.04-arm64
```

### Common Error Patterns

```bash
# Validation error
if ! daq_platform_validate "$user_platform"; then
    echo "Error: '$user_platform' is not a valid platform" >&2
    echo "Run with --list-platforms to see supported platforms" >&2
    exit 1
fi

# Detection error with fallback
if ! platform=$(daq_platform_detect 2>/dev/null); then
    echo "Warning: Could not detect platform, using default" >&2
    platform="ubuntu20.04-x86_64"
fi

# Composition error
if ! platform=$(daq_platform_compose \
    --os-name "$os" \
    --os-version "$version" \
    --os-arch "$arch" 2>&1); then
    echo "Error: Failed to compose platform" >&2
    echo "  OS: $os" >&2
    echo "  Version: $version" >&2
    echo "  Arch: $arch" >&2
    exit 1
fi

# Parse error with helpful message
if ! components=$(daq_platform_parse "$platform" 2>&1); then
    echo "Error: Failed to parse platform: $platform" >&2
    echo "Use 'daq_platform_validate' to check if platform is valid" >&2
    exit 1
fi
```

### Defensive Programming

```bash
#!/usr/bin/env bash
set -euo pipefail  # Exit on error, undefined var, pipe failure

source platform-format.sh

# Detect with error handling
platform=$(daq_platform_detect) || {
    echo "Fatal: Cannot detect platform" >&2
    exit 1
}

# Validate user input
user_platform="${1:-}"
if [ -z "$user_platform" ]; then
    echo "Usage: $0 <platform>" >&2
    exit 1
fi

if ! daq_platform_validate "$user_platform"; then
    echo "Error: Invalid platform: $user_platform" >&2
    exit 1
fi

# Safe parsing
read -r os_name os_version os_arch <<< "$(daq_platform_parse "$user_platform")" || {
    echo "Fatal: Failed to parse platform" >&2
    exit 1
}

echo "Processing platform: $user_platform"
echo "  OS: $os_name $os_version"
echo "  Architecture: $os_arch"
```

---

## See Also

- [README.md](./README.md) - Quick start and CLI usage
- [CONVENTIONS.md](./../CONVENTIONS.md) - Common naming conventions for OpenDAQ bash scripts.
