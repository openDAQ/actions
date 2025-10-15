# Bash Script Naming Conventions

Common naming conventions for OpenDAQ bash scripts.

## Overview

All OpenDAQ bash scripts follow consistent naming conventions to:
- Prevent namespace pollution
- Clearly distinguish public API from private implementation
- Enable safe sourcing of multiple scripts
- Provide stability guarantees for public interfaces

## Function Naming

### Public API Functions

**Pattern**: `daq_<module>_<action>`

**Examples**:
```bash
daq_version_compose      # version-format.sh
daq_version_parse
daq_platform_detect      # platform-format.sh
daq_platform_normalize
daq_package_compose      # packaging-format.sh
```

**Rules**:
- Must start with `daq_`
- Module name in singular form
- Action verb describing what function does
- Use underscore separators (snake_case)
- All lowercase

**Guarantees**:
- ✅ Stable API - will not change without major version bump
- ✅ Documented in module's API.md
- ✅ Safe to use in production scripts
- ✅ Backward compatibility maintained

### Private Functions

**Pattern**: `__daq_<module>_<name>`

**Examples**:
```bash
__daq_version_match         # Internal matching logic
__daq_version_validate_hash # Hash validation
__daq_platform_detect_os    # OS detection helper
```

**Rules**:
- Must start with `__daq_` (double underscore)
- Module name in singular form
- Descriptive name
- Use underscore separators
- All lowercase

**Guarantees**:
- ⚠️  **No stability guarantees** - may change between minor versions
- ⚠️  **Internal use only** - not documented in API
- ⚠️  **Subject to refactoring** - implementation details
- ❌ **Do not use directly** - use public API instead

### Utility Functions

**Pattern**: `__daq_<module>_<utility>`

**Examples**:
```bash
__daq_version_log        # Logging helper
__daq_version_error      # Error message helper
__daq_version_usage      # Usage display
```

**Rules**:
- Same as private functions
- Typically for logging, errors, help text
- May be shared across functions in same module

## Variable Naming

### Public Constants

**Pattern**: `OPENDAQ_<MODULE>_<NAME>`

**Examples**:
```bash
OPENDAQ_VERSION_FORMATS     # Array of supported formats
OPENDAQ_PLATFORM_SUPPORTED  # Supported platforms
```

**Rules**:
- Must start with `OPENDAQ_`
- Module name in uppercase
- Descriptive name in uppercase
- Use underscore separators (UPPER_SNAKE_CASE)
- Declared as `readonly` when possible

**Guarantees**:
- ✅ Stable - values and format will not change
- ✅ Documented
- ✅ Safe to reference in scripts

### Private Variables

**Pattern**: `__DAQ_<MODULE>_<NAME>`

**Examples**:
```bash
__DAQ_VERSION_VERBOSE       # Verbose flag
__DAQ_VERSION_REGEX         # Internal regex pattern
__DAQ_VERSION_SOURCED       # Source detection flag
```

**Rules**:
- Must start with `__DAQ_` (double underscore)
- Module name in uppercase
- Descriptive name in uppercase
- Use underscore separators

**Guarantees**:
- ⚠️  **Internal use only**
- ⚠️  **May change without notice**
- ❌ **Do not reference directly**

### Match Result Variables

**Pattern**: `__MATCH_<COMPONENT>`

**Examples**:
```bash
__MATCH_PREFIX      # Matched prefix (v or empty)
__MATCH_MAJOR       # Matched major version
__MATCH_MINOR       # Matched minor version
__MATCH_PATCH       # Matched patch version
__MATCH_SUFFIX      # Matched suffix (rc or empty)
__MATCH_HASH        # Matched git hash
```

**Rules**:
- Used for storing regex match results
- Always start with `__MATCH_`
- Component name in uppercase
- Cleared at start of matching function

**Usage**:
```bash
__daq_version_match "$version"
# Now __MATCH_MAJOR, __MATCH_MINOR, etc. are populated
echo "$__MATCH_MAJOR"
```

### Configuration Arrays

For module configuration (supported versions, formats, etc.):

**If configuration is part of public API:**
```bash
readonly OPENDAQ_<MODULE>_<CONFIG>=("value1" "value2")
```

**If configuration is internal:**
```bash
readonly __DAQ_<MODULE>_<CONFIG>=("value1" "value2")
```

**Best practices:**
- Always use `readonly` for configuration that shouldn't change at runtime
- Use public prefix (`OPENDAQ_`) if users may need to read these values
- Use private prefix (`__DAQ_`) if values are purely internal
- Document which values are supported in README.md

**Examples from platform-format.sh:**

```bash
# Private configuration (internal use only)
readonly __DAQ_PLATFORM_UBUNTU_VERSIONS=("20.04" "22.04" "24.04")
readonly __DAQ_PLATFORM_DEBIAN_VERSIONS=("8" "9" "10" "11" "12")
readonly __DAQ_PLATFORM_LINUX_ARCHS=("arm64" "x86_64")

# Alternative: Public configuration (if users need to read)
readonly OPENDAQ_PLATFORM_UBUNTU_VERSIONS=("20.04" "22.04" "24.04")
```

**Note:** In platform-format.sh, these arrays use private prefix (`__DAQ_`) but could be made public (`OPENDAQ_`) if there's a use case for external code to read supported versions.

## Module Naming

### Script Files

**Pattern**: `<module>-<purpose>.sh`

**Examples**:
```bash
version-format.sh       # Version formatting utilities
platform-format.sh      # Platform detection and formatting
packaging-format.sh     # Package naming utilities
api-github-gh.sh       # GitHub API utilities
```

**Rules**:
- Module name describes domain
- Purpose describes what module does
- Use dash separators (kebab-case)
- Always `.sh` extension
- All lowercase

### Module Prefixes

Each script module uses consistent prefix:

| Script | Prefix | Example Function |
|--------|--------|------------------|
| `version-format.sh` | `daq_version_` | `daq_version_compose` |
| `platform-format.sh` | `daq_platform_` | `daq_platform_detect` |
| `packaging-format.sh` | `daq_package_` | `daq_package_compose` |
| `api-github-gh.sh` | `daq_gh_` | `daq_gh_release_list` |

## Namespace Protection

### Why Prefixes Matter

Without prefixes:
```bash
# ❌ BAD - namespace pollution
compose() { ... }       # Conflicts with system/other scripts
parse() { ... }         # Too generic
validate() { ... }      # Common name
```

With prefixes:
```bash
# ✅ GOOD - protected namespace
daq_version_compose() { ... }   # Unique, clear origin
daq_version_parse() { ... }     # No conflicts
daq_version_validate() { ... }  # Module name in function
```

### Sourcing Multiple Modules

Prefixes enable safe multi-module sourcing:

```bash
# All can be sourced together safely
source version-format.sh
source platform-format.sh
source packaging-format.sh

# No naming conflicts
daq_version_compose --major 1 --minor 2 --patch 3
daq_platform_detect
daq_package_compose --version "$version" --platform "$platform"
```

## Examples

### Complete Module Example

```bash
#!/usr/bin/env bash
# example-module.sh - Example module following conventions

# Public constant
readonly OPENDAQ_EXAMPLE_FORMATS=("format1" "format2")

# Private variables
__DAQ_EXAMPLE_VERBOSE=0
__MATCH_VALUE=""

# Private utility function
__daq_example_log() {
    [ "$__DAQ_EXAMPLE_VERBOSE" -eq 1 ] && echo "[example] $*" >&2
}

# Private implementation function
__daq_example_internal_logic() {
    local input="$1"
    # Implementation details
    __MATCH_VALUE="$input"
}

# Public API function
daq_example_process() {
    local input="$1"
    
    __daq_example_log "Processing: $input"
    __daq_example_internal_logic "$input"
    
    echo "$__MATCH_VALUE"
}

# Public API function
daq_example_validate() {
    local value="$1"
    
    for format in "${OPENDAQ_EXAMPLE_FORMATS[@]}"; do
        if [ "$value" = "$format" ]; then
            return 0
        fi
    done
    
    return 1
}
```

### Using the Module

```bash
#!/usr/bin/env bash
# my-script.sh - Using example module

source example-module.sh

# Use public API
result=$(daq_example_process "input")

if daq_example_validate "$result"; then
    echo "Valid: $result"
fi

# ❌ DON'T use private functions/variables
# __daq_example_internal_logic "data"  # BAD
# __DAQ_EXAMPLE_VERBOSE=1              # BAD

# ✅ DO use public API only
daq_example_process "data"              # GOOD
```

## Migration Guide

### From Generic Names

If you have existing scripts with generic names:

**Before**:
```bash
compose_version() { ... }
parse_version() { ... }
FORMATS=("X.Y.Z")
```

**After**:
```bash
daq_version_compose() { ... }
daq_version_parse() { ... }
readonly OPENDAQ_VERSION_FORMATS=("X.Y.Z")
```

### Creating New Module

1. Choose module name: `<module>.sh`
2. Define prefix: `daq_<module>_`
3. Create constants: `OPENDAQ_<MODULE>_*`
4. Create public functions: `daq_<module>_<action>`
5. Create private functions: `__daq_<module>_<name>`
6. Document public API in `docs/scripts/shell/bash/<module>/API.md`

## Verification Checklist

Use this checklist when creating or reviewing scripts:

- [ ] All public functions start with `daq_<module>_`
- [ ] All private functions start with `__daq_<module>_`
- [ ] All public constants start with `OPENDAQ_<MODULE>_`
- [ ] All private variables start with `__DAQ_<MODULE>_`
- [ ] Match variables start with `__MATCH_`
- [ ] No generic function names (parse, compose, etc.)
- [ ] Public API documented in API.md
- [ ] Private functions not documented in public API
- [ ] Module can be sourced with other modules
- [ ] No naming conflicts possible

## Benefits

Following these conventions provides:

1. **Clear ownership**: Function name indicates which module it belongs to
2. **Stability**: Public API protected from accidental changes
3. **Safety**: Multiple modules can be sourced together
4. **Maintainability**: Easy to distinguish public from private
5. **Documentation**: Clear what's stable and what's not
6. **Debugging**: Function names show call chain clearly

## See Also

- [version-format.sh](version-format/README.md) - Example implementation
- [platform-format.sh](platform-format/README.md) - Example implementation
