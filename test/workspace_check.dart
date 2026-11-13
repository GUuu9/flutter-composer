import 'dart:convert';
import 'dart:io';
import '../scripts/workspace.dart' as workspace;

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

void rejects(void Function() action) {
  try {
    action();
  } on StateError {
    return;
  }
  throw StateError('잘못된 입력을 허용했습니다.');
}

void main() {
  final root = Directory.systemTemp.createTempSync('flutter-workspace-check-');
  try {
    final project = Directory.fromUri(root.uri.resolve('project/'))
      ..createSync();
    for (final name in ['beta', 'alpha', '.hidden']) {
      Directory.fromUri(project.uri.resolve('$name/')).createSync();
    }
    File.fromUri(project.uri.resolve('note.txt')).writeAsStringSync('keep');
    if (!Platform.isWindows) {
      Link.fromUri(project.uri.resolve('linked')).createSync(root.path);
    }
    check(workspace.listProjects(root).join(',') == 'alpha,beta', '실제 폴더만 정렬');
    for (final answer in ['0', '3', '1,1', '1,', '../alpha', '01']) {
      rejects(() => workspace.selectProjects(answer, ['alpha', 'beta']));
    }
    check(
      workspace.createWorkspace(root, (_) => '', report: (_) {}) == null,
      'Enter 취소',
    );
    final file = workspace.createWorkspace(root, (_) => '2,1', report: (_) {})!;
    final data = jsonDecode(file.readAsStringSync()) as Map;
    check(data['folders'][0]['path'] == '.', 'Composer 포함');
    check(data['folders'][1]['path'] == 'project/beta', '선택 순서');
    final previous = file.readAsStringSync();
    final answers = ['1', 'n'].iterator;
    workspace.createWorkspace(root, (_) {
      answers.moveNext();
      return answers.current;
    }, report: (_) {});
    check(file.readAsStringSync() == previous, '교체 거절 보존');
    final yes = ['1', 'yes'].iterator;
    workspace.createWorkspace(root, (_) {
      yes.moveNext();
      return yes.current;
    }, report: (_) {});
    check(
      (jsonDecode(file.readAsStringSync())['folders'] as List).length == 2,
      '확인 후 교체',
    );
    final race = ['1', 'yes'].iterator;
    rejects(
      () => workspace.createWorkspace(root, (_) {
        race.moveNext();
        if (race.current == 'yes') file.writeAsStringSync('changed');
        return race.current;
      }, report: (_) {}),
    );
    check(file.readAsStringSync() == 'changed', '동시 변경 보존');
    check(
      File.fromUri(project.uri.resolve('note.txt')).readAsStringSync() ==
          'keep',
      '앱 파일 보존',
    );
    file.deleteSync();
    Directory(file.path).createSync();
    rejects(() => workspace.createWorkspace(root, (_) => '1', report: (_) {}));
    print('workspace checks passed');
  } finally {
    root.deleteSync(recursive: true);
  }
}
