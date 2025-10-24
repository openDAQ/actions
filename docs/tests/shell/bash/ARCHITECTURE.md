# Test Runner Architecture

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────┐
│                      test-runner.sh                      │
│                    (Main Entry Point)                    │
│                                                          │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│   │   CLI Parser │  │   Discovery  │  │   Executor   │   │
│   └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │
│          │                 │                 │           │
└──────────┼─────────────────┼─────────────────┼───────────┘
           │                 │                 │
           │                 │                 │
┌──────────▼─────────────────▼─────────────────▼───────────┐
│                       Core Modules                       │
│                                                          │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │ compat.sh│  │ filter.sh│  │  log.sh  │  │ paths.sh │  │
│  │          │  │          │  │          │  │          │  │
│  │ Shell    │  │ Pattern  │  │ Logging  │  │ Files    │  │
│  │ Compat   │  │ Matching │  │ System   │  │ System   │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│                                                          │
└──────────────────────────────────────────────────────────┘
                            │
                            │ loads
                            │
                  ┌─────────▼──────────┐
                  │   Test Suites      │
                  │                    │
                  │  test-*.sh files   │
                  │                    │
                  │  ┌──────────────┐  │
                  │  │ test-basic   │  │
                  │  │ test-integ.  │  │
                  │  │ test-adv.    │  │
                  │  └──────────────┘  │
                  └────────────────────┘
```

## Component Details

### 1. test-runner.sh (Main Entry Point)

```
┌───────────────────────────────────┐
│         test-runner.sh            │
├───────────────────────────────────┤
│                                   │
│  __daq_tests_main()               │
│    │                              │
│    ├─► __daq_tests_parse_args()   │
│    │                              │
│    ├─► __daq_tests_validate()     │
│    │                              │
│    ├─► __daq_tests_discover()     │
│    │     │                        │
│    │     ├─► discover_suites()    │
│    │     └─► discover_tests()     │
│    │                              │
│    ├─► __daq_tests_filter()       │
│    │                              │
│    └─► __daq_tests_execute()      │
│          │                        │
│          ├─► run_suite()          │
│          │     └─► run_test()     │
│          │           (subshell)   │
│          │                        │
│          └─► collect_stats()      │
│                                   │
└───────────────────────────────────┘
```

### 2. core/compat.sh (Compatibility Layer)

```
┌───────────────────────────────────┐
│            compat.sh              │
├───────────────────────────────────┤
│                                   │
│  Shell Detection:                 │
│    __daq_tests_detect_shell()     │
│      ├─► bash 3.2+ check          │
│      └─► zsh check                │
│                                   │
│  Compatibility Functions:         │
│    __daq_tests_list_functions()   │
│    __daq_tests_list_variables()   │
│    __daq_tests_match_pattern()    │
│    __daq_tests_array_*()          │
│    __daq_tests_is_sourced()       │
│                                   │
└───────────────────────────────────┘
```

### 3. core/filter.sh (Pattern Matching)

```
┌────────────────────────────────────┐
│             filter.sh              │
├────────────────────────────────────┤
│                                    │
│  Pattern Storage:                  │
│    __DAQ_TESTS_INCLUDE_PATTERNS[]  │
│    __DAQ_TESTS_EXCLUDE_PATTERNS[]  │
│                                    │
│  API:                              │
│    daq_tests_filter_include_*()    │
│    daq_tests_filter_exclude_*()    │
│    daq_tests_filter_should_run()   │
│                                    │
│  Logic:                            │
│    ┌─────────────────┐             │
│    │ Parse pattern   │             │
│    │   suite:test    │             │
│    └────────┬────────┘             │
│             │                      │
│    ┌────────▼────────┐             │
│    │ Match with glob │             │
│    │  using 'case'   │             │
│    └────────┬────────┘             │
│             │                      │
│    ┌────────▼────────┐             │
│    │ Apply priority  │             │
│    │ exclude > incl. │             │
│    └─────────────────┘             │
│                                    │
└────────────────────────────────────┘
```

### 4. core/log.sh (Logging System)

```
┌────────────────────────────────┐
│            log.sh              │
├────────────────────────────────┤
│                                │
│  __DAQ_TESTS_LOG_VERBOSE flag  │
│                                │
│  ┌──────────────────────────┐  │
│  │ __daq_tests_log_info()   │  │
│  │   → stdout (always)      │  │
│  └──────────────────────────┘  │
│                                │
│  ┌──────────────────────────┐  │
│  │ __daq_tests_log_verbose()│  │
│  │   → stdout (if verbose)  │  │
│  └──────────────────────────┘  │
│                                │
│  ┌──────────────────────────┐  │
│  │ __daq_tests_log_warn()   │  │
│  │   → stderr (if verbose)  │  │
│  └──────────────────────────┘  │
│                                │
│  ┌──────────────────────────┐  │
│  │ __daq_tests_log_error()  │  │
│  │   → stderr (always)      │  │
│  └──────────────────────────┘  │
│                                │
└────────────────────────────────┘
```

## Execution Flow

### Normal Execution

```
┌─────────┐
│  Start  │
└────┬────┘
     │
     ▼
┌─────────────────┐
│ Initialize      │
│ - Load modules  │
│ - Detect shell  │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│ Parse CLI Args  │
│ - Read flags    │
│ - Set config    │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│ Validate Config │
│ - Check paths   │
│ - Verify exists │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│ Discover Suites │
│ - Scan dir      │
│ - Find test-*.sh│
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│ Discover Tests  │
│ - Source suite  │
│ - Find test-*() │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│ Apply Filters   │
│ - Check include │
│ - Check exclude │
└────┬────────────┘
     │
     ├─────────────► Dry Run? ──┐
     │                          │
     ▼                          ▼
┌─────────────────┐    ┌──────────────┐
│ Execute Tests   │    │ Show Preview │
│ - Per suite     │    │ - List tests │
│ - In subshell   │    └──────────────┘
│ - Track results │
└────┬────────────┘
     │
     ▼
┌─────────────────┐
│ Print Stats     │
│ - Total/passed  │
│ - Failed/skip   │
└────┬────────────┘
     │
     ▼
┌─────────┐
│  Exit   │
│ (code)  │
└─────────┘
```

### Test Execution (Detail)

```
For each suite:
  │
  ├─► Check if any tests should run
  │   └─► If no, skip suite
  │
  └─► Run in subshell:
      │
      ├─► Source suite file
      │
      ├─► For each test function:
      │   │
      │   ├─► Check filter
      │   │   └─► If excluded, skip
      │   │
      │   └─► Run test:
      │       │
      │       ├─► Check for test_setup()
      │       │   └─► If exists, run setup
      │       │       └─► If fails, skip test
      │       │
      │       ├─► Execute test function
      │       │
      │       ├─► Check for test_teardown()
      │       │   └─► If exists, run teardown
      │       │       └─► If fails, log warning
      │       │
      │       ├─► Capture exit code
      │       │
      │       ├─► Update stats
      │       │
      │       └─► If fail-fast and failed:
      │           └─► Exit immediately
      │
      └─► Subshell cleanup (automatic)
```

## Data Flow

```
┌──────────────┐
│ CLI Args     │
└──────┬───────┘
       │
       ▼
┌──────────────────┐         ┌─────────────┐
│ Filter Patterns  │────────►│ Pattern     │
│ - Include array  │         │ Matching    │
│ - Exclude array  │◄────────│ Engine      │
└──────────────────┘         └─────────────┘
       │                            │
       │                            │
       ▼                            ▼
┌──────────────────┐         ┌─────────────┐
│ Test Discovery   │────────►│ Filtering   │
│ - Suite list     │         │ Decision    │
│ - Test list      │◄────────│ Tree        │
└──────────────────┘         └─────────────┘
       │                            │
       │                            │
       ▼                            ▼
┌──────────────────┐         ┌─────────────┐
│ Test Execution   │────────►│ Results     │
│ - Run tests      │         │ Collection  │
│ - Collect result │◄────────│ & Stats     │
└──────────────────┘         └─────────────┘
       │
       │
       ▼
┌──────────────────┐
│ Statistics       │
│ - Print summary  │
│ - Exit code      │
└──────────────────┘
```

## Module Dependencies

```
test-runner.sh
    │
    ├─► core/assert.sh (required, no dependencies)
    │
    ├─► core/compat.sh (required, no dependencies)
    │
    ├─► core/log.sh    (required, no dependencies)
    │
    ├─► core/filter.sh (required, depends on compat.sh)
    │
    └─► core/paths.sh  (required, no dependencies)
```

## Naming Conventions

```
┌────────────────────────────────────┐
│        Variable Naming             │
├────────────────────────────────────┤
│                                    │
│  Public:                           │
│    OPENDAQ_TESTS_*                 │
│    daq_tests_*()                   │
│                                    │
│  Private:                          │
│    __DAQ_TESTS_*                   │
│    __daq_tests_*()                 │
│                                    │
│  Test Suites:                      │
│    test-<suite-name>.sh            │
│                                    │
│  Test Functions:                   │
│    test-<test-name>()              │
│                                    │
└────────────────────────────────────┘
```

## Extension Points

```
┌────────────────────────────────────┐
│      Easy to Extend                │
├────────────────────────────────────┤
│                                    │
│  1. Add new core module:           │
│     - Create core/newmodule.sh     │
│     - Source in test-runner.sh     │
│                                    │
│  2. Add new CLI flag:              │
│     - Add case in parse_args()     │
│     - Implement handler            │
│                                    │
│  3. Add new output format:         │
│     - Add format function          │
│     - Hook into print_stats()      │
│                                    │
│  4. Add setup/teardown:            │
│     - Check for setup_suite()      │
│     - Call before/after tests      │
│                                    │
└────────────────────────────────────┘
```

## See Also

- [README.md](README.md) - Complete user guide
- [IMPLEMENTATION.md](IMPLEMENTATION.md) - Implementation details
- [HOOKS.md](HOOKS.md) - Test hooks guide (setup/teardown)
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [INDEX.md](INDEX.md) - Documentation index
