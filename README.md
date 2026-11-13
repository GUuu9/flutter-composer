<!-- version: v2.1.2 -->
# Flutter Composer v0.0.0

현재 구성을 v0.0.0의 새 Git 기준으로 시작합니다. 문서 버전과 구성품 구현 버전은 Composer 기준 버전과 별도로 관리합니다.

Android·iOS 모바일용 빈 앱을 생성하고 기능은 사용자가 수동 추가하는 Dart/FVM Composer입니다. 사용자가 동작을 확인한 버전 조합을 versions.json과 실제 생성 설정에 고정했습니다. 2026-11-12 사용자가 Android·iOS 앱 실행을 확인했습니다. 이 결과를 모든 생성 구성·빌드·실기기 검증 완료로 확대하지 않습니다.

| 구성 | 생성 범위 |
| :--- | :--- |
| android | android/와 공통 Dart 앱 |
| ios | ios/와 공통 Dart 앱 |
| android-ios | 두 플랫폼과 공통 Dart 앱 하나 |

업무 화면·카운터·가짜 데이터·더미 Service·자동 저장·빈 기능 메뉴는 넣지 않습니다. Web/데스크톱·feature add·역추출·비대화형 CLI는 제공하지 않습니다.

## 생성

FVM과 고정 SDK를 준비한 Composer 루트에서 실행합니다. Composer에는 Node/npm이나 외부 Dart 패키지가 필요하지 않습니다. .fvmrc는 Flutter 3.35.7을 지정합니다. SDK가 없으면 사용자가 FVM 설치 안내에 따라 먼저 준비하고 자동 업그레이드하지 않습니다.

```bash
fvm dart run scripts/compose.dart
```

플랫폼 → 조직 식별자 → 프로젝트/package 이름 → 식별자·버전·출력 요약 확인 순서입니다. 이름은 snake_case이며 경로·예약 이름을 거부합니다. Android applicationId와 iOS bundle identifier는 Flutter 3.35.7의 생성 규칙으로 각각 계산·검증하고 최종 요약에서 확인합니다. 조직을 임의로 com.example로 확정하지 않습니다.

출력은 project/<name>입니다. 기존 목적지와 링크 경로는 거부합니다. 공식 flutter create --empty --no-pub로 선택 플랫폼과 선언된 파일·버전 설정을 생성합니다. 설치·분석·테스트·빌드·Git 초기화는 별도 작업입니다.

성공 상태 generated-unverified는 소스 생성만 뜻하며 active는 false입니다. 실패·취소 시 생성된 소스와 .composer/state.json을 보존합니다. 터미널과 state의 failure에 기록된 오류 종류·관련 파일/실행 경로·OS 오류 코드 또는 JSON 위치를 확인하고 원본 출력을 백업한 뒤 새 이름으로 재시도합니다. 출력 생성 전 중단이면 state 파일은 없습니다. 파일 본문·프로세스 인자·환경 변수는 진단에 기록하지 않습니다. 기존 출력에 이어쓰기·자동 복구·state 수동 활성화는 제공하지 않습니다.

## 생성 앱에서 시작

앱 내부 README → SDK/FVM → 선택 플랫폼 → 기능 수동 추가(필요할 때) → 구조 → 빌드/배포 문서를 순서대로 읽습니다. 모든 명령은 사용자 준비 후 앱 루트에서 수행합니다.

```bash
cd project/my_app
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm flutter devices
fvm flutter run -d 기기ID
```

Ctrl+C로 종료합니다. 빈 화면이 정상입니다. 앱 Git은 앱 폴더에서 별도로 초기화하고 실제 생성한 pubspec.lock·.fvmrc·versions.json·소스/설정·상태를 보관합니다. Composer의 Git에는 project 앱을 추가하지 않습니다.

## 기능 수동 추가

생성 시 기능을 선택하지 않습니다. 빈 앱을 만든 뒤 필요한 구성품의 lib 소스·test만 앱의 같은 경로로 직접 복사합니다. [수동 추가 안내](docs/02-manual-features.md)와 기능별 설명서를 따라 패키지·권한·DI·초기화/사용·버전을 연결합니다. 자동 feature add는 제공하지 않습니다.

| 구성품 | 기능 | 추가 의존성 |
| :--- | :--- | :--- |
| api | HTTPS 요청·크기/시간 제한 | Dart 기본 기능 |
| ble | BLE 검색·한 장치 연결·GATT 읽기/쓰기 | universal_ble 1.0.0 |
| tcp | TCP/TLS 클라이언트 | Dart 기본 기능 |
| udp | UDP unicast 송수신 | Dart 기본 기능 |
| mqtt | MQTT 3.1.1 발행·구독 | mqtt_client 10.11.11 |
| log | 민감 payload 없는 개발 이벤트 | Dart 기본 기능 |

기능별 설명서는 새 앱의 docs/features/에도 포함됩니다. 설명서만 제공되며 기능 코드·패키지·권한·DI는 추가하지 않습니다. 실제 연결한 기능만 versions.json에 기록하고 검증합니다. BLE는 Classic/SPP를 포함하지 않습니다. 기존 Android/iOS 실행 확인은 빈 앱에 대한 사용자 보고이며 통신 기능의 성공을 뜻하지 않습니다.

## 버전 기준

| 영역 | 사용자 동작 확인 조합 |
| :--- | :--- |
| Flutter / Dart | 3.35.7 / 3.9.2 |
| AGP / Kotlin / Gradle | 8.11.1 / 2.2.20 / 8.14 |
| JDK / Java 소스 타깃 | 17 / 11 |
| Android | min 28, compile/target 36, Build-Tools 35.0.0, NDK 27.0.12077973 |
| Android CLI 도구 | Command-line Tools 12.0 |
| iOS | 최소 15.0, OS 상한 고정 안 함 |
| Xcode / iOS SDK | 15.2 / 17.2 |
| Ruby / CocoaPods / Bundler | 3.3.13 / 1.16.2 / 2.5.23 |

이 조합을 기본으로 유지하며 설치된 버전이 다르다는 이유만으로 최신판으로 바꾸지 않습니다. 생성된 앱 README에 같은 기준을 전달하고 [실행 실패 시 버전 변경 절차](components/00-common/project/files/docs/06-build-and-release.md#실행-실패-시-버전-변경)에서 현재 경로/버전 확인 → 원인 구분 → 필요한 항목만 변경 → 검증/복귀를 안내합니다. 사용자 확인 결과와 새로 생성한 앱의 실행/빌드 결과는 별도입니다. 새 기기·OS·스토어 지원 조건은 작업 시 다시 확인합니다.

## 구성과 유지보수

components/00-common → 01-base → 02-targets로 빈 앱을 조립합니다. 03-features는 사용자가 수동으로 가져갈 원본이며 생성 구성에 포함하지 않습니다. 생성기는 이곳의 Markdown 설명서와 수동 추가 안내만 앱에 넣습니다. 03-features의 compose.json은 수동 추가 시 버전·설정 참고용이며 생성기가 이 메타데이터로 코드나 연결 파일을 만들지 않습니다.

[작업 지침](AGENTS.md)·[구조·검사 안내](docs/01-composition.md)·[변경 기록](update.md)을 따릅니다. 기본 검사는 짧은 구문·선언·diff 검사입니다. 설치·전체 분석/테스트·빌드·GUI는 명시적으로 요청한 범위에서만 수행합니다.

기존 project/ 앱은 새 생성기의 검사·자동 이행 대상으로 사용하지 않습니다.

공식 근거: [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli), [FVM](https://fvm.app/documentation/getting-started/installation), [Dart 명명](https://dart.dev/effective-dart/style).
