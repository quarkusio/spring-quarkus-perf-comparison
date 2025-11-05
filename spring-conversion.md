# Converting the Spring application to a Quarkus one with compatibility libraries

It is possible to recreate the application parts of the `quarkus3-spring-compatibility` project with a few steps.
This is a great way of seeing that the Quarkus performance gains are because of the runtime, not the programming model or code of the application.

## Doing the conversion for dev mode

1. Save the `pom.xml`, which we don't want to write by hand: `cp quarkus3-spring-compatibility/pom.xml spring-pom.xml` 
2. Delete the compatibility project (we're about to recreate it from scratch!): `rm -rf quarkus3-spring-compatibility`
3. Replace the spring pom: `mv spring-pom.xml springboot3/pom.xml`
4. Delete the tests, which are hard to convert ([for now](https://github.com/orgs/quarkusio/projects/60)): `rm -rf springboot3/src/test`
5. Start the app, with `(cd springboot3; quarkus dev)`. You'll see a failure and a crash.
6. What's the problem? The `SpringBootApplication` class doesn't compile. The good news is it's not even needed with Quarkus. Delete it.
7. Try `quarkus dev` again, and everything should work. Visiting the endpoint in a browser should work.

## Prod mode and stress testing

Although everything is working in dev mode, if you look at the `application.yml`, you can see it's filled with spring config.
There's no Quarkus database configured. In dev mode, that's fine, because Quarkus auto-starts one as a dev service, but that won't work in prod mode.
So we need to fill in config.

1. Copy the Quarkus config over to the Spring app: `cp ./quarkus3/src/main/resources/application.yml ./springboot3/src/main/resources/application.yml`
2. Build the app `(cd springboot3; ./mvnw clean package)` (don't forget the clean)
3. Run the stress tests: `./scripts/stress.sh springboot3/target/quarkus-app/quarkus-run.jar`

You should see that the throughput almost identical to the throughput of the 'normal' Quarkus app, and more than double that of the Quarkus-free Spring app.