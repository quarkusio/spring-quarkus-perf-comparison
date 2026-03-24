time-to-1st-request.sh
======================

Bash script to measure the time to first request (TTFR) of an application.

The script spawns the application, polls a URL using pure bash to create a TCP
connection (via `/dev/tcp`), and reports the elapsed time until the first
HTTP 200 response in nanoseconds. The polling loop is started **before**
the application so there is no timing gap.

Running
=======

To measure the time to first request for an application, invoke the script
with the run command, the target URL, and a log file path:

```
$ ./time-to-1st-request.sh <RUN_CMD> <TARGET_UTL> <LOG_FILE>
```

where:

- `RUN_CMD`    — command to start the application (e.g., `"java -jar myapp.jar"`)
- `TARGET_URL` — URL to poll for availability (e.g., `"http://localhost:8080/fruits"`)
- `LOG_FILE`   — file where application stdout/stderr will be written (e.g., `"app.log"`)

e.g.:
```
$ ./time-to-1st-request.sh "java -jar myapp.jar" \
    "http://localhost:8080/fruits" \
    "app.log"
```

> [!TIP]
> To pin the script to a single CPU core, and the application to a different set of
> cores, invoke it with the `taskset` command, e.g.:
> ```
> $ taskset -c 4 ./time-to-1st-request.sh \
>     "taskset -c 0-3 java -jar myapp.jar" \
>     "http://localhost:8080/fruits" \
>     "app.log"
> ```

The script outputs the TTFR in nanoseconds to stdout in the form:

```
TTFR=<nanoseconds> ns
```
