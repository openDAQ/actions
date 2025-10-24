# GitHub API Wrapper (api-github-gh.sh)

Bash/zsh wrapper for GitHub CLI (`gh`) providing convenient functions for working with releases, assets, artifacts, and workflow runs.

## Overview

`api-github-gh.sh` provides a simplified interface for common GitHub API operations:
- 🔍 Discovering and verifying release versions
- 📦 Listing and downloading release assets
- 🔧 Managing workflow artifacts
- 🏃 Accessing workflow run information

The script wraps GitHub CLI (`gh`) with retry logic, error handling, and consistent API patterns.

## Features

- ✅ **Bash 3.2+ and zsh compatible**
- ✅ **Version resolution** (latest, specific tags)
- ✅ **Pattern-based filtering** (glob-style wildcards)
- ✅ **Automatic authentication** via GitHub CLI
- ✅ **Rate limit handling**
- ✅ **Artifact extraction** support
- ✅ **Verbose and debug modes**

## Prerequisites

Required tools:
- `gh` - GitHub CLI ([installation](https://cli.github.com))
- `jq` - JSON processor ([installation](https://jqlang.github.io/jq/))

The script automatically checks for dependencies and provides installation instructions.

## Quick Start

### Basic Usage

```bash
# Get latest version
./api-github-gh.sh openDAQ/openDAQ

# Verify specific version exists
./api-github-gh.sh openDAQ/openDAQ --version v3.0.0

# List all available versions
./api-github-gh.sh openDAQ/openDAQ --list-versions
```

### Working with Assets

```bash
# List assets for latest release
./api-github-gh.sh openDAQ/openDAQ --list-assets

# List assets for specific version
./api-github-gh.sh openDAQ/openDAQ --list-assets --version v3.0.0

# Filter assets by pattern
./api-github-gh.sh openDAQ/openDAQ --list-assets --pattern "*ubuntu*amd64*"

# Download all assets
./api-github-gh.sh openDAQ/openDAQ --download-asset --output-dir ./downloads

# Download specific version
./api-github-gh.sh openDAQ/openDAQ --download-asset \
    --version v3.0.0 \
    --output-dir ./downloads/v3.0.0

# Download filtered assets
./api-github-gh.sh openDAQ/openDAQ --download-asset \
    --pattern "*ubuntu*" \
    --output-dir ./downloads/ubuntu
```

### Working with Artifacts

```bash
# List recent workflow runs
./api-github-gh.sh openDAQ/openDAQ --list-runs

# List artifacts for specific run
./api-github-gh.sh openDAQ/openDAQ --list-artifacts --run-id 12345678

# Download all artifacts from run
./api-github-gh.sh openDAQ/openDAQ --download-artifact \
    --run-id 12345678 \
    --output-dir ./artifacts

# Download and extract artifacts
./api-github-gh.sh openDAQ/openDAQ --download-artifact \
    --run-id 12345678 \
    --output-dir ./artifacts \
    --extract

# Download filtered artifacts
./api-github-gh.sh openDAQ/openDAQ --download-artifact \
    --run-id 12345678 \
    --pattern "*linux*" \
    --output-dir ./artifacts
```

## CLI Reference

### Synopsis

```bash
api-github-gh.sh OWNER/REPO [OPTIONS]
```

### Options

| Option | Argument | Description |
|--------|----------|-------------|
| `--version` | VERSION | Check specific version (default: latest) |
| `--list-versions` | - | List all available versions |
| `--list-assets` | - | List assets for a version |
| `--list-runs` | - | List latest workflow runs |
| `--list-artifacts` | - | List artifacts for run-id |
| `--download-asset` | - | Download assets for a version |
| `--download-artifact` | - | Download artifacts for run-id |
| `--pattern` | PATTERN | Filter assets/artifacts by pattern (glob-style) |
| `--output-dir` | DIR | Output directory for downloads (required with download) |
| `--run-id` | ID | Workflow run ID (required for artifact operations) |
| `--limit` | N | Limit number of versions (default: 30, use 'all' for all) |
| `--extract` | - | Extract artifacts from zip after downloading |
| `--verbose` | - | Enable verbose output |
| `--help` | - | Show help message |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENDAQ_GH_API_DEBUG` | 0 | Enable debug output (set to 1) |
| `OPENDAQ_GH_API_GITHUB_REPO` | - | Default GitHub repository (OWNER/REPO) |
| `OPENDAQ_GH_API_CACHE_DIR` | /tmp | Temporary directory for caching responses |

## Pattern Matching

The `--pattern` option supports glob-style wildcards:

| Pattern | Matches |
|---------|---------|
| `*` | Any characters |
| `?` | Single character |
| `*ubuntu*` | Contains "ubuntu" |
| `*-amd64.deb` | Ends with "-amd64.deb" |
| `opendaq-*-linux*` | Starts with "opendaq-", contains "linux" |

**Examples**:

```bash
# Ubuntu packages only
--pattern "*ubuntu*"

# AMD64 architecture
--pattern "*amd64*"

# Debian packages
--pattern "*.deb"

# Specific platform
--pattern "*ubuntu-22.04*amd64*"

# Multiple filters (combine in one pattern)
--pattern "*ubuntu*amd64*.deb"
```

## Common Workflows

### 1. Find Latest Version and Download

```bash
#!/bin/bash
REPO="openDAQ/openDAQ"

# Get latest version
VERSION=$(./api-github-gh.sh "$REPO")
echo "Latest version: $VERSION"

# Download all assets
./api-github-gh.sh "$REPO" \
    --download-asset \
    --version "$VERSION" \
    --output-dir "./releases/$VERSION"
```

### 2. Download Platform-Specific Builds

```bash
#!/bin/bash
REPO="openDAQ/openDAQ"
VERSION="v3.0.0"
PLATFORM="ubuntu-22.04"
ARCH="amd64"

# Download matching assets
./api-github-gh.sh "$REPO" \
    --download-asset \
    --version "$VERSION" \
    --pattern "*${PLATFORM}*${ARCH}*" \
    --output-dir "./builds/${PLATFORM}"
```

### 3. Monitor and Download Artifacts

```bash
#!/bin/bash
REPO="openDAQ/openDAQ"

# Get latest successful run
RUN_ID=$(./api-github-gh.sh "$REPO" --list-runs --verbose | \
    grep -E "completed.*success" | head -1 | cut -f1)

echo "Latest successful run: $RUN_ID"

# Download and extract artifacts
./api-github-gh.sh "$REPO" \
    --download-artifact \
    --run-id "$RUN_ID" \
    --output-dir "./artifacts" \
    --extract
```

### 4. Verify Version Exists Before Use

```bash
#!/bin/bash
REPO="openDAQ/openDAQ"
VERSION="v3.0.0"

# Verify version exists
if ./api-github-gh.sh "$REPO" --version "$VERSION" >/dev/null 2>&1; then
    echo "✓ Version $VERSION exists"
    
    # Proceed with download
    ./api-github-gh.sh "$REPO" \
        --download-asset \
        --version "$VERSION" \
        --output-dir "./downloads"
else
    echo "✗ Version $VERSION not found"
    exit 1
fi
```

### 5. List All Versions in CI

```bash
#!/bin/bash
REPO="openDAQ/openDAQ"

# Get all versions for processing
./api-github-gh.sh "$REPO" --list-versions --limit all | \
while read -r version; do
    echo "Processing $version..."
    
    # Check if ubuntu build exists
    if ./api-github-gh.sh "$REPO" \
        --list-assets \
        --version "$version" \
        --pattern "*ubuntu*" >/dev/null 2>&1; then
        echo "  ✓ Ubuntu build available"
    else
        echo "  ✗ No Ubuntu build"
    fi
done
```

## Output Formats

### List Versions

```
v3.0.0
v2.5.1
v2.5.0
```

### List Assets (simple)

```
opendaq-3.0.0-ubuntu-22.04-amd64.deb
opendaq-3.0.0-ubuntu-20.04-amd64.deb
opendaq-3.0.0-windows-amd64.exe
```

### List Runs (verbose)

```
12345678    completed   success    Build and Test    2025-01-15T10:30:00Z
12345677    completed   failure    Build and Test    2025-01-15T09:15:00Z
```

### List Artifacts (verbose)

```
ubuntu-build    150MB   2025-01-16T00:00:00Z
windows-build   200MB   2025-01-16T00:00:00Z
```

## Error Handling

The script provides clear error messages:

```bash
# Missing dependencies
✗ Missing required dependencies:
  - gh (GitHub CLI)
  - jq (JSON processor)

# Authentication required
✗ GitHub CLI not authenticated
Run: gh auth login

# Rate limit exceeded
✗ GitHub API rate limit exceeded
Try again later or authenticate with: gh auth login

# Invalid repository format
✗ Invalid repository format. Expected: owner/repo

# Version not found
✗ Version v99.99.99 not found
```

## Debugging

Enable verbose output to see what's happening:

```bash
# Verbose mode
./api-github-gh.sh openDAQ/openDAQ --list-assets --verbose

# Debug mode (environment variable)
OPENDAQ_GH_API_DEBUG=1 ./api-github-gh.sh openDAQ/openDAQ --list-runs
```

**Output example**:
```
[INFO] Getting latest version for openDAQ/openDAQ
[DEBUG] [bash 5.2.26] API request: gh api repos/openDAQ/openDAQ/releases/latest
[INFO] Latest version: v3.0.0
[INFO] Listing assets for openDAQ/openDAQ version v3.0.0
```

## Limitations

- **Pagination**: Version list limited to 30 by default (use `--limit all` for all versions)
- **File size**: Large artifact downloads may timeout (gh CLI default timeout)
- **Authentication**: Some operations require authentication via `gh auth login`
- **Archive format**: Artifacts are always downloaded as .zip files

## Troubleshooting

### "gh: command not found"

Install GitHub CLI:
```bash
# macOS
brew install gh

# Ubuntu/Debian
sudo apt install gh

# Or follow: https://cli.github.com
```

### "jq: command not found"

Install jq:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Or follow: https://jqlang.github.io/jq/
```

### Authentication issues

```bash
# Login to GitHub
gh auth login

# Check status
gh auth status

# Refresh token
gh auth refresh
```

### Rate limit exceeded

```bash
# Check current limit
gh api rate_limit

# Authenticate to increase limit (5000/hour)
gh auth login
```

## See Also

- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub REST API](https://docs.github.com/en/rest)
- [version-format.sh](../version-format/README.md) - Version string utilities
- [platform-format.sh](../platform-format/README.md) - Platform detection utilities
- [packaging-format.sh](../packaging-format/README.md) - Package format utilities
- [README.md](./../../../../../README.md) - Actions overview
