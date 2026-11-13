import 'dart:async';
import 'dart:typed_data';
import 'package:universal_ble/universal_ble.dart' as ble;

class BleService {
  Future<void> _pending = Future.value();
  Future<void>? _disposal;
  bool _disposed = false;
  bool _scanning = false;
  String? _deviceId;

  // 플러그인은 앱 전체 BLE 상태를 공유하므로 메인 DI의 한 인스턴스로만 사용합니다.
  Future<T> _run<T>(Future<T> Function() operation) {
    if (_disposed) return Future.error(StateError('BLE disposed'));
    final result = _pending.then((_) => operation());
    _pending = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Stream<ble.BleDevice> get devices => ble.UniversalBle.scanStream;
  Stream<bool> connection(String deviceId) =>
      ble.UniversalBle.connectionStream(deviceId);

  Future<void> startScan({required List<String> serviceUuids}) => _run(
    () async {
      if (_scanning) throw StateError('BLE scan already active');
      await ble.UniversalBle.requestPermissions(withAndroidFineLocation: false);
      if (await ble.UniversalBle.getBluetoothAvailabilityState() !=
          ble.AvailabilityState.poweredOn) {
        throw StateError('Bluetooth unavailable or powered off');
      }
      _scanning = true;
      try {
        await ble.UniversalBle.startScan(
          scanFilter: ble.ScanFilter(withServices: serviceUuids),
          platformConfig: ble.PlatformConfig(
            android: ble.AndroidOptions(requestLocationPermission: false),
          ),
        );
      } catch (error, stack) {
        try {
          await _stopScan();
        } catch (cleanup, cleanupStack) {
          throw [(error, stack), (cleanup, cleanupStack)];
        }
        Error.throwWithStackTrace(error, stack);
      }
    },
  );

  Future<void> _stopScan() async {
    if (_scanning) {
      await ble.UniversalBle.stopScan();
      _scanning = false;
    }
  }

  Future<void> stopScan() => _run(_stopScan);

  Future<List<ble.BleService>> connect(String deviceId) => _run(() async {
    if (deviceId.isEmpty || _deviceId != null)
      throw StateError('BLE device unavailable');
    await _stopScan();
    await ble.UniversalBle.requestPermissions(withAndroidFineLocation: false);
    _deviceId = deviceId;
    try {
      await ble.UniversalBle.connect(
        deviceId,
        timeout: const Duration(seconds: 15),
      );
      return await ble.UniversalBle.discoverServices(deviceId);
    } catch (error, stack) {
      try {
        await _disconnect();
      } catch (cleanup, cleanupStack) {
        throw [(error, stack), (cleanup, cleanupStack)];
      }
      Error.throwWithStackTrace(error, stack);
    }
  });

  Future<Uint8List> read(String service, String characteristic) => _run(
    () => ble.UniversalBle.read(
      _deviceId ?? (throw StateError('BLE disconnected')),
      service,
      characteristic,
    ),
  );

  Future<void> write(String service, String characteristic, Uint8List bytes) =>
      _run(
        () => ble.UniversalBle.write(
          _deviceId ?? (throw StateError('BLE disconnected')),
          service,
          characteristic,
          bytes,
        ),
      );

  Future<void> _disconnect() async {
    final deviceId = _deviceId;
    if (deviceId != null) {
      await ble.UniversalBle.disconnect(
        deviceId,
        timeout: const Duration(seconds: 15),
      );
      if (await ble.UniversalBle.getConnectionState(deviceId) !=
          ble.BleConnectionState.disconnected) {
        throw StateError('BLE disconnect not confirmed');
      }
      _deviceId = null;
    }
  }

  Future<void> disconnect() => _run(_disconnect);

  Future<void> dispose() {
    _disposed = true;
    return _disposal ??= _pending.then((_) async {
      final errors = <(Object, StackTrace)>[];
      for (final close in [_stopScan, _disconnect]) {
        try {
          await close();
        } catch (error, stack) {
          errors.add((error, stack));
        }
      }
      if (errors.isNotEmpty) throw errors;
    });
  }
}
