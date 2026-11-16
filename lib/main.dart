import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const MyFitDayApp());
}

class MyFitDayApp extends StatelessWidget {
  const MyFitDayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyFitDay AI',
      debugShowCheckedModeBanner:
          false, // Sağ üstteki kırmızı Debug yazısını gizler
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(), // Uygulama açıldığında ilk bu sayfa yüklenecek
    );
  }
}
