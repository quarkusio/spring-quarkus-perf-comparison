#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../run-benchmarks.sh"

TESTS_RUN=0
TESTS_FAILED=0

assert_equals() {
  local description="$1"
  local expected="$2"
  local actual="$3"
  TESTS_RUN=$(( TESTS_RUN + 1 ))

  if [[ "$actual" == "$expected" ]]; then
    echo "PASS: ${description}"
  else
    echo "FAIL: ${description} (expected ${expected}, got ${actual})"
    TESTS_FAILED=$(( TESTS_FAILED + 1 ))
  fi
}

test_count_cpus() {
  assert_equals "single cpu (0)" \
    "1" "$(count_cpus "0")"

  assert_equals "single cpu (5)" \
    "1" "$(count_cpus "5")"

  assert_equals "simple range (0-3)" \
    "4" "$(count_cpus "0-3")"

  assert_equals "simple range (4-7)" \
    "4" "$(count_cpus "4-7")"

  assert_equals "step range (0-7:2)" \
    "4" "$(count_cpus "0-7:2")"

  assert_equals "step range (0-15:4)" \
    "4" "$(count_cpus "0-15:4")"

  assert_equals "comma-separated singles (0,1,2,3)" \
    "4" "$(count_cpus "0,1,2,3")"

  assert_equals "range + single (0-3,8)" \
    "5" "$(count_cpus "0-3,8")"

  assert_equals "range + singles (0-3,8,10-12)" \
    "8" "$(count_cpus "0-3,8,10-12")"

  assert_equals "range + step range (0-3,8-14:2)" \
    "8" "$(count_cpus "0-3,8-14:2")"

  assert_equals "multiple ranges (0-3,8-11)" \
    "8" "$(count_cpus "0-3,8-11")"
}

assert_succeeds() {
  local description="$1"
  shift
  TESTS_RUN=$(( TESTS_RUN + 1 ))

  if "$@"; then
    echo "PASS: ${description}"
  else
    echo "FAIL: ${description} (expected success)"
    TESTS_FAILED=$(( TESTS_FAILED + 1 ))
  fi
}

assert_fails() {
  local description="$1"
  shift
  TESTS_RUN=$(( TESTS_RUN + 1 ))

  if "$@"; then
    echo "FAIL: ${description} (expected failure)"
    TESTS_FAILED=$(( TESTS_FAILED + 1 ))
  else
    echo "PASS: ${description}"
  fi
}

test_is_allowed_value() {
  local allowed=("quarkus4-jvm" "quarkus4-native" "spring4-jvm")

  assert_succeeds "exact match is allowed" \
    is_allowed_value "quarkus4-jvm" "${allowed[@]}"

  assert_fails "prefix of an allowed value is rejected (quarkus4)" \
    is_allowed_value "quarkus4" "${allowed[@]}"

  assert_fails "suffix of an allowed value is rejected (jvm)" \
    is_allowed_value "jvm" "${allowed[@]}"

  assert_fails "unknown value is rejected" \
    is_allowed_value "quarkus5-jvm" "${allowed[@]}"

  assert_fails "empty value is rejected" \
    is_allowed_value "" "${allowed[@]}"
}

# --- Run tests ---

test_count_cpus
test_is_allowed_value

# --- Summary ---

echo ""
echo "${TESTS_RUN} tests run, ${TESTS_FAILED} failed."

if [[ "${TESTS_FAILED}" -gt 0 ]]; then
  exit 1
fi
