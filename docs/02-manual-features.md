<!-- version: v0.1.0 -->
# 기능 수동 추가

생성기는 Android·iOS·android-ios 중 OS 구성만 선택해 빈 앱을 만듭니다. 기능 소스·검사·패키지·권한·DI는 자동 추가하지 않습니다. 프로젝트 이름과 조직 식별자는 앱 생성에 필요한 기본 입력입니다. 이 문서와 기능별 문서는 안내용으로 포함되며 기능 설치 완료를 뜻하지 않습니다.

## 1. 필요한 기능 확인

| 구성품 | 상세 문서 |
| :--- | :--- |
| api | [설치·DI·사용·버전 안내](../components/03-features/api/files/docs/features/01-api.md) |
| ble | [설치·DI·사용·버전 안내](../components/03-features/ble/files/docs/features/02-ble.md) |
| log | [설치·DI·사용·버전 안내](../components/03-features/log/files/docs/features/06-log.md) |
| mqtt | [설치·DI·사용·버전 안내](../components/03-features/mqtt/files/docs/features/05-mqtt.md) |
| tcp | [설치·DI·사용·버전 안내](../components/03-features/tcp/files/docs/features/03-tcp.md) |
| udp | [설치·DI·사용·버전 안내](../components/03-features/udp/files/docs/features/04-udp.md) |

기능별 문서의 지원 OS·패키지/권한·실제 시작 메서드를 먼저 확인합니다. 통신은 필요한 시점에 시작하고, 필요 없는 계층이나 빈 initialize/dispose를 만들지 않습니다.

## 2. 구성품을 직접 복사

구성품 원본은 Flutter Composer의 components/03-features/<id>/files/입니다. Composer를 이미 내려받았다면 그 위치를 사용하고, 없다면 별도 폴더에 원본을 준비합니다. 아래 주소는 공개 원본이며 사용자 앱에 Composer를 덮어쓰는 명령이 아닙니다.

```bash
# 실행 위치: 원본을 보관할 상위 폴더의 터미널. 기존 폴더가 없는 새 경로를 사용합니다.
git clone https://github.com/GUuu9/flutter-composer.git flutter-composer-source
```

파일 탐색기/IDE에서 원하는 구성품의 다음 항목만 앱의 같은 상대 경로로 복사합니다. 예를 들어 tcp/files/lib/services/tcp/는 앱의 lib/services/tcp/에 둡니다. 이미 같은 파일이 있으면 먼저 diff를 확인해 합치며 폴더 전체 덮어쓰기를 하지 않습니다. 문서는 새 원본과 버전이 일치하도록 함께 확인/갱신합니다.

| 원본의 files/ 아래 | 앱 위치 | 처리 |
| :--- | :--- | :--- |
| lib/services/<기능>/ | lib/services/<기능>/ | 필요한 Service·소유 Model만 복사 |
| lib/apis/<기능>/ | lib/apis/<기능>/ | API 전송 경계가 있을 때 복사 |
| lib/utils/ | lib/utils/ | 구성품이 사용하는 util이 있을 때 복사 |
| test/ | test/ | 해당 기능 검사만 복사. package import의 이름을 실제 앱 이름으로 변경 |
| docs/features/ | docs/features/ | 기능 버전과 일치하는 설명서로 갱신 |

검사 원본의 package import에 있는 {{name}}은 Composer 생성 때 치환되는 템플릿이 아니라, **수동 복사 시 바꿔야 하는 자리표시자**입니다. 실제 앱 pubspec.yaml의 name으로 수정합니다.

```dart
// 파일: test/tcp_test.dart (TCP를 복사한 경우)
// 원본 package import의 {{name}}을 실제 앱 이름으로 변경합니다. 아래 my_app도 예시 이름입니다.
import 'package:my_app/services/tcp/tcp_service.dart';
```

앱의 main.dart·core/app.dart·core/di.dart·pubspec.yaml·플랫폼 설정·.env·Git·.composer/state.json을 원본으로 교체하지 않습니다. 구성품의 compose.json은 원본 정보 확인용이며 앱에 복사할 설정 파일이 아닙니다. 복사 후 실행/빌드는 앱 안의 소스만 사용하며 부모 Composer를 런타임에 참조하지 않습니다.

## 3. 패키지·권한·버전 연결

기능별 문서의 파일/위치 주석에 따라 pubspec.yaml·선택 OS의 Manifest/plist를 합칩니다. 같은 패키지/권한/키는 기존 값과 비교해 하나로 유지하고, 선언과 런타임 권한 요청/거부 처리를 함께 연결합니다. 실제 .env·키·토큰을 소스나 앱 asset에 넣지 않습니다.

앱 루트 versions.json의 SDK/도구와 기존 features를 유지하며 **실제 적용한 기능만** 구현/패키지 버전을 추가합니다. JSONC 예제의 설명 주석은 실제 JSON 파일에 넣지 않습니다. 직접 의존성은 pubspec.yaml, 실제 전체 의존성은 pubspec.lock으로 보관합니다. 버전 기록이 설치·검증을 대신하지 않습니다.

```bash
# 실행 위치: 앱 루트 터미널. 외부 패키지를 추가한 경우 실제 lock을 갱신합니다.
fvm flutter pub get
```

iOS는 앱의 docs/03-ios.md 절차로 Ruby·Bundler·CocoaPods·Xcode를 준비합니다. Android 전용 앱에는 iOS 설정을 추가하지 않습니다.

## 4. DI·초기화·호출 연결

기능별 문서의 DI 예제를 기존 lib/core/di.dart에 합칩니다. AppDependencies는 의존성을 생성자로 받고 createAppDependencies는 실제 객체를 생성·주입합니다. 같은 기능을 여러 소비자에 전달할 때 인스턴스를 한 번 확보해 공유합니다. 실제 ViewModel/Service에는 필요한 객체만 주입하고 DI 전체를 넘기지 않습니다.

```dart
// 파일: lib/main.dart
// 기존 main 진입을 유지합니다. 같은 runApp을 추가 호출하지 않습니다.
runApp(MobileApp(dependencies: createAppDependencies()));
```

app.dart는 전달받은 ViewModel을 Scene에 연결합니다. 생성자/Widget build에서 통신·권한 팝업을 실행하지 않고 실제 사용자/업무 동작 시 기능별 request/startScan/connect/bind/event를 호출합니다. 수신 구독의 onError/onDone과 화면 해제 뒤 결과 반영 방지도 처리합니다.

## 5. 세션 중단·최종 해제

화면이 만든 구독은 화면 종료 때 cancel합니다. 공유 Service는 필요가 끝나면 stopScan/disconnect/close로 중단하고 다시 사용할 수 있습니다. 최종 dispose는 DI 소유자가 맡으며 그 뒤에는 재사용하지 않습니다. 기능별 DI 예제의 dispose를 여러 개 합칠 때 역순으로 모두 시도하고 원래 오류와 정리 오류를 보존합니다.

자원이 있는 기능을 추가했을 때만 AppDependencies.dispose를 연결합니다. 아래 앱 예제는 해당 기능이 없는 빈 앱에 미리 추가하지 않습니다. AppDependencies는 같은 앱 수명 동안 교체하지 않으며, 외부에서 주입한 객체는 해제 소유권을 먼저 정합니다.

lib/core/app.dart는 의존성을 생성하지 않고 전달받은 의존성을 화면에 연결하며 앱 해제 시 최종 정리를 호출합니다. 기존 화면·theme·라우팅은 보존하고 수명 연결만 합칩니다.

```dart
// 파일: lib/core/app.dart
// 기존 MobileApp에 상태·최종 해제를 합칩니다. 화면·theme·라우팅은 보존합니다.
import 'dart:async';
import 'package:flutter/material.dart';
import 'di.dart';

class MobileApp extends StatefulWidget {
  const MobileApp({super.key, required this.dependencies});
  final AppDependencies dependencies;

  @override
  State<MobileApp> createState() => _MobileAppState();
}

class _MobileAppState extends State<MobileApp> {
  @override
  void dispose() {
    unawaited(widget.dependencies.dispose().catchError((Object error, StackTrace stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'app cleanup'));
    }));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: SizedBox.shrink()),
  );
}
```

OS 강제 종료·백그라운드에서 비동기 정리 완료를 보장하지 않습니다. 자동 재연결·백그라운드 서비스는 제공하지 않습니다.

## 6. 확인·업데이트·복귀

```bash
# 실행 위치: 앱 루트 터미널. 복사한 import·DI·검사 연결을 확인합니다.
fvm flutter analyze
fvm flutter test
fvm flutter devices
fvm flutter run -d Android기기ID
```

```bash
# 실행 위치: 앱 루트 터미널. iOS 준비 후 해당 플랫폼을 실행할 때 사용합니다.
bundle _2.5.23_ exec fvm flutter run -d iOS기기ID
```

기능별 실기기/서버 확인 항목을 수행하고 실제 확인일·기기/OS·결과 또는 미검증을 기록합니다. 빈 화면 실행이나 클래스 복사만으로 통신 연결 완료로 표시하지 않습니다. .composer/state.json은 최초 생성 기록이며 수동 기능 추가 후 성공 상태로 고쳐 쓰지 않습니다.

업데이트는 정상 소스·DI·플랫폼 설정·versions.json·pubspec/lock을 보관한 뒤 필요한 구성품만 diff로 병합합니다. 실패하면 함께 보관한 파일/버전 조합으로 복귀합니다. 기존 사용자 앱을 생성기의 재출력·검사 대상으로 사용하지 않습니다.
