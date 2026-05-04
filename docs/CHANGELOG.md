# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-05-04

### Added
- [Docs] add architecture decision records (ADR-002)
- [Feat] add Pi-hole + Unbound DNS stack via docker-compose
   - introduce Pi-hole container as DNS filtering layer
   - add Unbound recursive resolver container
   - docker_compose.bootstrap.yml: add intermediary docker compose file for bootstrap operation purposes
   - orchestrator_dns.sh: introduce declarative file for provisioning container config files (bootstrap and seed operations)
   - unbound.conf: set basic and required parameters for recursive resolving
   - root.hints: add file required for recursive resolver

### Changed
- [Fix] (update_changelog.sh) handle scope in git header message
- [Refactor] (update_changelog.sh) rewrite structure and fix multiline parsing

## [1.0.2] - 2026-05-03

### Changed
- [Refactor] replace CONFIG_TYPE with declarative INIT_FLOW pipeline
  - cli: introduce step:param execution model (e.g. bootstrap:FILES_MAP)
  - cli: dynamic param resolution (FILES_MAP_<service>)
  - cli: support multiple steps per service (e.g. bootstrap + seed)
  - seed_config: fix skip logic (file-level instead of dir-level)
  - bootstrap_config: mark config as BROKEN on copy failure

- [Fix] bugfix swallowing errors in run(); bugfix silent bootstrap failures

---

## [1.0.1] - 2026-04-23

### Added
- [Docs] add architecture decision records and conventions (ADR-001)
- [Chore] add global helpers
- [Feat] initial docker ops toolkit (ADR-001)

### Fixed
- [Fix] correct commit parsing


---

## [Links]
- [Architecture Decision Records](docs/adr/)
- [Documentation](docs/)
