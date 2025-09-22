# spring-quarkus-perf-comparison
Performance comparison between Spring Boot and Quarkus

This project contains the following modules:
- [springboot3](springboot3)
    - A Spring Boot 3.x version of the application
- [quarkus3](quarkus3)
    - A Quarkus 3.x version of the application
- [quarkus3-spring-compatibility](quarkus3-spring-compatibility)
    - A Quarkus 3.x version of the application using the Spring compatibility layer

## Application requirements/dependencies

- Base JVM Version: 21

The application expects a PostgreSQL database to be running on localhost:5432. You can use Docker or Podman to start a PostgreSQL container:

### Docker

```shell
docker run -it --rm=true --name fruits -p 5432:5432 -e POSTGRES_USER=fruits -e POSTGRES_PASSWORD=fruits -e POSTGRES_DB=fruits postgres:17
```

### Podman

```shell
podman run -it --rm=true --name fruits -p 5432:5432 -e POSTGRES_USER=fruits -e POSTGRES_PASSWORD=fruits -e POSTGRES_DB=fruits postgres:17
```

## Scripts

There are some [scripts](scripts) available to help you run the application:
- [`1strequest.sh`](scripts/1strequest.sh)
    - Runs an application X times and computes the time to 1st request and RSS for each iteration as well as an average over the X iterations.
- [`run-requests.sh`](scripts/run-requests.sh)
    - Runs a set of requests against a running application.
