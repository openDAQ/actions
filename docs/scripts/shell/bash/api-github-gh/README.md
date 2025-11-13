# GitHub API Wrapper (api-github-gh.sh)

Bash/zsh wrapper for GitHub CLI (`gh`) providing convenient functions for working with release versions.

## Overview

`api-github-gh.sh` provides a simplified interface for GitHub release version operations:
- 🔍 Discovering and verifying release versions
- 📋 Listing available versions

The script wraps GitHub CLI (`gh`) with retry logic, error handling, and consistent API patterns.

## Features

- ✅ **Bash 3.2+ and zsh compatible**
- ✅ **Version resolution** (latest, specific tags)
- ✅ **Automatic authentication** via GitHub CLI
- ✅ **Rate limit handling**
- ✅ **Verbose and debug modes**

## Prerequisites

Required tools:
- `gh` - GitHub CLI ([installation](https://cli.github.com))
- `jq` - JSON processor ([installation](https://jqlang.github.io/jq/))

The script automatically checks for dependencies and provides installation instructions.

## Usage

### Basic Examples

```bash
# Get latest version
./api-github-gh.sh openDAQ/openDAQ

# Verify specific version exists
./api-github-gh.sh openDAQ/openDAQ --version v3.0.0

# List all versions
./api-github-gh.sh openDAQ/openDAQ --list-versions

# List last 5 versions
./api-github-gh.sh openDAQ/openDAQ --list-versions --limit 5
```

### CLI Options

| Option | Argument | Description |
|--------|----------|-------------|
| `--version` | VERSION | Check specific version (default: latest) |
| `--list-versions` | - | List all available versions |
| `--limit` | N | Limit number of versions (default: 30, use 'all' for all) |
| `--verbose` | - | Enable verbose output |
| `--help` | - | Show help message |

## Sourcing as Library

```bash
#!/usr/bin/env bash
source ./api-github-gh.sh

# Use API functions
latest=$(daq_api_gh_version_latest "openDAQ/openDAQ")
echo "Latest version: $latest"

# List versions
daq_api_gh_version_list "openDAQ/openDAQ" 10

# Verify version
if daq_api_gh_version_verify "openDAQ/openDAQ" "v3.0.0"; then
    echo "Version exists"
fi
```

## Public API Functions

### Version Functions

- `daq_api_gh_version_latest(repo)` - Get latest version tag
- `daq_api_gh_version_verify(repo, version)` - Verify version exists
- `daq_api_gh_version_resolve(repo, version)` - Resolve version tag
- `daq_api_gh_version_list(repo, [limit])` - List version tags

## Environment Variables

- `OPENDAQ_GH_API_DEBUG=1` - Enable debug output
- `OPENDAQ_GH_API_GITHUB_REPO` - Set default GitHub repo
- `OPENDAQ_GH_API_CACHE_DIR=/tmp` - Temp dir for cache responses

## Error Handling

The script uses `set -u` for undefined variable detection and returns non-zero exit codes on errors.

```bash
if ./api-github-gh.sh openDAQ/openDAQ --version v999.0.0; then
    echo "Version found"
else
    echo "Version not found" >&2
    exit 1
fi
```

## Shell Compatibility

- ✅ bash 3.2+ (macOS default)
- ✅ bash 4.0+
- ✅ bash 5.0+
- ✅ zsh 5.0+

Tested on:
- macOS (bash 3.2, zsh 5.9)
- Ubuntu Linux (bash 5.1+, zsh 5.8+)

## Limitations

- Requires authenticated `gh` CLI
- Rate limited by GitHub API (5000 requests/hour for authenticated users)

## See Also

- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [GitHub REST API](https://docs.github.com/en/rest)
- [Naming Conventions](../CONVENTIONS.md)
