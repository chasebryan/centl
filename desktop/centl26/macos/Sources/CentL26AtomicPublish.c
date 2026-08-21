// SPDX-License-Identifier: Apache-2.0
// Publish one fully assembled directory, or install a verified CentL26 update.

#include <errno.h>
#include <signal.h>
#include <spawn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stdio.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

extern char **environ;

static int ends_with(const char *value, const char *suffix) {
    size_t value_length = strlen(value);
    size_t suffix_length = strlen(suffix);
    return value_length >= suffix_length
        && strcmp(value + value_length - suffix_length, suffix) == 0;
}

static int open_application(const char *application) {
    pid_t child = 0;
    char *const arguments[] = {"/usr/bin/open", "-n", (char *)application, NULL};
    int result = posix_spawn(&child, arguments[0], NULL, NULL, arguments, environ);
    if (result != 0) {
        fprintf(stderr, "centl26-update-installer: relaunch failed: %s\n", strerror(result));
        return 74;
    }
    int status = 0;
    pid_t waited;
    do {
        waited = waitpid(child, &status, 0);
    } while (waited < 0 && errno == EINTR);
    if (waited < 0) {
        fprintf(stderr, "centl26-update-installer: cannot wait for relaunch: %s\n", strerror(errno));
        return 74;
    }
    if (!WIFEXITED(status) || WEXITSTATUS(status) != 0) {
        fprintf(stderr, "centl26-update-installer: open returned unsuccessfully\n");
        return 74;
    }
    return 0;
}

static int validate_install_paths(const char *source, const char *destination) {
    static const char marker[] = "/.CentL26-update-";
    static const char source_suffix[] = "/expanded/CentL26.app";
    const char *stage = strstr(source, marker);
    if (source[0] != '/' || destination[0] != '/' || stage == NULL
        || !ends_with(source, source_suffix)
        || !ends_with(destination, "/CentL26.app")) {
        return 0;
    }

    const char *identifier = stage + strlen(marker);
    const char *suffix = strstr(identifier, source_suffix);
    if (suffix == NULL || suffix == identifier || strlen(identifier) != strlen(source_suffix) + 36) {
        return 0;
    }
    for (const char *cursor = identifier; cursor < suffix; cursor++) {
        char character = *cursor;
        if (!((character >= '0' && character <= '9')
            || (character >= 'A' && character <= 'F')
            || (character >= 'a' && character <= 'f')
            || character == '-')) {
            return 0;
        }
    }

    size_t parent_length = (size_t)(stage - source);
    static const char application_suffix[] = "/CentL26.app";
    if (strlen(destination) != parent_length + strlen(application_suffix)
        || strncmp(source, destination, parent_length) != 0
        || strcmp(destination + parent_length, application_suffix) != 0) {
        return 0;
    }

    struct stat source_status;
    struct stat destination_status;
    if (lstat(source, &source_status) != 0 || lstat(destination, &destination_status) != 0
        || !S_ISDIR(source_status.st_mode) || !S_ISDIR(destination_status.st_mode)
        || S_ISLNK(source_status.st_mode) || S_ISLNK(destination_status.st_mode)
        || source_status.st_dev != destination_status.st_dev) {
        return 0;
    }
    return 1;
}

static int install_update(const char *parent_text, const char *source, const char *destination) {
    char *end = NULL;
    errno = 0;
    long parsed = strtol(parent_text, &end, 10);
    if (errno != 0 || end == parent_text || *end != '\0' || parsed <= 1 || parsed > INT32_MAX
        || !validate_install_paths(source, destination)) {
        fprintf(stderr, "centl26-update-installer: invalid installation request\n");
        return 64;
    }

    pid_t parent = (pid_t)parsed;
    for (int attempt = 0; attempt < 1200; attempt++) {
        if (kill(parent, 0) != 0) {
            if (errno == ESRCH) {
                break;
            }
            if (errno != EPERM) {
                fprintf(stderr, "centl26-update-installer: cannot inspect parent: %s\n", strerror(errno));
                return 74;
            }
        }
        const struct timespec interval = {.tv_sec = 0, .tv_nsec = 100000000};
        while (nanosleep(&interval, NULL) != 0 && errno == EINTR) {
        }
        if (attempt == 1199) {
            fprintf(stderr, "centl26-update-installer: timed out waiting for CentL26 to exit\n");
            return 75;
        }
    }

    if (renamex_np(source, destination, RENAME_SWAP) != 0) {
        int saved_errno = errno;
        fprintf(stderr, "centl26-update-installer: atomic swap failed: %s\n", strerror(saved_errno));
        // The destination is unchanged when RENAME_SWAP fails. Reopen that
        // known-good copy so an installation failure never strands the user.
        (void)open_application(destination);
        return saved_errno == EACCES || saved_errno == EPERM ? 77 : 74;
    }
    int launch_result = open_application(destination);
    if (launch_result == 0) {
        return 0;
    }

    // A successful swap is not considered committed until LaunchServices has
    // accepted the new application. Restore the original app on launch failure
    // and reopen it so an update cannot leave a non-launching destination.
    if (renamex_np(source, destination, RENAME_SWAP) != 0) {
        fprintf(stderr, "centl26-update-installer: rollback swap failed: %s\n", strerror(errno));
        return 76;
    }
    if (open_application(destination) != 0) {
        fprintf(stderr, "centl26-update-installer: restored application could not be reopened\n");
    }
    return launch_result;
}

static int self_test_rollback(const char *source, const char *destination) {
    if (!validate_install_paths(source, destination)) {
        fprintf(stderr, "centl26-update-installer: invalid rollback self-test paths\n");
        return 64;
    }
    struct stat original_source;
    struct stat original_destination;
    if (lstat(source, &original_source) != 0 || lstat(destination, &original_destination) != 0) {
        fprintf(stderr, "centl26-update-installer: cannot inspect rollback self-test paths\n");
        return 74;
    }
    if (renamex_np(source, destination, RENAME_SWAP) != 0) {
        fprintf(stderr, "centl26-update-installer: rollback self-test initial swap failed: %s\n", strerror(errno));
        return 74;
    }
    if (renamex_np(source, destination, RENAME_SWAP) != 0) {
        fprintf(stderr, "centl26-update-installer: rollback self-test restoration failed: %s\n", strerror(errno));
        return 76;
    }
    struct stat restored_source;
    struct stat restored_destination;
    if (lstat(source, &restored_source) != 0 || lstat(destination, &restored_destination) != 0
        || restored_source.st_ino != original_source.st_ino
        || restored_destination.st_ino != original_destination.st_ino) {
        fprintf(stderr, "centl26-update-installer: rollback self-test identity differs\n");
        return 76;
    }
    return 0;
}

int main(int argc, char **argv) {
    unsigned int flags = RENAME_EXCL;
    const char *source = NULL;
    const char *destination = NULL;
    if (argc == 5 && strcmp(argv[1], "--install") == 0) {
        return install_update(argv[2], argv[3], argv[4]);
    } else if (argc == 4 && strcmp(argv[1], "--self-test-rollback") == 0) {
        return self_test_rollback(argv[2], argv[3]);
    } else if (argc == 3) {
        source = argv[1];
        destination = argv[2];
    } else if (argc == 4 && strcmp(argv[1], "--swap") == 0) {
        flags = RENAME_SWAP;
        source = argv[2];
        destination = argv[3];
    } else {
        fprintf(stderr,
            "usage: centl26-atomic-publish [--swap] SOURCE_DIRECTORY DESTINATION_DIRECTORY\n"
            "       centl26-update-installer --install PARENT_PID STAGED_APP INSTALLED_APP\n"
            "       centl26-update-installer --self-test-rollback STAGED_APP INSTALLED_APP\n");
        return 64;
    }
    if (renamex_np(source, destination, flags) != 0) {
        fprintf(stderr, "centl26-atomic-publish: %s\n", strerror(errno));
        return errno == EEXIST ? 73 : 74;
    }
    return 0;
}
