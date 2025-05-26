import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

class TestServer {
  late HttpServer _server;
  late String baseUrl;

  Future<void> start({int port = 0}) async {
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler(_router);

    _server = await shelf_io.serve(handler, 'localhost', port);
    baseUrl = 'http://localhost:${_server.port}';
    print('Test server started at $baseUrl');
  }

  Future<void> stop() async {
    await _server.close();
    print('Test server stopped');
  }

  Response _router(Request request) {
    final path = request.url.path;
    final query = request.url.query;

    print('Request: ${request.method} $path${query.isNotEmpty ? '?$query' : ''}');

    switch (path) {
      case '':
      case '/':
        return _indexPage(request);
      case 'page':
        return _pageWithImage(request);
      case 'pagewithqueryparam':
        return _pageWithQueryParam(request, query);
      case 'pagetoavoid':
        return _pageToAvoid(request);
      case 'image1.jpg':
        return _image1(request);
      case 'image2.jpg':
        return _image2(request);
      default:
        print('404 - Path not found: $path');
        return Response.notFound('Page not found: $path');
    }
  }

  Response _indexPage(Request request) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Test Index Page</title>
</head>
<body>
    <h1>Test Crawler Index</h1>
    <p>This is the main index page for testing the crawler.</p>
    <ul>
        <li><a href="/page">Page with Image</a></li>
        <li><a href="/pagewithqueryparam?example=1">Page with Query Param (example=1)</a></li>
        <li><a href="/pagewithqueryparam?example=2">Page with Query Param (example=2)</a></li>
        <li><a href="/pagetoavoid">Page to Avoid (should not be crawled)</a></li>
    </ul>
</body>
</html>
    ''';

    return Response.ok(
      html,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }

  Response _pageWithImage(Request request) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Page with Image</title>
</head>
<body>
    <h1>Page with Image</h1>
    <p>This page contains an image and links.</p>
    <img src="/image1.jpg" alt="Test Image 1" width="200" height="150">
    <ul>
        <li><a href="/">Back to Index</a></li>
        <li><a href="/pagewithqueryparam?example=1">Page with Query Param (example=1)</a></li>
    </ul>
</body>
</html>
    ''';

    return Response.ok(
      html,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }

  Response _pageWithQueryParam(Request request, String query) {
    if (query.contains('example=1')) {
      final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Page with Query Param (example=1)</title>
</head>
<body>
    <h1>Page with Query Parameter - Example 1</h1>
    <p>This page has images to test duplicate image handling.</p>
    <img src="/image1.jpg" alt="Test Image 1 (duplicate)" width="200" height="150">
    <img src="/image2.jpg" alt="Test Image 2" width="200" height="150">
    <ul>
        <li><a href="/">Back to Index</a></li>
        <li><a href="/page">Page with Image</a></li>
        <li><a href="/pagewithqueryparam?example=2">Query Param Example 2</a></li>
    </ul>
</body>
</html>
      ''';

      return Response.ok(
        html,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    } else if (query.contains('example=2')) {
      final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Page with Query Param (example=2)</title>
</head>
<body>
    <h1>Page with Query Parameter - Example 2</h1>
    <p>This page has only HTML content and links, no images.</p>
    <ul>
        <li><a href="/">Back to Index</a></li>
        <li><a href="/page">Page with Image</a></li>
        <li><a href="/pagewithqueryparam?example=1">Query Param Example 1</a></li>
    </ul>
</body>
</html>
      ''';

      return Response.ok(
        html,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    } else {
      return Response.notFound('Invalid query parameter');
    }
  }

  Response _pageToAvoid(Request request) {
    final html = '''
<!DOCTYPE html>
<html>
<head>
    <title>Page to Avoid</title>
</head>
<body>
    <h1>This Page Should Not Be Crawled</h1>
    <p>If you see this page in the crawler output, the path filtering is not working correctly.</p>
    <a href="/">Back to Index</a>
</body>
</html>
    ''';

    return Response.ok(
      html,
      headers: {'content-type': 'text/html; charset=utf-8'},
    );
  }

  Response _image1(Request request) {
    // Simple 1x1 pixel red PNG image
    final pngBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg==',
    );

    return Response.ok(pngBytes, headers: {'content-type': 'image/png'});
  }

  Response _image2(Request request) {
    // Simple 1x1 pixel blue PNG image
    final pngBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAEUlEQVR42mNkYPhfz0AEYBxgGAFdNRCVJQAAAABJRU5ErkJggg==',
    );

    return Response.ok(pngBytes, headers: {'content-type': 'image/png'});
  }
}
