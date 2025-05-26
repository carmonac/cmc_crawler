class CrawlerTask {
  final String url;
  final String referrer;
  final int depth;

  CrawlerTask({required this.url, this.referrer = '', this.depth = 0});

  @override
  String toString() {
    return 'CrawlerTask(url: $url, referrer: $referrer, depth: $depth)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CrawlerTask && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
