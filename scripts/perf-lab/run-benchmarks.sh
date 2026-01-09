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
  echo "  --cpus <CPUS>                                           How many CPUs to allocate to the application"
  echo "                                                              Default: ${CPUS}"
  echo "  --drop-fs-caches                                        Purge/drop OS filesystem caches between iterations"
  echo "  --extra-qdup-args <EXTRA_QDUP_ARGS>                     Any extra arguments that need to be passed to qDup ahead of the qDup scripts"
  echo "                                                              NOTE: This is an advanced option. Make sure you know what you are doing when using it."
  echo "  --graalvm-version <GRAALVM_VERSION>                     The GraalVM version to use if running any native tests (from SDKMAN)"
  echo "                                                              Default: ${GRAALVM_VERSION}"
  echo "  --host <HOST>                                           The HOST to run the benchmarks on"
  echo "                                                              LOCAL is a keyword that can be used to run everything on the local machine"
  echo "                                                              Default: ${HOST}"
  echo "  --iterations <ITERATIONS>                               The number of iterations to run each test"
  echo "                                                              Default: ${ITERATIONS}"
  echo "  --java-version <JAVA_VERSION>                           The Java version to use (from SDKMAN)"
  echo "                                                              Default: ${JAVA_VERSION}"
  echo "  --jvm-args <JVM_ARGS>                                   Any runtime JVM args to be passed to the apps"
  echo "  --jvm-memory <JVM_MEMORY>                               JVM Memory setting (i.e. -Xmx -Xmn -Xms)"
  echo "  --native-quarkus-build-options <NATIVE_QUARKUS_OPTS>    Native build options to be passed to Quarkus native build process"
  echo "  --native-spring3-build-options <NATIVE_SPRING3_OPTS>    Native build options to be passed to Spring 3.x native build process"
  echo "  --native-spring4-build-options <NATIVE_SPRING4_OPTS>    Native build options to be passed to Spring 4.x native build process"
  echo "  --output-dir <OUTPUT_DIR>                               The directory containing the run output"
  echo "                                                              Default: ${OUTPUT_DIR}"
  echo "  --profiler <PROFILER>                                   Enable profiling with async profiler"
  echo "                                                              Accepted values: none, jfr, flamegraph"
  echo "                                                              Default: ${PROFILER}"
  echo "  --quarkus-build-config-args <QUARKUS_BUILD_CONFIG_ARGS> Quarkus app configuration properties fixed at build time"
  echo "  --quarkus-version <QUARKUS_VERSION>                     The Quarkus version to use"
  echo "                                                              Default: Whatever version is set in pom.xml of the Quarkus app"
  echo "                                                              NOTE: Its a good practice to set this manually to ensure proper version"
  echo "  --repo-branch <SCM_REPO_BRANCH>                         The branch in the SCM repo"
  echo "                                                              Default: '${SCM_REPO_BRANCH}'"
  echo "  --repo-url <SCM_REPO_URL>                               The SCM repo url"
  echo "                                                              Default: '${SCM_REPO_URL}'"
  echo "  --runtimes <RUNTIMES>                                   The runtimes to test, separated by commas"
  echo "                                                              Accepted values (1 or more of): quarkus3-jvm, quarkus3-virtual, quarkus3-native, spring3-jvm, spring3-virtual, spring3-jvm-aot, spring3-native, spring4-jvm, spring4-virtual, spring4-jvm-aot, spring4-native"
  echo "                                                              Default: 'quarkus3-jvm,quarkus-jvm-virtual,quarkus3-native,spring3-jvm,spring3-jvm-aot,spring3-virtual,spring3-native,spring4-jvm,spring4-virtual,spring4-jvm-aot,spring4-native'"
  echo "  --springboot3-version <SPRING_BOOT3_VERSION>            The Spring Boot 3.x version to use"
  echo "                                                              Default: Whatever version is set in pom.xml of the Spring Boot 3 app"
  echo "                                                              NOTE: Its a good practice to set this manually to ensure proper version"
  echo "  --springboot4-version <SPRING_BOOT4_VERSION>            The Spring Boot 4.x version to use"
  echo "                                                              Default: Whatever version is set in pom.xml of the Spring Boot 4 app"
  echo "                                                              NOTE: Its a good practice to set this manually to ensure proper version"
  echo "  --tests <TESTS_TO_RUN>                                  The tests to run, separated by commas"
  echo "                                                              Accepted values (1 or more of): test-build, measure-build-times, measure-time-to-first-request, measure-rss, run-load-test"
  echo "                                                              Default: 'test-build,measure-build-times,measure-time-to-first-request,measure-rss,run-load-test'"
  echo "  --user <USER>                                           The user on <HOST> to run the benchmark"
  echo "  --wait-time <WAIT_TIME>                                 Wait time (in seconds) to wait for things like application startup"
  echo "                                                              Default: ${WAIT_TIME}"
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
  echo "  NATIVE_SPRING3_BUILD_OPTIONS: $NATIVE_SPRING3_BUILD_OPTIONS"
  echo "  NATIVE_SPRING4_BUILD_OPTIONS: $NATIVE_SPRING4_BUILD_OPTIONS"
  echo "  PROFILER: $PROFILER"
  echo "  QUARKUS_BUILD_CONFIG_ARGS: $QUARKUS_BUILD_CONFIG_ARGS"
  echo "  QUARKUS_VERSION: $QUARKUS_VERSION"
  echo "  RUNTIMES: ${RUNTIMES[@]}"
  echo "  SPRING_BOOT3_VERSION: $SPRING_BOOT3_VERSION"
  echo "  SPRING_BOOT4_VERSION: $SPRING_BOOT4_VERSION"
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
local current_cpu=$((current_cpu + 3))
local first_request_cpu="${current_cpu}"
local current_cpu=$((current_cpu + 1))
local monitor_cpu="${current_cpu}"

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
    -S config.resources.app_cpus=${CPUS} \
    -S config.resources.cpu.app="${app_cpus}" \
    -S config.resources.cpu.db="${db_cpus}" \
    -S config.resources.cpu.load_generator="${load_gen_cpus}" \
    -S config.resources.cpu.1st_request="${first_request_cpu}" \
    -S config.resources.cpu.monitor="${monitor_cpu}" \
    -S config.springboot3.version=${SPRING_BOOT3_VERSION} \
    -S config.springboot4.version=${SPRING_BOOT4_VERSION} \
    -S config.jvm.memory="${JVM_MEMORY}" \
    -S config.quarkus.build_config_args="${QUARKUS_BUILD_CONFIG_ARGS}" \
    -S config.quarkus.version=${QUARKUS_VERSION} \
    -S config.springboot3.native_build_options="${NATIVE_SPRING3_BUILD_OPTIONS}" \
    -S config.springboot4.native_build_options="${NATIVE_SPRING4_BUILD_OPTIONS}" \
    -S config.profiler.events=cpu \
    -S config.repo.branch=${SCM_REPO_BRANCH} \
    -S config.repo.url=${SCM_REPO_URL} \
    -S env.run.host.user=${USER} \
    -S env.run.host.target=${target} \
    -S env.run.host.name=${HOST} \
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
NATIVE_SPRING3_BUILD_OPTIONS=""
NATIVE_SPRING4_BUILD_OPTIONS=""
PROFILER="none"
QUARKUS_BUILD_CONFIG_ARGS=""
QUARKUS_VERSION=""
ALLOWED_RUNTIMES=("quarkus3-jvm" "quarkus3-virtual" "quarkus3-native" "spring3-jvm" "spring3-virtual" "spring3-jvm-aot" "spring3-native" "spring4-jvm" "spring4-virtual" "spring4-jvm-aot" "spring4-native")
RUNTIMES=${ALLOWED_RUNTIMES[@]}
SPRING_BOOT3_VERSION=""
SPRING_BOOT4_VERSION=""
ALLOWED_TESTS_TO_RUN=("test-build" "measure-build-times" "measure-time-to-first-request" "measure-rss" "run-load-test")
TESTS_TO_RUN=${ALLOWED_TESTS_TO_RUN[@]}
USER=""
JVM_MEMORY=""
WAIT_TIME="20"
DROP_OS_FILESYSTEM_CACHES=false
JVM_ARGS=""
EXTRA_QDUP_ARGS=""
OUTPUT_DIR="/tmp"

# Process the inputs - Manual parsing for portability
while [[ $# -gt 0 ]]; do
  case "$1" in
    --jvm-args)
      JVM_ARGS="$2"
      shift 2
      ;;

    --repo-branch)
      SCM_REPO_BRANCH="$2"
      shift 2
      ;;

    --cpus)
      CPUS="$2"
      shift 2
      ;;

    --drop-fs-caches)
      DROP_OS_FILESYSTEM_CACHES=true
      shift
      ;;

    --extra-qdup-args)
      EXTRA_QDUP_ARGS="$2"
      shift 2
      ;;

    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;

    --graalvm-version)
      GRAALVM_VERSION="$2"
      shift 2
      ;;

    --host)
      HOST="$2"
      shift 2
      ;;

    --iterations)
      ITERATIONS="$2"
      shift 2
      ;;

    --java-version)
      JAVA_VERSION="$2"
      shift 2
      ;;

    --repo-url)
      SCM_REPO_URL="$2"
      shift 2
      ;;

    --native-quarkus-build-options)
      NATIVE_QUARKUS_BUILD_OPTIONS="$2"
      shift 2
      ;;

    --native-spring3-build-options)
      NATIVE_SPRING3_BUILD_OPTIONS="$2"
      shift 2
      ;;

    --native-spring4-build-options)
      NATIVE_SPRING4_BUILD_OPTIONS="$2"
      shift 2
      ;;

    --profiler)
      if [[ "$2" =~ ^(none|jfr|flamegraph)$ ]]; then
        PROFILER="$2"
      else
        echo "!! [ERROR] --profiler option must be one of (none, jfr, flamegraph)!!"
        exit_abnormal
      fi
      shift 2
      ;;

    --quarkus-build-config-args)
      QUARKUS_BUILD_CONFIG_ARGS="$2"
      shift 2
      ;;

    --quarkus-version)
      QUARKUS_VERSION="$2"
      shift 2
      ;;

    --runtimes)
      rt=($(IFS=','; echo $2))

      for item in "${rt[@]}"; do
        if [[ ! "${ALLOWED_RUNTIMES[@]}" =~ "${item}" ]]; then
          echo "!! [ERROR] --runtimes option must contain 1 or more of [${ALLOWED_RUNTIMES[@]}]!!"
          exit_abnormal
        fi
      done

      RUNTIMES=${rt[@]}
      shift 2
      ;;

    --springboot3-version)
      SPRING_BOOT3_VERSION="$2"
      shift 2
      ;;

    --springboot4-version)
      SPRING_BOOT4_VERSION="$2"
      shift 2
      ;;

    --tests)
      ttr=($(IFS=','; echo $2))

      for item in "${ttr[@]}"; do
        if [[ ! "${ALLOWED_TESTS_TO_RUN[@]}" =~ "${item}" ]]; then
          echo "!! [ERROR] --tests option must contain 1 or more of [${ALLOWED_TESTS_TO_RUN[@]}]!!"
          exit_abnormal
        fi
      done

      TESTS_TO_RUN=${ttr[@]}
      shift 2
      ;;

    --user)
      USER="$2"
      shift 2
      ;;

    --jvm-memory)
      JVM_MEMORY="$2"
      shift 2
      ;;

    --wait-time)
      WAIT_TIME="$2"
      shift 2
      ;;

    -*)
      echo "!! [ERROR] Unknown option: $1"
      exit_abnormal
      ;;

    *)
      echo "!! [ERROR] Unexpected argument: $1"
      exit_abnormal
      ;;
  esac
done

validate_values
print_values
setup_jbang
run_benchmarks
