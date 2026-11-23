# 02. Android 준비

기준은 AGP 8.11.1·Kotlin 2.2.20·Gradle Wrapper 8.14·JDK 17, Platform/compile/target 36·min 28·Build-Tools 35.0.0·NDK 27.0.12077973입니다. Kotlin/Java 소스 타깃과 Gradle 실행 JDK는 구분합니다. Gradle/AGP를 전역 설치하지 않습니다.

## JDK·SDK

Android Studio의 Gradle JDK가 17이면 그대로 사용합니다. 별도 JDK가 필요할 때만 OS별 설치 절차를 따릅니다. Gradle 실행에 실제 선택된 JDK는 앱 루트의 `fvm flutter doctor -v`와 Gradle Wrapper로 확인합니다.

### macOS

Homebrew로 OpenJDK 17을 설치하고 현재 프로젝트 터미널에서 선택합니다. Intel Mac에서 formula 설치가 지원되지 않으면 [공식 OpenJDK 다운로드](https://learn.microsoft.com/en-us/java/openjdk/download)에서 현재 macOS·CPU와 호환되는 17 버전을 사용합니다.

```bash
brew install openjdk@17
export JAVA_HOME="$(brew --prefix openjdk@17)/libexec/openjdk.jdk/Contents/Home"
export PATH="$JAVA_HOME/bin:$PATH"
java -version
```

### Windows

Microsoft Build of OpenJDK 17을 설치합니다. 설치 뒤 새 PowerShell을 열고 현재 `java` 경로에서 JDK 루트를 선택해 이 터미널에만 적용합니다. [공식 설치 안내](https://learn.microsoft.com/en-us/java/openjdk/install)

```powershell
winget install --id Microsoft.OpenJDK.17 --exact
$JavaExe = (Get-Command java -CommandType Application).Source
$env:JAVA_HOME = Split-Path (Split-Path $JavaExe -Parent) -Parent
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
java -version
javac -version
```

### Linux

[Eclipse Temurin 17](https://adoptium.net/temurin/releases/?version=17)의 Linux·CPU용 아카이브를 내려받아 체크섬을 확인한 뒤 프로젝트가 관리하는 버전별 폴더에 풉니다. 다음 예시 경로는 실제 압축 해제 경로로 바꿉니다.

```bash
export JAVA_HOME="$HOME/Developer/jdks/jdk-17"
export PATH="$JAVA_HOME/bin:$PATH"
java -version
javac -version
```

각 예시의 환경 변수는 현재 터미널에만 적용됩니다. 버전이 다르면 설치를 다시 하기 전에 `fvm flutter doctor -v`에서 Flutter가 선택한 Java 경로를 확인하고, Android Studio의 Gradle JDK·Gradle Wrapper도 비교합니다. 실행 실패 시 필요한 항목만 바꾸는 절차는 [빌드·배포 문서](06-build-and-release.md#실행-실패-시-버전-변경)를 따릅니다.

Android Studio 또는 [Command-line Tools](https://developer.android.com/studio#command-tools)를 설치하고 cmdline-tools/버전/bin/sdkmanager 배치를 확인합니다. 기존 검증 값은 Command-line Tools 12.0입니다. 오래된 공식 배포본을 구할 수 없으면 임의의 최신판을 같은 버전으로 표시하지 말고 별도 검증합니다.

macOS SDK 경로 예시이며 Linux는 실제 SDK 경로로 바꿉니다.

```bash
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/12.0/bin:$JAVA_HOME/bin:$PATH"
sdkmanager "platform-tools" "platforms;android-36" "build-tools;35.0.0" "ndk;27.0.12077973"
java -version
adb version
```

Windows SDK는 기본 위치를 사용합니다. JAVA_HOME은 위에서 선택한 Microsoft OpenJDK 17 설치 경로입니다.

```powershell
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
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
