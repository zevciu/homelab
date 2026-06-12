# Config

Config is a declarative configuration component.

## Classification

```text
Type:      Component
Structure: Config
Role:      Environment | Blueprint
```

## Purpose

Config components define configuration data used by other components.

They should:

- remain declarative,
- define configuration values and relationships,
- expose configuration through variables,
- avoid execution logic.

Config defines data. It does not execute behavior.

---

## Roles

### Environment

Defines shared environment configuration.

Examples:

- repository paths,
- workspace locations,
- global defaults,
- feature flags,
- exported variables.

### Blueprint

Defines project-specific configuration.

Examples:

- project identity,
- managed services,
- initialization flows,
- deployment mappings,
- project-specific declarations.

---

## Sections

### Section Layout

Config components follow this structure:

```text
METADATA
 └── CLASSIFICATION

CONFIGURATION
 ├── DECLARATIONS
 ├── DERIVATIONS
 └── EXPORTS (optional)
```

### Section Responsibilities

#### METADATA

Config files use the following basic metadata structure:

```bash
# ##############################################################################
# METADATA
# ##############################################################################
# FILE: <file_name>
# PURPOSE: <description>
#
# ------------------------------------------------------------------------------
# CLASSIFICATION
# ------------------------------------------------------------------------------
# TYPE: COMPONENT
# STRUCTURE: CONFIG
# ROLE: <role>
# ##############################################################################
```

---

#### CONFIGURATION

Contains all configuration definitions.

Configuration should not:

- perform orchestration,
- execute commands,
- contain business logic,
- mutate runtime state.

##### I. DECLARATIONS

Defines source configuration values.

Responsibilities:

- define defaults,
- define feature flags,
- define project data,
- define service declarations.

Declarations represent information that exists independently.

They should not depend on values derived later in the file.

##### II. DERIVATIONS

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

##### III. EXPORTS (optional)

Exports configuration values for external consumers.

Only export values that are intended to be consumed outside the component.

---

## Summary

The intended configuration flow is:

```text
DECLARATIONS
  ↓
DERIVATIONS
  ↓
EXPORTS (optional)
```

Conceptually:

- DECLARATIONS define source configuration values.
- DERIVATIONS compute values from existing configuration.
- EXPORTS expose selected values to external consumers.

A key design goal is:

```text
Configure once, use everywhere.
```

The Config component takes care of all configuration concerns in a centralized manner.
