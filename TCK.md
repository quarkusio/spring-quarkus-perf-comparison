# Framework Performance Benchmarking TCK — OOTB (Out of the Box)

## 1. Overview

This document defines the requirements for implementing a new framework module in the performance benchmarking suite under the **OOTB (out-of-the-box) strategy**. The goal is to enable **like-for-like performance comparison** across Java frameworks by guaranteeing architectural, behavioral, and data parity — while keeping the application as simple as possible with **no tuning**.

The OOTB strategy prioritizes simplicity and measures the default performance experience each framework provides:

- **No DTOs or mapping layer** — domain entities are serialized directly to JSON
- **No service layer** — the REST controller depends directly on the repository
- **No observability** — no distributed tracing, no metrics endpoint, no health checks
- **No tuning** — no connection pool sizes, batch fetch sizes, or other configuration adjustments

The application is a simple "Fruit Store" domain: fruits sold at stores with per-store pricing. Every module implements the same domain model, the same REST API, the same data access patterns, and seeds the same test data. The only things that differ are the framework-specific annotations, DI mechanisms, and configuration idioms.

> [!NOTE]
> For the **tuned** strategy TCK, see the [`main` branch](https://github.com/quarkusio/spring-quarkus-perf-comparison/blob/main/TCK.md).

### Compliance Levels

- **MUST** — Required for a fair comparison. Violations invalidate benchmark results.
- **SHOULD** — Strongly recommended. Deviations require justification.
- **MAY** — Allowed to vary. This is the framework-specific adaptation surface.

### Reference Implementation

The `quarkus3/` module on the `ootb` branch serves as the reference implementation. When in doubt, match its behavior. The `domain` package MUST be copied verbatim (it contains `@JsonIgnore` annotations required for correct serialization when returning entities directly).

---

## 2. Package Structure

Root package: `org.acme`

### Required Packages

| Package | Purpose | Portable? |
|---------|---------|-----------|
| `org.acme.domain` | JPA entity classes | Yes — copy verbatim |
| `org.acme.repository` | Data access layer | No — framework-specific |
| `org.acme.rest` | REST controller | No — framework-specific |

### Optional Packages

| Package | Purpose |
|---------|---------|
| `org.acme.config` | Framework-specific configuration classes (e.g., L2 cache setup) |
| `org.acme` (root) | Framework entry point class (e.g., `SpringBoot3Application`) |

### Packages NOT Present

The following packages from the tuned strategy are **not used** in the OOTB strategy:

- `org.acme.dto` — no DTOs; entities are returned directly
- `org.acme.mapping` — no mapping layer needed
- `org.acme.service` — no service layer; controller accesses repository directly

---

## 3. Domain Model

All entity classes reside in `org.acme.domain`. They MUST be **copied verbatim** from the reference implementation. They use `jakarta.persistence.*`, `org.hibernate.annotations.*`, `jakarta.validation.*`, and `com.fasterxml.jackson.annotation.JsonIgnore` annotations.

> [!NOTE]
> The `@JsonIgnore` annotations on `StoreFruitPrice` are the only Jackson import in the domain layer. They are necessary because entities are serialized directly — without DTOs to control the JSON shape, `@JsonIgnore` prevents circular references and hides internal composite key fields.

### 3.1 Address

`@Embeddable` Java record embedded into the `stores` table.

| Field | Type | Annotations |
|-------|------|-------------|
| `address` | `String` | `@Column(nullable = false)`, `@NotBlank(message = "Address is mandatory")` |
| `city` | `String` | `@Column(nullable = false)`, `@NotBlank(message = "City is mandatory")` |
| `country` | `String` | `@Column(nullable = false)`, `@NotBlank(message = "Country is mandatory")` |

### 3.2 Fruit

| Annotation | Value |
|------------|-------|
| `@Entity` | |
| `@Table` | `name = "fruits"` |

| Field | Type | Annotations |
|-------|------|-------------|
| `id` | `Long` | `@Id`, `@GeneratedValue(strategy = SEQUENCE, generator = "fruits_seq")`, `@SequenceGenerator(name = "fruits_seq", sequenceName = "fruits_seq", allocationSize = 1)` |
| `name` | `String` | `@Column(nullable = false, unique = true)`, `@NaturalId`, `@NotBlank(message = "Name is mandatory")` |
| `description` | `String` | (none) |
| `storePrices` | `List<StoreFruitPrice>` | `@OneToMany(mappedBy = "fruit")` |

Constructors: no-arg + `(Long id, String name, String description)`. Standard getters/setters. `toString()` using `StringJoiner`.

### 3.3 Store

| Annotation | Value |
|------------|-------|
| `@Entity` | |
| `@Table` | `name = "stores"` |
| `@Cacheable` | (L2 cache) |

| Field | Type | Annotations |
|-------|------|-------------|
| `id` | `Long` | `@Id`, `@GeneratedValue(strategy = SEQUENCE, generator = "stores_seq")`, `@SequenceGenerator(name = "stores_seq", sequenceName = "stores_seq", allocationSize = 1)` |
| `name` | `String` | `@Column(nullable = false, unique = true)`, `@NaturalId`, `@NotBlank(message = "Name is mandatory")` |
| `currency` | `String` | `@Column(nullable = false)`, `@NotBlank(message = "Currency is mandatory")` |
| `address` | `Address` | `@Embedded` |

Constructors: no-arg + `(Long id, String name, Address address, String currency)`. Standard getters/setters. `toString()` using `StringJoiner`.

### 3.4 StoreFruitPriceId

`@Embeddable` Java record implementing `Serializable`. Composite primary key.

| Field | Type | Annotations |
|-------|------|-------------|
| `storeId` | `Long` | `@Column(nullable = false)` |
| `fruitId` | `Long` | `@Column(nullable = false)` |

Convenience constructor: `(Store store, Fruit fruit)` — extracts IDs with null-safety.

### 3.5 StoreFruitPrice

| Annotation | Value |
|------------|-------|
| `@Entity` | |
| `@Table` | `name = "store_fruit_prices"` |

| Field | Type | Annotations |
|-------|------|-------------|
| `id` | `StoreFruitPriceId` | `@EmbeddedId`, **`@JsonIgnore`** |
| `store` | `Store` | `@MapsId("storeId")`, `@ManyToOne(fetch = EAGER, optional = false)`, `@JoinColumn(name = "store_id", nullable = false)`, `@Fetch(FetchMode.SELECT)`, `@Cache(usage = CacheConcurrencyStrategy.NONSTRICT_READ_WRITE)` |
| `fruit` | `Fruit` | `@MapsId("fruitId")`, `@ManyToOne(fetch = LAZY, optional = false)`, `@JoinColumn(name = "fruit_id", nullable = false)`, **`@JsonIgnore`** |
| `price` | `BigDecimal` | `@NotNull`, `@DecimalMin(value = "0.00", message = "Price must be >= 0")`, `@Digits(integer = 10, fraction = 2)`, `@Column(nullable = false, precision = 12, scale = 2)` |

Constructors: no-arg + `(Store store, Fruit fruit, BigDecimal price)`. Setters for `store` and `fruit` MUST maintain composite key consistency by reconstructing `StoreFruitPriceId`.

**`@JsonIgnore` rationale:**
- `id` — The composite key (`StoreFruitPriceId`) is an internal persistence detail that should not be exposed in the API.
- `fruit` — Prevents circular serialization: `Fruit → storePrices → StoreFruitPrice → fruit → Fruit → ...`

---

## 4. REST API Contract

### Endpoints

Base path: `/fruits`

| Method | Path | Request Body | Success | Failure |
|--------|------|-------------|---------|---------|
| `GET` | `/fruits` | — | `200`, `List<Fruit>` | — |
| `GET` | `/fruits/{name}` | — | `200`, `Fruit` | `404` (empty body) |
| `POST` | `/fruits` | `Fruit` (JSON, validated) | `200`, `Fruit` | — |

### Controller Requirements

- Class: `FruitController` in `org.acme.rest`
- MUST depend directly on `FruitRepository` (there is no service layer)
- MUST NOT access any other packages besides `repository` and `domain`
- The `GET /{name}` endpoint MUST return the framework's idiomatic response wrapper to enable 404 handling (`Response` for JAX-RS, `ResponseEntity` for Spring MVC, etc.)
- The `POST` endpoint MUST apply bean validation on the request body
- The `POST` endpoint MUST be annotated with `@Transactional` (since there is no service layer to manage transactions)

### JSON Serialization

Jackson MUST be configured with `NON_EMPTY` serialization inclusion. Response shape for a fruit:

```json
{
  "id": 1,
  "name": "Apple",
  "description": "Hearty fruit",
  "storePrices": [
    {
      "store": {
        "id": 1,
        "name": "Store 1",
        "currency": "USD",
        "address": {
          "address": "123 Main St",
          "city": "Anytown",
          "country": "USA"
        }
      },
      "price": 1.29
    }
  ]
}
```

Note: `StoreFruitPrice.id` and `StoreFruitPrice.fruit` are excluded from the JSON output by `@JsonIgnore` on the entity fields.

### Framework-Specific Annotations (MAY vary)

| Concern | Quarkus (JAX-RS) | Spring (MVC) |
|---------|-------------------|--------------|
| Controller class | `@Path("/fruits")` | `@RestController` + `@RequestMapping("/fruits")` |
| GET | `@GET` | `@GetMapping` |
| POST | `@POST` + `@Consumes` | `@PostMapping(consumes = ...)` |
| Path parameter | `@PathParam` | `@PathVariable` |
| Request body | (implicit) | `@RequestBody` |
| Response wrapper | `jakarta.ws.rs.core.Response` | `ResponseEntity` |
| Validation | `@Valid` (implicit body) | `@Valid @RequestBody` |

---

## 5. Package Dependency Rules

The following directed dependency graph defines which packages MAY reference which. Any dependency not listed is forbidden.

```
rest       → repository, domain
repository → domain
domain     → (no org.acme.* dependencies)
config     → (unrestricted — framework-specific)
```

### Key Prohibitions

- `rest` MUST NOT access `config`
- `domain` MUST NOT access any other `org.acme.*` package
- `repository` MUST NOT access `rest`

---

## 6. Repository

### Contract

Class or interface: `FruitRepository` in `org.acme.repository`

| Operation | Signature | Transaction |
|-----------|-----------|-------------|
| Find by name | `Optional<Fruit> findByName(String name)` | (none) |
| List all | Returns `List<Fruit>` | (none) |
| Persist | Saves a `Fruit` entity | (inherited from caller) |

> [!NOTE]
> Unlike the tuned strategy, repository methods do NOT have `@Transactional(SUPPORTS)` annotations. Transaction management is minimal — only the `POST` controller method has `@Transactional`.

### Implementation (MAY vary)

| Framework | Approach | List all | Persist |
|-----------|----------|----------|---------|
| Quarkus | `implements PanacheRepository<Fruit>` (class) | `listAll()` | `persist(entity)` |
| Spring | `extends JpaRepository<Fruit, Long>` (interface) | `findAll()` | `save(entity)` |
| Other | Framework-equivalent repository pattern | equivalent | equivalent |

MUST depend only on `org.acme.domain`.

---

## 7. Data and Schema

### Database Tables

| Table | Columns | Primary Key | Sequence |
|-------|---------|-------------|----------|
| `fruits` | `id` (bigint), `name` (varchar, unique, not null), `description` (varchar) | `id` via `fruits_seq` | `fruits_seq` (allocationSize=1) |
| `stores` | `id` (bigint), `name` (varchar, unique, not null), `currency` (varchar, not null), `address` (varchar, not null), `city` (varchar, not null), `country` (varchar, not null) | `id` via `stores_seq` | `stores_seq` (allocationSize=1) |
| `store_fruit_prices` | `store_id` (bigint, FK), `fruit_id` (bigint, FK), `price` (numeric(12,2), not null) | Composite (`store_id`, `fruit_id`) | — |

Schema MAY be generated by Hibernate or by explicit DDL, but the result MUST be equivalent.

### Seed Data

The seed data SQL MUST be identical across all modules (only the filename may differ: `import.sql` for Quarkus, `data.sql` for Spring, etc.).

Contents:
- **10 fruits** (IDs 1-10): Apple, Pear, Banana, Orange, Strawberry, Mango, Grape, Pineapple, Watermelon, Kiwi
- **8 stores** (IDs 1-8): Store 1 through Store 8, with specific addresses, cities, countries, and currencies (USD, EUR, GBP, JPY, CAD, AUD, EUR, MXN)
- **34 store-fruit-price records** with specific (store_id, fruit_id, price) triples
- Sequence restarts: `fruits_seq RESTART WITH 11`, `stores_seq RESTART WITH 9`

Reference file: `quarkus3/src/main/resources/import.sql`

---

## 8. Configuration and Runtime

### Mandatory Settings (MUST match)

| Concern | Required Value | Rationale |
|---------|---------------|-----------|
| Database | PostgreSQL on `localhost:5432`, database `fruits`, user/password `fruits` | Shared infrastructure |
| Jackson serialization | `NON_EMPTY` inclusion | JSON output parity |
| Hibernate L2 cache | Enabled for `Store` entity and `StoreFruitPrice.store` association | Cache behavior parity |

### Explicitly NOT Required

The following settings from the tuned strategy are **not used** in the OOTB strategy. Modules MUST NOT include them:

- Hibernate batch fetch size tuning
- Connection pool size tuning
- Open Session in View configuration
- Observability / distributed tracing configuration
- Trace sampling ratio
- Health endpoint
- Metrics endpoint

### Framework-Specific Settings (MAY vary)

- Configuration file format and property naming
- L2 cache provider setup mechanism
- HTTP server configuration
- GraalVM / native image configuration
- Dev services / test database provisioning

---

## 9. Testing

### Repository Tests

- Class: `FruitRepositoryTests` in `org.acme.repository`
- MUST run against a real PostgreSQL (testcontainers, dev services, or equivalent)
- MUST run within a transaction that rolls back after each test
- MUST test `findByName`: persist `Fruit(null, "Grapefruit", "Summer fruit")`, query by name, assert name, description, and that `id` is non-null and `> 2L`

### Controller Tests

- Class: `FruitControllerTests` in `org.acme.rest`
- MUST mock the **repository** layer
- MUST use a shared `createFruit()` helper that builds:
  - `Fruit(1L, "Apple", "Hearty Fruit")` with one `StoreFruitPrice`:
    - `Store(1L, "Some Store", Address("123 Some St", "Some City", "USA"), "USD")`
    - `price = BigDecimal.valueOf(1.29)`

| Test | Behavior | Key Assertions |
|------|----------|----------------|
| `getAll` | Mock list-all → one fruit | 200, size=1, all fields including nested store/address/price |
| `getFruitFound` | Mock findByName("Apple") → fruit | 200, all fields |
| `getFruitNotFound` | Mock findByName("Apple") → empty | 404 |
| `addFruit` | POST `{"name":"Grapefruit","description":"Summer fruit"}` | 200, name and description in response |

- All tests MUST verify mock interactions (`verify` + `verifyNoMoreInteractions`)

### End-to-End Tests (OPTIONAL)

MAY include integration tests in `org.acme.e2e` that run against the full application stack without mocks.

### Test Infrastructure (MAY vary)

| Concern | Quarkus | Spring | Other |
|---------|---------|--------|-------|
| Test annotation | `@QuarkusTest` | `@SpringBootTest` | equivalent |
| Mock injection | `@InjectMock` | `@MockitoBean` | equivalent |
| HTTP testing | REST Assured | MockMvc | equivalent |
| Database | Dev services | Testcontainers | equivalent |
| Transaction rollback | `@TestTransaction` | `@Transactional` | equivalent |

---

## 10. Framework-Specific Adaptation Surface

The following aspects are explicitly **allowed to vary** between implementations. They represent the boundary where frameworks use their idiomatic approaches.

### DI and Bean Lifecycle

| Concern | Examples |
|---------|----------|
| Bean declaration | `@ApplicationScoped`, `@Service`, `@Singleton`, `@jakarta.inject.Singleton` |
| Injection style | Constructor injection, field injection, method injection — any style is acceptable |
| Injection trigger | `@Inject` (CDI), `@Autowired` (Spring), implicit, etc. |

### REST Framework

See the table in Section 4.

### Repository Implementation

See the table in Section 6.

### Transaction Annotations

| Framework | Import |
|-----------|--------|
| Quarkus (CDI) | `jakarta.transaction.Transactional` |
| Spring | `org.springframework.transaction.annotation.Transactional` |
| Other | Framework equivalent |

> [!NOTE]
> In the OOTB strategy, only the controller's `POST` method requires `@Transactional`. There are no `SUPPORTS` annotations on repository or service methods.

### Configuration Classes

The `org.acme.config` package is fully framework-specific. Examples from existing modules:

- `L2CacheConfiguration` — programmatic JCache/Caffeine setup (Spring)
- `GraalVMConfig` — native image runtime hints (Spring)

A new framework MAY add any configuration classes needed, provided they reside in `org.acme.config`.

### Application Entry Point

- Quarkus: no explicit main class needed
- Spring Boot: `@SpringBootApplication` class in `org.acme`
- Other: framework equivalent

---

## 11. Future: ArchUnit Enforcement

The following rules are candidates for automated enforcement:

| Category | Rule | Enforceable? |
|----------|------|-------------|
| Packages | All production classes reside in specified packages | Yes |
| Packages | Package dependency rules (Section 5) | Yes |
| Domain | Entity classes exist with correct names and annotations | Yes |
| Domain | Entity classes have no framework-specific imports (except `@JsonIgnore`) | Yes |
| REST | FruitController depends only on repository + domain | Yes |
| Repository | FruitRepository depends only on domain | Yes |
| Data | Seed data is identical across modules | No (file comparison) |
| Config | Required runtime properties are set | No (integration tests) |

---

## 12. Compliance Checklist

When creating a new module (e.g., `micronaut/`):

1. Copy `org.acme.domain` verbatim from the reference implementation (includes `@JsonIgnore` annotations on `StoreFruitPrice`)
2. Copy the seed data SQL file (adjust filename if needed by framework convention)
3. Implement `FruitRepository` in `org.acme.repository` using framework-idiomatic data access
4. Implement `FruitController` in `org.acme.rest` matching the API contract in Section 4
5. Add any framework-specific configuration in `org.acme.config`
6. Configure mandatory settings from Section 8 using framework-native configuration
7. Write tests per Section 9
8. Verify the REST API returns identical JSON for identical requests (conforming to `openapi.yml`)
9. Verify all ArchUnit rules pass (when available)
