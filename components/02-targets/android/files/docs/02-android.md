# 02. Android 준비

기준은 AGP 8.11.1·Kotlin 2.2.20·Gradle Wrapper 8.14·JDK 17, Platform/compile/target 36·min 28·Build-Tools 35.0.0·NDK 27.0.12077973입니다. Kotlin/Java 소스 타깃과 Gradle 실행 JDK는 구분합니다. Gradle/AGP를 전역 설치하지 않습니다.

## JDK·SDK

macOS에서 별도 JDK는 Homebrew로 major별 관리하고 현재 터미널에서 선택합니다.

```bash
brew install openjdk@17
export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
java -version
```

위 java -version은 현재 셸의 Java 확인입니다. Flutter는 별도 jdk-dir 설정이나 Android Studio 내장 JDK를 우선할 수 있으므로 앱 루트의 fvm flutter doctor -v에서 실제 Java binary·버전을 확인합니다. 경로가 다르면 설치 실패로 판단해 버전을 올리기 전에 선택 설정부터 확인합니다. [실행 실패 시 버전 변경](06-build-and-release.md#실행-실패-시-버전-변경)을 함께 따릅니다.

Linux/Windows는 [Temurin 17](https://adoptium.net/temurin/releases/?version=17)의 OS/CPU용 배포본을 설치하고 해당 프로젝트 터미널의 JAVA_HOME/PATH를 지정합니다. Intel/구형 macOS에서 brew가 지원하지 않으면 공식 호환 아카이브·체크섬을 확인해 별도 경로에 풉니다.

Android Studio 또는 [Command-line Tools](https://developer.android.com/studio#command-tools)를 설치하고 cmdline-tools/버전/bin/sdkmanager 배치를 확인합니다. 기존 검증 값은 Command-line Tools 12.0입니다. 오래된 공식 배포본을 구할 수 없으면 임의의 최신판을 같은 버전으로 표시하지 말고 별도 검증합니다.

macOS SDK 경로 예시이며 Linux는 실제 SDK 경로로 바꿉니다.

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/12.0/bin:$JAVA_HOME/bin:$PATH"
sdkmanager "platform-tools" "platforms;android-36" "build-tools;35.0.0" "ndk;27.0.12077973"
java -version
adb version
```

Windows의 경로 예시는 실제 설치 위치로 바꿉니다. JAVA_HOME은 Temurin 17 설치 폴더입니다.

```powershell
$env:JAVA_HOME = "D:\Developer\Java\jdk-17"
$env:ANDROID_HOME = "D:\Developer\Android\Sdk"
$env:PATH = "$env:JAVA_HOME\bin;$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\cmdline-tools\12.0\bin;" + $env:PATH
sdkmanager.bat "platform-tools" "platforms;android-36" "build-tools;35.0.0" "ndk;27.0.12077973"
java -version
adb version
```

앱 루트에서 라이선스를 읽고 동의합니다. FVM은 adb를 설치하지 않습니다.

```bash
fvm flutter doctor --android-licenses
fvm flutter doctor -v
fvm flutter devices
```

macOS/Linux는 필요 시 android/local.properties에 실제 sdk.dir/flutter.sdk 경로가 도구로 생성되는지 확인합니다. Windows는 로컬 경로/백슬래시 처리를 실제 도구 결과에 맞춥니다. 개인 경로 파일을 Git에 추가하지 않습니다. 다른 프로젝트의 전역 JAVA_HOME·Flutter 설정을 덮어쓰지 않습니다.

실기기는 개발자 옵션·USB 디버깅을 켜고 데이터 케이블로 연결한 뒤 기기에서 RSA 연결을 승인합니다. adb devices의 unauthorized/offline은 승인·케이블·연결을 확인합니다. Windows는 제조사 USB 드라이버가 필요할 수 있습니다. 에뮬레이터는 Android Studio의 Device Manager에서 OS/CPU에 맞는 AVD를 생성합니다.

```bash
adb devices
fvm flutter run -d 기기ID
```

공식 근거: [Android SDK 관리](https://developer.android.com/tools/sdkmanager), [Android 연결](https://developer.android.com/studio/run/device), [Flutter Android](https://docs.flutter.dev/platform-integration/android/setup).

Linux의 별도 압축 설치 예시는 실제 경로로 바꿔 현재 프로젝트 터미널에만 적용합니다.

```bash
export JAVA_HOME="$HOME/Developer/jdks/jdk-17"
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/12.0/bin:$PATH"
java -version
adb version
```
