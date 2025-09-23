import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.cyan,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.canvasColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvasColor,
        foregroundColor: AppColors.primaryColor,
      ),
      cardColor: AppColors.cardColor,
      dividerColor: AppColors.borderColor,
    );
  }
}