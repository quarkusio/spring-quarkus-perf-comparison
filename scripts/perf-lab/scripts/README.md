# time_to_1st_request

C program to measure the time to first request (TTFR) of an application.

Spawns an application process and polls a URL until an HTTP 200 response is received, measuring the elapsed time.

## Building

```bash
make
```

## Usage

Run without arguments to see usage instructions:

```bash
./time_to_1st_request
```

Example:
```bash
./time_to_1st_request "java -jar app.jar" /dev/null "http://localhost:8080/health"
```