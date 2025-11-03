#!/bin/bash
set -euo pipefail
thisdir="$(realpath $(dirname "$0"))"

help() {
  echo "This script starts the necessary services for the app in question"
  echo
  echo "Syntax: infra.sh [options]"
  echo "options:"
  echo " -d                    Destroy the services"
  echo " -h                    Prints this help message"
  echo " -s                    Start the services"
}

exit_abnormal() {
  echo
  help
  exit 1
}

start_postgres() {
  echo "Starting PostgreSQL database '${DB_CONTAINER_NAME}'"
  local pid=$(${engine} run \
    -d \
    --rm \
    --name ${DB_CONTAINER_NAME} \
    --mount type=tmpfs,destination=/var/lib/postgresql \
    -v ${thisdir}/dbdata:/docker-entrypoint-initdb.d:O \
    -p 5432:5432 \
    -e POSTGRES_USER=fruits \
    -e POSTGRES_PASSWORD=fruits \
    -e POSTGRES_DB=fruits \
    postgres:17 \
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
  timeout 90s bash -c "until ${engine} exec $DB_CONTAINER_NAME pg_isready ; do sleep 5 ; done"
}

stop_postgres() {
  echo "Stopping PostgreSQL database '${DB_CONTAINER_NAME}'"
  ${engine} stop ${DB_CONTAINER_NAME}
}

start_services() {
  echo "-----------------------------------------"
  echo "[$(date +"%m/%d/%Y %T")]: Starting services"
  echo "-----------------------------------------"
  start_postgres
}

stop_services() {
  echo "-----------------------------------------"
  echo "[$(date +"%m/%d/%Y %T")]: Stopping services"
  echo "-----------------------------------------"
  stop_postgres
}

if [ "$#" -ne 1 ]; then
  exit_abnormal
fi

DB_CONTAINER_NAME="fruits_db"

engine=""

if command -v podman >/dev/null 2>&1; then
  engine="podman"
elif command -v docker >/dev/null 2>&1; then
  engine="docker"
else
  echo "Error: Neither podman nor docker can be found"
  exit_abnormal
fi

echo "Using $engine to start/stop containers"

# Process the input options
while getopts "dhs" option; do
  case $option in
    d) stop_services
       exit
       ;;

    h) help
       exit
       ;;

    s) start_services
       exit
       ;;

    *) exit_abnormal
       ;;
  esac
done