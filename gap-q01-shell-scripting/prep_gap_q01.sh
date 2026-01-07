#!/bin/bash
#
# RHCSA Bonus Gap Q01 – Lab Preparation Script
# This script prepares a randomized lab environment and
# generates the expected output for instructor/self verification.
#

set -e

BASE_DIR="/opt/lab"
ANSWER_FILE="/root/.gap_q01_answers.txt"

DIRS=("dir1" "dir2" "dir3")

echo "Preparing RHCSA Gap Q01 lab environment..."

# Reset environment
rm -rf "$BASE_DIR"
mkdir -p "$BASE_DIR"
> "$ANSWER_FILE"

for DIR in "${DIRS[@]}"; do
    FULL_PATH="$BASE_DIR/$DIR"

    # Randomly decide if directory exists (50/50)
    if [ $((RANDOM % 2)) -eq 0 ]; then
        echo "Directory $FULL_PATH not found" >> "$ANSWER_FILE"
        continue
    fi

    mkdir -p "$FULL_PATH"

    # Random number of files: 0–4
    FILE_COUNT=$((RANDOM % 5))
    TXT_FOUND=0

    for i in $(seq 1 "$FILE_COUNT"); do
        if [ $((RANDOM % 2)) -eq 0 ]; then
            FILE="$FULL_PATH/file_$RANDOM.txt"
            echo "Sample text $RANDOM" > "$FILE"
            echo "$(basename "$FILE")" >> "$ANSWER_FILE"
            TXT_FOUND=1
        else
            echo "Log data $RANDOM" > "$FULL_PATH/file_$RANDOM.log"
        fi
    done

    if [ "$TXT_FOUND" -eq 0 ]; then
        echo "No text files found in $FULL_PATH" >> "$ANSWER_FILE"
    fi
done

chmod 600 "$ANSWER_FILE"

echo "Lab preparation complete."
echo "Expected results generated (hidden)."
