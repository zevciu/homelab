# Library
Library is a reusable logic component.

## Classification

```text
Type:      Component
Structure: Library
Role:      Helper | Domain logic
```

## Purpose

Library components encapsulate reusable logic.

They should:

- perform a single responsibility,
- expose one public function,
- remain easy to test and reuse,
- avoid orchestration concerns,
- avoid environment initialization.

Libraries implement behavior.

They do not decide when or why that behavior should execute.

---

## Roles

Helper: generic reusable utilities with no domain knowledge.

Domain logic: reusable logic specific to a project or operational domain.

---

## Section

### Section Layout

Libraries follow this structure:

```text
METADATA
 ├── CLASSIFICATION
 ├── DEPENDENCIES
 └── INPUT / OUTPUT CONTRACT

HELPERS (optional)

MAIN
 ├── INPUT
 ├── SETUP
 ├── VALIDATION
 ├── CORE
 ├── FALLBACK (optional)
 └── OUTPUT / RETURN
```

### Section Responsibilities

#### METADATA

Library files use the following metadata structure:

```bash
# ##############################################################################
# METADATA
# ##############################################################################
# FUNCTION: <function_name>
# PURPOSE: <short description>
#
# ------------------------------------------------------------------------------
# CLASSIFICATION
# ------------------------------------------------------------------------------
# TYPE: COMPONENT
# STRUCTURE: LIBRARY
# ROLE: <role>
#
# ------------------------------------------------------------------------------
# DEPENDENCIES
# ------------------------------------------------------------------------------
#   - <file_name>.sh (<function_name>)
#   - <file_name>.sh (<function_name>)
#
# ------------------------------------------------------------------------------
# INPUT / OUTPUT CONTRACT
# ------------------------------------------------------------------------------
# INPUT:
#   $1 - <param_name>: <description>
#   $2 - <param_name>: <description>
#   $@ - <additional_flags_or_args>: <description>
#
# OUTPUT:
#   stdout: <what is printed to stdout>
#
# SIDE EFFECTS:
#   - <description>
#
# RETURNS:
#   0 on success
#   1 on validation or runtime failure
# ##############################################################################
```

##### I. Classification

##### II. Dependencies

Dependencies must document all external functons required by the library. Only direct dependencies should be listed. Maintaining the accurate listing is to make runtime requirements visible without reading the implementation.

##### III. Input / Output Contract

Every library should explicitly document:

- inputs,
- outputs,
- side effects,
- return behavior.

This contract should describe the public function only.

---

#### HELPERS (optional)

Internal helper functions used only by the main public function.

Helpers should:

- remain lightweight,
- remain deterministic,
- assume valid input unless documented otherwise.

---

#### MAIN

Contains the public function.

The function name should match the filename.

##### I. INPUT

Responsibilities:

- map positional arguments,
- parse function flags/options,
- perform lightweight sanity checks.

Should not:

- access filesystem state,
- perform network checks,
- execute business logic.

##### II. SETUP

Responsibilities:

- derive internal variables,
- build paths,
- compute helper values,
- initialize arrays and flags.

Should not:

- perform validation,
- modify state,
- execute business logic.

##### III. VALIDATION

Responsibilities:

- verify runtime preconditions,
- validate filesystem state,
- validate dependencies and resources.

This is the final fail-fast gate before execution.

Should not:

- mutate state,
- execute business logic.

##### IV. CORE

Contains the actual business logic.

At this point all validation is assumed to have passed.

Responsibilities:

- execute the intended operation,
- perform state-changing actions,
- produce results.

##### V. FALLBACK (optional)

Optional alternative behavior when the primary execution path produces no usable result.

Examples:

- default values,
- secondary lookup strategy,
- graceful degradation.

##### VI. OUTPUT / RETURN

Responsibilities:

- print output,
- return exit status,
- expose final result.

This section should conclude the public function.

---

## Summary

The intended execution flow is:

```text
INPUT
  ↓
SETUP
  ↓
VALIDATION
  ↓
CORE
  ↓
FALLBACK (optional)
  ↓
OUTPUT / RETURN
```

Conceptually:

- INPUT handles all incoming data and basic sanity checks.
- SETUP derives everything required for execution.
- VALIDATION verifies all runtime assumptions.
- CORE performs the actual operation.
- FALLBACK handles exceptional non-fatal cases.
- OUTPUT / RETURN exposes the result.

A key design goal is:

```text
No side effects before CORE.
```

If execution never reaches CORE, the function should leave no meaningful changes behind.

This makes code behavior predictable, fail-fast, safer to maintain, and easier to debug.
