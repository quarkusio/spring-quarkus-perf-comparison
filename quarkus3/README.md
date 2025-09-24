## JVM Mode
To compile for JVM mode:
`./mvnw clean package`

To run in JVM Mode:
`java -jar target/quarkus-app/quarkus-run.jar`

## Native Mode
To compile for native mode:
`./mvnw clean package -Pnative`

To run in native mode:
`target/app-runner`