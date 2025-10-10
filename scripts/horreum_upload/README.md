# Horreum Upload

## Setup

1. Create `.env` file with the following entries specific to your horreum installation;

```
HORREUM_USER=
HORREUM_PASS=

JENKINS_HOST=
HORREUM_HOST=
KEYCLOAK_HOST=
KEYCLOAK_REALM=
KEYCLOAK_CLIENT_ID=
```

2. Export environmental params;

```shell
$ export $(cat .env | xargs)
```

3. Create job configuration file, e.g.;

```json
{
    "jobPath": "job/Products/job/Quarkus/job/regression/job/quarkus-startup",
    "artefacts": [
        { 
            "horreumTest": "Quarkus - getting-started - JVM",
            "filePath": "server.url/getting-started.JVM.json",
            "start": "$.build-timestamp",
            "stop": "$.build-timestamp",
            "owner": "perf-team", 
            "schema": "urn:quarkus-quickstart:0.1"
        },
        { 
            "horreumTest": "Quarkus - getting-started - native",
            "filePath": "server.url/getting-started.native.json"
            "start": "$.build-timestamp",
            "stop": "$.build-timestamp",
            "owner": "perf-team", 
            "schema": "urn:quarkus-quickstart:0.1"
        },
        { 
            "horreumTest": "Quarkus - config-quickstart - JVM",
            "filePath": "server.url/config-quickstart.JVM.json"
            "start": "$.build-timestamp",
            "stop": "$.build-timestamp",
            "owner": "perf-team", 
            "schema": "urn:quarkus-quickstart:0.1"
        },
        { 
            "horreumTest": "Quarkus - config-quickstart - native",
            "filePath": "server.url/config-quickstart.native.json"
            "start": "$.build-timestamp",
            "stop": "$.build-timestamp",
            "owner": "perf-team", 
            "schema": "urn:quarkus-quickstart:0.1"
        }
    ]

}
```

4. [Install Jbang](https://www.jbang.dev/download/)


## Run upload

```shell
 $ ./horreumUpload.java -b 1255 -c ./config.json
```

where;

  -b : Jenkins build id

  -c : path to config file creates in step 1