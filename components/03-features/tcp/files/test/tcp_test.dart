import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{name}}/services/tcp/tcp_service.dart';

void main() {
  test('tcp: rejects invalid input and disposed use without I/O', () async {
    final service = TcpService();
    await expectLater(service.connect('', 0), throwsArgumentError);
    service.dispose();
    await expectLater(service.connect('localhost', 1), throwsStateError);
  });
  test('TCP disconnect during connect discards late socket', () async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final incoming = server.listen((socket) => socket.destroy());
    final service = TcpService();
    try {
      final connection = service.connect(
        '127.0.0.1',
        server.port,
        secure: false,
      );
      service.disconnect();
      await expectLater(connection, throwsStateError);
      expect(() => service.bytes, throwsStateError);
    } finally {
      service.dispose();
      await incoming.cancel();
      await server.close();
    }
  });
}
