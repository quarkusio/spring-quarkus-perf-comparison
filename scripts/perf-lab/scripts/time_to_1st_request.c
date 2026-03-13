/*
 * Feature test macros must be defined before any system headers.
 *
 * _POSIX_C_SOURCE 200809L:
 *   Enables POSIX.1-2008 features including:
 *   - clock_gettime() and CLOCK_MONOTONIC_RAW for high-resolution timing
 *   - getaddrinfo() and struct addrinfo for network address resolution
 *   - strdup() for string duplication
 *
 * _DEFAULT_SOURCE:
 *   Enables additional features including:
 *   - usleep() for microsecond-precision sleep
 *   - BSD-style functions like FD_ZERO, FD_SET for select()
 *
 * _DARWIN_C_SOURCE:
 *   On macOS, enables Darwin-specific extensions including CLOCK_MONOTONIC_RAW
 *
 * Without these macros, the compiler will report implicit function declarations
 * and undefined types when compiling with -std=c11 -Werror.
 */
#define _POSIX_C_SOURCE 200809L
#define _DEFAULT_SOURCE
#define _DARWIN_C_SOURCE

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <time.h>
#include <unistd.h>
#include <netdb.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/select.h>
#include <errno.h>
#include <fcntl.h>
#include <signal.h>

static long now_nsec() {
	struct timespec t;
	clock_gettime(CLOCK_MONOTONIC_RAW, &t);
	return t.tv_sec * 1e9 + t.tv_nsec;
}

pid_t forkme(char *args[], const char *log_path) {
	pid_t pid = fork();

	if (pid == 0) {
		if (log_path[0] != '\0') {
			// Redirect stdout and stderr to log file
			int log = open(log_path, O_WRONLY | O_CREAT | O_TRUNC, 0644);
			if (log != -1) {
				dup2(log, STDOUT_FILENO);
				dup2(log, STDERR_FILENO);
				close(log);
			}
		}
		execvp(args[0], args);
		// execvp only returns if there is an error
		exit(1);
	}
	return pid;
}

// Parse URL into host, port, and path components
// Returns 0 on success, -1 on failure
static int parse_url(const char *url, char *host, char *port, char *path) {
	const char *p = url;

	// Skip protocol if present
	if (strncmp(p, "http://", 7) == 0) {
		p += 7;
	} else if (strncmp(p, "https://", 8) == 0) {
		fprintf(stderr, "HTTPS not supported\n");
		return -1;
	}

	// Extract host
	const char *slash = strchr(p, '/');
	const char *colon = strchr(p, ':');

	// Check if colon is before slash (port specification)
	if (colon && (!slash || colon < slash)) {
		size_t host_len = colon - p;
		if (host_len >= 256) {
			return -1;
		}
		memcpy(host, p, host_len);
		host[host_len] = '\0';

		// Parse port
		int port_check = atoi(colon + 1);
		if (port_check <= 0 || port_check > 65535) {
			return -1;
		}

		const char *path_start = strchr(colon, '/');
		size_t port_len;
		if (path_start) {
			port_len = path_start - colon - 1;
		} else {
			port_len = 15;
		}
		strncpy(port, colon + 1, port_len);
		port[port_len] = '\0';

		// Extract path
		if (path_start) {
			strncpy(path, path_start, 1023);
			path[1023] = '\0';
		} else {
			path[0] = '/';
			path[1] = '\0';
		}
	} else {
		// No port specified, use default
		port[0] = '8';
		port[1] = '0';
		port[2] = '\0';

		size_t host_len = slash ? (size_t)(slash - p) : strlen(p);
		if (host_len >= 256) {
		  return -1;
		}
		memcpy(host, p, host_len);
		host[host_len] = '\0';

		if (slash) {
			strncpy(path, slash, 1023);
			path[1023] = '\0';
		} else {
			path[0] = '/';
			path[1] = '\0';
		}
	}

	return 0;
}

int main(int argc, char *argv[]) {
	if (argc < 4) {
		fprintf(stderr, "Usage: %s <command> <log_path> <url> [timeout in seconds]\n", argv[0]);
		fprintf(stderr, "Example: %s \"java -jar app.jar\" \"/tmp/my.log\" http://localhost:8080/health\n", argv[0]);
		return 1;
	}

	const char *command = argv[1];
	const char *log_path = argv[2];
	const char *url = argv[3];
	long timeout_ns = 5 * 1e9;

	if (argc == 5) {
		timeout_ns = atoi(argv[4]) * 1e9;
	}

	// Parse URL
	char host[256];
	char port[16];
	char path[1024];

	if (parse_url(url, host, port, path) < 0) {
		fprintf(stderr, "Failed to parse URL: %s\n", url);
		return 1;
	}

	// Parse command into arguments for execvp
	// Simple space-based tokenization
	char *cmd_copy = strdup(command);
	char *cmd_args[256];
	int arg_count = 0;

	char *saveptr;  // Context pointer for strtok_r
	char *token = strtok_r(cmd_copy, " ", &saveptr);
	while (token && arg_count < 255) {
		cmd_args[arg_count++] = token;
		token = strtok_r(NULL, " ", &saveptr);
	}
	cmd_args[arg_count] = NULL;

	if (arg_count == 0) {
		fprintf(stderr, "Empty command\n");
		free(cmd_copy);
		return 1;
	}

	struct addrinfo hints = { .ai_family = AF_UNSPEC, .ai_socktype = SOCK_STREAM };
	struct addrinfo *res;

	if (getaddrinfo(host, port, &hints, &res) != 0) {
		perror("getaddrinfo");
		return false;
	}

	char req[sizeof(path) + sizeof(host) + 100], buf[64];
	snprintf(req, sizeof(req), "GET %s HTTP/1.0\r\nHost: %s\r\n\r\n", path, host);

	bool success = false;
	int attempts = 0, code = 0;

	long end_time = 0;
	// Record start time
	long start_time = now_nsec();

	// Fork and execute command
	pid_t child_pid = forkme(cmd_args, log_path);

	// Poll URL until we get 2xx response
	while (!success && (now_nsec() - start_time) < timeout_ns) {
		int fd = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
		attempts++;
		if (connect(fd, res->ai_addr, res->ai_addrlen) == 0 &&
			send(fd, req, strlen(req), 0) > 0 &&
			recv(fd, buf, sizeof(buf) - 1, 0) > 0 &&
			sscanf(buf, "HTTP/%*d.%*d %d", &code) == 1 &&
			code >= 200 && code < 300) {
			end_time = now_nsec();
			close(fd);
			break;
		}
		close(fd);
	}

	if (end_time == 0) {
		end_time = now_nsec();
	}

	freeaddrinfo(res);

	printf("http_code=%d attempts=%d elapsed=%ld ns\n", code, attempts, end_time - start_time);

	if (child_pid < 0) {
		perror("fork failed");
		free(cmd_copy);
		return 1;
	}

	success = code >= 200 && code < 300;

	if (success) {
		// Clean up: kill child process
		kill(child_pid, SIGTERM);
		waitpid(child_pid, NULL, 0);

		free(cmd_copy);
		return 0;
	} else {
		fprintf(stderr, "Failed to get 2xx response after %d attempts\n", attempts);

		// Clean up: kill child process
		kill(child_pid, SIGTERM);
		waitpid(child_pid, NULL, 0);

		free(cmd_copy);
		return 1;
	}
}
