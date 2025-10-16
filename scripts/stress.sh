#!/bin/bash

thisdir=`dirname "$0"`

# make sure the port is clear before enabling halting-on-error
kill $(lsof -t -i:8080) &>/dev/null

set -euo pipefail

${thisdir}/infra.sh -s
java -XX:ActiveProcessorCount=8 -Xms512m -Xmx512m -jar $1 &
jbang wrk2@hyperfoil -t2 -c100 -d30s -R 200 --latency http://localhost:8080/fruits
scripts/infra.sh -d
kill $(lsof -t -i:8080) &>/dev/null