import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lamlayers/screens/hive_model.dart';
import 'package:lamlayers/screens/home_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:lamlayers/utils/export_manager.dart';
import 'package:lamlayers/screens/poster_maker_screen.dart';
import 'package:lamlayers/screens/scrapbook_flip_book_view.dart';
import 'package:lamlayers/widgets/connectivity_overlay.dart';
import 'package:archive/archive.dart';
//test
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
        title: 'Lamlayers',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        builder: (context, materialChild) {
          final Widget appChild = materialChild ?? const HomePage();
          return ConnectivityOverlay(child: DeepLinkHost(child: appChild));
        },
        home: const HomePage(),
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
    print('DeepLinkHost: Received method call: ${call.method}');
    print('DeepLinkHost: Arguments: ${call.arguments}');

    if (call.method == 'openedFile') {
      print('DeepLinkHost: Processing openedFile method call...');

      final Map args = (call.arguments as Map?) ?? {};
      print('DeepLinkHost: Args extracted: $args');

      final String? path = args['path'] as String?;
      final String? uri = args['uri'] as String?;
      final String? candidate = path ?? uri;

      print('DeepLinkHost: Path: $path');
      print('DeepLinkHost: URI: $uri');
      print('DeepLinkHost: Candidate: $candidate');

      if (candidate == null) {
        print('DeepLinkHost: No candidate path/URI found');
        return null;
      }

      // Normalize to file path where possible
      String normalized = candidate;
      if (normalized.startsWith('file://')) {
        normalized = normalized.replaceFirst('file://', '');
      }

      print('DeepLinkHost: Normalized path: $normalized');

      // Handle .lamlayers (poster project) directly via existing loader
      if (normalized.toLowerCase().endsWith('.lamlayers')) {
        print('DeepLinkHost: Detected .lamlayers file, opening as project');
        await _openLamlayersProject(normalized);
        return null;
      }

      // Try to handle as a .lambook regardless of extension (some providers strip it)
      // Debug log
      // ignore: avoid_print
      print('DeepLinkHost: attempting to open as lambook -> $normalized');

      // Check if file has .lambook extension
      bool isLikelyLambook = normalized.toLowerCase().endsWith('.lambook');
      print('DeepLinkHost: file extension check: $isLikelyLambook');

      print('DeepLinkHost: About to check file content...');

      // If the file doesn't have .lambook extension, try to detect if it's a lambook file
      // by checking if it's a valid ZIP file with scrapbook.json
      print('DeepLinkHost: isLikelyLambook (by extension): $isLikelyLambook');

      print('DeepLinkHost: About to check if content analysis is needed...');
      if (!isLikelyLambook) {
        print(
          'DeepLinkHost: File does not have .lambook extension, checking content...',
        );
        try {
          final file = File(normalized);
          if (file.existsSync() && file.lengthSync() > 0) {
            final bytes = await file.readAsBytes();
            // Check for ZIP signature
            if (bytes.length >= 4 &&
                bytes[0] == 0x50 &&
                bytes[1] == 0x4B &&
                (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
                (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08)) {
              // It's a ZIP file, check if it contains scrapbook.json
              try {
                final archive = ZipDecoder().decodeBytes(bytes);
                final hasScrapbookJson = archive.any(
                  (f) => f.name == 'scrapbook.json',
                );
                if (hasScrapbookJson) {
                  isLikelyLambook = true;
                  print(
                    'DeepLinkHost: Detected lambook file by content analysis',
                  );
                }
              } catch (e) {
                print('DeepLinkHost: Error analyzing ZIP content: $e');
              }
            }
          }
        } catch (e) {
          print('DeepLinkHost: Error checking file content: $e');
        }
      }

      print('DeepLinkHost: Content analysis check completed');
      print(
        'DeepLinkHost: After content analysis, isLikelyLambook: $isLikelyLambook',
      );

      if (!isLikelyLambook) {
        print('DeepLinkHost: File does not appear to be a lambook file');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'This file does not appear to be a valid .lambook file',
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return null;
      }

      print('DeepLinkHost: Proceeding to file existence check...');

      // Check if file exists and has content
      print('DeepLinkHost: Creating File object for: $normalized');
      final file = File(normalized);
      print('DeepLinkHost: Checking if file exists...');
      if (!file.existsSync()) {
        print('DeepLinkHost: File does not exist: $normalized');
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File not found or could not be accessed'),
            ),
          );
        }
        return null;
      }

      print('DeepLinkHost: Getting file size...');
      final fileSize = file.lengthSync();
      print('DeepLinkHost: file size: $fileSize bytes');

      if (fileSize == 0) {
        print('DeepLinkHost: File is empty');
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File is empty or corrupted')),
          );
        }
        return null;
      }

      print('DeepLinkHost: About to show loading dialog...');
      int _progress = 1;
      StateSetter? _dialogSetState;
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setState) {
                _dialogSetState = setState;
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
                        const SizedBox(height: 8),
                        Text(
                          _progress < 30
                              ? 'Reading file...'
                              : _progress < 60
                              ? 'Processing pages...'
                              : _progress < 90
                              ? 'Loading images...'
                              : 'Finalizing...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      }

      print('DeepLinkHost: Loading dialog created successfully');
      print('DeepLinkHost: About to call ExportManager.loadLambook...');

      final data = await Future.any([
        ExportManager.loadLambook(
          normalized,
          onProgress: (p) {
            _progress = p;
            print('DeepLinkHost: Progress update: $p%');
            // Update dialog if still mounted and dialog setState is available
            if (mounted && _dialogSetState != null) {
              _dialogSetState!(() {
                // This will trigger a rebuild of the dialog
              });
            }
          },
        ).catchError((error) {
          print('DeepLinkHost: Error loading lambook: $error');
          return null;
        }),
        Future.delayed(const Duration(seconds: 30), () {
          print('DeepLinkHost: Loading timeout after 30 seconds');
          return null;
        }),
      ]);

      print(
        'DeepLinkHost: loadLambook completed, data: ${data != null ? 'success' : 'null'}',
      );
      if (data != null) {
        print('DeepLinkHost: Pages count: ${data.pages.length}');
        for (int i = 0; i < data.pages.length; i++) {
          final page = data.pages[i];
          print('DeepLinkHost: Page $i - name: ${page.name}');
          print('DeepLinkHost: Page $i - thumbnailPath: ${page.thumbnailPath}');
          print(
            'DeepLinkHost: Page $i - backgroundImagePath: ${page.backgroundImagePath}',
          );
          if (page.thumbnailPath != null) {
            print(
              'DeepLinkHost: Page $i - thumbnail exists: ${File(page.thumbnailPath!).existsSync()}',
            );
          }
          if (page.backgroundImagePath != null) {
            print(
              'DeepLinkHost: Page $i - background exists: ${File(page.backgroundImagePath!).existsSync()}',
            );
          }
        }
      }
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (!mounted) return null;
      if (data != null) {
        if (data.pages.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This book has no pages')),
            );
          }
          return null;
        }
        // ignore: avoid_print
        print(
          'DeepLinkHost: lambook pages loaded = ' +
              data.pages.length.toString(),
        );

        // Add a small delay to ensure the loading dialog is fully closed
        // and the context is ready for navigation
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;

          try {
            print(
              'DeepLinkHost: Attempting navigation to ScrapbookFlipBookView...',
            );

            // Create a dummy Scrapbook for the viewer
            final scrapbook = Scrapbook(
              id: data.meta.id,
              name: data.meta.name,
              createdAt: DateTime.now(),
              lastModified: DateTime.now(),
              pageProjectIds: data.pages.map((p) => p.id).toList(),
              pageWidth: data.meta.pageWidth,
              pageHeight: data.meta.pageHeight,
            );

            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ScrapbookFlipBookView(
                  scrapbook: scrapbook,
                  directPages: data.pages,
                  scrapbookName: data.meta.name,
                  scaffoldBgColor: data.meta.scaffoldBgColor,
                  scaffoldBgImagePath: data.meta.scaffoldBgImagePath,
                  leftCoverColor: data.meta.leftCoverColor,
                  leftCoverImagePath: data.meta.leftCoverImagePath,
                  rightCoverColor: data.meta.rightCoverColor,
                  rightCoverImagePath: data.meta.rightCoverImagePath,
                ),
              ),
            );
            print(
              'DeepLinkHost: Successfully navigated to ScrapbookFlipBookView',
            );
          } catch (e) {
            print('DeepLinkHost: Navigation error: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to open book reader: $e'),
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        });
        return null;
      } else {
        // If loading failed, show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to open file. Please make sure it\'s a valid .lambook file.',
              ),
              duration: Duration(seconds: 5),
            ),
          );
        }
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
