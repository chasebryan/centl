// SPDX-License-Identifier: Apache-2.0
// Publish one fully assembled release directory without replacing a peer.

#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/stdio.h>

int main(int argc, char **argv) {
    unsigned int flags = RENAME_EXCL;
    const char *source = NULL;
    const char *destination = NULL;
    if (argc == 3) {
        source = argv[1];
        destination = argv[2];
    } else if (argc == 4 && strcmp(argv[1], "--swap") == 0) {
        flags = RENAME_SWAP;
        source = argv[2];
        destination = argv[3];
    } else {
        fprintf(stderr, "usage: centl26-atomic-publish [--swap] SOURCE_DIRECTORY DESTINATION_DIRECTORY\n");
        return 64;
    }
    if (renamex_np(source, destination, flags) != 0) {
        fprintf(stderr, "centl26-atomic-publish: %s\n", strerror(errno));
        return errno == EEXIST ? 73 : 74;
    }
    return 0;
}
