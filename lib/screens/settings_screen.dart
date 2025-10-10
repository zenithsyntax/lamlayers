import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'hive_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Box<UserPreferences> _userPreferencesBox;
  late UserPreferences userPreferences;

  @override
  void initState() {
    super.initState();
    _userPreferencesBox = Hive.box<UserPreferences>('userPreferences');
    userPreferences =
        _userPreferencesBox.get('user_prefs_id') ?? UserPreferences();
  }

  void _updatePreferences() {
    _userPreferencesBox.put('user_prefs_id', userPreferences);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-Save Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Auto-Save'),
                    subtitle: const Text('Automatically save your work'),
                    value: userPreferences.autoSave,
                    onChanged: (value) {
                      setState(() {
                        userPreferences.autoSave = value;
                        _updatePreferences();
                      });
                    },
                  ),
                  if (userPreferences.autoSave) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Auto-Save Interval',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Slider(
                      value: userPreferences.autoSaveInterval.toDouble(),
                      min: 5,
                      max: 300,
                      divisions: 19,
                      label: '${userPreferences.autoSaveInterval}s',
                      onChanged: (value) {
                        setState(() {
                          userPreferences.autoSaveInterval = value.round();
                          _updatePreferences();
                        });
                      },
                    ),
                    Text(
                      'Current interval: ${userPreferences.autoSaveInterval} seconds',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Canvas Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Show Grid'),
                    subtitle: const Text('Display grid lines on canvas'),
                    value: userPreferences.showGrid,
                    onChanged: (value) {
                      setState(() {
                        userPreferences.showGrid = value;
                        _updatePreferences();
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Snap to Grid'),
                    subtitle: const Text('Align items to grid lines'),
                    value: userPreferences.snapToGrid,
                    onChanged: (value) {
                      setState(() {
                        userPreferences.snapToGrid = value;
                        _updatePreferences();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Default Export Format'),
                    subtitle: Text(
                      _getFormatName(userPreferences.defaultExportFormat),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showFormatDialog(),
                  ),
                  ListTile(
                    title: const Text('Default Export Quality'),
                    subtitle: Text(
                      _getQualityName(userPreferences.defaultExportQuality),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showQualityDialog(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    subtitle: const Text('Use dark theme'),
                    value: userPreferences.darkMode,
                    onChanged: (value) {
                      setState(() {
                        userPreferences.darkMode = value;
                        _updatePreferences();
                      });
                    },
                  ),
                  SwitchListTile(
                    title: const Text('Haptic Feedback'),
                    subtitle: const Text('Vibrate on interactions'),
                    value: userPreferences.enableHapticFeedback,
                    onChanged: (value) {
                      setState(() {
                        userPreferences.enableHapticFeedback = value;
                        _updatePreferences();
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormatName(ExportFormat format) {
    switch (format) {
      case ExportFormat.png:
        return 'PNG';
      case ExportFormat.jpg:
        return 'JPEG';
      case ExportFormat.pdf:
        return 'PDF';
      case ExportFormat.svg:
        return 'SVG';
    }
  }

  String _getQualityName(ExportQuality quality) {
    switch (quality) {
      case ExportQuality.low:
        return 'Low';
      case ExportQuality.medium:
        return 'Medium';
      case ExportQuality.high:
        return 'High';
      case ExportQuality.ultra:
        return 'Ultra';
    }
  }

  void _showFormatDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExportFormat.values.map((format) {
            return RadioListTile<ExportFormat>(
              title: Text(_getFormatName(format)),
              value: format,
              groupValue: userPreferences.defaultExportFormat,
              onChanged: (value) {
                setState(() {
                  userPreferences.defaultExportFormat = value!;
                  _updatePreferences();
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Export Quality'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExportQuality.values.map((quality) {
            return RadioListTile<ExportQuality>(
              title: Text(_getQualityName(quality)),
              value: quality,
              groupValue: userPreferences.defaultExportQuality,
              onChanged: (value) {
                setState(() {
                  userPreferences.defaultExportQuality = value!;
                  _updatePreferences();
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
  //gshg
}
