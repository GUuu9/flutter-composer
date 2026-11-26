# 01. 프로젝트에서 시작

이 앱을 가져온 위치가 작업 루트입니다. `.fvmrc`·`versions.json`·`pubspec.yaml`을 확인합니다. Flutter 3.35.7/Dart 3.9.2를 사용자가 동작을 확인한 기본 조합으로 사용하며 최신 버전으로 자동 변경하지 않습니다.

README의 확인된 버전 표와 실제 사용 버전을 비교합니다. 기준과 같고 실행된다면 유지합니다. 도구가 없으면 아래/플랫폼 준비 절차로 설치하고, 경로·라이선스·권한 문제는 먼저 해결합니다. 실제 호환성 오류로 변경이 필요할 때만 [버전 변경 절차](06-build-and-release.md#실행-실패-시-버전-변경)를 따릅니다.

## FVM 설치·확인

이미 FVM이 있으면 중복 설치하지 않습니다. macOS/Linux의 공식 독립 설치 방식은 다음과 같습니다. 설치 명령은 사용자가 필요한 경우에만 실행합니다.

```bash
curl -fsSL https://fvm.app/install.sh | bash
export PATH="$HOME/fvm/bin:$PATH"
fvm --version
```

Windows에서는 개발 도구와 SDK를 C 드라이브의 기본 경로에 설치합니다. D 드라이브는 앱 소스와 프로젝트 문서를 저장할 때 사용합니다. Chocolatey가 준비되면 관리자 PowerShell에서 FVM을 설치합니다. [FVM 공식 설치 안내](https://fvm.app/documentation/getting-started/installation)

```powershell
choco install fvm
```

새 PowerShell에서 `Get-Command fvm`과 `fvm --version`으로 설치를 확인합니다. 앱 폴더가 D에 있어도 FVM 실행 파일 경로를 D로 바꾸지 않습니다.

앱 루트의 고정 SDK를 준비합니다. 없으면 아래 명령이 SDK를 다운로드하므로 네트워크와 저장 공간을 먼저 확인합니다.

```bash
fvm install
fvm flutter --version
fvm dart --version
```

선택 플랫폼의 JDK/SDK 또는 Xcode를 준비한 후 의존성을 설치합니다. Dart는 Flutter에 포함되므로 별도 버전을 설치하지 않습니다.

```bash
fvm flutter pub get
fvm flutter doctor -v
```

새 pubspec.lock은 실제 도구가 생성하도록 하고 이후 앱 Git에 저장합니다. 기존 앱은 lock을 삭제하거나 pub upgrade를 초기 준비에 사용하지 않습니다. VS Code의 Flutter/Dart 확장을 설치하고 프로젝트 SDK 경로를 `.fvm/flutter_sdk`로 선택합니다. Android Studio는 SDK/AVD 관리 용도로 사용할 수 있습니다. 전역 Flutter 경로를 다른 앱에 맞춰 바꾸지 않습니다.

공식 근거: [FVM 설치](https://fvm.app/documentation/getting-started/installation), [Flutter CLI](https://docs.flutter.dev/reference/flutter-cli), [Dart 명명](https://dart.dev/effective-dart/style).

## 프로젝트 환경 보관

JDK/SDK/Xcode 경로는 현재 프로젝트의 작업 셸에서 선택합니다. 공유할 값의 형식은 필요할 때 .env.example로 기록하고 실제 .env는 Git에서 제외합니다. .env가 존재하는 것만으로 셸·Flutter가 자동 로딩하지는 않습니다. 폴더 진입 시 도구 설치·업데이트를 수행하지 않습니다.

Ruby는 프로젝트 .ruby-version, CocoaPods는 Gemfile과 bundle exec, Xcode는 작업 셸의 DEVELOPER_DIR로 선택합니다. 이 방식이 공유 도구 설치·키체인·IDE 설정까지 격리하는 것은 아닙니다. SDK/도구 변경 전 정상 버전과 로컬 경로·lock·데이터를 보존합니다.
