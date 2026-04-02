# Benchmarks

This is the main entrypoint for running benchmarks.

> [!IMPORTANT]
> Please read the [Running performance comparisons documentation](../../README.md#running-performance-comparisons)!!! This is super important to understand how benchmarks work!

Now that you've read that (if you haven't, please go do so now) here's the details on how to run on a single machine, with solid automation and detailed reporting.

The main tool for scripting the automation is [qDup](https://github.com/Hyperfoil/qDup). qDup supports running on the local machine as well as on a remote host.

The [`main.yml`](main.yml) file is the main entrypoint for qDup. It defines the sequence of steps to run and ensures all the required tools are installed on the host the benchmark is being run on.

> [!NOTE]
> This is also the same benchmark we run in our controlled performance lab environment. We have dedicated hardware for this purpose.

The main entrypoint is the `run-benchmarks.sh` script. This script has many options that can be passed in. Run `./run-benchmarks.sh -h` to see them all.

> [!TIP]
> This automation currently supports Linux and macOS hosts. Running on Windows Subsystem for Linux (WSL) has not been tested. Running on Windows directly is not supported.
> 
> ALSO - it only supports `bash` shell on both local & remote hosts.

The script also has 3 dependencies that need to be resolved before it can be run:
- [git](https://github.com/git-guides/install-git)
- [jbang](https://www.jbang.dev/download)
- [jq](https://stedolan.github.io/jq)
- bash shell

> [!IMPORTANT]
> There are several requirements to run the benchmarks:
> 1. The host must have `bash` shell installed.
> 2. If running on a remote host, the ssh connection to the remote host must be configured to allow [passwordless login](https://www.strongdm.com/blog/ssh-passwordless-login).
> 3. If running on Linux, the user on the host (local or remote) must have [passwordless sudo privileges](https://unix.stackexchange.com/questions/468416/setting-up-passwordless-sudo-on-linux-distributions).
>     - If this isn't an option, then the host must have the following software installed (see [requirements.yml](helpers/requirements.yml) for details):
>         - [SDKMAN!](https://sdkman.io/)
>             - `sdk i java <-j flag passed to the script>`
>             - `sdk i java <-g flag passed to the script>`
>             - `export GRAALVM_HOME=$(sdk home java <-g flag passed to the script>)`
>         - [git](https://github.com/git-guides/install-git)
>         - [jbang](https://www.jbang.dev/download)
>         - [jq](https://stedolan.github.io/jq)
>         - gcc
>         - [NVM](https://github.com/nvm-sh/nvm/blob/master/README.md)
>             - `nvm install --lts`
>             - `nvm use --lts`

## Usage

```bash
./run-benchmarks.sh [options]
```

### Options

| Option                           | Parameter                     | Description                                                                                                                                                                                                             | Default                                                                                                              |
|----------------------------------|-------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------|
| `--cpus-app`                     | `<CPUS_APP>`                  | CPU list for the application                                                                                                                                                                                            | `0,2,4,6`                                                                                                            |
| `--cpus-db`                      | `<CPUS_DB>`                   | CPU list for the database                                                                                                                                                                                               | `8,10,12`                                                                                                            |
| `--cpus-first-request`           | `<CPUS_FIRST_REQUEST>`        | CPU for time-to-first-request measurement                                                                                                                                                                               | `9`                                                                                                                  |
| `--cpus-load-gen`                | `<CPUS_LOAD_GEN>`             | CPU list for the load generator                                                                                                                                                                                         | `1,3,5`                                                                                                              |
| `--cpus-monitoring`              | `<CPUS_MONITORING>`           | CPU for monitoring                                                                                                                                                                                                      | `7`                                                                                                                  |
| `--drop-fs-caches`               |                               | Purge/drop OS filesystem caches between iterations                                                                                                                                                                      |                                                                                                                      |
| `--extra-qdup-args`              | `<EXTRA_QDUP_ARGS>`           | Any extra arguments that need to be passed to qDup ahead of the qDup scripts<br/>**NOTE:** This is an advanced option. Make sure you know what you are doing when using it.                                             |                                                                                                                      |
| `--graalvm-home`                 | `<GRAALVM_HOME>`              | Path to a locally installed GraalVM/Mandrel distribution<br/>If set, this takes precedence over `--graalvm-version`                                                                                                     |                                                                                                                      |
| `--graalvm-version`              | `<GRAALVM_VERSION>`           | The GraalVM version to use if running any native tests (from SDKMAN)<br/>Ignored if `--graalvm-home` is set                                                                                                             | `25.0.1-graalce`                                                                                                     |
| `--host`                         | `<HOST>`                      | The HOST to run the benchmarks on<br/>`LOCAL` is a keyword that can be used to run everything on the local machine                                                                                                      | `LOCAL`                                                                                                              |
| `--iterations`                   | `<ITERATIONS>`                | The number of iterations to run each test                                                                                                                                                                               | `3`                                                                                                                  |
| `--java-home`                    | `<JAVA_HOME>`                 | Path to a locally installed Java distribution<br/>If set, this takes precedence over `--java-version`                                                                                                                   |                                                                                                                      |
| `--java-version`                 | `<JAVA_VERSION>`              | The Java version to use (from SDKMAN)<br/>Ignored if `--java-home` is set                                                                                                                                               | `25.0.1-tem`                                                                                                         |
| `--jvm-args`                     | `<JVM_ARGS>`                  | Any runtime JVM args to be passed to the apps                                                                                                                                                                           |                                                                                                                      |
| `--jvm-memory`                   | `<JVM_MEMORY>`                | JVM Memory setting (i.e. -Xmx -Xmn -Xms)                                                                                                                                                                                |                                                                                                                      |
| `--native-quarkus-build-options` | `<NATIVE_QUARKUS_OPTS>`       | Native build options to be passed to Quarkus native build process                                                                                                                                                       |                                                                                                                      |
| `--native-spring3-build-options` | `<NATIVE_SPRING3_OPTS>`       | Native build options to be passed to Spring 3.x native build process                                                                                                                                                    |                                                                                                                      |
| `--native-spring4-build-options` | `<NATIVE_SPRING4_OPTS>`       | Native build options to be passed to Spring 4.x native build process                                                                                                                                                    |                                                                                                                      |
| `--output-dir`                   | `<OUTPUT_DIR>`                | The directory containing the run output                                                                                                                                                                                 | `/tmp`                                                                                                               |
| `--profiler`                     | `<PROFILER>`                  | Enable profiling with async profiler<br/>Accepted values: `none`, `jfr`, `flamegraph`                                                                                                                                   | `none`                                                                                                               |
| `--quarkus-build-config-args`    | `<QUARKUS_BUILD_CONFIG_ARGS>` | Quarkus app configuration properties fixed at build time                                                                                                                                                                |                                                                                                                      |
| `--quarkus-version`              | `<QUARKUS_VERSION>`           | The Quarkus version to use<br/>**NOTE:** Its a good practice to set this manually to ensure proper version                                                                                                              | Whatever version is set in pom.xml of the Quarkus app                                                                |
| `--repo-branch`                  | `<SCM_REPO_BRANCH>`           | The branch in the SCM repo                                                                                                                                                                                              | `main`                                                                                                               |
| `--repo-url`                     | `<SCM_REPO_URL>`              | The SCM repo url                                                                                                                                                                                                        | `https://github.com/quarkusio/spring-quarkus-perf-comparison.git`                                                    |
| `--runtimes`                     | `<RUNTIMES>`                  | The runtimes to test, separated by commas<br/>Accepted values (1 or more of): `quarkus3-jvm`, `quarkus3-native`, `spring3-jvm`, `spring3-jvm-aot`, `spring3-native`, `spring4-jvm`, `spring4-jvm-aot`, `spring4-native` | `quarkus3-jvm,quarkus3-native,spring3-jvm,spring3-native,spring4-jvm,spring4-native`                                 |
| `--springboot3-version`          | `<SPRING_BOOT3_VERSION>`      | The Spring Boot 3.x version to use<br/>**NOTE:** Its a good practice to set this manually to ensure proper version                                                                                                      | Whatever version is set in pom.xml of the Spring Boot 3 app                                                          |
| `--springboot4-version`          | `<SPRING_BOOT4_VERSION>`      | The Spring Boot 4.x version to use<br/>**NOTE:** Its a good practice to set this manually to ensure proper version                                                                                                      | Whatever version is set in pom.xml of the Spring Boot 4 app                                                          |
| `--tests`                        | `<TESTS_TO_RUN>`              | The tests to run, separated by commas<br/>Accepted values (1 or more of): `test-build`, `measure-build-times`, `measure-time-to-first-request`, `measure-rss`, `run-load-test`                                          | `test-build,measure-build-times,measure-time-to-first-request,measure-rss,run-load-test`                             |
| `--user`                         | `<USER>`                      | The user on `<HOST>` to run the benchmark                                                                                                                                                                               |                                                                                                                      |
| `--wait-time`                    | `<WAIT_TIME>`                 | Wait time (in seconds) to wait for things like application startup                                                                                                                                                      | `20`                                                                                                                 |

### Proper CPU affinity

Proper CPU affinity is important for the performance of the benchmark to ensure proper isolation of the workloads.

You need to have enough cpus in order to run this script. We recommend 12 cpus minimum allocated as follows:
- 4 CPUs for the application
- 3 CPUs for the database
- 3 CPUs for the load generator
- 1 CPU for monitoring the system during test execution
- 1 CPU for the time to first request measurement

Using a tool like `lscpu -e` can help you understand how many CPUs you have available and how best to allocate them. It's important to avoid sharing physical cores between workloads and keep workloads on the same NUMA node when possible.

For example, `lscpu -e` reports the following in our lab environment:

```
CPU NODE SOCKET CORE L1d:L1i:L2:L3 ONLINE    MAXMHZ    MINMHZ       MHZ
  0    0      0    0 0:0:0:0          yes 3900.0000 1000.0000 3900.0000
  1    1      1    1 16:16:16:1       yes 3900.0000 1000.0000 3900.0000
  2    0      0    2 7:7:7:0          yes 3900.0000 1000.0000 3900.0000
  3    1      1    3 23:23:23:1       yes 3900.0000 1000.0000 3900.0000
  4    0      0    4 1:1:1:0          yes 3900.0000 1000.0000 3900.0000
  5    1      1    5 17:17:17:1       yes 3900.0000 1000.0000 3900.0000
  6    0      0    6 6:6:6:0          yes 3900.0000 1000.0000 3900.0000
  7    1      1    7 22:22:22:1       yes 3900.0000 1000.0000 3900.0000
  8    0      0    8 2:2:2:0          yes 3900.0000 1000.0000 3900.0000
  9    1      1    9 18:18:18:1       yes 3900.0000 1000.0000 3900.0000
 10    0      0   10 5:5:5:0          yes 3900.0000 1000.0000 3900.0000
 11    1      1   11 21:21:21:1       yes 3900.0000 1000.0000 2800.6411
 12    0      0   12 3:3:3:0          yes 3900.0000 1000.0000 3900.0000
 13    1      1   13 19:19:19:1       yes 3900.0000 1000.0000 3900.0000
 14    0      0   14 4:4:4:0          yes 3900.0000 1000.0000 3900.0000
 15    1      1   15 20:20:20:1       yes 3900.0000 1000.0000 2799.9961
 16    0      0   16 8:8:8:0          yes 3900.0000 1000.0000 3900.0000
 17    1      1   17 24:24:24:1       yes 3900.0000 1000.0000 3900.0000
 18    0      0   18 15:15:15:0       yes 3900.0000 1000.0000 3900.0000
 19    1      1   19 31:31:31:1       yes 3900.0000 1000.0000 3900.0000
 20    0      0   20 9:9:9:0          yes 3900.0000 1000.0000 3900.0000
 21    1      1   21 25:25:25:1       yes 3900.0000 1000.0000 3900.0000
 22    0      0   22 14:14:14:0       yes 3900.0000 1000.0000 3900.0000
 23    1      1   23 30:30:30:1       yes 3900.0000 1000.0000 3900.0000
 24    0      0   24 10:10:10:0       yes 3900.0000 1000.0000 3900.0000
 25    1      1   25 26:26:26:1       yes 3900.0000 1000.0000 3900.0000
 26    0      0   26 13:13:13:0       yes 3900.0000 1000.0000 3900.0000
 27    1      1   27 29:29:29:1       yes 3900.0000 1000.0000 3900.0000
 28    0      0   28 11:11:11:0       yes 3900.0000 1000.0000 3900.0000
 29    1      1   29 27:27:27:1       yes 3900.0000 1000.0000 3900.0000
 30    0      0   30 12:12:12:0       yes 3900.0000 1000.0000 3900.0000
 31    1      1   31 28:28:28:1       yes 3900.0000 1000.0000 2801.5439
 32    0      0    0 0:0:0:0          yes 3900.0000 1000.0000 3900.0000
 33    1      1    1 16:16:16:1       yes 3900.0000 1000.0000 3900.0000
 34    0      0    2 7:7:7:0          yes 3900.0000 1000.0000 3900.0000
 35    1      1    3 23:23:23:1       yes 3900.0000 1000.0000 3900.0000
 36    0      0    4 1:1:1:0          yes 3900.0000 1000.0000 3900.0000
 37    1      1    5 17:17:17:1       yes 3900.0000 1000.0000 3900.0000
 38    0      0    6 6:6:6:0          yes 3900.0000 1000.0000 3900.0000
 39    1      1    7 22:22:22:1       yes 3900.0000 1000.0000 3900.0000
 40    0      0    8 2:2:2:0          yes 3900.0000 1000.0000 3900.0000
 41    1      1    9 18:18:18:1       yes 3900.0000 1000.0000 3900.0000
 42    0      0   10 5:5:5:0          yes 3900.0000 1000.0000 3900.0000
 43    1      1   11 21:21:21:1       yes 3900.0000 1000.0000 3900.0000
 44    0      0   12 3:3:3:0          yes 3900.0000 1000.0000 3900.0000
 45    1      1   13 19:19:19:1       yes 3900.0000 1000.0000 2800.0010
 46    0      0   14 4:4:4:0          yes 3900.0000 1000.0000 3900.0000
 47    1      1   15 20:20:20:1       yes 3900.0000 1000.0000 3900.0000
 48    0      0   16 8:8:8:0          yes 3900.0000 1000.0000 3900.0000
 49    1      1   17 24:24:24:1       yes 3900.0000 1000.0000 3900.0000
 50    0      0   18 15:15:15:0       yes 3900.0000 1000.0000 3900.0000
 51    1      1   19 31:31:31:1       yes 3900.0000 1000.0000 3900.0000
 52    0      0   20 9:9:9:0          yes 3900.0000 1000.0000 3900.0000
 53    1      1   21 25:25:25:1       yes 3900.0000 1000.0000 3900.0000
 54    0      0   22 14:14:14:0       yes 3900.0000 1000.0000 3900.0000
 55    1      1   23 30:30:30:1       yes 3900.0000 1000.0000 3900.0000
 56    0      0   24 10:10:10:0       yes 3900.0000 1000.0000 3900.0000
 57    1      1   25 26:26:26:1       yes 3900.0000 1000.0000 3900.0000
 58    0      0   26 13:13:13:0       yes 3900.0000 1000.0000 3900.0000
 59    1      1   27 29:29:29:1       yes 3900.0000 1000.0000 3900.0000
 60    0      0   28 11:11:11:0       yes 3900.0000 1000.0000 3900.0000
 61    1      1   29 27:27:27:1       yes 3900.0000 1000.0000 3900.0000
 62    0      0   30 12:12:12:0       yes 3900.0000 1000.0000 3900.0000
 63    1      1   31 28:28:28:1       yes 3900.0000 1000.0000 3900.0000
```

We can make some assumptions from looking at the `lscpu -e` output:

The system has `64` logical CPUs total
- The table has 64 rows (CPU 0 through CPU 63), one per logical CPU.

There are `2` sockets / `2` [NUMA](https://en.wikipedia.org/wiki/Non-uniform_memory_access) nodes
- The `SOCKET` column contains only values `0` and `1`, and the `NODE` column mirrors it exactly 
- There are 2 physical sockets, each corresponding to one NUMA node

There are `32` physical cores (`16` per socket)
- The CORE column lists values 0–31, but each value appears exactly twice across the full table.
- That repetition is the hyperthreading signature: one physical core → two logical CPUs.
    - 64 logical CPUs ÷ 2 = 32 physical cores, split evenly as 16 per socket.

Hyperthreading sibling pairing (N and N+32)
- CPUs `0–31` and CPUs `32–63` share identical `CORE` and cache (L1d:L1i:L2:L3) values in pairs (e.g., CPU 0 and CPU 32 both map to CORE 0 with cache set 0:0:0:0), confirming the sibling relationship.

Even/odd CPU index → Socket 0 / Socket 1
- Looking at the `SOCKET` column, even-indexed CPUs (0, 2, 4, …, 30 and their siblings 32, 34, …, 62) all belong to Socket 0, while odd-indexed CPUs (1, 3, 5, …, 31 and siblings 33, 35, …, 63) belong to Socket 1.

**Key principle:** Avoid sharing physical cores between workloads (no hyperthreading siblings across workload boundaries), and keep workloads on the same NUMA node when possible.

**Recommended allocation** (using whole physical cores, avoiding hyperthreading siblings across workloads):

| Workload                      | CPUs       | NUMA Node |
|-------------------------------|------------|-----------|
| Application (4 CPUs)          | `2,4,6,8`  | Socket 0  |
| Database (3 CPUs)             | `10,12,14` | Socket 0  |
| Load generator (3 CPUs)       | `22,24,26` | Socket 0  |
| System monitor (1 CPU)        | `28`       | Socket 0  |
| Time-to-first-request (1 CPU) | `22`       | Socket 0  |

**Rationale:**
- All workloads are on Socket 0 (same NUMA node).
- Leave CPU 0 (and its sibling 32) entirely free for the OS and IRQ handling. All 15 remaining Socket 0 physical cores cover the workload exactly.
- The **application** gets Socket 0 cores to benefit from shared L3 cache with the **database** (also Socket 0) — this minimizes cross-NUMA latency for DB calls.
- The **database** stays on Socket 0 too, close to the app.
- The time to first request (TTFR) workload can share one of the same CPUs as the load generator because those two tests never run at the same time.
- **No hyperthreading siblings are shared** between workloads, eliminating contention on shared execution units, L1/L2 caches.

This approach uses 14 out of 32 physical cores (no hyperthreading), leaving the remaining cores free for the OS and other system processes. This is also why the defaults are set the way they are

### Available Runtimes

The `-r` option accepts one or more of the following values (comma-separated):

- `quarkus3-jvm` - [Quarkus 3](../../quarkus3) on JVM
- `quarkus3-native` - [Quarkus 3](../../quarkus3) native executable
- `spring4-jvm` - [Spring Boot 4](../../springboot4) on JVM
- `spring4-jvm-aot` - [Spring Boot 3](../../springboot4) on JVM with AOT compilation
- `spring4-native` - [Spring Boot 3](../../springboot4) native executable
- `spring3-jvm` - [Spring Boot 3](../../springboot3) on JVM
- `spring3-jvm-aot` - [Spring Boot 3](../../springboot3) on JVM with AOT compilation
- `spring3-native` - [Spring Boot 3](../../springboot3) native executable

**Default:** All runtimes except `spring3-jvm-aot` and `spring4-jvm-aot` are tested. To include AOT variants, pass them explicitly via `--runtimes`.

### Available Tests

The `-t` option accepts one or more of the following values (comma-separated):

| Test Name                       | Description                                                               | Notes                                                                                                                                                                                   |
|---------------------------------|---------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `test-build`                    | Verifies that the applications build successfully                         | There aren't any actual metrics reported for this test                                                                                                                                  |
| `measure-build-times`           | Measure application build times                                           | `Build RSS`, `# of classes/fields/methods`, and `# of classes/fields/methods using reflection` are also calculated if any of the [`native` runtimes](#available-runtimes) are selected. |
| `measure-time-to-first-request` | Measure startup time to first request                                     |                                                                                                                                                                                         |
| `measure-rss`                   | Measure Resident Set Size (memory usage) at startup and after 1st request |                                                                                                                                                                                         |
| `run-load-test`                 | Run load testing scenarios                                                | Calculates max throughput, peak RSS, and throughput density (i.e. at max throughput, how many req/sec per MB of memory needed for capacity planning)                                    |

**Default:** All tests are executed

## Output
The output of the run will be a bunch of files, whose location will be output at the end of the run:

```shell
09:14:14.985 run-1761051869844 downloading queued downloads
09:14:14.985 Local.download(hyperfoil@deathstar:22:/tmp/metrics.json,/tmp/20251021_090429/target-host/)
09:14:15.375 Local.download(hyperfoil@deathstar:22:/home/hyperfoil/spring-quarkus-perf-comparison/logs/*,/tmp/20251021_090429/target-host/)
Finished in 09:44.800 at /tmp/20251021_090429 
```

If you examine the output directory:

```shell
├── run.json
├── run.log
└── target-host
    ├── build-times-quarkus3-jvm-0.log
    ├── build-times-quarkus3-jvm-1.log
    ├── build-times-quarkus3-jvm-2.log
    ├── build-times-quarkus3-native-0.log
    ├── build-times-quarkus3-native-1.log
    ├── build-times-quarkus3-native-2.log
    ├── build-times-spring3-jvm-0.log
    ├── build-times-spring3-jvm-1.log
    ├── build-times-spring3-jvm-2.log
    ├── build-times-spring3-jvm-aot-0.log
    ├── build-times-spring3-jvm-aot-1.log
    ├── build-times-spring3-jvm-aot-2.log
    ├── build-times-spring3-native-0.log
    ├── build-times-spring3-native-1.log
    ├── build-times-spring3-native-2.log
    └── <potentially more .log files based on which tests were run>
    └── metrics.json
```

- The `run.json` file contains the run metadata.
- The `run.log` file contains the full run log.
- All of the `target-host/*.log` files contain the output from the individual tests.
- The `target-host/metrics.json` file contains all the recorded metrics.

## Examples
### Basic Local Benchmark

Runs [all the tests](#available-tests) against [all the runtimes](#available-runtimes) using Quarkus version `3.28.4` and Spring Boot version `3.5.6`.

```shell
./run-benchmarks.sh --quarkus-version 3.28.4 --springboot3-version 3.5.6
```

### JVM tests only

Runs [all the tests](#available-tests) only the JVM runtimes using Quarkus version `3.30.5` and Spring Boot versions `3.5.9` & `4.0.1`.

```shell
./run-benchmarks.sh --quarkus-version 3.30.5 --springboot3-version 3.5.9 --springboot4-version 4.0.1 --runtimes 'quarkus3-jvm,spring4-jvm,spring3-jvm'
```

### Run all the benchmarks on a remote host from a different fork

Runs [all the tests](#available-tests) against [all the runtimes](#available-runtimes) using Quarkus version `3.28.4` and Spring Boot version `3.5.6` on a remote host, while pulling the benchmarks from the `open-benchmarks` branch on the https://github.com/edeandrea/spring-quarkus-perf-comparison.git repo, and running 5 iterations of each test.

```shell
 ./run-benchmarks.sh \
    --user <REMOTE_USER> \
    --host <REMOTE_HOST> \
    --quarkus-version 3.28.4 \
    --springboot3-version 3.5.6 \
    --springboot4-version 4.0.1 \
    --tests 'measure-build-times,measure-time-to-first-request,measure-rss,run-load-test' \
    --runtimes 'quarkus3-jvm,quarkus3-native,spring4-jvm,spring4-jvm-aot,spring4-native,spring3-jvm,spring3-jvm-aot,spring3-native' \
    --iterations 5 \
    --repo-url https://github.com/<some_user>/spring-quarkus-perf-comparison.git \
    --repo-branch another-branch \
    --drop-fs-caches
```


## Notes

- **Version Specification:** It is strongly recommended to explicitly set the Quarkus and Spring Boot versions to ensure consistent and reproducible benchmarks.
- **Remote Execution:** When using a HOST other than `LOCAL`, the `--user` (USER) parameter is required.
- **Resource Constraints:** The `--cpus-*` options (CPU affinity) and `--jvm-memory` (memory constraints) use `taskset` to control resource allocation. Use `lscpu -e` to understand CPU topology and avoid sharing physical cores between workloads.
- **Profiling:** When profiling is enabled, async profiler will be used to generate JFR files or flamegraphs depending on the selected option.

## Exit Codes

- **0** - Successful execution
- **1** - Error occurred (missing required parameters, invalid options, etc.)
