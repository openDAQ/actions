# Install openDAQ Framework Package

This action installs the openDAQ framework package on Windows and Linux runners.

## Usage

```yaml
- uses: openDAQ/install-opendaq-action@v1
  with:
    # Full path to the openDAQ framework package file
    # Required
    framework-filename: ''
```

## Inputs

### `framework-filename`

**Required** Full path to the openDAQ framework package file.

- **Windows**: Path to `.exe` installer (e.g., `opendaq-v3.20.4-win64.exe`)
- **Linux**: Path to `.deb` package (e.g., `opendaq-v3.20.4-ubuntu20.04-x86_64.deb`)

## Supported Platforms

- ✅ Windows (via `.exe` installer)
- ✅ Linux (via `.deb` package)
- ❌ macOS (not yet supported)

## Examples

### Install from downloaded artifact

```yaml
steps:
  - name: Download openDAQ package
    uses: actions/download-artifact@v4
    with:
      name: opendaq-package
      path: ${{ runner.temp }}/packages

  - name: Install openDAQ
    uses: openDAQ/install-opendaq-action@v1
    with:
      framework-filename: ${{ runner.temp }}/packages/opendaq-v3.20.4-win64.exe
```

### Install from release

```yaml
steps:
  - name: Download openDAQ release
    run: |
      curl -L -o ${{ runner.temp }}/opendaq.deb \
        https://github.com/openDAQ/openDAQ/releases/download/v3.20.4/opendaq-v3.20.4-ubuntu22.04-x86_64.deb

  - name: Install openDAQ
    uses: openDAQ/install-opendaq-action@v1
    with:
      framework-filename: ${{ runner.temp }}/opendaq.deb
```

### Matrix build with multiple platforms

```yaml
jobs:
  test:
    strategy:
      matrix:
        include:
          - os: ubuntu-22.04
            package: opendaq-v3.20.4-ubuntu22.04-x86_64.deb
          - os: ubuntu-20.04
            package: opendaq-v3.20.4-ubuntu20.04-x86_64.deb
          - os: windows-2022
            package: opendaq-v3.20.4-win64.exe
    
    runs-on: ${{ matrix.os }}
    
    steps:
      - name: Download package
        run: |
          # Download logic here
          # Save to ${{ runner.temp }}/${{ matrix.package }}

      - name: Install openDAQ
        uses: openDAQ/install-opendaq-action@v1
        with:
          framework-filename: ${{ runner.temp }}/${{ matrix.package }}

      - name: Verify installation
        run: |
          # Your verification commands
```

## How It Works

### Windows
1. Runs the `.exe` installer with `/S` (silent) flag
2. Waits for installation to complete
3. Adds `C:\Program Files\openDAQ\bin` to `PATH`
4. Verifies exit code

### Linux
1. Uses `dpkg -i` with `sudo` to install the `.deb` package
2. Package dependencies are automatically resolved

## Post-Installation

After successful installation:

- **Windows**: The openDAQ binaries are added to `PATH`
- **Linux**: The openDAQ libraries are installed system-wide

You can immediately use openDAQ commands and libraries in subsequent steps.

## Error Handling

The action will fail if:
- The package file doesn't exist
- Installation returns a non-zero exit code
- The runner OS is not supported (macOS)
