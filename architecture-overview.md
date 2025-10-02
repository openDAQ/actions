# Architecture Overview

## Directory Structure

```
actions/
├── .github/
│   └── workflows/           # CI/CD workflows for testing actions
├── scripts/
│   └── shell/
│       ├── bash/            # Bash implementation
│       │   ├── lib/         # Shared libraries (sourced modules)
│       │   ├── core/        # Low-level atomic operations
│       │   ├── package/     # Package filename operations
│       │   ├── storage/     # Storage backend integrations
│       │   ├── download/    # Download operations
│       │   ├── install/     # Installation operations
│       │   └── workflows/   # High-level orchestration scripts
│       └── pwsh/            # PowerShell implementation (future)
├── <action-name>/           # GitHub Action directories
│   ├── action.yml           # Action definition
│   └── README.md            # Action documentation
└── tests/
    └── shell/
        ├── lib/             # Test framework
        ├── suites/          # Test suites
        └── test-runner.sh   # Test executor
```

## Layer Responsibilities

### 1. `lib/` - Shared Libraries
**Purpose**: Reusable utilities used across all modules

- `common.sh` - Logging, error handling, temp file management
- `validation.sh` - Input validation functions
- `http.sh` - HTTP/API utilities (curl wrappers)

**Dependencies**: None (foundation layer)

### 2. `core/` - Atomic Operations
**Purpose**: Low-level parsing and composition of individual components

- `version-parse.sh` - Parse version strings (e.g., `3.14.2-rc-abc123f`)
- `version-compose.sh` - Compose version strings
- `platform-parse.sh` - Parse platform aliases (e.g., `ubuntu22.04-x86_64`)
- `platform-compose.sh` - Compose platform aliases
- `extension-parse.sh` - Parse file extensions
- `extension-compose.sh` - Compose extensions

**Dependencies**: `lib/*`

### 3. `package/` - Package Operations
**Purpose**: Work with complete package filenames

- `filename-parse.sh` - Parse `opendaq-{version}-{platform}.{ext}`
- `filename-compose.sh` - Compose package filenames
- `filename-validate.sh` - Validate package filename format

**Dependencies**: `lib/*`, `core/*`

### 4. `storage/` - Storage Backends
**Purpose**: Integrate with storage systems

- `github-releases.sh` - GitHub Releases API operations
- `github-artifacts.sh` - GitHub Artifacts API operations
- `s3-storage.sh` - AWS S3 operations
- `storage-check.sh` - Multi-source availability check

**Dependencies**: `lib/*`, `package/*`

### 5. `download/` - Download Operations
**Purpose**: Download packages from various sources

- `download-release.sh` - Download from GitHub Releases
- `download-artifact.sh` - Download from GitHub Artifacts
- `download-s3.sh` - Download from S3
- `download-auto.sh` - Auto-detect source and download

**Dependencies**: `lib/*`, `storage/*`

### 6. `install/` - Installation
**Purpose**: Install downloaded packages

- `install-deb.sh` - Install Debian packages
- `install-exe.sh` - Install Windows executables
- `install-tar.sh` - Install tar.gz archives
- `install-auto.sh` - Auto-detect format and install

**Dependencies**: `lib/*`

### 7. `workflows/` - High-Level Workflows
**Purpose**: Orchestrate complete operations

- `setup-opendaq.sh` - Complete setup: find → download → install
- `check-availability.sh` - Check package availability across sources
- `build-third-party.sh` - Setup environment for builds

**Dependencies**: All layers below

## Naming Conventions

### Functions

Inspired by C++ `namespace daq::` and CMake `OPENDAQ_*`:

```bash
# Public functions - short prefix (like C++ namespace)
daq_<module>_<function_name>()

# Private functions - double underscore
__daq_<module>_<function_name>()
```

**Examples:**
```bash
# lib/common.sh
daq_common_log_info()
daq_common_check_command()
__daq_common_log()              # private

# core/version-parse.sh
daq_version_parse()
daq_version_is_rc()
__daq_version_extract_major()   # private

# package/filename-parse.sh
daq_filename_parse()
daq_filename_compose()
__daq_filename_split()          # private
```

### Variables and Constants

```bash
# Public environment variables - full prefix (like CMake)
OPENDAQ_<VAR_NAME>

# Private global variables - short prefix
__DAQ_<VAR_NAME>

# Private constants
readonly __DAQ_<CONST_NAME>

# Public constants (if needed externally)
readonly OPENDAQ_<CONST_NAME>
```

**Examples:**
```bash
# Public configuration (user-settable)
OPENDAQ_DEBUG=false
OPENDAQ_VERBOSE=false
OPENDAQ_GITHUB_TOKEN=""
OPENDAQ_LOG_FILE=""

# Private state
__DAQ_TEMP_DIR=""
__DAQ_INIT_DONE=false

# Private constants
readonly __DAQ_VERSION_REGEX='^v?[0-9]+\.[0-9]+\.[0-9]+'
readonly __DAQ_COLOR_RED='\033[0;31m'

# Public constants
readonly OPENDAQ_SUPPORTED_PLATFORMS="ubuntu20.04 ubuntu22.04 macos14"
readonly OPENDAQ_DEFAULT_PLATFORM="ubuntu22.04-x86_64"
```

### Files

```bash
# Script files - kebab-case.sh
version-parse.sh
platform-compose.sh
download-auto.sh

# Action directories - kebab-case
opendaq-version-parse/
opendaq-setup/

# Test files - test-<module>.sh
test-opendaq-version-parse.sh
test-platform-compose.sh
```

## Namespace Reference Table

| Module | Prefix | Examples |
|--------|--------|----------|
| `lib/common.sh` | `daq_common_` | `daq_common_log_info()` |
| `lib/validation.sh` | `daq_validation_` | `daq_validation_version()` |
| `lib/http.sh` | `daq_http_` | `daq_http_get()` |
| `core/version-parse.sh` | `daq_version_` | `daq_version_parse()` |
| `core/platform-parse.sh` | `daq_platform_` | `daq_platform_parse()` |
| `package/filename-parse.sh` | `daq_filename_` | `daq_filename_parse()` |
| `storage/github-releases.sh` | `daq_gh_releases_` | `daq_gh_releases_check()` |
| `storage/s3-storage.sh` | `daq_s3_` | `daq_s3_check()` |
| `download/download-auto.sh` | `daq_download_` | `daq_download_auto()` |
| `install/install-auto.sh` | `daq_install_` | `daq_install_auto()` |
| `workflows/setup-opendaq.sh` | `daq_setup_` | `daq_setup_full()` |

## Module Structure Template

```bash
#!/bin/bash
################################################################################
# Module: <module-name>
# Namespace: daq_<module>
# Description: <brief description>
#
# Public API:
#   daq_<module>_<func1>() - <description>
#   daq_<module>_<func2>() - <description>
#
# Dependencies:
#   - lib/common.sh
#   - lib/validation.sh
################################################################################

# Source dependencies
source "$(dirname "${BASH_SOURCE[0]}")/../lib/common.sh"

# Public functions
daq_<module>_<function>() {
    local param="$1"
    
    daq_validation_not_empty "param" "$param" || return 1
    
    # Implementation
}

# Private functions
__daq_<module>_<helper>() {
    local param="$1"
    # Implementation
}

# Private constants
readonly __DAQ_<MODULE>_<CONSTANT>="value"
```

## Dependency Graph

```
lib/*           ← Foundation (no dependencies)
  ↑
core/*          ← Depends on lib/*
  ↑
package/*       ← Depends on lib/*, core/*
  ↑
storage/*       ← Depends on lib/*, package/*
  ↑
download/*      ← Depends on lib/*, storage/*
  ↑
install/*       ← Depends on lib/*
  ↑
workflows/*     ← Depends on all layers
```

**Rules:**
- Lower layers MUST NOT depend on higher layers
- Circular dependencies are prohibited
- Each layer uses only layers below it

## Design Principles

1. **Modularity** - Each script solves one specific problem
2. **Composition** - Complex operations built from simple components
3. **Separation of Concerns** - Clear layer boundaries
4. **Testability** - Every module independently testable
5. **Namespace Isolation** - Consistent prefixes prevent collisions
6. **Consistency** - Matches C++ (`namespace daq`) and CMake (`OPENDAQ_*`)

## Rationale

### Why `daq_` for functions?
- Matches C++ codebase: `namespace daq { ... }`
- Shorter and more convenient than `opendaq_`
- Sufficient uniqueness for the domain

### Why `OPENDAQ_` for environment variables?
- Matches CMake conventions: `OPENDAQ_ENABLE_TESTS`
- Full prefix for global namespace (reduces collision risk)
- Clear association with the project

### Why layered architecture?
- Clear separation of concerns
- Easy to test individual layers
- Prevents circular dependencies
- Scalable for new features

### Why double underscore for private functions?
- Visual distinction (public vs private)
- Convention borrowed from Python, C++
- Signals "internal use only" to developers
```
