# ADR-005: Stateful Host-based Firewall Architecture for the Application Server (Docker & Tailscale Integration)

## Status
Valid

## Date
2026-05-17

## Context

The application server initially operated without a dedicated host-level firewall.

Network exposure was implicitly controlled by Docker port publishing, service-level configuration and LAN topology.

---

### Problems Identified

#### 1. Excessive trust model
Without a firewall:
- all interfaces were implicitly trusted,
- services could accidentally become exposed.

---

#### 2. Networking complexity
Adding Tailscale introduced:
- a new ingress interface (`tailscale0`),
- additional forwarding paths,
- interaction between nftables, Docker NAT and Tailscale-managed networking.

Docker-managed NAT chains combined with Tailscale-injected nftables/iptables rules introduced additional routing complexity and expanded the attack surface. 

Incorrect nftables policies could disrupt container networking, NAT, DNS resolution and inter-container communication.

---

## Decision

A stateful nftables firewall was introduced on the host.

The firewall controls:
- INPUT policy,
- FORWARD policy,

while Docker and Tailscale continue managing their own dynamic networking chains.

---

### 1. Default-deny ingress model

The INPUT chain operates in default-drop mode.

Only explicitly approved traffic is allowed:

- DNS (53 TCP/UDP)
- HTTP/HTTPS (80/443 TCP)
- SSH (22 TCP)
- ICMP/ICMPv6

Ingress is restricted to:

- eth0
- tailscale0

Stateful connection tracking is enabled via:

- `ct state established,related accept`

This allows:
- return traffic,
- stable NAT behavior,
- predictable service exposure.

All other interfaces are implicitly denied.

---

### 2. Controlled forwarding between trust zones

The FORWARD chain operates in default-drop mode.

Controlled forwarding is allowed between:

- LAN/Tailscale ↔ Docker
- Docker ↔ Docker

Trusted forwarding interfaces:

- eth0
- tailscale0
- docker0
- br-*
- veth*

Stateful forwarding rules permit:

- established flows,
- Docker bridge networking,
- NAT return traffic.

This prevents accidental forwarding through unmanaged or rogue interfaces.

Docker and Tailscale retain ownership of their dynamically managed NAT and routing chains.

---

## Consequences

### Positive
- Explicit default-deny security model
- Controlled ingress exposure
- Interface-aware trust segmentation
- Deterministic forwarding behavior
- Working Tailscale integration

### Negative
- Increased operational complexity
- More difficult debugging
- Interaction between nftables, Docker and Tailscale requires careful validation

---

### Risks

#### Docker networking disruption
Improper FORWARD rules may break:
- container Internet access,
- bridge networking,
- NAT.

Mitigation:
- preserve Docker-owned NAT chains,
- validate forwarding paths after changes.

---

### Tailscale routing interference
Overlay networking may interact unpredictably with forwarding rules.

Mitigation:
- explicitly allow `tailscale0`.

---

### Future interface sprawl
New interfaces may accidentally bypass intended segmentation.

Mitigation:
- maintain default-drop policy & explicitly enumerate trusted interfaces.

---

## Summary

A stateful nftables firewall was introduced on the application server after integrating Tailscale overlay networking alongside Docker bridge networking.

The resulting architecture implements:
- default-deny ingress filtering,
- interface-aware allowlisting,
- controlled forwarding between LAN, Tailscale and Docker networks,
- stateful connection tracking.

Docker and Tailscale retain ownership of their dynamically managed networking chains, while nftables enforces host-level INPUT and FORWARD policies.

---
*This document is part of the Architecture Decision Records (ADR) series for my Homelab project.*
