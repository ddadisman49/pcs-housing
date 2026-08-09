import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'navigation/main_navigation.dart';

class PCSHousingApp extends StatelessWidget {
  const PCSHousingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PCS Housing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const MainNavigation(),
    );
  }
}