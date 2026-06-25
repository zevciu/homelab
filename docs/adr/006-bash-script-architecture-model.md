# ADR-006: Bash Script Architecture Model

## Status

Valid

## Date

2026-06-25

## Context

While building Homelab automation, I could not find a simple and broadly applicable convention for structuring Bash scripts.

Different use cases required different levels of complexity:

* small operational scripts,
* reusable automation components,
* larger multi-layered systems.

Without a consistent model, script organization gradually became ad hoc.

---

### Problems Identified

#### 1. Lack of consistent structure

Scripts evolved with different layouts, conventions and responsibilities.

This made code harder to read, navigate, maintain and debug.

#### 2. Poor reuse model

One-dimensional scripts encouraged duplication.

Sourcing other scripts helped reuse but, without architectural boundaries, quickly led to unclear dependencies and growing complexity.

A structured way to partition configuration, logic and execution was missing.

---

### Constraints

#### 1. No external framework

The solution must remain lightweight and rely only on standard scripting techniques.

#### 2. Support both simple and complex automation

The model must support both:

* small standalone scripts,
* larger layered automation systems.

---

## Decision

### Script classification model

A formal script classification model is established.

Scripts are classified using:

```text
Type
└── Structure
    └── Role
```

The model defines two architectural categories (types) and five implementation templates (structures):

```text
Standalone
├── Task
└── Procedure

Component
├── Config
├── Library
└── Engine
```

Each structure owns a distinct responsibility:

```text
Task
→ self-contained executable workflow

Procedure
→ automated manual operation
```

Task represents the default self-contained automation model commonly found in Bash scripting.

Procedure provides a lightweight alternative for operational one-shot activities where introducing a full workflow-oriented structure would provide little value.

```text
Config
→ declarative configuration

Library
→ reusable logic

Engine
→ orchestration and execution ownership
```

Config, Library and Engine form a layered architecture that separates configuration, implementation and orchestration concerns. Conceptually, these components represent responsibilities that would otherwise be embedded inside a Task.

The model is defined by the following documentation set:

```text
script_model.md
coding_convention.md

task.md
procedure.md
config.md
library.md
engine.md
```

Each structure defines its own implementation model and section responsibilities.

Roles on the other hand provide additional specialization and context, but do not change the overall underlying structure.

Skeleton templates demonstrate the intended implementation pattern for each structure.

---

### Alternatives

#### Continue with ad-hoc scripting

Scripts could continue evolving without a formal architecture.

This would preserve maximum flexibility but would also continue increasing inconsistency, duplication and maintenance cost as the repository grows.

---

## Consequences

### Positive

A shared architectural vocabulary is established across the repository.

Configuration, reusable logic and orchestration gain explicit ownership, reducing ambiguity and making automation easier to understand, extend and maintain.

The model also scales from simple operational scripts to larger automation systems while preserving consistent conventions.

---

### Negative

The architecture introduces additional concepts, documentation and templates that must be maintained over time.

New scripts require conscious classification decisions instead of relying on ad-hoc implementation.

---

### Risks

#### 1. Over-engineering

The model may become more complex than the problems it solves.

Mitigation:

* optional sections allow structures to scale with complexity,
* complexity should only be introduced when justified by real use cases,
* a lightweight structure (Procedure) was introduced for simple cases.

#### 2. Model evolution

Future use cases may not fit cleanly into existing structures or roles.

Mitigation:

* review the model periodically,
* evolve structures and roles only through explicit architectural decisions.

---

## Summary

A formal Script Architecture Model is adopted for the repository.

The model introduces a common classification system based on Type, Structure and Role, and establishes five documented structures:

```text
Task
Procedure
Config
Library
Engine
```

The goal is to improve consistency, reuse, maintainability and long-term scalability.

---

*This document is part of the Architecture Decision Records (ADR) series for the Homelab project.*
