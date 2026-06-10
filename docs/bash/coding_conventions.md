# Coding Conventions

This document defines the general coding conventions used across all my Bash scripts in this repository.

It describes rules that apply regardless of script type, structure, or role.

---

# 0. Purpose

The goals of these conventions are:

- improve readability,
- maintain consistency,
- make scripts easier to navigate.

For script classification and architecture, see:

- `script_model.md`

---

# 1. Design Principles

## 1.1 Fail-Fast Validation

Errors should be detected as early as possible.

Use:

set -euo pipefail

unless there is a specific reason not to.

Validate assumptions before performing any actions.

Abort execution immediately when required conditions are not met.

## 1.2 Deterministic Execution Flow

Execution should be predictable and easy to follow.

Avoid hidden control flow and implicit behavior.

## 1.3 Minimal Hidden State

Prefer explicit inputs and outputs.

Avoid relying on global mutable state whenever possible.

## 1.4 Explicit Dependencies

External dependencies should be clearly declared and sourced.

Avoid implicit runtime requirements.

## 1.5 Reusable Logic

Reusable functionality should be extracted into library components.

Avoid duplicating logic across any type of scripts.

---

# 2. Architectural Rules

## 2.1 Single Responsibility

Every script, file, and function should have a single clear responsibility.

Avoid mixing unrelated concerns within the same unit.

Responsibilities should be separated according to the Script Model.

## 2.2 Library Components

Library files should expose a single reusable public function.

## 2.3 Helper Placement

Internal helper functions should be defined before the main public function.

## 2.4 Validation Separation

Validation should be separated from execution logic whenever practical.

---

# 3. Naming Rules

## 3.1 Files

Use snake_case.

Examples:

```text
apply_config.sh
deploy_containers.sh
create_dirs.sh
```

## 3.2 Functions

Use snake_case.

Examples:

```bash
apply_config()
deploy_containers()
create_dirs()
```

## 3.3 Main Function

The primary function should match the filename.

Example:

```text
apply_config.sh
```

```bash
apply_config()
```

## 3.4 Internal Helpers

Internal helper functions should use:

```text
<main_function>__<helper>
```

Examples:

```bash
apply_config__validate()
apply_config__copy_files()
```

## 3.5 Variables

Local variables:

```bash
local source_dir
local runtime_root
```

Global/exported variables:

```bash
PROJECT_NAME
WORKSPACE_ROOT
DEBUG
```

---

# 4. Visual Hierarchy

Scripts use four visual hierarchy levels.

## 4.1 Metasections

```bash
# ##############################################################################
# METADATA
# ##############################################################################
```

Used only for metadata sections.

## 4.2 Sections

```bash
# ==============================================================================
# CONFIGURATION
# ==============================================================================
```

## 4.3 Subsections

```bash
# ------------------------------------------------------------------------------
# SETUP
# ------------------------------------------------------------------------------
```

## 4.4 Inline Comments

```bash
# --- resolve paths ---
```

---

