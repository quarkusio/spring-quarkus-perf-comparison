# spring-quarkus-perf-comparison
Performance comparison between Spring Boot and Quarkus

This project contains the following modules:
- [springboot3](springboot3)
    - A Spring Boot 3.x version of the application
- [quarkus3](quarkus3)
    - A Quarkus 3.x version of the application
- [quarkus3-spring-compatibility](quarkus3-spring-compatibility)
    - A Quarkus 3.x version of the application using the Spring compatibility layer
 
## Building

`./mvnw clean verify -Dquarkus.hibernate-orm.sql-load-script=import.sql`

## Application requirements/dependencies
             
- (macOS) You need to have a `timeout` compatible command:
  - Via `coreutils` (installed via Homebrew): `brew install coreutils` but note that this will install lots of GNU utils that will duplicate native commands and prefix them with `g` (e.g. `gdate`)
  - Use [this implementation](https://github.com/aisk/timeout) via Homebrew: `brew install aisk/homebrew-tap/timeout`
  - More options at https://stackoverflow.com/questions/3504945/timeout-command-on-mac-os-x

- Base JVM Version: 21

The application expects a PostgreSQL database to be running on localhost:5432. You can use Docker or Podman to start a PostgreSQL container:

```shell
cd scripts
./infra.sh -s
```

This will start the database, create the required tables and populate them with some data.

To stop the database:

```shell
cd scripts
./infra.sh -d
```

## Scripts

There are some [scripts](scripts) available to help you run the application:
- [`1strequest.sh`](scripts/1strequest.sh)
    - Runs an application X times and computes the time to 1st request and RSS for each iteration as well as an average over the X iterations.
- [`run-requests.sh`](scripts/run-requests.sh)
    - Runs a set of requests against a running application.
- [`infra.sh`](scripts/infra.sh)
    - Starts/stops required infrastructure 
