#!/usr/bin/env bash
set -euo pipefail

# Function to display usage information
usage() {
    echo "Usage: $(basename "$0") RUN_CMD TARGET_URL LOG_FILE"
    echo ""
    echo "Measures the time to first request (TTFR) for an application."
    echo ""
    echo "Arguments:"
    echo "    RUN_CMD     Command to start the application (e.g., \"java -jar app.jar\")"
    echo "    TARGET_URL  URL to poll for availability (e.g., \"http://localhost:8080/health\")"
    echo "    LOG_FILE    Path to file where application logs will be written"
    echo ""
    echo "Example:"
    echo "    $(basename "$0") \"java -jar myapp.jar\" \"http://localhost:8080/api\" \"app.log\""
    echo ""
    echo "Output:"
    echo "    Prints TTFR in nanoseconds to stdout"
    exit 1
}

# Validate number of arguments
if [ "$#" -ne 3 ]; then
    echo "Error: Invalid number of arguments (expected 3, got $#)" >&2
    echo >&2
    usage
fi

RUN_CMD="$1"
TARGET_URL="$2"
LOG_FILE="$3"

# Temporary file to use for writing end timestamp
END_TS_FILE=$(mktemp)

# Parse host and port from TARGET_URL (e.g. http://localhost:8080/fruits)
# Strip off the scheme (http://)
URL_NO_SCHEME="${TARGET_URL#http://}"
# Get host and port
HOST_PORT="${URL_NO_SCHEME%%/*}"
# Get host
HOST="${HOST_PORT%%:*}"
# Get port
PORT="${HOST_PORT##*:}"
if [ -z "$PORT" ]; then
    PORT=80
fi
# Get the path by stripping off the host:port
if [[ "$URL_NO_SCHEME" == */* ]]; then
  URL_PATH="/${URL_NO_SCHEME#*/}"
else
  URL_PATH="/"
fi

# Detect the date command to use
if date +%s%N &>/dev/null; then
  DATE_CMD="date"
else
  DATE_CMD="gdate"
fi

function _date() {
    $DATE_CMD +%s%N
}

# Start the client loop before the application so it's already polling
(
  while true; do
    # Try to open a TCP connection to the target host and port and use file descriptor 3 for it
    if exec 3<>/dev/tcp/"$HOST"/"$PORT"; then
      # Send HTTP GET request to the server
      if ! echo -e "GET $URL_PATH HTTP/1.0\r\nHost: $HOST\r\nConnection: close\r\n\r\n" >&3; then
        exec 3>&-
        continue
      fi
      # Read the HTTP response status line and extract the status code
      if read -r _ status_code _ <&3; then
        exec 3>&-
        continue
      fi
      # Close the file descriptor
      exec 3>&-
      # If we got a 200 OK response, exit the loop
      if [[ "$status_code" == "200" ]]; then
        break
      fi
    fi
    # Spin here and do nothing rather than waiting some arbitrary unlucky timing
  done
  # Record the timestamp when we successfully got a 200 response
  _date > "$END_TS_FILE"
) 2>/dev/null &
CURL_PID=$!

# Record start time and launch the application.
# Redirect and exec inside the subshell so the application process
# directly replaces the subshell, making $APP_PID its actual PID.
ts=$(_date)
( exec $RUN_CMD &>"$LOG_FILE" ) &
APP_PID=$!

# Ensure cleanup on exit (e.g. on timeout)
trap "kill -15 $APP_PID $CURL_PID 2>/dev/null; wait $APP_PID 2>/dev/null || true; rm -f $END_TS_FILE" EXIT

# Wait for the client loop to get a successful response
wait $CURL_PID 2>/dev/null || true

TTFR=$(($(cat "$END_TS_FILE") - ts))
echo "TTFR=${TTFR} ns"
