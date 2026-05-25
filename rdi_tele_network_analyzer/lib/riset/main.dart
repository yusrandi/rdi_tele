import 'package:flutter/material.dart';
import 'package:realspeed_analyzer/riset/ping/pages/speed_test_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SpeedTestPage(),
    );
  }
}
