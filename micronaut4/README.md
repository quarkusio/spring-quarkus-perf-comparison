## JVM Mode
To compile for JVM mode:
`./mvnw clean package`

To run in JVM mode:
`java -jar target/micronaut4.jar`

## Native Mode
To compile for native mode:
`../mvnw -DskipTests native:compile -Dexec.mainClass=org.acme.MicronautApplication`

To run in native mode:
`./target/micronaut4`