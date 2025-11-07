# CI/CD Guide

## Overview

The test runner includes GitHub Actions workflows for automated testing across multiple shell versions and platforms.

## Workflows

### 1. Test Bash Scripts (`test-bash-scripts.yml`)

**Purpose:** Test all scripts (not framework demos) on all platforms

**Runs on:** `push` to `main`/`develop`, `pull_request`, `workflow_dispatch`

**Matrix:**
- ubuntu-latest
- macos-latest
- windows-latest

**Shell:** bash (default)

**What it tests:**
- Script functionality (e.g., `test-math-utils.sh`)
- Cross-platform compatibility
- Excludes framework demo suites

**Configuration:**
```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]

steps:
  - name: Setup environment variables
    run: |
      echo "SCRIPTS_DIR=${{ github.workspace }}/scripts" >> $GITHUB_ENV
  
  - name: Run tests
    working-directory: tests/shell/bash
    run: |
      ./test-runner.sh \
        --suites-dir ./suites \
        --scripts-dir "${SCRIPTS_DIR}" \
        --exclude-test 'test-basic*' \
        --exclude-test 'test-integration*' \
        --exclude-test 'test-advanced*' \
        --fail-fast true
```

### 2. Test Bash Framework (`test-bash-framework.yml`)

**Purpose:** Test framework features on multiple shells and platforms

**Runs on:** `push` to `main`/`develop`, `pull_request`, `workflow_dispatch`

**Matrix:**
- Ubuntu: bash (latest), zsh
- macOS: bash (default 3.2), zsh (default)
- Windows: bash (Git Bash)

**What it tests:**
- Framework functionality (basic, integration, advanced, math-utils)
- Shell compatibility (bash and zsh)
- Cross-platform compatibility
- Excludes intentional failures

**Configuration:**
```yaml
strategy:
  matrix:
    include:
      # Ubuntu - bash and zsh
      - os: ubuntu-latest
        shell-name: bash
        shell-cmd: bash
      - os: ubuntu-latest
        shell-name: zsh
        shell-cmd: zsh
      
      # macOS - bash and zsh
      - os: macos-latest
        shell-name: bash
        shell-cmd: bash
      - os: macos-latest
        shell-name: zsh
        shell-cmd: zsh
      
      # Windows - bash only
      - os: windows-latest
        shell-name: bash
        shell-cmd: bash

steps:
  - name: Run demo tests
    shell: ${{ matrix.shell }}
    run: |
      ./test-runner.sh \
        --suites-dir ./suites \
        --scripts-dir "${SCRIPTS_DIR}" \
        --include-test 'test-basic*' \
        --include-test 'test-integration*' \
        --include-test 'test-advanced*' \
        --include-test 'test-math-utils*' \
        --exclude-test '*:test-integration-fail' \
        --exclude-test '*:test-*-slow' \
        --fail-fast true
```

## Local Testing

### Replicating CI Environment

```bash
# Set scripts directory
export SCRIPTS_DIR="$(pwd)/scripts"

cd tests/shell/bash

# Test scripts (like test-bash-scripts.yml)
./test-runner.sh \
  --suites-dir ./suites \
  --scripts-dir "${SCRIPTS_DIR}" \
  --exclude-test 'test-basic*' \
  --exclude-test 'test-integration*' \
  --exclude-test 'test-advanced*' \
  --exclude-test 'test-hooks*' \
  --exclude-test 'test-assertions*' \
  --exclude-test 'test-windows-paths*' \
  --fail-fast true

# Test framework (like test-bash-framework.yml)
./test-runner.sh \
  --suites-dir ./suites \
  --scripts-dir "${SCRIPTS_DIR}" \
  --include-test 'test-basic*' \
  --include-test 'test-integration*' \
  --include-test 'test-advanced*' \
  --include-test 'test-math-utils*' \
  --exclude-test '*:test-integration-fail' \
  --exclude-test '*:test-*-slow' \
  --fail-fast true
```

### Testing Specific Shell

```bash
# Test with bash
bash test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}"

# Test with zsh
zsh test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}"

# Test with specific bash version (if installed)
bash --version
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}"
```

## Excluded Tests in CI

### Why exclude certain tests?

**In test-bash-scripts.yml:**
- Excludes framework demo suites (basic, integration, advanced, hooks, assertions, windows-paths)
- Only runs script tests (e.g., test-math-utils.sh)

**In test-bash-framework.yml:**
- Excludes intentional failures: `test-integration-fail`
- Excludes slow tests: `*:test-*-slow`
- Runs only demo suites to validate framework features

### Running all tests locally (including excluded):

```bash
# Run everything including demos and failures
./test-runner.sh \
  --suites-dir ./suites \
  --scripts-dir "${SCRIPTS_DIR}" \
  --verbose

# Run only excluded tests
./test-runner.sh \
  --suites-dir ./suites \
  --scripts-dir "${SCRIPTS_DIR}" \
  --include-test 'test-integration:test-integration-fail' \
  --include-test '*:test-*-slow'
```

## Environment Variables

### Required Variables

```bash
SCRIPTS_DIR    # Path to scripts directory
```

### Setting in GitHub Actions

```yaml
- name: Setup environment variables
  run: |
    echo "SCRIPTS_DIR=${{ github.workspace }}/scripts" >> $GITHUB_ENV
```

### Setting Locally

```bash
# Absolute path
export SCRIPTS_DIR="/path/to/project/scripts"

# Relative to test-runner location
export SCRIPTS_DIR="../../../scripts"
```

## CI Best Practices

### 1. Fail Fast
Always use `--fail-fast true` in CI for quicker feedback:

```bash
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --fail-fast true
```

### 2. Verbose on Failure
Add verbose output only when tests fail:

```yaml
- name: Run tests
  id: tests
  run: ./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --fail-fast true

- name: Run tests with verbose (on failure)
  if: failure()
  run: ./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --verbose
```

### 3. Test Summary
Add test results to job summary:

```yaml
- name: Test results summary
  if: always()
  run: |
    echo "### Test Results for ${{ matrix.os }}" >> $GITHUB_STEP_SUMMARY
    echo "✅ Tests completed" >> $GITHUB_STEP_SUMMARY
```

### 4. Matrix Strategy
Use matrix for testing multiple configurations:

```yaml
strategy:
  fail-fast: false  # Don't cancel other jobs on first failure
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    shell: [bash, zsh]
```

## Debugging CI Failures

### 1. Check Job Logs
Look at the test output in GitHub Actions logs

### 2. Run Locally with Same Parameters
Copy the exact command from CI and run locally:

```bash
export SCRIPTS_DIR="./scripts"
./test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}" --fail-fast true --verbose
```

### 3. Test Specific Shell Version
If failure is shell-specific, test with that shell version:

```bash
# Install specific bash version (Ubuntu)
sudo apt-get install bash=4.4*

# Test with it
bash test-runner.sh --suites-dir ./suites --scripts-dir "${SCRIPTS_DIR}"
```

### 4. Platform-Specific Issues
For Windows path issues, check `core/paths.sh` and `test-windows-paths.sh`

## Integration with Pre-commit Hooks

```bash
#!/bin/bash
# .git/hooks/pre-commit

set -e

echo "Running test suite..."

export SCRIPTS_DIR="./scripts"

cd tests/shell/bash
./test-runner.sh \
  --suites-dir ./suites \
  --scripts-dir "${SCRIPTS_DIR}" \
  --exclude-test '*:test-integration-fail' \
  --exclude-test '*:test-*-slow' \
  --fail-fast true

echo "✅ All tests passed!"
```

## Continuous Deployment

After tests pass, you can trigger deployment:

```yaml
jobs:
  test:
    # ... test jobs ...
  
  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy
        run: |
          echo "Deploying after successful tests"
```

## Monitoring Test Health

### Test Duration
Monitor test execution time to catch performance regressions

### Flaky Tests
Tests that fail intermittently should be:
1. Investigated and fixed
2. Temporarily excluded with `*:test-name-slow`
3. Documented in test comments

### Coverage
Track which scripts have tests:
- Every script in `scripts/` should have a corresponding `test-*.sh`
- Review test coverage in code reviews

## See Also

- [README.md](README.md) - Complete test runner documentation
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [IMPLEMENTATION.md](IMPLEMENTATION.md) - Implementation details
- [Root README](../../../../README.md) - Project architecture and actions
