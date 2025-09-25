import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:lamlayers/screens/home_screen.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDirectory.path);

  // Register Adapters
  Hive.registerAdapter(PosterProjectAdapter());
  Hive.registerAdapter(ProjectSettingsAdapter());
  Hive.registerAdapter(ExportSettingsAdapter());
  Hive.registerAdapter(HiveCanvasItemAdapter());
  Hive.registerAdapter(HiveOffsetAdapter());
  Hive.registerAdapter(HiveColorAdapter());
  Hive.registerAdapter(HiveSizeAdapter());
  Hive.registerAdapter(HiveCanvasItemTypeAdapter());
  Hive.registerAdapter(ExportFormatAdapter());
  Hive.registerAdapter(ExportQualityAdapter());
  Hive.registerAdapter(HiveCanvasActionAdapter());
  Hive.registerAdapter(ActionTypeAdapter());
  Hive.registerAdapter(HiveTextPropertiesAdapter());
  Hive.registerAdapter(HiveImagePropertiesAdapter());
  Hive.registerAdapter(HiveShapePropertiesAdapter());
  Hive.registerAdapter(HiveStickerPropertiesAdapter());
  Hive.registerAdapter(ProjectTemplateAdapter());
  Hive.registerAdapter(UserPreferencesAdapter());
  Hive.registerAdapter(ColorAdapter()); // Register the new ColorAdapter

  await Hive.openBox<PosterProject>('posterProjects');
  await Hive.openBox<UserPreferences>('userPreferences');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
        home: child,
      ),
      child: const HomeScreen(),
    );
  }
}


