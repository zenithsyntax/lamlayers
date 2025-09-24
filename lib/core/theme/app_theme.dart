import 'package:flutter/material.dart';
import 'package:lamlayers/core/constants/app_colors.dart';
import 'package:lamlayers/core/constants/app_text_styles.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.background,
    iconTheme: const IconThemeData(color: AppColors.icon),

    // Apply Google Font to your textTheme
    textTheme: TextTheme(
      bodySmall: GoogleFonts.inter(textStyle: AppTextStyles.small),
      bodyMedium: GoogleFonts.inter(textStyle: AppTextStyles.regular),
      bodyLarge: GoogleFonts.inter(textStyle: AppTextStyles.medium),
      titleMedium: GoogleFonts.inter(textStyle: AppTextStyles.large),
      titleLarge: GoogleFonts.inter(textStyle: AppTextStyles.extraLarge),
    ),

    cardColor: AppColors.container,
    useMaterial3: true,
  );
}


// @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Theme Demo", style: Theme.of(context).textTheme.titleLarge),
//       ),
//       body: Center(
//         child: Container(
//           color: Theme.of(context).cardColor,
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text("Small", style: Theme.of(context).textTheme.bodySmall),
//               Text("Regular", style: Theme.of(context).textTheme.bodyMedium),
//               Text("Medium", style: Theme.of(context).textTheme.bodyLarge),
//               Text("Large", style: Theme.of(context).textTheme.titleMedium),
//               Text("Extra Large", style: Theme.of(context).textTheme.titleLarge),
//               const Icon(Icons.home),
//             ],
//           ),
//         ),