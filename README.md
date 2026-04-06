# spring-quarkus-perf-comparison

This application is designed to allow like-for-like performance comparisons between Spring Boot and Quarkus.

## Guiding principles 

Designing good benchmarks is hard! There are lots of trade-offs, and lots of "right" answers. 

Here are the principles we used when making implementation choices:

- **Parity**
    - The application code in the Spring and Quarkus versions of the application should be as equivalent as possible to perform the same function. This mean that the domain models should be identical, the underlying persistence mechanisms should be identical (i.e. JPA with Hibernate).
    - Performance differences should come from architecture differences and library-integration optimisations in the frameworks themselves.
    - If a change is made that changes the architecture of an application (i.e. moving blocking to reactive, using virtual threads, etc), then these changes should be applied to all the versions of the applications.
- **Normal-ness**
    - Realism is more important than squeezing out every last bit of performance.
- **High quality**
    - Applications should model best practices.
    - Although we want the application to represent a typical usage, someone who copies it shouldn't ever be copying 'wrong' or bad code. 
- **Easy to try at home**
    - Running measurements should be easy for a non-expert to do with a minimum of infrastructure setup, and it should also be rigorous in terms of performance best practices.
    - These two goals are contradictory, unfortunately! To try and achieve both, we have two versions of the scripts, one optimised for simplicity, and one for methodological soundness.
- **Testing the framework, not the infrastructure**
  -  Measurements should be measuring the performance of the frameworks, rather than supporting infrastructure like the database. In practice this means we want the experimental setup to be CPU-bound.


## Goals

Initially, we wanted to measure the "out of the box" performance experience, meaning the use of tuning knobs are kept to a minimum. This is different from the goals for a benchmark like [TechEmpower](https://www.techempower.com/benchmarks/#section=data-r23), where the aim is to tune things to get the highest absolute performance numbers. While having an out-of-the-box baseline is important, not all frameworks perform equally well out of the box. A more typical production scenario would involve tuning, so we wanted to be as fair as possible and capture that too.

To that end, we use different branches within this repository for separating the strategies. The scenario is recorded in the raw output data and visualisations, so an out-of-the-box strategy run can be recorded independently of a tuned strategy run. 

> [!IMPORTANT]
> While the strategies and outcomes may be different, each strategy should still represent the same set of [guiding principles](#guiding-principles-) when comparing applications within the strategy.

| Strategy              | Goals                                                                                                                                                                                        | Constraints                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             | Branch                                                                                                  |
|-----------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------|
| OOTB (Out of the box) | - Simplicity<br/>- Measure performance characteristics each framework provides out of the box<br/>&nbsp;&nbsp;&nbsp;&nbsp;- Does one framework provide a more "production ready" experience? | - No tuning allowed, even to fix load-related errors<br/>&nbsp;&nbsp;&nbsp;&nbsp;- Since there's no tuning, pool sizes might be different between Quarkus and Spring applications (or even between Spring 3 and Spring 4)                                                                                                                                                                                                                                                                               | [`ootb`](https://github.com/quarkusio/spring-quarkus-perf-comparison/blob/ootb)                         |
| Tuned                 | Performance                                                                                                                                                                                  | Reasonable improvements to help improve performance without changing the architecture of the application<br/>- Code and architectural equivalence are still important<br/>- Metrics and OpenTelemetry stack<br/><br/>**Acceptable**<br/>- Adjustments to HTTP/database thread/connection pool sizes<br/>- Removal of the [open session in view pattern](https://www.baeldung.com/spring-open-session-in-view)<br/><br/>**Unacceptable**<br/>- Changes specific to a fixed number of CPU cores or memory | [`main`](https://github.com/quarkusio/spring-quarkus-perf-comparison)<br/>The default repository branch |

## What's in the repo
This project contains the following modules:
- [springboot3](springboot3)
    - A Spring Boot 3.x version of the application
- [springboot4](springboot4)
    - A Spring Boot 4.x version of the application
- [quarkus3](quarkus3)
    - A Quarkus 3.x version of the application
- [quarkus3-virtual](quarkus3-virtual)
    - A Quarkus 3.x version of the application using Virtual Threads
- [quarkus3-spring-compatibility](quarkus3-spring-compatibility)
    - A Quarkus 3.x version of the application using the Spring compatibility layer. You can also recreate this application from the spring application using [a few manual steps](spring-conversion.md).
 
## Architecture & Workflow

This diagram shows the architecture & workflow of how the benchmarking executes. As you can see, the internal CI system (Jenkins) is just a wrapper around the [`run-benchmarks.sh` script](scripts/perf-lab/run-benchmarks.sh).

![workflow](docs/benchmark-workflow.png)

## Building

Each module can be built using 

```sh
./mvnw clean verify
```

You can also run `./mvnw clean verify` at the project root to build all modules. 

## Application requirements/dependencies
             
- (macOS) You need to have a `timeout` compatible command:
  - Via `coreutils` (installed via Homebrew): `brew install coreutils` but note that this will install lots of GNU utils that will duplicate native commands and prefix them with `g` (e.g. `gdate`)
  - Use [this implementation](https://github.com/aisk/timeout) via Homebrew: `brew install aisk/homebrew-tap/timeout`
  - More options at https://stackoverflow.com/questions/3504945/timeout-command-on-mac-os-x

- Base JVM Version: 21

The application expects a PostgreSQL database to be running on localhost:5432. You can use Docker or Podman to start a PostgreSQL container:

```shell
cd scripts
./infra.sh -s
```

This will start the database, create the required tables and populate them with some data.

To stop the database:

```shell
cd scripts
./infra.sh -d
```

## Scripts

There are some [scripts](scripts) available to help you run the application:
- [`run-requests.sh`](scripts/run-requests.sh)
    - Runs a set of requests against a running application.
- [`infra.sh`](scripts/infra.sh)
    - Starts/stops required infrastructure 

## Running performance comparisons

Of course you want to start generating some numbers and doing some comparisons, that's why you're here! 
There are lots of *wrong* ways to run benchmarks, and running them reliably requires a controlled environment, strong automation, and multiple machines.
Realistically, that kind of setup isn't always possible. 

Here's a range of options, from easiest to best practice. 
Remember that the easy setup will *not* be particularly accurate, but it does sidestep some of the worst pitfalls of casual benchmarking.


### Quick and dirty: Single laptop, simple scripts

Before we go any further, know that this kind of test is not going to be reliable. 
Laptops usually have a number of other processes running on them, and modern laptop CPUs are subject to power management which can wildly skew results. 
Often, some cores are 'fast' and some are 'slow', and without extra care, you don't know which core your test is running on. 
Thermal management also means 'fast' jobs get throttled, while 'slow' jobs might run at their normal speed.

Load shouldn't be generated on the same machine as the one running the workload, because the work of load generation can interfere with what's being measured. 

But if you accept all that, and know these results should be treated with caution, here's our recommendation for the least-worst way of running a quick and dirty test. 
We use [Hyperfoil](https://hyperfoil.io/https://hyperfoil.io/) instead of [wrk](https://github.com/wg/wrk), to avoid [coordinated omission](https://redhatperf.github.io/post/coordinated-omission/) issues. For simplicity, we use the [wrk2](https://github.com/giltene/wrk2) Hyperfoil bindings. 

You can run these in any order. 

#### Throughput 

The [`stress.sh`](scripts/stress.sh) script starts the infrastructure, and uses a load generator to measure
how many requests the applications can handle over a short period of time. 

```shell
scripts/stress.sh quarkus3/target/quarkus-app/quarkus-run.jar
scripts/stress.sh quarkus3-spring-compatibility/target/quarkus-app/quarkus-run.jar
scripts/stress.sh springboot3/target/springboot3.jar
```

For each test, you should see output like 

```shell
  Thread Stats   Avg      Stdev     Max   +/- Stdev
    Latency     9.58ms    6.03ms  94.90ms   85.57%
    Req/Sec   9936.90   2222.61  10593.00     95.24
```

#### RSS and time to first request 


The [`1strequest.sh`](scripts/1strequest.sh) starts the infrastructure and runs an application X times and computes the time to 1st request and RSS for each iteration as well as an average over the X iterations.

For example, 
```shell
scripts/1strequest.sh "java -XX:ActiveProcessorCount=8 -Xms512m -Xmx512m -jar quarkus3/target/quarkus-app/quarkus-run.jar" 5
scripts/1strequest.sh "java -XX:ActiveProcessorCount=8 -Xms512m -Xmx512m -jar quarkus3-spring-compatibility/target/quarkus-app/quarkus-run.jar" 5
scripts/1strequest.sh "java -XX:ActiveProcessorCount=8 -Xms512m -Xmx512m -jar springboot3/target/springboot3.jar" 5
```

You should see output like 

```shell
-------------------------------------------------
AVG RSS (after 1st request): 35.2 MB
AVG time to first request: 0.150 sec
-------------------------------------------------
```

### Acceptable: Run on a single machine, with solid automation and detailed output

These scripts are being developed, but in the mean time if you are on a Linux machine with at least 12 cores you can use the [scripts used in Red Hat/IBM performance labs](https://github.com/quarkusio/spring-quarkus-perf-comparison/tree/main/scripts/perf-lab).
To achieve this you need to pass `--host LOCAL` to the `./run-benchmarks.sh` script.
For instance, from the `scripts/perf-lab/` directory:

```shell
./run-benchmarks.sh \
  --host LOCAL \
  --drop-fs-caches \
  --runtimes quarkus3-jvm,quarkus3-virtual \
  --quarkus-version "3.32.2" \
  --output-dir ./results \
  --tests measure-time-to-first-request
```

> [!NOTE]
> `qDup`, which is used by these scripts, officially only supports the `bash` shell, so your mileage may vary if you are using a different shell.

To explore all available options (including the full list of runtimes and tests), run:

```shell
./run-benchmarks.sh --help
```

To produce charts from the output, you can use the scripts at https://github.com/quarkusio/benchmarks.

### The best: Run tests in a controlled lab

These tests are run on a regular schedule in Red Hat/IBM performance labs.
[The scripts](https://github.com/quarkusio/spring-quarkus-perf-comparison/tree/main/scripts/perf-lab) are viewable in this repository. The controlled environment and the scripts ensure workloads are isolated properly across cpus and memory without any contention between components (application under test, load generator, database, etc).

#### Published results 

The results are published to https://github.com/quarkusio/benchmarks/tree/main/results/spring-quarkus-perf-comparison, and also available in an internal [Horreum](https://github.com/Hyperfoil/Horreum) instance. 
[Charts of the results](https://github.com/quarkusio/benchmarks/tree/main/images/spring-quarkus-perf-comparison) are also available. The latest results are shown below.

##### Subset

![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-throughput-for-main-comparison-light.svg#gh-light-mode-only)
![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-throughput-for-main-comparison-dark.svg#gh-dark-mode-only)

![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-boot-and-first-response-time-for-main-comparison-light.svg#gh-light-mode-only)
![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-boot-and-first-response-time-for-main-comparison-dark.svg#gh-dark-mode-only)

![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-memory-rss-for-main-comparison-light.svg#gh-for-main-comparison-light-mode-only)
![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-memory-rss-for-main-comparison-dark.svg#gh-dark-mode-only)

##### Full set

![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-throughput-for-all-light.svg#gh-light-mode-only)
![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-throughput-for-all-dark.svg#gh-dark-mode-only)

![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-boot-and-first-response-time-for-all-light.svg#gh-light-mode-only)
![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-boot-and-first-response-time-for-all-dark.svg#gh-dark-mode-only)

![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-memory-rss-for-all-light.svg#gh-for-all-light-mode-only)
![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/tuned/results-latest-tuned-memory-rss-for-all-dark.svg#gh-dark-mode-only)

## Further reading 

- Why Quarkus is Fast: https://quarkus.io/performance/
- How the Quarkus team measure performance (and some anti-patterns to be aware of): https://quarkus.io/guides/performance-measure

# Running `run-benchmarks.sh` directly on Bare Metal

You can run the benchmark directly on a bare metal machine without the Jenkins infrastructure, which is useful for 
local development and testing.

## Prerequisites
- Linux system with at least 14 real physical cores

## Configure Passwordless sudo for Required Commands
Some commands require sudo privileges. `qDup` expects these commands to run without password prompts. To configure this, 
either create a user called `jenkins` or adapt the following instructions for your existing user.

Execute: `sudo visudo`
```text
jenkins ALL=(root) NOPASSWD: /usr/bin/tee /proc/sys/vm/drop_caches
jenkins ALL=(root) NOPASSWD: /usr/bin/tee /proc/sys/kernel/perf_event_paranoid
jenkins ALL=(root) NOPASSWD: /usr/bin/tee /proc/sys/kernel/kptr_restrict
```

## Running a Benchmark Example

The following example demonstrates how to run a benchmark with specific parameters. Adapt these values to match 
your environment:

```bash
cd scripts/perf-lab
BRANCH=main
REPO=https://github.com/quarkusio/spring-quarkus-perf-comparison.git
QDUP_USER=jenkins
./run-benchmarks.sh --repo-branch $BRANCH --scenario tuned --output-dir run --graalvm-version 25.0.2-graalce \
  --host 127.0.0.1 --iterations 1 --java-version 25.0.2-tem --repo-url $REPO --profiler none \
  --quarkus-version 3.34.1 --springboot3-version 3.5.13 --springboot4-version 4.0.5 --user $QDUP_USER \
  --wait-time 30 --run-identifier local-1 --drop-fs-caches \
  --jvm-args "-XX:+UseNUMA -Dserver.tomcat.threads.max=50 -Dserver.tomcat.threads.min-spare=50" \
  --description "Local Test" --cpus-app 0,1,2,3 --cpus-db 4,5,6 --cpus-first-request 7 --cpus-load-gen 7,8,9 \
  --cpus-monitoring 16 --cpus-otel 10,11,12 --jvm-memory "-Xmx512m -Xms512m" --runtimes quarkus3-jvm,spring4-jvm \
  --tests run-load-test
```

### Important Configuration Notes

- **CPU Allocation**: Adjust all `--cpus-*` parameters to match your system's available cores.
- **Memory Settings**: The `--jvm-memory` parameter sets both min and max heap to 512MB.
- **Versions**: Update `--graalvm-version`, `--java-version`, `--quarkus-version`, and Spring Boot versions to match 
your desired test configuration.
- **REPO**: For local development, point `REPO` to your local repository path. When using a local path, the `BRANCH` 
parameter is ignored.
