# 05. 구조·개발

main.dart → core/app.dart의 MobileApp → 빈 MaterialApp 순서입니다. main.dart가 core/di.dart의 createAppDependencies() 결과를 MobileApp에 전달합니다. app.dart는 화면·앱 수명, di.dart는 객체 생성·주입·정리를 담당합니다. 현재 기능/자원이 없으므로 Service·ViewModel·initialize/dispose를 더미로 만들지 않았습니다.

| 위치 | 역할 |
| :--- | :--- |
| lib/core/app.dart | 앱 진입 Widget·화면·앱 수명 |
| lib/core/di.dart | 메인 DI·필요한 공유 자원의 생성/수명 |
| lib/scenes/기능 | 화면·화면 상태·내부 Model |
| lib/services/기능 | 공유 기능·payload 검증·기능 Model |
| lib/apis | 외부 호출 경계 |
| lib/components | 재사용 Widget |
| lib/utils·config·resource | 순수 함수·공개 설정·자산 경로 |
| resource | 실제 자산. 추가할 때 pubspec에 등록 |
| android·ios | 선택한 플랫폼만 포함하는 공식 생성 구조 |
| test | 실제 추가한 기능의 독립 검사 |
| .composer | 생성 상태·소유 파일 기록. 수동 성공 처리 금지 |

필요한 기능이 생기면 Widget → ViewModel → Service → Api로 나누고 필요한 의존성만 생성자로 주입합니다. 모든 계층을 강제하지 않으며 객체가 DI 전체를 참조하지 않습니다. 파일/기능 폴더는 snake_case입니다. Model은 소유 기능 옆에 두며 core/composition·최상위 models를 만들지 않습니다.

화면 구독은 Widget 종료 때 해제하고 비동기 결과는 해제 뒤 반영하지 않습니다. 화면이 공유 Service를 임의 종료하지 않습니다. 자원이 생기면 초기화 실패 시 역순 정리·원인 보존을 구현하고 모바일 종료 콜백은 보장되지 않는 것으로 다룹니다.

새 권한/플러그인은 플랫폼 지원·의존성·네이티브 설정·런타임 요청·거부 동작을 함께 문서화합니다. 앱에 포함되는 환경 파일/asset/빌드 값은 공개 정보입니다. 서버 비밀이나 서명 자료를 넣지 않습니다.
