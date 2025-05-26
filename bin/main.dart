import 'dart:io';
import 'package:args/args.dart';
import 'package:cmc_crawler/crawler.dart';
import 'package:cmc_crawler/crawler_config.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'base-url',
      abbr: 'b',
      help: 'Base URL for the crawler (required)',
      mandatory: true,
    )
    ..addOption(
      'target-url',
      abbr: 't',
      help: 'Starting URL (defaults to base-url)',
    )
    ..addOption(
      'max-workers',
      abbr: 'w',
      help: 'Maximum number of worker threads',
      defaultsTo: '4',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output directory',
      defaultsTo: 'output',
    )
    ..addFlag('skip-css', help: 'Skip downloading CSS files', defaultsTo: false)
    ..addFlag(
      'skip-js',
      help: 'Skip downloading JavaScript files',
      defaultsTo: false,
    )
    ..addFlag('skip-images', help: 'Skip downloading images', defaultsTo: false)
    ..addMultiOption(
      'allowed-domains',
      abbr: 'a',
      help: 'Additional allowed domains',
    )
    ..addMultiOption(
      'disallowed-paths',
      abbr: 'd',
      help: 'Disallowed URL paths',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    );

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('CMC Crawler - Web Crawler with Dart Isolates\n');
      print('Usage: dart run bin/main.dart [options]\n');
      print(parser.usage);
      print('\nExamples:');
      print('  dart run bin/main.dart -b https://example.com');
      print(
        '  dart run bin/main.dart -b https://example.com -t https://example.com/start -w 8',
      );
      print(
        '  dart run bin/main.dart -b https://example.com --skip-css --skip-js',
      );
      print(
        '  dart run bin/main.dart -b https://example.com -a subdomain.example.com -d /admin',
      );
      return;
    }

    final baseUrl = results['base-url'] as String;
    final targetUrl = results['target-url'] as String?;
    final maxWorkers = int.parse(results['max-workers'] as String);
    final outputDir = results['output'] as String;
    final skipCSS = results['skip-css'] as bool;
    final skipJS = results['skip-js'] as bool;
    final skipImages = results['skip-images'] as bool;
    final allowedDomains = results['allowed-domains'] as List<String>;
    final disallowedPaths = results['disallowed-paths'] as List<String>;

    // Validate base URL
    final uri = Uri.tryParse(baseUrl);
    if (uri == null || (!uri.scheme.startsWith('http'))) {
      print('Error: Invalid base URL. Must be a valid HTTP/HTTPS URL.');
      exit(1);
    }

    // Create configuration
    final config = CrawlerConfig(
      baseUrl: baseUrl,
      targetUrl: targetUrl,
      maxWorkers: maxWorkers,
      skipCSS: skipCSS,
      skipJS: skipJS,
      skipImages: skipImages,
      allowedDomains: allowedDomains,
      disallowedPaths: disallowedPaths,
      outputDirectory: outputDir,
    );

    print('=== CMC Crawler Configuration ===');
    print('Base URL: ${config.baseUrl}');
    print('Target URL: ${config.targetUrl ?? config.baseUrl}');
    print('Max Workers: ${config.maxWorkers}');
    print('Output Directory: ${config.outputDirectory}');
    print('Skip CSS: ${config.skipCSS}');
    print('Skip JS: ${config.skipJS}');
    print('Skip Images: ${config.skipImages}');
    if (config.allowedDomains.isNotEmpty) {
      print('Allowed Domains: ${config.allowedDomains.join(', ')}');
    }
    if (config.disallowedPaths.isNotEmpty) {
      print('Disallowed Paths: ${config.disallowedPaths.join(', ')}');
    }
    print('================================\n');

    // Create and start crawler
    final crawler = Crawler(config);

    // Handle Ctrl+C gracefully
    ProcessSignal.sigint.watch().listen((signal) {
      print('\nReceived interrupt signal. Stopping crawler...');
      crawler.stop();
      exit(0);
    });

    await crawler.start();
  } catch (e) {
    if (e is FormatException) {
      print('Error: ${e.message}\n');
      print('Use --help for usage information.');
    } else {
      print('Error: $e');
    }
    exit(1);
  }
}
