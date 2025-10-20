# Test Runner Documentation Index

Welcome to the Shell Script Test Runner documentation!

## 🚀 Quick Links

- **New here?** → Start with [QUICKSTART.md](QUICKSTART.md)
- **Need help?** → Check [README.md](README.md)
- **Want details?** → See [IMPLEMENTATION.md](IMPLEMENTATION.md)
- **Planning changes?** → Review [ARCHITECTURE.md](ARCHITECTURE.md)
- **Project architecture?** → See [Root README](../../../../README.md)

## 📚 Documentation Structure

### For Users

1. **[QUICKSTART.md](QUICKSTART.md)** - Get started in 5 minutes
   - Installation
   - Basic usage
   - Common patterns
   - Quick examples

2. **[README.md](README.md)** - Complete user guide
   - All features
   - Detailed examples
   - CLI reference
   - Troubleshooting
   - Best practices

3. **[demo.sh](demo.sh)** - Interactive demonstration
   - Run it: `./demo.sh`
   - See all features in action
   - Learn by example

### For Developers

4. **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design
   - Component overview
   - Data flow diagrams
   - Module dependencies
   - Extension points

5. **[IMPLEMENTATION.md](IMPLEMENTATION.md)** - Implementation details
   - Design decisions
   - Testing strategy
   - Quality metrics
   - Integration examples

6. **[HOOKS.md](HOOKS.md)** - Test hooks guide
   - Setup and teardown
   - Hook examples
   - Best practices

7. **[WINDOWS.md](WINDOWS.md)** - Windows support
   - Path conversion
   - Platform compatibility
   - Testing on Windows

8. **[CI.md](CI.md)** - CI/CD integration
   - GitHub Actions workflows
   - Testing strategy
   - Automation examples

## 🎯 Choose Your Path

### I want to...

#### Run Tests
→ [QUICKSTART.md](QUICKSTART.md) → Section "Run Tests"

#### Write Tests
→ [QUICKSTART.md](QUICKSTART.md) → Section "Create New Test Suite"
→ [README.md](README.md) → Section "Writing Tests"

#### Filter Tests
→ [README.md](README.md) → Section "Filtering Tests"

#### Integrate with CI/CD
→ [CI.md](CI.md) → Section "GitHub Actions Workflows"

#### Understand the Code
→ [ARCHITECTURE.md](ARCHITECTURE.md) → Section "Component Details"

#### Use Test Hooks
→ [HOOKS.md](HOOKS.md) → Section "Setup and Teardown"

#### Debug Issues
→ [README.md](README.md) → Section "Troubleshooting"

## 📂 Project Structure

```
Actions/                         ← Root project
│
├── 📖 Root Documentation
│   └── README.md               ← Project architecture
│
├── 🔧 Scripts
│   └── scripts/shell/bash/     ← Scripts to be tested
│       └── math-utils.sh
│
├── 🧪 Tests
│   └── tests/shell/bash/
│       │
│       ├── 📖 Documentation
│       │   ├── INDEX.md        ← You are here
│       │   ├── QUICKSTART.md   ← Start here
│       │   ├── README.md       ← Complete guide
│       │   ├── ARCHITECTURE.md ← Design docs
│       │   ├── IMPLEMENTATION.md ← Tech details
│       │   ├── HOOKS.md        ← Test hooks
│       │   ├── WINDOWS.md      ← Windows support
│       │   └── CI.md           ← CI/CD guide
│       │
│       ├── 🎬 Demo
│       │   └── demo.sh         ← Interactive demo
│       │
│       ├── 🧠 Core Modules
│       │   ├── test-runner.sh  ← Main script
│       │   └── core/
│       │       ├── compat.sh   ← Shell compatibility
│       │       ├── filter.sh   ← Pattern matching
│       │       ├── log.sh      ← Logging system
│       │       ├── assert.sh   ← Assertion library
│       │       └── paths.sh    ← Path conversion
│       │
│       └── 🧪 Test Suites
│           └── suites/
│               ├── test-basic.sh       ← Basic examples
│               ├── test-integration.sh ← Integration examples
│               ├── test-advanced.sh    ← Advanced examples
│               ├── test-math-utils.sh  ← Script testing example
│               └── test-*.sh           ← Your tests here
│
└── ⚙️  CI/CD
    └── .github/workflows/
        ├── test-bash-scripts.yml   ← Script testing
        └── test-bash-framework.yml ← Framework testing
```

## 🎓 Learning Path

### Beginner
1. Read [QUICKSTART.md](QUICKSTART.md)
2. Run `./demo.sh`
3. Modify example tests in `suites/`
4. Create your first test suite

### Intermediate
1. Read full [README.md](README.md)
2. Learn filtering patterns
3. Integrate with your project
4. Set up CI/CD pipeline

### Advanced
1. Study [ARCHITECTURE.md](ARCHITECTURE.md)
2. Review [IMPLEMENTATION.md](IMPLEMENTATION.md)
3. Understand compatibility layer
4. Consider contributing features

## 💡 Tips

- **Start simple**: Run the demo first
- **Read examples**: Check `suites/test-*.sh` files
- **Use verbose**: Add `--verbose` flag when learning
- **Dry run first**: Use `--dry-run` to preview
- **Check filters**: Use `--list-tests-included` to debug patterns

## 🔍 Quick Reference

### Essential Commands
```bash
# Show help
./test-runner.sh --help

# Set environment variables once
export OPENDAQ_TESTS_SCRIPTS_DIR="../../../scripts"
export OPENDAQ_TESTS_SUITES_DIR="./suites"

# Run all tests
./test-runner.sh

# Run specific suite
./test-runner.sh --include-test "test-basic*"

# Dry run
./test-runner.sh --dry-run --verbose

# List tests
./test-runner.sh --list-tests
```

### Pattern Examples
```bash
# All suites
test-*

# Specific suite
test-integration*

# Specific test
test-basic:test-basic-pass

# All slow tests
*:test-*-slow

# Integration API tests
test-integration*:test-api*
```

## 📞 Need Help?

1. Check [README.md](README.md) → Troubleshooting section
2. Run with `--verbose` for detailed output
3. Check example tests for patterns
4. See [Root README](../../../../README.md) for project architecture

## 📊 Status

- ✅ **Complete**: All core features implemented
- ✅ **Tested**: Working with bash 5.2+
- ✅ **Documented**: Comprehensive docs
- ✅ **Production Ready**: Use it today!

## 🎉 Quick Wins

Get started in 3 minutes:

```bash
# 1. Run demo
./demo.sh

# 2. Set environment variables
export OPENDAQ_TESTS_SCRIPTS_DIR="../../../scripts"
export OPENDAQ_TESTS_SUITES_DIR="./suites"

# 3. Run example tests
./test-runner.sh

# 4. Create your first test
cat > suites/test-mytest.sh << 'EOF'
#!/usr/bin/env bash
test-mytest-hello() {
    echo "Hello from my test!"
    return 0
}
EOF

# 5. Run it!
./test-runner.sh --include-test "test-mytest*"
```

Happy testing! 🚀
