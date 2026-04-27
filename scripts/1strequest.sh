#!/usr/bin/env bash


# 1st argument is the command to execute
# 2nd argument is the number of iterations. If not specified defaults to 1
# --no-purge: skip OS page cache drop (useful for local dev without sudo)
#
# Example usage
# 1) Run the Spring app 10 times
# $ ./1strequest.sh "java -XX:ActiveProcessorCount=8 -Xms512m -Xmx512m -jar ../springboot3/target/springboot3.jar" 10
#
# 2) Run the Quarkus app 10 times
# $ ./1strequest.sh "java -XX:ActiveProcessorCount=8 -Xms512m -Xmx512m -jar ../quarkus3/target/quarkus-app/quarkus-run.jar" 10
#
# 3) Run the Quarkus with spring compatibility app 10 times
# $ ./1strequest.sh "java -XX:ActiveProcessorCount=8 -Xms512m -Xmx512m -jar ../quarkus3-spring-compatibility/target/quarkus-app/quarkus-run.jar" 10
#
# 4) Run the dotnet app 3 times without sudo (local dev)
# $ ./1strequest.sh "dotnet10/publish/dotnet10" 3 --no-purge
set -euo pipefail

thisdir=`dirname "$0"`

COMMAND=$1
NUM_ITERATIONS=1
TOTAL_RSS=0
TOTAL_TTFR=0
NO_PURGE=false

function _date() {
    current=$(date +%s%N)
    if [ $? -ne 0 ]; then
      current=$(gdate +%s%N)
    fi
    echo "$current"
}

if [ "$#" -ge 2 ]; then
  NUM_ITERATIONS=$2
fi
for arg in "$@"; do
  if [ "$arg" = "--no-purge" ]; then NO_PURGE=true; fi
done

LC_NUMERIC=C
if [[ "$1" != *.jar ]]; then
  # .NET Environment variables to mimic Java -Xmx and -XX:ActiveProcessorCount:
  # DOTNET_GCHeapHardLimit: Hard memory limit in hex (0x20000000 = 512MB)
  # DOTNET_ProcessorCount: Limits the CPU cores the runtime perceives
  # DOTNET_gcServer: Enables Server GC for high-throughput
  export DOTNET_GCHeapHardLimit=0x20000000
  export DOTNET_ProcessorCount=4
  export DOTNET_gcServer=1

  # Suppress logging
  export Logging__LogLevel__Default=None
fi

for (( i=0; i<$NUM_ITERATIONS; i++))
do
  # drop OS page cache entries, inode etc etc
  if [ "$NO_PURGE" = false ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sync && sudo purge
    else
      # Linux: drop pagecache, dentries and inodes
      sync && sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
    fi
  fi

  # Start the infra
  ${thisdir}/infra.sh -s

  ts=$(_date)

  $COMMAND &
  CURRENT_PID=$!

  while ! (curl -sf http://localhost:8080/fruits > /dev/null)
  do
    # Spin here and do nothing rather waiting some arbitrary unlucky timing
    :
  done

  TTFR=$((($(_date) - ts)/1000000))
  RSS=`ps -o rss= -p $CURRENT_PID | sed 's/^ *//g'`
  kill $CURRENT_PID
  wait $CURRENT_PID 2> /dev/null || true
  TOTAL_RSS=$((TOTAL_RSS + RSS))
  TOTAL_TTFR=$((TOTAL_TTFR + TTFR))

  echo
  echo "-------------INTERMEDIATE RESULTS ---------------"
  printf "RSS (after 1st request): %.1f MB\n" $(echo "$RSS / 1024" | bc -l)
  printf "time to first request: %.3f sec\n" $(echo "$TTFR / 1000" | bc -l)
  echo "-------------------------------------------------"

  # Stop the infra
  ${thisdir}/infra.sh -d
done

echo
echo
echo "-------------------------------------------------"
printf "AVG RSS (after 1st request): %.1f MB\n" $(echo "$TOTAL_RSS / $NUM_ITERATIONS / 1024" | bc -l)
printf "AVG time to first request: %.3f sec\n" $(echo "$TOTAL_TTFR / $NUM_ITERATIONS / 1000" | bc -l)
echo "-------------------------------------------------"
