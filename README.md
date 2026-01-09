# spring-quarkus-perf-comparison

This application is designed to allow like-for-like performance comparisons between Spring Boot and Quarkus.

## Guiding principles 

Designing good benchmarks is hard! There are lots of trade-offs, and lots of "right" answers. 
Here are the principles we used when making implementation choices:

  - **Parity**. The application code in the Spring and Quarkus versions of the application should be strictly equivalent, and the domain models should be identical. Performance differences should come from architecture differences and library-integration optimisations in the frameworks themselves.
  - **Normal-ness**. Realism is more important than squeezing out every last bit of performance. We wanted to measure the "out of the box" performance experience. That means the use of tuning knobs are kept to a minimum. This is different from the goals for a benchmark like [TechEmpower](https://www.techempower.com/benchmarks/#section=data-r23), where the tuning aim is to get the highest absolute performance numbers.
  - **High quality**. Applications should model best practices. Although we want the application to be represent a typical usage, someone who copies it shouldn't ever be copying 'wrong' or bad code. 
  - **Easy to try at home**. Running measurements should be easy for a non-expert to do with a minimum of infrastructure setup, and it should also be rigorous in terms of performance best practices. These two goals are contradictory, unfortunately! To try and achieve both, we have two versions of the scripts, one optimised for simplicity, and one for methodological soundness.

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

These scripts are being developed.

To produce charts from the output, you can use the scripts at https://github.com/quarkusio/benchmarks.

### The best: Run tests in a controlled lab

These tests are run on a regular schedule in Red Hat/IBM performance labs.
[The scripts](https://github.com/quarkusio/spring-quarkus-perf-comparison/tree/main/scripts/perf-lab) are viewable in this repository.

#### Published results 

The results are published to https://github.com/quarkusio/benchmarks/tree/main/results/spring-quarkus-perf-comparison, and also available in an internal [Horreum](https://github.com/Hyperfoil/Horreum) instance. 
[Charts of the results](https://github.com/quarkusio/benchmarks/tree/main/images/spring-quarkus-perf-comparison) are also available. The latest results are shown below.

![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/results-latest-throughput-light.svg#gh-light-mode-only)
![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/results-latest-throughput.svg#gh-dark-mode-only)

![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/results-latest-boot-and-first-response-time-light.svg#gh-light-mode-only)
![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/results-latest-boot-and-first-response-time-dark.svg#gh-dark-mode-only)

![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/results-latest-memory-(rss)-light.svg#gh-light-mode-only)
![](https://github.com/quarkusio/benchmarks/blob/main/images/spring-quarkus-perf-comparison/results-latest-memory-(rss)-dark.svg#gh-dark-mode-only)

## Further reading 

- Why Quarkus is Fast: https://quarkus.io/performance/
- How the Quarkus team measure performance (and some anti-patterns to be aware of): https://quarkus.io/guides/performance-measure


