#!/usr/bin/env bash
# Demo script to showcase test runner features
# Runs only demo suites: basic, integration, advanced + math-utils

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

# Path to scripts directory (relative to test-runner location)
SCRIPTS_DIR="$(cd "../../../scripts-demo/shell/bash" && pwd)"
SUITES_DIR="./suites-demo"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Test Runner Demo - Framework Features              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Demo 1: List demo suites
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Demo 1: Discovering Demo Test Suites"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$ ./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir ${SCRIPTS_DIR} --list-suites"
echo ""
./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir "${SCRIPTS_DIR}" --list-suites
echo ""
read -p "Press Enter to continue..."
echo ""

# Demo 2: List tests from demo suites
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Demo 2: Discovering Tests in Demo Suites"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$ ./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir ${SCRIPTS_DIR} \\"
echo "    --include-test 'test-basic*' --include-test 'test-integration*' \\"
echo "    --include-test 'test-advanced*' --include-test 'test-math-utils*' \\"
echo "    --list-tests"
echo ""
./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir "${SCRIPTS_DIR}" \
    --include-test 'test-basic*' --include-test 'test-integration*' \
    --include-test 'test-advanced*' --include-test 'test-math-utils*' \
    --list-tests
echo ""
read -p "Press Enter to continue..."
echo ""

# Demo 3: Dry run with verbose
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Demo 3: Dry Run (Verbose) - Preview Execution"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$ ./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir ${SCRIPTS_DIR} \\"
echo "    --include-test 'test-basic*' --dry-run --verbose"
echo ""
./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir "${SCRIPTS_DIR}" \
    --include-test 'test-basic*' --dry-run --verbose
echo ""
read -p "Press Enter to continue..."
echo ""

# Demo 4: Run basic tests with filtering
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Demo 4: Run Basic Tests with Filtering"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$ ./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir ${SCRIPTS_DIR} \\"
echo "    --include-test 'test-basic*' \\"
echo "    --exclude-test '*:test-basic-arrays'"
echo ""
./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir "${SCRIPTS_DIR}" \
    --include-test 'test-basic*' \
    --exclude-test '*:test-basic-arrays'
echo ""
read -p "Press Enter to continue..."
echo ""

# Demo 5: Show excluded tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Demo 5: List Excluded Tests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$ ./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir ${SCRIPTS_DIR} \\"
echo "    --exclude-test '*:test-integration-fail' \\"
echo "    --exclude-test '*:test-*-slow' \\"
echo "    --list-tests-excluded"
echo ""
./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir "${SCRIPTS_DIR}" \
    --exclude-test '*:test-integration-fail' \
    --exclude-test '*:test-*-slow' \
    --list-tests-excluded
echo ""
read -p "Press Enter to continue..."
echo ""

# Demo 6: Run demo suites without failing tests
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Demo 6: Run Demo Suites (Excluding Intentional Failures)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$ ./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir ${SCRIPTS_DIR} \\"
echo "    --include-test 'test-basic*' --include-test 'test-integration*' \\"
echo "    --include-test 'test-advanced*' --include-test 'test-math-utils*' \\"
echo "    --exclude-test '*:test-integration-fail' \\"
echo "    --exclude-test '*:test-*-slow'"
echo ""
./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir "${SCRIPTS_DIR}" \
    --include-test 'test-basic*' --include-test 'test-integration*' \
    --include-test 'test-advanced*' --include-test 'test-math-utils*' \
    --exclude-test '*:test-integration-fail' \
    --exclude-test '*:test-*-slow'
echo ""
read -p "Press Enter to continue..."
echo ""

# Demo 7: Fail fast demo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Demo 7: Fail Fast Mode (Stops on First Failure)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$ ./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir ${SCRIPTS_DIR} \\"
echo "    --include-test 'test-integration*' --fail-fast true"
echo ""
echo "(This will stop when test-integration-fail fails)"
echo ""
./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir "${SCRIPTS_DIR}" \
    --include-test 'test-integration*' --fail-fast true 2>&1 || true
echo ""
read -p "Press Enter to continue..."
echo ""

# Demo 8: Verbose execution
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Demo 8: Verbose Execution (Detailed Output)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "$ ./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir ${SCRIPTS_DIR} \\"
echo "    --include-test 'test-math-utils:test-math-add' \\"
echo "    --verbose"
echo ""
./test-runner.sh --suites-dir ${SUITES_DIR} --scripts-dir "${SCRIPTS_DIR}" \
    --include-test 'test-math-utils:test-math-add' \
    --verbose
echo ""

echo "╔════════════════════════════════════════════════════════════╗"
echo "║                   Demo Complete!                           ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "Demo Suites Covered:"
echo "  ✅ test-basic       : Basic functionality tests"
echo "  ✅ test-integration : Integration tests (with fail demo)"
echo "  ✅ test-advanced    : Advanced features"
echo "  ✅ test-math-utils  : Example script testing"
echo ""
echo "Key Takeaways:"
echo "  ✅ Automatic test discovery"
echo "  ✅ Flexible filtering with wildcards"
echo "  ✅ Scripts directory support (--scripts-dir)"
echo "  ✅ Dry-run preview mode"
echo "  ✅ Fail-fast for quick feedback"
echo "  ✅ Detailed verbose logging"
echo "  ✅ Comprehensive statistics"
echo ""
echo "For more information:"
echo "  - README.md       : Complete documentation"
echo "  - QUICKSTART.md   : Quick start guide"
echo "  - ARCHITECTURE.md : Architecture overview"
echo "  - INDEX.md        : Documentation index"
echo ""
