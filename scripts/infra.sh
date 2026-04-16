#!/usr/bin/env bash
set -euo pipefail
thisdir="$(realpath $(dirname "$0"))"

help() {
  echo "This script starts the necessary services for the app in question"
  echo
  echo "Syntax: infra.sh [options]"
  echo "options:"
  echo " -c <DB_CPUS>          The number of cpus to allocate to the database container"
  echo " -d                    Destroy the services"
  echo " -g <OTEL_CPUSET_CPUS> Otel CPUs in which to allow execution (0-3, 0,1)"
  echo " -h                    Prints this help message"
  echo " -l <OTEL_CPUS>        The number of cpus to allocate to the Otel container"
  echo " -m <DB_MEMORY>        Memory to allocate to the database container"
  echo "                         Default: ${DB_MEMORY}"
  echo " -n                    Use host networking instead of port mapping on infra containers"
  echo " -o                    Output the Otel process host PID"
  echo " -p <DB_CPUSET_CPUS>   Database CPUs in which to allow execution (0-3, 0,1)"
  echo " -r                    Output the PostgreSQL process host PID"
  echo " -s                    Start the services"
  echo " -t <OTEL_MEMORY>      Memory to allocate to the Otel container"
  echo "                         Default: ${OTEL_MEMORY}"
}

exit_abnormal() {
  echo
  help
  exit 1
}

get_postgres_host_pid() {
  echo $(${engine} inspect -f '{{.State.Pid}}' ${DB_CONTAINER_NAME})
}

get_otel_host_pid() {
  echo $(${engine} inspect -f '{{.State.Pid}}' ${OTEL_CONTAINER_NAME})
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

start_otel() {
  echo "Starting Otel stack"

  local cpuset_flag=""
  local cpus_flag=""
  local networking_flags=""

  if [ -n "$OTEL_CPUS" ]; then
    cpus_flag="--cpus ${OTEL_CPUS}"
  fi

  if [ -n "${OTEL_CPUSET_CPUS}" ] && [ "$(uname)" = "Linux" ]; then
    # Only use --cpuset-cpus on Linux (if set at all)
    cpuset_flag="--cpuset-cpus ${OTEL_CPUSET_CPUS}"
  fi

  if [ "${USE_HOST_NETWORKING}" = "true" ]; then
    networking_flags="--network host"
  else
    networking_flags="-p 4317:4317 -p 4318:4318 -p 3000:3000 -p 4040:4040 -p 9090:9090"
  fi

  local pid=$(run_with_cgroup_support ${engine} run \
    ${cpus_flag} \
    ${cpuset_flag} \
    --memory ${OTEL_MEMORY} \
    -d \
    --rm \
    --name ${OTEL_CONTAINER_NAME} \
    ${networking_flags} \
    docker.io/grafana/otel-lgtm@sha256:205bfb9b4907c9acac5b99a407ad5fc4bf528a73dc735fa39ffc2c3a9335cbe9)
  echo "Grafana Otel LGTM process: $pid"

  echo "Waiting for Grafana Otel LGTM to be ready..."
#  timeout 90s bash -c "until curl -sf http://localhost:3000/api/health > /dev/null; do sleep 5; done" || {
  timeout 90s bash -c "until ${engine} exec $OTEL_CONTAINER_NAME curl -sf http://localhost:3000/api/health > /dev/null; do sleep 5 ; done" || {
    echo "Error: Otel LGTM failed to become ready"
    exit 1
  }
}

start_postgres() {
  echo "Starting PostgreSQL database '${DB_CONTAINER_NAME}'"

  local cpuset_flag=""
  local cpus_flag=""
  local networking_flags=""

  if [ -n "$DB_CPUS" ]; then
    cpus_flag="--cpus ${DB_CPUS}"
  fi

  if [ -n "${DB_CPUSET_CPUS}" ] && [ "$(uname)" = "Linux" ]; then
    # Only use --cpuset-cpus on Linux (if set at all)
    cpuset_flag="--cpuset-cpus ${DB_CPUSET_CPUS}"
  fi

  if [ "${USE_HOST_NETWORKING}" = "true" ]; then
    networking_flags="--network host"
  else
    networking_flags="-p 5432:5432"
  fi

  local pid=$(run_with_cgroup_support ${engine} run \
    ${cpus_flag} \
    ${cpuset_flag} \
    --memory ${DB_MEMORY} \
    -d \
    --rm \
    --name ${DB_CONTAINER_NAME} \
    ${networking_flags} \
    ghcr.io/quarkusio/postgres-17-perf@sha256:25547aa2c1a44685066f552e1c262929cf629cbc2f3a82bd18fa791a03f7cd48 \
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
  timeout 90s bash -c "until ${engine} exec $DB_CONTAINER_NAME pg_isready -h localhost -U fruits; do sleep 5 ; done" || {
    echo "Error: PostgreSQL failed to become ready"
    exit 1
  }
}

stop_otel() {
  echo "Stopping Otel stack"
  ${engine} stop ${OTEL_CONTAINER_NAME}
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
  start_otel
}

stop_services() {
  echo "Using $engine to stop containers"
  echo "-----------------------------------------"
  echo "[$(date +"%m/%d/%Y %T")]: Stopping services"
  echo "-----------------------------------------"
  stop_postgres
  stop_otel
}

DB_CONTAINER_NAME="fruits_db"
OTEL_CONTAINER_NAME="otel_lgtm"
OTEL_CPUS=""
OTEL_CPUSET_CPUS=""
OTEL_MEMORY="2g"
DB_CPUS=""
DB_CPUSET_CPUS=""
DB_MEMORY="2g"
engine=""
IS_STARTING=true
USE_HOST_NETWORKING=false

if command -v podman >/dev/null 2>&1; then
  engine="podman"
elif command -v docker >/dev/null 2>&1; then
  engine="docker"
else
  echo "Error: Neither podman nor docker can be found"
  exit_abnormal
fi

# Process the input options
while getopts "c:dg:hl:m:nop:rst:" option; do
  case $option in
    c) DB_CPUS=$OPTARG
       ;;

    d) IS_STARTING=false
       ;;

    g) OTEL_CPUSET_CPUS=$OPTARG
       ;;

    h) help
       exit
       ;;

    l) OTEL_CPUS=$OPTARG
       ;;

    m) DB_MEMORY=$OPTARG
       ;;

    n) USE_HOST_NETWORKING=true
       ;;

    o) get_otel_host_pid
       exit
       ;;

    p) DB_CPUSET_CPUS=$OPTARG
       ;;

    r) get_postgres_host_pid
       exit
       ;;

    s) IS_STARTING=true
       ;;

    t) OTEL_MEMORY=$OPTARG
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
