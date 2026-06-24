# Procedure

Procedure is a manual operation encoded as an executable script.

## Classification

```text
Type:      Standalone
Structure: Procedure
Role:      [Optional]
```

## Purpose

Procedure scripts exist to:

* automate manual execution,
* improve repeatability,
* reduce operator mistakes,
* document operational actions.

A Procedure represents a sequence of actions that would otherwise be executed manually.

The script serves two purposes simultaneously:

* as documentation describing what was done,
* as automation capable of repeating the same operation.

A Procedure models a sequence of operational actions rather than software architecture. Unlike a Task structure, its primary purpose is to organize operational knowledge rather than application logic.

Procedures are typically used for one-shot or infrequently repeated activities.

---

## Roles

Roles are optional.

Examples:

```text
Installation
Migration
Recovery
Bootstrap
Maintenance
```

Roles provide additional context about the operational purpose of the procedure but do not change the structure.

---

## Sections

### Section Layout

Procedures follow this structure:

```text
METADATA
 └── CLASSIFICATION

PRECONDITIONS

OPERATIONS
```

---

### Section Responsibilities

#### METADATA

Procedure files use the following metadata structure:

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
# STRUCTURE: PROCEDURE
# ROLE: <role>
# ##############################################################################
```

##### I. Classification

Identifies the script according to the Script Model.

---

#### PRECONDITIONS

Defines everything required before the operational procedure can be executed safely.

Typical responsibilities:

- verify privileges,
- validate required files,
- validate required resources,
- derive local paths,
- verify environmental assumptions.

This section is what transforms a manual procedure into an executable script.

Without PRECONDITIONS, OPERATIONS would merely be a sequence of manual commands.

PRECONDITIONS allow the procedure to verify assumptions automatically, fail early, and execute safely in a repeatable manner.

A Procedure should fail as early as possible when preconditions are not satisfied.

---

#### OPERATIONS

Contains the operational procedure itself.

This section should mirror the sequence of actions an operator would normally perform manually.

Typical responsibilities:

* execute operational steps,
* perform installations,
* deploy configuration,
* restart services,
* run maintenance actions,
* execute recovery actions.

Operations should be organized as a readable sequence of steps.

The structure of OPERATIONS should prioritize readability and operational understanding over software abstraction.

---

## Summary

The intended execution flow is intentionally simple:

```text
PRECONDITIONS
  ↓
OPERATIONS
```

Unlike other structures, a Procedure is not focused on organizing software architecture.

Its purpose is to organize operational knowledge.

Conceptually:

* PRECONDITIONS verify that the procedure can be executed safely.
* OPERATIONS perform the actual operational work.

A key design goal is:

```text
Manual operations made repeatable.
```

A Procedure should remain recognizable as the original manual process.

Reading the script should explain what an operator would do manually.

Executing the script should perform those same actions automatically and consistently.

The structure exists to transform operational knowledge into a repeatable, executable form while keeping the procedure easy to understand, review, and maintain.
