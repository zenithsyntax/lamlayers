import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import 'package:google_fonts/google_fonts.dart';

class TextEditor extends StatelessWidget {
  final TextEditingController textController;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final bool isUnderlined;
  final Color textColor;
  final TextAlign textAlign;
  final String fontFamily;
  final VoidCallback onClose;
  final VoidCallback onApply;
  final Function(double) onFontSizeChanged;
  final Function(bool) onBoldChanged;
  final Function(bool) onItalicChanged;
  final Function(bool) onUnderlineChanged;
  final Function(Color) onColorChanged;
  final Function(TextAlign) onAlignChanged;
  final Function(String) onFontFamilyChanged;

  const TextEditor({
    super.key,
    required this.textController,
    required this.fontSize,
    required this.isBold,
    required this.isItalic,
    required this.isUnderlined,
    required this.textColor,
    required this.textAlign,
    required this.fontFamily,
    required this.onClose,
    required this.onApply,
    required this.onFontSizeChanged,
    required this.onBoldChanged,
    required this.onItalicChanged,
    required this.onUnderlineChanged,
    required this.onColorChanged,
    required this.onAlignChanged,
    required this.onFontFamilyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 20,
      right: 20,
      bottom: 100,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Edit Text',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: AppColors.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text Input
            TextField(
              controller: textController,
              style: TextStyle(
                color: textColor,
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                decoration: isUnderlined ? TextDecoration.underline : TextDecoration.none,
                fontFamily: fontFamily,
              ),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter your text...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.accentColor),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Font Size
            Row(
              children: [
                const Text(
                  'Size: ',
                  style: TextStyle(color: AppColors.primaryColor, fontSize: 14),
                ),
                Expanded(
                  child: Slider(
                    value: fontSize,
                    min: 12.0,
                    max: 72.0,
                    divisions: 60,
                    activeColor: AppColors.accentColor,
                    inactiveColor: Colors.grey[600],
                    onChanged: onFontSizeChanged,
                  ),
                ),
                Text(
                  fontSize.round().toString(),
                  style: const TextStyle(color: AppColors.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Font Family Dropdown
            Row(
              children: [
                const Text(
                  'Font: ',
                  style: TextStyle(color: AppColors.primaryColor, fontSize: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: fontFamily,
                    dropdownColor: Colors.grey[800],
                    style: const TextStyle(color: AppColors.primaryColor),
                    underline: Container(
                      height: 1,
                      color: AppColors.accentColor,
                    ),
                    items: AppConstants.fontFamilies.map((String font) {
                      final preview = GoogleFonts.asMap()[font];
                      final previewStyle = preview != null
                          ? preview().copyWith(color: AppColors.primaryColor)
                          : TextStyle(fontFamily: font, color: AppColors.primaryColor);
                      return DropdownMenuItem<String>(
                        value: font,
                        child: Text(font, style: previewStyle),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        onFontFamilyChanged(newValue);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text Style Options
            Row(
              children: [
                const Text(
                  'Style: ',
                  style: TextStyle(color: AppColors.primaryColor, fontSize: 14),
                ),
                const SizedBox(width: 10),
                ToggleButtons(
                  isSelected: [isBold, isItalic, isUnderlined],
                  onPressed: (int index) {
                    switch (index) {
                      case 0:
                        onBoldChanged(!isBold);
                        break;
                      case 1:
                        onItalicChanged(!isItalic);
                        break;
                      case 2:
                        onUnderlineChanged(!isUnderlined);
                        break;
                    }
                  },
                  color: Colors.grey[400],
                  selectedColor: AppColors.primaryColor,
                  fillColor: AppColors.accentColor.withOpacity(0.2),
                  borderColor: Colors.grey[600],
                  selectedBorderColor: AppColors.accentColor,
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Icon(Icons.format_bold),
                    Icon(Icons.format_italic),
                    Icon(Icons.format_underlined),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Text Alignment
            Row(
              children: [
                const Text(
                  'Align: ',
                  style: TextStyle(color: AppColors.primaryColor, fontSize: 14),
                ),
                const SizedBox(width: 10),
                ToggleButtons(
                  isSelected: [
                    textAlign == TextAlign.left,
                    textAlign == TextAlign.center,
                    textAlign == TextAlign.right,
                  ],
                  onPressed: (int index) {
                    switch (index) {
                      case 0:
                        onAlignChanged(TextAlign.left);
                        break;
                      case 1:
                        onAlignChanged(TextAlign.center);
                        break;
                      case 2:
                        onAlignChanged(TextAlign.right);
                        break;
                    }
                  },
                  color: Colors.grey[400],
                  selectedColor: AppColors.primaryColor,
                  fillColor: AppColors.accentColor.withOpacity(0.2),
                  borderColor: Colors.grey[600],
                  selectedBorderColor: AppColors.accentColor,
                  borderRadius: BorderRadius.circular(8),
                  children: const [
                    Icon(Icons.format_align_left),
                    Icon(Icons.format_align_center),
                    Icon(Icons.format_align_right),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Color Picker
            Row(
              children: [
                const Text(
                  'Color: ',
                  style: TextStyle(color: AppColors.primaryColor, fontSize: 14),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _getTextColors().map((color) {
                        final isSelected = color == textColor;
                        return GestureDetector(
                          onTap: () => onColorChanged(color),
                          child: Container(
                            width: 32,
                            height: 32,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppColors.accentColor : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      foregroundColor: AppColors.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getTextColors() {
    return const [
      Colors.white,
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
      Colors.teal,
      Colors.indigo,
    ];
  }
}