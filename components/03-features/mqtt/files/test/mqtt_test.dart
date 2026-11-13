import 'package:flutter_test/flutter_test.dart';
import 'package:{{name}}/services/mqtt/mqtt_service.dart';

void main() {
  test('mqtt: rejects invalid input and disposed use without I/O', () async {
    final service = MqttService();
    await expectLater(service.connect('', 0, ''), throwsArgumentError);
    service.dispose();
    await expectLater(
      service.connect('localhost', 8883, 'client'),
      throwsStateError,
    );
  });
}
