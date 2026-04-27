# dotnet Port — TODO

This file tracks the integration work for the dotnet implementation and serves as the
canonical checklist for adding future dotnet versions.

## Quarkus → dotnet10 Concept Mapping

| Concept | Quarkus 3 | dotnet10 |
|---|---|---|
| **HTTP framework** | RESTEasy (JAX-RS `@Path`, `@GET`) | ASP.NET Core Minimal API (`app.MapGet`) |
| **DI container** | CDI (`@ApplicationScoped`, `@Inject`) | `IServiceCollection` (`AddScoped`, constructor injection) |
| **ORM** | Hibernate ORM Panache (`PanacheEntityBase`) | EF Core (`DbContext`, `DbSet<T>`) |
| **DB driver** | `quarkus-jdbc-postgresql` | Npgsql (`Npgsql.EntityFrameworkCore.PostgreSQL`) |
| **Connection pool** | Agroal (built into Quarkus datasource) | EF Core connection pool (Npgsql default) |
| **Health checks** | SmallRye Health (`/health/live`, `/health/ready`) | `AddHealthChecks().AddDbContextCheck<T>()` |
| **Metrics** | Micrometer → OTel OTLP | OTel `WithMetrics` → OTLP (ASP.NET Core + runtime meters) |
| **Traces** | SmallRye OTel, `traceidratio 0.1` | OTel `TraceIdRatioBasedSampler(0.1)` + `AddAspNetCoreInstrumentation()` |
| **Logs** | OTel OTLP (`otel.logs.enabled: true`) | *(not yet wired — `UseOtlpExporter()` API gap in 1.11)* |
| **OTel exporter** | OTLP gRPC `localhost:4317` | OTLP gRPC `localhost:4317` (same default) |
| **JSON serialization** | Jackson (via `quarkus-rest-jackson`) | `System.Text.Json` with source-generated `FruitJsonContext` |
| **Serialization optimization** | Reflection-free serializers (`enable-reflection-free-serializers: true`) | Source-generated context (`TypeInfoResolverChain`) — AOT-safe by design |
| **Config format** | `application.yml` | `appsettings.json` / env vars / `builder.Configuration` |
| **HTTP port** | 8080 (Quarkus default) | 8080 (explicit `UseUrls("http://0.0.0.0:8080")`) |
| **Build output** | `quarkus-run.jar` (fast-jar) | Self-contained binary via `dotnet publish -c Release` |
| **Native image** | GraalVM (`-Pnative`) — production-ready | `PublishAot` — blocked (see Native AOT section) |
| **Test framework** | JUnit 5 + REST Assured + Quarkus DevServices | xUnit + `WebApplicationFactory` + Testcontainers |
| **DB for tests** | Quarkus DevServices (auto-spins PostgreSQL) | Testcontainers (E2E) / mocked repos (unit) |
| **Startup log** | `quarkus3 started in Xs` (built-in) | Custom `ApplicationStarted` callback emitting same pattern |
| **CPU pinning** | `taskset --cpu-list 0-3` via `APP_CMD_PREFIX` | Same `APP_CMD_PREFIX` prepended to `runCmd` in `main.yml` |
| **Memory limit** | `-Xmx512m` via `--jvm-memory` → `config.jvm.memory` | `DOTNET_GCHeapHardLimit` computed from `--jvm-memory` by `xmx_to_dotnet_gc_limit()` in `run-benchmarks.sh` → `config.dotnet.gcHeapHardLimit` |
| **Processor count** | JVM infers from `taskset` cores | `DOTNET_ProcessorCount` set to `config.resources.app_cpus` (count derived from `--cpus-app`) |
| **GC mode** | Server GC (JVM default for server workloads) | `DOTNET_gcServer=1` |

## dotnet10 — Status

### Done ✓

- [x] ASP.NET Core 10 implementation equivalent to the plain Quarkus version
- [x] `scripts/stress.sh` detects dotnet binaries and sets correct runtime env vars
- [x] `scripts/1strequest.sh` detects dotnet binaries and sets correct runtime env vars
- [x] `scripts/perf-lab/main.yml` — `dotnet10` entry in `RUNTIMES` and `RUNTIMECMDS`; `updateScript: skip-version-update` prevents abort when qDup's `update-runtime-version` runs
- [x] `scripts/perf-lab/run-benchmarks.sh` — `dotnet10` in `ALLOWED_RUNTIMES`
- [x] `scripts/perf-lab/helpers/dotnet.yml` — `ensure-dotnet` requirement check
- [x] `scripts/perf-lab/helpers/requirements.yml` — `ensure-dotnet` wired into `ensure-requirements`
- [x] `dotnet10/README.md` documents how to run the dotnet app locally
- [x] `Program.cs` emits a startup log matching the perf-lab `logFileStartedRegex`
- [x] `scripts/remote-setup.sh` — one-command remote host preparation (SSH key install, passwordless sudo, environment verification)
- [x] `README.md` — "Better: Run on a dedicated remote Linux box" section with 3-step workflow and `--repo-url` guidance for local changes
- [x] perf-lab runtime constraints made fair — `main.yml` `runCmd` adds CPU pinning (`taskset` via `APP_CMD_PREFIX`), `DOTNET_gcServer=1`, and `DOTNET_ProcessorCount` from `config.resources.app_cpus`; `DOTNET_GCHeapHardLimit` is computed from `--jvm-memory` via `xmx_to_dotnet_gc_limit()` in `run-benchmarks.sh` so memory limits always match the JVM constraint

### Remaining / Open

- [ ] **E2E tests need a running database in CI.**
  The unit tests (`Dotnet10.Tests.Service.*`) run fine without infrastructure.
  The E2E tests (`Dotnet10.Tests.E2e.*`) require PostgreSQL with seed data.
  Current CI job excludes E2E tests with `--filter "FullyQualifiedName!~Dotnet10.Tests.E2e"`.
  Options:
  - Add Testcontainers (`Testcontainers.PostgreSql`) to `Dotnet10.Tests` so E2E tests
    spin up their own database, matching how Quarkus DevServices works for the JVM jobs.
  - Or start `ghcr.io/quarkusio/postgres-17-perf:main` as a GitHub Actions service
    container and remove the filter.

- [ ] **Dependabot NuGet monitoring.**
  `.github/dependabot.yml` only covers Maven (`package-ecosystem: maven`).
  Add a second entry for `nuget` pointing at `dotnet10/`.

- [ ] **perf-lab: `java -version` calls are misleading for dotnet runtimes.**
  `measure-build-times`, `measure-time-to-first-request`, and `measure-rss`
  all call `sh: java -version` unconditionally. For dotnet this is harmless noise (Java is
  always present because qDup itself is a Java tool), but it clutters the output.
  Consider making the call conditional on `${{RUNTIME.type}} != dotnet`.
  (`test-build` was removed from the allowed tests in the upstream refactor, so it is no
  longer a concern.)

- [ ] **perf-lab: no `--dotnet-version` selection support.** ⚠️ Hard
  `run-benchmarks.sh` lets you pin `--quarkus-version` and `--springboot3/4-version` because
  those are Maven dependency versions overridden at build time with a single property. The .NET
  SDK version is fundamentally different: it is an OS-level installation, not a project
  dependency. Whatever `dotnet` binary is on the `PATH` is what gets used, and `ensure-dotnet`
  in `helpers/dotnet.yml` merely logs it without any selection logic.
  To add proper version selection the following would all be needed:
  - Teach `helpers/dotnet.yml` to download and invoke Microsoft's `dotnet-install.sh` for a
    specific SDK version (mirroring how `ensure-java` / `ensure-graalvm` delegate to SDKMAN).
  - Add a `--dotnet-version` flag to `run-benchmarks.sh` and wire it through to a new qDup
    state variable (e.g. `config.dotnet.version`).
  - Handle SDK activation on the remote host — unlike SDKMAN's `sdk use`, the .NET SDK uses
    `global.json` or environment variables (`DOTNET_ROOT`, `PATH` prepending) to select a
    version, which must persist across the separate SSH commands qDup issues.
  - Decide whether to install into a shared location or a per-run sandbox to avoid races if
    benchmarks are ever run in parallel.

- [ ] **perf-lab: no dotnet profiling support.**
  The JVM runtimes can use async-profiler (JFR / flamegraph). dotnet has equivalent tools:
  `dotnet-trace` (CPU samples → speedscope / chromium), `dotnet-counters`, and Linux `perf`.
  A `scripts/perf-lab/helpers/dotnet-trace.yml` helper could mirror `async-profiler.yml`.

- [ ] **dotnet-native: not feasible yet.** ⛔ Blocked by Microsoft
  A `dotnet10-native` runtime (analogous to `quarkus3-native` / `spring3-native`) cannot be
  added in a like-for-like way with the current application stack. The blockers are fundamental,
  not configuration issues:

  **Why it doesn't work today:**
  - **EF Core**: Query compilation relies on expression trees and reflection that are built and
    evaluated at runtime. Native AOT trims this code away. As of .NET 10, EF Core's Native AOT
    support is still marked experimental and requires switching to interceptors (compile-time
    query pre-compilation via `dotnet ef dbcontext optimize`), which is a significant
    architectural change not present in the Quarkus or Spring implementations.
  - **Npgsql**: Requires explicit compile-time registration of all mapped CLR types
    (`NpgsqlDataSourceBuilder.EnableDynamicJson()` is not AOT-safe). Entity mappings, enum
    converters, and range types must all be declared upfront.
  - **Serialization edge cases**: Even with the source-generated `FruitJsonContext` already in
    place, generic collections and nested DTOs can still fail at runtime because the AOT
    trimmer's static analysis misses types that are only referenced through EF Core's
    internal materializer.
  - **No equivalent of Quarkus build-time extensions**: Quarkus has spent years solving these
    exact problems for Hibernate and Jackson via build-time bytecode generation and
    `@RegisterForReflection`. The .NET ecosystem has no equivalent tooling depth yet.

  **What would need to be true before adding `dotnet10-native`:**
  - EF Core Native AOT support reaches stable/non-experimental status (tracked in
    [dotnet/efcore#29840](https://github.com/dotnet/efcore/issues/29840))
  - `dotnet ef dbcontext optimize` (compiled query interceptors) works correctly with Npgsql
    without requiring application code changes beyond what Quarkus needs
  - The published binary produces identical HTTP behaviour to the JIT version under load
    (no trimming-related `NullReferenceException` or `MissingMethodException` at runtime)
  - Verified by running the full perf-lab test suite without errors across all 3 iterations

  **Checklist for when the above is met:**
  - [ ] Run `dotnet ef dbcontext optimize` and commit the generated interceptors
  - [ ] Add `<PublishAot>true</PublishAot>` and `<TrimmerRootDescriptor>` to `Dotnet10.csproj`
  - [ ] Register all Npgsql type mappings explicitly in `Program.cs`
  - [ ] Add `dotnet10-native` RUNTIMECMD to `main.yml` (same pattern as `quarkus3-native` /
    `spring3-native`, with `buildCmd: "dotnet publish Dotnet10 -c Release -r linux-x64 -o publish"`)
  - [ ] Add `dotnet10-native` to `ALLOWED_RUNTIMES` and `DEFAULT_RUNTIMES` in `run-benchmarks.sh`
  - [ ] Add a `dotnet10-native-build-test` CI job
  - [ ] Run perf-lab end-to-end and confirm zero errors across all iterations before merging

## Adding a Future dotnet Version (e.g., dotnet11)

Every new major dotnet version needs changes in exactly these places.
Work through the checklist top-to-bottom.

### 1. New application directory

```
cp -r dotnet10 dotnet11
```

Inside `dotnet11/`:
- [ ] Rename solution and project files:
  `Dotnet10.sln` → `Dotnet11.sln`, `Dotnet10/` → `Dotnet11/`, `Dotnet10.Tests/` → `Dotnet11.Tests/`
- [ ] Update `<TargetFramework>net10.0</TargetFramework>` → `net11.0` in both `.csproj` files
- [ ] Update all NuGet package versions to their dotnet 11–compatible releases
- [ ] Replace every occurrence of `dotnet10` / `Dotnet10` in source files and namespaces
  with `dotnet11` / `Dotnet11` (including the startup log message in `Program.cs`)
- [ ] Update `dotnet11/README.md`

### 2. `scripts/perf-lab/main.yml`

- [ ] Add `dotnet11` to the `RUNTIMES` list (line ~62)
- [ ] Add a `RUNTIMECMDS` entry (copy from `dotnet10`, update name, dir, and regex):
  ```yaml
  - name: dotnet11
    type: dotnet
    dir: ${{DOTNET11_DIR}}
    updateScript: skip-version-update
    buildCmd: "dotnet publish Dotnet11 -c Release -o publish"
    runCmd: "./publish/dotnet11"
    logFileStartedRegex: ".*dotnet11.+started in.*"
  ```
- [ ] Add `update-state` entry (note: use `${{PROJ_REPO_DIR}}`, not `${{REPO_DIR}}/${{PROJ_REPO_NAME}}`):
  ```yaml
  - set-state: RUN.DOTNET11_DIR ${{PROJ_REPO_DIR}}/dotnet11
  ```
- [ ] Add `output-vars` log line for `DOTNET11_DIR`

### 3. `scripts/perf-lab/run-benchmarks.sh`

- [ ] Add `dotnet11` to `ALLOWED_RUNTIMES` array (line ~338) and `DEFAULT_RUNTIMES` array (line ~339)
- [ ] Add `dotnet11` to the `--runtimes` help text (line ~79)

### 4. `.github/workflows/main.yml`

- [ ] Add a `dotnet11-build-test` job (copy `dotnet-build-test`, change SDK version to
  `11.x` and working-directory to `dotnet11`)

### 5. `README.md`

- [ ] Add `dotnet11` entry to "What's in the repo"
- [ ] Add `stress.sh` / `1strequest.sh` examples for dotnet11

### 6. `scripts/perf-lab/helpers/dotnet.yml`

No change needed — `ensure-dotnet` already checks the generic `dotnet --version`,
which satisfies any installed SDK version.

If the benchmark environment must pin to a specific SDK version (e.g. to prevent a newer
SDK from silently changing compiler behaviour), add a version-pinned variant:
```yaml
ensure-dotnet11:
  - log: Checking for .NET 11 SDK
  - sh: dotnet --version | grep -E '^11\.'
```
and wire it into `requirements.yml` instead of (or alongside) `ensure-dotnet`.

### 7. Dependabot

- [ ] Add a third `updates` entry in `.github/dependabot.yml` for the new directory.
