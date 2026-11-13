<!-- version: v0.2.0 -->
# 03. TCP

Dart Socket/SecureSocket 기반 단일 연결 클라이언트입니다. 패킷 변환·메시지 경계는 별도 프로토콜 Service에서 처리합니다. 추가 패키지는 없습니다.

## 설치·확인

[기능 설치·수명 안내](../04-features.md)에 따라 앱 루트에서 의존성을 설치하고 확인합니다. Android 최소 API 28·target/compile 36, iOS 최소 15.0이며 OS 상한은 고정하지 않습니다. 이 기능의 플랫폼 빌드·실기기 검증은 아직 수행하지 않았습니다(2026-11-12).


## 권한 파일에 추가

```xml
<!-- 파일: android/app/src/main/AndroidManifest.xml -->
<!-- manifest 바로 아래, application 밖에 합칩니다. 같은 권한은 속성까지 확인해 중복하지 않습니다. -->
<uses-permission android:name="android.permission.INTERNET" />
```

```xml
<!-- 파일: ios/Runner/Info.plist -->
<!-- 최상위 dict 안에 합칩니다. 같은 key를 중복 작성하지 않고 실제 용도 설명으로 수정합니다. -->
<key>NSLocalNetworkUsageDescription</key>
<string>같은 네트워크의 사용자가 선택한 장치와 데이터를 교환합니다.</string>
```

선택한 OS의 설정만 적용합니다. LAN을 사용하지 않는 앱은 NSLocalNetworkUsageDescription을 추가하지 않아도 됩니다.

## DI 등록·초기화

앱의 lib/core/di.dart에 아래 항목을 합칩니다. 이 예제는 tcp 하나를 연결한 형태이며 기존 AppDependencies·생성 함수 전체를 덮어쓰지 않습니다. 여러 기능의 해제 순서/오류 수집과 app.dart 연결은 [기능 수동 추가 안내](../04-features.md)를 따릅니다.

```dart
// 파일: lib/core/di.dart
// 기존 파일에 병합합니다. 같은 클래스/생성 함수를 중복 선언하지 않습니다.
// 기존 import 아래에 추가합니다.
import '../services/tcp/tcp_service.dart';

// 기존 AppDependencies의 생성자·필드·정리 메서드에 아래 항목을 합칩니다.
class AppDependencies {
  const AppDependencies({required this.tcpService});
  final TcpService tcpService;

  Future<void> dispose() async {
    tcpService.dispose();
  }
}

// 기존 createAppDependencies의 인자와 반환 객체에 이 기능을 합칩니다.
AppDependencies createAppDependencies({TcpService? tcpService}) {
  final sharedService = tcpService ?? TcpService();
  // 실제 소비자(ViewModel/Service)가 있으면 생성자에 tcpService: sharedService를 주입합니다.
  // AppDependencies에도 같은 객체를 전달합니다. 공유 객체를 다시 생성하지 않습니다.
  return AppDependencies(tcpService: sharedService);
}
```

main.dart의 MobileApp(dependencies: createAppDependencies()) 진입은 유지합니다. 업무 소비자가 있으면 위 createAppDependencies의 sharedService를 실제 ViewModel/Service 생성자에 주입하고 같은 객체를 AppDependencies에도 전달합니다. 소비자는 `TcpService`만 받고 DI 전체를 참조하지 않습니다. ViewModel을 추가했다면 AppDependencies에 함께 보관하고 app.dart는 전달받은 ViewModel을 Scene에 연결합니다. Widget build에서 공유 Service/ViewModel을 매번 새로 만들지 않습니다. 아래 사용 예제의 `tcpService`는 소비자 생성자로 받은 객체입니다.

별도 initialize는 없습니다. 실제 연결이 필요할 때 connect(host, port)를 await한 뒤 bytes를 구독합니다. 실패하면 오류를 처리하고 disconnect 후 명시적으로 재시도합니다.

세션 중단과 최종 해제를 구분합니다. 화면이 보관한 stream 구독은 화면 종료 때 취소하고, 공유 tcpService의 dispose는 DI 소유자가 앱 해제 때 호출합니다. app.dart의 비동기 해제 연결을 빠뜨리지 않습니다. 외부에서 객체를 주입했다면 해제 소유권을 정하고 중복 해제하지 않습니다.

## 사용

DI의 tcpService를 주입합니다. host·port·commandBytes는 실제 프로토콜 설정/입력입니다.

```dart
// 파일: lib/scenes/<기능>/<기능>_view_model.dart (실제 소비자 파일명으로 바꿉니다.)
// 생성자로 주입받은 객체를 사용해 사용자 동작/업무 메서드 안에 추가합니다.
// 아래 코드는 메서드 본문 일부이며 파일 최상위에 붙이지 않습니다.
await tcpService.connect(host, port); // 기본 TLS·서버 인증서 검증
final subscription = tcpService.bytes.listen(onBytes,
  onError: onConnectionError, onDone: onConnectionClosed);
try {
  await tcpService.send(commandBytes);
} finally {
  tcpService.disconnect();
  await subscription.cancel();
}
```

바이트 stream은 한 번만 listen합니다. 한 번 수신한 chunk가 한 메시지라는 보장은 없으므로 길이/구분자 기반 framing과 최대 메시지 크기를 호출부에서 처리합니다. 이 예제의 finally는 해당 통신 세션이 끝났을 때 수행합니다. 실제 화면에서는 세션이 유지되는 동안 구독을 보관합니다.

장치가 TLS를 지원하지 않는 경우만 connect(host, port, secure: false)를 명시합니다. 평문에는 비밀/인증값을 보내지 않습니다. 연결 제한 기본 15초, send는 최대 1 MiB와 flush 15초 제한입니다. send 완료는 수신측 처리 완료가 아닙니다. 실패/끊김 후 disconnect하고 다시 connect합니다. 연결 대기 중 disconnect/dispose하면 늦게 도착한 소켓도 폐기합니다. dispose 뒤에는 재사용하지 않습니다.

## 플랫폼 설정

- Android: 앱의 **main** AndroidManifest.xml에 INTERNET을 직접 추가합니다. 정확한 선언은 [기능 수동 추가 안내](../04-features.md)를 따릅니다. 현재 target 36 기준 일반 인터넷 권한은 런타임 요청이 없습니다. Android 17/API 37 이상을 target으로 올릴 때 LAN 접근에는 ACCESS_LOCAL_NETWORK 선언·런타임 요청 구현을 재검토해야 합니다. 현 compile 36에는 이 신규 권한 처리를 넣지 않습니다.
- iOS 15+: LAN 접속용 NSLocalNetworkUsageDescription을 Info.plist에 직접 추가합니다. 실제 사용자 목적에 맞게 수정합니다. 공개 인터넷만 사용하면 이 키를 제거할 수 있습니다. 최초 LAN 동작 때 OS가 동의를 요청하며 거부 뒤에는 설정 → 개인정보 보호 및 보안 → 로컬 네트워크에서 변경합니다. 연결 실패만으로 거부·방화벽·서버 종료를 확정할 수 없습니다.
- Bonjour 탐색·멀티캐스트·백그라운드 모드는 포함하지 않습니다. iOS Simulator와 실기기, Wi-Fi/셀룰러·VPN·방화벽 조건을 별도로 확인합니다. 휴대폰의 localhost는 휴대폰 자신이며 개발 PC 주소가 아닙니다.

공식 근거: [Android LAN 정책](https://developer.android.com/privacy-and-security/local-network-permission), [Apple 로컬 네트워크](https://developer.apple.com/documentation/technotes/tn3179-understanding-local-network-privacy).

확인: TLS 인증서 실패·서버 종료·분할/합쳐진 수신·전송 오류·연결 중 취소·재접속을 검사합니다.

공식 근거: [Dart Socket](https://api.dart.dev/dart-io/Socket-class.html), [SecureSocket](https://api.dart.dev/dart-io/SecureSocket-class.html).

## 사용 버전 기록·변경

구성품 구현 버전은 **0.1.0**입니다. 이것은 Composer 구성품의 선언 버전이며 실기기 검증 완료나 패키지 배포 버전을 뜻하지 않습니다. 별도 pub 패키지는 없고 Dart **3.9.2** 기본 기능을 사용합니다.

1. 앱 루트 versions.json의 기존 SDK/도구 값은 유지하고 features 안에 이 기능의 다음 항목을 합칩니다. 아래 JSON은 추가할 부분이며 파일 전체를 교체하지 않습니다. 실제 적용한 구현/패키지 버전을 기록합니다.

```jsonc
// 파일: versions.json
// 기존 최상위 객체의 features에 이 기능 항목을 합칩니다. 기존 SDK/기능 기록은 보존합니다.
// JSON은 주석을 지원하지 않으므로 이 설명 주석은 실제 파일에 넣지 않습니다.
{
  "features": {
    "tcp": {
      "version": "0.1.0",
      "dependencies": {}
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

기능 원본을 관리할 때는 components/03-features/tcp/compose.json의 version·dependencies, 이 문서·소스/검사·update.md를 함께 갱신합니다. 구현/사용 절차 추가는 minor, 호환 수정은 patch, 기존 호출/설정이 깨지면 major를 올립니다. 패키지만 바뀌어도 호환성 확인 결과를 남깁니다. Composer 밖 앱은 앱 내부 기록만 바꾸고 원본을 자동 수정하지 않습니다.
