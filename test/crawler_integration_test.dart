import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;
import '../lib/crawler.dart';
import '../lib/crawler_config.dart';
import 'server/test_server.dart';

void main() {
  late TestServer server;
  late String testOutputDir;

  setUpAll(() async {
    server = TestServer();
    await server.start();

    // Create unique test output directory
    testOutputDir = path.join(
      Directory.systemTemp.path,
      'cmc_crawler_test_${DateTime.now().millisecondsSinceEpoch}',
    );
  });

  tearDownAll(() async {
    await server.stop();

    // Clean up test output directory
    final dir = Directory(testOutputDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  });

  group('Crawler Tests', () {
    test('should crawl all accessible pages except disallowed paths', () async {
      final config = CrawlerConfig(
        baseUrl: server.baseUrl,
        maxWorkers: 2,
        outputDirectory: testOutputDir,
        disallowedPaths: ['/pagetoavoid'], // This path should be ignored
        skipCSS: true,
        skipJS: true,
        skipImages: false, // We want to test image downloading
      );

      final crawler = Crawler(config);
      await crawler.start();

      // Verify output directory structure
      final outputDir = Directory(testOutputDir);
      expect(await outputDir.exists(), isTrue);

      final hostDir = Directory(path.join(testOutputDir, 'localhost'));
      expect(await hostDir.exists(), isTrue);

      // Check that expected files were downloaded
      final indexFile = File(path.join(hostDir.path, 'index.html'));
      expect(await indexFile.exists(), isTrue);

      final pageFile = File(path.join(hostDir.path, 'page.html'));
      expect(await pageFile.exists(), isTrue);

      // Check query parameter files
      final queryParamFiles = await hostDir
          .list()
          .where((file) => file.path.contains('pagewithqueryparam'))
          .toList();
      expect(queryParamFiles.length, greaterThanOrEqualTo(1));

      // Check that disallowed page was NOT downloaded
      final pageToAvoidFile = File(path.join(hostDir.path, 'pagetoavoid.html'));
      expect(await pageToAvoidFile.exists(), isFalse);

      // Check that images were downloaded
      final image1File = File(path.join(hostDir.path, 'image1.jpg'));
      expect(await image1File.exists(), isTrue);

      final image2File = File(path.join(hostDir.path, 'image2.jpg'));
      expect(await image2File.exists(), isTrue);
    });

    test('should skip images when configured to do so', () async {
      final testOutputDirNoImages = path.join(testOutputDir, 'no_images');

      final config = CrawlerConfig(
        baseUrl: server.baseUrl,
        maxWorkers: 2,
        outputDirectory: testOutputDirNoImages,
        skipImages: true, // Skip images
        skipCSS: true,
        skipJS: true,
      );

      final crawler = Crawler(config);
      await crawler.start();

      final hostDir = Directory(path.join(testOutputDirNoImages, 'localhost'));
      expect(await hostDir.exists(), isTrue);

      // Check that HTML files were downloaded
      final indexFile = File(path.join(hostDir.path, 'index.html'));
      expect(await indexFile.exists(), isTrue);

      // Check that images were NOT downloaded
      final image1File = File(path.join(hostDir.path, 'image1.jpg'));
      expect(await image1File.exists(), isFalse);

      final image2File = File(path.join(hostDir.path, 'image2.jpg'));
      expect(await image2File.exists(), isFalse);
    });

    test('should handle workers configuration correctly', () async {
      final testOutputDirWorkers = path.join(testOutputDir, 'workers_test');

      final config = CrawlerConfig(
        baseUrl: server.baseUrl,
        maxWorkers: 1, // Single worker
        outputDirectory: testOutputDirWorkers,
        skipImages: true,
        skipCSS: true,
        skipJS: true,
      );

      final crawler = Crawler(config);
      await crawler.start();

      final hostDir = Directory(path.join(testOutputDirWorkers, 'localhost'));
      expect(await hostDir.exists(), isTrue);

      // Verify that crawling completed successfully even with single worker
      final indexFile = File(path.join(hostDir.path, 'index.html'));
      expect(await indexFile.exists(), isTrue);
    });

    test('should explicitly test disallowed paths filtering', () async {
      final testOutputDirFiltered = path.join(testOutputDir, 'filtered_test');

      final config = CrawlerConfig(
        baseUrl: server.baseUrl,
        maxWorkers: 1,
        outputDirectory: testOutputDirFiltered,
        disallowedPaths: ['/pagetoavoid'], // Explicitly filter this path
        skipImages: true,
        skipCSS: true,
        skipJS: true,
      );

      final crawler = Crawler(config);
      await crawler.start();

      final hostDir = Directory(path.join(testOutputDirFiltered, 'localhost'));
      expect(await hostDir.exists(), isTrue);

      // Check that allowed pages were downloaded
      final indexFile = File(path.join(hostDir.path, 'index.html'));
      expect(await indexFile.exists(), isTrue);

      final pageFile = File(path.join(hostDir.path, 'page.html'));
      expect(await pageFile.exists(), isTrue);

      // Check that query parameter pages were downloaded
      final files = await hostDir.list().map((f) => f.path).toList();
      final queryParamFiles = files
          .where((f) => f.contains('pagewithqueryparam'))
          .toList();
      expect(
        queryParamFiles.length,
        greaterThanOrEqualTo(1),
        reason: 'Should have downloaded query parameter pages',
      );

      // CRITICAL TEST: Check that disallowed page was NOT downloaded
      final pageToAvoidFile = File(path.join(hostDir.path, 'pagetoavoid.html'));
      expect(
        await pageToAvoidFile.exists(),
        isFalse,
        reason:
            'pagetoavoid.html should NOT exist due to disallowedPaths filter',
      );

      // Also verify it's not in the list of downloaded files
      expect(
        files.any((f) => f.contains('pagetoavoid')),
        isFalse,
        reason: 'No files should contain "pagetoavoid" in their name',
      );
    });
  });
}
