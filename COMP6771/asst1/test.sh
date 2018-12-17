#!/bin/bash

set -e
set -o pipefail

for N in $(seq ${2:-20}); do
    case $1 in
        sourceIsDest)
            # Source = dest
            INPUT="$(shuf -n 1 EnglishWords.txt)"
            INPUT="$INPUT"$'\n'"$INPUT"
            ;;
        random)
            # Completely random
            INPUT="$(shuf -n 2 EnglishWords.txt)"
            ;;
        #sameLength)
        *)
            # Input strings are same length (default)
            INPUT="$(awk "length(\$0) == $RANDOM % 23" EnglishWords.txt | shuf -n 2)"
            ;;
    esac

    START=$(date +%s.%N | awk '{print int($1 * 1000)}')
    diff -u <(./wl_ref <<< "$INPUT") <(./wl <<< "$INPUT") || (echo "Failed:"$'\n'"$INPUT"$'\n'; false)
    if (( $(date +%s.%N | awk '{print int($1 * 1000)}') - $START > 1000 )); then
        echo "Slow:"$'\n'"$INPUT"$'\n'
    fi
done
