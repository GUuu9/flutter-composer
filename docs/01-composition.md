<!-- version: v2.0.1 -->
# 조립 구조·검사·버전 관리

입력/검증/계획/공식 생성/overlay/플랫폼 설정/상태 기록은 scripts/compose.dart가 담당합니다. 구성품은 compose.json·files/이며 공식 SDK의 전체 플랫폼 파일을 Composer에서 재구현하지 않습니다. 단독 플랫폼의 사용자 문서는 해당 target에만 둡니다.

## 조립과 앱 구조

공통 문서 → Flutter base → OS target 순서로 빈 앱을 조립합니다. android-ios는 공통 Dart 앱 하나를 사용합니다. 구성 선택은 OS뿐이며 이름·조직 식별자를 입력합니다. 기능 선택/코드 복사/자동 연결은 생성기에서 제공하지 않습니다. docs/02-manual-features.md와 03-features의 Markdown만 새 앱의 docs/04-features.md·docs/features/에 포함합니다.

생성 앱은 main.dart → core/app.dart의 MobileApp → 빈 MaterialApp으로 시작합니다. main.dart는 core/di.dart의 createAppDependencies() 결과를 MobileApp에 전달합니다. app.dart는 화면/앱 수명, di.dart는 생성자로 받은 객체의 보관·생성/주입·정리를 담당합니다. DI는 Widget을 생성하지 않습니다. 기본 DI에는 기능이 없습니다. 앱 개발자가 선택 기능 문서의 AppDependencies 예제를 검토해 실제 객체 생성·주입·해제를 직접 연결합니다. 연결/권한 요청은 사용자 동작 때 호출하며 화면에 필요한 객체만 생성자로 주입합니다. 메인 DI가 필요한 객체를 직접 생성·주입하며, 기능 없는 초기 앱에는 더미 Service·ViewModel·빈 수명 메서드를 넣지 않습니다. Model은 소유 기능 옆에 두고 core/composition·최상위 models는 만들지 않습니다.

프로젝트 이름과 Dart package 이름은 같습니다. Android/iOS 식별자는 조직과 이름에서 고정 SDK의 규칙으로 계산해 각각 검증하며 최종 확인을 받습니다. 생성기는 설치·분석·테스트·빌드·Git 초기화를 수행하지 않고 generated-unverified/active:false로 기록합니다. 내부 SDK 생성 파일의 예상 패턴이 바뀌면 중단합니다.

## 소유와 실패

사용자 목적지는 생성 전에 거부합니다. Composer는 새 앱에서 README·lib/main.dart·pubspec.yaml·analysis_options.yaml 등 선언한 파일만 교체하며 기본 생성 테스트는 명시된 경로만 제거합니다. Android settings/Wrapper/app 설정과 iOS 프로젝트/프레임워크 최소 버전의 변경 경로는 target의 nativeOverrides에 기록합니다. 그 밖의 공식 플랫폼 파일은 SDK 결과를 유지합니다.

구성품 링크·위험한 경로·중복 파일·잘못된 플랫폼 선언은 중단합니다. 동일한 빈 .gitkeep만 중복 허용합니다. 실패/취소 후 기존 생성 파일을 지우지 않고 state에 단계와 미검증을 남깁니다. 원래 목적지에 재실행하거나 state를 편집해 성공 처리하지 않습니다. 사후 기능 추가·자동 복구·기존 앱 이행은 미구현입니다.

버전은 versions.json·.fvmrc·pubspec·native 설정·사용 문서를 함께 변경합니다. Flutter 고정 SDK가 다르거나 공식 생성 파일 패턴이 예상과 다르면 진행하지 않습니다. 임의 SDK 업데이트·잠금 파일 삭제·개인 경로 복사는 하지 않습니다. 모든 네이티브 설정 변경은 실제 빌드/기기/지원 범위를 별도로 확인합니다.

## 사용자가 요청할 수 있는 검사

아래는 수행 안내이며 이번 작업에서 실행했다는 뜻이 아닙니다. 기존 project 앱을 검사에 사용하지 않습니다.

| 위치 | 명령/검사 | 선행 조건·목적 |
| :--- | :--- | :--- |
| Composer 루트 | fvm dart run test/compose_check.dart | 고정 SDK. 이름·식별자·경로·세 OS 구성·수동 문서와 기능 코드 미포함 확인 |
| 별도 임시 Composer | fvm dart run scripts/compose.dart | FVM/SDK. 세 플랫폼을 각기 새 이름으로 생성하고 플랫폼/식별자/버전/상태 확인 |
| 새 앱 루트 | fvm flutter pub get | 네트워크·SDK. 의존성/실제 lock 생성 |
| 새 앱 루트 | fvm flutter analyze / fvm flutter test | 설치 완료. Dart 타입/빈 앱 확인 |
| 새 Android 앱 | fvm flutter build apk --debug | SDK 36/Build-Tools 35/NDK·JDK 17. 네이티브 빌드 |
| 새 iOS 앱 | fvm flutter build ios --no-codesign | macOS/Xcode. 미서명 빌드이며 배포 검증 아님 |

설치·분석·검사·빌드·실제 기기·서명/배포 결과를 구분합니다. 현재 검사 결과는 update.md에 기록하고 미실행 명령을 통과로 표시하지 않습니다.

## 기능 선언 작성

03-features/<id>/compose.json에 아래 항목을 선언하고 files/에는 앱 루트 기준 파일을 둡니다. 작성 뒤 수동 추가 목록·README·기능 문서·이력·자체 검사를 함께 수정합니다. 생성기의 기능 선택 목록은 만들지 않습니다. 제품 화면·page·제품 데이터/설정은 재사용 기능에 넣지 않습니다.

- dependencies: 정확한 패키지 버전. SDK 기본 기능이면 빈 객체이며 pubspec/lock 변경 근거를 확인합니다.
- integration: class·field·import(lib 아래 상대 경로)·dispose(bool). 수동 DI 연결 참고 정보이며 생성기가 해석하는 코드 등록 선언이 아닙니다. 앱에서 인자 없는 실제 객체를 생성하고 필요한 endpoint/인증값은 사용 시 전달합니다. dispose는 실제 자원이 있는 객체에만 선언합니다. DI 전체를 서비스에 전달하지 않습니다.
- androidPermissions: name·선택 maxSdkVersion/usesPermissionFlags. iosDescriptions: 허용된 Info.plist 용도 키와 실제 설명. 선택 권한을 안내 문서의 코드 블록으로 제공하며 main Manifest/plist는 앱 개발자가 검토 후 합칩니다. 사용하지 않는 권한/백그라운드 모드를 미리 넣지 않습니다.
- files/docs/features/NN-id.md: 패키지 버전·선행 설치/확인·OS/API별 선언/런타임 동의/거부/철회·호출/정리·제한·실기기 검사·공식 근거를 기록합니다. generated 앱 밖의 문서에 의존하지 않습니다.
- files/test: 잘못된 입력·해제·실패 경로의 독립 검사. 하드웨어/브로커 검사는 수동 확인 항목과 구분합니다.

기능 메타데이터는 수동 연결 참고용이며 생성기가 기능 의존성/등록/버전을 합치지 않습니다. 기능 Markdown만 경로·링크·충돌을 확인해 포함합니다. 수동 복사는 기능 문서에 따라 소스·검사·앱 설정/버전을 대조하고 필요한 부분만 병합합니다. 기존 또는 새 앱의 실제 DI·패키지·권한에 자동 패치를 적용하지 않습니다.

BLE는 앱 전체 SDK 상태를 DI 한 곳에서 소유합니다. 네트워크는 foreground 세션이며 권한 거부·타임아웃·연결 종료를 호출부로 전달하고 자동 재연결하지 않습니다. 문서의 main DI 역순 해제 예제는 오류가 발생해도 나머지 정리를 시도하고 오류/stack을 보존합니다. 종료 콜백 완료는 보장하지 않습니다.

모든 새 앱의 문서는 플랫폼 준비 → 04-features(수동 추가가 필요할 때) → 05-structure → 06-build-and-release 순서입니다. 기존 project 앱의 문서는 자동 이동하지 않습니다.

## 기능 사용·버전 문서 규칙

기능별 docs/features/NN-id.md에는 해당 기능의 import·AppDependencies 생성자/필드·createAppDependencies 주입·실제 시작 메서드(또는 초기화 불필요)·호출부 전달·세션 중단·최종 해제를 직접 기록합니다. 공통 안내로 연결만 하고 구체 등록 예제를 생략하지 않습니다. 프로젝트 main → app 진입을 유지하며 DI 코드와 앱 Widget 예제를 구분합니다.

compose.json의 version은 구성품 구현 SemVer이며 dependencies의 pub 패키지 버전·문서 첫 줄 버전과 구분합니다. 최초 구현 선언은 0.1.0이며 검증 완료를 뜻하지 않습니다. 호환 수정은 patch, 기능/사용 절차 추가는 minor, 기존 호출/설정이 깨지면 major를 올리고 소스·검사·기능 문서·update.md를 맞춥니다. 앱 사용자는 기존 versions.json의 features에 실제 적용한 구현/패키지 버전을 직접 합치고 pubspec.yaml·실제 lock·검사 결과·복귀 파일을 함께 보관합니다. 기존 SDK/기능 기록을 덮어쓰거나 Composer가 자동 연결/설치한 것으로 기록하지 않습니다.

코드/설정 작성 안내는 언어를 지정한 코드 블록으로 쓰고, 블록 첫 부분에 해당 언어의 주석으로 파일 경로·추가 위치·기존 내용 병합/교체 여부를 표시합니다. 호출 예제는 실제 소비자 파일과 메서드 본문 일부임을 구분하고 가변 파일명은 자리표시자라고 명시합니다. 터미널 명령에는 실행 위치를 표시합니다. JSON은 jsonc 설명 예제로 파일/위치를 주석 안내하되 실제 JSON 저장 시 주석을 제외하도록 명시합니다.

versions.json의 초기 값은 사용자 동작 확인 조합입니다. 앱 README에서 기준과 현재 PC의 실제 선택 버전을 구분하고 정상 동작하면 유지합니다. 오류 발생 시 경로/설치/라이선스/권한 문제부터 구분한 뒤 필요한 도구/SDK/의존성만 변경하는 절차를 제공합니다. 기준 버전·전역 기본값을 자동 갱신하거나 후보 버전을 검증 완료로 표시하지 않습니다. 실제 설정/선택 파일·lock·결과·복귀를 함께 관리하고 사용자 확인과 신규 생성 앱의 검증을 구분합니다.

## 경로·문서·실패 진단

구성품과 원본 루트를 실제 경로로 해석한 뒤 URI 형식으로 비교합니다. Windows는 경로 구분자·대소문자·UNC를 함께 처리하고, 비슷한 접두사/다른 드라이브/상위 경로는 하위 경로로 허용하지 않습니다. 앱 출력 파일명도 URI의 상대 경로 구간으로 계산합니다.

기능 files/docs/04-features.md는 원본 저장소 탐색용 연결 문서입니다. 앱에는 중앙 수동 안내를 포함하며 기능 문서는 docs/features/만 복사하므로 원본용 연결 파일로 앱 안내를 덮어쓰지 않습니다. 원본/반출 문서 링크를 각각 검사합니다.

실패 시 터미널과 생성된 .composer/state.json의 failure에 오류 종류·관련 경로·OS 오류 코드/JSON 위치를 남깁니다. 파일/JSON 본문·프로세스 인자/환경 변수·알 수 없는 오류의 원문은 기록하지 않습니다. StateError는 생성기에서 만든 안전한 안내만 사용합니다. 앱 생성 전 실패는 출력/state가 없음을 안내하며 진단 저장까지 실패하면 별도로 알립니다.
