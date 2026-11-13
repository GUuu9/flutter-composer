import 'dart:async';
import 'dart:convert';
import 'dart:io';

const targets = ['android', 'ios', 'android-ios'];
const forbiddenNames = {
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'get',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'set',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'while',
  'with',
  'yield',
  'con',
  'prn',
  'aux',
  'nul',
};

bool validName(String value) =>
    RegExp(r'^[a-z][a-z0-9_]{0,63}$').hasMatch(value) &&
    !forbiddenNames.contains(value) &&
    !RegExp(r'^(com|lpt)[1-9]$').hasMatch(value);
bool validOrganization(String value) =>
    RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$').hasMatch(value);
bool validAndroidId(String value) => RegExp(
  r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
).hasMatch(value);
bool validIosId(String value) => RegExp(
  r'^[a-zA-Z][a-zA-Z0-9-]*(\.[a-zA-Z][a-zA-Z0-9-]*)+$',
).hasMatch(value);

bool safeRelativePath(String value) =>
    value.isNotEmpty &&
    !value.startsWith('/') &&
    !value.contains('\\') &&
    !value.contains(':') &&
    !value.contains(String.fromCharCode(0)) &&
    !value
        .split('/')
        .any(
          (part) =>
              part.isEmpty ||
              part == '.' ||
              part == '..' ||
              part == '.git' ||
              part == '.composer',
        );

List<String> platformsFor(Directory root, String target) {
  if (!targets.contains(target)) throw ArgumentError('지원하지 않는 구성');
  final declaration = readJson(
    '${root.path}/components/02-targets/$target/compose.json',
  );
  final platforms = (declaration['platforms'] as List).cast<String>();
  if (declaration['id'] != target ||
      platforms.toSet().length != platforms.length ||
      (target == 'android-ios'
          ? platforms.length != 2 ||
                !platforms.contains('android') ||
                !platforms.contains('ios')
          : platforms.length != 1 || platforms.single != target)) {
    throw StateError('플랫폼 선언과 구성 식별자가 다릅니다.');
  }
  return platforms;
}

String iosIdentifier(String organization, String name) {
  // Flutter 3.35.7 createUTIIdentifier/camelCase와 동일한 변환입니다.
  var value = name;
  var index = value.indexOf('_');
  while (index != -1 && index < value.length - 2) {
    value =
        value.substring(0, index) +
        value.substring(index + 1, index + 2).toUpperCase() +
        value.substring(index + 2);
    index = value.indexOf('_');
  }
  return '$organization.${value.replaceAll('_', '')}';
}

String ask(String message, bool Function(String) validate) {
  while (true) {
    stdout.write('$message: ');
    final line = stdin.readLineSync();
    if (line == null) throw StateError('입력이 취소되었습니다.');
    final value = line.trim();
    if (validate(value)) return value;
    stderr.writeln('입력 형식을 확인해 주세요.');
  }
}

class JsonFileFormatException extends FormatException {
  JsonFileFormatException(this.path, int? offset)
    : super('JSON 파일 형식 오류', null, offset);
  final String path;
}

Map<String, dynamic> readJson(String path) {
  try {
    final value = jsonDecode(File(path).readAsStringSync());
    if (value is! Map<String, dynamic>)
      throw JsonFileFormatException(path, null);
    return value;
  } on JsonFileFormatException {
    rethrow;
  } on FormatException catch (error) {
    throw JsonFileFormatException(path, error.offset);
  }
}

// 실제 비교 전 양쪽 경로는 resolveSymbolicLinksSync로 해석합니다.
bool isPathWithin(String path, String parent, {bool? windows}) {
  final useWindows = windows ?? Platform.isWindows;
  String key(String value) {
    return Uri.directory(
      useWindows ? value.toLowerCase() : value,
      windows: useWindows,
    ).normalizePath().toString();
  }

  final childKey = key(path);
  final parentKey = key(parent);
  return childKey != parentKey && childKey.startsWith(parentKey);
}

Map<String, Object?> failureDetails(Object error) {
  final result = <String, Object?>{'type': error.runtimeType.toString()};
  if (error is JsonFileFormatException) {
    result.addAll({
      'message': error.message,
      'path': error.path,
      'offset': error.offset,
    });
  } else if (error is FileSystemException) {
    result.addAll({
      'message': '파일/폴더 접근 실패',
      'path': error.path,
      'osErrorCode': error.osError?.errorCode,
    });
  } else if (error is ProcessException) {
    result.addAll({
      'message': '외부 도구 실행 실패',
      'executable': error.executable,
      'osErrorCode': error.errorCode,
    });
  } else if (error is FormatException) {
    result['message'] = '입력/설정 형식 오류 (본문 생략)';
  } else if (error is StateError) {
    result['message'] = error.message;
  } else {
    result['message'] = '예상하지 못한 오류. 기록된 단계의 입력/설정을 확인하세요.';
  }
  return result;
}

String render(String source, String name, String target) {
  final docs = <String>[
    if (target != 'ios') '2. [Android 준비](docs/02-android.md)',
    if (target != 'android') '3. [iOS 준비](docs/03-ios.md)',
  ].join('\n');
  return source
      .replaceAll('{{name}}', name)
      .replaceAll('{{target}}', target)
      .replaceAll('{{platformDocs}}', docs);
}

Map<String, String> planFiles(Directory root, String target, String name) {
  if (!targets.contains(target) || !validName(name))
    throw ArgumentError('구성/이름 오류');
  final platforms = platformsFor(root, target);
  final planned = <String, String>{};
  final components = [
    '00-common/project',
    '01-base/flutter',
    '02-targets/$target',
  ];
  for (final component in components) {
    final directory = Directory('${root.path}/components/$component');
    final declaration = readJson('${directory.path}/compose.json');
    for (final key in ['replace', 'remove', 'nativeOverrides']) {
      for (final path in declaration[key] as List? ?? []) {
        if (path is! String || !safeRelativePath(path))
          throw StateError('구성품 소유 경로 오류');
      }
    }
    final directories = [directory];
    for (final include in declaration['includeFiles'] as List? ?? []) {
      if (!['02-targets/android', '02-targets/ios'].contains(include) ||
          !platforms.contains((include as String).split('/').last))
        throw StateError('지원하지 않는 구성품 참조');
      directories.add(Directory('${root.path}/components/$include'));
    }
    for (final source in directories) {
      if (!isPathWithin(
        source.resolveSymbolicLinksSync(),
        Directory('${root.path}/components').resolveSymbolicLinksSync(),
      ))
        throw StateError('구성품이 원본 밖을 참조합니다.');
      final filesDirectory = Directory('${source.path}/files');
      final prefixLength = filesDirectory.absolute.uri
          .normalizePath()
          .pathSegments
          .where((part) => part.isNotEmpty)
          .length;
      for (final entity in filesDirectory.listSync(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is Link) throw StateError('구성품 링크는 지원하지 않습니다.');
        if (entity is! File) continue;
        final path = entity.absolute.uri
            .normalizePath()
            .pathSegments
            .where((part) => part.isNotEmpty)
            .skip(prefixLength)
            .join('/');
        if (!safeRelativePath(path)) throw StateError('출력 경로 오류');
        for (final platform in ['android', 'ios']) {
          if (path.startsWith('$platform/') && !platforms.contains(platform))
            throw StateError('미선택 플랫폼 파일');
        }
        final content = render(entity.readAsStringSync(), name, target);
        if (planned.containsKey(path) &&
            !(path.endsWith('.gitkeep') &&
                content.isEmpty &&
                planned[path]!.isEmpty)) {
          throw StateError('구성품 파일 충돌: $path');
        }
        planned[path] = content;
      }
    }
  }
  addManualFeatureDocs(root, planned);
  return planned;
}

void addManualFeatureDocs(Directory root, Map<String, String> planned) {
  var guide = File(
    '${root.path}/docs/02-manual-features.md',
  ).readAsStringSync();
  for (final feature in Directory(
    '${root.path}/components/03-features',
  ).listSync(followLinks: false)) {
    if (feature is Link) throw StateError('기능 문서 링크는 지원하지 않습니다.');
    if (feature is! Directory) continue;
    final id = feature.absolute.uri.pathSegments
        .where((part) => part.isNotEmpty)
        .last;
    final source = Directory('${feature.path}/files/docs/features');
    if (!isPathWithin(
      source.resolveSymbolicLinksSync(),
      Directory('${root.path}/components').resolveSymbolicLinksSync(),
    )) {
      throw StateError('기능 문서가 구성품 밖을 참조합니다.');
    }
    for (final file in source.listSync(followLinks: false)) {
      if (file is! File || !file.path.endsWith('.md'))
        throw StateError('기능 문서는 일반 Markdown 파일만 허용합니다.');
      final name = file.absolute.uri.pathSegments.last;
      if (!safeRelativePath(name)) throw StateError('기능 문서 경로 오류');
      final path = 'docs/features/$name';
      if (planned.containsKey(path)) throw StateError('기능 문서 충돌: $path');
      planned[path] = file.readAsStringSync();
    }
    guide = guide.replaceAll(
      '../components/03-features/$id/files/docs/features/',
      'features/',
    );
  }
  if (planned.containsKey('docs/04-features.md'))
    throw StateError('수동 안내 문서 충돌');
  planned['docs/04-features.md'] = guide;
}

void replaceMatches(
  File file,
  Pattern pattern,
  String replacement, {
  int? expected,
}) {
  final source = file.readAsStringSync();
  final count = pattern.allMatches(source).length;
  if (count == 0 || (expected != null && count != expected)) {
    throw StateError('SDK 생성 파일 형식이 다릅니다: ${file.path}');
  }
  file.writeAsStringSync(source.replaceAll(pattern, replacement));
}

void configurePlatforms(
  Directory app,
  List<String> platforms,
  Map<String, dynamic> versions,
) {
  if (platforms.contains('android')) {
    final settings = File('${app.path}/android/settings.gradle.kts');
    for (final plugin in {
      'com.android.application': 'agp',
      'org.jetbrains.kotlin.android': 'kotlin',
    }.entries) {
      replaceMatches(
        settings,
        RegExp('id\\("${RegExp.escape(plugin.key)}"\\) version "[^"]+"'),
        'id("${plugin.key}") version "${versions[plugin.value]}"',
        expected: 1,
      );
    }
    replaceMatches(
      File('${app.path}/android/gradle/wrapper/gradle-wrapper.properties'),
      RegExp(r'gradle-[0-9.]+-all\.zip'),
      'gradle-${versions['gradle']}-all.zip',
      expected: 1,
    );
    final build = File('${app.path}/android/app/build.gradle.kts');
    for (final field in ['compileSdk', 'minSdk', 'targetSdk']) {
      replaceMatches(
        build,
        RegExp('$field = flutter\\.$field' + r'Version'),
        '$field = ${versions[field]}',
        expected: 1,
      );
    }
    replaceMatches(
      build,
      RegExp(r'JavaVersion.VERSION_[0-9]+'),
      'JavaVersion.VERSION_${versions['javaTarget']}',
      expected: 3,
    );
    replaceMatches(
      build,
      'compileSdk = ${versions['compileSdk']}',
      'compileSdk = ${versions['compileSdk']}\n    buildToolsVersion = \"${versions['buildTools']}\"',
      expected: 1,
    );
    replaceMatches(
      build,
      RegExp(r'ndkVersion = flutter\.ndkVersion'),
      'ndkVersion = "${versions['ndk']}"',
      expected: 1,
    );
  }
  if (platforms.contains('ios')) {
    replaceMatches(
      File('${app.path}/ios/Runner.xcodeproj/project.pbxproj'),
      RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;'),
      'IPHONEOS_DEPLOYMENT_TARGET = ${versions['iosMinimum']};',
    );
    replaceMatches(
      File('${app.path}/ios/Flutter/AppFrameworkInfo.plist'),
      RegExp(r'<key>MinimumOSVersion</key>\s*<string>[0-9.]+</string>'),
      '<key>MinimumOSVersion</key>\n  <string>${versions['iosMinimum']}</string>',
      expected: 1,
    );
    final podfile = File('${app.path}/ios/Podfile');
    if (podfile.existsSync()) {
      replaceMatches(
        podfile,
        RegExp(r"#?\s*platform :ios, '[0-9.]+'"),
        "platform :ios, '${versions['iosMinimum']}'",
        expected: 1,
      );
    }
  }
}

Future<void> main(List<String> arguments) async {
  if (arguments.isNotEmpty) {
    stderr.writeln('대화형 명령만 지원합니다: fvm dart run scripts/compose.dart');
    exitCode = 64;
    return;
  }
  final root = File(
    File.fromUri(Platform.script).resolveSymbolicLinksSync(),
  ).parent.parent;
  Directory? app;
  Process? process;
  var cancelled = false;
  var stage = 'input';
  Map<String, dynamic> state = {};
  void record(String status) {
    if (app == null) return;
    final directory = Directory('${app!.path}/.composer')..createSync();
    File('${directory.path}/state.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({...state, 'status': status, 'stage': stage})}\n',
    );
  }

  StreamSubscription<ProcessSignal>? interrupt;
  try {
    final versions = readJson('${root.path}/versions.json');
    final sdk = File(
      Platform.resolvedExecutable,
    ).parent.parent.parent.parent.parent;
    final installed = readJson('${sdk.path}/bin/cache/flutter.version.json');
    if (installed['frameworkVersion'] != versions['flutter'] ||
        installed['dartSdkVersion'] != versions['dart']) {
      throw StateError('FVM의 지정 SDK와 versions.json이 일치해야 합니다.');
    }
    final target = ask('구성 (${targets.join(' / ')})', targets.contains);
    final organization = ask(
      '조직 식별자 (직접 지정, 예: com.yourcompany)',
      validOrganization,
    );
    final name = ask('프로젝트/Dart package 이름 (snake_case, 마지막 입력)', validName);
    final androidId = '$organization.$name';
    final iosId = iosIdentifier(organization, name);
    final platforms = platformsFor(root, target);
    if (platforms.contains('android') && !validAndroidId(androidId))
      throw StateError('Android applicationId 오류');
    if (platforms.contains('ios') && !validIosId(iosId))
      throw StateError('iOS bundle identifier 오류');
    final plan = planFiles(root, target, name);
    final parent = Directory('${root.path}/project');
    if (FileSystemEntity.typeSync(parent.path, followLinks: false) ==
        FileSystemEntityType.link)
      throw StateError('project 링크는 지원하지 않습니다.');
    final destination = '${parent.path}/$name';
    if (FileSystemEntity.typeSync(destination, followLinks: false) !=
        FileSystemEntityType.notFound)
      throw StateError('기존 목적지는 변경하지 않습니다.');
    stdout.writeln(
      '구성: $target\n이름: $name\nFlutter: ${versions['flutter']}\n출력: $destination',
    );
    if (platforms.contains('android'))
      stdout.writeln('Android applicationId: $androidId');
    if (platforms.contains('ios'))
      stdout.writeln('iOS bundle identifier: $iosId');
    if (ask('위 식별자로 생성할까요? (yes/no)', (v) => v == 'yes' || v == 'no') != 'yes')
      return;
    interrupt = ProcessSignal.sigint.watch().listen((_) {
      cancelled = true;
      process?.kill();
    });
    if (cancelled) throw StateError('취소');
    parent.createSync(recursive: true);
    app = Directory(destination)..createSync();
    state = {
      'schema': 1,
      'target': target,
      'name': name,
      'platforms': platforms,
      'organization': organization,
      'androidApplicationId': platforms.contains('android') ? androidId : null,
      'iosBundleIdentifier': platforms.contains('ios') ? iosId : null,
      'versions': versions,
      'active': false,
    };
    stage = 'flutter-create';
    record('creating');
    final command =
        '${sdk.path}/bin/flutter${Platform.isWindows ? '.bat' : ''}';
    process = await Process.start(
      command,
      [
        '--no-version-check',
        'create',
        '--empty',
        '--no-pub',
        '--platforms=${platforms.join(',')}',
        '--org',
        organization,
        '--project-name',
        name,
        destination,
      ],
      mode: ProcessStartMode.inheritStdio,
      runInShell: Platform.isWindows,
    );
    if (cancelled) process!.kill();
    final result = await process!.exitCode;
    process = null;
    if (result != 0 || cancelled) throw StateError('Flutter 생성 실패/취소');
    if (platforms.contains('android') &&
        !File(
          '${app!.path}/android/app/build.gradle.kts',
        ).readAsStringSync().contains('applicationId = "$androidId"')) {
      throw StateError('SDK가 만든 Android 식별자가 확인한 값과 다릅니다.');
    }
    if (platforms.contains('ios') &&
        !File(
          '${app!.path}/ios/Runner.xcodeproj/project.pbxproj',
        ).readAsStringSync().contains('PRODUCT_BUNDLE_IDENTIFIER = $iosId;')) {
      throw StateError('SDK가 만든 iOS 식별자가 확인한 값과 다릅니다.');
    }
    stage = 'overlay';
    record('creating');
    final ownership = <String>{};
    final removable = <String>{};
    for (final component in [
      '00-common/project',
      '01-base/flutter',
      '02-targets/$target',
    ]) {
      final declaration = readJson(
        '${root.path}/components/$component/compose.json',
      );
      ownership.addAll((declaration['replace'] as List? ?? []).cast<String>());
      removable.addAll((declaration['remove'] as List? ?? []).cast<String>());
    }
    for (final entry in plan.entries) {
      final file = File('${app!.path}/${entry.key}');
      if (file.existsSync() &&
          !ownership.contains(entry.key) &&
          !entry.key.endsWith('.gitkeep'))
        throw StateError('공식 생성 파일 충돌: ${entry.key}');
    }
    for (final entry in plan.entries) {
      final file = File('${app!.path}/${entry.key}');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(entry.value);
    }
    for (final path in removable) {
      final file = File('${app!.path}/$path');
      if (file.existsSync()) file.deleteSync();
    }
    File(
      '${app!.path}/.fvmrc',
    ).writeAsStringSync('${jsonEncode({'flutter': versions['flutter']})}\n');
    File('${app!.path}/versions.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(versions)}\n',
    );
    final ignore = File('${app!.path}/.gitignore');
    var ignoreText = ignore.existsSync() ? ignore.readAsStringSync() : '';
    for (final line in ['.fvm/', '.env', '.bundle/', 'vendor/bundle/']) {
      if (!ignoreText.split('\n').contains(line)) ignoreText += '\n$line\n';
    }
    ignore.writeAsStringSync(ignoreText);
    stage = 'platform-configuration';
    record('creating');
    configurePlatforms(app!, platforms, versions);
    if (cancelled) throw StateError('취소');
    stage = 'complete';
    state['ownedFiles'] = [
      ...plan.keys,
      '.fvmrc',
      'versions.json',
      '.gitignore',
    ];
    state['nativeOverrides'] = [
      ...(readJson(
            '${root.path}/components/02-targets/$target/compose.json',
          )['nativeOverrides']
          as List),
    ];
    record('generated-unverified');
    stdout.writeln(
      '앱 소스 생성 완료. 설치·분석·테스트·빌드는 미실행입니다.\n앱 README의 준비/검사 과정을 따르세요.\n기능을 추가할 때 docs/04-features.md를 따르세요.',
    );
  } catch (error) {
    final details = failureDetails(error);
    state['failure'] = details;
    stderr.writeln('오류: ${jsonEncode(details)}');
    try {
      record(cancelled ? 'cancelled' : 'failed');
    } catch (recordError) {
      stderr.writeln('진단 저장 실패: ${jsonEncode(failureDetails(recordError))}');
    }
    if (app == null) {
      stderr.writeln(
        '생성 중단: $stage. 앱 출력은 생성하지 않았습니다. 위 오류의 파일/SDK/입력을 확인하세요.',
      );
    } else {
      stderr.writeln(
        '생성 중단: $stage. 출력은 ${app!.path}에 보존합니다. 저장에 성공한 진단은 .composer/state.json의 failure에서 확인하세요.\n기존 출력에 재실행하거나 state를 고쳐 우회하지 마세요.',
      );
    }

    exitCode = cancelled ? 130 : 1;
  } finally {
    await interrupt?.cancel();
  }
}
