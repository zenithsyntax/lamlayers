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
  //gshgrdfdrert
}
