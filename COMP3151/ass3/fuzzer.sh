#!/bin/bash

set -e # Ensures that any failures will abort the script

ITERATIONS_PER_SENIORS=100
MIN_SENIORS=3
MAX_SENIORS=9

while true; do
    for ((SENIORS=MIN_SENIORS; SENIORS<=MAX_SENIORS; ++SENIORS)); do
        printf "Testing SENIORS = $SENIORS"
        sed -i "s/^#define SENIORS .*/#define SENIORS $SENIORS/" lse.pml
        for ((I=0; I<ITERATIONS_PER_SENIORS; ++I)); do
            SEED="$RANDOM"
            spin -n"$SEED" -B -b lse.pml > /dev/null
            printf "."
        done
        echo
    done
done
