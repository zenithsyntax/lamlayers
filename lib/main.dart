import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lamlayers/canvas_screen.dart';
import 'package:lamlayers/core/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Lamlayers());
}

class Lamlayers extends StatelessWidget {
  const Lamlayers({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X reference
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => MaterialApp(
        title: 'Flutter Theme Demo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          textTheme: GoogleFonts.interTextTheme(AppTheme.lightTheme.textTheme),
        ),
        home: PosterMakerScreen(),
      ),
    );
  }
}
