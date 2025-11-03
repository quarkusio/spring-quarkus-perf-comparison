#!/bin/bash

thisdir=`dirname "$0"`

# make sure the port is clear before enabling halting-on-error
kill $(lsof -t -i:8080) &>/dev/null

set -euo pipefail

${thisdir}/infra.sh -s
java -XX:ActiveProcessorCount=4 -Xms512m -Xmx512m -jar ${thisdir}/../$1 &
jbang wrk@hyperfoil -t2 -c100 -d20s --timeout 1s http://localhost:8080/fruits
${thisdir}/infra.sh -d
kill $(lsof -t -i:8080) &>/dev/null
