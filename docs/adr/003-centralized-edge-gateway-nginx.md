# ADR-003: Centralized Edge Gateway Architecture (NGINX)

## Status
Valid

## Date
2026-05-15

## Context

Initially:
- services were either exposed directly on host ports, or
- reachable only internally via Docker networking.

### Problems Identified

#### 1. Flat shared Docker network

All containers operated within a shared Docker network scope without clear separation. Containers had unnecessary lateral visibility and unrestricted network reachability by default.

Such a flat topology weakens isolation boundaries, increases accidental coupling between services, and makes future ingress/security policies harder to enforce.

---

#### 2. Lack of ingress abstraction

Applications had no unified entry point.

Clients would need to access services via:
- raw IP addresses
- custom ports
- service-specific endpoints

instead of a centralized DNS-driven routing model.

---

#### 3. Direct container exposure

Without a reverse proxy, applications would require:
- individual host port mappings
- manual port management
- direct accessibility from the host network

This would:
- increase attack surface,
- reduce architectural consistency,
- make future TLS/authentication difficult to centralize.

---

## Decision

A centralized NGINX-based edge gateway architecture was introduced.

NGINX acts as:
- the single ingress point for HTTP traffic,
- a reverse proxy for internal services,
- a controlled inter-network bridge between isolated Docker segments.

A network segmentation model was introduced in place of flat topology.

---

### 1. Network segmentation model

The environment is split into three dedicated Docker networks:

| Network   | Purpose                                  |
|------------|------------------------------------------|
| edge-net  | External ingress / DMZ-style entry zone |
| app-net   | Internal application network            |
| dns-net   | Infrastructure-only DNS subsystem       |

This establishes:
- logical separation between ingress, application, and infrastructure traffic,
- explicit trust boundaries between network zones,
- reduced lateral visibility between containers.

---

### 2. Centralized ingress model

NGINX is the only service responsible for exposing HTTP services to the host and acts as the only bridge node between otherwise isolated networks.

NGINX is connected to:
- edge-net
- app-net
- dns-net

All other services remain restricted to their dedicated network scope. HTTP ports of internal applications are not exposed directly.

This establishes:
- a single externally reachable HTTP entry point,
- routing to internal applications,
- preservation of network isolation boundaries.

---

### 3. Reverse proxy routing model

Routing is performed using hostname-based virtual hosts.

NGINX forwards requests internally using Docker DNS service discovery. Containers are referenced by service/container name rather than static IP addresses.

This establishes:
- stable routing independent of container IP changes,
- elimination of direct host exposure for internal services,
- simplified onboarding of new services.

---

## Consequences

### Positive

#### Centralized ingress & simpler exposure model
- All HTTP traffic flows through a single controlled entry point.
- Internal applications remain hidden from direct host exposure.
- Future HTTPS/TLS rollout can be implemented centrally.

#### Stronger network isolation
- Infrastructure (`dns-net`) and applications (`app-net`) remain logically separated.
- NGINX acts as the explicitly controlled mediation layer between trust zones.
- Reduces unnecessary lateral visibility between containers.

#### Improved maintainability & scalability
- New services can be integrated without changing the overall exposure strategy.
- Docker-native DNS discovery removes dependency on static IP assignments.
- Routing behavior becomes standardized across the environment.

---

### Negative

#### NGINX becomes critical infrastructure
- Failure or misconfiguration of the reverse proxy affects all externally reachable services.
- The ingress layer becomes a central operational dependency.

#### Increased operational overhead
- Reverse proxy configuration must be maintained as services grow.

---

## Risks

### Single Point of Failure
- NGINX outage blocks access to all proxied services.
- Mitigation: acceptable within current homelab scope.

### NGINX misconfiguration
- Could unintentionally expose internal services.
- Mitigation: strict network segmentation and minimal host port exposure.

---

## Summary

This decision introduces a centralized NGINX-based edge gateway architecture using segmented Docker networks and a Hub-and-Spoke topology.

### Docker network layout
- `edge-net` → ingress / DMZ-style zone
- `app-net` → internal application network
- `dns-net` → infrastructure-only DNS network

### What is achieved
- centralized HTTP ingress through a single controlled gateway,
- elimination of direct exposure of internal applications,
- preservation of isolation between ingress, application, and infrastructure layers,
- controlled cross-network routing through NGINX,
- Docker-native hostname-based service discovery,
- architectural foundation for future HTTPS and authentication layers.

---
*This document is part of the Architecture Decision Records (ADR) series for my Homelab project.*
