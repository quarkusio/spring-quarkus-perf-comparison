#!/bin/bash
# This script is useful for measuring energy consumption, in combination with https://github.com/metacosm/power-server

thisdir=`dirname "$0"`

jbang wrk2@hyperfoil -t2 -c100 -d20s --rate 2000 --timeout 1s http://localhost:8080/fruits
kill $(lsof -t -i:8080) &>/dev/null
${thisdir}/infra.sh -d
