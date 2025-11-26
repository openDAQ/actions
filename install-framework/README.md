# Install openDAQ Framework

[![Test Install Framework Action](https://github.com/openDAQ/actions/actions/workflows/test-install-framework.yml/badge.svg)](https://github.com/openDAQ/actions/actions/workflows/test-install-framework.yml)

Download and install openDAQ framework packages from GitHub releases.

## Usage

```yaml
- uses: openDAQ/actions/install-framework@main
  with:
    # Framework version to install.
    # Supports: 'latest', 'latest-stable', or specific versions like 'v3.30.0'
    # Default: latest-stable
    version: ''

    # Enable 32-bit version installation (Windows only, ignored on Linux).
    # Default: false
    enable-32bit: false
```

### Outputs

- `version` - Resolved framework version that was installed (e.g., `v3.30.0`)

## Examples

### Basic Usage

Install latest stable version with automatic platform detection:

```yaml
- uses: openDAQ/actions/install-framework@main
```

### Install Specific Version

```yaml
- uses: openDAQ/actions/install-framework@main
  with:
    version: v3.30.0
```

### Install Latest Pre-release

```yaml
- uses: openDAQ/actions/install-framework@main
  with:
    version: latest
```

### Install 32-bit on Windows

```yaml
- uses: openDAQ/actions/install-framework@main
  with:
    enable-32bit: true
```

## Scenarios

### Platform Detection

The action automatically detects the platform and selects the appropriate package:

**Linux Runners:**
- Detects architecture from `runner.arch` (X64 → `x86_64`, ARM64 → `arm64`)
- Searches for assets matching pattern: `opendaq-{version}-ubuntu*-{arch}.deb`
- Installs using `sudo dpkg -i`
- Example: `opendaq-3.30.0-ubuntu22.04-x86_64.deb`

**Windows Runners:**
- Uses `win64` by default, or `win32` when `enable-32bit: true`
- Searches for assets matching pattern: `opendaq-{version}-win{32|64}.exe`
- Installs silently and updates `PATH` (silent installer doesn't update PATH automatically)
- Adds to PATH: `C:\Program Files\openDAQ\bin` (or `Program Files (x86)` for 32-bit)
- Example: `opendaq-3.30.0-win64.exe`

### Version Resolution

**`latest`** - Fetches the most recent release (including pre-releases):
```bash
gh release list -R openDAQ/openDAQ --limit 1 --json tagName --jq '.[0].tagName'
```

**`latest-stable`** - Fetches the latest stable release (excludes pre-releases):
```bash
gh release view -R openDAQ/openDAQ --json tagName --jq '.tagName'
```

**Specific version** - Validates format: `^(v?)([0-9]+)\.([0-9]+)\.([0-9]+)(-(.+))?$`
- Examples: `v3.30.0`, `3.30.0`, `v3.29.0-rc`

### Installation Process

1. **Resolve Version** - Determines version from input (`latest`, `latest-stable`, or specific)
2. **Detect Platform** - Identifies OS and architecture, selects package format
3. **Find Asset** - Searches GitHub releases for matching package using pattern
4. **Download** - Retrieves installer, displays SHA256 checksum and file size
5. **Install** - Executes platform-specific installation

## License

This action is part of the openDAQ project. See [LICENSE](../LICENSE) for details.
