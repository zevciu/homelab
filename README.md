# Homelab

Evergreen homelab project focused on building and evolving a private, self-hosted local infrastructure.

The primary goals are:
- continuous hands-on learning,
- infrastructure automation,
- and maximizing privacy and local control.

This repository serves as both:
- a real operational environment,
- and a long-term engineering playground for experimenting with infrastructure, networking, automation, and self-hosting concepts.

---

# Environment

## Application Server
- Raspberry Pi 3B running Ubuntu Server
- Docker host for self-hosted services
- Tailscale node for secure remote network access


---

# Philosophy

The project follows several core principles:

- infrastructure as code
- automation first
- self-hosting over third-party dependency
- privacy by default
- incremental evolution

The homelab is treated as a continuously evolving system rather than a static collection of containers or scripts.

---

# Architecture

Architectural decisions are documented through ADRs (Architecture Decision Records).

---

# Repository Structure

```text
docs/    → documentation and ADRs
infra/   → infrastructure and service definitions
ops/     → operational tooling and automation
scripts/ → helper scripts and utilities
```

---

# Current Progress

## ADR-001 — Docker Configuration Automation
Introduced a custom infrastructure automation toolkit featuring:
- Ops/Runtime separation,
- automated config bootstrap workflows,
- state-driven lifecycle management,
- and configuration drift detection.

## ADR-002 — Isolated DNS Stack
Introduced a dedicated DNS architecture based on:
- Pi-hole as the DNS filtering and local DNS management layer,
- and Unbound as a fully recursive resolver performing direct root-to-authoritative DNS resolution without external upstream providers.

# Future Plans

## Application Server
- introduce NGINX as a reverse proxy and centralized ingress layer

## Network Infrastructure
- integrate a managed network switch into the homelab environment for network segmentation and internal traffic management
- build a dedicated pfSense-based router/firewall appliance to gain full control over routing and firewall
