#!/bin/bash

# 1st argument is the command to execute
# 2nd argument is the number of iterations. If not specified defaults to 1

# Example usage
# 1) Run the Spring app 10 times
# $ ./1strequest.sh "java -jar target/chapter-4-spring-data-jpa-1.0.0-SNAPSHOT.jar" 10
#
# 2) Run the native app 10 times
# $ ./1strequest.sh target/chapter-4-spring-data-jpa 10
#
# 3) Run the Quarkus app 10 times
# $ ./1strequest.sh "java -jar target/quarkus-app/quarkus-run.jar" 10

COMMAND=$1
NUM_ITERATIONS=1
TOTAL_RSS=0
TOTAL_TTFR=0

if [ "$#" -eq 2 ]; then
  NUM_ITERATIONS=$2
fi

for (( i=0; i<$NUM_ITERATIONS; i++))
do
  # drop OS page cache entries, inode etc etc
  sync && sudo purge
  ts=$(gdate +%s%N)
  $COMMAND &
  CURRENT_PID=$!

  while ! (curl -sf http://localhost:8080/fruits > /dev/null)
  do
    # Spin here and do nothing rather waiting some arbitrary unlucky timing
    :
  done

  TTFR=$((($(gdate +%s%N) - $ts)/1000000))
  RSS=`ps -o rss= -p $CURRENT_PID | sed 's/^ *//g'`
  kill $CURRENT_PID
  wait $CURRENT_PID 2> /dev/null
  TOTAL_RSS=$((TOTAL_RSS + RSS))
  TOTAL_TTFR=$((TOTAL_TTFR + TTFR))
  echo
  echo "-------------INTERMEDIATE RESULTS ---------------"
  printf "RSS (after 1st request): %.1f MB\n" $(echo "$RSS / 1024" | bc -l)
  printf "time to first request: %.3f sec\n" $(echo "$TTFR / 1000" | bc -l)
  echo "-------------------------------------------------"
done

echo
echo
echo "-------------------------------------------------"
printf "AVG RSS (after 1st request): %.1f MB\n" $(echo "$TOTAL_RSS / $NUM_ITERATIONS / 1024" | bc -l)
printf "AVG time to first request: %.3f sec\n" $(echo "$TOTAL_TTFR / $NUM_ITERATIONS / 1000" | bc -l)
echo "-------------------------------------------------"