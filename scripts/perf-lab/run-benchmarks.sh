#!/bin/bash -e

help() {
  echo "This script runs benchmarks."
  echo "It assumes you have the following things installed on your machine:"
  echo "  - git (https://github.com/git-guides/install-git)"
  echo "  - jbang (https://www.jbang.dev/download)"
  echo "  - jq (https://stedolan.github.io/jq)"
  echo
  echo "Syntax: run-benchmarks.sh [options]"
  echo "options:"
  echo "  -a <JVM_ARGS>                       Any JVM args to be passed to the apps"
  echo "  -b <SCM_REPO_BRANCH>                The branch in the SCM repo"
  echo "                                          Default: 'main'"
  echo "  -c <CGROUPS_CPUS>                   Constrain to certain CPUs via cgroups"
  echo "                                          NOTE: Can be a comma-separated list (i.e. '0,2,4,6,8,10,12,14')"
  echo "  -d                                  Purge/drop OS filesystem caches between iterations"
  echo "  -e <EXTRA_QDUP_ARGS>                Any extra arguments that need to be passed to qDup ahead of the qDup scripts"
  echo "                                          NOTE: This is an advanced option. Make sure you know what you are doing when using it."
  echo "  -f <OUTPUT_DIR>                     The directory containing the run output"
  echo "                                          Default: /tmp"
  echo "  -g <GRAALVM_VERSION>                The GraalVM version to use if running any native tests (from SDKMAN)"
  echo "                                          Default: 25-graalce"
  echo "  -h <HOST>                           The HOST to run the benchmarks on"
  echo "                                          LOCAL is a keyword that can be used to run everything on the local machine"
  echo "                                          Default: LOCAL"
  echo "  -i <ITERATIONS>                     The number of iterations to run each test"
  echo "                                          Default: 3"
  echo "  -j <JAVA_VERSION>                   The Java version to use (from SDKMAN)"
  echo "                                          Default: 25-tem"
  echo "  -l <SCM_REPO_URL>                   The SCM repo url"
  echo "                                          Default: 'https://github.com/quarkusio/spring-quarkus-perf-comparison.git'"
  echo "  -m <CGROUPS_MAX_MEMORY>             Constrain available memory via cgroups"
  echo "                                          Default: 14G"
  echo "  -n <NATIVE_QUARKUS_BUILD_OPTIONS>   Native build options to be passed to Quarkus native build process"
  echo "  -o <NATIVE_SPRING_BUILD_OPTIONS>    Native build options to be passed to Spring native build process"
  echo "  -p <PROFILER>                       Enable profiling with async profiler"
  echo "                                          Accepted values: none, jfr, flamegraph"
  echo "                                          Default: none"
  echo "  -q <QUARKUS_VERSION>                The Quarkus version to use"
  echo "                                          Default: Whatever version is set in pom.xml of the Quarkus app"
  echo "                                          NOTE: Its a good practice to set this manually to ensure proper version"
  echo "  -r <RUNTIMES>                       The runtimes to test, separated by commas"
  echo "                                          Accepted values (1 or more of): quarkus3-jvm, quarkus3-native, spring3-jvm, spring3-jvm-aot, spring3-native"
  echo "                                          Default: 'quarkus3-jvm,quarkus3-native,spring3-jvm,spring3-jvm-aot,spring3-native'"
  echo "  -s <SPRING_BOOT_VERSION>            The Spring Boot version to use"
  echo "                                          Default: Whatever version is set in pom.xml of the Spring Boot app"
  echo "                                          NOTE: Its a good practice to set this manually to ensure proper version"
  echo "  -t <TESTS_TO_RUN>                   The tests to run, separated by commas"
  echo "                                          Accepted values (1 or more of): test-build, measure-build-times, measure-time-to-first-request, measure-rss, run-load-test"
  echo "                                          Default: 'test-build,measure-build-times,measure-time-to-first-request,measure-rss,run-load-test'"
  echo "  -u <USER>                           The user on <HOST> to run the benchmark"
  echo "  -v <JVM_MEMORY>                     JVM Memory setting (i.e. -Xmx -Xmn -Xms)"
  echo "  -w <WAIT_TIME>                      Wait time (in seconds) to wait for things like application startup"
  echo "                                          Default: 20"
  echo "  -x <CMD_PREFIX>                     Command prefix for running tests - allows us to restrict number of cores with taskset etc (i.e. taskset --cpu-list 0-3)"
}

exit_abnormal() {
  echo
  help
  exit 1
}

validate_values() {
  if [ -z "$HOST" ]; then
    echo "!! [ERROR] Please set the HOST!!"
    exit_abnormal
  fi

  if [ -z "$QUARKUS_VERSION" ]; then
    echo "!! [ERROR] Please set the QUARKUS_VERSION!!"
    exit_abnormal
  fi

  if [ -z "$SPRING_BOOT_VERSION" ]; then
    echo "!! [ERROR] Please set the SPRING_BOOT_VERSION!!"
    exit_abnormal
  fi

  if [ "$HOST" != "LOCAL" -a -z "$USER" ]; then
    echo "!! [ERROR] Please set the USER!!"
    exit_abnormal
  fi

  if [ -z "$OUTPUT_DIR" ]; then
    echo " [ERROR] Please set the OUTPUT_DIR!!"
    exit_abnormal
  fi

  if [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p $OUTPUT_DIR
  fi
}

print_values() {
  echo "Configuration Values:"
  echo "  CGROUPS_CPUS: $CGROUPS_CPUS"
  echo "  GRAALVM_VERSION: $GRAALVM_VERSION"
  echo "  HOST: $HOST"
  echo "  ITERATIONS: $ITERATIONS"
  echo "  JAVA_VERSION: $JAVA_VERSION"
  echo "  CGROUPS_MAX_MEMORY: $CGROUPS_MAX_MEMORY"
  echo "  NATIVE_QUARKUS_BUILD_OPTIONS: $NATIVE_QUARKUS_BUILD_OPTIONS"
  echo "  NATIVE_SPRING_BUILD_OPTIONS: $NATIVE_SPRING_BUILD_OPTIONS"
  echo "  PROFILER: $PROFILER"
  echo "  QUARKUS_VERSION: $QUARKUS_VERSION"
  echo "  RUNTIMES: ${RUNTIMES[@]}"
  echo "  SPRING_BOOT_VERSION: $SPRING_BOOT_VERSION"
  echo "  TESTS_TO_RUN: ${TESTS_TO_RUN[@]}"
  echo "  USER: $USER"
  echo "  JVM_MEMORY: $JVM_MEMORY"
  echo "  WAIT_TIME: $WAIT_TIME"
  echo "  CMD_PREFIX: $CMD_PREFIX"
  echo "  SCM_REPO_URL: $SCM_REPO_URL"
  echo "  SCM_REPO_BRANCH: $SCM_REPO_BRANCH"
  echo "  DROP_OS_FILESYSTEM_CACHES: $DROP_OS_FILESYSTEM_CACHES"
  echo "  JVM_ARGS: $JVM_ARGS"
  echo "  EXTRA_QDUP_ARGS: $EXTRA_QDUP_ARGS"
  echo "  OUTPUT_DIR: $OUTPUT_DIR"
}

make_json_array() {
  local bashArray=("$@")
  local jsonArray="${bashArray[*]}"
  echo "['${jsonArray// /','}']"
}

setup_jbang() {
  if command -v jbang &> /dev/null; then
    echo "Using installed jbang ($(jbang --version))"
    JBANG_CMD="jbang"
  else
    echo "jbang not found locally. Using jbang wrapper..."

    # Download the jbang wrapper if it doesn't exist
    if [ ! -f ".jbang-wrapper" ]; then

      chmod +x .jbang-wrapper
    fi

    JBANG_CMD="./.jbang-wrapper"
    echo "Using jbang wrapper"
  fi
}

run_benchmarks() {
# jbang -Dqdup.console.level="ALL" qDup@hyperfoil \

  if [[ "$HOST" == "LOCAL" ]]; then
    local target="LOCAL"
    USER=$(whoami)
  else
    local target="${USER}@${HOST}"
  fi

#print_values

#  jbang qDup@hyperfoil --trace="target" \
${JBANG_CMD} qDup@hyperfoil \
    -C \
    -B ${OUTPUT_DIR} \
    -ix \
    ${EXTRA_QDUP_ARGS} \
    ./main.yml \
    ./helpers/ \
    -S config.jvm.graalvm.version=${GRAALVM_VERSION} \
    -S config.jvm.version=${JAVA_VERSION} \
    -S config.quarkus.native_build_options="${NATIVE_QUARKUS_BUILD_OPTIONS}" \
    -S config.jvm.args="${JVM_ARGS}" \
    -S config.profiler.name=${PROFILER} \
    -S config.cgroup.mem_max=${CGROUPS_MAX_MEMORY} \
    -S config.cgroup.cpu=${CGROUPS_CPUS} \
    -S config.springboot.version=${SPRING_BOOT_VERSION} \
    -S config.jvm.memory="${JVM_MEMORY}" \
    -S config.CMD_PREFIX="${CMD_PREFIX}" \
    -S config.quarkus.version=${QUARKUS_VERSION} \
    -S config.springboot.native_build_options="${NATIVE_SPRING_BUILD_OPTIONS}" \
    -S config.profiler.events=cpu \
    -S config.repo.branch=${SCM_REPO_BRANCH} \
    -S config.repo.url=${SCM_REPO_URL} \
    -S env.USER=${USER} \
    -S env.TARGET=${target} \
    -S config.num_iterations=${ITERATIONS} \
    -S PROJ_REPO_NAME="$(basename ${SCM_REPO_URL} .git)" \
    -S RUNTIMES="$(make_json_array ${RUNTIMES})" \
    -S PAUSE_TIME=${WAIT_TIME} \
    -S TESTS="$(make_json_array ${TESTS_TO_RUN})" \
    -S DROP_OS_FILESYSTEM_CACHES=${DROP_OS_FILESYSTEM_CACHES}
}

# Define defaults
CGROUPS_CPUS=""
SCM_REPO_URL="https://github.com/quarkusio/spring-quarkus-perf-comparison.git"
SCM_REPO_BRANCH="main"
GRAALVM_VERSION="25-graalce"
HOST="LOCAL"
ITERATIONS="3"
JAVA_VERSION="25-tem"
CGROUPS_MAX_MEMORY="14G"
NATIVE_QUARKUS_BUILD_OPTIONS=""
NATIVE_SPRING_BUILD_OPTIONS=""
PROFILER="none"
QUARKUS_VERSION=""
ALLOWED_RUNTIMES=("quarkus3-jvm" "quarkus3-native" "spring3-jvm" "spring3-jvm-aot" "spring3-native")
RUNTIMES=${ALLOWED_RUNTIMES[@]}
SPRING_BOOT_VERSION=""
ALLOWED_TESTS_TO_RUN=("test-build" "measure-build-times" "measure-time-to-first-request" "measure-rss" "run-load-test")
TESTS_TO_RUN=${ALLOWED_TESTS_TO_RUN[@]}
USER=""
JVM_MEMORY=""
WAIT_TIME="20"
CMD_PREFIX=""
DROP_OS_FILESYSTEM_CACHES=false
JVM_ARGS=""
EXTRA_QDUP_ARGS=""
OUTPUT_DIR="/tmp"

# Process the inputs
while getopts "a:b:c:de:f:g:h:i:j:l:m:n:o:p:q:r:s:t:u:v:w:x:" option; do
  case $option in
    a) JVM_ARGS=$OPTARG
      ;;

    b) SCM_REPO_BRANCH=$OPTARG
      ;;

    c) CGROUPS_CPUS=$OPTARG
      ;;

    d) DROP_OS_FILESYSTEM_CACHES=true
      ;;

    e) EXTRA_QDUP_ARGS=$OPTARG
      ;;

    f) OUTPUT_DIR=$OPTARG
      ;;

    g) GRAALVM_VERSION=$OPTARG
      ;;

    h) HOST=$OPTARG
      ;;

    i) ITERATIONS=$OPTARG
      ;;

    j) JAVA_VERSION=$OPTARG
      ;;

    l) SCM_REPO_URL=$OPTARG
      ;;

    m) CGROUPS_MAX_MEMORY=$OPTARG
      ;;

    n) NATIVE_QUARKUS_BUILD_OPTIONS=$OPTARG
      ;;

    o) NATIVE_SPRING_BUILD_OPTIONS=$OPTARG
      ;;

    p) if [[ "$OPTARG" =~ ^(none|jfr|flamegraph)$ ]]; then
         PROFILER=$OPTARG
       else
         echo "!! [ERROR] -p option must be one of (none, jfr, flamegraph)!!"
         exit_abnormal
       fi
      ;;

    q) QUARKUS_VERSION=$OPTARG
      ;;

    r) rt=($(IFS=','; echo $OPTARG))

       for item in "${rt[@]}"; do
         if [[ ! "${ALLOWED_RUNTIMES[@]}" =~ "${item}" ]]; then
           echo "!! [ERROR] -r option must contain 1 or more of [${ALLOWED_RUNTIMES[@]}]!!"
           exit_abnormal
         fi
       done

       RUNTIMES=${rt[@]}
      ;;

    s) SPRING_BOOT_VERSION=$OPTARG
      ;;

    t) ttr=($(IFS=','; echo $OPTARG))

       for item in "${ttr[@]}"; do
         if [[ ! "${ALLOWED_TESTS_TO_RUN[@]}" =~ "${item}" ]]; then
           echo "!! [ERROR] -t option must contain 1 or more of [${ALLOWED_TESTS_TO_RUN[@]}]!!"
           exit_abnormal
         fi
       done

       TESTS_TO_RUN=${ttr[@]}
      ;;

    u) USER=$OPTARG
      ;;

    v) JVM_MEMORY=$OPTARG
      ;;

    w) WAIT_TIME=$OPTARG
      ;;

    x) CMD_PREFIX=$OPTARG
      ;;

    *) exit_abnormal
      ;;
  esac
done

validate_values
setup_jbang
run_benchmarks
