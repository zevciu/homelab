# Task

Task is a self-contained executable script.

## Classification

```text
Type:      Standalone
Structure: Task
Role:      [Optional]
```

## Purpose

Task scripts are designed to accomplish a specific goal.

They contain everything required to execute a task:

* configuration,
* dependencies,
* logic,
* execution.

A Task owns its entire lifecycle and can be executed directly.

Unlike Component structures, a Task does not rely on external Config, Library, or Engine layers.

---

## Roles

Roles are optional.

Examples:

```text
Daemon
Monitor
Generator
Worker
Utility
```

Roles provide additional context about the script's responsibility but do not change the structure.

---

## Sections

### Section Layout

Tasks follow this structure:

```text
METADATA
 ├── CLASSIFICATION
 └── REQUIREMENTS

CONFIGURATION
 ├── DECLARATIONS
 ├── DERIVATIONS
 └── EXPORTS (optional)

DEPENDENCIES
 ├── CONTEXT (optional)
 └── LIBRARIES (optional)

HELPERS (optional)

MAIN
 ├── INPUT
 ├── SETUP
 ├── VALIDATION
 ├── EXECUTION
 ├── FALLBACK (optional)
 └── OUTPUT / RETURN

ENTRYPOINT
```

---

### Section Responsibilities

#### METADATA

Task files use the following metadata structure:

```bash
# ##############################################################################
# METADATA
# ##############################################################################
# SCRIPT: <script_name>
# PURPOSE: <short description>
#
# ------------------------------------------------------------------------------
# CLASSIFICATION
# ------------------------------------------------------------------------------
# TYPE: STANDALONE
# STRUCTURE: TASK
# ROLE: <role>
#
# ------------------------------------------------------------------------------
# REQUIREMENTS
# ------------------------------------------------------------------------------
#   - <requirement>
#   - <requirement>
# ##############################################################################
```

##### I. Classification

Identifies the script according to the Script Model.

##### II. Requirements

Documents important runtime requirements required by the script.

---

#### CONFIGURATION

Contains all configuration definitions. Configuration should not:
- perform orchestration,
- execute commands,
- contain business logic,
- mutate runtime state.

##### I. Declarations

Defines source configuration values.

Responsibilities:
- define defaults,
- define feature flags,
- define project data,
- define service declarations.

Declarations represent information that exists independently. They should not depend on values derived later in the file.


##### II. Derivations

Defines configuration values derived from existing declarations.

Responsibilities:
- derive paths,
- derive naming conventions,
- derive helper variables,
- derive computed configuration values.

Derivations may depend on:
- declarations,
- previously loaded configuration components.

Derivations should remain deterministic and side-effect free.

##### III. Exports (optional)

Exports configuration values for external consumers.
Only export values that are intended to be consumed outside the file.

---

#### DEPENDENCIES

Loads reusable external resources.

##### I. Context (optional)

Loads external declarative context when required.

Examples:

* environment files,
* project definitions,
* shared configuration.

##### II. Libraries (optional)

Loads reusable logic modules when required.

Examples:

* logging,
* filesystem utilities,
* reusable domain logic.

---

#### HELPERS (optional)

Internal helper functions used only within the file. 

Helpers should:
- remain lightweight,
- remain deterministic

For unusually complex helpers, a lightweight Library-style internal structure may be used:

```text
FUNCTION
 ├── INPUT
 ├── SETUP
 ├── VALIDATION
 ├── CORE
 └── OUTPUT / RETURN
```

This is an exception rather than the default.

---

#### MAIN

Contains the primary workflow.

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

##### IV. EXECUTION

Contains the actual workflow.

Responsibilities:

* coordinate execution,
* invoke helpers,
* perform operations,
* drive the script toward its goal.

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

---

#### ENTRYPOINT

Provides the executable entrypoint.

Example:

```bash
main "$@"
```

---

## Summary

The intended execution flow is:

```text
CONFIGURATION
  ↓
DEPENDENCIES
  ↓
MAIN
    ├── INPUT
    ├── SETUP
    ├── VALIDATION
    ├── EXECUTION
    └── OUTPUT / RETURN
  ↓
ENTRYPOINT
```

Conceptually:

* CONFIGURATION defines the task's operating parameters.
* DEPENDENCIES assemble external resources.
* INPUT handles all incoming data and basic sanity checks.
* SETUP derives everything required for execution.
* VALIDATION verifies all runtime assumptions.
* EXECUTION performs the actual work.
* OUTPUT / RETURN exposes the result.
* ENTRYPOINT starts execution.

A key design goal is:

```text
Self-contained execution unit.
```

A Task is a complete executable script that owns its configuration, logic, and execution.

Everything required to perform the task should be understandable from a single file.

External dependencies may be used, but the script should not rely on a separate configuration, library, or orchestration layer.
