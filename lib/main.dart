import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'screens/poster_maker_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PosterMakerApp());
}

class PosterMakerApp extends StatelessWidget {
  const PosterMakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      builder: (context, child) => MaterialApp(
        title: 'Poster Maker',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        home: const PosterMakerScreen(),
      ),
    );
  }
}


