import 'package:flutter/material.dart';
import 'di.dart';

class MobileApp extends StatelessWidget {
  const MobileApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: SizedBox.shrink()),
  );
}
