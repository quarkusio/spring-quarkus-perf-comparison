# Framework Performance Benchmarking TCK

## 1. Overview

This document defines the requirements for implementing a new framework module in the performance benchmarking suite. The goal is to enable **like-for-like performance comparison** across Java frameworks by guaranteeing architectural, behavioral, and data parity.

The application is a simple "Fruit Store" domain: fruits sold at stores with per-store pricing. Every module implements the same domain model, the same REST API, the same data access patterns, and seeds the same test data. The only things that differ are the framework-specific annotations, DI mechanisms, and configuration idioms.

### Compliance Levels

- **MUST** — Required for a fair comparison. Violations invalidate benchmark results.
- **SHOULD** — Strongly recommended. Deviations require justification.
- **MAY** — Allowed to vary. This is the framework-specific adaptation surface.

### Reference Implementation

The `quarkus3/` module serves as the reference implementation. When in doubt, match its behavior. The `domain` and `dto` packages are byte-identical across all modules and MUST be copied verbatim.

---

## 2. Package Structure

Root package: `org.acme`

### Required Packages

| Package | Purpose | Portable? |
|---------|---------|-----------|
| `org.acme.domain` | JPA entity classes | Yes — copy verbatim |
| `org.acme.dto` | Data Transfer Objects | Yes — copy verbatim |
| `org.acme.repository` | Data access layer | No — framework-specific |
| `org.acme.service` | Business logic | No — framework-specific |
| `org.acme.rest` | REST controller | No — framework-specific |

### Optional Packages

| Package | Purpose |
|---------|---------|
| `org.acme.mapping` | Entity/DTO mappers (implementation-specific — any mapping approach is acceptable) |
| `org.acme.config` | Framework-specific configuration classes |
| `org.acme` (root) | Framework entry point class (e.g., `SpringBoot3Application`) |

---

## 3. Domain Model

All entity classes reside in `org.acme.domain`. They MUST be **copied verbatim** from the reference implementation — they use only `jakarta.persistence.*`, `org.hibernate.annotations.*`, and `jakarta.validation.*` annotations with no framework-specific imports.

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
| `id` | `StoreFruitPriceId` | `@EmbeddedId` |
| `store` | `Store` | `@MapsId("storeId")`, `@ManyToOne(fetch = EAGER, optional = false)`, `@JoinColumn(name = "store_id", nullable = false)`, `@Fetch(FetchMode.SELECT)`, `@Cache(usage = CacheConcurrencyStrategy.NONSTRICT_READ_WRITE)` |
| `fruit` | `Fruit` | `@MapsId("fruitId")`, `@ManyToOne(fetch = LAZY, optional = false)`, `@JoinColumn(name = "fruit_id", nullable = false)` |
| `price` | `BigDecimal` | `@NotNull`, `@DecimalMin(value = "0.00", message = "Price must be >= 0")`, `@Digits(integer = 10, fraction = 2)`, `@Column(nullable = false, precision = 12, scale = 2)` |

Constructors: no-arg + `(Store store, Fruit fruit, BigDecimal price)`. Setters for `store` and `fruit` MUST maintain composite key consistency by reconstructing `StoreFruitPriceId`.

---

## 4. DTOs

All DTO classes reside in `org.acme.dto`. They MUST be **copied verbatim**. All are Java records.

### 4.1 AddressDTO

```
record AddressDTO(
    @NotBlank(message = "Address is mandatory") String address,
    @NotBlank(message = "City is mandatory") String city,
    @NotBlank(message = "Country is mandatory") String country
)
```

Compact constructor validates all fields are non-null and non-blank, throws `IllegalArgumentException`.

### 4.2 StoreDTO

```
record StoreDTO(Long id, String name, String currency, AddressDTO address)
```

Compact constructor validates `name` and `currency` are non-null and non-blank.

### 4.3 StoreFruitPriceDTO

```
record StoreFruitPriceDTO(StoreDTO store, float price)
```

Compact constructor validates `price >= 0`. Note: uses `float` (not `BigDecimal`).

### 4.4 FruitDTO

```
record FruitDTO(
    Long id,
    @NotBlank(message = "Name is mandatory") String name,
    String description,
    List<StoreFruitPriceDTO> storePrices
)
```

Compact constructor validates `name` is non-null. Defaults `storePrices` to empty `ArrayList` if null.

---

## 5. Entity/DTO Mapping

The service layer MUST convert between domain entities and DTOs. The mapping approach is **framework-specific** — implementations MAY use any mechanism (hand-written mappers, MapStruct, framework-native conversion, etc.) as long as the REST API produces correct JSON output conforming to the OpenAPI spec (`openapi.yml`).

### Reference Approach

The existing modules use hand-written static mapper classes in `org.acme.mapping`:

| Class | Methods |
|-------|---------|
| `AddressMapper` | `static AddressDTO map(Address)`, `static Address map(AddressDTO)` |
| `StoreMapper` | `static StoreDTO map(Store)`, `static Store map(StoreDTO)` |
| `StoreFruitPriceMapper` | `static StoreFruitPriceDTO map(StoreFruitPrice)` (one-way only) |
| `FruitMapper` | `static FruitDTO map(Fruit)`, `static Fruit map(FruitDTO)` |

This pattern is not required. New implementations MAY adopt it or use any alternative.

---

## 6. Package Dependency Rules

The following directed dependency graph defines which packages MAY reference which. Any dependency not listed is forbidden.

```
rest       → service, dto
service    → repository, dto, domain (+ any mapping mechanism)
repository → domain
dto        → (no org.acme.* dependencies)
domain     → (no org.acme.* dependencies)
config     → (unrestricted — framework-specific)
```

### Key Prohibitions

- `rest` MUST NOT access `domain` or `repository`
- `dto` MUST NOT access `domain`
- `domain` MUST NOT access any other `org.acme.*` package
- `repository` MUST NOT access `dto`, `service`, or `rest`

---

## 7. REST API Contract

### Endpoints

Base path: `/fruits`

| Method | Path | Request Body | Success | Failure |
|--------|------|-------------|---------|---------|
| `GET` | `/fruits` | — | `200`, `List<FruitDTO>` | — |
| `GET` | `/fruits/{name}` | — | `200`, `FruitDTO` | `404` (empty body) |
| `POST` | `/fruits` | `FruitDTO` (JSON, validated) | `200`, `FruitDTO` | — |

### Controller Requirements

- Class: `FruitController` in `org.acme.rest`
- MUST depend only on `FruitService` (no direct repository, mapper, or domain access)
- MUST delegate all business logic to `FruitService`
- The `GET /{name}` endpoint MUST return the framework's idiomatic response wrapper to enable 404 handling (`Response` for JAX-RS, `ResponseEntity` for Spring MVC, etc.)
- The `POST` endpoint MUST apply bean validation on the request body

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

### Framework-Specific Annotations (MAY vary)

| Concern | Quarkus (JAX-RS) | Spring (MVC) |
|---------|-------------------|--------------|
| Controller class | `@Path("/fruits")` | `@RestController` + `@RequestMapping("/fruits")` |
| GET | `@GET` | `@GetMapping` |
| POST | `@POST` + `@Consumes` | `@PostMapping(consumes = ...)` |
| Path parameter | `@PathParam` | `@PathVariable` |
| Request body | (implicit) | `@RequestBody` |
| Response wrapper | `jakarta.ws.rs.core.Response` | `ResponseEntity` |

---

## 8. Service Layer

### Contract

Class: `FruitService` in `org.acme.service`

| Method | Signature | Transaction |
|--------|-----------|-------------|
| `getAllFruits` | `List<FruitDTO> getAllFruits()` | SUPPORTS / read-only |
| `getFruitByName` | `Optional<FruitDTO> getFruitByName(String name)` | SUPPORTS / read-only |
| `createFruit` | `FruitDTO createFruit(FruitDTO fruitDTO)` | REQUIRED (default) |

### Requirements

- MUST be a singleton/application-scoped bean (framework annotation varies)
- MUST depend on `FruitRepository`
- MUST convert between `Fruit` entities and `FruitDTO` (mapping mechanism MAY vary)
- Read operations MUST use SUPPORTS propagation
- Write operation MUST use default (REQUIRED) propagation
- Transaction annotation MAY vary (`jakarta.transaction.Transactional` vs `org.springframework.transaction.annotation.Transactional`)

### Observability

All three methods MUST be instrumented with named spans:

| Method | Span Name | Parameter Attributes |
|--------|-----------|---------------------|
| `getAllFruits` | `FruitService.getAllFruits` | — |
| `getFruitByName` | `FruitService.getFruitByName` | `arg.name` on the `name` parameter |
| `createFruit` | `FruitService.createFruit` | `arg.fruit` on the `fruitDTO` parameter |

Instrumentation mechanism MAY vary:
- OpenTelemetry API: `@WithSpan` / `@SpanAttribute`
- Micrometer Observation API: `@Observed` / `@ObservationKeyValue`
- Other framework-native mechanisms that produce equivalent spans

---

## 9. Repository

### Contract

Class or interface: `FruitRepository` in `org.acme.repository`

| Operation | Signature | Transaction |
|-----------|-----------|-------------|
| Find by name | `Optional<Fruit> findByName(String name)` | SUPPORTS / read-only |
| List all | Returns `List<Fruit>` | SUPPORTS / read-only |
| Persist | Saves a `Fruit` entity | (inherited) |

### Implementation (MAY vary)

| Framework | Approach | List all | Persist |
|-----------|----------|----------|---------|
| Quarkus | `implements PanacheRepository<Fruit>` (class) | `listAll()` | `persist(entity)` |
| Spring | `extends JpaRepository<Fruit, Long>` (interface) | `findAll()` | `save(entity)` |
| Other | Framework-equivalent repository pattern | equivalent | equivalent |

MUST depend only on `org.acme.domain`.

---

## 10. Data and Schema

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

## 11. Configuration and Runtime

### Mandatory Settings (MUST match)

| Concern | Required Value | Rationale |
|---------|---------------|-----------|
| Database | PostgreSQL on `localhost:5432`, database `fruits`, user/password `fruits` | Shared infrastructure |
| Jackson serialization | `NON_EMPTY` inclusion | JSON output parity |
| Hibernate L2 cache | Enabled for `Store` entity and `StoreFruitPrice.store` association | Cache behavior parity |
| Hibernate batch fetch size | 16 | Query behavior parity |
| Open Session in View | Disabled | Performance parity |
| Garbage collector | ParallelGC (`-XX:+UseParallelGC`) | GC behavior and overhead parity |
| Trace sampling ratio | 10% (`0.1`) | Observability overhead parity |
| Health endpoint | Exposed | Operational parity |
| Metrics endpoint | Prometheus-compatible, exposed | Observability parity |

### Framework-Specific Settings (MAY vary)

- Configuration file format and property naming
- L2 cache provider setup mechanism
- Connection pool implementation (SHOULD target ~50 connections)
- HTTP server configuration
- GraalVM / native image configuration
- OpenTelemetry integration wiring
- Dev services / test database provisioning

---

## 12. Observability

### Distributed Tracing

- All `FruitService` methods MUST emit named spans (see Section 8)
- Trace sampling: 10%
- JDBC connections SHOULD be instrumented for tracing

### Metrics

A Prometheus-compatible metrics endpoint MUST be exposed via the framework's native actuator/health mechanism.

### Health

A health check endpoint MUST be exposed.

---

## 13. Testing

### Repository Tests

- Class: `FruitRepositoryTests` in `org.acme.repository`
- MUST run against a real PostgreSQL (testcontainers, dev services, or equivalent)
- MUST run within a transaction that rolls back after each test
- MUST test `findByName`: persist `Fruit(null, "Grapefruit", "Summer fruit")`, query by name, assert name, description, and that `id` is non-null and `> 2L`

### Controller Tests

- Class: `FruitControllerTests` in `org.acme.rest`
- MUST mock the **repository** layer (not the service layer)
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

## 14. Framework-Specific Adaptation Surface

The following aspects are explicitly **allowed to vary** between implementations. They represent the boundary where frameworks use their idiomatic approaches.

### DI and Bean Lifecycle

| Concern | Examples |
|---------|----------|
| Bean declaration | `@ApplicationScoped`, `@Service`, `@Singleton`, `@jakarta.inject.Singleton` |
| Injection style | Constructor injection, field injection, method injection — any style is acceptable |
| Injection trigger | `@Inject` (CDI), `@Autowired` (Spring), implicit, etc. |

### REST Framework

See the table in Section 7.

### Repository Implementation

See the table in Section 9.

### Transaction Annotations

| Framework | Import |
|-----------|--------|
| Quarkus (CDI) | `jakarta.transaction.Transactional` with `TxType.SUPPORTS` |
| Spring | `org.springframework.transaction.annotation.Transactional` with `propagation = SUPPORTS, readOnly = true` |
| Other | Framework equivalent |

### Configuration Classes

The `org.acme.config` package is fully framework-specific. Examples from existing modules:

- `L2CacheConfiguration` — programmatic JCache/Caffeine setup (Spring)
- `GraalVMConfig` — native image runtime hints (Spring)
- `DataSourceConfig` — JDBC telemetry wrapping (Spring Boot 4)
- `OpentelemetryConfiguration` — metrics beans (Spring Boot 4)

A new framework MAY add any configuration classes needed, provided they reside in `org.acme.config`.

### Entity/DTO Mapping

The mapping approach is entirely up to the implementor. Examples:

| Approach | Used By |
|----------|---------|
| Hand-written static mapper classes in `org.acme.mapping` | quarkus3, springboot3, springboot4 |
| MapStruct or similar code-generation mapper | (alternative) |
| Framework-native conversion | (alternative) |
| Inline mapping in service methods | (alternative) |

The only requirement is that the REST API produces correct JSON conforming to the OpenAPI spec.

### Application Entry Point

- Quarkus: no explicit main class needed
- Spring Boot: `@SpringBootApplication` class in `org.acme`
- Other: framework equivalent

---

## 15. Future: ArchUnit Enforcement

The following rules are candidates for automated enforcement:

| Category | Rule | Enforceable? |
|----------|------|-------------|
| Packages | All production classes reside in specified packages | Yes |
| Packages | Package dependency rules (Section 6) | Yes |
| Domain | Entity classes exist with correct names and annotations | Yes |
| Domain | Entity classes have no framework-specific imports | Yes |
| DTOs | DTO classes are Java records | Yes |
| DTOs | DTOs have no dependencies on domain package | Yes |
| Service | FruitService depends only on repository + dto + domain (+ mapping) | Yes |
| REST | FruitController depends only on service + dto | Yes |
| Repository | FruitRepository depends only on domain | Yes |
| Data | Seed data is identical across modules | No (file comparison) |
| Config | Required runtime properties are set | No (integration tests) |

---

## 16. Compliance Checklist

When creating a new module (e.g., `micronaut/`):

1. Copy `org.acme.domain` and `org.acme.dto` verbatim from the reference implementation
2. Copy the seed data SQL file (adjust filename if needed by framework convention)
3. Implement entity/DTO mapping using your preferred approach (see Section 5)
4. Implement `FruitRepository` in `org.acme.repository` using framework-idiomatic data access
5. Implement `FruitService` in `org.acme.service` matching the contract in Section 8
6. Implement `FruitController` in `org.acme.rest` matching the API contract in Section 7
7. Add any framework-specific configuration in `org.acme.config`
8. Configure mandatory settings from Section 11 using framework-native configuration
9. Write tests per Section 13
10. Verify the REST API returns identical JSON for identical requests (conforming to `openapi.yml`)
11. Verify all ArchUnit rules pass (when available)
