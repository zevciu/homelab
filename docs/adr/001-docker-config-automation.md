# ADR-001: Architecture for Docker Configuration Management (Ops/Runtime Separation & Automation)

## Status
Superseded by ADR-006

## Date
2026-04-17

## Context
Managing Docker services in a homelab environment (e.g., Pi-hole, Unbound) presented significant operational challenges, particularly during the initial setup and ongoing maintenance phases.

### Problems Identified

#### Manual Bootstrap & Configuration Drift
Initially, bringing up a new service required a tedious, error-prone manual workflow:
1.  **Manual Container Startup**: Starting a temporary container to access its internal configuration.
2.  **Manual File Extraction**: Running `docker cp` to extract default configuration files to the host.
3.  **Manual Editing**: Stopping the container, editing the extracted files on the host, and restarting the container to apply changes.
4.  **Repetition**: This cycle has to be repeated for every service and every configuration update.
5.  **Lack of Version Control**: Configuration files lived alongside runtime data, making it impossible to track changes, revert mistakes, or replicate environments reliably.
6.  **Configuration Drift**: Over time, manual edits or semi-automated edits (done by the running container) in the runtime directory caused the live environment to diverge from the intended configuration, leading to unpredictable behavior.

### Constraints
- Must work within a standard Linux/Docker environment.
- Must minimize external dependencies (avoid heavy orchestration tools like Kubernetes or Ansible for simple services).
- Must ensure safety & idempotency.
- Must be modular and reusable.

## Decision
I have implemented a custom **Ops/Runtime Separation Architecture** driven by a state-based automation engine.

### 1. Strict Directory Separation

    - **Ops Directory** (`ops/config/<service>`): The "Source of Truth." Contains version-controlled configuration files, status markers (`.status`), and backups. Managed via Git.
    - **Runtime Directory** (`<service>`): The "Working Copy." Mounted directly into Docker containers. Excluded from version control.

### 2. Automated Bootstrap Workflow

    - Replaced the manual "start-extract-stop-edit" cycle with a single `bootstrap` command.
    - **Process**:
        1.  Spin up a temporary container.
        2.  Wait for health checks.
        3.  Automatically copy default configs to the Ops directory.
        4.  Stop the container.
        5.  Mark status as `INIT`.
    - This allows to initialize a service with one command, ensuring a consistent baseline.

### 3. State-Driven Lifecycle Management

    - Services track their state: `EMPTY` → `INIT` → `APPLIED` → `EXPORTED`.
    - Commands (`apply`, `export`, `destroy`) validate the current state before proceeding.
    - **Drift Detection**: Automated comparison between Ops and Runtime directories to detect unauthorized changes.
    - **Guard Rails**: `guard_direction` prevents conflicting operations (e.g., blocking `apply` if Runtime has newer changes than Ops).

### 4. Safety & Idempotency

    - **Automatic Backups**: Created before every `apply` or `export` operation.
    - **Confirmation Prompts**: Required for destructive actions (unless `--yes` is used).
    - **Dry-Run Mode**: Simulates actions without executing them.
    - **Idempotent Operations**: Running the same command multiple times yields the same result without side effects.

### 5. Layered Architecture

    - **Layered Design**: The system is divided into three distinct layers to ensure modularity and reusability:
        - **`ops/docker/config/env.sh` (Configuration Layer)**: Defines global paths, arrays (e.g., `SERVICES`), and environment variables. It acts as the single source of truth for environment setup and is sourced by all other components.
        - **`ops/docker/lib/*.sh` (Engine Layer)**: Contains reusable, pure business logic functions (e.g., `compare_dirs`, `get_drift_direction`, `bootstrap_config`). These functions are agnostic to the specific service and focus solely on operations.
        - **`orchestrator_*.sh` (CLI/Orchestration Layer)**: Service-specific entry points (e.g., `orchestrator_dns.sh`). They source `env.sh` and the Engine, then expose a user-friendly CLI interface to dispatch commands to the Engine.
    - **Modularity**: This separation allows new serv ices to be added simply by creating a new orchestrator script and updating `env.sh`, without modifying the core engine logic.

### Alternatives

- **Ansible/Terraform**: Rejected due to high learning curve and overhead for a small-scale homelab.
- **Single Directory Approach**: Rejected due to mixing of edits done manually with the edits done by the running container, preventing effective version control.
- **Manual Management**: Rejected due to the high risk of human error and inability to track configuration history.

## Consequences

### Positive
- **Automated Onboarding**: New services can be bootstrapped instantly without manual file extraction.
- **Full Audit Trail**: Configuration changes are tracked in Git, enabling easy rollbacks and history review.
- **Safety First**: Automatic backups and guard rails prevent accidental data loss and configuration conflicts.
- **Consistency**: Ensures that the running environment always matches the intended configuration (once applied).
- **Maintainability**: Standardized code structure and layered architecture make the system easy to extend, debug, and onboard new services.

### Negative
- **Initial Setup Complexity**: Requires defining the directory structure and environment variables before first use.
- **Shell Limitations**: Being written in Bash, it lacks the robustness of compiled languages for extremely complex logic (though sufficient for this scale).
- **Operational Overhead**: The automation layer adds a slight delay to operations due to validation and backup steps.

### Risks
- **Script Bugs**: Errors in the automation logic could theoretically corrupt files.
    - *Mitigation*: Extensive testing, `--dry-run` mode, and mandatory backups before changes.
- **User Bypass**: Users might manually edit files in the Runtime directory, bypassing the system.
    - *Mitigation*: Education and `guard_direction` warnings that detect and block such drift.
- **Dependency on Docker**: The system relies on `docker compose` being correctly configured.
    - *Mitigation*: Pre-flight checks in the orchestrator script to verify dependencies.

---
*This document is part of the Architecture Decision Records (ADR) series for my Homelab project.*
