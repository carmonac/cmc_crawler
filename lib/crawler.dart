import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:isolate';
import 'crawler_config.dart';
import 'crawler_task.dart';
import 'crawler_worker.dart';
import 'worker_message.dart';
import 'worker_result.dart';

class Crawler {
  final CrawlerConfig config;
  final Queue<CrawlerTask> _taskQueue = Queue<CrawlerTask>();
  final Set<String> _visitedUrls = <String>{};
  final List<Isolate> _workers = [];
  final List<SendPort> _workerSendPorts = [];
  final List<ReceivePort> _workerReceivePorts = [];
  bool _isRunning = false;
  int _completedTasks = 0;
  int _totalTasks = 0;

  Crawler(this.config);

  Future<void> start() async {
    if (_isRunning) {
      print('Crawler is already running');
      return;
    }

    _isRunning = true;
    print('Starting crawler with base URL: ${config.baseUrl}');
    print('Max workers: ${config.maxWorkers}');
    print('Output directory: ${config.outputDirectory}');

    // Create output directory
    final outputDir = Directory(config.outputDirectory);
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    // Add initial task
    final startUrl = config.targetUrl ?? config.baseUrl;
    _addTask(CrawlerTask(url: startUrl, depth: 0));

    // Start workers
    await _startWorkers();

    // Process tasks
    await _processTasks();

    print('Crawler completed. Total pages processed: $_completedTasks');
  }

  void stop() {
    print('Stopping crawler');
    _isRunning = false;
  }

  Future<void> _startWorkers() async {
    print('Starting ${config.maxWorkers} workers...');

    for (int i = 0; i < config.maxWorkers; i++) {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(CrawlerWorker.workerEntryPoint, [
        receivePort.sendPort,
      ]);

      _workers.add(isolate);
      _workerReceivePorts.add(receivePort);

      // Wait for worker to send back its SendPort
      final sendPort = await receivePort.first as SendPort;
      _workerSendPorts.add(sendPort);

      print('Worker ${i + 1} started');
    }
  }

  void _addTask(CrawlerTask task) {
    if (!_visitedUrls.contains(task.url) && _isValidUrl(task.url)) {
      _taskQueue.add(task);
      _visitedUrls.add(task.url);
      _totalTasks++;
      print(
        '[Queue] Added task: ${task.url} (Queue size: ${_taskQueue.length})',
      );
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final baseUri = Uri.parse(config.baseUrl);

      // Check if it's the same domain as base URL or in allowed domains
      if (uri.host != baseUri.host &&
          !config.allowedDomains.contains(uri.host)) {
        return false;
      }

      // Check disallowed paths
      for (final disallowedPath in config.disallowedPaths) {
        if (uri.path.startsWith(disallowedPath)) {
          print(
            '[Filter] Skipping disallowed path: $url (matches: $disallowedPath)',
          );
          return false;
        }
      }

      // Only HTTP/HTTPS
      return uri.scheme == 'http' || uri.scheme == 'https';
    } catch (e) {
      print('[Filter] Invalid URL: $url - $e');
      return false;
    }
  }

  Future<void> _processTasks() async {
    final activeTasks = <Completer<void>>[];
    final availableWorkers = List<int>.generate(config.maxWorkers, (i) => i);

    while (_isRunning && (_taskQueue.isNotEmpty || activeTasks.isNotEmpty)) {
      // Assign tasks to available workers
      while (_taskQueue.isNotEmpty && availableWorkers.isNotEmpty) {
        final task = _taskQueue.removeFirst();
        final workerIndex = availableWorkers.removeAt(0);

        final completer = Completer<void>();
        _processTaskWithWorker(task, workerIndex)
            .then((_) {
              availableWorkers.add(workerIndex);
              completer.complete();
            })
            .catchError((error) {
              availableWorkers.add(workerIndex);
              completer.completeError(error);
            });

        activeTasks.add(completer);
      }

      // Wait for at least one task to complete
      if (activeTasks.isNotEmpty) {
        final futures = activeTasks.map((c) => c.future).toList();
        await Future.any(futures);
        activeTasks.removeWhere((completer) => completer.isCompleted);
      }

      // Small delay to prevent tight loop
      await Future.delayed(Duration(milliseconds: 100));
    }

    // Wait for all remaining tasks to complete
    final remainingFutures = activeTasks.map((c) => c.future).toList();
    if (remainingFutures.isNotEmpty) {
      await Future.wait(remainingFutures);
    }

    // Stop all workers
    await _stopWorkers();
  }

  Future<void> _processTaskWithWorker(CrawlerTask task, int workerIndex) async {
    try {
      final sendPort = _workerSendPorts[workerIndex];

      // Create a unique ReceivePort for this task
      final taskReceivePort = ReceivePort();

      // Send task to worker with response port
      sendPort.send(
        WorkerMessage('crawl', {
          'url': task.url,
          'referrer': task.referrer,
          'depth': task.depth,
          'config': _configtoMap(),
          'responsePort': taskReceivePort.sendPort,
        }).toMap(),
      );

      // Wait for result from the task-specific port
      final resultData = await taskReceivePort.first as Map<String, dynamic>;
      taskReceivePort.close(); // Close the port after receiving the result

      final result = WorkerResult.fromMap(resultData);

      _completedTasks++;

      if (result.success) {
        print('[$_completedTasks/$_totalTasks] ✓ Downloaded: ${result.url}');
        if (result.filePath != null) {
          print('  Saved to: ${result.filePath}');
        }

        // Add found URLs to queue
        for (final foundUrl in result.foundUrls) {
          if (!_visitedUrls.contains(foundUrl)) {
            _addTask(
              CrawlerTask(
                url: foundUrl,
                referrer: task.url,
                depth: task.depth + 1,
              ),
            );
          }
        }
      } else {
        print('[$_completedTasks/$_totalTasks] ✗ Failed: ${result.url}');
        if (result.error != null) {
          print('  Error: ${result.error}');
        }
      }
    } catch (e) {
      print('Error processing task with worker $workerIndex: $e');
    }
  }

  Map<String, dynamic> _configtoMap() {
    return {
      'baseUrl': config.baseUrl,
      'targetUrl': config.targetUrl,
      'maxWorkers': config.maxWorkers,
      'skipCSS': config.skipCSS,
      'skipJS': config.skipJS,
      'skipImages': config.skipImages,
      'allowedDomains': config.allowedDomains,
      'disallowedPaths': config.disallowedPaths,
      'outputDirectory': config.outputDirectory,
      'userAgent': config.userAgent,
    };
  }

  Future<void> _stopWorkers() async {
    print('Stopping workers...');

    for (int i = 0; i < _workerSendPorts.length; i++) {
      _workerSendPorts[i].send(WorkerMessage('stop', null).toMap());
    }

    for (final isolate in _workers) {
      isolate.kill();
    }

    for (final receivePort in _workerReceivePorts) {
      receivePort.close();
    }

    _workers.clear();
    _workerSendPorts.clear();
    _workerReceivePorts.clear();
  }
}
