import 'dart:io';
import 'dart:typed_data';

class UdpService {
  RawDatagramSocket? _socket;
  bool _binding = false;
  bool _disposed = false;
  int _generation = 0;

  Future<void> bind(InternetAddress localAddress, {int port = 0}) async {
    if (_disposed || _socket != null || _binding)
      throw StateError('UDP unavailable');
    if (port < 0 || port > 65535 || localAddress.isMulticast) {
      throw ArgumentError('UDP unicast bind address or port');
    }
    _binding = true;
    final generation = _generation;
    try {
      final socket = await RawDatagramSocket.bind(localAddress, port);
      if (_disposed || generation != _generation) {
        socket.close();
        throw StateError('UDP bind cancelled');
      }
      _socket = socket;
    } finally {
      _binding = false;
    }
  }

  int get port => (_socket ?? (throw StateError('UDP closed'))).port;

  Stream<Datagram> get datagrams {
    final socket = _socket ?? (throw StateError('UDP closed'));
    return socket
        .where((event) => event == RawSocketEvent.read)
        .map((_) => socket.receive())
        .where((data) => data != null)
        .cast<Datagram>();
  }

  void send(Uint8List bytes, InternetAddress address, int port) {
    if (address.isMulticast ||
        port < 1 ||
        port > 65535 ||
        bytes.length > 1200) {
      throw ArgumentError(
        'UDP unicast destination or payload (max 1200 bytes)',
      );
    }
    final socket = _socket ?? (throw StateError('UDP closed'));
    if (socket.send(bytes, address, port) != bytes.length) {
      throw const SocketException('UDP send buffer unavailable');
    }
  }

  void close() {
    _generation++;
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    _disposed = true;
    close();
  }
}
