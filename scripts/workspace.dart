import 'dart:convert';
import 'dart:io';

const workspaceName = 'flutter-composer.local.code-workspace';

void requireDirectory(Directory directory) {
  if (FileSystemEntity.typeSync(directory.path, followLinks: false) !=
      FileSystemEntityType.directory) {
    throw StateError('실제 디렉터리가 아닙니다: ${directory.path}');
  }
}

List<String> listProjects(Directory root) {
  final directory = Directory.fromUri(root.uri.resolve('project/'));
  requireDirectory(directory);
  return directory
      .listSync(followLinks: false)
      .whereType<Directory>()
      .map((entry) => entry.uri.pathSegments.where((s) => s.isNotEmpty).last)
      .where((name) => !name.startsWith('.'))
      .toList()
    ..sort();
}

List<String> selectProjects(String answer, List<String> projects) {
  final selected = <int>{};
  for (final value in answer.split(',')) {
    final text = value.trim();
    final number = int.tryParse(text);
    if (!RegExp(r'^[1-9]\d*$').hasMatch(text) ||
        number == null ||
        number > projects.length ||
        !selected.add(number)) {
      throw StateError('중복 없이 목록의 번호를 쉼표로 구분하세요.');
    }
  }
  return selected.map((number) => projects[number - 1]).toList();
}

String? readWorkspace(File file) {
  final type = FileSystemEntity.typeSync(file.path, followLinks: false);
  if (type == FileSystemEntityType.notFound) return null;
  if (type != FileSystemEntityType.file) {
    throw StateError('workspace 경로가 일반 파일이 아닙니다.');
  }
  return file.readAsStringSync();
}

File? createWorkspace(
  Directory root,
  String Function(String) ask, {
  void Function(String) report = print,
}) {
  final projects = listProjects(root);
  if (projects.isEmpty) {
    report('선택할 프로젝트 폴더가 없습니다.');
    return null;
  }
  for (var index = 0; index < projects.length; index++) {
    report('${index + 1}. ${projects[index]}');
  }
  final answer = ask('함께 열 폴더 번호 (쉼표 구분, Enter 취소): ').trim();
  if (answer.isEmpty) return null;
  final selected = selectProjects(answer, projects);
  final destination = File.fromUri(root.uri.resolve(workspaceName));
  final previous = readWorkspace(destination);
  if (previous != null &&
      ![
        'y',
        'yes',
      ].contains(ask('기존 workspace를 교체할까요? (y/N): ').trim().toLowerCase())) {
    return null;
  }
  requireDirectory(Directory.fromUri(root.uri.resolve('project/')));
  for (final name in selected) {
    requireDirectory(
      Directory.fromUri(
        root.uri.resolveUri(Uri(pathSegments: ['project', name, ''])),
      ),
    );
  }
  final contents =
      '${const JsonEncoder.withIndent('  ').convert({
        'folders': [
          {'name': 'flutter-composer', 'path': '.'},
          for (final name in selected) {'path': 'project/$name'},
        ],
        'settings': {'git.autoRepositoryDetection': true},
      })}\n';
  final temporary = root.createTempSync('.workspace-');
  try {
    final output = File.fromUri(temporary.uri.resolve(workspaceName));
    output.writeAsStringSync(contents, flush: true);
    if (readWorkspace(destination) != previous) {
      throw StateError('workspace가 변경되었습니다. 다시 실행하세요.');
    }
    output.renameSync(destination.path);
  } finally {
    temporary.deleteSync(recursive: true);
  }
  report('생성: ${destination.path}\nVS Code에서 해당 workspace 파일을 여세요.');
  return destination;
}

void main(List<String> arguments) {
  try {
    if (arguments.isNotEmpty || !stdin.hasTerminal || !stdout.hasTerminal) {
      throw StateError(
        'fvm dart run scripts/workspace.dart를 인자 없이 터미널에서 실행하세요.',
      );
    }
    createWorkspace(File.fromUri(Platform.script).parent.parent, (question) {
      stdout.write(question);
      final answer = stdin.readLineSync();
      if (answer == null) throw StateError('입력이 종료되어 취소했습니다.');
      return answer;
    });
  } on StateError catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln(
      'workspace 파일 작업 실패: ${error.path} (OS 코드 ${error.osError?.errorCode})',
    );
    exitCode = 1;
  }
}
