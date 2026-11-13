# 06. 빌드·배포·버전 관리

생성된 소스에 사용자 업무·서명·배포 설정은 없습니다. 사용자가 동작을 확인한 조합을 versions.json·버전 선택/빌드 설정에 보존합니다. 이 기본 조합으로 시작하며, 새 앱의 빌드·실기기·스토어 결과는 별도로 기록합니다.

## 지원과 기준

Android는 최소 API 28, compile/target 36이며 사용자 OS 상한은 고정하지 않습니다. iOS는 최소 15.0, 사용자 OS 상한은 고정하지 않습니다. 개발/빌드 OS·CPU와 앱 사용자 OS를 구분합니다. Xcode 15.2/iOS SDK 17.2는 과거 확인 기준이며 최신 기기·스토어 제출 지원 보장이 아닙니다. 현재 PC·기기에서 검증한 OS/CPU·도구·확인일을 별도로 기록합니다.

선택 플랫폼을 준비한 앱 루트에서 사용자가 실행할 검사입니다.

```bash
fvm flutter analyze
fvm flutter test
# Android를 선택한 경우
fvm flutter build apk --debug
# iOS를 선택하고 macOS/Xcode를 준비한 경우
fvm flutter build ios --no-codesign
```

## 배포 준비

Android는 applicationId·pubspec version/build 번호·권한·서명·보안 설정을 확정하고 `fvm flutter build appbundle --release`로 .aab를 만듭니다. 공식 생성기의 debug 서명 설정을 스토어용 서명으로 사용하지 않습니다. 키·비밀번호는 앱 밖의 안전한 저장소와 로컬 제외 파일로 관리합니다. Play Console 테스트 트랙·target API 정책·실제 설치/업데이트를 확인한 뒤 배포합니다.

iOS는 bundle identifier·버전/build 번호·Signing Team·entitlement·권한 설명을 확정하고 Xcode Archive 또는 `fvm flutter build ipa --release`로 서명된 archive/IPA를 준비합니다. App Store Connect의 검증·TestFlight·실기기 확인을 거칩니다. no-codesign 빌드는 배포 성공이 아닙니다.

산출물 경로·소스 커밋·pubspec.lock·버전/SDK·서명 식별자·배포 설정을 보관합니다. 앱/데이터 스키마 변경은 별도 이행·백업을 준비합니다. 정상 커밋/lock/SDK로 복귀한 뒤 다시 빌드·검사하며 사용자 데이터와 서명키를 삭제하지 않습니다. 재설치가 데이터 복구를 보장하지는 않습니다.

## 실행 실패 시 버전 변경

### 1. 현재 상태 확인

먼저 앱 README의 사용자 확인 조합과 현재 실행되는 버전/경로를 비교합니다. 다른 버전이 설치돼 있다는 사실만으로 오류로 판단하거나 전체 도구를 업데이트하지 않습니다. 아래 명령은 자동 검사 결과가 아니라 사용자가 앱 루트에서 실행할 확인 절차입니다. 미설치는 미설치, 아직 확인하지 않은 항목은 미확인으로 기록합니다.

```bash
# 실행 위치: 앱 루트 터미널. 공통 도구/SDK의 실제 버전을 확인합니다.
fvm --version
fvm flutter --version
fvm dart --version
fvm flutter doctor -v
```

```bash
# 실행 위치: 앱 루트 터미널. Android를 개발할 때 확인합니다.
java -version
adb version
# Flutter가 선택한 실제 Java 경로/버전은 doctor -v에서도 확인합니다.
fvm flutter doctor -v
```

```bash
# 실행 위치: 앱 루트 터미널. iOS를 개발하는 macOS에서 준비된 도구를 확인합니다.
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
ruby -v
gem --version
bundle _2.5.23_ --version
bundle _2.5.23_ exec pod --version
```

JAVA_HOME/PATH와 java -version만으로 Flutter의 JDK가 고정되는 것은 아닙니다. Flutter의 jdk-dir 설정·Android Studio 내장 JDK가 우선될 수 있으므로 doctor -v의 실제 Java binary를 확인합니다. Ruby는 rbenv의 선택, Xcode는 현재 DEVELOPER_DIR도 함께 확인합니다. RubyGems는 Ruby에 포함된 패키지 관리 도구이며 이 프로젝트는 gem 자체의 별도 버전을 고정하지 않습니다.

| 상황 | 먼저 할 작업 |
| :--- | :--- |
| 명령을 찾지 못함·SDK/패키지 미설치 | 시작·OS 준비 문서에서 기준 버전을 설치하고 PATH/실제 선택 경로 확인 |
| 라이선스·권한·서명·연결·네트워크 오류 | 해당 오류를 해결한 뒤 같은 버전으로 재시도 |
| 실제 JDK/Ruby/Xcode 경로가 의도와 다름 | 선택 경로부터 바로잡고 실제 버전 재확인 |
| 최소 SDK/JDK 요구·도구/플러그인 호환성 오류 | 오류가 요구하는 항목과 공식 호환 범위를 확인해 아래 절차로 변경 |
| 새 기기·macOS·스토어 요구를 기존 도구가 지원하지 않음 | 호환 Xcode/SDK·Flutter 범위를 확인하고 필요한 조합만 변경 |

변경 전 정상 소스·버전 파일·lock·로컬 경로와 오류 로그를 보관합니다. 로그에서 토큰·키·계정/개인 정보는 제외합니다. 아래 <...> 값은 최신판을 뜻하지 않으며 오류 원인과 공식 호환 범위로 선택한 실제 버전/경로로 바꿉니다.

### 2. Flutter와 Dart

변경은 **생성된 앱 루트**에서만 수행합니다. Flutter에 포함된 Dart를 함께 선택하며 Dart를 따로 설치/업그레이드하지 않습니다.

```bash
# 실행 위치: 앱 루트 터미널. <호환_Flutter_버전>을 실제 값으로 바꾼 뒤 실행합니다.
PROJECT_FLUTTER_VERSION="<호환_Flutter_버전>"
fvm install "$PROJECT_FLUTTER_VERSION"
fvm use "$PROJECT_FLUTTER_VERSION" --skip-pub-get
fvm flutter --version
fvm dart --version
fvm flutter pub get
```

변경된 .fvmrc를 확인하고 pubspec.yaml의 environment.sdk와 소스/패키지가 포함 Dart를 지원하는지 확인합니다. 필요한 경우에만 SDK 제약을 수정하고 pubspec.lock은 실제 도구로 갱신합니다. versions.json의 flutter/dart는 실제 출력과 검증 결과에 맞춰 기록합니다. 이 명령은 Bash 예시이며 Windows에서는 PowerShell 변수 형식으로 값을 지정하거나 같은 FVM 명령의 버전 자리에 실제 값을 직접 넣습니다. 전역 Flutter나 Composer 원본 SDK는 바꾸지 않습니다.

### 3. Android 빌드 도구

AGP 릴리스의 Gradle/JDK/SDK 호환표와 선택 Flutter 지원 범위를 먼저 확인합니다. JDK 실행 버전과 Java/Kotlin 소스 타깃은 별개입니다. JDK가 바뀌었다는 이유만으로 javaTarget=11도 올리지 않습니다.

| 변경 대상 | 실제 적용 위치·작업 |
| :--- | :--- |
| JDK | Android 준비 문서의 Homebrew major formula 또는 OS용 배포본으로 필요한 major 설치/선택. Flutter가 사용하는 JDK와 Gradle 실행 JVM을 각각 확인 |
| AGP·Kotlin | android/settings.gradle.kts의 해당 plugin version만 수정. Flutter loader 등 나머지 선언 유지 |
| Gradle | android/gradle/wrapper/gradle-wrapper.properties의 distributionUrl 및 Wrapper 스크립트/JAR 함께 관리. 전역 Gradle 설치 금지 |
| compileSdk·targetSdk·Build-Tools·NDK | android/app/build.gradle.kts의 필요한 값만 수정하고 sdkmanager로 해당 패키지 설치 |
| minSdk | 의존성의 최소 요구/제품 지원 범위를 확인한 경우만 변경. 기존 사용자 지원 영향 기록 |

Wrapper가 현재 환경에서 실행 가능한 경우 Android 폴더에서 필요한 버전으로 갱신합니다.

```bash
# 실행 위치: 앱 루트의 Android 폴더로 이동합니다. <호환_Gradle_버전>은 실제 값으로 교체합니다.
cd android
./gradlew wrapper --gradle-version "<호환_Gradle_버전>" --distribution-type all
./gradlew --version
cd ..
```

```powershell
# 실행 위치: Windows 앱 루트 터미널. Gradle 버전을 실제 값으로 교체합니다.
Set-Location android
.\gradlew.bat wrapper --gradle-version "<호환_Gradle_버전>" --distribution-type all
.\gradlew.bat --version
Set-Location ..
```

기존 Wrapper가 시작조차 안 되면 실행 JDK/현재 AGP 호환부터 확인합니다. 필요한 distributionUrl 수정 후 Wrapper가 실행되면 공식 Wrapper 절차로 스크립트/JAR까지 갱신하고 변경 파일을 보관합니다. SDK 패키지 설치 명령/경로는 앱의 Android 준비 문서에서 해당 버전으로 바꿉니다. versions.json만 고쳐서는 빌드 설정이 바뀌지 않습니다.

### 4. iOS 도구

Xcode는 Mac의 OS/CPU·iPhone OS·스토어 요구를 지원하는 버전을 공식 지원표에서 선택합니다. 기존 Xcode를 보존하고 현재 프로젝트 터미널의 DEVELOPER_DIR로 새 경로를 선택한 뒤 라이선스·최초 초기화를 완료합니다. 명령과 Ruby/CocoaPods 설치는 앱의 iOS 준비 문서를 따릅니다. iOS SDK는 선택 Xcode에 포함된 값을 사용합니다.

Ruby 변경이 필요한 경우 rbenv에 별도 버전을 설치하고 앱에서 선택합니다. 현재 Ruby로 Bundler/CocoaPods가 정상 실행되면 그대로 유지합니다.

```bash
# 실행 위치: 앱 루트 터미널. rbenv shell 연결 후 실제 호환 Ruby 버전으로 바꿉니다.
PROJECT_RUBY_VERSION="<호환_Ruby_버전>"
rbenv install "$PROJECT_RUBY_VERSION"
rbenv local "$PROJECT_RUBY_VERSION"
ruby -v
gem --version
```

새 Ruby에는 필요한 Bundler/gem 설치가 별도로 필요할 수 있습니다. Bundler 기준을 유지하는 경우 iOS 준비 문서의 2.5.23 설치/실행 절차를 사용합니다. CocoaPods 변경이 필요한 경우에만 Gemfile의 기존 cocoapods 선언을 선택한 버전으로 바꾸고 해당 gem을 대상으로 갱신합니다.

```ruby
# 파일: Gemfile
# 기존 cocoapods 버전만 교체합니다. source와 다른 gem은 유지합니다.
gem "cocoapods", "<호환_CocoaPods_버전>"
```

```bash
# 실행 위치: 앱 루트 터미널. 위 Gemfile 수정 후 CocoaPods와 필요한 의존성만 갱신합니다.
bundle _2.5.23_ update cocoapods
bundle _2.5.23_ exec pod --version
```

Bundler 자체도 변경해야 할 때만 다음을 실행합니다. Ruby와 호환되는 실제 버전을 선택하고 Gemfile.lock의 BUNDLED WITH도 함께 갱신합니다.

```bash
# 실행 위치: 앱 루트 터미널. <호환_Bundler_버전>을 실제 값으로 교체합니다.
PROJECT_BUNDLER_VERSION="<호환_Bundler_버전>"
gem install bundler -v "$PROJECT_BUNDLER_VERSION"
bundle "_${PROJECT_BUNDLER_VERSION}_" update --bundler="$PROJECT_BUNDLER_VERSION"
bundle "_${PROJECT_BUNDLER_VERSION}_" exec pod --version
```

이후 bundle exec 명령도 선택한 같은 버전을 사용합니다. RubyGems 오류가 아니라면 gem update --system을 기본 해결책으로 실행하지 않습니다. Gemfile.lock/Podfile.lock을 일괄 삭제하거나 인자 없는 bundle update로 모든 gem을 올리지 않습니다.

### 5. 검증·기록·복귀

변경 후 이 문서의 플랫폼별 분석/테스트·빌드와 실제 기기 실행을 확인합니다. iOS Flutter 명령은 준비한 Bundler 버전의 bundle exec로 실행해 프로젝트 CocoaPods 환경을 전달합니다. 확인한 OS/CPU·도구/SDK·기기·날짜·실제 명령/결과와 변경 이유를 앱 문서에 기록하고 성공한 조합을 versions.json 및 실제 설정/lock과 맞춥니다. 미검증 후보를 기존 동작 확인 조합으로 표시하지 않습니다.

실패하면 보관한 소스·.fvmrc·pubspec/lock·Android 설정/Wrapper·.ruby-version·Gemfile/lock·플랫폼 설정과 원래 SDK/JDK/Ruby/Xcode 선택으로 함께 복귀합니다. 다른 앱이 쓰는 설치본·서명키·데이터를 삭제하지 않습니다. Composer 원본의 SDK/versions.json을 바꾸는 유지보수는 생성 앱 변경과 별도이며 공식 템플릿과 생성기 호환 검사가 필요합니다.

공식 근거: [FVM 버전 선택](https://fvm.app/documentation/guides/basic-commands), [Android JDK](https://developer.android.com/build/jdks), [AGP 호환표](https://developer.android.com/build/releases/gradle-plugin), [Gradle Wrapper](https://docs.gradle.org/current/userguide/gradle_wrapper.html), [Xcode 지원](https://developer.apple.com/support/xcode/), [rbenv](https://github.com/rbenv/rbenv), [CocoaPods Gemfile](https://guides.cocoapods.org/using/a-gemfile.html), [Bundler 버전 변경](https://bundler.io/blog/2022/01/23/bundler-v2-3.html).

Composer 원본 업데이트는 기존 앱을 자동 변경하지 않습니다. 새 별도 앱과 필요한 차이만 비교·이행하고 .composer/state.json을 고쳐 보호를 우회하지 않습니다. 생성 실패 출력은 보존한 채 실패 단계를 확인하고 새 이름으로 다시 생성합니다. 자동 이어쓰기·기능 추가는 현재 제공하지 않습니다.

공식 근거: [Android 배포](https://docs.flutter.dev/deployment/android), [iOS 배포](https://docs.flutter.dev/deployment/ios), [Xcode 지원](https://developer.apple.com/support/xcode/).

| 지원 기록 구분 | 현재 상태 |
| :--- | :--- |
| 개발/빌드 OS·CPU 최소/최대 | 이 새 앱에서는 미확정. 공식 SDK·Xcode 조건을 확인 |
| Android 사용자 OS | 최소 API 28, 상한 고정 안 함. 실기기 검증 최저/최고 미검증 |
| iOS 사용자 OS | 최소 15.0, 상한 고정 안 함. 실기기 검증 최저/최고 미검증 |
| 실제 빌드·설치·배포 | 미검증. 수행한 날짜·OS/CPU·기기·SDK/lock·결과를 추가 기록 |
