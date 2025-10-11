import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../interactive_book.dart';
import '../page/page_turn.dart';
import 'paper_widget.dart';
import 'interactive_book_render_object_widget.dart';

class InteractiveBookView extends StatefulWidget {
  final PageTurnController? controller;
  final PageWidgetBuilder builder;
  final int pageCount;
  final InteractiveBookCallback? onPageChanged;
  final FlipSettings settings;
  final double aspectRatio;
  final Size bookSize;
  final PaperBoundaryDecoration paperBoundaryDecoration;
  final bool pagesBoundaryIsEnabled;

  const InteractiveBookView({
    super.key,
    this.controller,
    this.onPageChanged,
    required this.builder,
    required this.pageCount,
    required this.aspectRatio,
    required this.bookSize,
    required this.settings,
    required this.paperBoundaryDecoration,
    this.pagesBoundaryIsEnabled = true,
  });

  @override
  State<InteractiveBookView> createState() => _InteractiveBookViewState();
}

class _InteractiveBookViewState extends State<InteractiveBookView> {
  /// PageTurn core logic
  late PageTurn _pageTurn;

  /// Get the adjusted settings for the PageTurn instance
  FlipSettings get _settings => widget.settings.copyWith(
    width: widget.bookSize.width,
    height: widget.bookSize.height,
    startPage: widget.settings.startPageIndex,
  );

  @override
  void initState() {
    _pageTurn = PageTurn(_settings);
    _setupPageTurnEventsAndController();
    super.initState();
  }

  Future<void> _setupPageTurnEventsAndController() async {
    widget.controller?.initializeController(pageTurn: _pageTurn);
    // Set up event listeners
    _pageTurn.on('flip', (_) {
      if (mounted) {
        final newIndex = _pageTurn.getCurrentPageIndex();
        final left = newIndex.clamp(0, widget.pageCount - 1);
        final right = (newIndex + 1 < widget.pageCount) ? newIndex + 1 : -1;
        widget.settings.startPageIndex = left;
        _pageTurn.updateSetting(_settings);
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onPageChanged?.call(left, right);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PaperWidget(
      size: widget.bookSize,
      isSinglePage: widget.settings.usePortrait,
      paperBoundaryDecoration: widget.paperBoundaryDecoration,
      isEnabled: widget.pagesBoundaryIsEnabled,
      child: InteractiveBookRenderObjectWidget(
        pageCount: widget.pageCount,
        builder: (ctx, index) => widget.builder(ctx, index),
        settings: _settings,
        pageTurn: _pageTurn,
      ),
    );
  }
}
