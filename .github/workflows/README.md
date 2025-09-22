[![Test All Actions](https://github.com/openDAQ/actions/actions/workflows/test-all-actions.yml/badge.svg)](https://github.com/openDAQ/actions/actions/workflows/test-all-actions.yml)

# Test All Actions

This workflow runs automated tests for all openDAQ GitHub Actions in this repository.

---

## 📌 Purpose

- Ensures that all actions work correctly.
- Runs shared workflows for each action.
- Can be used in pull requests to verify changes before merging.

---

## 🚀 Usage

This workflow is triggered automatically on:

- `push` to `main`

No manual configuration is needed — it automatically runs tests for all actions listed in the matrix.

---

## ⚙️ Matrix

Currently tested actions (via their **testing workflows**):

> TODO: add a shared testing workflow for each action here

- [ ] test-framework-download-artifact
- [ ] test-framework-download-release
- [ ] test-framework-install-package

You can add new actions to the matrix in `test-all-actions.yml` when new actions are added to the repository.

---

## 🤝 Contributing

- To add a new action for testing:
  1. Create a shared workflow for the action (e.g., `test-<action>.yml`).
  2. Add the action name to the matrix in `test-all-actions.yml`.
  3. Update this README if needed.
