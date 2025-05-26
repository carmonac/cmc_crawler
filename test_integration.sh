#!/bin/bash

echo "Running CMC Crawler integration tests..."
echo

# Run the integration tests
dart test test/crawler_integration_test.dart

echo
echo "Integration tests completed."
