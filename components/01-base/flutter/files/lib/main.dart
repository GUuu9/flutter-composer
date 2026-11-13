import 'package:flutter/widgets.dart';
import 'core/app.dart';
import 'core/di.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MobileApp(dependencies: createAppDependencies()));
}
