#!/bin/bash

clear

# Define the URL of the page to scrape
url="https://www.weea.kr/en-vod?category1=Business+Missions&mod=list&pageid=1"

# Fetch content from the webpage
content=$(curl -s --fail "$url")
if [ $? -ne 0 ]; then
    echo "Error: Failed to fetch the webpage. Please check the URL or your internet connection."
    exit 1
fi

# Extract titles for display
titles=$(echo "$content" | pup 'div.kboard-default-cut-strings text{}' | sed -e 's/Business Missions | //g' -e 's/^[[:space:]]*//;s/[[:space:]]*$//' | awk 'NF')

# Display titles with line numbers
echo "$titles" | nl -w1 -s'. '

# Prompt the user to select a title
read -p  "Please select an option from the list (enter the number): " choice

# Validate the input and extract the selected title
total_choices=$(echo "$titles" | wc -l)
if [[ $choice -ge 1 && $choice -le $total_choices ]]; then
    selected_title=$(echo "$titles" | sed -n "${choice}p")

    # Extract the link corresponding to the selected title
    link=$(echo "$content" | pup 'a[href*="uid="]' | grep -o 'href="[^"]*' | sed -n "${choice}p" | cut -d'"' -f2)

    # Extract UUID from the link
    uuid=$(echo "$link" | grep -o 'uid=[^&]*' | cut -d'=' -f2)

    # Get the URL of the file to download
    file_url=$(curl -s "https://www.weea.kr/en-vod?uid=$uuid&mod=document&pageid=1" | pcregrep -o '(?<=href=")https://d2s2swbh67svv2\.cloudfront\.net/[^"]*_bm_en_1m\.mp4')

    # Specify the download folder
    download_folder="$HOME/Downloads"

    # Updated Beautiful Texts
    clear
    echo "Downloading '${selected_title}'"
    echo

    # Download the file to the specified folder if found
    if [ -n "$file_url" ]; then
        curl -o "$download_folder/${selected_title}.mp4" -L "$file_url"
        echo
        echo "Downloaded file: ${selected_title}.mp4"
    else
        echo
        echo "No file matching the pattern found to download."
    fi
else
    echo
    echo "Invalid selection. Please enter a number between 1 and $total_choices."
    exit 1
fi
