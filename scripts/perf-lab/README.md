# Benchmarks

This is the main entrypoint for running benchmarks.

> [!IMPORTANT]
> Please read the [Running performance comparisons documentation](../README.md#running-performance-comparisons)!!! This is super important to understand how benchmarks work!

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

| Option | Parameter                        | Description                                                                                                                                                                                   | Default                                                           |
|--------|----------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------|
 `-a`   | `<JVM_ARGS>`                     | Any JVM args to be passed to the apps                                                                                                                                                         | `main`                                                            |
| `-b`   | `<SCM_REPO_BRANCH>`              | The branch in the SCM repository                                                                                                                                                              | `main`                                                            |
| `-c`   | `<CGROUPS_CPUS>`                 | Constrain to certain CPUs via [cgroups](https://en.wikipedia.org/wiki/Cgroups) (comma-separated list, e.g., `0,2,4,6,8,10,12,14`). Ignored if running on a host that doesn't support cgroups. |                                                                   |
| `-d`   |                                  | Purge/drop OS filesystem caches between iterations                                                                                                                                            |                                                                   |
| `-e`   | <EXTRA_QDUP_ARGS>                | Any extra arguments that need to be passed to qDup ahead of the qDup scripts.<br/> - **NOTE:** This is an advanced option. Make sure you know what you are doing when using it.               |                                                                   |
| `-f`   | <OUTPUT_DIR>                     | The directory containing the run output                                                                                                                                                       | `/tmp`                                                            |
| `-g`   | `<GRAALVM_VERSION>`              | The GraalVM version to use for native tests (from SDKMAN)                                                                                                                                     | `25-graalce`                                                      |
| `-h`   | `<HOST>`                         | The HOST to run benchmarks on. Use `LOCAL` to run on the local machine                                                                                                                        | `LOCAL`                                                           |
| `-i`   | `<ITERATIONS>`                   | The number of iterations to run each test. The output is the average across all iterations.                                                                                                   | `3`                                                               |
| `-j`   | `<JAVA_VERSION>`                 | The Java version to use (from SDKMAN)                                                                                                                                                         | `25-tem`                                                          |
| `-l`   | `<SCM_REPO_URL>`                 | The SCM repository URL                                                                                                                                                                        | `https://github.com/quarkusio/spring-quarkus-perf-comparison.git` |
| `-m`   | `<CGROUPS_MAX_MEMORY>`           | Constrain available memory via [cgroups](https://en.wikipedia.org/wiki/Cgroups). Ignored if running on a host that doesn't support cgroups.                                                   | `14G`                                                             |
| `-n`   | `<NATIVE_QUARKUS_BUILD_OPTIONS>` | Native build options passed to Quarkus native build process                                                                                                                                   |                                                                   |
| `-o`   | `<NATIVE_SPRING_BUILD_OPTIONS>`  | Native build options passed to Spring native build process                                                                                                                                    |                                                                   |
| `-p`   | `<PROFILER>`                     | Enable profiling with async profiler. Values: `none`, `jfr`, `flamegraph`                                                                                                                     | `none`                                                            |
| `-q`   | `<QUARKUS_VERSION>`              | The Quarkus version to use. **Recommended to set manually**                                                                                                                                   | Version from pom.xml                                              |
| `-r`   | `<RUNTIMES>`                     | Comma-separated list of runtimes to test                                                                                                                                                      | All runtimes                                                      |
| `-s`   | `<SPRING_BOOT_VERSION>`          | The Spring Boot version to use. **Recommended to set manually**                                                                                                                               | Version from pom.xml                                              |
| `-t`   | `<TESTS_TO_RUN>`                 | Comma-separated list of tests to run                                                                                                                                                          | All tests                                                         |
| `-u`   | `<USER>`                         | The user on `<HOST>` to run the benchmark (required if HOST is not LOCAL)                                                                                                                     |                                                                   |
| `-v`   | `<JVM_MEMORY>`                   | JVM Memory settings (e.g., `-Xmx`, `-Xmn`, `-Xms`)                                                                                                                                            |                                                                   |
| `-w`   | `<WAIT_TIME>`                    | Wait time in seconds for operations like application startup                                                                                                                                  | `20`                                                              |
| `-x`   | `<CMD_PREFIX>`                   | Command prefix for running tests (e.g., `taskset --cpu-list 0-3` to restrict cores)                                                                                                           | -                                                                 |

### Available Runtimes

The `-r` option accepts one or more of the following values (comma-separated):

- `quarkus3-jvm` - [Quarkus 3](../quarkus3) on JVM
- `quarkus3-native` - [Quarkus 3](../quarkus3) native executable
- `spring3-jvm` - [Spring Boot 3](../springboot3) on JVM
- `spring3-jvm-aot` - [Spring Boot 3](../springboot3) on JVM with AOT compilation
- `spring3-native` - [Spring Boot 3](../springboot3) native executable

**Default:** All runtimes are tested

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
./run-benchmarks.sh -q 3.28.4 -s 3.5.6
```

### JVM tests only

Runs [all the tests](#available-tests) only the JVM runtimes using Quarkus version `3.28.4` and Spring Boot version `3.5.6`.

```shell
./run-benchmarks.sh -q 3.28.4 -s 3.5.6 -r 'quarkus3-jvm,spring3-jvm'
```

### Run all of the benchmarks on a remote host from a different fork

Runs [all the tests](#available-tests) against [all the runtimes](#available-runtimes) using Quarkus version `3.28.4` and Spring Boot version `3.5.6` on a remote host, while pulling the benchmarks from the `open-benchmarks` branch on the https://github.com/edeandrea/spring-quarkus-perf-comparison.git repo, and running 5 iterations of each test.

```shell
 ./run-benchmarks.sh \
    -u <REMOTE_USER> \
    -h <REMOTE_HOST> \
    -q 3.28.4 \
    -s 3.5.6 \
    -t 'measure-build-times,measure-time-to-first-request,measure-rss,run-load-test' \
    -r 'quarkus3-jvm,quarkus3-native,spring3-jvm,spring3-jvm-aot,spring3-native' \
    -i 5 \
    -l https://github.com/edeandrea/spring-quarkus-perf-comparison.git \
    -b open-benchmarks \
    -d
```


## Notes

- **Version Specification:** It is strongly recommended to explicitly set both `-q` (Quarkus version) and `-s` (Spring Boot version) to ensure consistent and reproducible benchmarks.
- **Remote Execution:** When using a HOST other than `LOCAL`, the `-u` (USER) parameter is required.
- **Resource Constraints:** The `-c` (CPU constraints) and `-m` (memory constraints) options use cgroups to limit resources available to the benchmarked applications.
- **Profiling:** When profiling is enabled, async profiler will be used to generate JFR files or flamegraphs depending on the selected option.

## Exit Codes

- **0** - Successful execution
- **1** - Error occurred (missing required parameters, invalid options, etc.)