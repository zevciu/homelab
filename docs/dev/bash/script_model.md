# Script Model

## Purpose

Since there is not an universal convention in Bash scripting I've decided to cook something of my own. This document defines the script classification model used across the repository.

The goal is to provide a consistent way to understand:

- how a script participates in the system,
- how a script is structured,
- what responsibility it fulfills.

The model focuses on architecture and implementation patterns.

---

# 0. Classification Model

Every script is described using three classification levels:

```text
Type
└── Structure
    └── Role
```

Each level answers a different question.

| Level | Question |
|---------|---------|
| Type | How does the script participate in the system? |
| Structure | How is the script built? |
| Role | What responsibility does it fulfill? |

---

## 0.1 Type

Type describes the highest-level architectural category.

A type determines whether a script is:

- self-contained,
- or part of a larger layered architecture.

Types:

```text
Standalone
Component
```

---

## 0.2 Structure

Structure defines how a script is organized internally.

Each structure has its own:

- coding convention,
- file template,
- architectural constraints.

Structures:

```text
Task
Procedure
Config
Library
Engine
```

---

## 0.3 Role

Role provides additional context about the responsibility of a script.

Unlike Structure, a Role does not define a template.

Instead, it explains:

- what kind of data the script manages,
- what responsibility it owns,
- how it is expected to be used.

Roles:

```text
Environment
Blueprint
Helper
Domain Logic
Orchestrator
Runner
```

---

# 1. Type: Standalone
A standalone script is self-contained.

It contains everything required to perform its task and can be executed directly.

Characteristics:

- executable entrypoint,
- owns its execution flow,
- does not require an external engine,
- does not participate in a layered architecture.

---

## 1.1 Structure: Task

A task is a self-contained script designed to achieve a specific goal.

Responsibilities:

- perform a complete workflow,
- own configuration,
- own logic,
- own execution flow.

Examples:

```text
backup_database.sh
generate_report.sh
watch_logs.sh
```

Typical characteristics:

- long-lived or reusable,
- may be interactive,
- may run continuously,
- may expose CLI arguments.

---

### Possible Roles

Not decided yet. Roles for tasks are optional.

Examples:

```text
Task
├── Daemon
├── Generator
├── Monitor
├── Worker
└── Utility
```

I may establish them on-the-go.

---

## 1.2 Structure: Procedure

A procedure is an executable representation of a manual operational process.

Responsibilities:

- encode operational steps,
- improve repeatability,
- reduce operator mistakes,
- serve as executable documentation.

Examples:

```text
install_host_firewall.sh
bootstrap_server.sh
recover_node.sh
```

Typical characteristics:

- one-shot execution,
- infrastructure-focused,
- operational in nature,
- mirrors a manual runbook.

---

### Possible Roles

Roles for procedures are optional.

Examples:

```text
Procedure
├── Installation
├── Migration
├── Recovery
├── Bootstrap
└── Maintenance
```

I may establish them on-the-go.

---

# 2. Type: Component

A component is not intended to be executed independently.

It exists as a building block used by other scripts.

Characteristics:

- reusable,
- focused on a single responsibility,
- participates in a layered architecture,
- typically sourced or invoked by another component.

---

## 2.1 Structure: Config

Declarative configuration layer.

Responsibilities:

- define paths,
- define variables,
- define mappings,
- define settings,
- define declarations consumed by other layers.

Rules:

- no business logic,
- no orchestration,
- no side effects.

---

### 2.1.1. Role: Environment

Defines shared environment configuration.

Examples:

```text
env.sh
```

Responsibilities:

- global paths,
- exports,
- runtime defaults,
- feature flags,
- environment-wide configuration.

The Environment role contains shared configuration that is independent of any specific project.

---

### 2.1.2 Role: Blueprint

Defines project-specific declarations consumed by the engine.

Examples:

```text
dns.sh
edge.sh
monitoring.sh
```

Responsibilities:

- project definitions,
- service declarations,
- initialization flows,
- deployment mappings,
- project-specific configuration.

The Blueprint role contains domain-specific data but no business logic.

---

## 2.2 Structure: Library

Reusable logic layer.

Responsibilities:

- implement reusable functions,
- encapsulate business logic,
- provide utility functions.

Rules:

- no orchestration,
- no CLI handling,
- no direct execution.

---

### 2.2.1 Role: Helper

Generic reusable utility functions.

Examples:

```text
create_dirs.sh
create_files.sh
require_args.sh
```

Responsibilities:

- provide generic utilities,
- remain domain-independent,
- support multiple projects.

Helpers should be broadly reusable.

---

### 2.2.2 Role: Domain Logic

Reusable domain-specific logic.

Examples:

```text
deploy_containers.sh
apply_config.sh
destroy_environment.sh
```

Responsibilities:

- implement domain operations,
- encapsulate project-specific workflows,
- coordinate lower-level helpers.

Domain Logic components contain business logic but no orchestration.

---

## 2.3 Structure: Engine

Execution and orchestration layer.

Responsibilities:

- assemble execution dependencies,
- provide execution entrypoints,
- coordinate execution flow,
- dispatch reusable logic.

Rules:

- minimal business logic,
- no declarative configuration,
- orchestration only.

---

### 2.3.1 Role: CLI

Coordinates execution based on user input.

Examples:

```text
cli.sh
```

Responsibilities:

- parse CLI arguments,
- invoke workflows,
- route commands,
- connect blueprints with libraries.

The CLI role acts as the primary execution inteface of the system.

---

### 2.3.2 Role: Runner

Executes predefined scenarios or workflows.

Examples:

```text
test_runner.sh
```

Responsibilities:

- execute predefined cases,
- automate repetitive execution,
- drive libraries using fixed input,
- suport testing, validation, and automation workflows.

A Runner does not typically expose a rich user-facing interface (as opposed to CLI). Its primary purpose is execution of predefined flows.



# Summary

```text
Standalone
├── Task
│
└── Procedure


Component
├── Config
│   ├── Environment
│   └── Blueprint
│
├── Library
│   ├── Helper
│   └── Domain Logic
│
└── Engine
    └── CLI
    └── Runner
```

This classification model exists to standardize script architecture, improve discoverability, ensure consistent templates, and simplify long-term maintenance across the repository.
