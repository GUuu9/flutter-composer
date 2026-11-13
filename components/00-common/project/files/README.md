# {{name}}

{{target}}용 빈 Flutter 앱입니다. 생성은 소스 준비까지만 수행하며 설치·분석·테스트·빌드는 실행하지 않았습니다. `.composer/state.json`의 generated-unverified는 실행 성공을 뜻하지 않습니다.

## 동작 확인 버전

아래는 사용자가 동작을 확인한 기본 조합입니다. 그대로 시작하며, 현재 PC에서 실제로 선택된 도구/경로와는 구분합니다. 선택한 플랫폼의 항목만 준비합니다.

| 영역 | 확인된 기준 |
| :--- | :--- |
| Flutter / 포함 Dart | 3.35.7 / 3.9.2 |
| Android AGP / Kotlin / Gradle | 8.11.1 / 2.2.20 / 8.14 |
| Android JDK / Java 소스 타깃 | 17 / 11 |
| Android SDK | min 28, compile/target 36, Build-Tools 35.0.0, NDK 27.0.12077973, CLI Tools 12.0 |
| iOS | 최소 15.0, 사용자 OS 상한 고정 안 함 |
| Xcode / iOS SDK | 15.2 / 17.2 |
| Ruby / Bundler / CocoaPods | 3.3.13 / 2.5.23 / 1.16.2 |

FVM은 SDK 선택 도구이고 Dart는 Flutter에 포함됩니다. RubyGems(gem)는 Ruby 환경에서 확인하며 별도 고정 버전은 지정하지 않았습니다. 2026-11-12 사용자가 Android/iOS 실행을 확인했으나 기기·OS/CPU별 상세 기록은 없습니다. 이 새 앱의 빌드·수동 추가 기능·배포 확인은 작업 후 기록합니다.

실행이 안 되면 [현재 환경 확인·필요한 버전만 변경](docs/06-build-and-release.md#실행-실패-시-버전-변경)을 따릅니다. 자동 버전 변경·도구 설치는 수행하지 않습니다.

## 읽는 순서

1. [시작·SDK 준비](docs/01-getting-started.md)
{{platformDocs}}
4. [기능 수동 추가](docs/04-features.md) — 기능이 필요할 때 진행
5. [구조·개발](docs/05-structure.md)
6. [빌드·배포·버전 관리](docs/06-build-and-release.md)

플랫폼 설정 뒤 앱 루트에서 실행합니다. iOS는 03-ios.md의 Xcode·Ruby/CocoaPods·Simulator 또는 실기기 준비를 먼저 완료하고, 해당 문서의 bundle exec 실행 명령을 따릅니다.

```bash
fvm flutter pub get
fvm flutter analyze
fvm flutter test
fvm flutter devices
fvm flutter run -d 기기ID
```

종료는 Ctrl+C입니다. 정상 실행 화면은 비어 있습니다. Composer 외부 소스를 실행 중 참조하지 않습니다. feature add·역추출·자동 재시도/활성화 명령은 제공하지 않습니다. SDK·캐시 설치가 필요하면 시작 가이드에 따라 사용자가 준비합니다.

기본 생성에는 기능 소스·검사·외부 패키지가 포함되지 않습니다. 필요할 때 [수동 추가 안내](docs/04-features.md)를 따라 원하는 구성품만 복사하고 직접 연결합니다. 기능별 문서가 포함되어 있다는 사실은 기능이 설치되었다는 뜻이 아닙니다.
