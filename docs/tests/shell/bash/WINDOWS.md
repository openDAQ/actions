# Windows Support Guide

## Overview

The test runner fully supports Windows environments through:
- **Git Bash** (Git for Windows) - Recommended
- **Cygwin** - Full Unix environment
- **WSL** (Windows Subsystem for Linux) - Native Linux

## Quick Start on Windows

### Using Git Bash (Recommended)

```bash
# 1. Open Git Bash
# 2. Navigate to project
cd /c/Users/YourName/project

# 3. Set paths (Unix-style in Git Bash)
export OPENDAQ_TESTS_SCRIPTS_DIR="$(pwd)/scripts"
export OPENDAQ_TESTS_SUITES_DIR="$(pwd)/suites"

# 4. Run tests
cd tests/scripts/shell/bash
./test-runner.sh --suites-dir ./suites
```

### Using Cygwin

```bash
# 1. Open Cygwin terminal
# 2. Navigate to project
cd /cygdrive/c/Users/YourName/project

# 3. Set paths (use cygpath for conversion)
export OPENDAQ_TESTS_SCRIPTS_DIR=$(cygpath -u "C:\Users\YourName\project\scripts")
export OPENDAQ_TESTS_SUITES_DIR=$(cygpath -u "C:\Users\YourName\project\suites")

# 4. Run tests
cd tests/scripts/shell/bash
./test-runner.sh --suites-dir ./suites
```

### Using WSL

```bash
# WSL behaves like Linux - no special handling needed
cd ~/project
export OPENDAQ_TESTS_SCRIPTS_DIR="$(pwd)/scripts"
./test-runner.sh --suites-dir ./suites
```

## Path Handling

### Automatic Path Conversion

The test runner automatically handles path conversion:

```bash
# Windows paths are converted to Unix format internally
./test-runner.sh \
    --scripts-dir "C:\Users\test\scripts" \
    --suites-dir "C:\Users\test\suites"

# Paths are normalized automatically
# C:\Users\test\scripts → /c/Users/test/scripts (Git Bash)
# C:\Users\test\scripts → /cygdrive/c/Users/test/scripts (Cygwin)
```

### Path Conversion Functions

Available in `core/paths.sh`:

```bash
# Convert Windows path to Unix
unix_path=$(__daq_tests_to_unix_path "C:\Users\test\project")
# Result: /c/Users/test/project (Git Bash)
# Result: /cygdrive/c/Users/test/project (Cygwin)

# Convert Unix path to Windows
win_path=$(__daq_tests_to_windows_path "/c/Users/test/project")
# Result: C:\Users\test\project

# Normalize path (always returns Unix format)
normalized=$(__daq_tests_normalize_path "C:\Users\test\project")
# Result: /c/Users/test/project
```

### Platform Detection

```bash
# Check if running on Windows
if __daq_tests_is_windows; then
    echo "Running on Windows"
fi

# Check if cygpath is available
if __daq_tests_has_cygpath; then
    echo "Cygwin environment"
fi

# Get platform name
platform=$(__daq_tests_get_platform)
# Returns: "Windows (Git Bash)" or "Windows (Cygwin)" or "Linux" or "macOS"
```

## Environment Variables

### Setting Paths

**Option 1: Environment variables (recommended)**
```bash
export OPENDAQ_TESTS_SCRIPTS_DIR="C:\project\scripts"
export OPENDAQ_TESTS_SUITES_DIR="C:\project\suites"
./test-runner.sh
```

**Option 2: Command line arguments**
```bash
./test-runner.sh \
    --scripts-dir "C:\project\scripts" \
    --suites-dir "C:\project\suites"
```

**Option 3: Unix-style paths**
```bash
# In Git Bash, you can use Unix-style paths
export OPENDAQ_TESTS_SCRIPTS_DIR="/c/project/scripts"
./test-runner.sh --suites-dir /c/project/suites
```

### Path Formats

The test runner accepts and automatically converts:

| Input Format | Environment | Output (Internal) |
|--------------|-------------|-------------------|
| `C:\Users\...` | Git Bash | `/c/Users/...` |
| `C:\Users\...` | Cygwin | `/cygdrive/c/Users/...` |
| `/c/Users/...` | Git Bash | `/c/Users/...` |
| `C:/Users/...` | Any | Converted to Unix |
| Mixed slashes | Any | Normalized to `/` |

## GitHub Actions (Windows)

The project includes Windows CI workflow:

```yaml
# .github/workflows/test-windows.yml
- Git Bash testing (default on GitHub Windows runners)
- Cygwin testing (installed during workflow)
- Automatic path conversion
- Same test exclusions as Unix
```

### Running Locally Like CI

```bash
# Git Bash
./test-runner.sh --suites-dir ./suites \
    --exclude-test "test-assertions:test-assertion-demo-failure" \
    --exclude-test "test-integration:test-integration-fail" \
    --exclude-test "*:test-*-slow"
```

## Common Issues and Solutions

### Issue: "No such file or directory"

**Cause:** Incorrect path format or mixed path styles

**Solution:**
```bash
# Make sure paths are consistent
# DON'T mix formats:
export OPENDAQ_TESTS_SCRIPTS_DIR="C:\project\scripts"
cd /c/project  # ❌ Mixed formats

# DO use consistent format:
export OPENDAQ_TESTS_SCRIPTS_DIR="/c/project/scripts"
cd /c/project  # ✅ Consistent
```

### Issue: "Command not found: test-runner.sh"

**Cause:** Running from wrong directory or missing execute permission

**Solution:**
```bash
# Add execute permission
chmod +x test-runner.sh

# Run with explicit bash
bash ./test-runner.sh --suites-dir ./suites
```

### Issue: Line ending problems (CRLF)

**Cause:** Windows uses CRLF (`\r\n`), Unix uses LF (`\n`)

**Solution:**
```bash
# Configure git to handle line endings
git config --global core.autocrlf true

# Or convert files manually
dos2unix test-runner.sh
dos2unix suites/*.sh
dos2unix core/*.sh
```

### Issue: Spaces in paths

**Cause:** Unquoted paths with spaces

**Solution:**
```bash
# Always quote paths with spaces
export OPENDAQ_TESTS_SCRIPTS_DIR="/c/Program Files/project/scripts"

# Or use quotes in arguments
./test-runner.sh --scripts-dir "C:\Program Files\project\scripts"
```

## Best Practices for Windows

### 1. Use Git Bash

Git Bash is the most compatible and widely available option:
- Pre-installed with Git for Windows
- Good bash compatibility
- Handles paths automatically
- Works with most bash scripts

### 2. Avoid Absolute Windows Paths in Scripts

```bash
# ❌ Don't hardcode Windows paths
SCRIPTS_DIR="C:\project\scripts"

# ✅ Use relative paths or environment variables
SCRIPTS_DIR="${OPENDAQ_TESTS_SCRIPTS_DIR:-./scripts}"
```

### 3. Use Forward Slashes in Shell Scripts

```bash
# ✅ Forward slashes work everywhere
./test-runner.sh --suites-dir ./suites

# ❌ Backslashes need escaping
.\test-runner.sh --suites-dir .\suites  # Doesn't work in bash
```

### 4. Test on Windows Regularly

```bash
# Use GitHub Actions for Windows testing
git push  # Triggers Windows workflow automatically

# Or use Makefile locally
make test-windows  # Run Windows path tests
```

## Testing Windows Functionality

### Test Windows Path Conversion

```bash
# Run Windows-specific tests
make test-windows

# Or directly
./test-runner.sh --suites-dir ./suites \
    --include-test "test-windows-paths*"
```

### Test Platform Detection

```bash
# Check platform detection
bash -c 'source core/paths.sh && __daq_tests_get_platform'
# Output: "Windows (Git Bash)" or "Linux" or "macOS"

# Check if running on Windows
bash -c 'source core/paths.sh && __daq_tests_is_windows && echo YES || echo NO'
```

### Manual Path Conversion Test

```bash
# Test path conversion manually
source core/paths.sh

# Windows to Unix
__daq_tests_to_unix_path "C:\Users\test\project"

# Unix to Windows
__daq_tests_to_windows_path "/c/Users/test/project"

# Normalize any path
__daq_tests_normalize_path "C:/Users/test/../project"
```

## Windows-Specific Features

### Supported Features

✅ Automatic path conversion (Windows ↔ Unix)
✅ Git Bash support
✅ Cygwin support
✅ WSL support (native Linux)
✅ Mixed slash handling
✅ Drive letter conversion (C: → /c)
✅ Space in path support
✅ Environment variable normalization
✅ Relative path resolution
✅ GitHub Actions Windows runners

### Limitations

⚠️ Bash 3.2 compatibility (associative arrays limited)
⚠️ Some Unix-specific tests may behave differently
⚠️ Performance may be slower than native Unix

### Not Supported

❌ CMD/PowerShell (use Git Bash instead)
❌ Pure Windows batch scripts
❌ Windows-native path separators in test logic

## Troubleshooting

### Enable Verbose Mode

```bash
./test-runner.sh --suites-dir ./suites --verbose

# Or with environment variable
export OPENDAQ_TESTS_VERBOSE=1
./test-runner.sh --suites-dir ./suites
```

### Check Path Conversion

```bash
# Enable verbose to see path conversions
./test-runner.sh --suites-dir "C:\project\suites" --verbose

# Output will show:
# Platform: Windows (Git Bash)
# Path conversion: cygpath available (or fallback mode)
# Normalized paths: /c/project/suites
```

### Verify Environment

```bash
# Check bash version
bash --version

# Check environment
uname -s  # Should show MINGW*, CYGWIN*, or MSYS*

# Check cygpath
which cygpath  # Available in Cygwin only

# Check Git Bash version
git --version
```

## Examples

### Full Example: Running Tests on Windows

```bash
# 1. Clone repository (Git Bash)
cd /c/Users/YourName
git clone https://github.com/yourorg/project.git
cd project

# 2. Set up paths
export OPENDAQ_TESTS_SCRIPTS_DIR="$(pwd)/scripts"
export OPENDAQ_TESTS_SUITES_DIR="$(pwd)/suites"

# 3. Run all tests
cd tests/scripts/shell/bash
./test-runner.sh --suites-dir ./suites --verbose

# 4. Run specific suite
./test-runner.sh --suites-dir ./suites --include-test "test-math-utils*"

# 5. Run with exclusions (like CI)
./test-runner.sh --suites-dir ./suites \
    --exclude-test "test-assertions:test-assertion-demo-failure" \
    --exclude-test "*:test-*-slow"
```

### Example: Using Windows Paths

```bash
# All these work and are converted automatically:

./test-runner.sh --scripts-dir "C:\project\scripts"
./test-runner.sh --scripts-dir "C:/project/scripts"
./test-runner.sh --scripts-dir "/c/project/scripts"

# Environment variables also work
export OPENDAQ_TESTS_SCRIPTS_DIR="C:\project\scripts"
./test-runner.sh  # Uses converted path automatically
```

## Resources

- [Git for Windows](https://gitforwindows.org/)
- [Cygwin](https://www.cygwin.com/)
- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [Path Conversion Module](core/paths.sh)
- [Windows Tests](suites/test-windows-paths.sh)

## Support

For Windows-specific issues:
1. Check this guide
2. Run `make test-windows` to verify path conversion
3. Enable `--verbose` to see path normalization
4. Check GitHub Actions Windows workflow results
5. Ensure line endings are correct (LF not CRLF)

For general test runner issues, see [README.md](README.md#troubleshooting)
