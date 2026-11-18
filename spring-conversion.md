# Converting the Spring application to a Quarkus one with compatibility libraries

It is possible to recreate the application parts of the `quarkus3-spring-compatibility` project with a few steps.
This is a great way of seeing that the Quarkus performance gains are because of the runtime, not the programming model or code of the application.

## Manual conversion

### Doing the conversion for dev mode

1. Save the `pom.xml`, which we don't want to write by hand: `cp quarkus3-spring-compatibility/pom.xml spring-pom.xml` 
2. Delete the compatibility project (we're about to recreate it from scratch!): `rm -rf quarkus3-spring-compatibility`
3. Replace the spring pom: `mv spring-pom.xml springboot3/pom.xml`
4. Delete the tests, which are hard to convert ([for now](https://github.com/orgs/quarkusio/projects/60)): `rm -rf springboot3/src/test`. To keep some coverage, you can copy across `quarkus3/src/test/java/org/acme/e2e` end-to-end tests after deleting the Spring ones.
5. Start the app, with `(cd springboot3; quarkus dev --clean)`. You'll see a failure and a crash.
6. What's the problem? The `SpringBootApplication` class doesn't compile. The good news is it's not even needed with Quarkus. Delete it.
7. The `config/` package (`L2CacheConfiguration`, `GraalVMConfig`, `L2CacheRuntimeHints`) also won't compile. These classes wire up Caffeine as a JCache provider for Hibernate's L2 cache and register GraalVM native-image hints — all Spring-specific plumbing. Quarkus handles Hibernate L2 cache automatically, so delete the whole `config/` directory: `rm -rf springboot3/src/main/java/org/acme/config`
8. Try `quarkus dev` again, and everything should work. Visiting the endpoint in a browser should work. 

### Prod mode and stress testing

Although everything is working in dev mode, if you look at the `application.yml`, you can see it's filled with spring config.
There's no Quarkus database configured. In dev mode, that's fine, because Quarkus auto-starts one as a dev service, but that won't work in prod mode.
So we need to fill in config.

1. Copy the Quarkus config over to the Spring app: `cp ./quarkus3/src/main/resources/application.yml ./springboot3/src/main/resources/application.yml`
2. Build the app `(cd springboot3; ./mvnw clean package)` (don't forget the clean)
3. Run the stress tests: `./scripts/stress.sh springboot3/target/quarkus-app/quarkus-run.jar`

You should see that the throughput almost identical to the throughput of the 'normal' Quarkus app, and more than double that of the Quarkus-free Spring app.

## Automated conversion

You can run the automated conversion script to perform all the manual steps above:

```shell
./scripts/spring-conversion.sh [output-directory]
```

The script accepts an optional output directory argument. The Spring Boot source and the Quarkus app providing the config and e2e tests are derived from the directory name:
- **Default** (no argument): Creates/recreates `quarkus3-spring-compatibility` (from `springboot3`, using `quarkus3`)
- **`quarkus4-spring4-compatibility`**: Creates/recreates that directory (from `springboot4`, using `quarkus4`)
- **`springboot3`** / **`springboot4`**: Converts that Spring Boot application in place (using `quarkus3` / `quarkus4` respectively)

Examples:
```shell
# Convert to quarkus3-spring-compatibility (default)
./scripts/spring-conversion.sh

# Convert springboot3 in place
./scripts/spring-conversion.sh springboot3

# Convert to quarkus4-spring4-compatibility (from springboot4, using quarkus4)
./scripts/spring-conversion.sh quarkus4-spring4-compatibility

# Convert springboot4 in place
./scripts/spring-conversion.sh springboot4
```

The manual steps above are written for the Quarkus 3 / Spring Boot 3 pair. For Quarkus 4, substitute `quarkus4`, `springboot4` and `quarkus4-spring4-compatibility`.

**Quarkus 4 note:** `springboot4`'s `FruitService` uses Micrometer `@Observed`/`@ObservationKeyValue` instead of OpenTelemetry `@WithSpan`. These compile in the converted app (Micrometer observation is on the classpath via the Quarkus Micrometer extension), but have not been verified to emit spans there, a possible observability difference from the Quarkus-native apps.

This script will automatically execute all the conversion steps, build the application, and provide instructions for running stress tests.