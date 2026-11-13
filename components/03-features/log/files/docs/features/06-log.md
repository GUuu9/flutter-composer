<!-- version: v0.2.0 -->
# 06. 로그

dart:developer.log 기반 개발 진단 이벤트입니다. 추가 패키지·OS 권한·파일/네트워크 수집은 없습니다. 앱의 업무 기록·감사 로그 영속 저장을 대신하지 않습니다.

## 설치·확인

[기능 설치·수명 안내](../04-features.md)에 따라 앱 루트에서 의존성을 설치하고 확인합니다. Android 최소 API 28·target/compile 36, iOS 최소 15.0이며 OS 상한은 고정하지 않습니다. 이 기능의 플랫폼 빌드·실기기 검증은 아직 수행하지 않았습니다(2026-11-12).

## DI 등록·초기화

앱의 lib/core/di.dart에 아래 항목을 합칩니다. 이 예제는 log 하나를 연결한 형태이며 기존 AppDependencies·생성 함수 전체를 덮어쓰지 않습니다. 여러 기능의 해제 순서/오류 수집과 app.dart 연결은 [기능 수동 추가 안내](../04-features.md)를 따릅니다.

```dart
// 파일: lib/core/di.dart
// 기존 파일에 병합합니다. 같은 클래스/생성 함수를 중복 선언하지 않습니다.
// 기존 import 아래에 추가합니다.
import '../services/log/log_service.dart';

// 기존 AppDependencies의 생성자·필드·정리 메서드에 아래 항목을 합칩니다.
class AppDependencies {
  const AppDependencies({required this.logService});
  final LogService logService;
}

// 기존 createAppDependencies의 인자와 반환 객체에 이 기능을 합칩니다.
AppDependencies createAppDependencies({LogService? logService}) {
  final sharedService = logService ?? LogService();
  // 실제 소비자(ViewModel/Service)가 있으면 생성자에 logService: sharedService를 주입합니다.
  // AppDependencies에도 같은 객체를 전달합니다. 공유 객체를 다시 생성하지 않습니다.
  return AppDependencies(logService: sharedService);
}
```

main.dart의 MobileApp(dependencies: createAppDependencies()) 진입은 유지합니다. 업무 소비자가 있으면 위 createAppDependencies의 sharedService를 실제 ViewModel/Service 생성자에 주입하고 같은 객체를 AppDependencies에도 전달합니다. 소비자는 `LogService`만 받고 DI 전체를 참조하지 않습니다. ViewModel을 추가했다면 AppDependencies에 함께 보관하고 app.dart는 전달받은 ViewModel을 Scene에 연결합니다. Widget build에서 공유 Service/ViewModel을 매번 새로 만들지 않습니다. 아래 사용 예제의 `logService`는 소비자 생성자로 받은 객체입니다.

initialize/dispose가 없습니다. 객체 생성 후 필요한 시점에 event를 호출합니다. 자원 없는 서비스에 빈 수명 메서드를 추가하지 않습니다.

## 사용

DI의 logService를 실제 Service에 주입합니다.

```dart
// 파일: lib/scenes/<기능>/<기능>_view_model.dart (실제 소비자 파일명으로 바꿉니다.)
// 생성자로 주입받은 객체를 사용해 사용자 동작/업무 메서드 안에 추가합니다.
// 아래 코드는 메서드 본문 일부이며 파일 최상위에 붙이지 않습니다.
logService.event('device.connected');
logService.event('connection.failed', level: 1000);
```

이벤트 코드는 소문자 영문으로 시작하고 영문 소문자/숫자/밑줄/마침표만 최대 80자입니다. level은 0–2000(기본 800)입니다. 허용한 정적 코드만 사용하고 토큰·장치 ID·주소·사용자 입력·payload를 코드에 끼워 넣지 않습니다. 정규식은 비밀 제거기가 아닙니다. 예외 원문/stack을 자동 수집하지 않습니다.

디버그로 실행한 앱의 DevTools Logging에서 name=app 이벤트를 확인합니다. 개발 환경/빌드 모드에 따라 보이는 위치가 다르므로 배포 앱의 영구 보존을 보장하지 않습니다. 파일 로깅이 필요하면 앱 전용 저장 위치·보관 기간/용량·삭제·민감 정보 제거·반출 정책을 별도로 구현합니다. 현재 로그를 위해 Android 저장소나 iOS 사진 권한을 요청하지 않습니다.

확인: 정적 이벤트/level 필터·잘못된 코드 거절·비밀/payload가 기록되지 않는지 검사합니다.

공식 근거: [Dart developer.log](https://api.dart.dev/dart-developer/log.html), [Flutter Logging](https://docs.flutter.dev/tools/devtools/logging).

## 사용 버전 기록·변경

구성품 구현 버전은 **0.1.0**입니다. 이것은 Composer 구성품의 선언 버전이며 실기기 검증 완료나 패키지 배포 버전을 뜻하지 않습니다. 별도 pub 패키지는 없고 Dart **3.9.2** 기본 기능을 사용합니다.

1. 앱 루트 versions.json의 기존 SDK/도구 값은 유지하고 features 안에 이 기능의 다음 항목을 합칩니다. 아래 JSON은 추가할 부분이며 파일 전체를 교체하지 않습니다. 실제 적용한 구현/패키지 버전을 기록합니다.

```jsonc
// 파일: versions.json
// 기존 최상위 객체의 features에 이 기능 항목을 합칩니다. 기존 SDK/기능 기록은 보존합니다.
// JSON은 주석을 지원하지 않으므로 이 설명 주석은 실제 파일에 넣지 않습니다.
{
  "features": {
    "log": {
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

기능 원본을 관리할 때는 components/03-features/log/compose.json의 version·dependencies, 이 문서·소스/검사·update.md를 함께 갱신합니다. 구현/사용 절차 추가는 minor, 호환 수정은 patch, 기존 호출/설정이 깨지면 major를 올립니다. 패키지만 바뀌어도 호환성 확인 결과를 남깁니다. Composer 밖 앱은 앱 내부 기록만 바꾸고 원본을 자동 수정하지 않습니다.
