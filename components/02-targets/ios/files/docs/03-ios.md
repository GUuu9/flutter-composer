# 03. iOS 준비·실행

모든 명령은 생성한 앱 루트에서 실행합니다. 먼저 [SDK/FVM 준비](01-getting-started.md)를 완료하고 `ios/`, `Gemfile`, `.ruby-version`이 있는지 확인합니다. 아래 설치 명령은 준비가 안 된 항목에만 사용합니다.

기준은 Flutter 3.35.7/Dart 3.9.2, 최소 iOS 15.0, Xcode 15.2/iOS SDK 17.2, Ruby 3.3.13/Bundler 2.5.23/CocoaPods 1.16.2입니다. 이 버전 표는 사용자가 동작을 확인한 기본 조합이며 현재 환경에서 정상 동작하면 유지합니다. 호환성 오류가 있을 때는 [필요한 버전만 변경](06-build-and-release.md#실행-실패-시-버전-변경)합니다. 프로젝트마다 실제 실행한 기기/Simulator·OS·도구 버전을 별도로 기록합니다. Windows/Linux에서는 iOS를 빌드할 수 없습니다.

## 1. Xcode 설치·선택·초기화

[Apple Developer 다운로드](https://developer.apple.com/download/all/)에서 Mac의 OS/CPU가 지원하는 Xcode를 준비합니다. 기준 버전을 유지한다면 Xcode 15.2의 .xip을 풀어 Applications에 두고 한 번 실행합니다. 이미 설치한 Xcode를 덮어쓰지 않습니다. 아래는 /Applications/Xcode.app 기준입니다. 다른 위치에 설치했다면 실제 경로로 바꿉니다.

```bash
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
sudo env DEVELOPER_DIR="$DEVELOPER_DIR" xcodebuild -license
sudo env DEVELOPER_DIR="$DEVELOPER_DIR" xcodebuild -runFirstLaunch
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
xcrun --find simctl
```

라이선스를 읽고 동의한 뒤 초기화를 완료합니다. 기대값은 Xcode 15.2·iOS SDK 17.2이며 simctl 경로가 선택한 Xcode 아래에 있어야 합니다. `/Library/Developer/CommandLineTools`만 설치한 상태로는 부족합니다. `sudo env`는 관리자 작업에도 선택한 Xcode를 전달합니다. 전역 `xcode-select`를 바꾸지 않고 이 터미널에서만 선택하며 새 터미널에는 DEVELOPER_DIR를 다시 적용합니다.

## 2. Homebrew·Ruby·CocoaPods 준비

이미 Homebrew가 있으면 중복 설치하지 않습니다. 없으면 Xcode 초기화 후 공식 설치기를 실행하고 마지막에 표시되는 shellenv 안내를 적용합니다.

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Homebrew가 설치됐는데 명령이 없다면 CPU/설치 위치에 맞는 한 줄만 적용합니다.

```bash
# Apple Silicon의 기본 경로
eval "$(/opt/homebrew/bin/brew shellenv)"
```

```bash
# Intel의 기본 경로
eval "$(/usr/local/bin/brew shellenv)"
```

기존 Mac/Intel에서 배포 패키지가 지원되지 않으면 반복 설치로 해결하지 말고 [공식 Homebrew 지원](https://docs.brew.sh/Support-Tiers)·[rbenv 수동 설치](https://github.com/rbenv/rbenv#installation) 조건을 확인합니다. 설치 완료 후 현재 zsh에 rbenv를 연결합니다.

```bash
brew --version
brew install rbenv ruby-build
eval "$(rbenv init - zsh)"
rbenv install -s 3.3.13
rbenv local 3.3.13
ruby -v
rbenv which ruby
```

Ruby 3.3.13과 rbenv의 해당 버전 경로가 나와야 합니다. `/usr/bin/ruby`가 나오면 shell 연결부터 해결합니다. 새 터미널에도 적용하려면 `eval "$(rbenv init - zsh)"`를 ~/.zshrc에 한 번만 기록합니다. 기존 RBENV_VERSION이 있으면 .ruby-version보다 우선하므로 현재 작업 셸에서 확인·해제한 뒤 다시 확인합니다. 다른 프로젝트의 global Ruby는 변경하지 않습니다.

앱 루트 Gemfile은 다음 버전을 선언합니다. 기존 파일을 확인하며 다른 gem이나 사용자 설정을 통째로 덮어쓰지 않습니다.

```ruby
source "https://rubygems.org"
gem "cocoapods", "1.16.2"
```

```bash
gem install bundler -v 2.5.23
bundle _2.5.23_ config set --local path vendor/bundle
bundle _2.5.23_ install
bundle _2.5.23_ exec pod --version
```

CocoaPods 1.16.2 출력과 Gemfile.lock 생성을 확인합니다. 시스템 Ruby에 sudo gem install을 하지 않습니다. .ruby-version·Gemfile·Gemfile.lock은 보관하고 .bundle/·vendor/bundle/은 Git에서 제외합니다.

## 3. Flutter 의존성·iOS 도구 확인

다음 precache는 고정 SDK의 iOS 캐시가 없으면 다운로드합니다. SDK를 최신 버전으로 올리는 명령은 아닙니다.

```bash
fvm flutter --version
fvm flutter precache --ios
fvm flutter pub get
bundle _2.5.23_ exec fvm flutter doctor -v
```

Xcode·CocoaPods 항목을 확인합니다. iOS만 점검할 때 Android 관련 경고를 해결하느라 프로젝트의 도구 버전을 바꾸지 않습니다. `bundle exec`는 Flutter가 실행하는 pod에도 이 프로젝트의 Gemfile 환경을 전달합니다.

빈 앱에 ios/Podfile이 없다면 정상일 수 있습니다. **현재 단계에서 pod install을 실행하지 말고 4절의 Flutter 실행으로 진행합니다.** Flutter는 실제 native 플러그인과 의존성 관리 방식에 따라 CocoaPods 처리를 결정합니다. pod init·임의 Podfile 생성·프로젝트 재생성을 하지 않습니다.

수동 pod install은 **ios/Podfile이 실제로 존재하고**, CocoaPods 의존성을 복원해야 할 때만 사용하는 별도 명령입니다. 기본 실행 순서에는 필요하지 않습니다. Generated.xcconfig 누락은 앱 루트의 pub get부터 확인하며 lock·Pods를 일괄 삭제하지 않습니다.

## 4. 시뮬레이터에서 먼저 실행

1. 선택한 Xcode의 **Settings → Platforms**에서 호환 iOS Simulator runtime을 설치합니다. Xcode 15.2 기준은 iOS 17.2이며 앱의 최소 15.0 이상이어야 합니다.
2. **Window → Devices and Simulators → Simulators**에서 iPhone 시뮬레이터를 선택합니다. 없으면 +로 기기 종류와 설치한 runtime을 선택해 만듭니다.
3. 선택한 Xcode의 Simulator를 실행합니다.

```bash
open "$DEVELOPER_DIR/Applications/Simulator.app"
xcrun simctl list runtimes
xcrun simctl list devices available
```

목록에서 사용할 iPhone의 UUID와 상태를 확인합니다. Shutdown 상태라면 해당 UUID로 부팅하고, 이미 Booted이면 boot 명령을 생략합니다. 아래 UUID는 실제 값으로 바꿉니다.

```bash
xcrun simctl boot 시뮬레이터UUID
xcrun simctl bootstatus 시뮬레이터UUID -b
fvm flutter devices
bundle _2.5.23_ exec fvm flutter run -d 시뮬레이터UUID
```

빈 화면이 표시되면 기본 실행 확인입니다. Ctrl+C로 종료합니다. 시뮬레이터 확인에는 실기기용 Signing Team/프로비저닝을 먼저 설정할 필요가 없습니다.

## 5. 실기기 실행·서명

1. iPhone을 데이터 케이블로 연결하고 잠금을 해제합니다. Mac/기기에서 신뢰를 승인하고 iOS 16 이상에서는 iPhone의 **설정 → 개인정보 보호 및 보안 → 개발자 모드**를 켭니다. iOS 15에는 이 메뉴가 없습니다. 기기가 요구하면 재시동·재승인을 완료합니다.
2. Xcode의 **Window → Devices and Simulators → Devices**에서 준비가 끝났는지 확인합니다. 기기 iOS가 해당 Xcode의 지원 범위보다 새로우면 호환 Xcode가 필요합니다. Simulator runtime 설치로 이 문제를 해결할 수는 없습니다.
3. 앱 루트에서 workspace를 엽니다.

```bash
open ios/Runner.xcworkspace
```

4. Xcode **Settings → Accounts**에 Apple ID를 연결합니다. **TARGETS → Runner → Signing & Capabilities**에서 Team과 Automatically manage signing을 설정하고 생성 시 확인한 Bundle Identifier를 확인합니다. 개인 개발 실행과 App Store 배포 계정/권한은 구분합니다.
5. 실행 대상을 연결한 iPhone으로 선택합니다. 기기에서 개발자 인증서 신뢰를 요구하면 설정의 **일반 → VPN 및 기기 관리**에서 본인 개발자를 확인합니다.

```bash
fvm flutter devices
bundle _2.5.23_ exec fvm flutter run -d 실기기ID
```

CocoaPods를 사용하는 프로젝트는 .xcodeproj 대신 .xcworkspace를 엽니다. Team/인증서/프로비저닝은 사용자 계정으로 준비하고 키·비밀번호·개인 설정을 커밋하지 않습니다. 미서명 빌드나 시뮬레이터 실행을 실기기/배포 성공으로 기록하지 않습니다.

## 완료 확인·주요 오류

| 현상 | 먼저 확인할 항목 |
| :--- | :--- |
| Xcode가 없거나 CLT만 감지됨 | 현재 터미널의 DEVELOPER_DIR·xcodebuild·xcrun 경로 |
| rbenv shell integration 오류/시스템 Ruby 사용 | 현재 셸 init·ruby 경로·RBENV_VERSION |
| CocoaPods를 찾지 못함/버전이 다름 | bundle install·bundle exec pod --version·bundle exec Flutter 실행 |
| 시뮬레이터가 devices에 없음 | 호환 runtime·생성된 기기·Booted 상태 |
| No profiles / Team 오류 | Runner의 Team·Bundle Identifier·연결 기기·Apple ID |
| 기기 iOS 버전이 지원되지 않음 | Xcode/기기 호환성. 고정 기준 변경은 별도 검증 |

실행한 날짜·macOS/CPU·Xcode/SDK·Simulator 또는 기기 OS·실제 명령/결과를 기록합니다. Android 실행 확인을 iOS 검증으로 확대하지 않습니다.

공식 근거: [Flutter iOS](https://docs.flutter.dev/platform-integration/ios/setup), [Xcode 지원](https://developer.apple.com/support/xcode/), [Homebrew 설치](https://docs.brew.sh/Installation), [rbenv](https://github.com/rbenv/rbenv), [CocoaPods Gemfile](https://guides.cocoapods.org/using/a-gemfile.html).
