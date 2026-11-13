import 'package:flutter_test/flutter_test.dart';
import 'package:{{name}}/apis/http/http_api.dart';

void main() {
  test('api: rejects invalid input and disposed use without I/O', () async {
    final api = HttpApi();
    await expectLater(
      api.request('GET', Uri.parse('http://localhost')),
      throwsArgumentError,
    );
    api.dispose();
    await expectLater(
      api.request('GET', Uri.parse('https://localhost')),
      throwsStateError,
    );
  });
}
