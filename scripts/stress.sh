#!/bin/bash

thisdir=`dirname "$0"`
set -euo pipefail

# Kills any process running on 8080, but avoids erroring out if there is none
(lsof -t -i:8080 || true) | xargs -r kill

wait_for_8080() {
    echo "Waiting for port 8080..."
    for ((i=0; i<30; i++)); do
        # Using 127.0.0.1 is safer than localhost on macOS to avoid IPv6 ::1 mismatch
        if (echo > /dev/tcp/127.0.0.1/8080) >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    echo "Timeout waiting for port 8080"
    return 1
}

${thisdir}/infra.sh -s
java -XX:ActiveProcessorCount=4 -Xms512m -Xmx512m -jar ${thisdir}/../$1 &
wait_for_8080
jbang wrk@hyperfoil -t2 -c100 -d20s --timeout 1s http://localhost:8080/fruits
${thisdir}/infra.sh -d
kill $(lsof -t -i:8080) &>/dev/null
