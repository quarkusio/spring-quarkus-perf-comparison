#!/bin/bash -e

# This script pushes the results of a run from ./run-benchmarks.sh as a pull request to
# https://github.com/quarkusio/spring-quarkus-perf-comparison

help() {
  echo "This script publishes benchmark results as a pull request to https://github.com/quarkusio/spring-quarkus-perf-comparison."
  echo "It assumes you have the following things installed on your machine:"
  echo "  - git (https://github.com/git-guides/install-git)"
  echo "  - GitHub CLI (https://cli.github.com)"
  echo
  echo "Syntax: push-results.sh [options]"
  echo "options:"
  echo "  -r <RUN_RESULTS_DIR>                The directory containing the results to publish"
  echo "  -t <GITHUB_TOKEN>                   The GitHub token to use to create the pull request"
}

exit_abnormal() {
  echo
  help
  exit 1
}

validate_inputs() {
  if [ -z "$RUN_RESULTS_DIR" ]; then
    echo "!! [Error] -r option MUST be specified!"
    exit_abnormal
  elif [ ! -d "$RUN_RESULTS_DIR" ]; then
    echo "!! [ERROR] directory '${RUN_RESULTS_DIR}' does not exist!"
    exit_abnormal
  fi

  if [ -z "${GITHUB_TOKEN}" ]; then
    echo "!! [ERROR] no -t option specified - it is required"
    exit_abnormal
  fi
}

sanitize_results() {
  echo "Sanitizing results to remove sensitive domain information"

  # Find all files in resultsDir and replace redhat.com and ibm.com patterns
  find ${resultsDir} -type f -exec sed -i.bak \
    -e 's/[^[:space:]]*redhat\.com/*****/g' \
    -e 's/[^[:space:]]*ibm\.com/*****/g' \
    {} +

  rm -rf ${resultsDir}/*.bak
}

push_results() {
  # Setup GH cli
  gh auth login --with-token <<< "${GITHUB_TOKEN}"

  # Make a temporary directory to clone the repo
  tempdir=$(mktemp -d)
  cd ${tempdir}

  # Check out the repo
  echo "Cloning https://github.com/quarkusio/benchmarks.git into ${tempdir}"
  git clone https://quarkusbot:${GITHUB_TOKEN}@github.com/quarkusio/benchmarks.git

  # cd into the directory
  cd benchmarks

  # Create a new branch for the PR
  git checkout -b ${branchName}

  # Copy over the results into a new directory named with the current date/time
  mkdir -p ${resultsDir}

  cp -R ${RUN_RESULTS_DIR}/* ${resultsDir}/

  # Strip out the .env section of the json
  jq 'del(.env.run)' ${resultsDir}/metrics.json > ${resultsDir}/metrics.json.tmp && \
    mv ${resultsDir}/metrics.json.tmp ${resultsDir}/metrics.json

  # Calculate the scenario
  local scenario=$(jq -r '.config.repo.scenario // ""' ${resultsDir}/metrics.json)
  local filenameSuffix="latest.json"

  if [[ -n "$scenario" ]]; then
    filenameSuffix="latest-${scenario}.json"
  fi

  # Copy the metrics.json to latest
  cp -f ${resultsDir}/metrics.json ${jobResultsDir}/results-${filenameSuffix}
  cp -f ${resultsDir}/metrics.json results/${jobName}-${filenameSuffix}

  # Sanitize the results
  sanitize_results

  # Add things to git
  git config --local user.email quarkusio+quarkusbot@gmail.com
  git config --local user.name quarkusbot
  git add results

  # Commit
  echo "Committing results"
  git commit -m "Adding results from perf lab run ${jobName}.${currentDateTime}"

  # Push the branch
  echo "Pushing results to local branch ${branchName}"
  git push -u origin ${branchName}

  # Issue a PR
  echo "Creating PR"
  gh pr create \
    -l perf-lab-run \
    -t "Adding results from perf lab run ${jobName}.${currentDateTime}" \
    -b "This PR was automatically created to add the results from the perf lab run ${jobName}.${currentDateTime}." \
    -B main

  # Log out GH CLI
  gh auth logout -u quarkusbot
}

# Setup default values
RUN_RESULTS_DIR=""
GITHUB_TOKEN=""
currentDateTime=$(date +%Y-%m-%d_%H-%M-%S)
branchName="upload-results-${currentDateTime}"
jobName="spring-quarkus-perf-comparison"
jobResultsDir="results/${jobName}"
resultsDir="${jobResultsDir}/${currentDateTime}"

# Process the inputs
while getopts "r:t:" option; do
  case $option in
    r) RUN_RESULTS_DIR=$OPTARG
      ;;

    t) GITHUB_TOKEN=$OPTARG
      ;;

    *) exit_abnormal
      ;;
  esac
done

validate_inputs
push_results
