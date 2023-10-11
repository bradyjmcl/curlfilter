#!/bin/bash

# Check if the input file, base URL, output file, and search string are provided as arguments
if [ $# -ne 4 ]; then
  echo "Usage: $0  <base_url> <input_file> <output_file> <search_string>"
  exit 1
fi

base_url="$1"
input_file="$2"
output_file="$3"
search_string="$4"

# Check if the input file exists
if [ ! -f "$input_file" ]; then
  echo "Input file does not exist."
  exit 1
fi

# Check if curl is installed
if ! command -v curl &> /dev/null; then
  echo "curl is not installed. Please install it."
  exit 1
fi

# Create or clear the output file
> "$output_file"

# Prompt the user for their preference
echo "[?][?] Do you want to output the entire request or just the line containing the search string? [?][?]"
select option in "Entire Request" "Line with Search String"; do
  case $option in
    "Entire Request")
      output_entire_request=true
      break
      ;;
    "Line with Search String")
      output_entire_request=false
      break
      ;;
    *) echo "Invalid option. Please select 1 or 2.";;
  esac
done

# Function to strip HTML tags using awk and replace tags with a single space
strip_html_tags() {
  awk 'BEGIN { RS="</tr>"; ORS="\n" } {
    gsub(/<[^>]+>/, " ", $0)
    sub(/^[[:space:]]*/, "", $0)
    sub(/[[:space:]]*$/, "", $0)
    if (length($0) > 0) {
      print $0
    }
  }'
}

# Iterate through each line in the input file
while IFS= read -r line; do
  # Construct the URL by appending the line content to the base URL
  url="${base_url}${line}"

  # Run the curl command and capture the output
  response=$(curl -s "$url")

  # Check if the search string is present in the response
  if [[ $response == *"$search_string"* ]]; then
    if [ "$output_entire_request" = true ]; then
      # Append the entire response to the output file
      echo "$response" >> "$output_file"
    else
      # Use the strip_html_tags function to remove HTML tags and format as a table
      echo "$response" | grep "$search_string" | strip_html_tags >> "$output_file"
    fi
  fi

# You can add other curl options or process the response as needed
done < "$input_file"

# Prompt the user to view results or quit
echo "[?][?] Do you want to view the results? [?][?]"
select choice in "Yes" "No"; do
  case "$choice" in
    "Yes")
      cat "$output_file"
      break
      ;;
    "No")
      echo "Results are saved in $output_file. Exiting."
      exit 0
      ;;
    *)
      echo "Invalid choice. Please select 1 for yes or 2 for no."
      ;;
  esac
done
