#!/bin/bash

echo "Testing CMC Crawler..."

cd /Users/carmonac/Projects/cmc_crawler

echo "1. Testing help command:"
dart run bin/main.dart --help

echo -e "\n2. Testing with example.com (limited):"
timeout 10s dart run bin/main.dart -b https://example.com -w 1 --skip-images --skip-js --skip-css || echo "Timed out (expected)"

echo -e "\n3. Checking output directory:"
ls -la output/ 2>/dev/null || echo "No output directory found"

echo -e "\nDone!"
