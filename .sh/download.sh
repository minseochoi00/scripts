#!/bin/bash

# Loop until a valid selection is made
while true; do
    # Prompt user to choose between BM.sh or Core.sh
    echo "Choose the script to verify and run:"
    echo "1) BM"
    echo "2) Core"
    read -p "Enter your choice (1 or 2): " script_choice

    case $script_choice in
        1)
            file="BM.sh"
            expected_hash="13b2d5b64b434496991df0ff0ad16898"
            break
            ;;
        2)
            file="Core.sh"
            # Replace this with the actual hash of Core.sh
            expected_hash="87ff707c076f474887dc28b8f2abb29f"
            break
            ;;
        *)
            echo "Invalid choice. Please select 1 for BM or 2 for Core."
            ;;
    esac
done

# Command to run if the hash matches
external_command="./$file"

# Determine OS and calculate hash accordingly
if command -v md5sum >/dev/null 2>&1; then
    # Linux system
    current_hash=$(md5sum "$file" | awk '{ print $1 }')
elif command -v md5 >/dev/null 2>&1; then
    # macOS system
    current_hash=$(md5 -q "$file")
else
    echo "MD5 utility not found. Exiting."
    exit 1
fi

# Compare the current hash with the expected hash
if [ "$current_hash" == "$expected_hash" ]; then
    echo "Hash match. Running $file."
    # Execute the external command
    $external_command
else
    echo "Hash mismatch. Exiting."
    exit 1
fi
