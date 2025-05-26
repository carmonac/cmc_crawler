# CMC Crawler

A high-performance, multi-threaded web crawler built in Dart that downloads web pages and extracts links for further crawling. The crawler uses Dart isolates for concurrent processing and supports various configuration options for different crawling scenarios.

## Features

- **Multi-threaded crawling** using Dart isolates for parallel processing
- **Configurable worker threads** for optimal performance
- **Domain filtering** with allowed domains and disallowed paths
- **Asset filtering** options for CSS, JavaScript, and images
- **Automatic file organization** by domain
- **Progress tracking** with detailed logging
- **Graceful error handling** and recovery

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd cmc_crawler
```

2. Install dependencies:
```bash
dart pub get
```

## Usage

### Basic Usage

```bash
dart run bin/main.dart --url https://example.com
```

### Command Line Arguments

| Argument | Description | Default | Required |
|----------|-------------|---------|----------|
| `--url` | Base URL to start crawling | - | Yes |
| `--target` | Specific target URL (if different from base) | Same as `--url` | No |
| `--workers` | Number of worker threads | 4 | No |
| `--output` | Output directory for downloaded files | `output` | No |
| `--skip-css` | Skip downloading CSS files | false | No |
| `--skip-js` | Skip downloading JavaScript files | false | No |
| `--skip-images` | Skip downloading image files | false | No |
| `--allowed-domains` | Comma-separated list of allowed domains | Base URL domain | No |
| `--disallowed-paths` | Comma-separated list of disallowed paths | - | No |

### Examples

#### Basic crawling
```bash
dart run bin/main.dart --url https://example.com
```

#### High-performance crawling with 8 workers
```bash
dart run bin/main.dart --url https://example.com --workers 8
```

#### Skip assets (CSS, JS, images)
```bash
dart run bin/main.dart --url https://example.com --skip-css --skip-js --skip-images
```

#### Custom output directory
```bash
dart run bin/main.dart --url https://example.com --output /path/to/downloads
```

#### Multi-domain crawling
```bash
dart run bin/main.dart --url https://example.com --allowed-domains example.com,subdomain.example.com,partner.com
```

#### Exclude specific paths
```bash
dart run bin/main.dart --url https://example.com --disallowed-paths /admin,/private,/api
```

#### Complete example with all options
```bash
dart run bin/main.dart \
  --url https://example.com \
  --target https://example.com/start-here \
  --workers 6 \
  --output ./downloads \
  --skip-css \
  --allowed-domains example.com,docs.example.com \
  --disallowed-paths /admin,/login,/api
```

## Output Structure

The crawler organizes downloaded files by domain:

```
output/
├── example.com/
│   ├── index.html
│   ├── about.html
│   └── products.html
├── subdomain.example.com/
│   ├── index.html
│   └── services.html
└── docs.example.com/
    ├── index.html
    └── api.html
```

## Configuration Options

### Worker Threads
- **Default**: 4 workers
- **Recommendation**: Set to number of CPU cores for optimal performance
- **Range**: 1-16 workers (adjust based on system resources)

### Domain Filtering
- **Allowed Domains**: Only crawl URLs from specified domains
- **Disallowed Paths**: Skip URLs that start with specified paths
- **Default**: Only crawl the same domain as the base URL

### Asset Filtering
- **CSS Files**: `--skip-css` to exclude stylesheets
- **JavaScript Files**: `--skip-js` to exclude scripts
- **Images**: `--skip-images` to exclude image files

## Performance Tips

1. **Adjust worker count** based on your system:
   ```bash
   # For powerful systems
   dart run bin/main.dart --url https://example.com --workers 8
   
   # For limited resources
   dart run bin/main.dart --url https://example.com --workers 2
   ```

2. **Skip unnecessary assets** for faster crawling:
   ```bash
   dart run bin/main.dart --url https://example.com --skip-css --skip-js --skip-images
   ```

3. **Use specific target URLs** to avoid crawling the entire site:
   ```bash
   dart run bin/main.dart --url https://example.com --target https://example.com/documentation
   ```

## Error Handling

The crawler handles various error scenarios:
- **Network timeouts**: 30-second timeout per request
- **HTTP errors**: Logs and continues with other URLs
- **Invalid URLs**: Skips malformed URLs
- **File system errors**: Creates directories as needed

## Logging

The crawler provides detailed logging:
- Worker startup and shutdown
- Task queue status
- Download progress with success/failure indicators
- Error messages with context
- Final statistics

Example output:
```
Starting crawler with base URL: https://example.com
Max workers: 4
Output directory: output
Starting 4 workers...
Worker 1 started
Worker 2 started
Worker 3 started
Worker 4 started
[Queue] Added task: https://example.com (Queue size: 1)
[1/1] ✓ Downloaded: https://example.com
  Saved to: output/example.com/index.html
[Queue] Added task: https://example.com/about (Queue size: 1)
[2/2] ✓ Downloaded: https://example.com/about
  Saved to: output/example.com/about.html
Crawler completed. Total pages processed: 2
```

## Requirements

- Dart SDK 3.0 or higher
- Internet connection for web crawling
- Sufficient disk space for downloaded content

## License

[Add your license information here]