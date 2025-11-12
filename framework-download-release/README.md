# Download OpenDAQ Release Asset

Download release assets from the `openDAQ/openDAQ` repository with automatic platform detection.

## Usage

```yaml
- uses: ./framework-download-release
  with:
    # GitHub token for API authentication
    # Default: ${{ github.token }}
    github-token: ''

    # Release version (e.g., v3.20.4) or 'latest'
    # Default: latest
    version: ''

    # Target platform (e.g., ubuntu22.04-x86_64, win64)
    # Leave empty for auto-detection
    # Default: (auto-detected)
    platform: ''

    # Package format override (e.g., deb, exe, tar.gz, zip)
    # Leave empty for auto-detection
    # Default: (auto-detected)
    packaging: ''

    # Custom glob pattern to filter assets
    # Overrides auto-detection
    # Default: (auto-generated)
    asset-pattern: ''

    # Output directory for downloaded assets
    # Default: ${{ runner.temp }}
    output-dir: ''

    # Enable verbose output
    # Default: false
    verbose: ''
```

## Outputs

```yaml
outputs:
  asset:          # Path to the downloaded asset
  asset-dir:      # Path to the downloaded asset directory
  asset-filename: # Path to the downloaded asset filename
  asset-filesize: # Size of the downloaded asset in bytes
  asset-checksum: # Checksum of the downloaded asset
  version:        # Framework version
  platform:       # Platform alias
  packaging:      # Package format/extension (e.g., deb, exe, tar.gz)
```

## Examples

### Download latest release

```yaml
- uses: ./framework-download-release
  with:
    version: latest
```

### Download specific version

```yaml
- uses: ./framework-download-release
  with:
    version: v3.20.4
```

### Download for specific platform

```yaml
- uses: ./framework-download-release
  with:
    version: latest
    platform: ubuntu22.04-x86_64
```

### Download with custom pattern

```yaml
- uses: ./framework-download-release
  with:
    version: latest
    asset-pattern: '*ubuntu*amd64*.deb'
```
