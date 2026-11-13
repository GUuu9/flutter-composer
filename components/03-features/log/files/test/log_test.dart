import 'package:flutter_test/flutter_test.dart';
import 'package:{{name}}/services/log/log_service.dart';

void main() {
  test('log: rejects invalid input and disposed use without I/O', () async {
    final service = LogService();
    expect(() => service.event('Bearer secret value'), throwsArgumentError);
    expect(() => service.event('event', level: -1), throwsArgumentError);
  });
}
