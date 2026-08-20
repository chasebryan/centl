// SPDX-License-Identifier: Apache-2.0
//
// Minimal ownership supervisor for the bundled CentL26 backend. The helper
// keeps no scientific state and performs no network operations.

#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

static volatile sig_atomic_t requested_signal = 0;

static void request_shutdown(int signal_number) {
    requested_signal = signal_number;
}

static int install_signal_handlers(void) {
    struct sigaction action;
    memset(&action, 0, sizeof(action));
    action.sa_handler = request_shutdown;
    sigemptyset(&action.sa_mask);

    const int signals[] = {SIGTERM, SIGINT, SIGHUP, SIGQUIT};
    for (size_t index = 0; index < sizeof(signals) / sizeof(signals[0]); index++) {
        if (sigaction(signals[index], &action, NULL) != 0) {
            return -1;
        }
    }
    return 0;
}

static void restore_default_signal_handlers(void) {
    struct sigaction action;
    memset(&action, 0, sizeof(action));
    action.sa_handler = SIG_DFL;
    sigemptyset(&action.sa_mask);

    const int signals[] = {SIGTERM, SIGINT, SIGHUP, SIGQUIT};
    for (size_t index = 0; index < sizeof(signals) / sizeof(signals[0]); index++) {
        (void)sigaction(signals[index], &action, NULL);
    }
}

static void sleep_milliseconds(long milliseconds) {
    struct timespec duration;
    duration.tv_sec = milliseconds / 1000;
    duration.tv_nsec = (milliseconds % 1000) * 1000000L;
    while (nanosleep(&duration, &duration) != 0 && errno == EINTR) {
        if (requested_signal != 0) {
            return;
        }
    }
}

static int child_exit_code(int status) {
    if (WIFEXITED(status)) {
        return WEXITSTATUS(status);
    }
    if (WIFSIGNALED(status)) {
        return 128 + WTERMSIG(status);
    }
    return EXIT_FAILURE;
}

static int stop_child(pid_t child, int exit_code) {
    int status = 0;
    if (kill(child, SIGTERM) != 0 && errno != ESRCH) {
        fprintf(stderr, "centl26-supervisor: could not terminate backend: %s\n", strerror(errno));
    }

    for (int attempt = 0; attempt < 20; attempt++) {
        pid_t result = waitpid(child, &status, WNOHANG);
        if (result == child) {
            return exit_code;
        }
        if (result < 0 && errno == ECHILD) {
            return exit_code;
        }
        if (result < 0 && errno != EINTR) {
            break;
        }
        sleep_milliseconds(50);
    }

    if (kill(child, SIGKILL) != 0 && errno != ESRCH) {
        fprintf(stderr, "centl26-supervisor: could not kill unresponsive backend: %s\n", strerror(errno));
    }
    while (waitpid(child, &status, 0) < 0 && errno == EINTR) {
    }
    return exit_code;
}

static int valid_port(const char *text) {
    if (text == NULL || *text == '\0') {
        return 0;
    }
    char *end = NULL;
    errno = 0;
    long value = strtol(text, &end, 10);
    return errno == 0 && end != text && *end == '\0' && value > 0 && value <= UINT16_MAX;
}

int main(int argc, char **argv) {
    if (argc != 3 || !valid_port(argv[2])) {
        fprintf(stderr, "usage: centl26-supervisor BACKEND PORT\n");
        return 64;
    }
    if (access(argv[1], X_OK) != 0) {
        fprintf(stderr, "centl26-supervisor: backend is not executable: %s\n", strerror(errno));
        return 66;
    }
    if (install_signal_handlers() != 0) {
        fprintf(stderr, "centl26-supervisor: signal setup failed: %s\n", strerror(errno));
        return 70;
    }

    const pid_t owner = getppid();
    const pid_t child = fork();
    if (child < 0) {
        fprintf(stderr, "centl26-supervisor: fork failed: %s\n", strerror(errno));
        return 71;
    }
    if (child == 0) {
        restore_default_signal_handlers();
        execl(argv[1], argv[1], argv[2], (char *)NULL);
        fprintf(stderr, "centl26-supervisor: exec failed: %s\n", strerror(errno));
        _exit(127);
    }

    for (;;) {
        int status = 0;
        pid_t result = waitpid(child, &status, WNOHANG);
        if (result == child) {
            return child_exit_code(status);
        }
        if (result < 0 && errno != EINTR) {
            fprintf(stderr, "centl26-supervisor: wait failed: %s\n", strerror(errno));
            return stop_child(child, 72);
        }

        if (requested_signal != 0) {
            return stop_child(child, 128 + requested_signal);
        }

        errno = 0;
        if (getppid() != owner || (kill(owner, 0) != 0 && errno == ESRCH)) {
            return stop_child(child, EXIT_SUCCESS);
        }
        sleep_milliseconds(100);
    }
}
