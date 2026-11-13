import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{name}}/services/udp/udp_service.dart';

void main() {
  test('udp: rejects invalid input and disposed use without I/O', () async {
    final service = UdpService();
    await expectLater(
      service.bind(InternetAddress.loopbackIPv4, port: -1),
      throwsArgumentError,
    );
    service.dispose();
    await expectLater(
      service.bind(InternetAddress.loopbackIPv4),
      throwsStateError,
    );
  });
  test('UDP unicast loopback delivers bytes and sender port', () async {
    final sender = UdpService();
    final receiver = UdpService();
    try {
      await sender.bind(InternetAddress.loopbackIPv4);
      await receiver.bind(InternetAddress.loopbackIPv4);
      final response = receiver.datagrams.first.timeout(
        const Duration(seconds: 2),
      );
      sender.send(
        Uint8List.fromList([1, 2]),
        InternetAddress.loopbackIPv4,
        receiver.port,
      );
      final datagram = await response;
      expect(datagram.data, [1, 2]);
      expect(datagram.port, sender.port);
    } finally {
      sender.dispose();
      receiver.dispose();
    }
  });
}
