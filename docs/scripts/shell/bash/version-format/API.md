# API Reference

Complete API documentation for `version-format.sh` functions.

## Table of Contents

- [Public API Functions](#public-api-functions)
  - [daq_version_compose](#daq_version_compose)
  - [daq_version_parse](#daq_version_parse)
  - [daq_version_validate](#daq_version_validate)
  - [daq_version_extract](#daq_version_extract)
- [Public Constants](#public-constants)
- [Exit Codes](#exit-codes)
- [Usage Modes](#usage-modes)

---

## Public API Functions

### daq_version_compose

Build a version string from components.

#### Syntax

```bash
daq_version_compose --major X --minor YY --patch Z [OPTIONS]
```

#### Parameters

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `--major X` | Yes | Major version number | `--major 1` |
| `--minor YY` | Yes | Minor version number | `--minor 2` |
| `--patch Z` | Yes | Patch version number | `--patch 3` |
| `--suffix SUFFIX` | No | Release candidate suffix (only `rc`) | `--suffix rc` |
| `--hash HASH` | No | Git hash (7-40 hex chars, lowercase) | `--hash a1b2c3d` |
| `--exclude-prefix` | No | Omit 'v' prefix | `--exclude-prefix` |
| `--format FORMAT` | No | Use specific format | `--format vX.YY.Z-rc` |

#### Returns

- **stdout**: Composed version string
- **exit code**: 0 on success, 1 on error

#### Constraints

- `--suffix` and `--hash` are **mutually exclusive**
- Only `rc` is allowed as suffix value
- Hash must be 7-40 lowercase hexadecimal characters
- If `--format` is specified, parameters are adjusted to match format

#### Examples

```bash
# Basic release (default includes 'v' prefix)
version=$(daq_version_compose --major 1 --minor 2 --patch 3)
echo "$version"  # v1.2.3

# Release without prefix
version=$(daq_version_compose --major 1 --minor 2 --patch 3 --exclude-prefix)
echo "$version"  # 1.2.3

# Release candidate
version=$(daq_version_compose --major 1 --minor 2 --patch 3 --suffix rc)
echo "$version"  # v1.2.3-rc

# Development version with hash
version=$(daq_version_compose --major 1 --minor 2 --patch 3 --hash a1b2c3d)
echo "$version"  # v1.2.3-a1b2c3d

# Using format (auto-adjusts parameters)
version=$(daq_version_compose --major 1 --minor 2 --patch 3 --format "X.YY.Z-rc")
echo "$version"  # 1.2.3-rc (no prefix, rc suffix added)
```

#### Error Cases

```bash
# Missing required parameter
daq_version_compose --major 1 --minor 2
# ERROR: Missing required arguments: --major, --minor, --patch

# Invalid suffix
daq_version_compose --major 1 --minor 2 --patch 3 --suffix beta
# ERROR: Invalid suffix: 'beta' (only 'rc' is allowed)

# Mutually exclusive options
daq_version_compose --major 1 --minor 2 --patch 3 --suffix rc --hash a1b2c3d
# ERROR: Cannot use both --suffix and --hash (mutually exclusive)

# Invalid hash format
daq_version_compose --major 1 --minor 2 --patch 3 --hash abc
# ERROR: Invalid hash format: 'abc' (must be 7-40 hex characters)

# Hash too long
daq_version_compose --major 1 --minor 2 --patch 3 --hash a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c
# ERROR: Invalid hash format: '...' (too long, max 40 chars)
```

---

### daq_version_parse

Parse version string and extract components.

#### Syntax

```bash
daq_version_parse VERSION [COMPONENT]
```

#### Parameters

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `VERSION` | Yes | Version string to parse | `v1.2.3-rc` |
| `--major` | No | Return only major version | `--major` |
| `--minor` | No | Return only minor version | `--minor` |
| `--patch` | No | Return only patch version | `--patch` |
| `--suffix` | No | Return only suffix (rc or empty) | `--suffix` |
| `--hash` | No | Return only hash | `--hash` |
| `--prefix` | No | Return only prefix (v or empty) | `--prefix` |

#### Returns

- **stdout**: 
  - If component specified: component value
  - If no component: space-separated list "MAJOR MINOR PATCH SUFFIX HASH PREFIX"
- **exit code**: 0 on success, 1 on error

#### Examples

```bash
# Parse release version
daq_version_parse v1.2.3 --major    # Output: 1
daq_version_parse v1.2.3 --minor    # Output: 2
daq_version_parse v1.2.3 --patch    # Output: 3
daq_version_parse v1.2.3 --prefix   # Output: v

# Parse RC version
daq_version_parse v1.2.3-rc --suffix  # Output: rc

# Parse development version
daq_version_parse v1.2.3-a1b2c3d --hash  # Output: a1b2c3d

# Parse all components
result=$(daq_version_parse v1.2.3-rc)
echo "$result"  # 1 2 3 rc  v
# Format: major minor patch suffix hash prefix

# Use in variables
version="v1.2.3-rc"
major=$(daq_version_parse "$version" --major)
minor=$(daq_version_parse "$version" --minor)
patch=$(daq_version_parse "$version" --patch)
suffix=$(daq_version_parse "$version" --suffix)

echo "Version: $major.$minor.$patch"  # Version: 1.2.3
[ "$suffix" = "rc" ] && echo "This is an RC"
```

#### Error Cases

```bash
# Invalid version format
daq_version_parse 1.2
# ERROR: Invalid version format: 1.2

# Invalid component
daq_version_parse v1.2.3 --invalid
# ERROR: Unknown component: --invalid
```

---

### daq_version_validate

Validate version string format and check specific properties.

#### Syntax

```bash
daq_version_validate VERSION [OPTIONS]
```

#### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `VERSION` | Yes | Version string to validate |
| `--format FORMAT` | No | Check against specific format |
| `--is-release` | No | Check if release format (no suffix/hash) |
| `--is-rc` | No | Check if RC format (contains -rc) |
| `--is-dev` | No | Check if dev format (contains hash) |

#### Returns

- **stdout**: None (silent on success)
- **exit code**: 0 if valid/matches, 1 if invalid/doesn't match

#### Examples

```bash
# Basic validation
if daq_version_validate v1.2.3; then
    echo "Valid version"
fi

# Check specific format
if daq_version_validate v1.2.3-rc --format "vX.YY.Z-rc"; then
    echo "Matches vX.YY.Z-rc format"
fi

# Check version type
if daq_version_validate v1.2.3 --is-release; then
    echo "This is a release version"
fi

if daq_version_validate v1.2.3-rc --is-rc; then
    echo "This is an RC version"
fi

if daq_version_validate v1.2.3-a1b2c3d --is-dev; then
    echo "This is a development version"
fi

# Use in conditionals
version="v1.2.3-rc"

if daq_version_validate "$version" --is-rc; then
    echo "Building RC package..."
elif daq_version_validate "$version" --is-release; then
    echo "Building release package..."
elif daq_version_validate "$version" --is-dev; then
    echo "Building development package..."
fi
```

#### Validation Rules

| Type | Rule |
|------|------|
| Release | No suffix, no hash (e.g., `v1.2.3` or `1.2.3`) |
| RC | Suffix is `rc`, no hash (e.g., `v1.2.3-rc`) |
| Dev | Has hash, no suffix (e.g., `v1.2.3-a1b2c3d`) |

#### Error Cases

```bash
# Invalid format
daq_version_validate v1.2.3 --format "invalid"
# ERROR: Invalid format name: invalid

# Version doesn't match format
daq_version_validate v1.2.3 --format "X.YY.Z"
# Exit code: 1 (has prefix, doesn't match format without prefix)

# Not an RC
daq_version_validate v1.2.3 --is-rc
# Exit code: 1
```

---

### daq_version_extract

Extract version string from text (filenames, tags, etc.).

#### Syntax

```bash
daq_version_extract TEXT
```

#### Parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `TEXT` | Yes | Text to search for version |

#### Returns

- **stdout**: Extracted version string (first match)
- **exit code**: 0 if found, 1 if not found

#### Search Patterns

Searches in order of specificity:
1. Development versions: `v?X.YY.Z-HASH` (7-40 hex chars)
2. RC versions: `v?X.YY.Z-rc`
3. Release versions: `v?X.YY.Z`

#### Examples

```bash
# Extract from filename
version=$(daq_version_extract "opendaq-v1.2.3-linux.tar.gz")
echo "$version"  # v1.2.3

# Extract from git tag
version=$(daq_version_extract "refs/tags/v1.2.3-rc")
echo "$version"  # v1.2.3-rc

# Extract from artifact name
version=$(daq_version_extract "build-v1.2.3-a1b2c3d-artifact")
echo "$version"  # v1.2.3-a1b2c3d

# Use in scripts
filename="opendaq-v1.2.3-rc-windows.msi"
if version=$(daq_version_extract "$filename"); then
    echo "Found version: $version"
    
    # Parse extracted version
    major=$(daq_version_parse "$version" --major)
    echo "Major version: $major"
fi

# CI/CD usage
git_tag="${GITHUB_REF#refs/tags/}"
version=$(daq_version_extract "$git_tag")
```

#### Error Cases

```bash
# No version found
daq_version_extract "random-text-without-version"
# Exit code: 1 (no output)

# Hash too short (invalid)
daq_version_extract "file-v1.2.3-abc.tar.gz"
# Exit code: 1 (hash must be 7+ chars)
```

---

## Public Constants

### OPENDAQ_VERSION_FORMATS

Array of supported version formats.

```bash
# Access in scripts
source version-format.sh

for format in "${OPENDAQ_VERSION_FORMATS[@]}"; do
    echo "$format"
done

# Output:
# X.YY.Z
# vX.YY.Z
# X.YY.Z-rc
# vX.YY.Z-rc
# X.YY.Z-HASH
# vX.YY.Z-HASH
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error (invalid input, validation failed, not found) |

---

## Usage Modes

### CLI Mode

Direct execution as command-line tool:

```bash
./version-format.sh compose --major 1 --minor 2 --patch 3
```

### Library Mode

Source and use API functions:

```bash
source version-format.sh

version=$(daq_version_compose --major 1 --minor 2 --patch 3)
```

### Verbose Mode

Enable detailed logging (both modes):

```bash
# CLI
./version-format.sh --verbose compose --major 1 --minor 2 --patch 3

# Library (set before sourcing)
export __DAQ_VERSION_VERBOSE=1
source version-format.sh
```

---

## Best Practices

### 1. Always Quote Variables

```bash
# Good
version=$(daq_version_compose --major 1 --minor 2 --patch 3)
if daq_version_validate "$version"; then
    echo "Valid: $version"
fi

# Bad
version=$(daq_version_compose --major 1 --minor 2 --patch 3)
if daq_version_validate $version; then  # Can fail if version is empty
    echo "Valid: $version"
fi
```

### 2. Check Exit Codes

```bash
# Good
if version=$(daq_version_extract "$filename"); then
    echo "Found: $version"
else
    echo "No version found in: $filename"
fi

# Also good
version=$(daq_version_extract "$filename") || {
    echo "Error: Could not extract version"
    exit 1
}
```

### 3. Use Specific Validators

```bash
# Good - explicit type check
if daq_version_validate "$version" --is-release; then
    deploy_to_production
fi

# Less clear
if daq_version_validate "$version"; then
    # What type is it?
fi
```

### 4. Parse Once, Use Multiple Times

```bash
# Good
major=$(daq_version_parse "$version" --major)
minor=$(daq_version_parse "$version" --minor)
patch=$(daq_version_parse "$version" --patch)

# Less efficient (but still works)
if [ "$(daq_version_parse "$version" --major)" -ge 2 ]; then
    if [ "$(daq_version_parse "$version" --minor)" -ge 5 ]; then
        # ...
    fi
fi
```

## See Also

- [README.md](./README.md) - Version format utility description
- [CONVENTIONS.md](../CONVENTIONS.md) - Common naming conventions for OpenDAQ bash scripts.
