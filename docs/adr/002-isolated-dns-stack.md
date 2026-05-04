# ADR-002: Isolated DNS Stack Architecture (Pi-hole + Unbound)

## Status
Valid

## Date
2026-05-04

## Context

DNS in the homelab was either:
- handled by external resolvers (ISP / public DNS), or
- managed in an ad-hoc, inconsistent way.

This caused several issues:

- **No privacy**
  DNS queries were sent to third-party resolvers.

- **No filtering layer**  
  No central ad-blocking or domain control.

- **No ownership of resolution**  
  Full dependency on upstream DNS providers.

- **Weak service discovery**  
  Internal services had no reliable DNS mapping.

### Constraints

- Must remain fully containerized (Docker-native).
- Must integrate with existing Ops/Runtime architecture (ADR-001).
- Must avoid reliance on external DNS resolvers for recursive resolution.
- Must remain lightweight and maintainable on single-node homelab infrastructure.
- Must support future extension (local zones, SRV records, service discovery).

---

## Decision

### 1. Architecture: Split DNS responsibilities

The system is split into two layers:

#### Pi-hole (Edge DNS layer)
- Acts as the entry point for all DNS queries
- Handles:
  - Ad blocking
  - Local DNS records (via dnsmasq-style config)
  - Forwarding of unresolved queries to Unbound

#### Unbound (Recursive resolver)
- Operates as a **fully recursive DNS resolver**
- Queries root servers directly (no upstream resolver dependency)
- Performs full DNS resolution chain:
  root → TLD → authoritative DNS

---

### 2. No upstream resolvers (privacy-first design)
Unbound is explicitly configured to avoid upstream DNS providers.

Instead:
- Root hints are used (`root.hints`)
- DNSSEC validation is enabled (where applicable)
- Queries are resolved iteratively

---

### 3. Pi-hole + Unbound integration
- Pi-hole forwards all DNS queries to Unbound:
  - `unbound#53`
- Pi-hole handles:
  - Filtering (blocklists)
  - Local overrides (A/AAAA/SRV records)
- Unbound handles:
  - Recursive resolution

---

### 4. Local DNS overrides
Custom local records are managed via:
- `a-records.conf`
- `srv-records.conf`

This allows:
- Local service discovery
- Internal domains (LAN-only resolution)
- Static IP mapping for services

---

### 5. Docker network isolation
- Both services run in a dedicated Docker network:
  - `dns-net`
- Only Pi-hole exposes port 53 to host
- Unbound is not directly exposed externally

---

## Privacy vs Anonymity

This architecture improves **privacy**, but does NOT provide **network anonymity**.

### What IS achieved (Privacy improvements)
- No third-party DNS resolvers
- No ISP DNS logging (for DNS queries)
- Local filtering before resolution (Pi-hole)
- Full control over DNS resolution chain
- Reduced external telemetry exposure

### What is NOT achieved (Anonymity limitations)

Although ultimately desired, anonymity is NOT achieved due to:

#### 1. ISP visibility
- ISP can still see:
  - IP connections to root DNS servers
  - Encrypted DNS traffic patterns (if DoT/DoH used elsewhere)

#### 2. IP-level traceability
- This stack does not hide:
  - Public IP address
  - Device identity at network level

#### 3. Authoritative DNS exposure
- Final queried domains are still visible to:
  - Authoritative DNS servers
  - Registry operators

#### 4. Traffic correlation
- DNS resolution can be correlated with:
  - HTTP(S) traffic patterns
  - Timing analysis
  - Network metadata

---

### Conclusion
This system provides:
> **Better privacy, but not anonymity**

To achieve anonymity, additional layers would be required, such as:
- Tor / Onion routing
- VPN tunneling with trusted exit nodes
- Traffic obfuscation layers

To be considered in the future as possible architecture directions. 

---

## Consequences

### Positive

- **DNS sovereignty & improved privacy**
  - No dependency on external resolvers. No query leakage to upstream providers
- **Centralized DNS policy**
  - Filtering controlled via Pi-hole
- **Deterministic resolution path**
  - Fully traceable DNS recursion chain
- **Composable architecture**
  - Pi-hole and Unbound can evolve independently

### Negative

- **Increased operational complexity**
  - Two-layer DNS stack instead of single resolver.
- **More components to maintain**
  - Requires monitoring of both Pi-hole and Unbound. More complex debugging.
- **Slight latency overhead**
  - Recursive resolution is slower than cached forwarders.

---

## Risks

- **Misconfiguration of Unbound recursion**
  - Could break external DNS resolution entirely
  - Mitigation: DNSSEC validation + test queries (dig +trace)

- **Pi-hole forwarding misrouting**
  - Could bypass Unbound if misconfigured
  - Mitigation: enforce strict upstream = unbound only

- **Single-node failure**
  - Entire DNS stack depends on one host
  - Mitigation: acceptable within homelab constraints

---

## Summary

This architecture establishes a **fully self-contained, privacy-preserving DNS subsystem** that:

- removes external DNS dependency
- enforces recursive resolution ownership
- centralizes filtering logic
- integrates cleanly with existing Ops/Runtime automation model (ADR-001).

---
