#!/bin/bash
#
# RHCSA Bonus Gap Q01 – Student Script
# Checks predefined possible directories for .txt files
#

OUTPUT="/root/check_txt_output.txt"

DIRS=(
  "/opt/lab/dir1"
  "/opt/lab/dir2"
  "/opt/lab/dir3"
)

# Initialize output file
> "$OUTPUT"

for DIR in "${DIRS[@]}"; do
    if [ ! -d "$DIR" ]; then
        echo "Directory $DIR not found" >> "$OUTPUT"
        continue
    fi

    FILES=$(find "$DIR" -maxdepth 1 -name "*.txt" | sort)

    if [ -z "$FILES" ]; then
        echo "No text files found in $DIR" >> "$OUTPUT"
    else
        for FILE in $FILES; do
            basename "$FILE" >> "$OUTPUT"
        done
    fi
done

exit 0
