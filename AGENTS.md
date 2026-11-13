<!-- version: v2.0.1 -->
# Flutter Composer 작업 지침

Android·iOS·android-ios 빈 앱 Composer를 재구성합니다. Dart/FVM 생성기와 공식 Flutter 플랫폼 생성 기반을 구현합니다. 사용자 확인 버전은 versions.json에 고정하고 실제 생성·실행 검증은 별도로 구분합니다. README와 [조립 구조](docs/01-composition.md)를 먼저 읽습니다.

## 범위와 보호

- 사용자 변경·stage·삭제를 먼저 확인하고 삭제된 구형 생성기·기능을 자동 복구하지 않습니다.
- project/의 기존 앱·독립 Git·데이터·설정·state는 수정·설치·시험·이행 대상으로 사용하지 않습니다.
- Composer와 생성 앱은 별도 Git 저장소이며 commit·remote·push는 요청받은 범위에서만 수행합니다.
- 기본 제공 범위는 모바일 세 구성·빈 앱과 수동 기능 추가 문서입니다. api/ble/tcp/udp/mqtt/log 소스·검사는 사용자가 필요한 경우 직접 복사합니다. 샘플 카운터·업무 화면·가짜 데이터·더미 Service·자동 저장·빈 기능 선택 메뉴를 넣지 않습니다. 사후 추가·역추출은 별도 요청 범위입니다.

## 설계와 구조

합의한 Dart/FVM·모바일 세 구성·기존 검증 버전을 기준으로 작업합니다. 새로운 실행 계약은 확인 후 적용하며 이미 합의한 범위를 반복 승인받지 않습니다.

생성 구성품은 common → base → target으로 계획하며 각 선언과 files/의 역할을 구분합니다. 선택 플랫폼만 생성하고 Dart 공통 코드를 세 target에 복제하지 않습니다. 플랫폼 뼈대는 공식 Flutter 도구 재사용을 우선합니다.

lib는 core(app.dart·di.dart)·scenes·services·apis·components·utils·config·resource로 책임을 구분합니다. 불필요한 Usecase·Repository·DI/상태 관리 패키지는 추가하지 않습니다. 표준 빈 폴더는 .gitkeep으로 보존하고 미선택 영역은 만들지 않습니다. core/composition·최상위 models는 만들지 않습니다.

Dart 파일/폴더는 snake_case, 타입은 PascalCase, 함수/변수는 lowerCamelCase입니다. Widget은 화면·입력·UI 수명, ViewModel은 필요한 화면 상태, Service는 기능·payload 검증, Api는 전송을 담당합니다. Model은 소유 기능 옆에 둡니다. 순수 계산은 함수로 작성합니다.

앱 개발자가 메인 DI에 실제 필요한 객체를 직접 생성·주입하고 전체 수명을 소유하도록 연결합니다. 생성기의 구성 선택은 OS뿐이며 프로젝트 이름·조직 식별자 입력은 유지합니다. Composer는 기능 코드/검사·DI·패키지·권한을 추가하지 않고 수동 안내와 기능 Markdown만 포함합니다. 자동 연결·권한 요청·로깅을 시작하지 않습니다. BLE SDK는 앱 전체 상태를 공유하므로 DI의 단일 인스턴스로 관리합니다. 업무 객체가 DI 전체를 참조하지 않습니다. 초기화 실패는 후속 화면 표시를 막고 확보 자원을 역순 정리하며 원래 오류와 정리 오류를 보존합니다. 빈 수명 메서드를 강제하지 않습니다.

Widget 해제·공유 Service 해제·백그라운드·복귀·프로세스 종료를 구별합니다. 모바일 OS의 종료 콜백 실행이나 비동기 저장 완료를 보장하지 않습니다. 화면 해제 후 결과 반영·중복 요청·구독 누수를 방지합니다.

## 설정·문서·검사

권한 선언과 런타임 요청을 구분합니다. 기능의 패키지·권한·DI 메타데이터는 안내용이며 실제 앱 설정과의 충돌 확인/병합은 사용자가 문서에 따라 수행합니다. 생성 시 공통/base/target 파일과 포함 문서의 경로·충돌을 검사합니다. 수동 기능 복사 전 실제 앱의 파일·의존성·설정 충돌은 사용자가 확인합니다. 공개 설정만 .env.example로 공유하며 앱 asset/빌드 정의에 비밀을 넣지 않습니다. 서명키·인증서·계정은 자동 생성·수집하지 않습니다.

기존 목적지는 거부하고 생성 실패/취소 시 생성된 소스·lock·진단을 보존합니다. 외부 설치 부작용·캐시/산출물까지 복원했다고 설명하지 않습니다. 자동 설치·검사·활성화는 현재 제공 범위가 아닙니다.

기본 검사는 짧은 구문·선언·diff 검사입니다. SDK 설치·pub 다운로드·전체 analyze/test·Gradle/Xcode 빌드·GUI/기기·전체 조합은 자동 실행하지 않습니다. 요청받은 검사만 별도 임시 새 앱에서 수행하고 실제 결과와 미검증을 구분합니다. Flutter/Dart를 자동 업그레이드하지 않습니다.

문서는 한국어로 간결하게 작성하고 변경 시 README·AGENTS·실제 명령·앱 안내·이력을 맞춥니다. update.md를 작성할 때 최신순·커밋당 한 항목으로 핵심 변경 1~3줄과 실제 검사 1줄만 기록합니다. 커밋 제목은 type(scope): 한국어 요약을 따릅니다.

## 기능 구성품 변경

components/03-features/<id>/compose.json의 dependencies(정확한 버전)·integration(class/field/import/dispose, 수동 연결 참고용)·androidPermissions·iosDescriptions와 files/를 함께 관리합니다. files에는 재사용 가능한 소스·자체 검사·docs/features/NN-id.md만 두고 scenes/page·제품 설정·비밀·산출물을 복사하지 않습니다. API는 전송 경계, Service는 공유 기능이며 소유 Model을 옆에 둡니다.

기능 추가/변경 시 docs/02-manual-features.md의 목록·수동 복사·설치·DI/수명·버전 절차와 구성품 소스/검사/문서를 함께 맞춥니다. 생성기에는 기능 메뉴·통신/Service 선택·패키지/권한 병합·DI 예제 생성·기능 상태 등록을 다시 넣지 않습니다. 생성기는 03-features의 Markdown만 포함하므로 기능 소스/검사가 기본 앱에 들어가지 않는지 test/compose_check.dart로 확인할 수 있게 유지합니다. 사용자 코드·DI·pubspec·네이티브 설정을 통째로 덮어쓰도록 안내하지 않습니다. 외부 패키지의 고정 소스/SDK 조건과 권한 거부 처리를 함께 기록하며 미검증을 보장으로 쓰지 않습니다.

앱 진입 구조는 main.dart → core/app.dart의 MobileApp이며 main에서 core/di.dart의 createAppDependencies() 결과를 전달합니다. AppDependencies는 생성자로 의존성을 받고 createAppDependencies는 실제 객체를 구성·주입합니다. di.dart는 Flutter Widget/MaterialApp을 import하거나 앱 진입 Widget을 만들지 않습니다. app.dart는 전달받은 객체를 화면에 연결하고 실제 해제 대상이 있을 때 최종 정리를 호출합니다. 빈 앱에는 빈 dispose를 만들지 않습니다.

## 기능 사용·버전 문서 규칙

기능별 docs/features/NN-id.md에는 해당 기능의 import·AppDependencies 생성자/필드·createAppDependencies 주입·실제 시작 메서드(또는 초기화 불필요)·호출부 전달·세션 중단·최종 해제를 직접 기록합니다. 공통 안내로 연결만 하고 구체 등록 예제를 생략하지 않습니다. 프로젝트 main → app 진입을 유지하며 DI 코드와 앱 Widget 예제를 구분합니다.

compose.json의 version은 구성품 구현 SemVer이며 dependencies의 pub 패키지 버전·문서 첫 줄 버전과 구분합니다. 최초 구현 선언은 0.1.0이며 검증 완료를 뜻하지 않습니다. 호환 수정은 patch, 기능/사용 절차 추가는 minor, 기존 호출/설정이 깨지면 major를 올리고 소스·검사·기능 문서·update.md를 맞춥니다. 앱 사용자는 기존 versions.json의 features에 실제 적용한 구현/패키지 버전을 직접 합치고 pubspec.yaml·실제 lock·검사 결과·복귀 파일을 함께 보관합니다. 기존 SDK/기능 기록을 덮어쓰거나 Composer가 자동 연결/설치한 것으로 기록하지 않습니다.

코드/설정 작성 안내는 언어를 지정한 코드 블록으로 쓰고, 블록 첫 부분에 해당 언어의 주석으로 파일 경로·추가 위치·기존 내용 병합/교체 여부를 표시합니다. 호출 예제는 실제 소비자 파일과 메서드 본문 일부임을 구분하고 가변 파일명은 자리표시자라고 명시합니다. 터미널 명령에는 실행 위치를 표시합니다. JSON은 jsonc 설명 예제로 파일/위치를 주석 안내하되 실제 JSON 저장 시 주석을 제외하도록 명시합니다.

versions.json의 초기 값은 사용자 동작 확인 조합입니다. 앱 README에서 기준과 현재 PC의 실제 선택 버전을 구분하고 정상 동작하면 유지합니다. 오류 발생 시 경로/설치/라이선스/권한 문제부터 구분한 뒤 필요한 도구/SDK/의존성만 변경하는 절차를 제공합니다. 기준 버전·전역 기본값을 자동 갱신하거나 후보 버전을 검증 완료로 표시하지 않습니다. 실제 설정/선택 파일·lock·결과·복귀를 함께 관리하고 사용자 확인과 신규 생성 앱의 검증을 구분합니다.

경로 검사는 실제 경로를 동일한 URI 형식으로 정규화하고 Windows 구분자·대소문자·UNC 및 경로 경계를 확인합니다. 기능별 원본 문서와 반출 문서의 링크를 모두 검사하고 원본용 files/docs/04-features.md 연결 파일로 앱 공통 안내를 덮어쓰지 않습니다. 실패 진단은 오류 종류·경로·코드/위치만 보존하고 파일/JSON 본문·실행 인자·환경 변수를 출력하지 않습니다.
