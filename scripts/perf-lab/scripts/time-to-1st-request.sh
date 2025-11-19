#!/bin/bash

TARGET_URL=$1

function _date() {
    current=$(date +%s%N)
    if [ $? -ne 0 ]; then
      current=$(gdate +%s%N)
    fi
    echo "$current"
}

ts=$(_date)

while ! (curl -sf ${TARGET_URL} > /dev/null)
do
  # Spin here and do nothing rather waiting some arbitrary unlucky timing
  :
done

TTFR=$((($(_date) - ts)/1000000))
echo "${TTFR} ms"