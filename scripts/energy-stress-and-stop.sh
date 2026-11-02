#!/bin/bash
# This script is useful for measuring energy consumption, in combination with https://github.com/metacosm/power-server

thisdir=`dirname "$0"`

# Run wrk2 and format output to emphasise the latency
jbang wrk2@hyperfoil -t2 -c100 -d20s --rate 2000 --timeout 1s http://localhost:8080/fruits | while IFS= read -r line; do
    # Make only the "Latency" summary line bold (contains average latency)
    if [[ "$line" =~ ^[[:space:]]*Latency[[:space:]] ]]; then
        echo -e "\033[1m${line}\033[0m"
    else
        echo "$line"
    fi
done

kill $(lsof -t -i:8080) &>/dev/null
${thisdir}/infra.sh -d
