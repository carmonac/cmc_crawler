class WorkerResult {
  final String url;
  final bool success;
  final List<String> foundUrls;
  final String? error;
  final String? filePath;

  WorkerResult({
    required this.url,
    required this.success,
    this.foundUrls = const [],
    this.error,
    this.filePath,
  });

  Map<String, dynamic> toMap() => {
    'url': url,
    'success': success,
    'foundUrls': foundUrls,
    'error': error,
    'filePath': filePath,
  };

  factory WorkerResult.fromMap(Map<String, dynamic> json) => WorkerResult(
    url: json['url'],
    success: json['success'],
    foundUrls: List<String>.from(json['foundUrls'] ?? []),
    error: json['error'],
    filePath: json['filePath'],
  );
}
