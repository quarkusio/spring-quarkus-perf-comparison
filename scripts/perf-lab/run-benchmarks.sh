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
  echo "                                          Default: '${SCM_REPO_BRANCH}'"
  echo "  -c <CPUS>                           How many CPUs to allocate to the application"
  echo "                                          Default: ${CPUS}"
  echo "  -d                                  Purge/drop OS filesystem caches between iterations"
  echo "  -e <EXTRA_QDUP_ARGS>                Any extra arguments that need to be passed to qDup ahead of the qDup scripts"
  echo "                                          NOTE: This is an advanced option. Make sure you know what you are doing when using it."
  echo "  -f <OUTPUT_DIR>                     The directory containing the run output"
  echo "                                          Default: ${OUTPUT_DIR}"
  echo "  -g <GRAALVM_VERSION>                The GraalVM version to use if running any native tests (from SDKMAN)"
  echo "                                          Default: ${GRAALVM_VERSION}"
  echo "  -h <HOST>                           The HOST to run the benchmarks on"
  echo "                                          LOCAL is a keyword that can be used to run everything on the local machine"
  echo "                                          Default: ${HOST}"
  echo "  -i <ITERATIONS>                     The number of iterations to run each test"
  echo "                                          Default: ${ITERATIONS}"
  echo "  -j <JAVA_VERSION>                   The Java version to use (from SDKMAN)"
  echo "                                          Default: ${JAVA_VERSION}"
  echo "  -l <SCM_REPO_URL>                   The SCM repo url"
  echo "                                          Default: '${SCM_REPO_URL}'"
  echo "  -n <NATIVE_QUARKUS_BUILD_OPTIONS>   Native build options to be passed to Quarkus native build process"
  echo "  -o <NATIVE_SPRING_BUILD_OPTIONS>    Native build options to be passed to Spring native build process"
  echo "  -p <PROFILER>                       Enable profiling with async profiler"
  echo "                                          Accepted values: none, jfr, flamegraph"
  echo "                                          Default: ${PROFILER}"
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
  echo "                                          Default: ${WAIT_TIME}"
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
  echo
  echo "#####################"
  echo "Configuration Values:"
  echo "  CPUS: $CPUS"
  echo "  GRAALVM_VERSION: $GRAALVM_VERSION"
  echo "  HOST: $HOST"
  echo "  ITERATIONS: $ITERATIONS"
  echo "  JAVA_VERSION: $JAVA_VERSION"
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
  echo "  SCM_REPO_URL: $SCM_REPO_URL"
  echo "  SCM_REPO_BRANCH: $SCM_REPO_BRANCH"
  echo "  DROP_OS_FILESYSTEM_CACHES: $DROP_OS_FILESYSTEM_CACHES"
  echo "  JVM_ARGS: $JVM_ARGS"
  echo "  EXTRA_QDUP_ARGS: $EXTRA_QDUP_ARGS"
  echo "  OUTPUT_DIR: $OUTPUT_DIR"
  echo
}

make_json_array() {
  local items=($@)  # Split on whitespace into array
  local json="["
  local first=true

  for item in "${items[@]}"; do
    if [ "$first" = true ]; then
      first=false
    else
      json+=","
    fi

    json+="\"$item\""
  done

  json+="]"
  echo "$json"
}

setup_jbang() {
  if command -v jbang &> /dev/null; then
    echo "Using installed jbang ($(jbang --version))"
    JBANG_CMD="jbang"
  else
    echo "jbang not found locally. Using jbang wrapper..."
    
    # Download the jbang wrapper if it doesn't exist
    if [ ! -f ".jbang-wrapper" ]; then
      curl -Ls https://sh.jbang.dev -o .jbang-wrapper
      chmod +x .jbang-wrapper
    fi
    
    JBANG_CMD="./.jbang-wrapper"
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

local current_cpu=$((CPUS - 1))
local app_cpus="0-${current_cpu}"
local current_cpu=$((current_cpu + 1))
local db_cpus="${current_cpu}-$((current_cpu + 2))"
local current_cpu=$((current_cpu + 3))
local load_gen_cpus="${current_cpu}-$((current_cpu + 2))"

${JBANG_CMD} qDup@hyperfoil \
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
    -S config.resources.cpu.app="${app_cpus}" \
    -S config.resources.cpu.db="${db_cpus}" \
    -S config.resources.cpu.load_generator="${load_gen_cpus}" \
    -S config.springboot.version=${SPRING_BOOT_VERSION} \
    -S config.jvm.memory="${JVM_MEMORY}" \
    -S config.quarkus.version=${QUARKUS_VERSION} \
    -S config.springboot.native_build_options="${NATIVE_SPRING_BUILD_OPTIONS}" \
    -S config.profiler.events=cpu \
    -S config.repo.branch=${SCM_REPO_BRANCH} \
    -S config.repo.url=${SCM_REPO_URL} \
    -S env.USER=${USER} \
    -S env.TARGET=${target} \
    -S env.HOST=${HOST} \
    -S config.num_iterations=${ITERATIONS} \
    -S PROJ_REPO_NAME="$(basename ${SCM_REPO_URL} .git)" \
    -S RUNTIMES="$(make_json_array $RUNTIMES)" \
    -S PAUSE_TIME=${WAIT_TIME} \
    -S TESTS="$(make_json_array $TESTS_TO_RUN)" \
    -S DROP_OS_FILESYSTEM_CACHES=${DROP_OS_FILESYSTEM_CACHES}
}

# Define defaults
CPUS="4"
SCM_REPO_URL="https://github.com/quarkusio/spring-quarkus-perf-comparison.git"
SCM_REPO_BRANCH="main"
GRAALVM_VERSION="25.0.1-graalce"
HOST="LOCAL"
ITERATIONS="3"
JAVA_VERSION="25.0.1-tem"
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
DROP_OS_FILESYSTEM_CACHES=false
JVM_ARGS=""
EXTRA_QDUP_ARGS=""
OUTPUT_DIR="/tmp"

# Process the inputs
while getopts "a:b:c:de:f:g:h:i:j:l:n:o:p:q:r:s:t:u:v:w:" option; do
  case $option in
    a) JVM_ARGS=$OPTARG
      ;;

    b) SCM_REPO_BRANCH=$OPTARG
      ;;

    c) CPUS=$OPTARG
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

    *) exit_abnormal
      ;;
  esac
done

validate_values
print_values
setup_jbang
run_benchmarks
