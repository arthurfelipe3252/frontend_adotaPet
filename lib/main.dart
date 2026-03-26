import 'package:flutter/material.dart';
import 'package:adota_pet/core/network/http_client.dart';

void main() {
  final client = HttpClient();

  runApp(const AdotaPetApp());
}

class AdotaPetApp extends StatelessWidget {
  const AdotaPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AdotaPet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('AdotaPet'),
        ),
      ),
    );
  }
}
