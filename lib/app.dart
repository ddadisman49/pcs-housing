import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';

class PCSHousingApp extends StatelessWidget {
  const PCSHousingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCS Housing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}