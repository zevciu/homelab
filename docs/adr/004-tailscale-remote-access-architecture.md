# ADR-004: Remote Access Architecture with Tailscale and Static Pseudo-Split DNS

## Status
Valid

## Date
2026-05-18

## Context

Secure remote access to internal homelab services was required.

---

### Problems Identified

#### Remote access exposure model

Direct Internet exposure through router port forwarding would:
- increase attack surface,
- require public ingress hardening,
- complicate TLS and access management.

A secure overlay-based access mechanism was preferred.

---

### Constraints

#### VPN architecture selection

A lightweight remote-access solution was required without introducing:
- self-hosted VPN infrastructure,
- additional gateway appliances,
- complex network reconfiguration.

The selected solution needed to:
- support encrypted overlay networking,
- provide simple device-to-device connectivity,
- minimize infrastructure complexity,
- remain operationally lightweight.

---

## Decision

Tailscale was introduced directly on the application server (host-level) as the remote-access overlay network solution.

Tailscale was selected due to:
- minimal operational overhead,
- fast deployment,
- free-tier suitability for homelab usage,
- mesh VPN architecture.

A static pseudo-split DNS model was adopted to distinguish:
- LAN access,
- remote Tailscale access.

---

### 1. Host-based Tailscale integration

The Tailscale client runs directly on the application server host.

This provides:
- encrypted remote access,
- mesh VPN connectivity,
- service exposure through the tailnet,
- device-level authentication,
- network simplicity through host-level integration.

Remote clients access services through:
- the `tailscale0` interface,
- Tailscale-assigned IP addressing.

No direct public service exposure is required.

---

### 2. Static pseudo-split DNS model

Services are exposed through separate static DNS namespaces:

- `*.home.lab` → LAN address,
- `*.remote.lab` → Tailscale address.

DNS mappings are statically managed through Pi-hole configuration.

This creates a lightweight pseudo-split DNS model without:
- subnet routing,
- dynamic DNS views,
- full LAN exposure through Tailscale.

---

## Alternatives

### 1. Tailscale as a Docker container

Run Tailscale inside a Docker container instead of installing it directly on the host system.

Advantages:
- improved isolation from the host operating system,
- easier configuration portability (infrastructure-as-code),
- straightforward rollback via container lifecycle management.

Disadvantages:
- additional dependency on Docker networking stack correctness,
- potential conflicts between container-managed and host-managed firewall/NAT rules,
- reduced transparency of routing and packet flow compared to host-level daemon.

Overall, this approach increases architectural complexity due to containerized VPN layer without providing meaningful operational benefits in a single-host homelab environment.

---

### 2. Tailscale subnet router

Expose the entire LAN through Tailscale subnet routing.

Advantages:
- single DNS namespace,
- native LAN reachability,
- transparent routing model.

Disadvantages:
- broader trust boundary,
- increased lateral movement risk,
- unnecessary remote exposure of internal infrastructure.

---

### 3. Dynamic split-horizon DNS

Use DNS views or policy-based DNS responses depending on client origin.

Advantages:
- single canonical namespace,
- cleaner service discovery model.

Disadvantages:
- not natively supported by Pi-hole.

---

## Consequences

### Positive
- Secure remote access without public ingress exposure,
- lightweight overlay networking,
- separation between local and remote service access,
- minimal infrastructure complexity,
- predictable DNS behavior.

---

### Negative
- Manual maintenance of static DNS mappings,
- increased naming overhead → duplicated DNS records (`*.home.lab` and `*.remote.lab`),
- no dynamic client-aware DNS resolution.

---

## Risks

### Configuration drift in dual namespace model

The pseudo-split DNS model introduces duplicated service records:
- `*.home.lab`,
- `*.remote.lab`.

This creates risk of:
- inconsistent updates (stale mappings and/or naming divergence).

Mitigation:
- centralize DNS configuration in Docker Compose file,
- standardize naming conventions,
- validate mappings during deployment changes.

---

## Summary

A remote-access architecture based on Tailscale overlay networking was introduced for the application server on the host-level in order to:
- enable secure remote access,
- expose selected services over tailnet,
- provide encrypted overlay networking.

The design avoids direct Internet exposure while enabling authenticated remote access to internal services.

A static pseudo-split DNS model was adopted:
- `*.home.lab` for LAN access,
- `*.remote.lab` for Tailscale access.

This provides lightweight separation between local and remote service discovery without requiring subnet routing or dynamic split-horizon DNS infrastructure.
