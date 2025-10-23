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
                  Text(
                    clamped.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
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
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
