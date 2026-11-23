<!-- version: v0.1.0 -->
# Flutter Composer 변경 기록

현재 파일 구성을 v0.0.0의 새 Git 기준으로 시작합니다. 이후 변경은 최신순·커밋당 한 항목으로 기록합니다.

## 2026-11-24 — docs(android): JDK 설치·프로젝트 선택 절차 갱신

- Android Studio의 JDK 17 재사용 여부를 먼저 확인하고 macOS Homebrew, Windows Microsoft OpenJDK, Linux Temurin 설치·선택 안내를 맞춥니다.
- Android SDK 경로를 Windows 기본 위치로 수정하고 JDK 선택 확인을 Gradle Wrapper·Flutter 진단과 연결합니다.
- 검증: 문서 링크·코드 블록·diff 검사. 설치·Android 빌드는 미검증입니다.

## 2026-11-13 — feat(workspace): 선택 프로젝트의 VS Code 작업 영역 생성

- Dart workspace 명령으로 Composer와 선택한 프로젝트를 하나의 로컬 작업 영역으로 엽니다.
- 번호 선택·취소·교체 확인·링크 제외를 제공하며 기존 앱과 Git은 변경하지 않습니다.
- 검증: 임시 폴더 자체 검사·변경 Dart 정적 분석·diff 검사. 실제 VS Code 화면과 Windows 실행은 미검증입니다.

## 2026-11-13 — chore(repo): v0.0.0 초기 기준 생성

- Android·iOS·android-ios 빈 앱 생성과 main → app / DI 분리 구조를 초기 기준으로 보관합니다. 기능은 수동 추가하며 설치·권한·DI·버전 관리 문서를 포함합니다.
- 사용자 동작 확인 SDK/도구 조합을 유지하고 Windows 경로 처리·원본/반출 문서 연결·민감 정보 없는 실패 진단을 포함합니다.
- 기존 Git 이력을 제거하고 현재 파일의 최초 커밋·v0.0.0 태그로 시작합니다. project/의 앱·독립 Git은 제외하며 원격 연결·push는 수행하지 않습니다.
- 검증: 초기화 전 수행한 생성기/검사 코드 정적 컴파일·짧은 경로/진단 검사·임시 선언 렌더·버전 기준 보존·문서/설정 문법 검사 결과를 기록합니다. 실제 Windows 실행·새 앱 생성·전체 테스트·실기기·네이티브 빌드는 미수행입니다.
