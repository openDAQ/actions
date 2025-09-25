[![Test All Actions](https://github.com/openDAQ/actions/actions/workflows/test-all-actions.yml/badge.svg)](https://github.com/openDAQ/actions/actions/workflows/test-all-actions.yml)
# openDAQ/actions

A collection of reusable GitHub Actions for working with the [openDAQ Framework](https://github.com/openDAQ).

---

## [📦 Available Actions](#-available-actions)

> TODO: put an available actions list here:

- [![tests](https://github.com/openDAQ/actions/workflows/test-framework-compose-filename-shared.yml/badge.svg)](https://github.com/openDAQ/actions/workflows/test-framework-compose-filename-shared.yml) [framework-compose-filename](./framework-compose-filename/README.md) 
- [ ] framework-download-artifact
- [ ] framework-download-release
- [ ] framework-install-package

---

## [🧪 CI / Testing](#-ci-testing)

We run automated tests for all actions using the **Test All Actions workflow**.

- Runs automatically on `push` to `main` and on `pull_request` events.
- Ensures that all actions work correctly.

---

## [🤝 Contributing](#-contributing)

To add a new composite action:

1. Create a new directory for the action in the repository root (e.g., `new-action-name/`).
1. Inside this directory:
    - Define the action in `action.yml`.
    - Add a `README.md` describing the purpose of the action and usage examples.  
    *(Example: `new-action-name/README.md`)*
1. Create a reusable workflow to test the action: `.github/workflows/test-<action>-shared.yml`.
1. In `.github/workflows/test-all-actions.yml`, **add a new job** that calls `test-<action>-shared.yml`.  
    (Matrix cannot be used with `uses:`, so each action must have its own job.)
1. Create a manual test workflow: `.github/workflows/test-<action>-manual.yml`.
1. Update the root `README.md`:
    - Add the new action to the section [📦 Available Actions](#-available-actions) with a link to its `README.md` and a short description.

```txt
.
├─ 🔄 .github/
│  └─ 🔄 workflows/
│     ├─ ...
│     ├─ 🆕 test-new-action-name-shared.yml
│     ├─ 🆕 test-new-action-name-manual.yml
│     ├─ ...
│     └─ 🔄 test-all-actions.yml
├─ ...
├─ 🆕 new-action-name/
│  ├─ 🆕 action.yml
│  └─ 🆕 README.md
├─ ...
└─ 🔄 README.md
```

---

## [📜 License](#-license)

Apache License 2.0 © openDAQ
