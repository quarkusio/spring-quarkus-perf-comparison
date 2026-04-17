# CLAUDE.md

## Project Overview

Performance benchmarking suite comparing Spring Boot and Quarkus frameworks. The goal is like-for-like comparisons using equivalent application code (same domain models, same persistence via JPA/Hibernate, same REST endpoints).

## Modules

| Module | Framework | Notes |
|--------|-----------|-------|
| `springboot3/` | Spring Boot 3.x (3.5.x) | Tomcat, Spring Data JPA |
| `springboot4/` | Spring Boot 4.x | |
| `quarkus3/` | Quarkus 3.x (3.32.x) | RESTEasy, Hibernate ORM Panache |
| `quarkus3-virtual/` | Quarkus 3.x | Virtual threads variant |
| `quarkus3-spring-compatibility/` | Quarkus 3.x | Uses Quarkus Spring compatibility layer |

All modules share the same domain: `org.acme` package with Fruit/Store/Address entities, DTOs, mappers, and a REST controller.

## Build

```sh
./mvnw clean verify          # Build all modules
./mvnw clean verify -pl quarkus3  # Build single module
```

- Java 21 required
- Maven wrapper included (`./mvnw`)
- Parent POM is an aggregator only (no shared dependencies)
- Each module manages its own dependencies independently

## Key Technologies

- **Quarkus modules**: Hibernate ORM Panache, REST Jackson, SmallRye Health, Micrometer OpenTelemetry, PostgreSQL JDBC, config via YAML
- **Spring modules**: Spring Data JPA, Spring Web (MVC), Spring Actuator, Hibernate with JCache/Caffeine L2 cache, OpenTelemetry Spring Boot starter, PostgreSQL
- **Testing**: JUnit, AssertJ, REST Assured (Quarkus), Testcontainers (Spring)
- **Native image**: GraalVM support in both Quarkus (`-Pnative`) and Spring (`native-maven-plugin`)

## Infrastructure

PostgreSQL on `localhost:5432`. Managed via scripts:

```sh
cd scripts
./infra.sh -s   # Start DB (Docker/Podman), create tables, seed data
./infra.sh -d   # Stop DB
```

## Benchmarking Scripts

Located in `scripts/`:
- `stress.sh` - Throughput measurement using Hyperfoil (wrk2 bindings)
- `1strequest.sh` - Startup time and RSS measurement
- `run-requests.sh` - Run requests against a running app
- `perf-lab/run-benchmarks.sh` - Full benchmarking automation (used in CI/perf labs)

## Branching Strategy

- `main` - Tuned strategy (reasonable perf tuning allowed)
- `ootb` - Out-of-the-box strategy (no tuning allowed)

## Conventions

- Application code must maintain parity across all modules (same domain, same endpoints, same behavior)
- Changes to architecture (e.g., virtual threads) must be applied to all modules
- Config files use YAML (`application.yml`) in all modules
- `.gitignore` excludes `target/`, IDE files, and `.claude/`

## Things to keep in mind

- When doing `sudo` in qDup scripts, ensure you use the `sudo` script whenever possible rather than doing `- sh: sudo...`
    - The `sudo` script takes a `command` argument
