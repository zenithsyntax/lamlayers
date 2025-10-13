import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:lamlayers/screens/home_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:lamlayers/utils/export_manager.dart';
import 'package:lamlayers/screens/poster_maker_screen.dart';
import 'package:lamlayers/screens/lambook_reader_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Google Mobile Ads SDK
  await MobileAds.instance.initialize();
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDirectory.path);

  // Register Adapters
  Hive.registerAdapter(ScrapbookAdapter());
  Hive.registerAdapter(PosterProjectAdapter());
  Hive.registerAdapter(ProjectSettingsAdapter());
  Hive.registerAdapter(ExportSettingsAdapter());
  Hive.registerAdapter(HiveCanvasItemAdapter());
  Hive.registerAdapter(OffsetAdapter());
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
  Hive.registerAdapter(FontWeightAdapter()); // Register FontWeightAdapter
  Hive.registerAdapter(FontStyleAdapter()); // Register FontStyleAdapter
  Hive.registerAdapter(TextAlignAdapter()); // Register TextAlignAdapter

  await Hive.openBox<PosterProject>('posterProjects');
  await Hive.openBox<Scrapbook>('scrapbooks');
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
        home: DeepLinkHost(child: child ?? const HomePage()),
      ),
      child: const HomePage(),
    );
  }
}

class DeepLinkHost extends StatefulWidget {
  final Widget child;
  const DeepLinkHost({Key? key, required this.child}) : super(key: key);

  @override
  State<DeepLinkHost> createState() => _DeepLinkHostState();
}

class _DeepLinkHostState extends State<DeepLinkHost> {
  static const MethodChannel _channel = MethodChannel(
    'com.lamlayers/deep_links',
  );
  // No stream subscription needed; using MethodChannel callbacks.

  @override
  void initState() {
    super.initState();
    // Set method call handler to receive opened file paths
    _channel.setMethodCallHandler(_handleMethodCall);
    // Notify native we're ready to receive any pending deep link
    // ignore: unawaited_futures
    _channel.invokeMethod('ready');
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'openedFile') {
      final Map args = (call.arguments as Map?) ?? {};
      final String? path = args['path'] as String?;
      final String? uri = args['uri'] as String?;
      final String? candidate = path ?? uri;
      if (candidate == null) return null;

      // Normalize to file path where possible
      String normalized = candidate;
      if (normalized.startsWith('file://')) {
        normalized = normalized.replaceFirst('file://', '');
      }

      // Handle .lamlayers (poster project) directly via existing loader
      if (normalized.toLowerCase().endsWith('.lamlayers')) {
        await _openLamlayersProject(normalized);
        return null;
      }

      // Try to handle as a .lambook regardless of extension (some providers strip it)
      // Debug log
      // ignore: avoid_print
      print('DeepLinkHost: attempting to open as lambook -> ' + normalized);

      int _progress = 1;
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setState) {
                return Dialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Opening book...',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: _progress.clamp(1, 100) / 100,
                        ),
                        const SizedBox(height: 8),
                        Text('$_progress%'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }

      final data = await ExportManager.loadLambook(
        normalized,
        onProgress: (p) {
          _progress = p;
          // try updating dialog if still mounted
          if (mounted) {
            // Force rebuild of dialog via Navigator overlay by popping and re-showing would flicker.
            // Instead, rely on StatefulBuilder above: call setState captured there via context.
            // Since we don't hold setState reference here, use Navigator to find current route's widget tree rebuild via addPostFrameCallback.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // No-op to keep UI responsive; StatefulBuilder rebuilds when its setState is called only.
            });
          }
        },
      );
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return null;
      if (data != null) {
        if (data.pages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This book has no pages')),
          );
          return null;
        }
        // ignore: avoid_print
        print(
          'DeepLinkHost: lambook pages loaded = ' +
              data.pages.length.toString(),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LambookReaderScreen(lambook: data),
            ),
          );
        });
        return null;
      }
    }
    return null;
  }

  Future<void> _openLamlayersProject(String filePath) async {
    try {
      final project = await ExportManager.loadProject(filePath);
      if (project == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to open project')));
        return;
      }

      final box = Hive.box<PosterProject>('posterProjects');
      await box.put(project.id, project);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PosterMakerScreen(projectId: project.id),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
