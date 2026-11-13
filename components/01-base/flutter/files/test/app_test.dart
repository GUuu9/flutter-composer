import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{name}}/core/app.dart';
import 'package:{{name}}/core/di.dart';

void main() {
  testWidgets('Starts an empty application', (tester) async {
    await tester.pumpWidget(MobileApp(dependencies: createAppDependencies()));
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Hello World!'), findsNothing);
  });
}
