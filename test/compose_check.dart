import 'dart:convert';
import 'dart:io';
import '../scripts/compose.dart' as composer;

void check(bool value, String message) {
  if (!value) throw StateError(message);
}

void main() {
  final root = File.fromUri(Platform.script).parent.parent;
  check(composer.validName('my_app'), 'snake_case 이름');
  for (final value in [
    '../app',
    'MyApp',
    '_app',
    'class',
    'con',
    'com1',
    '1app',
  ]) {
    check(!composer.validName(value), '잘못된 이름: $value');
  }
  check(composer.validOrganization('com.company'), '조직 식별자');
  check(!composer.validOrganization('com..company'), '빈 조직 segment');
  check(composer.validAndroidId('com.company.my_app'), 'Android 식별자');
  check(!composer.validIosId('com.company.my_app'), 'iOS 밑줄 거부');
  check(composer.validIosId('com.company.myApp'), 'iOS 식별자');
  check(
    composer.iosIdentifier('com.company', 'my_app') == 'com.company.myApp',
    'SDK iOS 이름 변환',
  );
  for (final value in ['../app', '/app', 'C:/app', '.composer/state.json']) {
    check(!composer.safeRelativePath(value), '출력 경로 보호');
  }

  check(
    composer.isPathWithin(
      r'D:\repo\components\flutter',
      'D:/repo/components',
      windows: true,
    ),
    'Windows 구분자',
  );
  check(
    composer.isPathWithin(
      'd:/REPO/COMPONENTS/flutter',
      r'D:\repo\components',
      windows: true,
    ),
    'Windows 대소문자',
  );
  check(
    composer.isPathWithin(
      r'\\server\share\components\flutter',
      '//server/share/components',
      windows: true,
    ),
    'Windows UNC',
  );
  check(
    !composer.isPathWithin(
      'D:/repo/components-other/flutter',
      'D:/repo/components',
      windows: true,
    ),
    '비슷한 경로 거부',
  );
  check(
    !composer.isPathWithin(
      'D:/repo/components/../outside',
      'D:/repo/components',
      windows: true,
    ),
    '부모 경로 이탈 거부',
  );
  check(
    !composer.isPathWithin(
      'D:/repo/components',
      'D:/repo/components',
      windows: true,
    ),
    '동일 경로 거부',
  );
  check(
    !composer.isPathWithin(
      'E:/repo/components/flutter',
      'D:/repo/components',
      windows: true,
    ),
    '다른 드라이브 거부',
  );
  check(
    !composer.isPathWithin(
      '/repo/Components/flutter',
      '/repo/components',
      windows: false,
    ),
    'POSIX 대소문자 구분',
  );
  check(
    composer.isPathWithin(
      '/repo/components/flutter',
      '/repo/components/',
      windows: false,
    ),
    'POSIX 끝 구분자',
  );
  final processFailure = composer.failureDetails(
    ProcessException('flutter', ['secret-argument'], 'secret-message', 2),
  );
  check(
    processFailure['executable'] == 'flutter' &&
        processFailure['osErrorCode'] == 2 &&
        !jsonEncode(processFailure).contains('secret'),
    '프로세스 실행 경로/코드만 진단',
  );
  final fileFailure = composer.failureDetails(
    const FileSystemException(
      'secret-message',
      '/missing/config.json',
      OSError('secret-os-message', 2),
    ),
  );
  check(
    fileFailure['path'] == '/missing/config.json' &&
        !jsonEncode(fileFailure).contains('secret'),
    '파일 진단에서 원문 메시지 제외',
  );
  check(
    !jsonEncode(
      composer.failureDetails(
        const FormatException('secret-message', 'secret-source'),
      ),
    ).contains('secret'),
    '형식 오류 원문 제외',
  );
  final jsonFailure = composer.failureDetails(
    composer.JsonFileFormatException('/config.json', 3),
  );
  check(
    jsonFailure['path'] == '/config.json' && jsonFailure['offset'] == 3,
    'JSON 경로/위치 진단',
  );
  for (final target in composer.targets) {
    final plan = composer.planFiles(root, target, 'my_app');
    check(plan['pubspec.yaml']!.contains('name: my_app'), '이름 반영');
    check(plan.containsKey('lib/core/di.dart'), '메인 DI');
    check(
      plan['lib/main.dart']!.contains(
        'MobileApp(dependencies: createAppDependencies())',
      ),
      '앱 진입·의존성 전달',
    );
    check(
      !plan['lib/core/di.dart']!.contains('package:flutter/'),
      'DI의 Widget 분리',
    );
    check(plan.containsKey('Gemfile') == (target != 'android'), '선택 OS 도구');
    check(
      plan.containsKey('docs/04-features.md') &&
          plan.containsKey('docs/05-structure.md') &&
          plan.containsKey('docs/06-build-and-release.md'),
      '일관된 읽기 순서',
    );
    check(
      !plan.keys.any(
        (path) =>
            (path.startsWith('lib/services/') ||
                path.startsWith('lib/apis/')) &&
            path.endsWith('.dart'),
      ),
      '기능 소스 미포함',
    );
    check(
      plan.keys
              .where(
                (path) => path.startsWith('test/') && path.endsWith('.dart'),
              )
              .toList()
              .single ==
          'test/app_test.dart',
      '기능 검사 미포함',
    );
    check(
      !plan['pubspec.yaml']!.contains('universal_ble') &&
          !plan['pubspec.yaml']!.contains('mqtt_client'),
      '기능 패키지 미포함',
    );
    check(plan['docs/04-features.md']!.contains('구성품을 직접 복사'), '수동 복사 안내');
    for (final id in ['api', 'ble', 'tcp', 'udp', 'mqtt', 'log']) {
      final doc = plan.entries
          .singleWhere(
            (entry) =>
                entry.key.startsWith('docs/features/') &&
                entry.key.endsWith('-$id.md'),
          )
          .value;
      final sourceGuide = File(
        '${root.path}/components/03-features/$id/files/docs/04-features.md',
      );
      check(
        sourceGuide.existsSync() &&
            sourceGuide.readAsStringSync().contains(
              '../../../../../docs/02-manual-features.md',
            ),
        '원본 기능 문서의 공통 안내 연결',
      );
      check(
        doc.contains('## DI 등록·초기화') && doc.contains('## 사용 버전 기록·변경'),
        '기능별 연결/버전 안내',
      );
    }
    check(
      !plan.entries
          .where(
            (entry) =>
                entry.key.endsWith('.dart') ||
                entry.key.endsWith('.yaml') ||
                entry.key == 'README.md',
          )
          .any((entry) => entry.value.contains('{{')),
      '실행 파일 미치환 값',
    );
  }
  stdout.writeln('이름·식별자·경로·OS 구성·수동 문서·기능 코드 미포함 확인 완료. 앱 생성/빌드 검사는 아닙니다.');
}
