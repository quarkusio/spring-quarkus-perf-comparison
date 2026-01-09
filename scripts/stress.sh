#!/bin/bash

callingdir="$(pwd)"
thisdir="$(realpath $(dirname "$0"))"

# Check if jbang is installed
if ! command -v jbang >/dev/null 2>&1; then
  echo "Error: jbang is not installed."
  echo "Please install jbang from https://www.jbang.dev/ before running this script."
  exit 1
fi

# Make sure the port is clear before enabling halting-on-error
kill $(lsof -t -i:8080) &>/dev/null

# Make sure DB is down (sanity check)
${thisdir}/infra.sh -d

set -euo pipefail

${thisdir}/infra.sh -s
java -XX:ActiveProcessorCount=4 -Xms512m -Xmx512m -jar ${callingdir}/$1 &

# Give the app a chance to fully start before throwing load at it
sleep 20

jbang wrk@hyperfoil -t2 -c100 -d20s --timeout 1s http://localhost:8080/fruits
${thisdir}/infra.sh -d
kill $(lsof -t -i:8080) &>/dev/null
