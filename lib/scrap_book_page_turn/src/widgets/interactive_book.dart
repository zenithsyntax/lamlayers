import 'package:flutter/material.dart';

import '../enums/page_view_mode.dart';
import '../flip/flip_settings.dart';
import '../model/paper_boundary_decoration.dart';
import 'page_turn_controller.dart';
import 'interactive_book_view.dart';

class InteractiveBook extends StatelessWidget {
  final PageTurnController? controller;
  final InteractiveBookBuilder builder;
  final int pageCount;
  final InteractiveBookCallback? onPageChanged;
  final FlipSettings settings;
  final PageViewMode pageViewMode;
  final bool autoResponseSize;
  final PaperBoundaryDecoration paperBoundaryDecoration;
  final double? aspectRatio;
  final bool pagesBoundaryIsEnabled;

  InteractiveBook({
    super.key,
    this.controller,
    this.aspectRatio,
    required this.builder,
    required this.pageCount,
    this.onPageChanged,
    this.pageViewMode = PageViewMode.single,
    this.autoResponseSize = true,
    this.paperBoundaryDecoration = PaperBoundaryDecoration.vintage,
    FlipSettings? settings,
    this.pagesBoundaryIsEnabled = true,
  }) : settings = settings ?? FlipSettings() {
    // Validate settings in both debug and release builds
    if (settings != null) {
      if (this.settings.startPageIndex < 0) {
        throw ArgumentError(
          'Start page index must be greater than or equal to 0',
        );
      }
      if (this.settings.startPageIndex >= pageCount) {
        throw ArgumentError('Start page index must be less than page count');
      }
    }

    // Validate page count
    if (pageCount <= 0) {
      throw ArgumentError('Page count must be greater than 0');
    }

    // Validate aspect ratio if provided
    if (aspectRatio != null && (aspectRatio! <= 0 || !aspectRatio!.isFinite)) {
      throw ArgumentError('Aspect ratio must be a positive finite number');
    }
  }

  Size _calculateBookSize({
    required double maxWidth,
    required double maxHeight,
    required double aspectRatio,
  }) {
    // Validate inputs
    if (maxWidth <= 0 ||
        maxHeight <= 0 ||
        aspectRatio <= 0 ||
        !aspectRatio.isFinite) {
      return const Size(300, 400); // Default fallback size
    }

    double height = maxWidth / aspectRatio;
    if (height > maxHeight) {
      height = maxHeight;
      maxWidth = height * aspectRatio;
    }

    // Ensure the calculated size is valid
    if (maxWidth <= 0 ||
        height <= 0 ||
        !maxWidth.isFinite ||
        !height.isFinite) {
      return const Size(300, 400); // Default fallback size
    }

    return Size(maxWidth, height);
  }

  double _getAspectRatio(bool isMobile) {
    if (!autoResponseSize && pageViewMode == PageViewMode.single) {
      return aspectRatio ?? 2 / 3;
    }
    if (pageViewMode == PageViewMode.single) {
      return aspectRatio ?? 2 / 3 * (isMobile ? 1 : 2);
    }
    return aspectRatio ?? (2 / 3) * 2;
  }

  FlipSettings _getAdjustedSetting(bool isMobile) {
    if (!autoResponseSize && pageViewMode == PageViewMode.single) {
      return settings.copyWith(usePortrait: true);
    }
    final usePortrait = pageViewMode == PageViewMode.single && isMobile;
    return settings.copyWith(usePortrait: usePortrait);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final aspectRatio = _getAspectRatio(isMobile);
        FlipSettings adjustedSettings = _getAdjustedSetting(isMobile);

        final bookSize = _calculateBookSize(
          maxWidth: constraints.maxWidth,
          maxHeight: constraints.maxHeight,
          aspectRatio: aspectRatio,
        );
        adjustedSettings = adjustedSettings.copyWith(
          width: bookSize.width,
          height: bookSize.height,
        );

        return InteractiveBookView(
          builder: (context, index) => builder(context, index, constraints),
          bookSize: bookSize,
          settings: adjustedSettings,
          pageCount: pageCount,
          controller: controller,
          aspectRatio: aspectRatio,
          onPageChanged: onPageChanged,
          pagesBoundaryIsEnabled: pagesBoundaryIsEnabled,
          paperBoundaryDecoration: paperBoundaryDecoration,
        );
      },
    );
  }
}

typedef InteractiveBookBuilder =
    Widget Function(
      BuildContext context,
      int pageIndex,
      BoxConstraints constraints,
    );
typedef InteractiveBookCallback =
    void Function(int leftPageIndex, int rightPageIndex);
typedef PageWidgetBuilder = Widget Function(BuildContext context, int index);
