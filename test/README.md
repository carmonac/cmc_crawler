# CMC Crawler Test Server

This directory contains a test server and integration tests for the CMC Crawler.

## Test Server

The test server (`test_server.dart`) is a simple HTTP server built with `shelf` that provides several routes for testing the crawler functionality:

### Routes

- **`/`** - Index page with links to all other pages
- **`/page`** - Page with one image and additional links
- **`/pagewithqueryparam?example=1`** - Page with two images (including the same image from `/page` to test duplicate handling)
- **`/pagewithqueryparam?example=2`** - Page with only HTML content and links (no images)
- **`/pagetoavoid`** - A simple page that should be filtered out when `disallowedPaths` is configured
- **`/image1.jpg`** - Simple PNG image (1x1 pixel red)
- **`/image2.jpg`** - Simple PNG image (1x1 pixel blue)

### Features Tested

1. **Basic crawling** - Downloads HTML pages and follows links
2. **Image downloading** - Downloads images and handles duplicates correctly
3. **Query parameter handling** - Handles URLs with query parameters
4. **Path filtering** - Respects `disallowedPaths` configuration
5. **Asset filtering** - Respects `skipImages`, `skipCSS`, `skipJS` flags
6. **Worker configuration** - Tests different worker count configurations

## Running Tests

### Prerequisites

1. Install dependencies:
   ```bash
   dart pub get
   ```

### Run Integration Tests

```bash
# Run all integration tests
dart test test/crawler_integration_test.dart

# Run with verbose output
dart test test/crawler_integration_test.dart --reporter=expanded

# Run a specific test
dart test test/crawler_integration_test.dart --name "should crawl all accessible pages"
```

### Using the Test Script

There's also a convenience script:

```bash
./test_integration.sh
```

## Test Structure

The integration tests follow this pattern:

1. **Setup** - Start the test server on a random port
2. **Test Execution** - Run crawler with different configurations
3. **Verification** - Check that expected files were downloaded and unwanted files were not
4. **Cleanup** - Stop the server and clean up temporary files

### Test Cases

1. **Complete Crawling Test** - Tests that all accessible pages are downloaded except those in `disallowedPaths`
2. **Image Skipping Test** - Verifies that images are not downloaded when `skipImages=true`
3. **Worker Configuration Test** - Tests single worker configuration
4. **Disallowed Paths Filtering Test** - Explicitly tests that `disallowedPaths` filtering works correctly

## Directory Structure

```
test/
├── crawler_integration_test.dart  # Main integration tests
└── server/
    └── test_server.dart           # Test HTTP server
```

## Expected Test Output

When tests pass, you should see output similar to:

```
Test server started at http://localhost:54224
Starting crawler with base URL: http://localhost:54224
Max workers: 2
Output directory: /tmp/cmc_crawler_test_1748266490659
[Queue] Added task: http://localhost:54224 (Queue size: 1)
[Filter] Skipping disallowed path: http://localhost:54224/pagetoavoid (matches: /pagetoavoid)
[1/7] ✓ Downloaded: http://localhost:54224
[2/7] ✓ Downloaded: http://localhost:54224/page
...
Test server stopped
All tests passed!
```

## Troubleshooting

### Common Issues

1. **Port conflicts** - The test server uses a random port, but if you see port conflicts, restart the tests
2. **Permission errors** - Make sure you have write permissions to the system temp directory
3. **Network issues** - Tests require localhost networking to work

### Debug Mode

To see more detailed output, you can modify the test server to add more logging:

```dart
print('Request: ${request.method} $path${query.isNotEmpty ? '?$query' : ''}');
```

This will show all HTTP requests being made during the test.
