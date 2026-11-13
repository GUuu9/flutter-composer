import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class HttpResult {
  const HttpResult(this.statusCode, this.body);
  final int statusCode;
  final Uint8List body;
}

class HttpApi {
  final _clients = <HttpClient>{};
  bool _disposed = false;

  Future<HttpResult> request(
    String method,
    Uri uri, {
    Map<String, String> headers = const {},
    Uint8List? body,
    Duration timeout = const Duration(seconds: 30),
    int maxBytes = 2 * 1024 * 1024,
  }) async {
    if (_disposed) throw StateError('HttpApi disposed');
    if (uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        !RegExp(r'^[A-Z]+$').hasMatch(method) ||
        timeout <= Duration.zero ||
        maxBytes < 1 ||
        (body?.length ?? 0) > maxBytes) {
      throw ArgumentError('HTTPS endpoint, method, timeout or size');
    }
    final client = HttpClient()..connectionTimeout = timeout;
    _clients.add(client);
    Future<HttpResult> send() async {
      final request = await client.openUrl(method, uri);
      request.followRedirects = false;
      headers.forEach((key, value) => request.headers.set(key, value));
      if (body != null) request.add(body);
      final response = await request.close();
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        if (bytes.length + chunk.length > maxBytes) {
          throw const HttpException('Response exceeds size limit');
        }
        bytes.add(chunk);
      }
      return HttpResult(response.statusCode, bytes.takeBytes());
    }

    try {
      return await send().timeout(
        timeout,
        onTimeout: () {
          client.close(force: true);
          throw TimeoutException('HTTPS request timed out', timeout);
        },
      );
    } finally {
      _clients.remove(client);
      client.close(force: true);
    }
  }

  void dispose() {
    _disposed = true;
    for (final client in _clients) {
      client.close(force: true);
    }
  }
}
