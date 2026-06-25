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
- Docker engine for self-hosted services
- Tailscale node for secure remote network access

---

# Philosophy

The project follows several core principles:

- self-hosting over third-party dependency
- infrastructure as code
- automation first
- privacy by default
- incremental evolution

---

# Architecture

Architectural decisions are documented through ADRs (Architecture Decision Records).

```mermaid
graph TD

    %% =========================
    %% WAN / INTERNET
    %% =========================

    subgraph Internet["Internet (WAN)"]
        User[Admin Device]
        TailscaleGW["Tailscale Mesh VPN<br/>"]
    end

    %% =========================
    %% NETWORK BOUNDARY
    %% =========================

    subgraph NetworkBoundary["Network Boundary"]
        ISP[ISP Router / Gateway]
    end

    %% =========================
    %% LOCAL NETWORK
    %% =========================

    subgraph LocalNetwork["Local Network (LAN)"]

        LANClients["LAN Clients<br/>(PC, Mobile, TV)"]

        subgraph EdgeNode["Edge node (Raspberry Pi 3B – Ubuntu Server Host OS)"]

            TailscaleClient["Tailscale VPN Client<br/>(Host Daemon)"]

            subgraph DockerEngine["Docker Engine"]

                Nginx["Nginx Reverse Proxy<br/>(Ports: 80)"]

                subgraph edgeNet["edge-net"]
                    Nginx
                end

                subgraph appNet["app-net"]
                    OtherServices["Other Services<br/>(Media, Tools, etc.)"]
                end

                subgraph dnsNet["dns-net"]
                    PiHole["Pi-hole<br/>DNS Filtering & Gateway<br/>(Port: 53)"]
                    Unbound["Unbound<br/>Recursive Resolver"]
                end

            end

            Orchestrator["Custom Orchestrator<br/>(Local Bash Scripts)"]

            InvisibleBottom[ ]

            %% Layout helpers (Links 0 & 1)
            DockerEngine ~~~ Orchestrator
            Orchestrator ~~~ InvisibleBottom

        end
    end

    %% =========================
    %% CONNECTIONS
    %% =========================

    %% USER FLOW (Link 2)
    User -->|Secure Access| TailscaleGW

    %% TAILSCALE FLOWS (Links 3-6)
    TailscaleGW -. Encrypted Tunnel .-> ISP
    ISP -->|"LAN (Ethernet)"| TailscaleClient
    TailscaleClient -->|"HTTP :80<br/>via tailscale0"| Nginx
    TailscaleClient -->|"DNS :53<br/>via tailscale0"| PiHole

    %% LAN CLIENT FLOWS (Links 7-8)
    LANClients -->|DNS :53</br>via eth0| PiHole
    LANClients -->|HTTP :80</br>via eth0| Nginx

    %% DNS STACK FLOWS (Links 9-10)
    PiHole -->|Forward Query| Unbound
    Unbound -->|"Recursive DNS Queries<br/>via ISP Gateway"| ISP

    %% NGINX ROUTING FLOWS (Links 11-12)
    Nginx -->|"Route :80<br/>(attached: app-net)"| OtherServices
    Nginx -->|"Route :80 Admin UI<br/>(attached: dns-net)"| PiHole

    %% ORCHESTRATOR FLOWS (Links 13-16)
    Orchestrator -.->|Manages config| Nginx
    Orchestrator -.->|Manages config| PiHole
    Orchestrator -.->|Manages config| Unbound
    Orchestrator -.->|Manages config| OtherServices

    %% =========================
    %% SUBGRAPH STYLING
    %% =========================

    %% Outer containers (Darkest Grey)
    style Internet fill:#D1D5DB,stroke:#9CA3AF,stroke-width:1px,color:#111827
    style NetworkBoundary fill:#D1D5DB,stroke:#9CA3AF,stroke-width:1px,color:#111827
    style LocalNetwork fill:#D1D5DB,stroke:#9CA3AF,stroke-width:1px,color:#111827

    %% Nested infra (Medium Grey)
    style EdgeNode fill:#E5E7EB,stroke:#4B5563,stroke-width:3px,color:#111827

    %% Innermost (Lightest Grey)
    style DockerEngine fill:#F3F4F6,stroke:#6B7280,stroke-width:3px,color:#111827

    %% Docker Networks
    style edgeNet fill:#DBEAFE,stroke:#2563EB,stroke-width:1px,stroke-dasharray: 5 5,color:#111827
    style appNet fill:#DBEAFE,stroke:#2563EB,stroke-width:1px,stroke-dasharray: 5 5,color:#111827
    style dnsNet fill:#DBEAFE,stroke:#2563EB,stroke-width:1px,stroke-dasharray: 5 5,color:#111827

    %% =========================
    %% NODE STYLING
    %% =========================

    %% Neutral nodes
    style User fill:#FFFFFF,stroke:#6B7280,stroke-width:2px,color:#111827
    style LANClients fill:#FFFFFF,stroke:#6B7280,stroke-width:2px,color:#111827
    style OtherServices fill:#FFFFFF,stroke:#6B7280,stroke-width:2px,color:#111827
    style Orchestrator fill:#FFFFFF,stroke:#6B7280,stroke-width:2px,color:#111827
    style ISP fill:#FFFFFF,stroke:#6B7280,stroke-width:2px,color:#111827

    %% Tailscale
    style TailscaleGW fill:#FFFFFF,stroke:#4F46E5,stroke-width:2px,color:#111827
    style TailscaleClient fill:#FFFFFF,stroke:#4F46E5,stroke-width:2px,color:#111827

    %% Nginx
    style Nginx fill:#FFFFFF,stroke:#047857,stroke-width:2px,color:#111827

    %% DNS Stack
    style PiHole fill:#FFFFFF,stroke:#991B1B,stroke-width:2px,color:#111827
    style Unbound fill:#FFFFFF,stroke:#991B1B,stroke-width:2px,color:#111827

    %% Invisible helper
    style InvisibleBottom fill:none,stroke:none

    %% =========================
    %% LINK STYLING
    %% =========================

    %% Link 2 - User (Grey)
    linkStyle 2 stroke:#6B7280,stroke-width:1.5px,color:#6B7280

    %% Links 3-6
    %% 3 = TailscaleGW -> ISP
    linkStyle 3 stroke:#4F46E5,stroke-width:1.5px,stroke-dasharray:5 5,color:#4F46E5

    %% 4 = ISP -> TailscaleClient
    linkStyle 4 stroke:#6B7280,stroke-width:1.5px,color:#6B7280

    %% 5-6 = TailscaleClient flows
    linkStyle 5 stroke:#4F46E5,stroke-width:1.5px,color:#4F46E5
    linkStyle 6 stroke:#4F46E5,stroke-width:1.5px,color:#4F46E5

    %% Links 7-8 = LANClients flows (Grey)
    linkStyle 7 stroke:#6B7280,stroke-width:1.5px,color:#6B7280
    linkStyle 8 stroke:#6B7280,stroke-width:1.5px,color:#6B7280

    %% Links 9-10 = DNS Stack flows (Red)
    linkStyle 9 stroke:#991B1B,stroke-width:1.5px,color:#991B1B
    linkStyle 10 stroke:#991B1B,stroke-width:1.5px,color:#991B1B

    %% Links 11-12 = Nginx flows (Green)
    linkStyle 11 stroke:#047857,stroke-width:1.5px,color:#047857
    linkStyle 12 stroke:#047857,stroke-width:1.5px,color:#047857

    %% Links 13-16 = Orchestrator flows (Grey dashed)
    linkStyle 13 stroke:#6B7280,stroke-width:1.5px,stroke-dasharray:5 5,color:#6B7280
    linkStyle 14 stroke:#6B7280,stroke-width:1.5px,stroke-dasharray:5 5,color:#6B7280
    linkStyle 15 stroke:#6B7280,stroke-width:1.5px,stroke-dasharray:5 5,color:#6B7280
    linkStyle 16 stroke:#6B7280,stroke-width:1.5px,stroke-dasharray:5 5,color:#6B7280
```

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

## ADR-001 — Docker Configuration Automation [Superseded by ADR-006]
Introduced a custom infrastructure automation toolkit featuring:
- Ops/Runtime separation, automated config bootstrap workflows, state-driven lifecycle management, and configuration drift detection.

## ADR-002 — Isolated DNS Stack
Introduced a dedicated DNS architecture based on:
- Pi-hole as the DNS filtering and local DNS management layer,
- and Unbound as a fully recursive resolver performing direct root-to-authoritative DNS resolution without external upstream providers.

## ADR-003 — Centralized Edge Gateway Architecture (NGINX)
Introduced a centralized NGINX reverse proxy layer and Docker network segmentation model:
- edge-net / app-net / dns-net separation
- single HTTP ingress point
- internal service routing via Docker DNS

## ADR-004 — Remote Access Architecture with Tailscale
Introduced secure remote access using Tailscale:
- encrypted mesh VPN connectivity
- host-level Tailscale deployment
- static pseudo-split DNS model (*.home.lab / *.remote.lab)

## ADR-005 — Stateful Application Server Firewall Architecture
Introduced host-level nftables firewall integrated with Docker and Tailscale:
- default-deny INPUT/FORWARD policies
- interface-aware filtering (eth0, tailscale0, docker networks)
- controlled forwarding for container networking

## ADR-006 - Bash Script Architecture Model
Introduced a formal Bash scripting architecture model for the repository:
- script classification framework
- self-contained and layered automation patterns
- shared conventions and implementation templates

# Future Plans

## Application Server
- implement local PKI infrastructure for internal service certificates
- extend NGINX with TLS/SSL termination

## Network Infrastructure
- integrate a managed network switch into the homelab environment for network segmentation and internal traffic management
- build a dedicated pfSense-based router/firewall appliance to gain full control over routing and firewall
