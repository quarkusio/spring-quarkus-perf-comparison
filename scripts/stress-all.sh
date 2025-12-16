#!/bin/bash

thisdir=`dirname "$0"`
set -euo pipefail

${thisdir}/infra.sh -s

killApp () {
  (lsof -t -i:8080 || true) | xargs -r kill
}

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

launchJar() {
  java -XX:ActiveProcessorCount=4 -Xms512m -Xmx512m -jar $1 &
}

bench () {
  echo "Now running $2" >> $REPORTNAME
  killApp
  echo "Booting: $2"
  launchJar ${thisdir}/../$1
  wait_for_8080
  echo "Starting Benchmark, please wait... "
  jbang wrk@hyperfoil -t2 -c100 -d20s --timeout 1s http://localhost:8080/fruits >> $REPORTNAME
  echo "" >> $REPORTNAME
  killApp
}

timestamp=$(date +"%Y-%m-%d_%H-%M-%S")
REPORTNAME="report_${timestamp}.txt"

echo "Collecting summary in report file $REPORTNAME"
bench "quarkus3/target/quarkus-app/quarkus-run.jar" "Quarkus"
bench "quarkus3-spring-compatibility/target/quarkus-app/quarkus-run.jar" "Quarkus, with Spring compatibility"
bench "springboot3/target/springboot3.jar" "Spring Boot"

${thisdir}/infra.sh -d

cat $REPORTNAME
