import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EnhancedSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  final IconData icon;
  final bool isMini;
  final double step;
  final Color? accentColor; // optional accent color per slider
  final bool borderOnly; // when true, no filled backgrounds
  final double? fixedStepSize; // optional fixed step size for + and - buttons

  const EnhancedSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    required this.icon,
    this.isMini = false,
    this.step = 0.1,
    this.accentColor,
    this.borderOnly = true,
    this.fixedStepSize,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    final stepSize = fixedStepSize ?? (max - min) * step;

    if (isMini) {
      return _buildMiniSlider(context, clamped, stepSize);
    } else {
      return _buildFullSlider(context, clamped, stepSize);
    }
  }

  Widget _buildMiniSlider(
    BuildContext context,
    double clamped,
    double stepSize,
  ) {
    final Color accent = accentColor ?? _colorForLabel(label);
    final Color inactive = accent.withOpacity(0.2);
    return Column(
      children: [
        Container(
          width: 220.w,
          margin: EdgeInsets.only(right: 12.w),
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14.r),
            // no border
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16.sp, color: accent),
                  SizedBox(width: 8.w),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () =>
                        _showNumberInputDialog(context, clamped, accent),
                    child: Text(
                      clamped.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  GestureDetector(
                    onTap: () =>
                        _showNumberInputDialog(context, clamped, accent),
                    child: Icon(Icons.edit_rounded, size: 14.sp, color: accent),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  // Minus button
                  GestureDetector(
                    onTap: () {
                      final newValue = (clamped - stepSize).clamp(min, max);
                      onChanged(newValue);
                    },
                    child: Container(
                      width: 28.w,
                      height: 28.h,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                        // no border
                      ),
                      child: Icon(Icons.remove, size: 16.sp, color: accent),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Slider
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: accent,
                        inactiveTrackColor: inactive,
                        thumbColor: accent,
                        overlayColor: accent.withOpacity(0.08),
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 10.0,
                        ),
                      ),
                      child: Slider(
                        value: clamped,
                        min: min,
                        max: max,
                        onChanged: onChanged,
                        onChangeEnd: onChangeEnd,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  // Plus button
                  GestureDetector(
                    onTap: () {
                      final newValue = (clamped + stepSize).clamp(min, max);
                      onChanged(newValue);
                    },
                    child: Container(
                      width: 28.w,
                      height: 28.h,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8.r),
                        // no border
                      ),
                      child: Icon(Icons.add, size: 16.sp, color: accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 10.h),
      ],
    );
  }

  Widget _buildFullSlider(
    BuildContext context,
    double clamped,
    double stepSize,
  ) {
    final Color accent = accentColor ?? _colorForLabel(label);
    final Color inactive = accent.withOpacity(0.2);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        // no border
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20.sp, color: accent),
              SizedBox(width: 12.w),
              Text(
                label,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showNumberInputDialog(context, clamped, accent),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12.r),
                    // no border
                  ),
                  child: Text(
                    clamped.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              GestureDetector(
                onTap: () => _showNumberInputDialog(context, clamped, accent),
                child: Icon(Icons.edit_rounded, size: 16.sp, color: accent),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              // Minus button
              GestureDetector(
                onTap: () {
                  final newValue = (clamped - stepSize).clamp(min, max);
                  onChanged(newValue);
                },
                child: Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    // no border
                  ),
                  child: Icon(Icons.remove, size: 20.sp, color: accent),
                ),
              ),
              SizedBox(width: 12.w),
              // Slider
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accent,
                    inactiveTrackColor: inactive,
                    thumbColor: accent,
                    overlayColor: accent.withOpacity(0.1),
                    trackHeight: 6.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 12.0,
                    ),
                  ),
                  child: Slider(
                    value: clamped,
                    min: min,
                    max: max,
                    onChanged: onChanged,
                    onChangeEnd: onChangeEnd,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Plus button
              GestureDetector(
                onTap: () {
                  final newValue = (clamped + stepSize).clamp(min, max);
                  onChanged(newValue);
                },
                child: Container(
                  width: 36.w,
                  height: 36.h,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10.r),
                    // no border
                  ),
                  child: Icon(Icons.add, size: 20.sp, color: accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showNumberInputDialog(
    BuildContext context,
    double current,
    Color accent,
  ) async {
    final controller = TextEditingController(text: current.toStringAsFixed(2));
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.r),
              ),
              titlePadding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 0),
              contentPadding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 0),
              actionsPadding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 8.h),
              title: Row(
                children: [
                  Icon(icon, color: accent),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Set $label',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16.sp,
                          color: accent.withOpacity(0.9),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Allowed range: ${min.toStringAsFixed(2)} to ${max.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: InputDecoration(
                      labelText: label,
                      prefixIcon: Icon(Icons.edit_rounded, color: accent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: accent, width: 1.5),
                      ),
                      helperText: errorText == null
                          ? 'Tap Min/Max to quick set'
                          : null,
                      errorText: errorText,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 12.h,
                      ),
                    ),
                    onChanged: (text) {
                      final parsed = double.tryParse(text);
                      String? err;
                      if (parsed == null) {
                        err = 'Enter a valid number';
                      } else if (parsed < min || parsed > max) {
                        err =
                            'Enter value between ${min.toStringAsFixed(2)} and ${max.toStringAsFixed(2)}';
                      }
                      setState(() => errorText = err);
                    },
                    onSubmitted: (_) => _trySubmit(
                      ctx,
                      controller,
                      setState,
                      refErrorText: () => errorText,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      ActionChip(
                        label: const Text('Min'),
                        avatar: const Icon(
                          Icons.chevron_left_rounded,
                          size: 18,
                        ),
                        onPressed: () {
                          controller.text = min.toStringAsFixed(2);
                          setState(() => errorText = null);
                        },
                        backgroundColor: Colors.grey.shade100,
                        shape: StadiumBorder(
                          side: BorderSide(color: accent.withOpacity(0.2)),
                        ),
                      ),
                      ActionChip(
                        label: const Text('Max'),
                        avatar: const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                        ),
                        onPressed: () {
                          controller.text = max.toStringAsFixed(2);
                          setState(() => errorText = null);
                        },
                        backgroundColor: Colors.grey.shade100,
                        shape: StadiumBorder(
                          side: BorderSide(color: accent.withOpacity(0.2)),
                        ),
                      ),
                      
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: accent,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  onPressed: errorText == null
                      ? () => _trySubmit(
                          ctx,
                          controller,
                          setState,
                          refErrorText: () => errorText,
                        )
                      : null,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _trySubmit(
    BuildContext ctx,
    TextEditingController controller,
    void Function(void Function()) setState, {
    required String? Function() refErrorText,
  }) {
    final text = controller.text.trim();
    final parsed = double.tryParse(text);
    if (parsed == null) {
      setState(() {}); // keep current error state
      return;
    }
    if (parsed < min || parsed > max) {
      setState(() {});
      return;
    }
    onChanged(parsed);
    if (onChangeEnd != null) {
      onChangeEnd!(parsed);
    }
    Navigator.of(ctx).pop();
  }

  Color _colorForLabel(String label) {
    // Deterministic colorful palette per label
    switch (label.toLowerCase()) {
      case 'opacity':
        return const Color(0xFF8E44AD); // purple
      case 'scale':
        return const Color(0xFF27AE60); // green
      case 'rotate':
        return const Color(0xFFE67E22); // orange
      case 'blur':
        return const Color(0xFF3498DB); // blue
      case 'shadow x':
      case 'shadow y':
      case 'shadow blur':
        return const Color(0xFF2C3E50); // dark blue-gray
      default:
        final List<Color> palette = const [
          Color(0xFFE74C3C), // red
          Color(0xFFF1C40F), // yellow
          Color(0xFF1ABC9C), // teal
          Color(0xFF9B59B6), // amethyst
          Color(0xFF16A085), // green teal
          Color(0xFF2ECC71), // light green
          Color(0xFF2980B9), // denim
          Color(0xFFD35400), // pumpkin
        ];
        final int index = (label.hashCode.abs()) % palette.length;
        return palette[index];
    }
  }
}

class EnhancedDrawingSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int divisions;

  const EnhancedDrawingSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions = 25,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    final stepSize = (max - min) / divisions;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Container(
        width: 210.w,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: Colors.grey.shade300, width: 1.5),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$label: ${clamped.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  // Minus button
                  GestureDetector(
                    onTap: () {
                      final newValue = (clamped - stepSize).clamp(min, max);
                      onChanged(newValue);
                    },
                    child: Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        Icons.remove,
                        size: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  // Slider
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Colors.blue.shade400,
                        inactiveTrackColor: Colors.blue.shade100,
                        thumbColor: Colors.blue.shade600,
                        trackHeight: 4.0,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8.0,
                        ),
                      ),
                      child: Slider(
                        value: clamped,
                        min: min,
                        max: max,
                        divisions: divisions,
                        onChanged: onChanged,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  // Plus button
                  GestureDetector(
                    onTap: () {
                      final newValue = (clamped + stepSize).clamp(min, max);
                      onChanged(newValue);
                    },
                    child: Container(
                      width: 24.w,
                      height: 24.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        Icons.add,
                        size: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
