import 'dart:io';
import 'dart:isolate';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as path;
import 'crawler_config.dart';
import 'crawler_task.dart';
import 'worker_message.dart';
import 'worker_result.dart';

class CrawlerWorker {
  static void workerEntryPoint(List<dynamic> args) async {
    final SendPort sendPort = args[0];
    final ReceivePort receivePort = ReceivePort();
    sendPort.send(receivePort.sendPort);

    await for (final message in receivePort) {
      if (message is Map<String, dynamic>) {
        final workerMessage = WorkerMessage.fromMap(message);

        if (workerMessage.type == 'crawl') {
          final taskData = workerMessage.data as Map<String, dynamic>;
          final task = CrawlerTask(
            url: taskData['url'],
            referrer: taskData['referrer'] ?? '',
            depth: taskData['depth'] ?? 0,
          );
          final config = _configfromMap(taskData['config']);

          final result = await _processTask(task, config);

          // Check if there's a specific response port for this task
          if (taskData.containsKey('responsePort')) {
            final responsePort = taskData['responsePort'] as SendPort;
            responsePort.send(result.toMap());
          } else {
            // Fallback to main sendPort for backwards compatibility
            sendPort.send(result.toMap());
          }
        } else if (workerMessage.type == 'stop') {
          break;
        }
      }
    }
  }

  static CrawlerConfig _configfromMap(Map<String, dynamic> json) {
    return CrawlerConfig(
      baseUrl: json['baseUrl'],
      targetUrl: json['targetUrl'],
      maxWorkers: json['maxWorkers'],
      skipCSS: json['skipCSS'],
      skipJS: json['skipJS'],
      skipImages: json['skipImages'],
      allowedDomains: List<String>.from(json['allowedDomains'] ?? []),
      disallowedPaths: List<String>.from(json['disallowedPaths'] ?? []),
      outputDirectory: json['outputDirectory'],
      userAgent: json['userAgent'] ?? 'CMC Crawler 1.0',
    );
  }

  static Future<WorkerResult> _processTask(
    CrawlerTask task,
    CrawlerConfig config,
  ) async {
    try {
      print('[Worker] Processing: ${task.url}');

      final response = await http
          .get(Uri.parse(task.url), headers: {'User-Agent': config.userAgent})
          .timeout(Duration(seconds: 30));

      if (response.statusCode != 200) {
        return WorkerResult(
          url: task.url,
          success: false,
          error: 'HTTP ${response.statusCode}',
        );
      }

      // Save the page
      final filePath = await _savePage(
        task.url,
        response.body,
        config.outputDirectory,
      );

      // Parse HTML and extract links
      final foundUrls = _extractLinks(response.body, task.url, config);

      print(
        '[Worker] Completed: ${task.url} - Found ${foundUrls.length} links',
      );

      return WorkerResult(
        url: task.url,
        success: true,
        foundUrls: foundUrls,
        filePath: filePath,
      );
    } catch (e) {
      print('[Worker] Error processing ${task.url}: $e');
      return WorkerResult(url: task.url, success: false, error: e.toString());
    }
  }

  static Future<String> _savePage(
    String url,
    String content,
    String outputDir,
  ) async {
    final uri = Uri.parse(url);
    String fileName = uri.path.isEmpty || uri.path == '/'
        ? 'index.html'
        : uri.path.split('/').last;

    if (!fileName.endsWith('.html') && !fileName.contains('.')) {
      fileName += '.html';
    }

    // Create safe filename
    fileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    // Include query params in filename if they exist
    if (uri.query.isNotEmpty) {
      final queryHash = uri.query.hashCode.abs().toString();
      final name = path.basenameWithoutExtension(fileName);
      final ext = path.extension(fileName);
      fileName = '${name}_q$queryHash$ext';
    }

    final directory = Directory(path.join(outputDir, uri.host));
    await directory.create(recursive: true);

    final file = File(path.join(directory.path, fileName));
    await file.writeAsString(content);

    return file.path;
  }

  static List<String> _extractLinks(
    String html,
    String baseUrl,
    CrawlerConfig config,
  ) {
    final document = html_parser.parse(html);
    final links = <String>[];
    final baseUri = Uri.parse(baseUrl);

    // Extract links from <a> tags
    for (final element in document.querySelectorAll('a[href]')) {
      final href = element.attributes['href'];
      if (href != null) {
        final url = _resolveUrl(href, baseUri);
        if (url != null && _isValidUrl(url, config)) {
          links.add(url.toString());
        }
      }
    }

    // Extract CSS files if not skipped
    if (!config.skipCSS) {
      for (final element in document.querySelectorAll(
        'link[rel="stylesheet"][href]',
      )) {
        final href = element.attributes['href'];
        if (href != null) {
          final url = _resolveUrl(href, baseUri);
          if (url != null && _isValidUrl(url, config)) {
            links.add(url.toString());
          }
        }
      }
    }

    // Extract JS files if not skipped
    if (!config.skipJS) {
      for (final element in document.querySelectorAll('script[src]')) {
        final src = element.attributes['src'];
        if (src != null) {
          final url = _resolveUrl(src, baseUri);
          if (url != null && _isValidUrl(url, config)) {
            links.add(url.toString());
          }
        }
      }
    }

    // Extract images if not skipped
    if (!config.skipImages) {
      for (final element in document.querySelectorAll('img[src]')) {
        final src = element.attributes['src'];
        if (src != null) {
          final url = _resolveUrl(src, baseUri);
          if (url != null && _isValidUrl(url, config)) {
            links.add(url.toString());
          }
        }
      }
    }

    return links.toSet().toList(); // Remove duplicates
  }

  static Uri? _resolveUrl(String href, Uri baseUri) {
    try {
      return baseUri.resolve(href);
    } catch (e) {
      return null;
    }
  }

  static bool _isValidUrl(Uri url, CrawlerConfig config) {
    final baseUri = Uri.parse(config.baseUrl);

    // Check if it's the same domain as base URL or in allowed domains
    if (url.host != baseUri.host && !config.allowedDomains.contains(url.host)) {
      return false;
    }

    // Check disallowed paths
    for (final disallowedPath in config.disallowedPaths) {
      if (url.path.startsWith(disallowedPath)) {
        return false;
      }
    }

    // Only HTTP/HTTPS
    return url.scheme == 'http' || url.scheme == 'https';
  }
}
