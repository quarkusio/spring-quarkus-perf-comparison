#!/usr/bin/env bash

callingdir="$(pwd)"
thisdir="$(realpath $(dirname "$0"))"

function _date() {
    current=$(date +%s%N)
    if [ $? -ne 0 ]; then
      current=$(gdate +%s%N)
    fi
    echo "$current"
}

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

ts=$(_date)

# -XX:ActiveProcessorCount doesn't limit the number of available cores as we might think
# It also doesn't isolate cores, meaning the cores the java process uses could be shared with other workloads
# See https://github.com/quarkusio/spring-quarkus-perf-comparison/issues/73
#
# On quarkus 3 (without virtual threads): -XX:ActiveProcessorCount wont't constrain the size of our (blocking) worker pool using platform threads,
# allowing it to consume more than the suggested number of processors
#
# On quarkus 3 (with virtual threads) : -XX:ActiveProcessorCount correctly enforce the Loom ForkJoin pool handling VirtualThreads to be sized correctly (in term of platform threads).
# This won't still honor the suggested number of processors, because we internally size the Netty event loop count equal to the number of cores (i.e -XX:ActiveProcessorCount),
# meaning that the total number of threads is -XX:ActiveProcessorCount * 2 (i.e. event loop count + loom fork join pool + GC threads + compiler threads) > -XX:ActiveProcessorCount
#
# On Spring with virtual threads, tomcat fully run it, and they handle blocking calls there too, meaning that the total number of platform threads honor -XX:ActiveProcessorCount
#
# When running in the lab environment (see perf-lab/run-benchmarks.sh & perf-lab/main.yml), this is taken care of by using taskset on Linux.
java -XX:ActiveProcessorCount=4 -Xms512m -Xmx512m -jar ${callingdir}/$1 &
CURRENT_PID=$!

# Wait and measure TTFR
while ! (curl -sf http://localhost:8080/fruits > /dev/null)
do
  # Spin here and do nothing rather waiting some arbitrary unlucky timing
  :
done

TTFR=$((($(_date) - ts)/1000000))
RSS=`ps -o rss= -p $CURRENT_PID | sed 's/^ *//g'`

tempdir=$(mktemp -d)

jbang \
  -Dio.hyperfoil.rootdir=${tempdir} \
  -Dio.hyperfoil.cpu.watchdog.idle.threshold=0.0 \
  run@hyperfoil \
    -o ${tempdir} \
    -PLOAD_DURATION=20s \
    -PWARMUP_DURATION=0s \
    -PWARMUP_PAUSE_DURATION=0s \
    ${thisdir}/perf-lab/load-tests/load-test-fixed-threads-read-all.hf.yml &> ${tempdir}/hf.log

kill $(lsof -t -i:8080) &>/dev/null
${thisdir}/infra.sh -d

echo "-------------------------------------------------"
printf "Time to first request: %.3f sec\n" $(echo "$TTFR / 1000" | bc -l)
printf "RSS (after 1st request): %.1f MB\n" $(echo "$RSS / 1024" | bc -l)
echo "-------------------------------------------------"

cat ${tempdir}/hf.log
echo "Other information output by hyperfoil is available in ${tempdir}"
