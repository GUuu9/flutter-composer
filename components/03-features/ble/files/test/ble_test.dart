import 'package:flutter_test/flutter_test.dart';
import 'package:universal_ble/universal_ble.dart' as ble;
import 'package:{{name}}/services/ble/ble_service.dart';

void main() {
  test('ble: rejects invalid input and disposed use without I/O', () async {
    final service = BleService();
    await service.dispose();
    await expectLater(service.startScan(serviceUuids: []), throwsStateError);
    await expectLater(service.connect('device'), throwsStateError);
  });
  test(
    'BLE permission refusal prevents scanning; owned scan is cleaned up',
    () async {
      final platform = _ScanPlatform();
      ble.UniversalBle.setInstance(platform);
      final service = BleService();
      await expectLater(service.startScan(serviceUuids: []), throwsStateError);
      expect(platform.scans, 0);
      platform.allow = true;
      await service.startScan(serviceUuids: []);
      await service.dispose();
      expect(platform.scans, 1);
      expect(platform.stops, 1);
    },
  );
}

class _ScanPlatform extends ble.UniversalBlePlatform {
  bool allow = false;
  int scans = 0;
  int stops = 0;
  @override
  Future<void> requestPermissions({
    bool withAndroidFineLocation = false,
  }) async {
    if (!allow) throw StateError('permission denied');
  }

  @override
  Future<ble.AvailabilityState> getBluetoothAvailabilityState() async =>
      ble.AvailabilityState.poweredOn;
  @override
  Future<void> startScan({
    ble.ScanFilter? scanFilter,
    ble.PlatformConfig? platformConfig,
  }) async {
    scans++;
  }

  @override
  Future<void> stopScan() async {
    stops++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Unexpected BLE platform call');
}
