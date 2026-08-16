CC ?= cc
CFLAGS ?= -O3 -std=c11 -Wall -Wextra

.PHONY: all clean sample

all: w_census

w_census: w_census.c
	$(CC) $(CFLAGS) -o $@ w_census.c

sample: w_census
	./w_census 2000000

clean:
	rm -f w_census
