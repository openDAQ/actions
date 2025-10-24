# Compose OpenDAQ Package Filename

Composes OpenDAQ installation package filename from version, platform, and packaging format.

## Usage

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-compose-filename@main
  with:
    # OpenDAQ version (if not set, resolves to latest from openDAQ/openDAQ)
    # Optional
    version: ''

    # Target platform (if not set, auto-detected)
    # Optional
    platform: ''

    # Packaging format for cpack (if not set, uses runner OS name)
    # Optional
    packaging: ''
```

## Outputs

```yaml
outputs:
  filename:          # Composed package filename
  version:           # Resolved version (full)
  version-major:     # Version major component
  version-minor:     # Version minor component
  version-patch:     # Version patch component
  version-suffix:    # Version suffix (rc or empty)
  version-hash:      # Version hash (or empty)
  platform:          # Resolved platform (full)
  platform-os-name:  # Platform OS name
  platform-os-version: # Platform OS version (empty for Windows)
  platform-os-arch:  # Platform OS architecture
  packaging:         # Resolved packaging format
```

## Format Specifications

### Version Format

Supports semantic versioning with optional prefix, suffix, and git hash:

| Format | Example | Type | Use Case |
|--------|---------|------|----------|
| `X.YY.Z` | `1.2.3` | Release | Production releases (no prefix) |
| `vX.YY.Z` | `v1.2.3` | Release | Production releases (with prefix) |
| `X.YY.Z-rc` | `1.2.3-rc` | RC | Release candidates |
| `vX.YY.Z-rc` | `v1.2.3-rc` | RC | Release candidates (with prefix) |
| `X.YY.Z-HASH` | `1.2.3-a1b2c3d` | Dev | Development builds |
| `vX.YY.Z-HASH` | `v1.2.3-a1b2c3d` | Dev | Development builds (with prefix) |

**Components**:
- **Major** (`X`): 0-999+
- **Minor** (`YY`): 0-999
- **Patch** (`Z`): 0-999+
- **Suffix**: `rc` (release candidate) or git hash (7-40 lowercase hex chars)
- **Prefix**: `v` (optional)

### Platform Format

Platform identifiers follow these patterns:

**Linux/macOS**: `{os}{version}-{arch}`
- **OS**: `ubuntu`, `debian`, `macos`
- **Version**: `20.04`, `22.04`, `24.04` (Ubuntu/Debian) or `13`, `14`, `15` (macOS)
- **Architecture**: `arm64`, `x86_64`
- Examples: `ubuntu22.04-x86_64`, `macos14-arm64`, `debian12-arm64`

**Windows**: `win{arch}`
- **Architecture**: `32`, `64` (bits, not x86/x64)
- Examples: `win64`, `win32`

**Supported Platforms**:
- Ubuntu: 20.04, 22.04, 24.04
- Debian: 8, 9, 10, 11, 12
- macOS: 13-18, 26 (Ventura to Sequoia + future)
- Windows: 32-bit, 64-bit

### Packaging Format

File extensions for installation packages:

| OS | Format | Extension | CPack Generator |
|----|--------|-----------|-----------------|
| **Windows** | Installer | `.exe` | `NSIS`, `NSIS64`, `WIX` |
| **Ubuntu/Debian** | Package | `.deb` | `DEB` |
| **macOS** | Archive | `.tar.gz` | `TGZ` |
| **macOS** | Archive | `.zip` | `ZIP` |

The action automatically detects the appropriate packaging format based on the runner OS or CPack generator.

## Examples

### Default (auto-detect everything)

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-compose-filename@main
  id: compose

# Result: opendaq-v3.30.0-ubuntu22.04-x86_64.deb
```

### Specify version

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-compose-filename@main
  id: compose
  with:
    version: 'v3.29.0-rc'

# Result: opendaq-v3.29.0-rc-ubuntu22.04-x86_64.deb
```

### Specify version without prefix

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-compose-filename@main
  id: compose
  with:
    version: '3.29.0-rc'

# Result: opendaq-3.29.0-rc-ubuntu22.04-x86_64.deb
```

### Specify platform

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-compose-filename@main
  id: compose
  with:
    platform: 'win64'

# Result: opendaq-v3.30.0-win64.exe
```

### Release candidate

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-compose-filename@main
  id: compose
  with:
    version: 'v3.29.0-rc'
    platform: 'macos14-arm64'

# Result: opendaq-v3.29.0-rc-macos14-arm64.tar.gz
```

### Development build with hash

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-compose-filename@main
  id: compose
  with:
    version: 'v3.30.0-a1b2c3d'
    platform: 'debian12-x86_64'

# Result: opendaq-v3.30.0-a1b2c3d-debian12-x86_64.deb
```

### Full specification

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-compose-filename@main
  id: compose
  with:
    version: 'v3.29.0-rc'
    platform: 'ubuntu22.04-x86_64'
    packaging: 'DEB'

# Result: opendaq-v3.29.0-rc-ubuntu22.04-x86_64.deb
```

### Using outputs

```yaml
- uses: openDAQ/openDAQ/.github/actions/framework-compose-filename@main
  id: compose

- name: Download package
  run: |
    echo "Filename: ${{ steps.compose.outputs.filename }}"
    echo "Version: ${{ steps.compose.outputs.version }}"
    echo "Platform: ${{ steps.compose.outputs.platform }}"
```

## See Also
- [README.md](./../README.md) - Actions overview
