time-to-1st-request.sh
======================

Bash script to measure the time to first request (TTFR) of an application.

The script polls a URL until a HTTP 200 response is returned. The time taken from when the script starts until a HTTP 200 response is received is measured and reported to the terminal in milliseconds.

Note: This script does not spawn the application. The application should be started separately (e.g., in the background or in another terminal).


Running
=======

To measure the time to first request for an application, start your application and invoke the script:

```
$ ./time-to-1st-request.sh "http://localhost:8080/fruits"
```

where:

"http://localhost:8080/fruits" - the URL to test

The script will output the time in milliseconds from when it started polling until the first successful HTTP 200 response.