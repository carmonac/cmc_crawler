class CrawlerConfig {
  final String baseUrl;
  final String? targetUrl;
  final int maxWorkers;
  final bool skipCSS;
  final bool skipJS;
  final bool skipImages;
  final List<String> allowedDomains;
  final List<String> disallowedPaths;
  final String outputDirectory;
  final String userAgent;

  CrawlerConfig({
    required this.baseUrl,
    this.targetUrl,
    this.maxWorkers = 4,
    this.skipCSS = false,
    this.skipJS = false,
    this.skipImages = false,
    List<String>? allowedDomains,
    List<String>? disallowedPaths,
    this.outputDirectory = 'output',
    this.userAgent = 'CMC Crawler 1.0',
  }) : allowedDomains = allowedDomains ?? [],
       disallowedPaths = disallowedPaths ?? [];
}
