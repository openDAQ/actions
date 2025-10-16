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

### API Size Guidelines

The number of public functions should match the module's complexity:

**Minimal API (2-3 functions)**:
- Used for simple, focused modules
- Typically single-purpose utilities
- Example: `packaging-format.sh` (2 detect functions)
- Pattern: One function per input type

**Standard API (4-7 functions)**:
- Used for moderate complexity modules
- Multiple operations on same data type
- Example: `version-format.sh` (compose, parse, validate, extract)
- Example: `platform-format.sh` (detect, parse, extract, compose, list, type checks)
- Pattern: CRUD-like operations + utilities

**Extended API (8+ functions)**:
- Used for complex, feature-rich modules
- Multiple data types or operations
- May include sub-modules or specialized functions
- Pattern: Core operations + convenience wrappers + utilities

**Principle**: Start minimal, expand only when needed. Don't add functions "just in case".

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
- Gerund forms (e.g., `packaging`, `testing`) are acceptable when more natural than base form
  - Use gerund when describing an ongoing process or activity
  - Example: `packaging-format.sh` (the activity of packaging)
  - Example: `testing-utils.sh` (utilities for testing)
  - Base form is still preferred for concrete nouns (e.g., `version`, `platform`)
- Use dash separators (kebab-case)
- Always `.sh` extension
- All lowercase
`
### Module Prefixes

Each script module uses consistent prefix:

| Script | Prefix | Example Function |
|--------|--------|------------------|
| `version-format.sh` | `daq_version_` | `daq_version_compose` |
| `platform-format.sh` | `daq_platform_` | `daq_platform_detect` |
| `packaging-format.sh` | `daq_packaging_` | `daq_packaging_detect_from_cpack` |
| `api-github-gh.sh` | `daq_api_gh_` | `daq_api_gh_version_latest` |

## Special Module Naming Cases

### API Wrapper Modules

Modules that wrap external APIs or services may use extended prefixes for clarity.

**Pattern**: `api-<service>-<tool>.sh` with prefix `daq_api_<service>_`

**When to use**:
- Module wraps external API or CLI tool
- Need to distinguish from domain modules
- Additional context improves API clarity

**Examples**:

```bash
# GitHub API wrapper
api-github-gh.sh          # Prefix: daq_api_gh_
  daq_api_gh_version_latest()
  daq_api_gh_assets_download()

# Hypothetical examples
api-gitlab-cli.sh         # Prefix: daq_api_gitlab_
api-docker-sdk.sh         # Prefix: daq_api_docker_
```

**Comparison with domain modules**:

| Type | File Pattern | Prefix Pattern | Use Case |
|------|--------------|----------------|----------|
| Domain module | `<domain>-format.sh` | `daq_<domain>_` | Data format parsing/composition |
| API wrapper | `api-<service>-<tool>.sh` | `daq_api_<service>_` | External service integration |

**Example distinction**:

```bash
# Domain module - formats and parsing
version-format.sh → daq_version_compose()    # Create version string
version-format.sh → daq_version_parse()      # Parse version string

# API wrapper - external service calls
api-github-gh.sh → daq_api_gh_version_latest()   # Fetch from GitHub API
api-github-gh.sh → daq_api_gh_assets_download()  # Download from GitHub
```

**Rationale**:
- Prefix `daq_api_gh_` clearly indicates GitHub API wrapper
- Distinguishes from potential `daq_github_` (format-related functions)
- Prevents confusion between API calls and format operations
- Allows both modules to coexist: `github-format.sh` (formats) and `api-github-gh.sh` (API)

**Namespace protection**:

```bash
# Safe to source together
source github-format.sh    # Hypothetical: daq_github_parse()
source api-github-gh.sh    # Actual: daq_api_gh_version_latest()

# No naming conflicts
daq_github_parse "v1.0.0"              # Format parsing
daq_api_gh_version_latest              # API call
```

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

## Module Design Principles

### Single Responsibility

Each module should have one clear purpose:

- `version-format.sh` - handles version strings
- `platform-format.sh` - handles platform identifiers
- `packaging-format.sh` - handles package extensions
- `utils.sh` - too generic, unclear purpose

### Focused API

Public API should be:
- **Minimal**: Only functions that external code needs
- **Consistent**: Similar naming and behavior across functions
- **Documented**: Every public function in API.md
- **Stable**: Changes require major version bump

### Composability

Modules should work well together:

```bash
# âœ… Good - modules compose naturally
source version-format.sh
source platform-format.sh
source packaging-format.sh

version=$(daq_version_compose --major 1 --minor 2 --patch 3)
platform=$(daq_platform_detect)
ext=$(daq_packaging_detect_from_os "ubuntu-latest")

package="opendaq-${version}-${platform}.${ext}"
```

### Independence

Modules should not depend on each other:
- Each module can be sourced independently
- No hard dependencies between modules
- Shared prefixes prevent naming conflicts
- Each module has its own namespace

### Evolution

Modules can grow, but should remain focused:

**Initial version** (minimal):
```bash
# packaging-format.sh v1.0
daq_packaging_detect_from_cpack()
daq_packaging_detect_from_os()
```

**Future version** (extended, if needed):
```bash
# packaging-format.sh v2.0
daq_packaging_detect_from_cpack()
daq_packaging_detect_from_os()
daq_packaging_list_generators()      # New: list supported generators
daq_packaging_validate_generator()   # New: validate generator name
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

- [ ] All public functions start with `daq_<module>_` or `daq_api_<service>_` (for API wrappers)
- [ ] All private functions start with `__daq_<module>_` or `__daq_api_<service>_` (for API wrappers)
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

- [version-format.sh](version-format/README.md) - Domain module example
- [platform-format.sh](platform-format/README.md) - Domain module example
- [packaging-format.sh](packaging-format/README.md) - Domain module example
- [api-github-gh.sh](api-github-gh/README.md) - API wrapper module example
- [README.md](./../../../../README.md) - Actions overview