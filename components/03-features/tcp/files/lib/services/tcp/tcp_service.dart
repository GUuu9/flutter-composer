import 'dart:io';
import 'dart:typed_data';

class TcpService {
  Socket? _socket;
  bool _connecting = false;
  bool _disposed = false;
  int _generation = 0;

  Future<void> connect(
    String host,
    int port, {
    bool secure = true,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_disposed || _socket != null || _connecting) {
      throw StateError('TCP unavailable; disconnect before reconnecting');
    }
    if (host.trim().isEmpty ||
        port < 1 ||
        port > 65535 ||
        timeout <= Duration.zero) {
      throw ArgumentError('TCP endpoint or timeout');
    }
    _connecting = true;
    final generation = _generation;
    try {
      final socket = secure
          ? await SecureSocket.connect(host, port, timeout: timeout)
          : await Socket.connect(host, port, timeout: timeout);
      if (_disposed || generation != _generation) {
        socket.destroy();
        throw StateError('TCP connection cancelled');
      }
      _socket = socket;
    } finally {
      _connecting = false;
    }
  }

  Stream<Uint8List> get bytes =>
      (_socket ?? (throw StateError('TCP disconnected')));

  Future<void> send(Uint8List bytes) async {
    if (bytes.length > 1024 * 1024)
      throw ArgumentError('TCP write exceeds 1 MiB');
    final socket = _socket ?? (throw StateError('TCP disconnected'));
    try {
      socket.add(bytes);
      await socket.flush().timeout(const Duration(seconds: 15));
    } catch (_) {
      disconnect();
      rethrow;
    }
  }

  void disconnect() {
    _generation++;
    _socket?.destroy();
    _socket = null;
  }

  void dispose() {
    _disposed = true;
    disconnect();
  }
}
