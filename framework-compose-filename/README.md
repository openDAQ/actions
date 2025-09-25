[![Test compose framework filename action](https://github.com/openDAQ/actions/workflows/test-framework-compose-filename-shared.yml/badge.svg)](https://github.com/openDAQ/actions/workflows/test-framework-compose-filename-shared.yml)

# Framework Compose Filename

Resolves artifact filename from pattern, inputs, or autodetect for [openDAQ Framework](https://github.com/openDAQ) packages.

---

## 📥 Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `pattern` | File pattern with wildcards (e.g., `opendaq-*-*.*`) | No | `opendaq-*-*.*` |
| `version` | Version or git tag (e.g., `3.20.4`, `v3.30.0`, `latest`) | No | `latest` |
| `platform` | Platform alias (e.g., `ubuntu22.04-x86_64`) | No | *autodetected* |
| `packaging` | CPack generator (`DEB`/`NSIS`/`TARGZ`/`ZIP`) | No | *autodetected* |
| `token` | Personal access token for GitHub API | No | `${{ github.token }}` |

---

## 📤 Outputs

| Output | Description | Example |
|--------|-------------|---------|
| `filename` | Resolved artifact filename | `opendaq-3.20.4-ubuntu22.04-x86_64.deb` |
| `extension` | File extension | `deb` |
| `version` | Version with 'v' prefix | `v3.20.4` |
| `version-major` | Major version | `3` |
| `version-minor` | Minor version | `20` |
| `version-patch` | Patch version | `4` |
| `platform` | Platform alias | `ubuntu22.04-x86_64` |
| `packaging` | CPack generator | `DEB` |

---

## 🖥️ Supported Platforms

### Linux (Ubuntu)
- `ubuntu22.04-x86_64` / `ubuntu22.04-arm64`
- `ubuntu24.04-x86_64` / `ubuntu24.04-arm64`

### macOS  
- `macos13-x86_64` / `macos13-arm64`
- `macos14-x86_64` / `macos14-arm64`
- `macos15-x86_64` / `macos15-arm64`
- `macos16-x86_64` / `macos16-arm64`

### Windows
- `win32` / `win64`

---

## 📦 Packaging Formats

| Format | Extension | Generator | Platform |
|--------|-----------|-----------|----------|
| Debian Package | `.deb` | `DEB` | Ubuntu |
| Windows Installer | `.exe` | `NSIS` | Windows |
| Tar Archive | `.tar.gz` | `TARGZ` | macOS |
| Zip Archive | `.zip` | `ZIP` | Cross-platform |

---

## 🎯 Pattern Examples

### Wildcards
```yaml
# Auto-resolve everything  
pattern: "opendaq-*-*.*"

# Specific version, auto-resolve platform/extension
pattern: "opendaq-3.20.4-*.*"

# Specific platform, auto-resolve version/extension
pattern: "opendaq-*-ubuntu22.04-x86_64.*"
```

### Fully Specified
```yaml
pattern: "opendaq-3.20.4-ubuntu22.04-x86_64.deb"
pattern: "opendaq-v3.30.0-macos14-arm64.tar.gz"
pattern: "opendaq-2.1.0-win64.exe"
```

---

## 🔄 Version Resolution

1. **Pattern-specified** → Version from pattern (e.g., `opendaq-3.20.4-*.*`)
2. **Input-specified** → Version from `version` input
3. **Latest release** → Auto-fetch from GitHub (default)

Supported formats: `3.20.4`, `v3.20.4`, `latest`

---

## 🤖 Auto-Detection

When using wildcards (`*`), automatically detects:

- **Platform** → Based on `runner.os` and `runner.arch`
- **Packaging** → DEB (Ubuntu), NSIS (Windows), TARGZ (macOS)
- **Version** → Latest from openDAQ/openDAQ releases

---

## 🚀 Usage

### Auto-resolve Everything

```yaml
- name: Auto-resolve filename
  uses: openDAQ/actions/framework-compose-filename@v1
  id: filename
  # No parameters needed - uses default pattern "opendaq-*-*.*"
  # Auto-detects: latest version, platform, packaging

- name: Use resolved filename
  run: |
    echo "📦 Filename: ${{ steps.filename.outputs.filename }}"
    # Example output: opendaq-3.20.4-ubuntu22.04-x86_64.deb
```

### Resolve Latest Version

```yaml
- name: Get latest version
  uses: openDAQ/actions/framework-compose-filename@v1
  id: filename
  with:
    version: "latest"

- name: Use latest version
  run: |
    echo "🏷️ Latest version: ${{ steps.filename.outputs.version }}"
    echo "📦 Filename: ${{ steps.filename.outputs.filename }}"
```

### Resolve Specific Version

```yaml
- name: Get specific version
  uses: openDAQ/actions/framework-compose-filename@v1
  id: filename
  with:
    version: "3.20.4"

- name: Use specific version
  run: |
    echo "🏷️ Version: ${{ steps.filename.outputs.version }}"
    echo "📦 Filename: ${{ steps.filename.outputs.filename }}"
```

### Resolve by Version and Platform

```yaml
- name: Get version for specific platform
  uses: openDAQ/actions/framework-compose-filename@v1
  id: filename
  with:
    version: "3.20.4"
    platform: "ubuntu22.04-x86_64"

- name: Use version and platform
  run: |
    echo "🏷️ Version: ${{ steps.filename.outputs.version }}"
    echo "🖥️ Platform: ${{ steps.filename.outputs.platform }}"
    echo "📦 Filename: ${{ steps.filename.outputs.filename }}"
    # Output: opendaq-3.20.4-ubuntu22.04-x86_64.deb
```

### Download Latest for Current Platform

```yaml
jobs:
  download:
    runs-on: ubuntu-22.04
    steps:
      - name: Get filename
        id: filename
        uses: openDAQ/actions/framework-compose-filename@v1
        
      - name: Download package
        run: |
          wget "https://github.com/openDAQ/openDAQ/releases/download/${{ steps.filename.outputs.version }}/${{ steps.filename.outputs.filename }}"
```

### Matrix Build

```yaml
jobs:
  build:
    strategy:
      matrix:
        include:
          - os: ubuntu-22.04
            platform: ubuntu22.04-x86_64
          - os: macos-14  
            platform: macos14-arm64
          - os: windows-2022
            platform: win64
    
    runs-on: ${{ matrix.os }}
    steps:
      - name: Compose filename
        uses: openDAQ/actions/framework-compose-filename@v1
        with:
          platform: ${{ matrix.platform }}
          version: "3.20.4"
```

---

## 📜 License

Apache License 2.0 © openDAQ
