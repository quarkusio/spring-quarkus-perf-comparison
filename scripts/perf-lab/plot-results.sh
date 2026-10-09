#!/usr/bin/env bash
set -e

# This script takes the output of a perf-lab run and plots it using the
# Quarkus benchmarks graphics generator from https://github.com/quarkusio/benchmarks

help() {
  echo "This script generates charts from perf-lab benchmark results."
  echo "It uses the graphics generator from https://github.com/quarkusio/benchmarks"
  echo
  echo "Syntax: plot-results.sh [options]"
  echo "options:"
  echo "  -i <INPUT_DIR>          The directory containing the benchmark results (must contain metrics.json)"
  echo "                          If not specified, will use the most recent run in /tmp"
  echo "  -o <OUTPUT_DIR>         The directory where charts will be generated (default: <INPUT_DIR>/charts)"
  echo "  -b <BENCHMARKS_REPO>    Path to local clone of benchmarks repo (optional, will clone if not provided)"
  echo "  -c                      Clean build the graphics generator (default: false)"
  echo "  -h                      Display this help message"
  echo
  echo "Examples:"
  echo "  ./plot-results.sh                                          # Use most recent run in /tmp"
  echo "  ./plot-results.sh -i /tmp/20251021_090429/target-host      # Specify exact directory"
  echo "  ./plot-results.sh -i /tmp/20251021_090429/target-host -o /tmp/charts"
  echo "  ./plot-results.sh -b /path/to/benchmarks                   # Use existing benchmarks repo"
}

exit_abnormal() {
  echo
  help
  exit 1
}

find_latest_run() {
  # Look for the most recent timestamped directory in /tmp that contains target-host/metrics.json
  # qDup creates directories like /tmp/20251021_090429/
  local latest_run=$(find /tmp -maxdepth 2 -type f -name "metrics.json" -path "*/target-host/metrics.json" 2>/dev/null | \
    sed 's|/target-host/metrics.json||' | \
    sort -r | \
    head -n 1)
  
  if [ -n "$latest_run" ]; then
    echo "${latest_run}/target-host"
  fi
}

validate_inputs() {
  # If no input directory specified, try to find the most recent run
  if [ -z "$INPUT_DIR" ]; then
    echo "No input directory specified, searching for most recent run in /tmp..."
    INPUT_DIR=$(find_latest_run)
    
    if [ -z "$INPUT_DIR" ]; then
      echo "!! [ERROR] No benchmark results found in /tmp!"
      echo "!! Please run benchmarks first or specify -i option with the results directory."
      exit_abnormal
    fi
    
    echo "Found most recent run: ${INPUT_DIR}"
  fi

  if [ ! -d "$INPUT_DIR" ]; then
    echo "!! [ERROR] Input directory '${INPUT_DIR}' does not exist!"
    exit_abnormal
  fi

  if [ ! -f "$INPUT_DIR/metrics.json" ]; then
    echo "!! [ERROR] metrics.json not found in '${INPUT_DIR}'!"
    echo "!! Make sure you're pointing to the correct results directory (usually <run-output>/target-host/)"
    exit_abnormal
  fi

  # Set default output directory if not specified
  if [ -z "$OUTPUT_DIR" ]; then
    OUTPUT_DIR="${INPUT_DIR}/charts"
  fi

  # Create output directory if it doesn't exist
  mkdir -p "$OUTPUT_DIR"
}

setup_benchmarks_repo() {
  if [ -n "$BENCHMARKS_REPO" ]; then
    if [ ! -d "$BENCHMARKS_REPO" ]; then
      echo "!! [ERROR] Specified benchmarks repo path '${BENCHMARKS_REPO}' does not exist!"
      exit 1
    fi
    echo "Using existing benchmarks repo at: ${BENCHMARKS_REPO}"
  else
    # Clone to a temporary directory
    BENCHMARKS_REPO=$(mktemp -d)
    echo "Cloning benchmarks repo to: ${BENCHMARKS_REPO}"
    git clone --depth 1 https://github.com/quarkusio/benchmarks.git "$BENCHMARKS_REPO"
    CLEANUP_REPO=true
  fi

  GRAPHICS_GENERATOR_DIR="${BENCHMARKS_REPO}/graphics-generator"
  
  if [ ! -d "$GRAPHICS_GENERATOR_DIR" ]; then
    echo "!! [ERROR] graphics-generator directory not found in benchmarks repo!"
    exit 1
  fi
}

build_graphics_generator() {
  echo "Building graphics generator..."
  cd "$GRAPHICS_GENERATOR_DIR"
  
  if [ "$CLEAN_BUILD" = true ]; then
    echo "Performing clean build..."
    ./mvnw clean verify -DskipTests
  else
    # Check if already built
    if [ -f "target/quarkus-app/quarkus-run.jar" ]; then
      echo "Graphics generator already built, skipping build (use -c to force clean build)"
    else
      echo "Building graphics generator for the first time..."
      ./mvnw verify -DskipTests
    fi
  fi
  
  if [ ! -f "target/quarkus-app/quarkus-run.jar" ]; then
    echo "!! [ERROR] Build failed - quarkus-run.jar not found!"
    exit 1
  fi
  
  cd - > /dev/null
}

generate_charts() {
  echo "Generating charts from: ${INPUT_DIR}/metrics.json"
  echo "Output directory: ${OUTPUT_DIR}"
  
  # The graphics generator expects:
  # java -jar target/quarkus-app/quarkus-run.jar <input-file-or-dir> <output-dir> [generate-dark-theme]
  # The third parameter (true/false) controls whether to generate dark theme variants
  
  java -jar "${GRAPHICS_GENERATOR_DIR}/target/quarkus-app/quarkus-run.jar" \
    "${INPUT_DIR}/metrics.json" \
    "${OUTPUT_DIR}" \
    true
  
  echo
  echo "✓ Charts generated successfully!"
  echo "  Location: ${OUTPUT_DIR}"
  echo
  echo "Generated files:"
  ls -lh "${OUTPUT_DIR}"
}

cleanup() {
  if [ "$CLEANUP_REPO" = true ] && [ -n "$BENCHMARKS_REPO" ]; then
    echo "Cleaning up temporary benchmarks repo..."
    rm -rf "$BENCHMARKS_REPO"
  fi
}

# Trap to ensure cleanup happens even on error
trap cleanup EXIT

# Setup default values
INPUT_DIR=""
OUTPUT_DIR=""
BENCHMARKS_REPO=""
CLEAN_BUILD=false
CLEANUP_REPO=false

# Process the inputs
while getopts "i:o:b:ch" option; do
  case $option in
    i) INPUT_DIR="$OPTARG"
      ;;
    
    o) OUTPUT_DIR="$OPTARG"
      ;;
    
    b) BENCHMARKS_REPO="$OPTARG"
      ;;
    
    c) CLEAN_BUILD=true
      ;;
    
    h) help
       exit 0
      ;;
    
    *) exit_abnormal
      ;;
  esac
done

validate_inputs
setup_benchmarks_repo
build_graphics_generator
generate_charts
