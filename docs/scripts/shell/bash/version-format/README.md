# OpenDAQ Version Format Utilities

Bash script for composing, parsing, validating, and extracting semantic version strings.

## 📝 Supported Formats

The script supports semantic versioning with the following formats:

| Format | Example | Type | Use Case |
|--------|---------|------|----------|
| `X.YY.Z` | `1.2.3` | Release | Production releases (no prefix) |
| `vX.YY.Z` | `v1.2.3` | Release | Production releases (with prefix) |
| `X.YY.Z-rc` | `1.2.3-rc` | RC | Release candidates |
| `vX.YY.Z-rc` | `v1.2.3-rc` | RC | Release candidates |
| `X.YY.Z-HASH` | `1.2.3-a1b2c3d` | Dev | Development builds |
| `vX.YY.Z-HASH` | `v1.2.3-a1b2c3d` | Dev | Development builds |

**Components**:
- **Major** (`X`): 0-999
- **Minor** (`YY`): 0-999
- **Patch** (`Z`): 0-999
- **Suffix**: `rc` (release candidate) or git hash (7-40 chars)
- **Prefix**: `v` (optional)

## 🚀 Quick Start

All examples show CLI usage. For API usage in scripts, see [API.md](API.md).

### Composing Versions

```bash
# Release version (default includes 'v' prefix)
./version-format.sh compose --major 1 --minor 2 --patch 3
# Output: v1.2.3

# Release without prefix
./version-format.sh compose --major 1 --minor 2 --patch 3 --exclude-prefix
# Output: 1.2.3

# Release candidate
./version-format.sh compose --major 1 --minor 2 --patch 3 --suffix rc
# Output: v1.2.3-rc

# Development version with git hash
./version-format.sh compose --major 1 --minor 2 --patch 3 --hash a1b2c3d
# Output: v1.2.3-a1b2c3d

# Using specific format
./version-format.sh compose --major 1 --minor 2 --patch 3 --format "X.YY.Z-rc"
# Output: 1.2.3-rc
```

### Parsing Versions

```bash
# Extract single component
./version-format.sh parse v1.2.3-rc --major
# Output: 1

./version-format.sh parse v1.2.3-rc --minor
# Output: 2

./version-format.sh parse v1.2.3-rc --suffix
# Output: rc

# Parse all components (space-separated output)
./version-format.sh parse v1.2.3-rc
# Output: 1 2 3 rc  v
# Order: major minor patch suffix hash prefix
```

### Validating Versions

```bash
# Check if version is valid
./version-format.sh validate v1.2.3
echo $?  # 0 = valid, 1 = invalid

# Check version type
./version-format.sh validate v1.2.3 --is-release
echo $?  # 0 = is release

./version-format.sh validate v1.2.3-rc --is-rc
echo $?  # 0 = is RC

./version-format.sh validate v1.2.3-a1b2c3d --is-dev
echo $?  # 0 = is dev version

# Check against specific format
./version-format.sh validate v1.2.3-rc --format "vX.YY.Z-rc"
echo $?  # 0 = matches format
```

### Extracting Versions from Text

```bash
# From filename
./version-format.sh extract "opendaq-v1.2.3-linux-amd64.tar.gz"
# Output: v1.2.3

# From git tag
./version-format.sh extract "refs/tags/v1.2.3-rc"
# Output: v1.2.3-rc

# From multiple files (finds first match)
./version-format.sh extract "build-v1.2.3-a1b2c3d-artifact.zip"
# Output: v1.2.3-a1b2c3d
```

### Verbose Mode

Add `--verbose` flag for detailed logging:

```bash
./version-format.sh --verbose compose --major 1 --minor 2 --patch 3
# [version-format] Composing version: major=1 minor=2 patch=3
# [version-format] Composed version: v1.2.3
# v1.2.3
```

### Help

```bash
./version-format.sh --help
```

## 🔧 Requirements

- **Shell**: bash 3.2+ or zsh
- **OS**: Linux, macOS, Windows (Git Bash, WSL)
- **Dependencies**: None (pure bash)

**Tested on**:
- Ubuntu 20.04+ (bash 5.0+)
- macOS 12+ (bash 3.2, zsh 5.8)
- Windows 10/11 Git Bash (bash 5.0+)

## 🐛 Troubleshooting

### Invalid version format

```bash
./version-format.sh validate 1.2
echo $?  # Returns 1
```

**Solution**: Ensure version has all three components (major.minor.patch):
```bash
./version-format.sh validate 1.2.0  # Valid
```

### Hash too short

```bash
./version-format.sh compose --major 1 --minor 2 --patch 3 --hash abc
# Error: Hash must be 7-40 characters
```

**Solution**: Use at least 7 characters for git hash:
```bash
git rev-parse --short=7 HEAD  # Get 7-char hash
./version-format.sh compose --major 1 --minor 2 --patch 3 --hash a1b2c3d
```

### Version not found in text

```bash
./version-format.sh extract "random-file.txt"
echo $?  # Returns 1
```

**Solution**: Ensure text contains a valid version string. Use verbose mode to debug:
```bash
./version-format.sh --verbose extract "random-file.txt"
```

### Permission denied

```bash
./version-format.sh compose --major 1 --minor 2 --patch 3
# bash: ./version-format.sh: Permission denied
```

**Solution**: Make script executable:
```bash
chmod +x version-format.sh
```

### Invalid suffix

```bash
./version-format.sh compose --major 1 --minor 2 --patch 3 --suffix beta
# Error: Invalid suffix (only 'rc' allowed)
```

**Solution**: Only `rc` suffix is supported. For other suffixes, use hash:
```bash
./version-format.sh compose --major 1 --minor 2 --patch 3 --hash beta-01
```

---

## 📚 API Documentation

- [API.md](./API.md) - Complete function reference for script integration
- [CONVENTIONS.md](./../CONVENTIONS.md) - Common naming conventions for OpenDAQ bash scripts.
- [README.md](./../../../../../README.md) - Actions overview