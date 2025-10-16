# openDAQ Composite Actions

Collection of reusable composite GitHub Actions for openDAQ project workflows.

## Project Architecture

This repository contains:
- **Composite Actions** (`*/action.yml`) - Reusable GitHub Actions for common workflows
- **Shell Scripts** (`scripts/`) - Common scripts used by actions
- **Shell Scripts Demo** (`scripts-demo/`) - Common scripts used by a sefl verification
- **Tests** (`tests/`) - Test suites for validating scripts and framework functionality
- **Tests Demo** (`tests-demo/`) - Test suites for self validating of local test framework functionality

### Directory Structure

```
Actions/
├── .github/workflows/          # CI/CD workflows
│   ├── test-bash-scripts.yml   # Test production scripts on all platforms
│   └── test-bash-framework.yml # Test runner framework on multiple shells
│
├── framework-compose-filename/ # Action: Compose openDAQ package filename
│   └── action.yml
│
├── framework-download-artifact/ # Action: Download workflow artifact
│   └── action.yml
│
├── framework-download-release/ # Action: Download GitHub release asset
│   └── action.yml
│
├── framework-install-package/  # Action: Install/extract downloaded package
│   └── action.yml
│
├── scripts/                    # Common scripts for actions (production)
│   └── shell/                  # Shell scripts
│       └── bash/               # Bash scripts (cross-platform)
│           ├── api-github-gh.sh      # GitHub API utilities
│           ├── packaging-format.sh   # Package format utilities
│           ├── platform-format.sh    # Platform detection/formatting
│           └── version-format.sh     # Version formatting utilities
│
├── scripts-demo/               # Common scripts for framework self tests
│   └── shell/                  # Shell self testing scripts
│       └── bash/               # Bash self testing scripts
│           └── math-utils.sh         # Math utilities (example)
│
└── tests/                      # Test suites
    └── shell/                  # Shell script tests
        └── bash/               # Bash test framework
            ├── core/           # Test framework core modules
            ├── suites/         # Test suites for production scripts
            ├── suites-demo/    # Test suites for self testing
            │   ├── test-basic.sh       # Basic framework tests
            │   ├── test-integration.sh # Integration tests
            │   ├── test-advanced.sh    # Advanced features
            │   └── test-math-utils.sh  # Example script testing
            ├── test-runner.sh  # Test runner
            ├── demo.sh         # Framework demo
            └── *.md            # Documentation
```

## Actions

### [framework-compose-filename](./framework-compose-filename/README.md)

Composes the filename for openDAQ installation packages based on version, platform, and format.

### [framework-download-artifact](./framework-download-artifact/README.md)

Downloads an artifact from a specific workflow run.

### [framework-download-release](./framework-download-release/README.md)

Downloads an asset from a GitHub release.

### [framework-install](./framework-install/README.md)

Installs or extracts a downloaded package.

## Scripts

Scripts in `scripts/` directory are self-contained and platform-aware.

### Script Development Guidelines

1. **Cross-platform compatibility**: Scripts should work on Linux, macOS, and Windows (Git Bash/Cygwin)
2. **Self-contained**: No cross-dependencies between scripts
3. **Environment variables**: Use `OPENDAQ_TESTS_SCRIPTS_DIR` for script location
4. **Path normalization**: Handle Windows paths using provided utilities
5. **Error handling**: Use `set -euo pipefail` for strict error handling

### Path Normalization Example

For Windows compatibility in actions:

```bash
# Normalize path for Windows (convert to Unix-style)
if command -v cygpath >/dev/null 2>&1; then
  dir_path="$(cygpath "$dir_path")"
fi
```

### Script Organization

- `shell/bash/` - Bash scripts (primary, cross-platform)
- `shell/pwsh/` - PowerShell scripts (Windows-specific, if needed)
- `js/` - JavaScript scripts (future expansion)

## Testing

### Script Testing

All scripts must have corresponding test suites in `tests/shell/bash/suites/`.

**Test naming convention:** `test-<script-name>.sh`

**Example:**
```bash
# For scripts/shell/bash/math-utils.sh
# Create tests/shell/bash/suites/test-math-utils.sh
```

See [Test Framework Documentation](tests/shell/bash/INDEX.md) for details.

### Framework Testing

The test runner framework itself is tested with demo suites:
- `test-basic.sh` - Basic functionality tests
- `test-integration.sh` - Integration tests
- `test-advanced.sh` - Advanced features
- `test-hooks.sh` - Setup/teardown hooks
- `test-assertions.sh` - Assertion library
- `test-windows-paths.sh` - Windows path conversion

### Action Testing

Each action should have corresponding workflows for testing:

#### Manual Testing

Create `test-<action>-manual.yml` for manual testing:

```yaml
name: Test [Action Name] (Manual)

on:
  workflow_dispatch:
    inputs:
      # Same inputs as the action
      version:
        description: 'Package version'
        required: true
      runner:
        description: 'Runner OS'
        required: true
        type: choice
        options:
          - ubuntu-latest
          - macos-latest
          - windows-latest

jobs:
  test-action:
    runs-on: ${{ inputs.runner }}
    steps:
      - uses: actions/checkout@v4
      - uses: ./framework-compose-filename
        with:
          version: ${{ inputs.version }}
```

#### Automated Testing

Create `test-<action>.yml` for automated testing (when applicable):

```yaml
name: Test [Action Name]

on:
  push:
    paths:
      - 'framework-compose-filename/**'
  pull_request:
    paths:
      - 'framework-compose-filename/**'

jobs:
  test:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@v4
      - uses: ./framework-compose-filename
        with:
          version: '3.20.4'
          platform: 'ubuntu20.04-x86_64'
      # Validate outputs
```

**Note:** Some actions like `framework-download-artifact` are difficult to test automatically because:
- Artifacts have limited retention periods
- Generating test artifacts is time-consuming
- Requires complex workflow dependencies

For such actions, manual testing workflows are sufficient.

## Running Tests Locally

### Test All Scripts

```bash
cd tests/shell/bash

# Set scripts directory
export SCRIPTS_DIR="../../../scripts"

# Run only script tests (e.g., math-utils)
./test-runner.sh \
  --suites-dir ./suites \
  --scripts-dir "${SCRIPTS_DIR}" \
  --include-test 'test-math-utils*'
```

### Test Framework Features

```bash
cd tests/shell/bash

# Run demo suites
./test-runner.sh \
  --suites-dir ./suites \
  --scripts-dir "${SCRIPTS_DIR}" \
  --include-test 'test-basic*' \
  --include-test 'test-integration*' \
  --include-test 'test-advanced*' \
  --exclude-test '*:test-integration-fail'
```

### Run Demo

```bash
cd tests/shell/bash
./demo.sh
```

## Environment Variables

### Required Variables

- `OPENDAQ_TESTS_SCRIPTS_DIR` - Path to scripts directory (set in tests)

### Usage in Tests

```bash
# In test suite
test-example() {
    # Source a script
    source "${__DAQ_TESTS_SCRIPTS_DIR}/shell/bash/math-utils.sh"
    
    # Or execute as command
    local SCRIPT="${__DAQ_TESTS_SCRIPTS_DIR}/shell/bash/version-format.sh"
    $SCRIPT --version "1.2.3" --format "semver"
}
```

## CI/CD Workflows

### test-bash-scripts.yml

Tests all scripts on multiple platforms (Ubuntu, macOS, Windows).

**Runs:**
- Only script test suites (e.g., `test-math-utils.sh`)
- Excludes framework demo suites
- Matrix: `[ubuntu-latest, macos-latest, windows-latest]`
- Shell: `bash` (default)

### test-bash-framework.yml

Tests the test runner framework on multiple shells and platforms.

**Runs:**
- Only demo suites (basic, integration, advanced, math-utils)
- Excludes intentional failures
- Matrix:
  - Ubuntu: bash (multiple versions), zsh
  - macOS: zsh (system default)
  - Windows: bash (Git Bash)

## Contributing

### Adding a New Script

1. Create script in `scripts/shell/bash/<script-name>.sh`
2. Make it self-contained (no dependencies on other scripts)
3. Add cross-platform support (Windows path handling)
4. Create test suite in `tests/shell/bash/suites/test-<script-name>.sh`
5. Update this README if needed

### Adding a New Action

1. Create directory `<action-name>/`
2. Create `<action-name>/action.yml`
3. Use scripts from `scripts/` directory
4. Normalize paths for Windows compatibility
5. Create test workflows:
   - `test-<action>-manual.yml` (always)
   - `test-<action>.yml` (if applicable)

### Modifying Tests

1. Tests are in `tests/shell/bash/suites/`
2. Follow naming convention: `test-<feature>.sh`
3. Use assertion library from `core/assert.sh`
4. Test with `--scripts-dir` parameter
5. Run locally before committing

## Documentation

- **Test Framework**: [tests/shell/bash/INDEX.md](tests/shell/bash/INDEX.md)
- **Quick Start**: [tests/shell/bash/QUICKSTART.md](tests/shell/bash/QUICKSTART.md)
- **Architecture**: [tests/shell/bash/ARCHITECTURE.md](tests/shell/bash/ARCHITECTURE.md)
- **Hooks Guide**: [tests/shell/bash/HOOKS.md](tests/shell/bash/HOOKS.md)
- **Windows Support**: [tests/shell/bash/WINDOWS.md](tests/shell/bash/WINDOWS.md)
- **CI/CD Guide**: [tests/shell/bash/CI.md](tests/shell/bash/CI.md)

## License

Apache License 2.0 © openDAQ

## Support

For issues and questions:
- Create an issue in this repository
- Check existing documentation in `tests/shell/bash/`
- Review workflow runs in `.github/workflows/`
