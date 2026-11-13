<!-- version: v0.2.0 -->
# 02. BLE

universal_ble **1.0.0**으로 주변 BLE 장치 검색·한 장치 연결·GATT 서비스 탐색·characteristic 읽기/응답 있는 쓰기를 제공합니다. Bluetooth Classic/SPP·광고·백그라운드 통신은 포함하지 않습니다. 플러그인의 Dart 조건(>=3.1.3), iOS 최소 13.1·Android 최소 21은 앱 기준보다 낮지만 현재 고정 Xcode/Gradle 조합의 네이티브 빌드 호환은 미검증입니다.

## 설치·확인

[기능 설치·수명 안내](../04-features.md)에 따라 앱 루트에서 의존성을 설치하고 확인합니다. Android 최소 API 28·target/compile 36, iOS 최소 15.0이며 OS 상한은 고정하지 않습니다. 이 기능의 플랫폼 빌드·실기기 검증은 아직 수행하지 않았습니다(2026-11-12).

```yaml
# 파일: pubspec.yaml
# 기존 dependencies에 아래 패키지를 합칩니다. dependencies 키를 중복 추가하지 않습니다.
dependencies:
  universal_ble: 1.0.0
```

## 권한

| OS | 직접 추가할 설정·사용자 동작 |
| :--- | :--- |
| Android 9/API 28 | BLUETOOTH·BLUETOOTH_ADMIN, COARSE/FINE 위치 선언. 플러그인이 FINE 위치를 런타임 요청하며 기기 위치 서비스도 확인 |
| Android 10–11/API 29–30 | 레거시 Bluetooth·FINE 위치 권한. 검색 전 위치 동의·위치 서비스 확인 |
| Android 12+/API 31+ | BLUETOOTH_SCAN·BLUETOOTH_CONNECT를 런타임 요청. 레거시/위치 선언은 maxSdkVersion으로 제한 |
| iOS 15+ | Info.plist의 NSBluetoothAlwaysUsageDescription·플러그인 안내용 NSBluetoothPeripheralUsageDescription. 실제 목적을 수정하고 최초 사용 때 Bluetooth 동의 |

startScan/connect가 사용자가 기능을 실행한 시점에 권한을 요청합니다. API 31+는 위치 추론을 하지 않는 **neverForLocation** 설정이며 일부 beacon이 검색에서 제외될 수 있습니다. 위치 측정 용도로 전환하면 Manifest와 런타임 위치 요청을 함께 재설계합니다. 광고/백그라운드 위치 권한은 생성하지 않습니다. Bluetooth가 꺼짐·미지원·권한 거부 시 예외를 UI에서 처리하고 설정 변경 뒤 재시도합니다. 영구 거부 시 반복 요청하지 말고 Android 앱 설정/iOS 개인정보 보호 및 보안 → Bluetooth를 안내합니다.


## 권한 파일에 추가

```xml
<!-- 파일: android/app/src/main/AndroidManifest.xml -->
<!-- manifest 바로 아래, application 밖에 합칩니다. 같은 권한은 속성까지 확인해 중복하지 않습니다. -->
<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" android:maxSdkVersion="28" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
```

```xml
<!-- 파일: ios/Runner/Info.plist -->
<!-- 최상위 dict 안에 합칩니다. 같은 key를 중복 작성하지 않고 실제 용도 설명으로 수정합니다. -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>사용자가 선택한 주변 BLE 기기를 검색하고 연결하여 데이터를 교환합니다.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>사용자가 선택한 주변 BLE 기기를 검색하고 연결하여 데이터를 교환합니다.</string>
```

선택한 OS의 BLE 권한만 적용하고 용도 설명을 실제 앱 목적에 맞게 수정합니다.

## DI 등록·초기화

앱의 lib/core/di.dart에 아래 항목을 합칩니다. 이 예제는 ble 하나를 연결한 형태이며 기존 AppDependencies·생성 함수 전체를 덮어쓰지 않습니다. 여러 기능의 해제 순서/오류 수집과 app.dart 연결은 [기능 수동 추가 안내](../04-features.md)를 따릅니다.

```dart
// 파일: lib/core/di.dart
// 기존 파일에 병합합니다. 같은 클래스/생성 함수를 중복 선언하지 않습니다.
// 기존 import 아래에 추가합니다.
import '../services/ble/ble_service.dart';

// 기존 AppDependencies의 생성자·필드·정리 메서드에 아래 항목을 합칩니다.
class AppDependencies {
  const AppDependencies({required this.bleService});
  final BleService bleService;

  Future<void> dispose() async {
    await bleService.dispose();
  }
}

// 기존 createAppDependencies의 인자와 반환 객체에 이 기능을 합칩니다.
AppDependencies createAppDependencies({BleService? bleService}) {
  final sharedService = bleService ?? BleService();
  // 실제 소비자(ViewModel/Service)가 있으면 생성자에 bleService: sharedService를 주입합니다.
  // AppDependencies에도 같은 객체를 전달합니다. 공유 객체를 다시 생성하지 않습니다.
  return AppDependencies(bleService: sharedService);
}
```

main.dart의 MobileApp(dependencies: createAppDependencies()) 진입은 유지합니다. 업무 소비자가 있으면 위 createAppDependencies의 sharedService를 실제 ViewModel/Service 생성자에 주입하고 같은 객체를 AppDependencies에도 전달합니다. 소비자는 `BleService`만 받고 DI 전체를 참조하지 않습니다. ViewModel을 추가했다면 AppDependencies에 함께 보관하고 app.dart는 전달받은 ViewModel을 Scene에 연결합니다. Widget build에서 공유 Service/ViewModel을 매번 새로 만들지 않습니다. 아래 사용 예제의 `bleService`는 소비자 생성자로 받은 객체입니다.

별도 initialize는 없습니다. 사용자가 검색을 실행할 때 startScan으로 권한을 요청하고, 선택한 장치에 connect한 뒤 서비스/characteristic을 확인합니다. Widget build나 생성자에서 권한 팝업을 실행하지 않습니다.

세션 중단과 최종 해제를 구분합니다. 화면이 보관한 stream 구독은 화면 종료 때 취소하고, 공유 bleService의 dispose는 DI 소유자가 앱 해제 때 호출합니다. app.dart의 비동기 해제 연결을 빠뜨리지 않습니다. 외부에서 객체를 주입했다면 해제 소유권을 정하고 중복 해제하지 않습니다.

## 사용

DI의 bleService 하나만 주입합니다. 플러그인을 다른 곳에서 직접 호출하거나 BleService를 추가 생성하면 앱 전체 스캔 상태가 충돌할 수 있습니다. serviceUuid·characteristicUuid는 실제 기기 명세, deviceId는 검색 결과에서 사용자가 선택한 값입니다. UUID를 임의 샘플 값으로 고정하지 않습니다.

```dart
// 파일: lib/scenes/<기능>/<기능>_view_model.dart (실제 소비자 파일명으로 바꿉니다.)
// 생성자로 주입받은 객체를 사용해 사용자 동작/업무 메서드 안에 추가합니다.
// 아래 코드는 메서드 본문 일부이며 파일 최상위에 붙이지 않습니다.
final subscription = bleService.devices.listen(onDevice, onError: onScanError);
try {
  await bleService.startScan(serviceUuids: [serviceUuid]);
  // 실제 UI에서 장치를 선택한 뒤 별도 동작으로 아래 과정을 실행합니다.
} catch (error) {
  await subscription.cancel();
  rethrow;
}
// 검색 화면을 닫거나 장치를 선택할 때:
await bleService.stopScan();
await subscription.cancel();
final services = await bleService.connect(deviceId);
try {
  final bytes = await bleService.read(serviceUuid, characteristicUuid);
  await bleService.write(serviceUuid, writableCharacteristicUuid, commandBytes);
} finally {
  await bleService.disconnect();
}
```

connect는 진행 중 스캔을 멈추고 서비스/characteristic 목록을 반환합니다. 읽기/쓰기 속성을 확인하여 사용하고 패킷 크기·분할·장치별 명령/응답은 기기 프로토콜에 맞춰 호출 Service에서 처리합니다. 쓰기 응답은 GATT 전달 확인이며 기기의 업무 완료 확인은 아닙니다. 연결 상태는 connection(deviceId) stream으로 관찰하며 구독을 해제합니다. 연결이 끊어지면 disconnect 후 명시적으로 재연결합니다.

작업은 순서대로 실행되며 dispose는 대기 작업 후 스캔·연결을 정리합니다. 권한 팝업이 열린 동안 정리가 즉시 끝나지는 않습니다. 실패 복구에서 원래 오류와 정리 오류를 모두 보존합니다. Hot restart는 네이티브 연결을 남길 수 있으므로 기기 재검사 때 앱 완전 종료 후 재실행합니다.

## 실기기 확인

Android API 28–30·31+ 및 iOS에서 허용/거부/설정에서 철회·Bluetooth 끄기·스캔 취소·연결 실패·읽기/쓰기·기기 전원 끊기·재연결을 확인합니다. BLE 검증에는 실제 주변 기기와 휴대폰을 사용합니다. Emulator/Simulator 성공을 실기기 확인으로 대체하지 않습니다.

공식 근거: [고정 패키지](https://pub.dev/packages/universal_ble/versions/1.0.0), [Android Bluetooth 권한](https://developer.android.com/develop/connectivity/bluetooth/bt-permissions), [Apple Bluetooth 용도 설명](https://developer.apple.com/documentation/bundleresources/information-property-list/nsbluetoothalwaysusagedescription).

## 사용 버전 기록·변경

구성품 구현 버전은 **0.1.0**입니다. 이것은 Composer 구성품의 선언 버전이며 실기기 검증 완료나 패키지 배포 버전을 뜻하지 않습니다. 외부 패키지는 universal_ble **1.0.0**로 별도 고정합니다.

1. 앱 루트 versions.json의 기존 SDK/도구 값은 유지하고 features 안에 이 기능의 다음 항목을 합칩니다. 아래 JSON은 추가할 부분이며 파일 전체를 교체하지 않습니다. 실제 적용한 구현/패키지 버전을 기록합니다.

```jsonc
// 파일: versions.json
// 기존 최상위 객체의 features에 이 기능 항목을 합칩니다. 기존 SDK/기능 기록은 보존합니다.
// JSON은 주석을 지원하지 않으므로 이 설명 주석은 실제 파일에 넣지 않습니다.
{
  "features": {
    "ble": {
      "version": "0.1.0",
      "dependencies": {
        "universal_ble": "1.0.0"
      }
    }
  }
}
```

2. 외부 패키지가 있으면 pubspec.yaml의 dependencies에도 같은 직접 의존성 버전을 고정하고 앱 루트 터미널에서 다음 명령으로 실제 pubspec.lock을 생성·갱신합니다.

```bash
# 실행 위치: 앱 루트 터미널 (파일에 작성하는 코드가 아닙니다.)
fvm flutter pub get
```

 lock 파일을 직접 편집하거나 삭제하지 않습니다. SDK 기본 기능만 쓰는 경우 pubspec에 dart 같은 패키지를 추가하지 않습니다.
3. 패키지 버전 변경은 이 기능만 대상으로 검토하며 다른 패키지를 일괄 upgrade하지 않습니다. 플랫폼 최소 버전/권한/호환성·아래 동작 확인을 점검하고 기능 문서에 실제 확인일·기기/OS·결과 또는 미검증을 기록합니다. versions.json은 기록용이며 의존성을 설치하거나 제한하지 않습니다.
4. 복사한 서비스 소스를 수정하면 앱의 구현 버전도 올리고 변경 내역을 남깁니다. Composer의 새 구현을 가져올 때는 기존 소스·DI·설정·lock을 보관하고 diff로 병합합니다. 복귀 시 해당 파일과 버전 기록을 정상 조합으로 함께 복구합니다.

기능 원본을 관리할 때는 components/03-features/ble/compose.json의 version·dependencies, 이 문서·소스/검사·update.md를 함께 갱신합니다. 구현/사용 절차 추가는 minor, 호환 수정은 patch, 기존 호출/설정이 깨지면 major를 올립니다. 패키지만 바뀌어도 호환성 확인 결과를 남깁니다. Composer 밖 앱은 앱 내부 기록만 바꾸고 원본을 자동 수정하지 않습니다.
