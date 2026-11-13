import 'dart:developer' as developer;

class LogService {
  void event(String code, {int level = 800}) {
    if (!RegExp(r'^[a-z][a-z0-9_.]{0,79}$').hasMatch(code) ||
        level < 0 ||
        level > 2000) {
      throw ArgumentError('Log event code or level');
    }
    developer.log(code, name: 'app', level: level);
  }
}
