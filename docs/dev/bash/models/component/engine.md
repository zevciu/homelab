# Engine

Engine is an orchestration component.

## Classification

```text
Type:      Component
Structure: Engine
Role:      CLI | Runner
```

## Purpose

Engine components coordinate execution.

They should:

- assembly execution context & reusable logic through dependencies,
- orchestrate workflows,
- dispatch reusable logic,
- manage orchestration state

Engines decide when and why logic executes.

They should not implement reusable business logic directly.

---

## Roles

CLI: command-driven orchestration interface.

Runner: scenario-driven execution engine.

---

## Sections

### Section Layout

Engines follow this structure:

```text
METADATA
 ├── CLASSIFICATION
 └── WORKFLOW MODEL

DEPENDENCIES
├── CONTEXT
└── LIBRARIES

HELPERS (optional)

ORCHESTRATOR
 ├── INPUT
 ├── SETUP
 ├── VALIDATION
 └── FLOW

ENTRYPOINT
```

### Section Responsibilities

#### METADATA

Engine files use the following metadata structure:

```bash
# ##############################################################################
# METADATA
# ##############################################################################
# FUNCTION: <function_name>
# PURPOSE: <description>
#
# ------------------------------------------------------------------------------
# CLASSIFICATION
# ------------------------------------------------------------------------------
# TYPE: COMPONENT
# STRUCTURE: ENGINE
# ROLE: <role>
#
# ------------------------------------------------------------------------------
# WORKFLOW MODEL
# ------------------------------------------------------------------------------
#
# CONTEXT MODEL:
#   <context entity>  -> <description>
#   <context entity>  -> <description>
#
# RESOURCE MODEL (optional):
#   <resource> -> <location>
#   <resource> -> <location>
#
# FLOW:
#   1. <step>
#   2. <step>
#   3. <step>
#
# SAFETY:
#   - <safety guarantee>
#   - <safety guarantee>
# ##############################################################################
```

##### I. Classification

Identifies the script according to the Script Model.

##### II. Workflow Model

Documents how the engine operates.

###### Context Model

Defines the primary concepts and entities used by the engine.

Examples:

- blueprint,
- service,
- scenario,
- fixture

###### Resource Model (optional)

Documents important resources and locations used by the engine.

This section is used when resource ownership or location is important to understanding the workflow.

###### Flow

Describes the high-level orchestration flow.

The goal is to explain execution behavior without requiring implementation details.

###### Safety

Documents safeguards and guarantees provided by the engine.

Examples:

- fail-fast validation,
- dry-run support,
- confirmation prompts,
- rollback behavior.

---

#### DEPENDENCIES

Responsible for assembling everything required by the engine.

This section defines the execution context and reusable logic available to the orchestration layer.

It also serves as the engine's dependency manifest.

##### I. CONTEXT

Loads declarative runtime context.

##### II. LIBRARIES

Loads reusable logic modules.

---

#### HELPERS (optional)

Internal helper functions used only by the engine.

Helpers should:

- remain lightweight,
- remain deterministic,
- avoid reusable business logic.

If helper logic becomes broadly reusable, it should be promoted into a Library component.

---

#### ORCHESTRATOR

Contains the primary orchestration function.

##### I. INPUT

Responsibilities:

- map arguments,
- parse flags/options,
- perform lightweight sanity checks.

Should not:

- access runtime resources,
- execute orchestration logic.

##### II. SETUP

Responsibilities:

- derive internal variables,
- resolve paths,
- initialize flags and state.

Should not:

- execute orchestration logic,
- mutate external state.

##### III. VALIDATION

Responsibilities:

- validate runtime context,
- verify resources,
- verify prerequisites.

This is the final fail-fast gate before execution.

Should not:

- modify state,
- execute orchestration logic.

##### IV. FLOW

Contains orchestration logic.

Responsibilities:

- dispatch workflows,
- coordinate reusable libraries,
- control execution order,
- manage orchestration state.

Business logic should remain inside Library components.

---

#### ENTRYPOINT

Defines how execution enters the engine.

Typical responsibilities:

- invoke the orchestration function,
- pass command-line arguments,
- initialize execution.

Example:

```bash
cli_engine "$@"
```

---

## Summary

The intended execution flow is:

```text
DEPENDENCIES
  ↓
INPUT
  ↓
SETUP
  ↓
VALIDATION
  ↓
FLOW
```

Conceptually:

- DEPENDENCIES load declarative configuration components and reusable logic components.
- INPUT receives execution requests.
- SETUP prepares execution context.
- VALIDATION verifies all runtime assumptions.
- FLOW coordinates and executes the orchestration process.

A key design goal is:

```text
One place owns the flow.
```

Engine components act as execution owners.

By centralizing orchestration inside the Engine, execution behavior remains explicit, predictable, traceable and easy to modify.
