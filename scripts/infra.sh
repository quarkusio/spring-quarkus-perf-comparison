#!/bin/bash
set -euo pipefail
thisdir="$(realpath $(dirname "$0"))"

help() {
  echo "This script starts the necessary services for the app in question"
  echo
  echo "Syntax: infra.sh [options]"
  echo "options:"
  echo " -c <CPUS>             The number of cpus to allocate"
  echo " -d                    Destroy the services"
  echo " -h                    Prints this help message"
  echo " -m <MEMORY>           Memory to allocate"
  echo "                         Default: ${MEMORY}"
  echo " -p <CPUSET_CPUS>      CPUs in which to allow execution (0-3, 0,1)"
  echo " -r                    Output the PostgreSQL process host PID"
  echo " -s                    Start the services"
}

exit_abnormal() {
  echo
  help
  exit 1
}

get_postgres_host_pid() {
  echo $(${engine} inspect -f '{{.State.Pid}}' ${DB_CONTAINER_NAME})
}

# Wrapper to handle rootless podman cgroup issues on Linux
run_with_cgroup_support() {
  # Check if we're on Linux with rootless podman
  if [ "$(uname)" = "Linux" ] && [ "$engine" = "podman" ] && [ "$(id -u)" -ne 0 ]; then
    # Linux rootless podman - use systemd-run for proper cgroup delegation
    if command -v systemd-run >/dev/null 2>&1; then
      systemd-run --user --scope --quiet -- "$@"
    else
    # systemd-run not found, running without cgroup delegation (resource limits may not work)
      "$@"
    fi
  else
    # macOS, Docker, or rootful podman - run directly
    "$@"
  fi
}

start_postgres() {
  echo "Starting PostgreSQL database '${DB_CONTAINER_NAME}'"

  local cpuset_flag=""
  local cpus_flag=""

  if [ -n "$CPUS" ]; then
    cpus_flag="--cpus ${CPUS}"
  fi

  if [ -n "${CPUSET_CPUS}" ] && [ "$(uname)" = "Linux" ]; then
    # Only use --cpuset-cpus on Linux (if set at all)
    cpuset_flag="--cpuset-cpus ${CPUSET_CPUS}"
  fi

  local pid=$(run_with_cgroup_support ${engine} run \
    ${cpus_flag} \
    ${cpuset_flag} \
    --memory ${MEMORY} \
    -d \
    --rm \
    --name ${DB_CONTAINER_NAME} \
    -p 5432:5432 \
    ghcr.io/quarkusio/postgres-17-perf:main \
    -c fsync=off \
    -c synchronous_commit=off \
    -c autovacuum=off \
    -c full_page_writes=off \
    -c wal_level=minimal \
    -c archive_mode=off \
    -c max_wal_senders=0 \
    -c max_wal_size=4GB \
    -c track_counts=off \
    -c checkpoint_timeout=1h \
    -c work_mem=32MB \
    -c maintenance_work_mem=256MB)
  echo "PostgreSQL DB process: $pid"

  echo "Waiting for PostgreSQL to be ready..."
  timeout 90s bash -c "until ${engine} exec $DB_CONTAINER_NAME pg_isready ; do sleep 5 ; done" || {
    echo "Error: PostgreSQL failed to become ready"
    exit 1
  }
}

stop_postgres() {
  echo "Stopping PostgreSQL database '${DB_CONTAINER_NAME}'"
  ${engine} stop ${DB_CONTAINER_NAME}
}

start_services() {
  echo "Using $engine to start containers"
  echo "-----------------------------------------"
  echo "[$(date +"%m/%d/%Y %T")]: Starting services"
  echo "-----------------------------------------"
  start_postgres
}

stop_services() {
  echo "Using $engine to stop containers"
  echo "-----------------------------------------"
  echo "[$(date +"%m/%d/%Y %T")]: Stopping services"
  echo "-----------------------------------------"
  stop_postgres
}

DB_CONTAINER_NAME="fruits_db"
CPUS=""
CPUSET_CPUS=""
MEMORY="2g"
engine=""
IS_STARTING=true

if command -v podman >/dev/null 2>&1; then
  engine="podman"
elif command -v docker >/dev/null 2>&1; then
  engine="docker"
else
  echo "Error: Neither podman nor docker can be found"
  exit_abnormal
fi

# Process the input options
while getopts "c:dhm:p:rs" option; do
  case $option in
    c) CPUS=$OPTARG
       ;;

    d) IS_STARTING=false
       ;;

    h) help
       exit
       ;;

    m) MEMORY=$OPTARG
       ;;

    p) CPUSET_CPUS=$OPTARG
       ;;

    r) get_postgres_host_pid
       exit
       ;;

    s) IS_STARTING=true
       ;;

    *) exit_abnormal
       ;;
  esac
done

if [ "${IS_STARTING}" = true ]; then
  start_services
else
  stop_services
fi
