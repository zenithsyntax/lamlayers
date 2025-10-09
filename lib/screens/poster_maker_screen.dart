import 'dart:io';
import 'dart:convert';

import 'dart:typed_data';

import 'dart:ui' as ui;

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import 'package:flutter/material.dart';

import 'package:flutter/rendering.dart';

import 'package:flutter/painting.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:image_picker/image_picker.dart';

import 'package:lamlayers/screens/hive_model.dart';

import 'package:path_provider/path_provider.dart';

import 'package:share_plus/share_plus.dart';

import '../models/canvas_models.dart';
import '../widgets/enhanced_slider.dart';

import '../widgets/canvas_grid_painter.dart';

import '../widgets/action_bar.dart';

import '../models/font_favorites.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:lamlayers/widgets/ad_banner.dart';

import 'package:flutter/services.dart';

import 'package:lamlayers/screens/add_images.dart';

import 'package:lamlayers/screens/settings_screen.dart';
import 'package:lamlayers/widgets/export_dialog.dart' as export_dialog;
import 'package:lamlayers/utils/export_manager.dart';
import 'package:lamlayers/screens/hive_model.dart' as hive_model;

import 'package:cached_network_image/cached_network_image.dart';

import 'package:hive/hive.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter/widgets.dart';

import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'package:lamlayers/screens/google_font_screen.dart';

import 'dart:async'; // Import for Timer

import 'package:image_editor_plus/image_editor_plus.dart';

import 'package:lamlayers/utils/image_stroke_processor.dart';

import 'package:lamlayers/utils/image_stroke_processor_v2.dart';

import 'package:http/http.dart' as http;

import 'package:image_background_remover/image_background_remover.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class PosterMakerScreen extends StatefulWidget {
  final String? projectId;
  final double? initialCanvasWidth;
  final double? initialCanvasHeight;
  final String? initialBackgroundImagePath;

  const PosterMakerScreen({
    super.key,
    this.projectId,
    this.initialCanvasWidth,
    this.initialCanvasHeight,
    this.initialBackgroundImagePath,
  });

  @override
  State<PosterMakerScreen> createState() => _PosterMakerScreenState();
}

class DrawingPainter extends CustomPainter {
  final List<DrawingLayer> layers;

  final List<Offset> currentPoints;

  final DrawingTool currentTool;

  final Color currentColor;

  final double currentStrokeWidth;

  final double currentOpacity;

  final String? currentPathText;

  final String? currentPathFontFamily;

  final double? currentPathLetterSpacing;

  DrawingPainter({
    required this.layers,

    required this.currentPoints,

    required this.currentTool,

    required this.currentColor,

    required this.currentStrokeWidth,

    required this.currentOpacity,

    this.currentPathText,

    this.currentPathFontFamily,

    this.currentPathLetterSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Use a layer so eraser strokes can clear previous content

    canvas.saveLayer(Offset.zero & size, Paint());

    // Draw all completed layers

    for (final layer in layers) {
      if (!layer.isVisible) continue;

      final paint = Paint()
        ..color =
            (layer.tool == DrawingTool.eraser
                    ? Colors.transparent
                    : layer.color)
                .withOpacity(layer.opacity)
        ..blendMode = layer.tool == DrawingTool.eraser
            ? BlendMode.clear
            : BlendMode.srcOver
        ..strokeWidth = layer.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (layer.tool == DrawingTool.textPath) {
        _drawTextAlongPath(
          canvas,

          layer.points,

          layer.text ?? '',

          layer.color,

          (layer.fontSize ?? layer.strokeWidth).toDouble(),

          fontFamily: layer.fontFamily,

          letterSpacing: layer.letterSpacing ?? 0.0,
        );
      } else if (layer.isDotted) {
        paint.strokeWidth = layer.strokeWidth;

        // Create dotted effect by drawing small segments

        _drawDottedPath(canvas, paint, layer.points);
      } else {
        _drawPath(canvas, paint, layer.points, layer.tool);
      }
    }

    // Draw current drawing in progress

    if (currentPoints.isNotEmpty) {
      final paint = Paint()
        ..color =
            (currentTool == DrawingTool.eraser
                    ? Colors.transparent
                    : currentColor)
                .withOpacity(currentOpacity)
        ..blendMode = currentTool == DrawingTool.eraser
            ? BlendMode.clear
            : BlendMode.srcOver
        ..strokeWidth = currentStrokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (currentTool == DrawingTool.textPath) {
        final String txt = (currentPathText ?? '').trim();

        if (txt.isEmpty) {
          // Show the path as a light preview if no text entered yet

          final previewPaint = Paint()
            ..color = currentColor.withOpacity(currentOpacity * 0.6)
            ..strokeWidth = currentStrokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;

          _drawPath(canvas, previewPaint, currentPoints, DrawingTool.brush);
        } else {
          _drawTextAlongPath(
            canvas,

            currentPoints,

            txt,

            currentColor,

            currentStrokeWidth,

            fontFamily: currentPathFontFamily,

            letterSpacing: currentPathLetterSpacing ?? 0.0,
          );
        }
      } else {
        final isDotted =
            currentTool == DrawingTool.dottedLine ||
            currentTool == DrawingTool.dottedArrow;

        if (isDotted) {
          _drawDottedPath(canvas, paint, currentPoints);
        } else {
          _drawPath(canvas, paint, currentPoints, currentTool);
        }
      }
    }

    canvas.restore();
  }

  void _drawTextAlongPath(
    Canvas canvas,

    List<Offset> points,

    String text,

    Color color,

    double fontSize, {

    String? fontFamily,

    FontWeight? fontWeight,

    FontStyle? fontStyle,

    double letterSpacing = 0.0,
  }) {
    if (points.length < 2 || text.isEmpty) return;

    final ui.ParagraphBuilder builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontSize: fontSize,

              fontFamily: fontFamily,

              fontWeight: fontWeight,

              fontStyle: fontStyle,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: color,

              fontFamily: fontFamily,

              fontWeight: fontWeight,

              fontStyle: fontStyle,
            ),
          )
          ..addText(text);

    final ui.Paragraph paragraph = builder.build();

    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    // Place characters repeatedly along the entire path

    double distanceAlong = 0.0;

    final List<_Segment> segments = _segmentsFromPoints(points);

    final double totalLength = segments.fold(0.0, (sum, s) => sum + s.length);

    int i = 0;

    while (true) {
      final int charIndex = i % text.length;

      final String char = text[charIndex];

      final ui.TextBox box = paragraph
          .getBoxesForRange(charIndex, charIndex + 1)
          .first;

      final double charWidth = (box.right - box.left).abs();

      final _PathSample sample = _sampleAtDistance(
        segments,

        distanceAlong + charWidth / 2,
      );

      if (!sample.valid) break;

      canvas.save();

      canvas.translate(sample.position.dx, sample.position.dy);

      canvas.rotate(sample.angle);

      final ui.ParagraphBuilder cb = ui.ParagraphBuilder(
        ui.ParagraphStyle(
          fontSize: fontSize,

          fontFamily: fontFamily,

          fontWeight: fontWeight,

          fontStyle: fontStyle,
        ),
      );

      cb.pushStyle(
        ui.TextStyle(
          color: color,

          fontFamily: fontFamily,

          fontWeight: fontWeight,

          fontStyle: fontStyle,
        ),
      );

      cb.addText(char);

      final ui.Paragraph p = cb.build();

      p.layout(const ui.ParagraphConstraints(width: double.infinity));

      canvas.drawParagraph(p, Offset(-charWidth / 2, -fontSize));

      canvas.restore();

      distanceAlong += charWidth + letterSpacing;

      if (distanceAlong >= totalLength) break;

      i++;
    }
  }

  List<_Segment> _segmentsFromPoints(List<Offset> points) {
    final List<_Segment> segments = [];

    for (int i = 0; i < points.length - 1; i++) {
      final Offset a = points[i];

      final Offset b = points[i + 1];

      final double len = (b - a).distance;

      if (len > 0.0001) {
        segments.add(_Segment(start: a, end: b, length: len));
      }
    }

    return segments;
  }

  _PathSample _sampleAtDistance(List<_Segment> segments, double d) {
    double remaining = d;

    for (final s in segments) {
      if (remaining <= s.length) {
        final t = remaining / s.length;

        final Offset pos = Offset(
          s.start.dx + (s.end.dx - s.start.dx) * t,

          s.start.dy + (s.end.dy - s.start.dy) * t,
        );

        final double angle = math.atan2(
          s.end.dy - s.start.dy,

          s.end.dx - s.start.dx,
        );

        return _PathSample(position: pos, angle: angle, valid: true);
      }

      remaining -= s.length;
    }

    return _PathSample(position: Offset.zero, angle: 0, valid: false);
  }

  void _drawPath(
    Canvas canvas,

    Paint paint,

    List<Offset> points,

    DrawingTool tool,
  ) {
    if (points.isEmpty) return;

    switch (tool) {
      case DrawingTool.brush:
      case DrawingTool.pencil:
      case DrawingTool.eraser:
        if (points.length == 1) {
          canvas.drawPoints(ui.PointMode.points, points, paint);
        } else {
          canvas.drawPoints(ui.PointMode.polygon, points, paint);
        }

        break;

      case DrawingTool.textPath:

        // handled elsewhere

        break;

      case DrawingTool.line:
      case DrawingTool.dottedLine:
        if (points.length >= 2) {
          canvas.drawLine(points.first, points.last, paint);
        }

        break;

      case DrawingTool.arrow:
      case DrawingTool.dottedArrow:
        if (points.length >= 2) {
          canvas.drawLine(points.first, points.last, paint);

          _drawArrowhead(canvas, paint, points.first, points.last);
        }

        break;

      case DrawingTool.rectangle:
        if (points.length >= 2) {
          final rect = Rect.fromPoints(points.first, points.last);

          canvas.drawRect(rect, paint);
        }

        break;

      case DrawingTool.circle:
        if (points.length >= 2) {
          final center = Offset(
            (points.first.dx + points.last.dx) / 2,

            (points.first.dy + points.last.dy) / 2,
          );

          final radius = (points.first - points.last).distance / 2;

          canvas.drawCircle(center, radius, paint);
        }

        break;

      case DrawingTool.triangle:
        if (points.length >= 2) {
          _drawTriangle(canvas, paint, points.first, points.last);
        }

        break;
    }
  }

  void _drawDottedPath(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;

    const dashLength = 8.0;

    const dashSpace = 4.0;

    // Simplified dotted line drawing for better performance

    for (int i = 0; i < points.length - 1; i += 2) {
      // Skip every other point for performance

      final start = points[i];

      final end = i + 1 < points.length ? points[i + 1] : points.last;

      final distance = (end - start).distance;

      if (distance < 1.0) continue; // Skip very short segments

      final normalized = _normalize(end - start);

      double currentDistance = 0.0;

      while (currentDistance < distance) {
        final dashStart = start + normalized * currentDistance;

        final dashEnd =
            start +
            normalized * (currentDistance + dashLength).clamp(0.0, distance);

        canvas.drawLine(dashStart, dashEnd, paint);

        currentDistance += dashLength + dashSpace;
      }
    }
  }

  void _drawArrowhead(Canvas canvas, Paint paint, Offset start, Offset end) {
    final arrowLength = 15.0;

    final arrowAngle = 0.5;

    final direction = _normalize(end - start);

    final perpendicular = Offset(-direction.dy, direction.dx);

    final arrowPoint1 =
        end -
        direction * arrowLength +
        perpendicular * arrowLength * arrowAngle;

    final arrowPoint2 =
        end -
        direction * arrowLength -
        perpendicular * arrowLength * arrowAngle;

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);

    canvas.drawPath(path, paint);
  }

  void _drawTriangle(Canvas canvas, Paint paint, Offset start, Offset end) {
    final Rect rect = Rect.fromPoints(start, end);

    final Offset top = Offset(rect.center.dx, rect.top);

    final Offset left = Offset(rect.left, rect.bottom);

    final Offset right = Offset(rect.right, rect.bottom);

    final Path path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  Offset _normalize(Offset vector) {
    final length = vector.distance;

    if (length == 0) return Offset.zero;

    return Offset(vector.dx / length, vector.dy / length);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) {
    // Always repaint if there are current points being drawn

    if (currentPoints.isNotEmpty) return true;

    // Only repaint if there are actual changes to completed layers

    return layers.length != oldDelegate.layers.length ||
        currentPoints.length != oldDelegate.currentPoints.length ||
        currentTool != oldDelegate.currentTool ||
        currentColor != oldDelegate.currentColor ||
        currentStrokeWidth != oldDelegate.currentStrokeWidth ||
        currentOpacity != oldDelegate.currentOpacity;
  }
}

class _Segment {
  final Offset start;

  final Offset end;

  final double length;

  _Segment({required this.start, required this.end, required this.length});
}

class _PathSample {
  final Offset position;

  final double angle;

  final bool valid;

  _PathSample({
    required this.position,

    required this.angle,

    required this.valid,
  });
}

class _SelectionBorderPainter extends CustomPainter {
  final Offset topLeft;

  final Offset topRight;

  final Offset bottomLeft;

  final Offset bottomRight;

  _SelectionBorderPainter({
    required this.topLeft,

    required this.topRight,

    required this.bottomLeft,

    required this.bottomRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint borderPaint = Paint()
      ..color = Colors.blue.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..isAntiAlias = true;

    final Path borderPath = Path();

    borderPath.moveTo(topLeft.dx, topLeft.dy);

    borderPath.lineTo(topRight.dx, topRight.dy);

    borderPath.lineTo(bottomRight.dx, bottomRight.dy);

    borderPath.lineTo(bottomLeft.dx, bottomLeft.dy);

    borderPath.close();

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SelectionBorderPainter oldDelegate) {
    return topLeft != oldDelegate.topLeft ||
        topRight != oldDelegate.topRight ||
        bottomLeft != oldDelegate.bottomLeft ||
        bottomRight != oldDelegate.bottomRight;
  }
}

class _DrawingItemPainter extends CustomPainter {
  final DrawingTool tool;

  final List<Offset> points;

  final Color color;

  final double strokeWidth;

  final bool isDotted;

  _DrawingItemPainter({
    required this.tool,

    required this.points,

    required this.color,

    required this.strokeWidth,

    required this.isDotted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isDotted) {
      _drawDottedPath(canvas, paint, points);
    } else {
      _drawPath(canvas, paint, points, tool);
    }
  }

  void _drawPath(
    Canvas canvas,

    Paint paint,

    List<Offset> points,

    DrawingTool tool,
  ) {
    if (points.isEmpty) return;

    switch (tool) {
      case DrawingTool.brush:
      case DrawingTool.pencil:
      case DrawingTool.eraser:
        if (points.length == 1) {
          canvas.drawPoints(ui.PointMode.points, points, paint);
        } else {
          canvas.drawPoints(ui.PointMode.polygon, points, paint);
        }

        break;

      case DrawingTool.textPath:

        // handled elsewhere

        break;

      case DrawingTool.line:
      case DrawingTool.dottedLine:
        if (points.length >= 2) {
          canvas.drawLine(points.first, points.last, paint);
        }

        break;

      case DrawingTool.arrow:
      case DrawingTool.dottedArrow:
        if (points.length >= 2) {
          canvas.drawLine(points.first, points.last, paint);

          _drawArrowhead(canvas, paint, points.first, points.last);
        }

        break;

      case DrawingTool.rectangle:
        if (points.length >= 2) {
          final rect = Rect.fromPoints(points.first, points.last);

          canvas.drawRect(rect, paint);
        }

        break;

      case DrawingTool.circle:
        if (points.length >= 2) {
          final center = Offset(
            (points.first.dx + points.last.dx) / 2,

            (points.first.dy + points.last.dy) / 2,
          );

          final radius = (points.first - points.last).distance / 2;

          canvas.drawCircle(center, radius, paint);
        }

        break;

      case DrawingTool.triangle:
        if (points.length >= 2) {
          _drawTriangle(canvas, paint, points.first, points.last);
        }

        break;
    }
  }

  void _drawDottedPath(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;

    const dashLength = 8.0;

    const dashSpace = 4.0;

    for (int i = 0; i < points.length - 1; i += 2) {
      final start = points[i];

      final end = i + 1 < points.length ? points[i + 1] : points.last;

      final distance = (end - start).distance;

      final dashCount = (distance / (dashLength + dashSpace)).floor();

      for (int j = 0; j < dashCount; j++) {
        final startRatio = j * (dashLength + dashSpace) / distance;

        final endRatio = (j * (dashLength + dashSpace) + dashLength) / distance;

        final dashStart = Offset.lerp(start, end, startRatio)!;

        final dashEnd = Offset.lerp(start, end, endRatio)!;

        canvas.drawLine(dashStart, dashEnd, paint);
      }
    }
  }

  void _drawArrowhead(Canvas canvas, Paint paint, Offset start, Offset end) {
    final direction = (end - start).direction;

    final arrowLength = strokeWidth * 2;

    final arrowAngle = math.pi / 6; // 30 degrees

    final arrowPoint1 =
        end +
        Offset(
          -arrowLength * math.cos(direction - arrowAngle),

          -arrowLength * math.sin(direction - arrowAngle),
        );

    final arrowPoint2 =
        end +
        Offset(
          -arrowLength * math.cos(direction + arrowAngle),

          -arrowLength * math.sin(direction + arrowAngle),
        );

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint1.dx, arrowPoint1.dy)
      ..moveTo(end.dx, end.dy)
      ..lineTo(arrowPoint2.dx, arrowPoint2.dy);

    canvas.drawPath(path, paint);
  }

  void _drawTriangle(Canvas canvas, Paint paint, Offset start, Offset end) {
    final Rect rect = Rect.fromPoints(start, end);

    final Offset top = Offset(rect.center.dx, rect.top);

    final Offset left = Offset(rect.left, rect.bottom);

    final Offset right = Offset(rect.right, rect.bottom);

    final Path path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DrawingItemPainter oldDelegate) {
    return tool != oldDelegate.tool ||
        points != oldDelegate.points ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        isDotted != oldDelegate.isDotted;
  }
}

class _MultiStrokeDrawingPainter extends CustomPainter {
  final List<Map<String, dynamic>> strokes;

  _MultiStrokeDrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    // Use a layer to support eraser strokes via BlendMode.clear

    canvas.saveLayer(Offset.zero & size, Paint());

    for (final stroke in strokes) {
      final DrawingTool tool =
          stroke['tool'] as DrawingTool? ?? DrawingTool.brush;

      final List<Offset> points =
          (stroke['points'] as List<dynamic>?)
              ?.map<Offset>((p) => _parseOffset(p) ?? const Offset(0, 0))
              .toList() ??
          <Offset>[];

      final dynamic colorRaw = stroke['color'];

      final Color color = colorRaw is HiveColor
          ? colorRaw.toColor()
          : (colorRaw is Color ? colorRaw : Colors.black);

      final double strokeWidth = (stroke['strokeWidth'] as double?) ?? 2.0;

      final bool isDotted = (stroke['isDotted'] as bool?) ?? false;

      final double opacity = (stroke['opacity'] as double?) ?? 1.0;

      final String text = (stroke['text'] as String?) ?? '';

      final double fontSize = (stroke['fontSize'] as double?) ?? strokeWidth;

      final String? fontFamily = stroke['fontFamily'] as String?;

      final FontWeight? fontWeight = stroke['fontWeight'] as FontWeight?;

      final FontStyle? fontStyle = stroke['fontStyle'] as FontStyle?;

      if (points.isEmpty) continue;

      final paint = Paint()
        ..color = (tool == DrawingTool.eraser ? Colors.transparent : color)
            .withOpacity(opacity.clamp(0.0, 1.0))
        ..blendMode = tool == DrawingTool.eraser
            ? BlendMode.clear
            : BlendMode.srcOver
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if ((tool) == DrawingTool.textPath) {
        final double letterSpacing =
            (stroke['letterSpacing'] as double?) ?? 0.0;

        _drawTextAlongPath(
          canvas,

          points,

          text,

          color,

          fontSize,

          fontFamily: fontFamily,

          fontWeight: fontWeight,

          fontStyle: fontStyle,

          letterSpacing: letterSpacing,
        );
      } else if (isDotted) {
        _drawDottedPath(canvas, paint, points);
      } else {
        _drawPath(canvas, paint, points, tool);
      }
    }

    canvas.restore();
  }

  void _drawTextAlongPath(
    Canvas canvas,

    List<Offset> points,

    String text,

    Color color,

    double fontSize, {

    String? fontFamily,

    FontWeight? fontWeight,

    FontStyle? fontStyle,

    double letterSpacing = 0.0,
  }) {
    if (points.length < 2 || text.isEmpty) return;

    final ui.ParagraphBuilder builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              fontSize: fontSize,

              fontFamily: fontFamily,

              fontWeight: fontWeight,

              fontStyle: fontStyle,
            ),
          )
          ..pushStyle(
            ui.TextStyle(
              color: color,

              fontFamily: fontFamily,

              fontWeight: fontWeight,

              fontStyle: fontStyle,
            ),
          )
          ..addText(text);

    final ui.Paragraph paragraph = builder.build();

    paragraph.layout(const ui.ParagraphConstraints(width: double.infinity));

    double distanceAlong = 0.0;

    final List<_Segment> segments = _segmentsFromPoints(points);

    final double totalLength = segments.fold(0.0, (sum, s) => sum + s.length);

    int i = 0;

    while (true) {
      final int charIndex = i % text.length;

      final String char = text[charIndex];

      final ui.TextBox box = paragraph
          .getBoxesForRange(charIndex, charIndex + 1)
          .first;

      final double charWidth = (box.right - box.left).abs();

      final _PathSample sample = _sampleAtDistance(
        segments,

        distanceAlong + charWidth / 2,
      );

      if (!sample.valid) break;

      canvas.save();

      canvas.translate(sample.position.dx, sample.position.dy);

      canvas.rotate(sample.angle);

      final ui.ParagraphBuilder cb =
          ui.ParagraphBuilder(
              ui.ParagraphStyle(
                fontSize: fontSize,

                fontFamily: fontFamily,

                fontWeight: fontWeight,

                fontStyle: fontStyle,
              ),
            )
            ..pushStyle(
              ui.TextStyle(
                color: color,

                fontFamily: fontFamily,

                fontWeight: fontWeight,

                fontStyle: fontStyle,
              ),
            )
            ..addText(char);

      final ui.Paragraph p = cb.build();

      p.layout(const ui.ParagraphConstraints(width: double.infinity));

      canvas.drawParagraph(p, Offset(-charWidth / 2, -fontSize));

      canvas.restore();

      distanceAlong += charWidth + letterSpacing;

      if (distanceAlong >= totalLength) break;

      i++;
    }
  }

  List<_Segment> _segmentsFromPoints(List<Offset> points) {
    final List<_Segment> segments = [];

    for (int i = 0; i < points.length - 1; i++) {
      final Offset a = points[i];

      final Offset b = points[i + 1];

      final double len = (b - a).distance;

      if (len > 0.0001) {
        segments.add(_Segment(start: a, end: b, length: len));
      }
    }

    return segments;
  }

  _PathSample _sampleAtDistance(List<_Segment> segments, double d) {
    double remaining = d;

    for (final s in segments) {
      if (remaining <= s.length) {
        final t = remaining / s.length;

        final Offset pos = Offset(
          s.start.dx + (s.end.dx - s.start.dx) * t,

          s.start.dy + (s.end.dy - s.start.dy) * t,
        );

        final double angle = math.atan2(
          s.end.dy - s.start.dy,

          s.end.dx - s.start.dx,
        );

        return _PathSample(position: pos, angle: angle, valid: true);
      }

      remaining -= s.length;
    }

    return _PathSample(position: Offset.zero, angle: 0, valid: false);
  }

  void _drawPath(
    Canvas canvas,

    Paint paint,

    List<Offset> points,

    DrawingTool tool,
  ) {
    if (points.isEmpty) return;

    switch (tool) {
      case DrawingTool.brush:
      case DrawingTool.pencil:
      case DrawingTool.eraser:
        if (points.length == 1) {
          canvas.drawPoints(ui.PointMode.points, points, paint);
        } else {
          canvas.drawPoints(ui.PointMode.polygon, points, paint);
        }

        break;

      case DrawingTool.textPath:
        break;

      case DrawingTool.line:
      case DrawingTool.dottedLine:
        if (points.length >= 2) {
          canvas.drawLine(points.first, points.last, paint);
        }

        break;

      case DrawingTool.arrow:
      case DrawingTool.dottedArrow:
        if (points.length >= 2) {
          canvas.drawLine(points.first, points.last, paint);

          _drawArrowhead(canvas, paint, points.first, points.last);
        }

        break;

      case DrawingTool.rectangle:
        if (points.length >= 2) {
          final rect = Rect.fromPoints(points.first, points.last);

          canvas.drawRect(rect, paint);
        }

        break;

      case DrawingTool.circle:
        if (points.length >= 2) {
          final center = Offset(
            (points.first.dx + points.last.dx) / 2,

            (points.first.dy + points.last.dy) / 2,
          );

          final radius = (points.first - points.last).distance / 2;

          canvas.drawCircle(center, radius, paint);
        }

        break;

      case DrawingTool.triangle:
        if (points.length >= 2) {
          _drawTriangle(canvas, paint, points.first, points.last);
        }

        break;
    }
  }

  void _drawDottedPath(Canvas canvas, Paint paint, List<Offset> points) {
    if (points.length < 2) return;

    const double dashLength = 6.0;

    const double gapLength = 6.0;

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];

      final end = points[i + 1];

      final totalLength = (end - start).distance;

      final direction = (end - start) / totalLength;

      double drawn = 0.0;

      while (drawn < totalLength) {
        final currentStart = start + direction * drawn;

        final currentEnd =
            start + direction * (drawn + dashLength).clamp(0.0, totalLength);

        canvas.drawLine(currentStart, currentEnd, paint);

        drawn += dashLength + gapLength;
      }
    }
  }

  void _drawArrowhead(Canvas canvas, Paint paint, Offset start, Offset end) {
    const double arrowHeadLength = 12.0;

    const double arrowHeadAngle = 25 * math.pi / 180;

    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowHeadLength * math.cos(angle - arrowHeadAngle),

        end.dy - arrowHeadLength * math.sin(angle - arrowHeadAngle),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowHeadLength * math.cos(angle + arrowHeadAngle),

        end.dy - arrowHeadLength * math.sin(angle + arrowHeadAngle),
      );

    canvas.drawPath(path, paint);
  }

  void _drawTriangle(Canvas canvas, Paint paint, Offset start, Offset end) {
    final Rect rect = Rect.fromPoints(start, end);

    final Offset top = Offset(rect.center.dx, rect.top);

    final Offset left = Offset(rect.left, rect.bottom);

    final Offset right = Offset(rect.right, rect.bottom);

    final Path path = Path()
      ..moveTo(top.dx, top.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MultiStrokeDrawingPainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}

// Robust parsing helpers for loaded project data
Offset? _parseOffset(dynamic value) {
  if (value == null) return null;
  if (value is Offset) return value;
  if (value is Map) {
    final dx = (value['dx'] as num?)?.toDouble() ?? 0.0;
    final dy = (value['dy'] as num?)?.toDouble() ?? 0.0;
    return Offset(dx, dy);
  }
  return null;
}

FontWeight _parseFontWeight(dynamic value) {
  if (value is FontWeight) return value;
  if (value is int) {
    return FontWeight.values.firstWhere(
      (e) => e.index == value,
      orElse: () => FontWeight.normal,
    );
  }
  if (value is Map && value['enum'] is String) {
    final name = (value['enum'] as String).toLowerCase();
    switch (name) {
      case 'w100':
        return FontWeight.w100;
      case 'w200':
        return FontWeight.w200;
      case 'w300':
        return FontWeight.w300;
      case 'w400':
        return FontWeight.w400;
      case 'w500':
        return FontWeight.w500;
      case 'w600':
        return FontWeight.w600;
      case 'w700':
        return FontWeight.w700;
      case 'w800':
        return FontWeight.w800;
      case 'w900':
        return FontWeight.w900;
    }
  }
  if (value is String) {
    // Accept names like 'bold', 'normal'
    switch (value.toLowerCase()) {
      case 'bold':
        return FontWeight.bold;
      case 'normal':
        return FontWeight.normal;
    }
  }
  return FontWeight.normal;
}

FontStyle _parseFontStyle(dynamic value) {
  if (value is FontStyle) return value;
  if (value is int) {
    return FontStyle.values.firstWhere(
      (e) => e.index == value,
      orElse: () => FontStyle.normal,
    );
  }
  if (value is Map && value['enum'] is String) {
    return (value['enum'] as String).toLowerCase() == 'italic'
        ? FontStyle.italic
        : FontStyle.normal;
  }
  if (value is String) {
    return value.toLowerCase() == 'italic'
        ? FontStyle.italic
        : FontStyle.normal;
  }
  return FontStyle.normal;
}

class _ShapePainter extends CustomPainter {
  final Map<String, dynamic> props;

  _ShapePainter(this.props);

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    final String shape =
        (props['shape'] as String?)?.toLowerCase() ?? 'rectangle';

    final double strokeWidth = (props['strokeWidth'] as double?) ?? 0.0;

    final Color fillColor =
        (props['fillColor'] as HiveColor?)?.toColor() ?? Colors.green;

    final Color strokeColor =
        (props['strokeColor'] as HiveColor?)?.toColor() ?? Colors.green;

    final bool hasGradient = (props['hasGradient'] as bool?) ?? false;

    final List<Color> gradientColors =
        (props['gradientColors'] as List<dynamic>?)
            ?.map(
              (e) => (e is HiveColor ? e : (e is int ? HiveColor(e) : null))
                  ?.toColor(),
            )
            .whereType<Color>()
            .toList() ??
        [];

    final double cornerRadius = (props['cornerRadius'] as double?) ?? 12.0;

    final ui.Image? fillImage = props['image'] as ui.Image?;

    final bool hasShadow = (props['hasShadow'] as bool?) ?? false;

    final HiveColor shadowColorHive = (props['shadowColor'] is HiveColor)
        ? (props['shadowColor'] as HiveColor)
        : (props['shadowColor'] is Color)
        ? HiveColor.fromColor(props['shadowColor'] as Color)
        : HiveColor.fromColor(Colors.black54);

    final double shadowBlur = (props['shadowBlur'] as double?) ?? 8.0;

    final Offset shadowOffset =
        (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);

    final double shadowOpacity = (props['shadowOpacity'] as double?) ?? 0.6;

    final double gradientAngle = (props['gradientAngle'] as double?) ?? 0.0;

    final Path path = _buildPath(shape, rect, cornerRadius);

    if (hasShadow) {
      canvas.save();

      canvas.translate(shadowOffset.dx, shadowOffset.dy);

      // drawShadow uses elevation to approximate blur

      canvas.drawShadow(
        path,

        shadowColorHive.toColor().withOpacity(shadowOpacity.clamp(0.0, 1.0)),

        shadowBlur,

        true,
      );

      canvas.restore();
    }

    if (fillImage != null) {
      // Draw image clipped to the shape path using BoxFit.cover

      canvas.save();

      canvas.clipPath(path);

      final Size imageSize = Size(
        fillImage.width.toDouble(),

        fillImage.height.toDouble(),
      );

      final FittedSizes fitted = applyBoxFit(BoxFit.cover, imageSize, size);

      final Rect inputSubrect = Alignment.center.inscribe(
        fitted.source,

        Offset.zero & imageSize,
      );

      final Rect outputSubrect = Alignment.center.inscribe(
        fitted.destination,

        rect,
      );

      canvas.drawImageRect(
        fillImage,

        inputSubrect,

        outputSubrect,

        Paint()..isAntiAlias = true,
      );

      canvas.restore();
    } else {
      final Paint fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true;

      if (hasGradient) {
        final double rad = gradientAngle * math.pi / 185.0;

        final double cx = math.cos(rad);

        final double sy = math.sin(rad);

        final Alignment begin = Alignment(-cx, -sy);

        final Alignment end = Alignment(cx, sy);

        fillPaint.shader = LinearGradient(
          colors: gradientColors,

          begin: begin,

          end: end,
        ).createShader(rect);
      } else {
        fillPaint.color = fillColor;
      }

      canvas.drawPath(path, fillPaint);
    }

    if (strokeWidth > 0) {
      final Paint strokePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = strokeColor
        ..isAntiAlias = true;

      canvas.drawPath(path, strokePaint);
    }
  }

  Path _buildPath(String shape, Rect rect, double cornerRadius) {
    switch (shape) {
      case 'circle':
        return Path()..addOval(rect);

      case 'rectangle':
      case 'square':
        return _rectanglePath(rect, cornerRadius);

      case 'triangle':
        return _trianglePath(rect, cornerRadius);

      case 'diamond':
        return _diamondPath(rect, cornerRadius);

      case 'hexagon':
        return _regularPolygonPath(rect, 6, cornerRadius);

      case 'star':
        return _starRoundedPath(rect, 5, cornerRadius);

      case 'heart':
        return _heartPathAccurate(rect, cornerRadius);

      default:
        return _rectanglePath(rect, cornerRadius);
    }
  }

  Path _rectanglePath(Rect rect, double cornerRadius) {
    // Check if individual side lengths are available and different from default

    final double? topSide = props['topSide'] as double?;

    final double? rightSide = props['rightSide'] as double?;

    final double? bottomSide = props['bottomSide'] as double?;

    final double? leftSide = props['leftSide'] as double?;

    // Only use custom rectangle path if side lengths are explicitly set and different from default

    // This prevents unnecessary use of custom path for regular squares/rectangles

    final bool hasCustomSides =
        (topSide != null && topSide != rect.width) ||
        (rightSide != null && rightSide != rect.height) ||
        (bottomSide != null && bottomSide != rect.width) ||
        (leftSide != null && leftSide != rect.height);

    if (hasCustomSides) {
      return _createCustomRectanglePath(
        rect,

        topSide ?? rect.width,

        rightSide ?? rect.height,

        bottomSide ?? rect.width,

        leftSide ?? rect.height,

        cornerRadius,
      );
    }

    // Check if individual corner radius values are available

    final double? topLeftRadius = props['topLeftRadius'] as double?;

    final double? topRightRadius = props['topRightRadius'] as double?;

    final double? bottomLeftRadius = props['bottomLeftRadius'] as double?;

    final double? bottomRightRadius = props['bottomRightRadius'] as double?;

    // If individual corner radius values are provided, use them

    if (topLeftRadius != null ||
        topRightRadius != null ||
        bottomLeftRadius != null ||
        bottomRightRadius != null) {
      return Path()..addRRect(
        RRect.fromLTRBAndCorners(
          rect.left,

          rect.top,

          rect.right,

          rect.bottom,

          topLeft: Radius.circular(topLeftRadius ?? 0.0),

          topRight: Radius.circular(topRightRadius ?? 0.0),

          bottomLeft: Radius.circular(bottomLeftRadius ?? 0.0),

          bottomRight: Radius.circular(bottomRightRadius ?? 0.0),
        ),
      );
    }

    // Otherwise, use the uniform corner radius

    return Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius)));
  }

  Path _createCustomRectanglePath(
    Rect rect,

    double topSide,

    double rightSide,

    double bottomSide,

    double leftSide,

    double cornerRadius,
  ) {
    final Path path = Path();

    // Calculate the center point

    final double centerX = rect.center.dx;

    final double centerY = rect.center.dy;

    // Calculate corner points to create a quadrilateral

    // For a true quadrilateral, we need to calculate the actual corner positions

    // based on the side lengths and create a polygon

    // Calculate the four corners of the quadrilateral

    final double halfTopSide = topSide / 2;

    final double halfBottomSide = bottomSide / 2;

    final double halfLeftSide = leftSide / 2;

    final double halfRightSide = rightSide / 2;

    // Calculate corner positions

    final Offset topLeft = Offset(
      centerX - halfTopSide,

      centerY - halfLeftSide,
    );

    final Offset topRight = Offset(
      centerX + halfTopSide,

      centerY - halfRightSide,
    );

    final Offset bottomLeft = Offset(
      centerX - halfBottomSide,

      centerY + halfLeftSide,
    );

    final Offset bottomRight = Offset(
      centerX + halfBottomSide,

      centerY + halfRightSide,
    );

    // Create a quadrilateral path with proper rounded corners

    if (cornerRadius > 0) {
      // Start from top-left corner, accounting for corner radius

      path.moveTo(topLeft.dx + cornerRadius, topLeft.dy);

      // Top side to top-right corner

      path.lineTo(topRight.dx - cornerRadius, topRight.dy);

      // Top-right rounded corner

      path.quadraticBezierTo(
        topRight.dx,

        topRight.dy,

        topRight.dx,

        topRight.dy + cornerRadius,
      );

      // Right side to bottom-right corner

      path.lineTo(bottomRight.dx, bottomRight.dy - cornerRadius);

      // Bottom-right rounded corner

      path.quadraticBezierTo(
        bottomRight.dx,

        bottomRight.dy,

        bottomRight.dx - cornerRadius,

        bottomRight.dy,
      );

      // Bottom side to bottom-left corner

      path.lineTo(bottomLeft.dx + cornerRadius, bottomLeft.dy);

      // Bottom-left rounded corner

      path.quadraticBezierTo(
        bottomLeft.dx,

        bottomLeft.dy,

        bottomLeft.dx,

        bottomLeft.dy - cornerRadius,
      );

      // Left side to top-left corner

      path.lineTo(topLeft.dx, topLeft.dy + cornerRadius);

      // Top-left rounded corner

      path.quadraticBezierTo(
        topLeft.dx,

        topLeft.dy,

        topLeft.dx + cornerRadius,

        topLeft.dy,
      );

      path.close(); // Close the path
    } else {
      // No rounded corners - create sharp quadrilateral

      path.moveTo(topLeft.dx, topLeft.dy);

      path.lineTo(topRight.dx, topRight.dy);

      path.lineTo(bottomRight.dx, bottomRight.dy);

      path.lineTo(bottomLeft.dx, bottomLeft.dy);

      path.close();
    }

    return path;
  }

  Path _trianglePath(Rect rect, double radius) {
    // Check if individual corner radius values are available for triangle

    final double? topRadius = props['topRadius'] as double?;

    final double? bottomRightRadius = props['bottomRightRadius'] as double?;

    final double? bottomLeftRadius = props['bottomLeftRadius'] as double?;

    // Check if we should use individual corner radius values

    // Only use individual radii if at least one has been explicitly set to a non-zero value

    // and we're not using the uniform corner radius slider

    final bool useIndividualRadii =
        (topRadius != null && topRadius > 0) ||
        (bottomRightRadius != null && bottomRightRadius > 0) ||
        (bottomLeftRadius != null && bottomLeftRadius > 0);

    if (useIndividualRadii) {
      final List<Offset> points = [
        Offset(rect.center.dx, rect.top),

        Offset(rect.right, rect.bottom),

        Offset(rect.left, rect.bottom),
      ];

      final List<double> radii = [
        topRadius ?? 0.0,

        bottomRightRadius ?? 0.0,

        bottomLeftRadius ?? 0.0,
      ];

      return _roundedPolygonPathWithIndividualRadii(points, radii);
    }

    // Otherwise, use the uniform corner radius

    final List<Offset> points = [
      Offset(rect.center.dx, rect.top),

      Offset(rect.right, rect.bottom),

      Offset(rect.left, rect.bottom),
    ];

    return _roundedPolygonPath(points, radius);
  }

  Path _diamondPath(Rect rect, double radius) {
    final List<Offset> points = [
      Offset(rect.center.dx, rect.top),

      Offset(rect.right, rect.center.dy),

      Offset(rect.center.dx, rect.bottom),

      Offset(rect.left, rect.center.dy),
    ];

    return _roundedPolygonPath(points, radius);
  }

  Path _regularPolygonPath(Rect rect, int sides, double cornerRadius) {
    final double cx = rect.center.dx;

    final double cy = rect.center.dy;

    final double r = math.min(rect.width, rect.height) / 2;

    final List<Offset> points = List.generate(sides, (i) {
      final double angle = (-math.pi / 2) + (2 * math.pi * i / sides);

      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    });

    return _roundedPolygonPath(points, cornerRadius);
  }

  Path _starRoundedPath(Rect rect, int points, double cornerRadius) {
    final double cx = rect.center.dx;

    final double cy = rect.center.dy;

    final double outerR = math.min(rect.width, rect.height) / 2;

    final double innerR = outerR * 0.5;

    final int total = points * 2;

    final List<Offset> vertices = List.generate(total, (i) {
      final double r = (i % 2 == 0) ? outerR : innerR;

      final double angle = (-math.pi / 2) + (i * math.pi / points);

      return Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
    });

    return _roundedPolygonPath(vertices, cornerRadius);
  }
  // Build a rounded-corner polygon path from ordered vertices

  Path _roundedPolygonPath(List<Offset> vertices, double radius) {
    // If radius is zero or negative, fall back to sharp polygon

    if (radius <= 0) {
      final Path sharp = Path()..moveTo(vertices.first.dx, vertices.first.dy);

      for (int i = 1; i < vertices.length; i++) {
        sharp.lineTo(vertices[i].dx, vertices[i].dy);
      }

      sharp.close();

      return sharp;
    }

    final int n = vertices.length;

    final Path path = Path();

    Offset _trimPoint(Offset from, Offset to, double d) {
      final Offset vec = to - from;

      final double len = vec.distance;

      if (len == 0) return from;

      final double t = (d / len).clamp(0.0, 1.0);

      return from + vec * t;
    }

    // Compute first corner trimmed start point

    for (int i = 0; i < n; i++) {
      final Offset p0 = vertices[(i - 1 + n) % n];

      final Offset p1 = vertices[i];

      final Offset p2 = vertices[(i + 1) % n];

      final Offset v1 = (p0 - p1);

      final Offset v2 = (p2 - p1);

      final double len1 = v1.distance;

      final double len2 = v2.distance;

      if (len1 == 0 || len2 == 0) continue;

      final Offset u1 = v1 / len1;

      final Offset u2 = v2 / len2;

      // Angle between incoming and outgoing edges

      final double dot = (u1.dx * u2.dx + u1.dy * u2.dy).clamp(-1.0, 1.0);

      final double theta = math.acos(dot);

      // Avoid division by zero for straight lines

      final double tangent = math.tan(theta / 2);

      double offsetDist = tangent == 0 ? 0 : (radius / tangent);

      // Limit by half of each adjacent edge

      offsetDist = math.min(offsetDist, math.min(len1, len2) / 2 - 0.01);

      if (offsetDist.isNaN || offsetDist.isInfinite || offsetDist < 0) {
        offsetDist = 0;
      }

      final Offset start = _trimPoint(p1, p0, offsetDist);

      final Offset end = _trimPoint(p1, p2, offsetDist);

      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }

      // Use quadratic curve with control at the original vertex to handle concave and convex cases

      path.quadraticBezierTo(p1.dx, p1.dy, end.dx, end.dy);
    }

    path.close();

    return path;
  }

  // Build a rounded-corner polygon path with individual radii for each corner

  Path _roundedPolygonPathWithIndividualRadii(
    List<Offset> vertices,

    List<double> radii,
  ) {
    final int n = vertices.length;

    final Path path = Path();

    Offset _trimPoint(Offset from, Offset to, double d) {
      final Offset vec = to - from;

      final double len = vec.distance;

      if (len == 0) return from;

      final double t = (d / len).clamp(0.0, 1.0);

      return from + vec * t;
    }

    // Compute first corner trimmed start point

    for (int i = 0; i < n; i++) {
      final double radius = radii[i];

      final Offset p0 = vertices[(i - 1 + n) % n];

      final Offset p1 = vertices[i];

      final Offset p2 = vertices[(i + 1) % n];

      final Offset v1 = (p0 - p1);

      final Offset v2 = (p2 - p1);

      final double len1 = v1.distance;

      final double len2 = v2.distance;

      if (len1 == 0 || len2 == 0) continue;

      final Offset u1 = v1 / len1;

      final Offset u2 = v2 / len2;

      // Angle between incoming and outgoing edges

      final double dot = (u1.dx * u2.dx + u1.dy * u2.dy).clamp(-1.0, 1.0);

      final double theta = math.acos(dot);

      // Avoid division by zero for straight lines

      final double tangent = math.tan(theta / 2);

      double offsetDist = tangent == 0 ? 0 : (radius / tangent);

      // Limit by half of each adjacent edge

      offsetDist = math.min(offsetDist, math.min(len1, len2) / 2 - 0.01);

      if (offsetDist.isNaN || offsetDist.isInfinite || offsetDist < 0) {
        offsetDist = 0;
      }

      final Offset start = _trimPoint(p1, p0, offsetDist);

      final Offset end = _trimPoint(p1, p2, offsetDist);

      if (i == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }

      // Use quadratic curve with control at the original vertex to handle concave and convex cases

      path.quadraticBezierTo(p1.dx, p1.dy, end.dx, end.dy);
    }

    path.close();

    return path;
  }

  // removed arrow path per request

  Path _heartPathAccurate(Rect rect, double radius) {
    final Path path = Path();

    final double w = rect.width;

    final double h = rect.height;

    final double x = rect.left;

    final double y = rect.top;

    final double cx = x + w / 2;

    // Dip at the top (between the lobes)

    final double dipY = y + h * 0.25;

    // Start at dip

    path.moveTo(cx, dipY);

    // Left lobe top curve

    path.cubicTo(
      cx - w * 0.25,

      y, // control 1

      x,

      y + h * 0.25, // control 2

      x,

      y + h * 0.45, // end of left lobe curve
    );

    // Left bottom curve

    path.cubicTo(
      x,

      y + h * 0.75,

      cx - w * 0.25,

      y + h * 0.9,

      cx,

      y + h, // bottom tip
    );

    // Right bottom curve

    path.cubicTo(
      cx + w * 0.25,

      y + h * 0.9,

      x + w,

      y + h * 0.75,

      x + w,

      y + h * 0.45,
    );

    // Right lobe top curve

    path.cubicTo(
      x + w,

      y + h * 0.25,

      cx + w * 0.25,

      y,

      cx,

      dipY, // back to dip
    );

    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) {
    // Repaint whenever the parent rebuilds to reflect in-place mutations to props

    return true;
  }
}

class _PosterMakerScreenState extends State<PosterMakerScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int selectedTabIndex = 0;

  List<CanvasItem> canvasItems = [];

  CanvasItem? selectedItem;

  bool showBottomSheet = false;

  bool snapToGrid = false;

  double canvasZoom = 1.0;

  int editTopbarTabIndex = 0; // 0: General, 1: Type

  final ImagePicker _imagePicker = ImagePicker();

  final GlobalKey _canvasRepaintKey = GlobalKey();

  // Nudge control timers for press-and-hold behavior

  Timer? _nudgeRepeatTimer;

  Timer? _nudgeInitialDelayTimer;

  static const Duration _nudgeInitialDelay = Duration(milliseconds: 300);

  static const Duration _nudgeRepeatInterval = Duration(milliseconds: 60);

  static const double _nudgeStep = 4.0; // base pixels per nudge

  // Undo/Redo system

  List<CanvasAction> actionHistory = [];

  int currentActionIndex = -1;

  // Animation controllers

  late AnimationController _bottomSheetController;

  late Animation<double> _bottomSheetAnimation;

  late AnimationController _selectionController;

  late Animation<double> _selectionAnimation;

  late AnimationController _itemAddController;

  late Animation<double> _itemAddAnimation;

  // Temp previous states for gesture-based history

  CanvasItem? _preDragState;

  CanvasItem? _preTransformState;

  final List<String> tabTitles = ['Text', 'Images', 'Shapes', 'Drawing'];

  // Drawing state variables

  DrawingTool selectedDrawingTool = DrawingTool.brush;

  DrawingMode drawingMode = DrawingMode.disabled;

  List<DrawingLayer> drawingLayers = [];

  Color drawingColor = Colors.black;

  double drawingStrokeWidth = 2.0;

  double drawingOpacity = 1.0;

  bool isDrawing = false;

  List<Offset> currentDrawingPoints = [];

  bool showDrawingToolSelection = true; // Show tool selection first

  bool showDrawingControls = false; // Show controls after tool selection

  DateTime? _lastDrawingUpdate;

  // Remembers last non-eraser tool to restore after toggling eraser off

  DrawingTool? _previousNonEraserTool;

  // Text along path current input

  String? _currentPathText = '';

  String? _currentPathFontFamily;

  double? _currentPathLetterSpacing;

  // Text items now driven by liked Google Fonts with a leading plus button

  List<String> get likedFontFamilies => FontFavorites.instance.likedFamilies;

  // Removed sample image icons; Images tab now only supports uploads

  final List<Map<String, dynamic>> sampleShapes = const [
    {'shape': 'rectangle', 'icon': Icons.crop_square_rounded},

    {'shape': 'circle', 'icon': Icons.circle_outlined},

    {'shape': 'triangle', 'icon': Icons.change_history_rounded},

    {'shape': 'hexagon', 'icon': Icons.hexagon_outlined},

    {'shape': 'diamond', 'icon': Icons.crop_square_rounded},

    {'shape': 'star', 'icon': Icons.star_border_rounded},

    {'shape': 'heart', 'icon': Icons.favorite_border_rounded},
  ];

  List<Map<String, dynamic>> _getDrawingTools() {
    return [
      {'tool': DrawingTool.textPath, 'icon': Icons.title, 'name': 'Text Path'},

      {'tool': DrawingTool.brush, 'icon': Icons.brush, 'name': 'Brush'},

      {'tool': DrawingTool.line, 'icon': Icons.horizontal_rule, 'name': 'Line'},

      {'tool': DrawingTool.arrow, 'icon': Icons.arrow_forward, 'name': 'Arrow'},

      {
        'tool': DrawingTool.dottedLine,

        'icon': Icons.more_horiz,

        'name': 'Dotted Line',
      },
    ];
  }

  // Recent colors for color picker

  List<Color> recentColors = [];

  final List<Color> favoriteColors = [
    Colors.black,

    Colors.redAccent,

    Colors.blueAccent,

    Colors.greenAccent,
  ];

  PosterProject? _currentProject;

  late Box<PosterProject> _projectBox;

  late Box<UserPreferences> _userPreferencesBox;

  late UserPreferences userPreferences;

  Timer? _autoSaveTimer;
  bool _isAutoSaving = false;
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _projectBox = Hive.box<PosterProject>('posterProjects');

    _userPreferencesBox = Hive.box<UserPreferences>('userPreferences');

    userPreferences =
        _userPreferencesBox.get('user_prefs_id') ?? UserPreferences();

    // Initialize auto-save timer based on user preferences

    _initializeAutoSave();

    // Initialize background remover

    BackgroundRemover.instance.initializeOrt();

    if (widget.projectId != null) {
      _currentProject = _projectBox.get(widget.projectId);

      if (_currentProject != null) {
        // Convert HiveCanvasItems back to CanvasItems and load images

        _loadProjectData();
      }
    } else {
      _currentProject = PosterProject(
        id: DateTime.now().millisecondsSinceEpoch.toString(),

        name: 'New Project',

        createdAt: DateTime.now(),

        lastModified: DateTime.now(),

        canvasItems: [],

        settings: ProjectSettings(exportSettings: ExportSettings()),
        canvasWidth: widget.initialCanvasWidth ?? 1080,
        canvasHeight: widget.initialCanvasHeight ?? 1920,
        backgroundImagePath: widget.initialBackgroundImagePath,
      );

      _projectBox.put(_currentProject!.id, _currentProject!);
    }

    _bottomSheetController = AnimationController(
      duration: const Duration(milliseconds: 350),

      vsync: this,
    );

    _bottomSheetAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _bottomSheetController,

        curve: Curves.easeOutCubic,
      ),
    );

    _selectionController = AnimationController(
      duration: const Duration(milliseconds: 200),

      vsync: this,
    );

    _selectionAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _selectionController, curve: Curves.elasticOut),
    );

    _itemAddController = AnimationController(
      duration: const Duration(milliseconds: 400),

      vsync: this,
    );

    _itemAddAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _itemAddController, curve: Curves.elasticOut),
    );

    if (_currentProject != null) {
      // Always use the canonical converter to properly rehydrate drawings

      // (including text-path strokes) instead of shallow-mapping properties.

      // This ensures brushes/text-path data are restored after app restart.

      _loadProjectData();
    } else {
      canvasItems = [];
    }

    if (userPreferences.recentColors.isEmpty) {
      userPreferences.recentColors = [
        Colors.black,

        Colors.redAccent,

        Colors.blueAccent,

        Colors.greenAccent,
      ].map((e) => HiveColor.fromColor(e)).toList();
    }

    if (userPreferences.recentColors.isNotEmpty) {
      final List<HiveColor> hiveRecentColors = List<HiveColor>.from(
        userPreferences.recentColors,
      );

      for (var recentColor in hiveRecentColors) {
        recentColors.add(recentColor.toColor());
      }
    }
  }

  @override
  void dispose() {
    _isDisposing = true;
    _autoSaveTimer?.cancel();
    _saveProject(showIndicator: false, saveThumbnail: false);

    WidgetsBinding.instance.removeObserver(this);

    _bottomSheetController.dispose();

    _selectionController.dispose();

    _itemAddController.dispose();

    _cancelNudgeTimers();

    BackgroundRemover.instance.dispose();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposing) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _saveProject(showIndicator: false, saveThumbnail: false);
    }
  }

  void _initializeAutoSave() {
    _autoSaveTimer?.cancel();

    if (userPreferences.autoSave) {
      _autoSaveTimer = Timer.periodic(
        Duration(seconds: userPreferences.autoSaveInterval),

        (timer) {
          _saveProject();
        },
      );
    }
  }

  Future<void> _loadProjectData() async {
    if (_currentProject != null) {
      canvasItems = await _convertHiveItemsToCanvas(
        _currentProject!.canvasItems,
      );

      if (mounted) {
        setState(() {});
      }
    }
  }

  void _saveProject({bool showIndicator = true, bool saveThumbnail = true}) {
    if (_currentProject != null) {
      _currentProject!.lastModified = DateTime.now();

      // Convert current CanvasItems to HiveCanvasItems before saving

      _currentProject!.canvasItems = canvasItems
          .map((item) => _convertCanvasItemToHive(item))
          .toList();

      _projectBox.put(_currentProject!.id, _currentProject!);

      if (saveThumbnail && mounted && !_isDisposing) {
        _generateAndStoreThumbnail(_currentProject!);
      }

      // Show auto-save indicator
      if (showIndicator && userPreferences.autoSave && !_isDisposing) {
        _showAutoSaveIndicator();
      }
    }
  }

  void _showAutoSaveIndicator() {
    if (!mounted || _isDisposing) return;

    // Set autosave state to show progress indicator
    setState(() {
      _isAutoSaving = true;
    });

    // Hide progress indicator after 2 seconds
    Timer(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
        });
      }
    });
  }

  Future<void> _generateAndStoreThumbnail(PosterProject project) async {
    try {
      final boundary =
          _canvasRepaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      // Low pixel ratio for light-weight thumbnail
      final ui.Image image = await boundary.toImage(pixelRatio: 1.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory thumbsDir = Directory('${appDir.path}/thumbnails');
      if (!thumbsDir.existsSync()) {
        thumbsDir.createSync(recursive: true);
      }

      final String filePath = '${thumbsDir.path}/${project.id}.png';
      final File file = File(filePath);
      await file.writeAsBytes(pngBytes, flush: true);

      // Update project with thumbnail path if changed
      if (project.thumbnailPath != filePath) {
        project.thumbnailPath = filePath;
        _projectBox.put(project.id, project);
      }
    } catch (_) {
      // Ignore thumbnail errors; not critical for saving
    }
  }

  void _updateUserPreferences(UserPreferences newPreferences) {
    userPreferences = newPreferences;

    _userPreferencesBox.put('user_prefs_id', userPreferences);

    _initializeAutoSave(); // Reinitialize auto-save with new preferences
  }

  HiveCanvasItem _convertCanvasItemToHive(CanvasItem item) {
    // Create a copy of properties to avoid modifying the original

    Map<String, dynamic> hiveProperties = Map<String, dynamic>.from(
      item.properties,
    );

    // Normalize drawing strokes to Hive-friendly values

    if (item.type == CanvasItemType.drawing) {
      final List<Map<String, dynamic>>? strokes =
          (hiveProperties['strokes'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList();

      if (strokes != null) {
        final List<Map<String, dynamic>> normalized = [];

        for (final stroke in strokes) {
          final dynamic colorRaw = stroke['color'];

          // Ensure color is stored as HiveColor

          final HiveColor hiveColor = colorRaw is HiveColor
              ? colorRaw
              : (colorRaw is Color
                    ? HiveColor.fromColor(colorRaw)
                    : (colorRaw is int
                          ? HiveColor(colorRaw)
                          : HiveColor.fromColor(Colors.black)));

          final dynamic toolRaw = stroke['tool'];

          final String toolName = toolRaw is Enum
              ? toolRaw.name
              : (toolRaw is String ? toolRaw : DrawingTool.brush.name);

          final List<Offset> points =
              (stroke['points'] as List<dynamic>?)
                  ?.map<Offset>((p) => _parseOffset(p) ?? const Offset(0, 0))
                  .toList() ??
              <Offset>[];

          normalized.add({
            'tool': toolName,

            'color': hiveColor,

            'strokeWidth': (stroke['strokeWidth'] as num?)?.toDouble() ?? 2.0,

            'opacity': (stroke['opacity'] as num?)?.toDouble() ?? 1.0,

            'isDotted': (stroke['isDotted'] as bool?) ?? false,

            'points': points,

            // Text-path specific
            'text': (stroke['text'] as String?) ?? '',

            'fontSize': (stroke['fontSize'] as num?)?.toDouble() ?? 24.0,

            'letterSpacing':
                (stroke['letterSpacing'] as num?)?.toDouble() ?? 0.0,

            'fontFamily': (stroke['fontFamily'] as String?) ?? 'Roboto',

            // Preserve optional style info if present
            if (stroke.containsKey('fontWeight'))
              'fontWeight': stroke['fontWeight'],

            if (stroke.containsKey('fontStyle'))
              'fontStyle': stroke['fontStyle'],
          });
        }

        hiveProperties['strokes'] = normalized;
      }
    }

    // Handle ui.Image serialization for shapes

    if (item.type == CanvasItemType.shape &&
        hiveProperties.containsKey('image')) {
      final ui.Image? image = hiveProperties['image'] as ui.Image?;

      if (image != null) {
        // Remove the ui.Image object as it cannot be serialized

        hiveProperties.remove('image');

        // Keep the imagePath for reconstruction

        if (!hiveProperties.containsKey('imagePath')) {
          // If no imagePath exists, we need to save the image to a file

          _saveImageToFile(image, item.id);
        }
      }
    }

    return HiveCanvasItem(
      id: item.id,

      type: HiveCanvasItemType.values.firstWhere(
        (e) =>
            e.toString().split('.').last ==
            item.type.toString().split('.').last,
      ),

      position: item.position,

      scale: item.scale,

      rotation: item.rotation,

      opacity: item.opacity,

      layerIndex: item.layerIndex,

      isVisible: item.isVisible,

      isLocked: item.isLocked,

      properties: hiveProperties,

      createdAt: item.createdAt,

      lastModified: item.lastModified,

      groupId: item.groupId,
    );
  }

  Future<void> _saveImageToFile(ui.Image image, String itemId) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();

      final String imagePath =
          '${tempDir.path}/shape_image_${itemId}_${DateTime.now().millisecondsSinceEpoch}.png';

      // Convert ui.Image to bytes

      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final File file = File(imagePath);

        await file.writeAsBytes(byteData.buffer.asUint8List());

        // Update the item's imagePath property

        final itemIndex = canvasItems.indexWhere((item) => item.id == itemId);

        if (itemIndex != -1) {
          canvasItems[itemIndex].properties['imagePath'] = imagePath;
        }
      }
    } catch (e) {
      print('Error saving image to file: $e');
    }
  }

  Future<List<CanvasItem>> _convertHiveItemsToCanvas(
    List<HiveCanvasItem> hiveItems,
  ) async {
    List<CanvasItem> items = [];

    for (final hiveItem in hiveItems) {
      Map<String, dynamic> properties = Map<String, dynamic>.from(
        hiveItem.properties,
      );

      // Rehydrate drawing strokes (convert 'tool' string back to enum, ensure colors)

      if (hiveItem.type == HiveCanvasItemType.drawing &&
          properties.containsKey('strokes')) {
        final List<dynamic>? rawStrokes =
            properties['strokes'] as List<dynamic>?;

        final List<Map<String, dynamic>>? strokes = rawStrokes?.map((e) {
          // Some persisted entries may be Map<dynamic, dynamic> – normalize to Map<String, dynamic>

          final Map raw = e as Map;

          return raw.map((key, value) => MapEntry(key.toString(), value));
        }).toList();

        if (strokes != null) {
          final List<Map<String, dynamic>> rehydrated = [];

          for (final stroke in strokes) {
            final dynamic colorRaw = stroke['color'];

            final HiveColor hiveColor = colorRaw is HiveColor
                ? colorRaw
                : (colorRaw is Color
                      ? HiveColor.fromColor(colorRaw)
                      : (colorRaw is int
                            ? HiveColor(colorRaw)
                            : HiveColor.fromColor(Colors.black)));

            final dynamic toolRaw = stroke['tool'];

            final DrawingTool tool = toolRaw is String
                ? DrawingTool.values.firstWhere(
                    (t) => t.name == toolRaw,

                    orElse: () => DrawingTool.brush,
                  )
                : (toolRaw is DrawingTool ? toolRaw : DrawingTool.brush);

            final List<Offset> points =
                (stroke['points'] as List<dynamic>?)
                    ?.map<Offset>((p) => _parseOffset(p) ?? const Offset(0, 0))
                    .toList() ??
                <Offset>[];

            // Rehydrate optional font props if they were serialized as {"enum": name}
            FontWeight? parsedFontWeight;
            final dynamic fwRaw = stroke['fontWeight'];
            if (fwRaw is FontWeight) {
              parsedFontWeight = fwRaw;
            } else if (fwRaw is Map && fwRaw['enum'] is String) {
              switch ((fwRaw['enum'] as String).toLowerCase()) {
                case 'w100':
                  parsedFontWeight = FontWeight.w100;
                  break;
                case 'w200':
                  parsedFontWeight = FontWeight.w200;
                  break;
                case 'w300':
                  parsedFontWeight = FontWeight.w300;
                  break;
                case 'w400':
                  parsedFontWeight = FontWeight.w400;
                  break;
                case 'w500':
                  parsedFontWeight = FontWeight.w500;
                  break;
                case 'w600':
                  parsedFontWeight = FontWeight.w600;
                  break;
                case 'w700':
                  parsedFontWeight = FontWeight.w700;
                  break;
                case 'w800':
                  parsedFontWeight = FontWeight.w800;
                  break;
                case 'w900':
                  parsedFontWeight = FontWeight.w900;
                  break;
              }
            }

            FontStyle? parsedFontStyle;
            final dynamic fsRaw = stroke['fontStyle'];
            if (fsRaw is FontStyle) {
              parsedFontStyle = fsRaw;
            } else if (fsRaw is Map && fsRaw['enum'] is String) {
              parsedFontStyle =
                  (fsRaw['enum'] as String).toLowerCase() == 'italic'
                  ? FontStyle.italic
                  : FontStyle.normal;
            }

            rehydrated.add({
              'tool': tool,

              'color': hiveColor,

              'strokeWidth': (stroke['strokeWidth'] as num?)?.toDouble() ?? 2.0,

              'opacity': (stroke['opacity'] as num?)?.toDouble() ?? 1.0,

              'isDotted': (stroke['isDotted'] as bool?) ?? false,

              'points': points,

              'text': (stroke['text'] as String?) ?? '',

              'fontSize': (stroke['fontSize'] as num?)?.toDouble() ?? 24.0,

              'letterSpacing':
                  (stroke['letterSpacing'] as num?)?.toDouble() ?? 0.0,

              'fontFamily': (stroke['fontFamily'] as String?) ?? 'Roboto',

              if (parsedFontWeight != null) 'fontWeight': parsedFontWeight,

              if (parsedFontStyle != null) 'fontStyle': parsedFontStyle,
            });
          }

          properties['strokes'] = rehydrated;
        }
      }

      // Load image for shapes if imagePath exists

      if (hiveItem.type == HiveCanvasItemType.shape &&
          properties.containsKey('imagePath')) {
        final String? imagePath = properties['imagePath'] as String?;

        if (imagePath != null) {
          try {
            final File imageFile = File(imagePath);

            if (await imageFile.exists()) {
              final Uint8List imageBytes = await imageFile.readAsBytes();

              final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);

              final ui.FrameInfo frame = await codec.getNextFrame();

              final ui.Image image = frame.image;

              properties['image'] = image;
            }
          } catch (e) {
            print('Error loading image from file: $e');
          }
        }
      }

      // Also support embedded base64 for shapes (cross-device portability)
      if (hiveItem.type == HiveCanvasItemType.shape &&
          properties['image'] == null) {
        // Prefer nested shapeProperties.imageBase64 if present
        String? imageBase64;
        if (properties['shapeProperties'] is Map<String, dynamic>) {
          final Map<String, dynamic> sp = Map<String, dynamic>.from(
            properties['shapeProperties'] as Map,
          );
          final String? nested = sp['imageBase64'] as String?;
          if (nested != null && nested.isNotEmpty) {
            imageBase64 = nested;
          }
        }
        // Fallback to top-level imageBase64 if provided
        imageBase64 ??= properties['imageBase64'] as String?;

        if (imageBase64 != null && imageBase64.isNotEmpty) {
          try {
            final Uint8List imageBytes = base64Decode(imageBase64);
            final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
            final ui.FrameInfo frame = await codec.getNextFrame();
            final ui.Image image = frame.image;
            properties['image'] = image;
          } catch (e) {
            print('Error decoding base64 shape image: $e');
          }
        }
      }

      final CanvasItem item = CanvasItem(
        id: hiveItem.id,

        type: CanvasItemType.values.firstWhere(
          (e) =>
              e.toString().split('.').last ==
              hiveItem.type.toString().split('.').last,
        ),

        position: hiveItem.position,

        scale: hiveItem.scale,

        rotation: hiveItem.rotation,

        opacity: hiveItem.opacity,

        layerIndex: hiveItem.layerIndex,

        isVisible: hiveItem.isVisible,

        isLocked: hiveItem.isLocked,

        properties: properties,

        createdAt: hiveItem.createdAt,

        lastModified: hiveItem.lastModified,

        groupId: hiveItem.groupId,
      );

      items.add(item);
    }

    return items;
  }

  TextDecoration _intToTextDecoration(int value) {
    switch (value) {
      case 1:
        return TextDecoration.underline;

      case 2:
        return TextDecoration.overline;

      case 3:
        return TextDecoration.lineThrough;

      default:
        return TextDecoration.none;
    }
  }

  void _addAction(CanvasAction action) {
    if (currentActionIndex < actionHistory.length - 1) {
      actionHistory.removeRange(currentActionIndex + 1, actionHistory.length);
    }

    actionHistory.add(action);

    currentActionIndex++;

    if (actionHistory.length > 50) {
      actionHistory.removeAt(0);

      currentActionIndex--;
    }

    // Apply the action immediately if it's a modify operation

    if (action.type == 'modify' && action.item != null) {
      final idx = canvasItems.indexWhere((it) => it.id == action.item!.id);

      if (idx != -1) {
        canvasItems[idx] = action.item!;
      }
    }
  }

  void _undo() {
    if (currentActionIndex < 0) return;

    final action = actionHistory[currentActionIndex];

    setState(() {
      switch (action.type) {
        case 'add':
          canvasItems.removeWhere((it) => it.id == action.item!.id);

          break;

        case 'remove':
          canvasItems.add(action.item!);

          break;

        case 'modify':
          final idx = canvasItems.indexWhere((it) => it.id == action.item!.id);

          if (idx != -1 && action.previousState != null) {
            canvasItems[idx] = action.previousState!;
          }

          break;
      }

      // Ensure selection stays consistent with current canvas items

      if (selectedItem != null) {
        final matchIdx = canvasItems.indexWhere(
          (it) => it.id == selectedItem!.id,
        );

        selectedItem = matchIdx != -1 ? canvasItems[matchIdx] : null;
      }
    });

    currentActionIndex--;
  }

  void _redo() {
    if (currentActionIndex >= actionHistory.length - 1) return;

    currentActionIndex++;

    final action = actionHistory[currentActionIndex];

    setState(() {
      switch (action.type) {
        case 'add':
          canvasItems.add(action.item!);

          break;

        case 'remove':
          canvasItems.removeWhere((it) => it.id == action.item!.id);

          break;

        case 'modify':
          final idx = canvasItems.indexWhere((it) => it.id == action.item!.id);

          if (idx != -1) {
            canvasItems[idx] = action.item!;
          }

          break;
      }

      // Ensure selection stays consistent with current canvas items

      if (selectedItem != null) {
        final matchIdx = canvasItems.indexWhere(
          (it) => it.id == selectedItem!.id,
        );

        selectedItem = matchIdx != -1 ? canvasItems[matchIdx] : null;
      }
    });
  }

  void _addCanvasItem(CanvasItemType type, {Map<String, dynamic>? properties}) {
    final newItem = CanvasItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),

      type: type,

      position: Offset(100.w, 100.h),

      properties: properties ?? _getDefaultProperties(type),

      layerIndex: canvasItems.length,

      lastModified: DateTime.now(),

      createdAt: DateTime.now(),
    );

    setState(() {
      canvasItems.add(newItem);

      _selectItem(newItem);
    });

    _addAction(
      CanvasAction(type: 'add', item: newItem, timestamp: DateTime.now()),
    );

    _itemAddController.forward().then((_) => _itemAddController.reset());
  }

  Map<String, dynamic> _getDefaultProperties(CanvasItemType type) {
    switch (type) {
      case CanvasItemType.text:
        return {
          'text': 'Sample Text',

          'fontSize': 24.0,

          'color': HiveColor.fromColor(Colors.black),

          'fontWeight': FontWeight.normal.index,

          'fontStyle': FontStyle.normal.index,

          'textAlign': TextAlign.center.index,

          'hasGradient': false,

          'gradientColors': const [],

          'gradientAngle': 0.0,

          'decoration': 0, // TextDecoration.none

          'letterSpacing': 0.0,

          'hasShadow': false,

          'shadowColor': HiveColor.fromColor(Colors.black.withOpacity(0.6)),

          'shadowOffset': const Offset(4, 4),

          'shadowBlur': 4.0,

          'shadowOpacity': 0.6,
        };

      case CanvasItemType.image:
        return {
          'tint': HiveColor.fromColor(Colors.transparent),

          'blur': 0.0,

          'hasGradient': false,

          'gradientColors': const [],

          'gradientAngle': 0.0,

          'hasShadow': false,

          'shadowColor': HiveColor.fromColor(Colors.black.withOpacity(0.6)),

          'shadowOffset': const Offset(8, 8),

          'shadowBlur': 8.0,

          'shadowOpacity': 0.6,
        };

      case CanvasItemType.sticker:
        return {
          'iconCodePoint': Icons.star.codePoint,

          'color': HiveColor.fromColor(Colors.yellow),

          'size': 60.0,
        };

      case CanvasItemType.shape:
        return {
          'shape': 'rectangle',

          'fillColor': HiveColor.fromColor(Colors.green),

          'strokeColor': HiveColor.fromColor(Colors.black),

          'strokeWidth': 2.0,

          'hasGradient': false,

          'gradientColors': const [],

          'cornerRadius': 0.0,

          'width': 100.0,

          'height': 100.0,

          'topSide': 100.0,

          'rightSide': 100.0,

          'bottomSide': 100.0,

          'leftSide': 100.0,

          'topLeftRadius': 0.0,

          'topRightRadius': 0.0,

          'bottomLeftRadius': 0.0,

          'bottomRightRadius': 0.0,

          'topRadius': 0.0,

          'hasShadow': false,

          'shadowColor': HiveColor.fromColor(Colors.black.withOpacity(0.6)),

          'shadowOffset': const Offset(8, 8),

          'shadowBlur': 8.0,

          'shadowOpacity': 0.6,
        };

      case CanvasItemType.drawing:
        return {
          'drawingTool': DrawingTool.brush,

          'color': HiveColor.fromColor(Colors.black),

          'strokeWidth': 2.0,

          'opacity': 1.0,

          'isDotted': false,
        };
    }
  }

  void _selectItem(CanvasItem item) {
    setState(() {
      selectedItem = item;

      showBottomSheet = false;
    });

    // Removed: _selectionController.forward();
  }

  void _deselectItem() {
    setState(() {
      selectedItem = null;

      showBottomSheet = false;
    });

    _bottomSheetController.reverse();

    // Removed: _selectionController.reverse();
  }

  void _removeItem(CanvasItem item) {
    setState(() {
      canvasItems.remove(item);

      if (selectedItem == item) {
        _deselectItem();
      }
    });

    _addAction(
      CanvasAction(type: 'remove', item: item, timestamp: DateTime.now()),
    );
  }

  void _duplicateItem(CanvasItem item) {
    final duplicatedItem = item.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),

      position: item.position + const Offset(20, 20),

      layerIndex: canvasItems.length,
    );

    setState(() {
      canvasItems.add(duplicatedItem);

      _selectItem(duplicatedItem);
    });

    _addAction(
      CanvasAction(
        type: 'add',

        item: duplicatedItem,

        timestamp: DateTime.now(),
      ),
    );
  }

  void _bringToFront(CanvasItem item) {
    setState(() {
      // Remove the item from the list

      canvasItems.remove(item);

      // Find the current highest layer index

      int maxLayerIndex = canvasItems.isEmpty
          ? -1
          : canvasItems
                .map((it) => it.layerIndex)
                .reduce((a, b) => a > b ? a : b);

      // Set the item to be on top (highest layer index + 1)

      item.layerIndex = maxLayerIndex + 1;

      // Add the item back to the list

      canvasItems.add(item);

      // Ensure selectedItem reference is maintained after reordering

      if (selectedItem == item) {
        selectedItem = item;
      }
    });
  }

  void _sendToBack(CanvasItem item) {
    setState(() {
      // Remove the item from the list

      canvasItems.remove(item);

      // Find the current lowest layer index

      int minLayerIndex = canvasItems.isEmpty
          ? 1
          : canvasItems
                .map((it) => it.layerIndex)
                .reduce((a, b) => a < b ? a : b);

      // Set the item to be at the bottom (lowest layer index - 1)

      item.layerIndex = minLayerIndex - 1;

      // Add the item back to the list

      canvasItems.add(item);

      // Ensure selectedItem reference is maintained after reordering

      if (selectedItem == item) {
        selectedItem = item;
      }
    });
  }

  Widget _buildTopToolbar() {
    if (selectedItem != null) {
      return _buildTopEditToolbar();
    }

    // Hide the main tool tabs when a drawing tool is selected or drawing is active
    if (selectedTabIndex == 3 &&
        (!showDrawingToolSelection || drawingMode == DrawingMode.enabled)) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 80.h,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildToolButton(
            context,
            Icons.text_fields_rounded,
            'Text',
            selectedTabIndex == 0,
            () => setState(() => selectedTabIndex = 0),
            Colors.purple[600]!,
          ),
          SizedBox(width: 8.w),
          _buildToolButton(
            context,
            Icons.image_rounded,
            'Images',
            selectedTabIndex == 1,
            () => setState(() => selectedTabIndex = 1),
            Colors.blue[600]!,
          ),
          SizedBox(width: 8.w),
          _buildToolButton(
            context,
            Icons.category_rounded,
            'Shapes',
            selectedTabIndex == 2,
            () => setState(() => selectedTabIndex = 2),
            Colors.orange[600]!,
          ),
          SizedBox(width: 8.w),
          _buildToolButton(
            context,
            Icons.brush_rounded,
            'Drawing',
            selectedTabIndex == 3,
            () => setState(() => selectedTabIndex = 3),
            Colors.pink[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(
    BuildContext context,
    IconData icon,
    String label,
    bool isSelected,
    VoidCallback onTap,
    Color iconColor,
  ) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 60.w,
          height: 60.h,
          decoration: BoxDecoration(
            color: isSelected ? Colors.transparent : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
            border: isSelected ? Border.all(color: iconColor, width: 2) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 24.sp),
              SizedBox(height: 4.h),
              Text(
                label,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _currentAccent() {
    final CanvasItemType? itemType = selectedItem?.type;
    switch (itemType) {
      case CanvasItemType.text:
        return Colors.purple[600]!;
      case CanvasItemType.image:
        return Colors.blue[600]!;
      case CanvasItemType.shape:
        return Colors.orange[600]!;
      case CanvasItemType.drawing:
        return Colors.pink[600]!;
      case CanvasItemType.sticker:
        return Colors.green[600]!;
      default:
        return Colors.blueGrey;
    }
  }

  Color _segmentColor(String label) {
    switch (label.toLowerCase()) {
      case 'general':
        return const Color(0xFF2980B9); // blue
      case 'type':
        return const Color(0xFF27AE60); // green
      case 'shadow':
        return const Color(0xFF8E44AD); // purple
      case 'gradient':
        return const Color(0xFFE67E22); // orange
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildTopEditToolbar() {
    // Compact editing UI shown at the top when an item is selected

    return Container(
      height: 185.h,

      decoration: BoxDecoration(
        color: Colors.white,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),

            blurRadius: 20,

            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),

            child: Row(
              children: [
                // Container(
                //   padding: EdgeInsets.all(10.w),

                //   decoration: BoxDecoration(
                //     gradient: LinearGradient(
                //       colors: [Colors.blue.shade400, Colors.blue.shade600],
                //     ),

                //     borderRadius: BorderRadius.circular(14.r),
                //   ),

                //   child: Icon(
                //     _getItemTypeIcon(selectedItem!.type),

                //     color: Colors.white,

                //     size: 20.sp,
                //   ),
                // ),

                // SizedBox(width: 12.w),

                // Text('${selectedItem!.type.name.toUpperCase()} ', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[800])),
                const Spacer(),

                _buildEditModeSegmentedControl(),

                const Spacer(),

                GestureDetector(
                  onTap: _deselectItem,

                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,

                      vertical: 8.h,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.transparent,

                      borderRadius: BorderRadius.circular(12.r),

                      // no border
                    ),

                    child: Row(
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 16.sp,
                          color: _currentAccent(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: selectedItem == null
                ? const SizedBox()
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),

                    child: ListView(
                      scrollDirection: Axis.horizontal,

                      children: _buildTopbarQuickControls(),
                    ),
                  ),
          ),

          SizedBox(height: 10.h),
        ],
      ),
    );
  }

  // Replace the _buildEditModeSegmentedControl method with this updated version:

  Widget _buildEditModeSegmentedControl() {
    final List<String> tabs = ['General', 'Type'];

    // Add Shadow and Gradient tabs based on item type

    if (selectedItem != null) {
      switch (selectedItem!.type) {
        case CanvasItemType.text:
        case CanvasItemType.shape:
          tabs.addAll(['Shadow', 'Gradient']);
          break;

        case CanvasItemType.image:
          tabs.add('Shadow'); // Images only get shadow, no gradient
          break;

        case CanvasItemType.sticker:

          // Stickers don't typically have shadow/gradient options

          break;

        case CanvasItemType.drawing:

          // Drawings don't typically have shadow/gradient options

          break;
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,

      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final int index = entry.key;

          final String label = entry.value;

          return _buildSegmentButton(label, index);
        }).toList(),
      ),
    );
  }

  Widget _buildSegmentButton(String label, int index) {
    final bool isActive = editTopbarTabIndex == index;

    final Color accent = _currentAccent();
    final Color segmentBorder = _segmentColor(label);
    final Color textColor = isActive ? accent : Colors.grey.shade700;
    return GestureDetector(
      onTap: () => setState(() => editTopbarTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 185),
        margin: EdgeInsets.symmetric(horizontal: 4.w),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: textColor, width: isActive ? 2 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: textColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTopbarQuickControls() {
    if (selectedItem == null) return [];

    switch (editTopbarTabIndex) {
      case 0: // General controls

        return [
          _miniNudgePad(),

          _miniSlider(
            'Opacity',

            selectedItem!.opacity,

            0.1,

            1.0,

            (v) => setState(() => selectedItem!.opacity = v),

            Icons.opacity_rounded,
          ),

          _miniSlider(
            'Scale',

            selectedItem!.scale,

            0.3,

            10.0,

            (v) => setState(() => selectedItem!.scale = v),

            Icons.zoom_out_map_rounded,
          ),

          _miniSlider(
            'Rotate',

            selectedItem!.rotation * 185 / 3.14159,

            -185,

            185,

            (v) => setState(() => selectedItem!.rotation = v * 3.14159 / 185),

            Icons.rotate_right_rounded,
          ),

          _miniIconButton(
            'Duplicate',

            Icons.copy_rounded,

            () => _duplicateItem(selectedItem!),
          ),

          _miniIconButton(
            'Delete',

            Icons.delete_rounded,

            () => _removeItem(selectedItem!),
          ),

          _miniIconButton(
            'Front',

            Icons.vertical_align_top_rounded,

            () => _bringToFront(selectedItem!),
          ),

          _miniIconButton(
            'Back',

            Icons.vertical_align_bottom_rounded,

            () => _sendToBack(selectedItem!),
          ),
        ];

      case 1: // Type specific controls

        return _buildTypeSpecificQuickControls();

      case 2: // Shadow controls

        return _buildShadowQuickControls();

      case 3: // Gradient controls

        return _buildGradientQuickControls();

      default:
        return [];
    }
  }

  List<Widget> _buildShadowQuickControls() {
    if (selectedItem == null) return [];

    final props = selectedItem!.properties;

    final bool hasShadow = props['hasShadow'] == true;

    return [
      _miniToggleIcon(
        'Enable Shadow',

        CupertinoIcons.moon_stars,

        hasShadow,

        () => setState(() {
          final bool newVal = !hasShadow;
          props['hasShadow'] = newVal;
          if (newVal) {
            props['hasGradient'] = false;
          }
        }),
      ),

      if (hasShadow) ...[
        _miniColorSwatch(
          'Color',

          (props['shadowColor'] is HiveColor)
              ? (props['shadowColor'] as HiveColor).toColor()
              : (props['shadowColor'] is Color)
              ? (props['shadowColor'] as Color)
              : Colors.black54,

          () => _showColorPicker('shadowColor'),
        ),

        _miniSlider(
          'Blur',

          (props['shadowBlur'] as double?) ?? 4.0,

          0.0,

          40.0,

          (v) => setState(() => props['shadowBlur'] = v),

          Icons.blur_on_rounded,
        ),

        _miniSlider(
          'Opacity',

          (props['shadowOpacity'] as double?) ?? 0.6,

          0.0,

          1.0,

          (v) => setState(() => props['shadowOpacity'] = v),

          Icons.opacity_rounded,
        ),

        _miniSlider(
          'Offset X',

          (props['shadowOffset'] as Offset?)?.dx ?? 4.0,

          -100.0,

          100.0,

          (v) => setState(() {
            final cur =
                (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);

            props['shadowOffset'] = Offset(v, cur.dy);
          }),

          Icons.swap_horiz_rounded,
        ),

        _miniSlider(
          'Offset Y',

          (props['shadowOffset'] as Offset?)?.dy ?? 4.0,

          -100.0,

          100.0,

          (v) => setState(() {
            final cur =
                (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);

            props['shadowOffset'] = Offset(cur.dx, v);
          }),

          Icons.swap_vert_rounded,
        ),

        _miniSlider(
          'Size',

          (props['shadowSize'] as double?) ?? 0.0,

          0.0,

          100.0,

          (v) => setState(() => props['shadowSize'] = v),

          Icons.zoom_out_map_rounded,
        ),
      ],
    ];
  }

  List<Widget> _buildGradientQuickControls() {
    if (selectedItem == null) return [];

    final props = selectedItem!.properties;

    final bool hasGradient = props['hasGradient'] == true;

    return [
      _miniToggleIcon(
        'Enable Gradient',

        Icons.gradient_rounded,

        hasGradient,

        () => setState(() {
          final bool newVal = !hasGradient;
          props['hasGradient'] = newVal;
          if (newVal) {
            props['hasShadow'] = false;
          }

          // Initialize gradient colors if not present
          if (hasGradient &&
              (props['gradientColors'] == null ||
                  (props['gradientColors'] as List).isEmpty)) {
            props['gradientColors'] = [
              HiveColor.fromColor(Colors.blue),

              HiveColor.fromColor(Colors.purple),
            ];
          }
        }),
      ),

      if (hasGradient) ...[
        _miniColorSwatch(
          'Color A',

          _getDisplayGradientColors().first,

          () => _showColorPicker('gradientColor1', isGradient: true),
        ),

        _miniColorSwatch(
          'Color B',

          _getDisplayGradientColors().last,

          () => _showColorPicker('gradientColor2', isGradient: true),
        ),

        _miniSlider(
          'Angle',

          (props['gradientAngle'] as double?) ?? 0.0,

          -185.0,

          185.0,

          (v) => setState(() => props['gradientAngle'] = v),

          Icons.rotate_right_rounded,
        ),
      ],
    ];
  }

  List<Widget> _buildTypeSpecificQuickControls() {
    if (selectedItem == null) return [];

    switch (selectedItem!.type) {
      case CanvasItemType.text:
        return [
          _miniTextEditButton(
            'Text',

            (selectedItem!.properties['text'] as String?) ?? '',

            (v) => setState(() => selectedItem!.properties['text'] = v),
          ),

          _miniFontButton(
            'Font',

            selectedItem!.properties['fontFamily'] as String? ?? 'Roboto',

            () => _showFontSelectionDialog(),
          ),

          _miniColorSwatch(
            'Color',

            (selectedItem!.properties['color'] is HiveColor)
                ? (selectedItem!.properties['color'] as HiveColor).toColor()
                : Colors.black,

            () => _showColorPicker('color'),
          ),

          _miniSlider(
            'Font Size',

            (selectedItem!.properties['fontSize'] as double?) ?? 24.0,

            10.0,

            72.0,

            (v) => setState(() => selectedItem!.properties['fontSize'] = v),

            Icons.format_size_rounded,
          ),

          _miniToggleIcon(
            'Bold',

            Icons.format_bold_rounded,

            selectedItem!.properties['fontWeight'] == FontWeight.bold,

            () => setState(() {
              selectedItem!.properties['fontWeight'] =
                  (selectedItem!.properties['fontWeight'] == FontWeight.bold)
                  ? FontWeight.normal
                  : FontWeight.bold;
            }),
          ),

          _miniToggleIcon(
            'Italic',

            Icons.format_italic_rounded,

            selectedItem!.properties['fontStyle'] == FontStyle.italic,

            () => setState(() {
              selectedItem!.properties['fontStyle'] =
                  (selectedItem!.properties['fontStyle'] == FontStyle.italic)
                  ? FontStyle.normal
                  : FontStyle.italic;
            }),
          ),
        ];

      case CanvasItemType.image:
        return [
          _miniIconButton('Edit Image', Icons.edit_rounded, _editSelectedImage),

          _miniIconButton(
            'Remove BG',

            Icons.auto_fix_high_rounded,

            _removeBackground,
          ),

          _miniIconButton(
            'Add Stroke',

            Icons.border_outer_rounded,

            _showStrokeSettingsDialog,
          ),

          _miniIconButton(
            'Replace',

            Icons.photo_library_rounded,

            () => _pickImage(replace: true),
          ),

          // _miniColorSwatch('Tint', selectedItem!.properties['tint'] as Color? ?? Colors.transparent,

          //   () => _showColorPicker('tint')),
          _miniSlider(
            'Blur',

            (selectedItem!.properties['blur'] as double?) ?? 0.0,

            0.0,

            10.0,

            (v) => setState(() => selectedItem!.properties['blur'] = v),

            Icons.blur_on_rounded,
          ),
        ];

      case CanvasItemType.shape:
        final String shape =
            (selectedItem!.properties['shape'] as String?) ?? 'rectangle';

        final bool isQuadrilateral = shape == 'rectangle' || shape == 'square';

        return [
          _miniColorSwatch(
            'Fill',

            (selectedItem!.properties['fillColor'] is HiveColor)
                ? (selectedItem!.properties['fillColor'] as HiveColor).toColor()
                : Colors.green,

            () => _showColorPicker('fillColor'),
          ),

          _miniColorSwatch(
            'Stroke',

            (selectedItem!.properties['strokeColor'] is HiveColor)
                ? (selectedItem!.properties['strokeColor'] as HiveColor)
                      .toColor()
                : Colors.black,

            () => _showColorPicker('strokeColor'),
          ),

          _miniSlider(
            'Stroke Width',

            (selectedItem!.properties['strokeWidth'] as double?) ?? 0.0,

            0.0,

            10.0,

            (v) => setState(() => selectedItem!.properties['strokeWidth'] = v),

            Icons.line_weight_rounded,
          ),

          _miniSlider(
            'Corner Radius',

            (selectedItem!.properties['cornerRadius'] as double?) ?? 12.0,

            0.0,

            50.0,

            (v) => setState(() {
              selectedItem!.properties['cornerRadius'] = v;

              // Clear individual corner radius values when using uniform radius

              selectedItem!.properties.remove('topRadius');

              selectedItem!.properties.remove('bottomRightRadius');

              selectedItem!.properties.remove('bottomLeftRadius');

              selectedItem!.properties.remove('topLeftRadius');

              selectedItem!.properties.remove('topRightRadius');
            }),

            Icons.rounded_corner_rounded,
          ),

          // Add individual side controls for quadrilaterals
          if (isQuadrilateral) ...[
            _miniSlider(
              'Top Side',

              (selectedItem!.properties['topSide'] as double?) ?? 100.0,

              20.0,

              500.0,

              (v) => setState(() => selectedItem!.properties['topSide'] = v),

              Icons.keyboard_arrow_up_rounded,
            ),

            _miniSlider(
              'Right Side',

              (selectedItem!.properties['rightSide'] as double?) ?? 100.0,

              20.0,

              500.0,

              (v) => setState(() => selectedItem!.properties['rightSide'] = v),

              Icons.keyboard_arrow_right_rounded,
            ),

            _miniSlider(
              'Bottom Side',

              (selectedItem!.properties['bottomSide'] as double?) ?? 100.0,

              20.0,

              500.0,

              (v) => setState(() => selectedItem!.properties['bottomSide'] = v),

              Icons.keyboard_arrow_down_rounded,
            ),

            _miniSlider(
              'Left Side',

              (selectedItem!.properties['leftSide'] as double?) ?? 100.0,

              20.0,

              500.0,

              (v) => setState(() => selectedItem!.properties['leftSide'] = v),

              Icons.keyboard_arrow_left_rounded,
            ),
          ],

          _miniIconButton(
            'Image Fill',

            Icons.photo_library_rounded,

            () => _pickShapeImage(),
          ),

          if (selectedItem!.properties['image'] != null)
            _miniIconButton(
              'Clear Image',

              Icons.delete_sweep_rounded,

              () => setState(() => selectedItem!.properties['image'] = null),
            ),
        ];

      case CanvasItemType.sticker:
        return [
          _miniColorSwatch(
            'Color',

            (selectedItem!.properties['color'] as HiveColor?)?.toColor() ??
                Colors.orange,

            () => _showColorPicker('color'),
          ),
        ];
      case CanvasItemType.drawing:

        // Determine if this drawing has any text-path strokes

        final List<Map<String, dynamic>>? strokes =
            (selectedItem!.properties['strokes'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList();

        final bool hasTextPath =
            strokes?.any(
              (s) => (s['tool'] is String
                  ? s['tool'] == DrawingTool.textPath.name
                  : s['tool'] == DrawingTool.textPath),
            ) ==
            true;

        // Helper getters for initial values from first text-path stroke

        double _initialFontSize() {
          if (strokes == null) return 24.0;

          final first = strokes.firstWhere(
            (s) => (s['tool'] is String
                ? s['tool'] == DrawingTool.textPath.name
                : s['tool'] == DrawingTool.textPath),

            orElse: () => {},
          );

          if (first.isEmpty) return 24.0;

          final double sw = (first['strokeWidth'] as double?) ?? 2.0;

          return (first['fontSize'] as double?) ?? sw;
        }

        double _initialLetterSpacing() {
          if (strokes == null) return 0.0;

          final first = strokes.firstWhere(
            (s) => (s['tool'] is String
                ? s['tool'] == DrawingTool.textPath.name
                : s['tool'] == DrawingTool.textPath),

            orElse: () => {},
          );

          if (first.isEmpty) return 0.0;

          return (first['letterSpacing'] as double?) ?? 0.0;
        }

        String _initialText() {
          if (strokes == null) return '';

          final first = strokes.firstWhere(
            (s) => (s['tool'] is String
                ? s['tool'] == DrawingTool.textPath.name
                : s['tool'] == DrawingTool.textPath),

            orElse: () => {},
          );

          if (first.isEmpty) return '';

          return (first['text'] as String?) ?? '';
        }

        String _initialFontFamily() {
          if (strokes == null) return 'Roboto';

          final first = strokes.firstWhere(
            (s) => s['tool'] == DrawingTool.textPath,

            orElse: () => {},
          );

          if (first.isEmpty) return 'Roboto';

          return (first['fontFamily'] as String?) ?? 'Roboto';
        }

        return [
          _miniColorSwatch(
            'Color',

            (selectedItem!.properties['color'] as HiveColor?)?.toColor() ??
                Colors.black,

            () => _showDrawingColorPicker(),
          ),

          if (!hasTextPath)
            _miniSlider(
              'Stroke Width',

              (selectedItem!.properties['strokeWidth'] as double?) ?? 0.0,

              0.0,

              20.0,

              (v) => setState(() {
                selectedItem!.properties['strokeWidth'] = v;

                final List<Map<String, dynamic>>? _strokes =
                    (selectedItem!.properties['strokes'] as List<dynamic>?)
                        ?.map((e) => e as Map<String, dynamic>)
                        .toList();

                if (_strokes != null) {
                  for (final stroke in _strokes) {
                    stroke['strokeWidth'] = v;
                  }

                  selectedItem!.properties['strokes'] = _strokes;
                }
              }),

              Icons.format_size_rounded,
            ),

          if (hasTextPath) ...[
            _miniTextEditButton(
              'Text',

              _initialText(),

              (value) => setState(() {
                final List<Map<String, dynamic>>? _strokes =
                    (selectedItem!.properties['strokes'] as List<dynamic>?)
                        ?.map((e) => e as Map<String, dynamic>)
                        .toList();

                if (_strokes != null) {
                  for (final stroke in _strokes) {
                    if (stroke['tool'] == DrawingTool.textPath) {
                      stroke['text'] = value;
                    }
                  }

                  selectedItem!.properties['strokes'] = _strokes;
                }
              }),
            ),

            _miniSlider(
              'Font Size',

              _initialFontSize(),

              8.0,

              200.0,

              (v) => setState(() {
                final List<Map<String, dynamic>>? _strokes =
                    (selectedItem!.properties['strokes'] as List<dynamic>?)
                        ?.map((e) => e as Map<String, dynamic>)
                        .toList();

                if (_strokes != null) {
                  for (final stroke in _strokes) {
                    if (stroke['tool'] == DrawingTool.textPath) {
                      stroke['fontSize'] = v;
                    }
                  }

                  selectedItem!.properties['strokes'] = _strokes;
                }
              }),

              Icons.format_size_rounded,
            ),

            _miniSlider(
              'Letter Spacing',

              _initialLetterSpacing(),

              -2.0,

              20.0,

              (v) => setState(() {
                final List<Map<String, dynamic>>? _strokes =
                    (selectedItem!.properties['strokes'] as List<dynamic>?)
                        ?.map((e) => e as Map<String, dynamic>)
                        .toList();

                if (_strokes != null) {
                  for (final stroke in _strokes) {
                    if (stroke['tool'] == DrawingTool.textPath) {
                      stroke['letterSpacing'] = v;
                    }
                  }

                  selectedItem!.properties['strokes'] = _strokes;
                }
              }),

              Icons.space_bar_rounded,
            ),

            _miniFontButton(
              'Font',

              _initialFontFamily(),

              () => _showFontSelectionDialog(),
            ),
          ],
        ];
    }
  }

  double _measureTextWidth(String text, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
    )..layout();
    return painter.width;
  }

  Widget _miniIconButton(String tooltip, IconData icon, VoidCallback onTap) {
    final Color accent = _currentAccent();

    final TextStyle labelStyle = TextStyle(
      fontSize: 10.sp,
      fontWeight: FontWeight.w600,
      color: accent,
    );
    final double baseWidth = 60.w;
    final double textWidth = _measureTextWidth(tooltip, labelStyle);
    final double containerWidth = (textWidth + 12.w) > baseWidth
        ? (textWidth + 12.w)
        : baseWidth;

    return Padding(
      padding: EdgeInsets.only(right: 10.w, bottom: 35.h),

      child: Tooltip(
        message: tooltip,

        child: GestureDetector(
          onTap: onTap,

          child: Container(
            width: containerWidth,

            height: 60.h,

            decoration: BoxDecoration(
              color: Colors.transparent,

              borderRadius: BorderRadius.circular(12.r),

              // no border
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20.sp, color: accent),
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    tooltip,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniToggleIcon(
    String tooltip,

    IconData icon,

    bool isActive,

    VoidCallback onTap,
  ) {
    final Color accent = _currentAccent();
    final String dynLabel = isActive
        ? tooltip.replaceFirst(
            RegExp('^Enable', caseSensitive: false),
            'Disable',
          )
        : tooltip;

    final Color activeGrey = Colors.grey.shade600;
    final TextStyle labelStyle = TextStyle(
      fontSize: 10.sp,
      fontWeight: FontWeight.w700,
      color: isActive ? activeGrey : accent,
    );
    final double baseWidth = 60.w;
    final double textWidth = _measureTextWidth(dynLabel, labelStyle);
    final double containerWidth = (textWidth + 12.w) > baseWidth
        ? (textWidth + 12.w)
        : baseWidth;

    return Padding(
      padding: EdgeInsets.only(right: 10.w, bottom: 35.h),

      child: Tooltip(
        message: dynLabel,

        child: GestureDetector(
          onTap: onTap,

          child: Container(
            width: containerWidth,

            height: 60.h,

            decoration: BoxDecoration(
              color: Colors.transparent,

              borderRadius: BorderRadius.circular(12.r),

              // no border
            ),

            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20.sp, color: isActive ? activeGrey : accent),
                SizedBox(height: 4.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Text(
                    dynLabel,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    textAlign: TextAlign.center,
                    style: labelStyle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Nudge helpers

  void _cancelNudgeTimers() {
    _nudgeInitialDelayTimer?.cancel();

    _nudgeRepeatTimer?.cancel();

    _nudgeInitialDelayTimer = null;

    _nudgeRepeatTimer = null;
  }

  void _nudgeSelected(Offset delta) {
    if (selectedItem == null) return;

    setState(() {
      // Adjust nudge by current canvas zoom so visual movement feels consistent

      final double zoomAdjusted = canvasZoom == 0 ? 1.0 : canvasZoom;

      final Offset step = delta * (_nudgeStep / zoomAdjusted);

      Offset newPosition = selectedItem!.position + step;

      if (snapToGrid) {
        const double gridSize = 20.0;

        newPosition = Offset(
          (newPosition.dx / gridSize).round() * gridSize,

          (newPosition.dy / gridSize).round() * gridSize,
        );
      }

      selectedItem!.position = newPosition;
    });
  }

  void _startNudgeHold(Offset delta) {
    _cancelNudgeTimers();

    // Small delay before starting fast repeat, to allow single-tap nudges

    _nudgeInitialDelayTimer = Timer(_nudgeInitialDelay, () {
      _nudgeRepeatTimer = Timer.periodic(_nudgeRepeatInterval, (_) {
        _nudgeSelected(delta);
      });
    });
  }

  void _endNudgeHold() {
    _cancelNudgeTimers();
  }

  Widget _miniNudgePad() {
    return Padding(
      padding: EdgeInsets.only(right: 10.0.h),

      child: SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                SizedBox(width: 35.w),

                _nudgeButton(
                  Icons.keyboard_arrow_up_rounded,

                  const Offset(0, -1),
                ),

                SizedBox(width: 35.w),
              ],
            ),

            SizedBox(height: 6.h),

            Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                _nudgeButton(
                  Icons.keyboard_arrow_left_rounded,

                  const Offset(-1, 0),
                ),

                SizedBox(width: 9.w),

                _nudgeCenterIndicator(),

                SizedBox(width: 9.w),

                _nudgeButton(
                  Icons.keyboard_arrow_right_rounded,

                  const Offset(1, 0),
                ),
              ],
            ),

            SizedBox(height: 6.h),

            Row(
              mainAxisSize: MainAxisSize.min,

              children: [
                SizedBox(width: 30.w),

                _nudgeButton(
                  Icons.keyboard_arrow_down_rounded,

                  const Offset(0, 1),
                ),

                SizedBox(width: 30.w),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _nudgeCenterIndicator() {
    return Container(
      width: 32.w,

      height: 32.h,

      decoration: BoxDecoration(
        color: Colors.transparent,

        borderRadius: BorderRadius.circular(8.r),
      ),

      alignment: Alignment.center,

      child: Icon(
        Icons.open_with_rounded,

        size: 14.sp,

        color: _currentAccent(),
      ),
    );
  }

  Widget _nudgeButton(IconData icon, Offset deltaDir) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,

      onTap: () => _nudgeSelected(deltaDir),

      onTapDown: (_) => _startNudgeHold(deltaDir),

      onTapUp: (_) => _endNudgeHold(),

      onTapCancel: _endNudgeHold,

      child: Container(
        width: 32.w,

        height: 32.h,

        decoration: BoxDecoration(
          color: Colors.transparent,

          borderRadius: BorderRadius.circular(8.r),

          // no border
        ),

        child: Icon(icon, size: 18.sp, color: _currentAccent()),
      ),
    );
  }

  Widget _miniSlider(
    String label,

    double value,

    double min,

    double max,

    ValueChanged<double> onChanged,

    IconData icon,
  ) {
    final Color accent = _currentAccent();
    return EnhancedSlider(
      label: label,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
      icon: icon,
      isMini: true,
      step: 0.05, // 5% of the range
      accentColor: accent,
      borderOnly: true,
    );
  }

  Widget _miniSliderButton(
    String label,

    double value,

    double min,

    double max,

    ValueChanged<double> onChanged,

    IconData icon,
  ) {
    return _miniSlider(label, value, min, max, onChanged, icon);
  }

  Widget _miniColorSwatch(String label, Color color, VoidCallback onTap) {
    final bool isTransparent = color == Colors.transparent;
    final Color accent = _currentAccent();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 12.w, bottom: 35.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22.w,
              height: 22.h,
              decoration: BoxDecoration(
                color: isTransparent ? Colors.white : color,
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: isTransparent
                  ? Stack(
                      children: [
                        // Checkerboard pattern for transparent
                        CustomPaint(
                          painter: CheckerboardPainter(),
                          size: Size(22.w, 22.h),
                        ),
                        // Diagonal line to indicate transparent
                        Center(
                          child: Container(
                            width: 16.w,
                            height: 2.h,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(1.r),
                            ),
                            transform: Matrix4.rotationZ(
                              0.785398,
                            ), // 45 degrees
                          ),
                        ),
                      ],
                    )
                  : null,
            ),

            SizedBox(width: 8.w),

            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Replace the _miniTextField method with this button version:

  Widget _miniTextEditButton(
    String label,

    String value,

    ValueChanged<String> onChanged,
  ) {
    final Color accent = _currentAccent();

    return Container(
      width: 260.w,

      margin: EdgeInsets.only(right: 12.w),

      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),

      decoration: BoxDecoration(
        color: Colors.transparent,

        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(Icons.text_fields_rounded, size: 16.sp, color: accent),

              SizedBox(width: 8.w),

              Text(
                label,

                style: TextStyle(
                  fontSize: 12.sp,

                  color: accent,

                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(height: 6.h),

          GestureDetector(
            onTap: () => _showTextEditDialog(value, onChanged),

            child: Container(
              width: double.infinity,

              // Reduce inner vertical padding to shrink bordered area height
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),

              decoration: BoxDecoration(
                color: Colors.transparent,

                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: Colors.grey.shade300),
              ),

              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value.isEmpty ? 'Tap to edit text' : value,

                      style: TextStyle(
                        fontSize: 12.sp,

                        color: value.isEmpty ? Colors.grey[400] : accent,
                      ),

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  SizedBox(width: 8.w),

                  Icon(Icons.edit_rounded, size: 14.sp, color: accent),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Add this method to show the text editing dialog:

  void _showTextEditDialog(String currentText, ValueChanged<String> onChanged) {
    final TextEditingController controller = TextEditingController(
      text: currentText,
    );

    final FocusNode focusNode = FocusNode();

    showDialog(
      context: context,

      barrierDismissible: false,

      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,

          insetPadding: EdgeInsets.all(20.w),

          child: Container(
            width: double.infinity,

            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,

              minHeight: 300.h,
            ),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(24.r),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),

                  blurRadius: 20,

                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Column(
              mainAxisSize: MainAxisSize.min,

              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20.w),

                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),

                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),

                      topRight: Radius.circular(24.r),
                    ),
                  ),

                  child: Row(
                    children: [
                      Icon(
                        Icons.text_fields_rounded,

                        color: Colors.white,

                        size: 24.sp,
                      ),

                      SizedBox(width: 12.w),

                      Text(
                        'Edit Text',

                        style: TextStyle(
                          fontSize: 20.sp,

                          fontWeight: FontWeight.bold,

                          color: Colors.white,
                        ),
                      ),

                      const Spacer(),

                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),

                        child: Container(
                          padding: EdgeInsets.all(8.w),

                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),

                            borderRadius: BorderRadius.circular(8.r),
                          ),

                          child: Icon(
                            Icons.close_rounded,

                            color: Colors.white,

                            size: 18.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Text editing area
                Flexible(
                  child: Container(
                    padding: EdgeInsets.all(20.w),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Text(
                          'Enter your text:',

                          style: TextStyle(
                            fontSize: 16.sp,

                            fontWeight: FontWeight.w600,

                            color: Colors.grey[800],
                          ),
                        ),

                        SizedBox(height: 12.h),

                        // Multi-line text field
                        Flexible(
                          child: Container(
                            width: double.infinity,

                            decoration: BoxDecoration(
                              color: Colors.grey[50],

                              borderRadius: BorderRadius.circular(16.r),

                              border: Border.all(color: Colors.grey.shade200),
                            ),

                            child: TextField(
                              controller: controller,

                              focusNode: focusNode,

                              maxLines: null,

                              minLines: 5,

                              keyboardType: TextInputType.multiline,

                              textInputAction: TextInputAction.newline,

                              style: TextStyle(
                                fontSize: 16.sp,

                                color: Colors.grey[800],

                                height: 1.5,
                              ),

                              decoration: InputDecoration(
                                hintText:
                                    'Type your text here...\nPress Enter for new lines',

                                hintStyle: TextStyle(
                                  color: Colors.grey[400],

                                  fontSize: 14.sp,
                                ),

                                contentPadding: EdgeInsets.all(16.w),

                                border: InputBorder.none,
                              ),

                              onChanged: (text) {
                                // Real-time update on canvas

                                onChanged(text);
                              },
                            ),
                          ),
                        ),

                        SizedBox(height: 16.h),

                        // Character count
                        Text(
                          '${controller.text.length} characters',

                          style: TextStyle(
                            fontSize: 12.sp,

                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Action buttons
                Container(
                  padding: EdgeInsets.all(20.w),

                  decoration: BoxDecoration(
                    color: Colors.grey[50],

                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24.r),

                      bottomRight: Radius.circular(24.r),
                    ),
                  ),

                  child: Row(
                    children: [
                      // Clear button
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            controller.clear();

                            onChanged('');
                          },

                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),

                            decoration: BoxDecoration(
                              color: Colors.red.shade50,

                              borderRadius: BorderRadius.circular(12.r),

                              border: Border.all(color: Colors.red.shade200),
                            ),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Icon(
                                  Icons.clear_rounded,

                                  color: Colors.red.shade600,

                                  size: 18.sp,
                                ),

                                SizedBox(width: 8.w),

                                Text(
                                  'Clear',

                                  style: TextStyle(
                                    fontSize: 14.sp,

                                    fontWeight: FontWeight.w600,

                                    color: Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 12.w),

                      // Done button
                      Expanded(
                        flex: 2,

                        child: GestureDetector(
                          onTap: () {
                            onChanged(controller.text);

                            Navigator.of(context).pop();
                          },

                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 14.h),

                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade400,

                                  Colors.blue.shade600,
                                ],
                              ),

                              borderRadius: BorderRadius.circular(12.r),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),

                                  blurRadius: 8,

                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Icon(
                                  Icons.check_rounded,

                                  color: Colors.white,

                                  size: 18.sp,
                                ),

                                SizedBox(width: 8.w),

                                Text(
                                  'Done',

                                  style: TextStyle(
                                    fontSize: 14.sp,

                                    fontWeight: FontWeight.w600,

                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Auto-focus the text field when dialog opens

      Future.delayed(const Duration(milliseconds: 100), () {
        if (focusNode.canRequestFocus) {
          focusNode.requestFocus();
        }
      });
    });
  }

  void _showFontSelectionDialog() {
    showDialog(
      context: context,

      barrierDismissible: true,

      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,

          insetPadding: EdgeInsets.all(20.w),

          child: Container(
            width: double.infinity,

            height: MediaQuery.of(context).size.height * 0.8,

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(24.r),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),

                  blurRadius: 20,

                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(20.w),

                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade600],
                    ),

                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.r),

                      topRight: Radius.circular(24.r),
                    ),
                  ),

                  child: Row(
                    children: [
                      Icon(
                        Icons.font_download_rounded,

                        color: Colors.white,

                        size: 24.sp,
                      ),

                      SizedBox(width: 12.w),

                      Text(
                        'Select Font',

                        style: TextStyle(
                          fontSize: 18.sp,

                          fontWeight: FontWeight.bold,

                          color: Colors.white,
                        ),
                      ),

                      const Spacer(),

                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),

                        child: Container(
                          padding: EdgeInsets.all(8.w),

                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),

                            borderRadius: BorderRadius.circular(8.r),
                          ),

                          child: Icon(
                            Icons.close_rounded,

                            color: Colors.white,

                            size: 20.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Column(
                    children: [
                      // Favorite Fonts Section
                      Container(
                        padding: EdgeInsets.all(20.w),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.favorite_rounded,

                                  color: Colors.red.shade400,

                                  size: 20.sp,
                                ),

                                SizedBox(width: 8.w),

                                Text(
                                  'Favorite Fonts',

                                  style: TextStyle(
                                    fontSize: 16.sp,

                                    fontWeight: FontWeight.bold,

                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 16.h),

                            Container(
                              height: 200.h,

                              child:
                                  FontFavorites.instance.likedFamilies.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,

                                        children: [
                                          Icon(
                                            Icons.font_download_outlined,

                                            size: 48.sp,

                                            color: Colors.grey[400],
                                          ),

                                          SizedBox(height: 12.h),

                                          Text(
                                            'No favorite fonts yet',

                                            style: TextStyle(
                                              fontSize: 14.sp,

                                              color: Colors.grey[600],
                                            ),
                                          ),

                                          SizedBox(height: 8.h),

                                          Text(
                                            'Browse fonts to add favorites',

                                            style: TextStyle(
                                              fontSize: 12.sp,

                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: FontFavorites
                                          .instance
                                          .likedFamilies
                                          .length,

                                      itemBuilder: (context, index) {
                                        final fontFamily = FontFavorites
                                            .instance
                                            .likedFamilies[index];

                                        return _buildFontListItem(
                                          fontFamily,

                                          true,
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),

                      // Divider
                      Divider(color: Colors.grey[300], height: 1),

                      // Browse Fonts Button
                      Container(
                        padding: EdgeInsets.all(20.w),

                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();

                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder: (context) => GoogleFontsPage(
                                  onFontSelected: (fontFamily) {
                                    setState(() {
                                      if (selectedItem == null) return;

                                      if (selectedItem!.type ==
                                          CanvasItemType.drawing) {
                                        final List<Map<String, dynamic>>?
                                        strokes =
                                            (selectedItem!.properties['strokes']
                                                    as List<dynamic>?)
                                                ?.map(
                                                  (e) =>
                                                      e as Map<String, dynamic>,
                                                )
                                                .toList();

                                        if (strokes != null) {
                                          for (final stroke in strokes) {
                                            if (stroke['tool'] ==
                                                DrawingTool.textPath) {
                                              stroke['fontFamily'] = fontFamily;
                                            }
                                          }

                                          selectedItem!.properties['strokes'] =
                                              strokes;
                                        }
                                      } else {
                                        selectedItem!.properties['fontFamily'] =
                                            fontFamily;
                                      }
                                    });
                                  },
                                ),
                              ),
                            );
                          },

                          child: Container(
                            width: double.infinity,

                            padding: EdgeInsets.symmetric(vertical: 16.h),

                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.green.shade400,

                                  Colors.green.shade600,
                                ],
                              ),

                              borderRadius: BorderRadius.circular(12.r),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),

                                  blurRadius: 8,

                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),

                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,

                              children: [
                                Icon(
                                  Icons.search_rounded,

                                  color: Colors.white,

                                  size: 20.sp,
                                ),

                                SizedBox(width: 8.w),

                                Text(
                                  'Browse All Fonts',

                                  style: TextStyle(
                                    fontSize: 16.sp,

                                    fontWeight: FontWeight.bold,

                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFontListItem(String fontFamily, bool isFavorite) {
    final isSelected = selectedItem?.properties['fontFamily'] == fontFamily;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selectedItem == null) return;

          if (selectedItem!.type == CanvasItemType.drawing) {
            final List<Map<String, dynamic>>? strokes =
                (selectedItem!.properties['strokes'] as List<dynamic>?)
                    ?.map((e) => e as Map<String, dynamic>)
                    .toList();

            if (strokes != null) {
              for (final stroke in strokes) {
                if (stroke['tool'] == DrawingTool.textPath) {
                  stroke['fontFamily'] = fontFamily;
                }
              }

              selectedItem!.properties['strokes'] = strokes;
            }
          } else {
            selectedItem!.properties['fontFamily'] = fontFamily;
          }
        });

        Navigator.of(context).pop();
      },

      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),

        padding: EdgeInsets.all(16.w),

        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey[50],

          borderRadius: BorderRadius.circular(12.r),

          border: Border.all(
            color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,

            width: isSelected ? 2 : 1,
          ),
        ),

        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    fontFamily,

                    style: TextStyle(
                      fontSize: 16.sp,

                      fontWeight: FontWeight.w600,

                      color: isSelected
                          ? Colors.blue.shade700
                          : Colors.grey[800],

                      fontFamily: fontFamily,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Text(
                    'The quick brown fox jumps',

                    style: TextStyle(
                      fontSize: 12.sp,

                      color: Colors.grey[600],

                      fontFamily: fontFamily,
                    ),
                  ),
                ],
              ),
            ),

            if (isSelected)
              Icon(
                Icons.check_circle_rounded,

                color: Colors.blue.shade600,

                size: 24.sp,
              ),

            if (isFavorite)
              Padding(
                padding: EdgeInsets.only(left: 8.w),

                child: Icon(
                  Icons.favorite_rounded,

                  color: Colors.red.shade400,

                  size: 20.sp,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniFontButton(String label, String fontFamily, VoidCallback onTap) {
    return Container(
      width: 190.w,
      margin: EdgeInsets.only(right: 12.w, bottom: 35.h),

      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),

      decoration: BoxDecoration(
        color: Colors.transparent,

        borderRadius: BorderRadius.circular(14.r),

        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(
            Icons.font_download_rounded,

            size: 16.sp,

            color: Colors.grey[600],
          ),

          SizedBox(width: 8.w),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                label,

                style: TextStyle(
                  fontSize: 10.sp,

                  color: Colors.grey[600],

                  fontWeight: FontWeight.w500,
                ),
              ),

              Text(
                fontFamily.length > 10
                    ? '${fontFamily.substring(0, 12)}...'
                    : fontFamily,

                style: TextStyle(
                  fontSize: 12.sp,

                  color: Colors.grey[800],

                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          SizedBox(width: 27.w),

          GestureDetector(
            onTap: onTap,

            child: Container(
              padding: EdgeInsets.all(6.w),

              decoration: BoxDecoration(
                color: Colors.blue.shade50,

                borderRadius: BorderRadius.circular(8.r),
              ),

              child: Icon(
                Icons.keyboard_arrow_down_rounded,

                size: 16.sp,

                color: Colors.blue.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    if (selectedTabIndex == 1) {
      // Custom layout for images tab with divider
      return SizedBox(
        height: 60.h,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Upload from Gallery button
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: GestureDetector(
                  onTap: () => _onTabItemTap(0),
                  child: Container(height: 60.h, child: _getTabItemWidget(0)),
                ),
              ),
            ),
            // Vertical divider
            Padding(
              padding: EdgeInsets.all(8.0.h),
              child: Container(
                width: 2.w,
                height: 40.h,
                color: Colors.grey[300],
              ),
            ),
            // Upload from Pixabay button
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: GestureDetector(
                  onTap: () => _onTabItemTap(1),
                  child: Container(height: 60.h, child: _getTabItemWidget(1)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Default ListView.builder for other tabs
    return SizedBox(
      height: 50.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _getTabItemCount(),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: GestureDetector(
              onTap: () => _onTabItemTap(index),
              child: Container(
                width: 50.w,
                height: 50.h,
                child: _getTabItemWidget(index),
              ),
            ),
          );
        },
      ),
    );
  }

  int _getTabItemCount() {
    switch (selectedTabIndex) {
      case 0:

        // 1 for the leading plus button + liked fonts as items

        return 1 + likedFontFamilies.length;

      case 1:
        return 2; // Two options: Upload and Pixabay

      case 2:
        return sampleShapes.length;

      case 3:
        return _getDrawingTools().length;

      default:
        return 0;
    }
  }

  bool _isValidFontFamily(String fontFamily) {
    // List of invalid font families that cause GoogleFonts errors
    final invalidFonts = ['Material Icons', 'MaterialIcons', 'Icons', 'Icon'];

    return !invalidFonts.contains(fontFamily) &&
        fontFamily.isNotEmpty &&
        !fontFamily.contains('Icon');
  }

  Widget _getTabItemWidget(int index) {
    switch (selectedTabIndex) {
      case 0:
        if (index == 0) {
          return Icon(
            Icons.add_rounded,
            size: 24.sp,
            color: Colors.purple[600],
          );
        }
        final family = likedFontFamilies[index - 1];
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon(
            //   Icons.text_fields_rounded,
            //   size:15.sp,
            //   color: Colors.purple[600],
            // ),
            // SizedBox(width: 4.w),
            Expanded(
              child: Text(
                family,
                style: _isValidFontFamily(family)
                    ? GoogleFonts.getFont(
                        family,
                        textStyle: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.purple[600],
                        ),
                      )
                    : TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.purple[600],
                      ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.fade,
              ),
            ),
          ],
        );

      case 1:
        if (index == 0) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_rounded,
                size: 25.sp,
                color: Colors.blue[600],
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Upload from Gallery',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        } else {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_search_rounded,
                size: 25.sp,
                color: Colors.blue[600],
              ),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'Upload from Pixabay',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        }

      case 2:
        final shapeData = sampleShapes[index];
        final icon = shapeData['icon'] as IconData;
        final shape = shapeData['shape'] as String;

        // Rotate diamond shape 90 degrees
        if (shape == 'diamond') {
          return Transform.rotate(
            angle: 0.7854,
            child: Icon(icon, size: 24.sp, color: Colors.orange[600]),
          );
        }

        return Icon(icon, size: 24.sp, color: Colors.orange[600]);

      case 3:
        final drawingTool = _getDrawingTools()[index];
        final isSelected = selectedDrawingTool == drawingTool['tool'];
        return Icon(
          drawingTool['icon'] as IconData,
          size: 24.sp,
          color: isSelected ? Colors.pink[600] : Colors.pink[400],
        );

      default:
        return const SizedBox();
    }
  }

  void _onTabItemTap(int index) {
    HapticFeedback.lightImpact();

    switch (selectedTabIndex) {
      case 0:
        if (index == 0) {
          Navigator.push(
            context,

            MaterialPageRoute(
              builder: (context) => GoogleFontsPage(
                onFontSelected: (fontFamily) {
                  _addCanvasItem(
                    CanvasItemType.text,

                    properties: {
                      'text': 'New Text',

                      'color': Colors.black,

                      'fontSize': 24.0,

                      'fontWeight': FontWeight.normal,

                      'fontStyle': FontStyle.normal,

                      'textAlign': TextAlign.center,

                      'decoration': 0, // TextDecoration.none

                      'letterSpacing': 0.0,

                      'hasShadow': false,

                      'shadowColor': Colors.grey,

                      'shadowOffset': const Offset(2, 2),

                      'shadowBlur': 4.0,

                      'fontFamily': fontFamily,
                    },
                  );
                },
              ),
            ),
          );
        } else {
          final family = likedFontFamilies[index - 1];

          _addCanvasItem(
            CanvasItemType.text,

            properties: {
              'text': 'New Text',

              'color': Colors.black,

              'fontSize': 24.0,

              'fontWeight': FontWeight.normal,

              'fontStyle': FontStyle.normal,

              'textAlign': TextAlign.center,

              'decoration': 0, // TextDecoration.none

              'letterSpacing': 0.0,

              'hasShadow': false,

              'shadowColor': Colors.grey,

              'shadowOffset': const Offset(2, 2),

              'shadowBlur': 4.0,

              'fontFamily': family,
            },
          );
        }

        break;

      case 1:
        if (index == 0) {
          _pickImage(); // Existing Upload functionality
        } else if (index == 1) {
          _navigateToPixabayImages(); // New Pixabay functionality
        }

        break;

      case 2:
        final shapeData = sampleShapes[index];

        _addCanvasItem(
          CanvasItemType.shape,

          properties: {
            'shape': shapeData['shape'],

            'fillColor': Colors.green,

            'strokeColor': Colors.black,

            'strokeWidth': 2.0,

            'hasGradient': false,

            'gradientColors': [
              HiveColor.fromColor(Colors.lightGreen),

              HiveColor.fromColor(Colors.green),
            ],

            'cornerRadius': 0.0,

            'width': 100.0,

            'height': 100.0,

            'topSide': 100.0,

            'rightSide': 100.0,

            'bottomSide': 100.0,

            'leftSide': 100.0,

            'topLeftRadius': 0.0,

            'topRightRadius': 0.0,

            'bottomLeftRadius': 0.0,

            'bottomRightRadius': 0.0,

            'topRadius': 0.0,
          },
        );

        break;

      case 3:

        // Reset drawing flow when entering drawing tab

        setState(() {
          showDrawingToolSelection = true;

          showDrawingControls = false;

          drawingMode = DrawingMode.disabled;
        });

        break;
    }
  }

  // Drawing gesture handlers

  void _onDrawingStart(DragStartDetails details) {
    print(
      'Drawing start - Mode: $drawingMode, Enabled: ${drawingMode == DrawingMode.enabled}',
    );

    if (drawingMode != DrawingMode.enabled) return;

    setState(() {
      isDrawing = true;

      currentDrawingPoints = [details.localPosition];

      _lastDrawingUpdate = DateTime.now();
    });

    if (selectedDrawingTool == DrawingTool.textPath &&
        ((_currentPathText == null) || _currentPathText!.trim().isEmpty)) {
      _promptForPathText();
    }

    print('Drawing started with ${currentDrawingPoints.length} points');
  }

  Future<void> _promptForPathText() async {
    String temp = _currentPathText ?? '';

    await showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: Text('Type text for path'),

          content: TextField(
            autofocus: true,

            controller: TextEditingController(text: temp),

            onChanged: (v) => temp = v,

            decoration: const InputDecoration(hintText: 'Enter text'),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();

                setState(() => _currentPathText = temp);
              },

              child: const Text('Use Text'),
            ),
          ],
        );
      },
    );
  }

  void _onDrawingUpdate(DragUpdateDetails details) {
    if (!isDrawing || drawingMode != DrawingMode.enabled) return;

    final now = DateTime.now();

    // Throttle updates to max 60 FPS (16ms intervals)

    if (_lastDrawingUpdate != null &&
        now.difference(_lastDrawingUpdate!).inMilliseconds < 16) {
      return;
    }

    // Only add point if it's far enough from the last point to avoid too many points

    if (currentDrawingPoints.isEmpty ||
        (details.localPosition - currentDrawingPoints.last).distance > 1.5) {
      setState(() {
        currentDrawingPoints.add(details.localPosition);

        _lastDrawingUpdate = now;
      });

      print('Drawing update - Points: ${currentDrawingPoints.length}');
    }
  }

  void _onDrawingEnd(DragEndDetails details) {
    if (!isDrawing || drawingMode != DrawingMode.enabled) return;

    // Commit the current stroke to layers so it persists

    setState(() {
      isDrawing = false;

      if (currentDrawingPoints.isNotEmpty) {
        drawingLayers.add(
          DrawingLayer(
            id: DateTime.now().millisecondsSinceEpoch.toString(),

            tool: selectedDrawingTool,

            points: List<Offset>.from(currentDrawingPoints),

            color: drawingColor,

            strokeWidth: drawingStrokeWidth,

            isDotted:
                selectedDrawingTool == DrawingTool.dottedLine ||
                selectedDrawingTool == DrawingTool.dottedArrow,

            opacity: drawingOpacity,

            createdAt: DateTime.now(),

            text: selectedDrawingTool == DrawingTool.textPath
                ? _currentPathText
                : null,

            fontSize: selectedDrawingTool == DrawingTool.textPath
                ? drawingStrokeWidth
                : null,

            fontFamily: selectedDrawingTool == DrawingTool.textPath
                ? _currentPathFontFamily
                : null,

            letterSpacing: selectedDrawingTool == DrawingTool.textPath
                ? _currentPathLetterSpacing
                : null,
          ),
        );

        currentDrawingPoints.clear();
      }
    });
  }

  Widget _buildDrawingControls() {
    if (showDrawingToolSelection) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_getDrawingTools().length, (index) {
          final drawingTool = _getDrawingTools()[index];
          final isSelected = selectedDrawingTool == drawingTool['tool'];
          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDrawingTool = drawingTool['tool'] as DrawingTool;
                showDrawingToolSelection = false;
                showDrawingControls = true;
              });
            },
            child: Container(
              width: 70.w,
              height: 70.h,
              child: Icon(
                drawingTool['icon'] as IconData,
                size: 28.sp,
                color: isSelected ? Colors.pink[600] : Colors.pink[400],
              ),
            ),
          );
        }),
      );
    } else if (showDrawingControls) {
      return _buildToolControls();
    } else {
      return _buildDrawingMode();
    }
  }

  Widget _buildToolSelection() {
    return Container(
      height: 60.h,

      child: ListView.builder(
        scrollDirection: Axis.horizontal,

        itemCount: _getDrawingTools().length,

        itemBuilder: (context, index) {
          final drawingTool = _getDrawingTools()[index];

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),

            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedDrawingTool = drawingTool['tool'] as DrawingTool;

                  showDrawingToolSelection = false;

                  showDrawingControls = true;
                });
              },

              child: Container(
                width: 70.w,

                padding: EdgeInsets.all(8.w),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: BorderRadius.circular(10.r),

                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    Icon(
                      drawingTool['icon'] as IconData,

                      size: 20.sp,

                      color: Colors.orange.shade600,
                    ),

                    SizedBox(height: 4.h),

                    Text(
                      drawingTool['name'] as String,

                      style: TextStyle(
                        fontSize: 8.sp,

                        fontWeight: FontWeight.w500,

                        color: Colors.grey.shade700,
                      ),

                      textAlign: TextAlign.center,

                      maxLines: 1,

                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolControls() {
    return SizedBox(
      height: 100.h,

      child: ListView(
        scrollDirection: Axis.horizontal,

        padding: EdgeInsets.only(
          left: 8.w,
          right: 8.w,
          bottom: 35.h,
          top: 10.h,
        ),

        children: [
          // Back to tools
          _chipButton(
            background: Colors.grey.shade200,
            borderColor: Colors.grey.shade300,
            icon: Icons.arrow_back,
            iconColor: Colors.grey.shade800,
            label: 'Back',
            onTap: () {
              setState(() {
                showDrawingToolSelection = true;

                showDrawingControls = false;
              });
            },
          ),

          // Start Drawing
          _chipButton(
            background: Colors.blue.shade600,
            borderColor: Colors.transparent,
            icon: Icons.brush,
            iconColor: Colors.white,
            label: 'Start',
            labelColor: Colors.white,
            onTap: () {
              setState(() {
                showDrawingControls = false;

                drawingMode = DrawingMode.enabled;
              });

              if (selectedDrawingTool == DrawingTool.textPath &&
                  ((_currentPathText == null) ||
                      _currentPathText!.trim().isEmpty)) {
                _promptForPathText();
              }
            },
          ),

          // Color picker
          _chipCustom(
            background: Colors.white,
            borderColor: Colors.grey.shade300,
            icon: Icons.color_lens,
            iconColor: drawingColor,
            label: 'Color',
            child: Container(
              width: 22.w,
              height: 22.w,
              decoration: BoxDecoration(
                color: drawingColor,
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: Colors.grey.shade300, width: 1),
              ),
            ),
            onTap: _showDrawingColorPicker,
          ),

          // Size slider condensed
          _chipSlider(
            icon: Icons.format_size,
            iconColor: Colors.deepPurple,
            label: selectedDrawingTool == DrawingTool.textPath
                ? 'Font ${drawingStrokeWidth.toInt()}'
                : 'Size ${drawingStrokeWidth.toInt()}',
            value: drawingStrokeWidth,
            min: 1.0,
            max: 20.0,
            divisions: 19,
            onChanged: (v) => setState(() => drawingStrokeWidth = v),
          ),

          // Font favorites (only for textPath)
          if (selectedDrawingTool == DrawingTool.textPath)
            _chipButton(
              background: Colors.pink.shade50,
              borderColor: Colors.pink.shade200,
              icon: Icons.favorite_rounded,
              iconColor: Colors.pink,
              label: _currentPathFontFamily ?? 'Fav fonts',
              onTap: _showTextPathFontFavorites,
            ),

          // Letter spacing (only for textPath)
          if (selectedDrawingTool == DrawingTool.textPath)
            _chipSlider(
              icon: Icons.space_bar,
              iconColor: Colors.teal,
              label: 'Spacing',
              value: _currentPathLetterSpacing ?? 0.0,
              min: -5.0,
              max: 20.0,
              divisions: 25,
              onChanged: (v) => setState(() => _currentPathLetterSpacing = v),
            ),

          // Opacity slider
          _chipSlider(
            icon: Icons.opacity,
            iconColor: Colors.indigo,
            label: 'Opacity ${(drawingOpacity * 100).toInt()}%',
            value: drawingOpacity,
            min: 0.1,
            max: 1.0,
            divisions: 9,
            onChanged: (v) => setState(() => drawingOpacity = v),
          ),
        ],
      ),
    );
  }

  void _showTextPathFontFavorites() {
    final liked = FontFavorites.instance.likedFamilies;

    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.white,

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
      ),

      builder: (context) {
        return SizedBox(
          height: 340.h,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Padding(
                padding: EdgeInsets.all(16.w),

                child: Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: Colors.pink),

                    SizedBox(width: 8.w),

                    Text(
                      'Choose favorite font',

                      style: TextStyle(
                        fontSize: 16.sp,

                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Colors.grey.shade200),

              Expanded(
                child: liked.isEmpty
                    ? Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.w),

                          child: Text(
                            'No favorite fonts yet. Browse fonts and tap heart to add.',

                            style: TextStyle(color: Colors.grey[600]),

                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: liked.length,

                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade100),

                        itemBuilder: (context, index) {
                          final family = liked[index];

                          final bool _isGoogleFont = GoogleFonts.asMap()
                              .containsKey(family);

                          return ListTile(
                            title: Text(
                              family,

                              style: _isGoogleFont
                                  ? GoogleFonts.getFont(family)
                                  : TextStyle(fontFamily: family),
                            ),

                            subtitle: Text(
                              'The quick brown fox jumps over the lazy dog',

                              style: _isGoogleFont
                                  ? GoogleFonts.getFont(family)
                                  : TextStyle(fontFamily: family),
                            ),

                            onTap: () async {
                              // Preload Google Font so Paragraph can render it immediately

                              String resolvedFamily = family;

                              if (_isGoogleFont) {
                                final ts = GoogleFonts.getFont(family);

                                try {
                                  await GoogleFonts.pendingFonts([ts]);
                                } catch (_) {
                                  // ignore loading errors; fallback to default
                                }

                                resolvedFamily = ts.fontFamily ?? family;
                              }

                              setState(() {
                                _currentPathFontFamily = resolvedFamily;
                              });

                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawingMode() {
    return SizedBox(
      height: 100.h,

      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.only(
          left: 8.w,
          right: 8.w,
          bottom: 35.h,
          top: 10.h,
        ),
        children: [
          _chipButton(
            background: Colors.grey.shade100,
            borderColor: Colors.grey.shade300,
            icon: Icons.settings,
            iconColor: Colors.grey.shade700,
            label: 'Settings',
            onTap: () {
              setState(() {
                showDrawingControls = true;

                drawingMode = DrawingMode.disabled;
              });
            },
          ),

          _chipToggle(
            active: selectedDrawingTool == DrawingTool.eraser,
            activeBackground: Colors.orange.shade700,
            inactiveBackground: Colors.grey.shade600,
            icon: Icons.auto_fix_off,
            label: 'Erase',
            onTap: () {
              setState(() {
                final isEraserActive =
                    selectedDrawingTool == DrawingTool.eraser;
                if (isEraserActive) {
                  selectedDrawingTool =
                      _previousNonEraserTool ?? DrawingTool.brush;
                } else {
                  if (selectedDrawingTool != DrawingTool.eraser) {
                    _previousNonEraserTool = selectedDrawingTool;
                  }
                  selectedDrawingTool = DrawingTool.eraser;
                  drawingMode = DrawingMode.enabled;
                }
              });
            },
          ),

          _chipButton(
            background: Colors.red.shade600,
            borderColor: Colors.transparent,
            icon: Icons.stop,
            iconColor: Colors.white,
            label: 'Stop & Save',
            labelColor: Colors.white,
            onTap: () {
              _saveCurrentDrawing();
              setState(() {
                drawingMode = DrawingMode.disabled;
                showDrawingToolSelection = true;
                showDrawingControls = false;
              });
            },
          ),

          // Quick status chips
          _chipStatus(
            label: 'Color',
            child: Container(
              width: 18.w,
              height: 18.w,
              decoration: BoxDecoration(
                color: drawingColor,
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: Colors.grey.shade300),
              ),
            ),
          ),
          _chipStatus(label: 'Size ${drawingStrokeWidth.toInt()}'),
          _chipStatus(label: 'Opacity ${(drawingOpacity * 100).toInt()}%'),
        ],
      ),
    );
  }

  Widget _buildSettingDisplay(String label, Widget value) {
    return Column(
      children: [
        Text(
          label,

          style: TextStyle(fontSize: 8.sp, color: Colors.grey.shade600),
        ),

        SizedBox(height: 2.h),

        value,
      ],
    );
  }

  // Reusable compact chip-style controls for horizontal toolbars
  Widget _chipButton({
    required Color background,
    required Color borderColor,
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? labelColor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: iconColor ?? Colors.white),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: labelColor ?? Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipCustom({
    required Color background,
    required Color borderColor,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Widget child,
    Color? iconColor,
    Color? labelColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: borderColor, width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: iconColor ?? Colors.black87),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: labelColor ?? Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(width: 10.w),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipSlider({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    int? divisions,
    Color? iconColor,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: iconColor ?? Colors.blueGrey),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(width: 10.w),
            _roundIcon(
              icon: Icons.remove,
              onTap: () {
                final double computedDivs = (divisions ?? 10).toDouble();
                final double step =
                    (max - min) / (computedDivs <= 0 ? 10 : computedDivs);
                final double next = (value - step).clamp(min, max);
                onChanged(next);
              },
            ),
            SizedBox(width: 8.w),
            SizedBox(
              width: 160.w,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.h,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 8,
                  ),
                ),
                child: Slider(
                  min: min,
                  max: max,
                  divisions: divisions,
                  value: value.clamp(min, max),
                  onChanged: onChanged,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            _roundIcon(
              icon: Icons.add,
              onTap: () {
                final double computedDivs = (divisions ?? 10).toDouble();
                final double step =
                    (max - min) / (computedDivs <= 0 ? 10 : computedDivs);
                final double next = (value + step).clamp(min, max);
                onChanged(next);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28.w,
        height: 28.w,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 14.sp, color: Colors.grey.shade800),
      ),
    );
  }

  Widget _chipToggle({
    required bool active,
    required Color activeBackground,
    required Color inactiveBackground,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final Color bg = active ? activeBackground : inactiveBackground;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16.sp, color: Colors.white),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipStatus({required String label, Widget? child}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            if (child != null) ...[SizedBox(width: 10.w), child],
          ],
        ),
      ),
    );
  }

  void _saveCurrentDrawing() {
    // If there's an in-progress stroke, commit it first

    if (currentDrawingPoints.isNotEmpty) {
      drawingLayers.add(
        DrawingLayer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),

          tool: selectedDrawingTool,

          points: List<Offset>.from(currentDrawingPoints),

          color: drawingColor,

          strokeWidth: drawingStrokeWidth,

          isDotted:
              selectedDrawingTool == DrawingTool.dottedLine ||
              selectedDrawingTool == DrawingTool.dottedArrow,

          opacity: drawingOpacity,

          createdAt: DateTime.now(),

          text: selectedDrawingTool == DrawingTool.textPath
              ? _currentPathText
              : null,

          fontSize: selectedDrawingTool == DrawingTool.textPath
              ? drawingStrokeWidth
              : null,

          fontFamily: selectedDrawingTool == DrawingTool.textPath
              ? _currentPathFontFamily
              : null,
        ),
      );

      currentDrawingPoints.clear();
    }

    if (drawingLayers.isEmpty) return;

    // Calculate bounding box over all strokes

    final List<Offset> allPoints = drawingLayers
        .expand((l) => l.points)
        .toList();

    final bounds = _calculateDrawingBounds(allPoints);

    // Serialize strokes relative to top-left bounds

    final strokes = drawingLayers
        .map(
          (l) => {
            'tool': l.tool.name,

            'points': l.points.map((p) => p - bounds.topLeft).toList(),

            'color': HiveColor.fromColor(l.color),

            'strokeWidth': l.strokeWidth,

            'isDotted': l.isDotted,

            'opacity': l.opacity,

            if (l.tool == DrawingTool.textPath) ...{
              'text': l.text ?? '',

              'fontSize': l.fontSize ?? l.strokeWidth,

              'fontFamily': l.fontFamily,

              'fontWeight': l.fontWeight,

              'fontStyle': l.fontStyle,

              'letterSpacing': l.letterSpacing ?? 0.0,
            },
          },
        )
        .toList();

    final drawingItem = CanvasItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),

      type: CanvasItemType.drawing,

      position: bounds.topLeft,

      scale: 1.0,

      rotation: 0.0,

      opacity: 1.0,

      layerIndex: canvasItems.length,

      isVisible: true,

      isLocked: false,

      properties: {
        'strokes': strokes,

        'width': bounds.width,

        'height': bounds.height,
      },

      createdAt: DateTime.now(),

      lastModified: DateTime.now(),
    );

    setState(() {
      canvasItems.add(drawingItem);

      _selectItem(drawingItem);

      drawingLayers.clear();

      showDrawingControls = true;
    });

    // Record undo action and persist immediately

    _addAction(
      CanvasAction(type: 'add', item: drawingItem, timestamp: DateTime.now()),
    );

    _saveProject();
  }

  Rect _calculateDrawingBounds(List<Offset> points) {
    if (points.isEmpty) return Rect.zero;

    double minX = points.first.dx;

    double maxX = points.first.dx;

    double minY = points.first.dy;

    double maxY = points.first.dy;

    for (final point in points) {
      minX = math.min(minX, point.dx);

      maxX = math.max(maxX, point.dx);

      minY = math.min(minY, point.dy);

      maxY = math.max(maxY, point.dy);
    }

    // Add some padding

    const padding = 10.0;

    return Rect.fromLTRB(
      minX - padding,

      minY - padding,

      maxX + padding,

      maxY + padding,
    );
  }

  // Drawing control helper methods

  void _showDrawingColorPicker() {
    // Allow opening even when no drawing item is selected; fall back to current drawingColor

    final bool hasSelectedDrawing =
        selectedItem != null && selectedItem!.type == CanvasItemType.drawing;

    final Color currentColor = hasSelectedDrawing
        ? ((selectedItem!.properties['color'] as HiveColor?)?.toColor() ??
              drawingColor)
        : drawingColor;

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: Text('Choose Drawing Color'),

          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: currentColor,

              onColorChanged: (color) {
                setState(() {
                  // Always update the live drawing color used for new strokes

                  drawingColor = color;

                  // If a drawing item is selected, also update its stored color and strokes

                  if (hasSelectedDrawing) {
                    selectedItem!.properties['color'] = HiveColor.fromColor(
                      color,
                    );

                    final List<Map<String, dynamic>>? strokes =
                        (selectedItem!.properties['strokes'] as List<dynamic>?)
                            ?.map((e) => e as Map<String, dynamic>)
                            .toList();

                    if (strokes != null) {
                      for (final stroke in strokes) {
                        stroke['color'] = HiveColor.fromColor(color);
                      }

                      selectedItem!.properties['strokes'] = strokes;
                    }
                  }
                });
              },
            ),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),

              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _clearAllDrawings() {
    setState(() {
      drawingLayers.clear();

      currentDrawingPoints.clear();

      isDrawing = false;
    });
  }

  void _undoLastDrawing() {
    if (drawingLayers.isNotEmpty) {
      setState(() {
        drawingLayers.removeLast();
      });
    }
  }

  Widget _buildCanvas() {
    return Expanded(
      child: InteractiveViewer(
        minScale: 0.005,

        maxScale: 3.0,

        onInteractionUpdate: (details) {
          setState(() {
            canvasZoom = details.scale;
          });
        },

        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double cw = _currentProject!.canvasWidth;
              final double ch = _currentProject!.canvasHeight;
              final double availW = constraints.maxWidth;
              final double availH = constraints.maxHeight;
              final double scale = math.min(availW / cw, availH / ch);
              final double displayW = cw * scale;
              final double displayH = ch * scale;

              return Center(
                child: Container(
                  width: displayW,
                  height: displayH,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    child: RepaintBoundary(
                      key: _canvasRepaintKey,
                      child: Stack(
                        children: [
                          GestureDetector(
                            onTap: _deselectItem,
                            child: CustomPaint(
                              painter: CanvasGridPainter(
                                showGrid: snapToGrid,
                                gridSize: 20.0,
                              ),
                              child: Stack(
                                children: [
                                  ...(() {
                                    final items = [...canvasItems]
                                      ..sort(
                                        (a, b) => a.layerIndex.compareTo(
                                          b.layerIndex,
                                        ),
                                      );
                                    final visibleItems = items
                                        .where((it) => it.isVisible)
                                        .toList();
                                    return visibleItems
                                        .map((it) => _buildCanvasItem(it))
                                        .toList();
                                  })(),
                                ],
                              ),
                            ),
                          ),

                          if (drawingMode == DrawingMode.enabled)
                            Positioned.fill(
                              child: GestureDetector(
                                onPanStart: _onDrawingStart,
                                onPanUpdate: _onDrawingUpdate,
                                onPanEnd: _onDrawingEnd,
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: DrawingPainter(
                                      layers: drawingLayers,
                                      currentPoints: currentDrawingPoints,
                                      currentTool: selectedDrawingTool,
                                      currentColor: drawingColor,
                                      currentStrokeWidth: drawingStrokeWidth,
                                      currentOpacity: drawingOpacity,
                                      currentPathText: _currentPathText,
                                      currentPathFontFamily:
                                          _currentPathFontFamily,
                                      currentPathLetterSpacing:
                                          _currentPathLetterSpacing,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCanvasItem(CanvasItem item) {
    final isSelected = selectedItem == item;

    return Positioned(
      left: item.position.dx,

      top: item.position.dy,

      child: Transform.rotate(
        angle: item.rotation,

        child: Transform.scale(
          scale: item.scale,

          child: GestureDetector(
            behavior: HitTestBehavior.translucent,

            onTap: () {
              if (!item.isLocked) {
                _selectItem(item);
              }
            },

            onPanStart: (_) {
              if (!item.isLocked && selectedItem == item) {
                _preDragState = item.copyWith();
              }
            },

            onPanUpdate: (details) {
              if (!item.isLocked && selectedItem == item) {
                setState(() {
                  // Normalize by canvas zoom and amplify by item scale so large items
                  // don't feel sluggish to move.
                  final double zoomAdjusted = canvasZoom == 0
                      ? 1.0
                      : canvasZoom;
                  final double scaleAmplify = (item.scale <= 0)
                      ? 1.0
                      : item.scale;
                  final Offset canvasDelta =
                      details.delta * (scaleAmplify / zoomAdjusted);

                  Offset newPosition = item.position + canvasDelta;

                  if (snapToGrid) {
                    const double gridSize = 20.0;

                    newPosition = Offset(
                      (newPosition.dx / gridSize).round() * gridSize,

                      (newPosition.dy / gridSize).round() * gridSize,
                    );
                  }

                  item.position = newPosition;
                });
              }
            },

            onPanEnd: (_) {
              if (!item.isLocked &&
                  selectedItem == item &&
                  _preDragState != null) {
                _addAction(
                  CanvasAction(
                    type: 'modify',

                    item: item.copyWith(),

                    previousState: _preDragState,

                    timestamp: DateTime.now(),
                  ),
                );

                _preDragState = null;
              }
            },

            child: Stack(
              clipBehavior: Clip.none,

              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color:
                          (isSelected &&
                              item.type == CanvasItemType.shape &&
                              ((item.properties['shape'] as String?) ==
                                      'rectangle' ||
                                  (item.properties['shape'] as String?) ==
                                      'square'))
                          ? Colors
                                .transparent // Hide default border for quadrilaterals
                          : (isSelected
                                ? Colors.blue.shade400
                                : Colors.transparent),

                      width: 2,
                    ),
                  ),

                  child: Opacity(
                    opacity: item.opacity.clamp(0.0, 1.0),

                    child: _buildItemContent(item),
                  ),
                ),

                // Add custom selection border for quadrilaterals
                if (isSelected &&
                    item.type == CanvasItemType.shape &&
                    ((item.properties['shape'] as String?) == 'rectangle' ||
                        (item.properties['shape'] as String?) == 'square'))
                  _buildCustomSelectionBorder(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomSelectionBorder(CanvasItem item) {
    final double topSide = (item.properties['topSide'] as double?) ?? 100.0;

    final double rightSide = (item.properties['rightSide'] as double?) ?? 100.0;

    final double bottomSide =
        (item.properties['bottomSide'] as double?) ?? 100.0;

    final double leftSide = (item.properties['leftSide'] as double?) ?? 100.0;

    // Calculate the actual bounds of the quadrilateral

    final double maxWidth = math.max(leftSide, rightSide);

    final double maxHeight = math.max(topSide, bottomSide);

    // Calculate corner positions exactly like the shape painter does

    final double centerX = maxWidth / 2;

    final double centerY = maxHeight / 2;

    final double halfTopSide = topSide / 2;

    final double halfBottomSide = bottomSide / 2;

    final double halfLeftSide = leftSide / 2;

    final double halfRightSide = rightSide / 2;

    // Calculate corner positions (matching _createCustomRectanglePath)

    final double topLeftX = (centerX - halfTopSide).w;

    final double topLeftY = (centerY - halfLeftSide).h;

    final double topRightX = (centerX + halfTopSide).w;

    final double topRightY = (centerY - halfRightSide).h;

    final double bottomLeftX = (centerX - halfBottomSide).w;

    final double bottomLeftY = (centerY + halfLeftSide).h;

    final double bottomRightX = (centerX + halfBottomSide).w;

    final double bottomRightY = (centerY + halfRightSide).h;

    return Positioned.fill(
      child: CustomPaint(
        painter: _SelectionBorderPainter(
          topLeft: Offset(topLeftX, topLeftY),

          topRight: Offset(topRightX, topRightY),

          bottomLeft: Offset(bottomLeftX, bottomLeftY),

          bottomRight: Offset(bottomRightX, bottomRightY),
        ),
      ),
    );
  }

  Widget _buildBoundingBox(CanvasItem item) {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.blue.shade400.withOpacity(0.6),

            width: 2,
          ),

          borderRadius: BorderRadius.circular(8.r),
        ),

        child: Stack(
          children: [..._buildCornerHandles(item), _buildRotationHandle(item)],
        ),
      ),
    );
  }

  List<Widget> _buildCornerHandles(CanvasItem item) {
    // Check if this is a shape with individual side controls

    final bool isShapeWithSides =
        item.type == CanvasItemType.shape &&
        ((item.properties['shape'] as String?) == 'rectangle' ||
            (item.properties['shape'] as String?) == 'square');

    if (isShapeWithSides) {
      // Calculate dynamic positioning based on actual shape dimensions

      final double topSide = (item.properties['topSide'] as double?) ?? 100.0;

      final double rightSide =
          (item.properties['rightSide'] as double?) ?? 100.0;

      final double bottomSide =
          (item.properties['bottomSide'] as double?) ?? 100.0;

      final double leftSide = (item.properties['leftSide'] as double?) ?? 100.0;

      // Calculate the actual bounds of the quadrilateral

      final double maxWidth = math.max(leftSide, rightSide);

      final double maxHeight = math.max(topSide, bottomSide);

      // Calculate corner positions exactly like the shape painter does

      final double centerX = maxWidth / 2;

      final double centerY = maxHeight / 2;

      final double halfTopSide = topSide / 2;

      final double halfBottomSide = bottomSide / 2;

      final double halfLeftSide = leftSide / 2;

      final double halfRightSide = rightSide / 2;

      // Calculate corner positions (matching _createCustomRectanglePath)

      // Apply the same scaling as the container (.w and .h)

      final double topLeftX = (centerX - halfTopSide).w;

      final double topLeftY = (centerY - halfLeftSide).h;

      final double topRightX = (centerX + halfTopSide).w;

      final double topRightY = (centerY - halfRightSide).h;

      final double bottomLeftX = (centerX - halfBottomSide).w;

      final double bottomLeftY = (centerY + halfLeftSide).h;

      final double bottomRightX = (centerX + halfBottomSide).w;

      final double bottomRightY = (centerY + halfRightSide).h;

      return [
        // Top-left corner - positioned at actual quadrilateral corner
        Positioned(
          top: topLeftY - 6.h,

          left: topLeftX - 6.w,

          child: _buildResizeHandle(
            item,

            (details) => _handleShapeCornerResize(item, details, 'topLeft'),
          ),
        ),

        // Top-right corner - positioned at actual quadrilateral corner
        Positioned(
          top: topRightY - 6.h,

          left: topRightX - 6.w,

          child: _buildResizeHandle(
            item,

            (details) => _handleShapeCornerResize(item, details, 'topRight'),
          ),
        ),

        // Bottom-left corner - positioned at actual quadrilateral corner
        Positioned(
          top: bottomLeftY - 6.h,

          left: bottomLeftX - 6.w,

          child: _buildResizeHandle(
            item,

            (details) => _handleShapeCornerResize(item, details, 'bottomLeft'),
          ),
        ),

        // Bottom-right corner - positioned at actual quadrilateral corner
        Positioned(
          top: bottomRightY - 6.h,

          left: bottomRightX - 6.w,

          child: _buildResizeHandle(
            item,

            (details) => _handleShapeCornerResize(item, details, 'bottomRight'),
          ),
        ),
      ];
    } else {
      // Default corner handles for other items

      return [
        Positioned(
          top: -6.h,

          left: -6.w,

          child: _buildResizeHandle(
            item,

            (details) => _handleResizeUpdate(item, details, scaleSign: -1),
          ),
        ),

        Positioned(
          top: -6.h,

          right: -6.w,

          child: _buildResizeHandle(
            item,

            (details) => _handleResizeUpdate(item, details, scaleSign: 1),
          ),
        ),

        Positioned(
          bottom: -6.h,

          left: -6.w,

          child: _buildResizeHandle(
            item,

            (details) => _handleResizeUpdate(item, details, scaleSign: 1),
          ),
        ),

        Positioned(
          bottom: -6.h,

          right: -6.w,

          child: _buildResizeHandle(
            item,

            (details) => _handleResizeUpdate(item, details, scaleSign: 1),
          ),
        ),
      ];
    }
  }

  Widget _buildResizeHandle(
    CanvasItem item,

    ValueChanged<DragUpdateDetails> onPanUpdate,
  ) {
    return GestureDetector(
      onPanStart: (_) {
        _preTransformState = item.copyWith();
      },

      onPanUpdate: onPanUpdate,

      onPanEnd: (_) {
        if (_preTransformState != null) {
          _addAction(
            CanvasAction(
              type: 'modify',

              item: item.copyWith(),

              previousState: _preTransformState,

              timestamp: DateTime.now(),
            ),
          );

          _preTransformState = null;
        }
      },

      child: Container(
        width: 12.w,

        height: 12.h,

        decoration: BoxDecoration(
          color: Colors.blue.shade400,

          shape: BoxShape.circle,

          border: Border.all(color: Colors.white, width: 2),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),

              blurRadius: 4,

              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  void _handleResizeUpdate(
    CanvasItem item,

    DragUpdateDetails details, {

    int scaleSign = 1,
  }) {
    setState(() {
      final double dragMagnitude =
          (details.delta.dx.abs() + details.delta.dy.abs()) / 2;

      final double scaleDelta = (dragMagnitude / 100.0) * scaleSign;

      final double newScale = (item.scale + scaleDelta).clamp(
        0.2,

        10.0,
      ); // Changed from 5.0 to 10.0

      item.scale = newScale;
    });
  }

  void _handleShapeCornerResize(
    CanvasItem item,

    DragUpdateDetails details,

    String corner,
  ) {
    setState(() {
      final double sensitivity =
          0.5; // Adjust sensitivity for side length changes

      final double deltaX = details.delta.dx * sensitivity;

      final double deltaY = details.delta.dy * sensitivity;

      // Get current side lengths

      double topSide = (item.properties['topSide'] as double?) ?? 100.0;

      double rightSide = (item.properties['rightSide'] as double?) ?? 100.0;

      double bottomSide = (item.properties['bottomSide'] as double?) ?? 100.0;

      double leftSide = (item.properties['leftSide'] as double?) ?? 100.0;

      // Update side lengths based on corner being dragged

      switch (corner) {
        case 'topLeft':

          // Dragging top-left affects top and left sides

          topSide = (topSide - deltaY).clamp(20.0, 500.0);

          leftSide = (leftSide - deltaX).clamp(20.0, 500.0);

          break;

        case 'topRight':

          // Dragging top-right affects top and right sides

          topSide = (topSide - deltaY).clamp(20.0, 500.0);

          rightSide = (rightSide + deltaX).clamp(20.0, 500.0);

          break;

        case 'bottomLeft':

          // Dragging bottom-left affects bottom and left sides

          bottomSide = (bottomSide + deltaY).clamp(20.0, 500.0);

          leftSide = (leftSide - deltaX).clamp(20.0, 500.0);

          break;

        case 'bottomRight':

          // Dragging bottom-right affects bottom and right sides

          bottomSide = (bottomSide + deltaY).clamp(20.0, 500.0);

          rightSide = (rightSide + deltaX).clamp(20.0, 500.0);

          break;
      }

      // Update the properties

      item.properties['topSide'] = topSide;

      item.properties['rightSide'] = rightSide;

      item.properties['bottomSide'] = bottomSide;

      item.properties['leftSide'] = leftSide;

      // Update overall width and height to match the new dimensions

      item.properties['width'] = math.max(leftSide, rightSide);

      item.properties['height'] = math.max(topSide, bottomSide);
    });
  }

  Widget _buildRotationHandle(CanvasItem item) {
    return Positioned(
      top: -30.h,

      left: 0,

      right: 0,

      child: Center(
        child: GestureDetector(
          onPanStart: (_) {
            _preTransformState = item.copyWith();
          },

          onPanUpdate: (details) {
            setState(() {
              item.rotation += details.delta.dx * 0.01;
            });
          },

          onPanEnd: (_) {
            if (_preTransformState != null) {
              _addAction(
                CanvasAction(
                  type: 'modify',

                  item: item.copyWith(),

                  previousState: _preTransformState,

                  timestamp: DateTime.now(),
                ),
              );

              _preTransformState = null;
            }
          },

          child: Container(
            width: 24.w,

            height: 24.h,

            decoration: BoxDecoration(
              color: Colors.green.shade400,

              shape: BoxShape.circle,

              border: Border.all(color: Colors.white, width: 2),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),

                  blurRadius: 4,

                  offset: const Offset(0, 2),
                ),
              ],
            ),

            child: Icon(
              Icons.rotate_right_rounded,

              color: Colors.white,

              size: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemContent(CanvasItem item) {
    switch (item.type) {
      case CanvasItemType.text:
        final props = item.properties;

        final String? fontFamily = props['fontFamily'] as String?;

        final bool textHasGradient = props['hasGradient'] == true;

        final bool textHasShadow = props['hasShadow'] == true;

        final double textShadowOpacity =
            (props['shadowOpacity'] as double?) ?? 0.6;

        final Color baseShadowColor = (props['shadowColor'] is HiveColor)
            ? (props['shadowColor'] as HiveColor).toColor()
            : (props['shadowColor'] is Color)
            ? (props['shadowColor'] as Color)
            : Colors.grey;

        final Color effectiveShadowColor = baseShadowColor.withOpacity(
          (baseShadowColor.opacity * textShadowOpacity).clamp(0.0, 1.0),
        );

        final TextStyle baseStyle = TextStyle(
          fontSize: (props['fontSize'] ?? 24.0) as double,

          // Force solid white text when using ShaderMask gradient so the alpha is solid
          color: textHasGradient
              ? Colors.white
              : (props['color'] is HiveColor)
              ? (props['color'] as HiveColor).toColor()
              : (props['color'] is Color)
              ? (props['color'] as Color)
              : Colors.black,

          fontWeight: _parseFontWeight(props['fontWeight']),

          fontStyle: _parseFontStyle(props['fontStyle']),

          decoration: _intToTextDecoration((props['decoration'] as int?) ?? 0),

          decorationColor: (props['color'] is HiveColor)
              ? (props['color'] as HiveColor).toColor()
              : (props['color'] as Color?),

          letterSpacing: (props['letterSpacing'] as double?) ?? 0.0,

          shadows: textHasShadow
              ? [
                  Shadow(
                    color: effectiveShadowColor,

                    offset:
                        _parseOffset(props['shadowOffset']) ??
                        const Offset(2, 2),

                    blurRadius: (props['shadowBlur'] as double?) ?? 4.0,
                  ),
                ]
              : null,
        );

        Widget textWidget;

        if (fontFamily != null) {
          try {
            final TextStyle gfStyle = GoogleFonts.getFont(
              fontFamily,

              textStyle: baseStyle,
            );

            textWidget = Text(
              (props['text'] ?? 'Text') as String,

              style: gfStyle,

              textAlign: (props['textAlign'] as TextAlign?) ?? TextAlign.center,
            );
          } catch (_) {
            textWidget = Text(
              (props['text'] ?? 'Text') as String,

              style: baseStyle,

              textAlign: (props['textAlign'] as TextAlign?) ?? TextAlign.center,
            );
          }
        } else {
          textWidget = Text(
            (props['text'] ?? 'Text') as String,

            style: baseStyle,

            textAlign: (props['textAlign'] as TextAlign?) ?? TextAlign.center,
          );
        }

        if (textHasGradient) {
          final double angle = (props['gradientAngle'] as double?) ?? 0.0;

          final double rad = angle * math.pi / 185.0;

          final double cx = math.cos(rad);

          final double sy = math.sin(rad);

          final Alignment begin = Alignment(-cx, -sy);

          final Alignment end = Alignment(cx, sy);

          textWidget = ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors:
                  (props['gradientColors'] as List<dynamic>?)
                      ?.map((e) => (e as HiveColor).toColor())
                      .toList() ??
                  [
                    HiveColor.fromColor(Colors.blue).toColor(),

                    HiveColor.fromColor(Colors.purple).toColor(),
                  ],

              begin: begin,

              end: end,
            ).createShader(bounds),

            child: textWidget,
          );
        }

        return Container(padding: EdgeInsets.all(16.w), child: textWidget);

      case CanvasItemType.image:
        final String? filePath = item.properties['filePath'] as String?;

        final double blur = (item.properties['blur'] as double?) ?? 0.0;

        final bool hasGradient =
            (item.properties['hasGradient'] as bool?) ?? false;

        final List<Color> grad =
            (item.properties['gradientColors'] as List<dynamic>?)
                ?.map(
                  (e) => (e is HiveColor ? e : (e is int ? HiveColor(e) : null))
                      ?.toColor(),
                )
                .whereType<Color>()
                .toList() ??
            [];

        final bool hasShadow = (item.properties['hasShadow'] as bool?) ?? false;

        final Color shadowColor = (item.properties['shadowColor'] is HiveColor)
            ? (item.properties['shadowColor'] as HiveColor).toColor()
            : (item.properties['shadowColor'] is Color)
            ? (item.properties['shadowColor'] as Color)
            : Colors.black54;

        final Offset shadowOffset =
            (item.properties['shadowOffset'] as Offset?) ?? const Offset(4, 4);

        final double shadowBlur =
            (item.properties['shadowBlur'] as double?) ?? 8.0;

        final double shadowOpacity =
            (item.properties['shadowOpacity'] as double?) ?? 0.6;

        final double shadowSize =
            (item.properties['shadowSize'] as double?) ?? 0.0;

        final double gradientAngle =
            (item.properties['gradientAngle'] as double?) ?? 0.0;

        final Color tintColor = (item.properties['tint'] is HiveColor)
            ? (item.properties['tint'] as HiveColor).toColor()
            : (item.properties['tint'] is Color)
            ? (item.properties['tint'] as Color)
            : Colors.transparent;

        final double? displayW = (item.properties['displayWidth'] as double?);

        final double? displayH = (item.properties['displayHeight'] as double?);

        // Build the main image first

        Widget mainImage = _buildActualImage(
          filePath,

          item,

          tintColor,

          grad,

          hasGradient,

          gradientAngle,
        );

        // Apply blur to the main image if needed

        if (blur > 0.0) {
          final ui.ImageFilter filter = ui.ImageFilter.blur(
            sigmaX: blur,

            sigmaY: blur,
          );

          mainImage = ImageFiltered(imageFilter: filter, child: mainImage);
        }

        // Create shadow and main image stack

        Widget imageWidget = Stack(
          children: [
            // Image-shaped shadow behind the image
            if (hasShadow)
              Transform.translate(
                offset: shadowOffset,

                child: _buildImageShadow(
                  mainImage,

                  shadowColor.withOpacity(shadowOpacity.clamp(0.0, 1.0)),

                  shadowBlur,

                  (displayW ?? 185.0).w,

                  (displayH ?? 10.0).h,

                  shadowSize,
                ),
              ),

            // Main image on top
            mainImage,
          ],
        );

        return imageWidget;

      case CanvasItemType.sticker:
        final props = item.properties;

        final int iconCodePoint =
            (props['iconCodePoint'] as int?) ?? Icons.star.codePoint;

        final String? iconFontFamily = props['iconFontFamily'] as String?;

        final Color color = (props['color'] is HiveColor)
            ? (props['color'] as HiveColor).toColor()
            : Colors.yellow;

        final double size = (props['size'] as double?) ?? 60.0;

        return FittedBox(
          fit: BoxFit.contain,

          child: Icon(
            IconData(iconCodePoint, fontFamily: iconFontFamily),

            color: color,

            size: size,
          ),
        );

      case CanvasItemType.shape:
        final props = item.properties;

        final String shape = (props['shape'] as String?) ?? 'rectangle';

        final Color fillColor = (props['fillColor'] is HiveColor)
            ? (props['fillColor'] as HiveColor).toColor()
            : Colors.green;

        final Color strokeColor = (props['strokeColor'] is HiveColor)
            ? (props['strokeColor'] as HiveColor).toColor()
            : Colors.black;

        final double strokeWidth = (props['strokeWidth'] as double?) ?? 2.0;

        final double cornerRadius = (props['cornerRadius'] as double?) ?? 0.0;

        final bool hasGradient = (props['hasGradient'] as bool?) ?? false;

        final List<Color> gradientColors =
            (props['gradientColors'] as List<dynamic>?)
                ?.map(
                  (e) => (e is HiveColor ? e : (e is int ? HiveColor(e) : null))
                      ?.toColor(),
                )
                .whereType<Color>()
                .toList() ??
            [];

        final double gradientAngle = (props['gradientAngle'] as double?) ?? 0.0;

        final bool hasShadow = (props['hasShadow'] as bool?) ?? false;

        final HiveColor shadowColorHive = (props['shadowColor'] is HiveColor)
            ? (props['shadowColor'] as HiveColor)
            : (props['shadowColor'] is Color)
            ? HiveColor.fromColor(props['shadowColor'] as Color)
            : HiveColor.fromColor(Colors.black54);

        final Offset shadowOffset =
            (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);

        final double shadowBlur = (props['shadowBlur'] as double?) ?? 8.0;

        final double shadowOpacity = (props['shadowOpacity'] as double?) ?? 0.6;

        final ui.Image? fillImage =
            props['image'] as ui.Image?; // Get the ui.Image

        final HiveSize? hiveSize = props['size'] as HiveSize?;

        final double width = (props['width'] as double?) ?? 100.0;

        final double height = (props['height'] as double?) ?? 100.0;

        // For quadrilaterals, calculate the actual bounds based on side lengths

        Size itemSize;

        if (shape == 'rectangle' || shape == 'square') {
          final double topSide = (props['topSide'] as double?) ?? 100.0;

          final double rightSide = (props['rightSide'] as double?) ?? 100.0;

          final double bottomSide = (props['bottomSide'] as double?) ?? 100.0;

          final double leftSide = (props['leftSide'] as double?) ?? 100.0;

          // Calculate the maximum bounds needed to contain the quadrilateral

          final double maxWidth = math.max(leftSide, rightSide);

          final double maxHeight = math.max(topSide, bottomSide);

          itemSize = Size(maxWidth.w, maxHeight.h);
        } else {
          itemSize = Size(width.w, height.h);
        }

        Widget shapeWidget = CustomPaint(
          painter: _ShapePainter({
            'shape': shape,

            'fillColor': HiveColor.fromColor(fillColor),

            'strokeColor': HiveColor.fromColor(strokeColor),

            'strokeWidth': strokeWidth,

            'cornerRadius': cornerRadius,

            'topSide': props['topSide'] as double?,

            'rightSide': props['rightSide'] as double?,

            'bottomSide': props['bottomSide'] as double?,

            'leftSide': props['leftSide'] as double?,

            'topLeftRadius': props['topLeftRadius'] as double?,

            'topRightRadius': props['topRightRadius'] as double?,

            'bottomLeftRadius': props['bottomLeftRadius'] as double?,

            'bottomRightRadius': props['bottomRightRadius'] as double?,

            'topRadius': props['topRadius'] as double?,

            'hasGradient':
                hasGradient &&
                fillImage == null, // Disable gradient if image is present

            'gradientColors': gradientColors
                .map((color) => HiveColor.fromColor(color))
                .toList(),

            'gradientAngle': gradientAngle,

            'hasShadow': hasShadow,

            'shadowColor': shadowColorHive,

            'shadowOffset': shadowOffset,

            'shadowBlur': shadowBlur,

            'shadowOpacity': shadowOpacity,

            'image': fillImage, // Pass the ui.Image to the painter
          }),

          size: itemSize,
        );

        return SizedBox(
          width: itemSize.width,

          height: itemSize.height,

          child: FittedBox(fit: BoxFit.contain, child: shapeWidget),
        );

      case CanvasItemType.drawing:
        final props = item.properties;

        final double width = (props['width'] as double?) ?? 100.0;

        final double height = (props['height'] as double?) ?? 100.0;

        final List<Map<String, dynamic>>? strokes =
            (props['strokes'] as List<dynamic>?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList();

        if (strokes != null && strokes.isNotEmpty) {
          final bool canErase =
              drawingMode == DrawingMode.enabled &&
              selectedItem?.id == item.id &&
              selectedDrawingTool == DrawingTool.eraser;

          final Widget painted = SizedBox(
            width: width,

            height: height,

            child: CustomPaint(
              painter: _MultiStrokeDrawingPainter(
                strokes: (props['strokes'] as List<dynamic>)
                    .map((e) => e as Map<String, dynamic>)
                    .map((s) {
                      // Normalize: if tool is stored as String, map it back to enum for painter

                      final dynamic toolRaw = s['tool'];

                      if (toolRaw is String) {
                        try {
                          s['tool'] = DrawingTool.values.firstWhere(
                            (t) => t.name == toolRaw,
                          );
                        } catch (_) {}
                      }

                      return s;
                    })
                    .toList(),
              ),
            ),
          );

          if (!canErase) {
            // Not in eraser mode → let parent gesture handle moving/transforming

            return painted;
          }

          return GestureDetector(
            onPanStart: (details) {
              if (selectedItem?.id != item.id) return;

              setState(() {
                final Offset p = details.localPosition;

                props['strokes'] = [
                  ...strokes,

                  {
                    'tool': DrawingTool.eraser,

                    'points': <Offset>[p],

                    'color': HiveColor.fromColor(Colors.transparent),

                    'strokeWidth': (props['strokeWidth'] as double?) ?? 12.0,

                    'isDotted': false,

                    'opacity': 1.0,
                  },
                ];
              });
            },

            onPanUpdate: (details) {
              if (selectedItem?.id != item.id) return;

              setState(() {
                final List<Map<String, dynamic>> list =
                    (props['strokes'] as List<dynamic>)
                        .map((e) => e as Map<String, dynamic>)
                        .toList();

                if (list.isEmpty) return;

                final last = list.last;

                if ((last['tool'] as DrawingTool?) == DrawingTool.eraser) {
                  final List<Offset> points = (last['points'] as List<dynamic>)
                      .map((e) => e as Offset)
                      .toList();

                  points.add(details.localPosition);

                  last['points'] = points;

                  props['strokes'] = list;
                }
              });
            },

            child: painted,
          );
        } else {
          // Backward compatibility for single-stroke drawings

          final DrawingTool tool =
              props['tool'] as DrawingTool? ?? DrawingTool.brush;

          final List<Offset> points =
              (props['points'] as List<dynamic>?)
                  ?.map<Offset>((p) => _parseOffset(p) ?? const Offset(0, 0))
                  .toList() ??
              <Offset>[];

          final Color color = (props['color'] is HiveColor)
              ? (props['color'] as HiveColor).toColor()
              : Colors.black;

          final double strokeWidth = (props['strokeWidth'] as double?) ?? 2.0;

          final bool isDotted = (props['isDotted'] as bool?) ?? false;

          return SizedBox(
            width: width,

            height: height,

            child: CustomPaint(
              painter: _DrawingItemPainter(
                tool: tool,

                points: points,

                color: color,

                strokeWidth: strokeWidth,

                isDotted: isDotted,
              ),
            ),
          );
        }
    }
  }

  Widget _buildActualImage(
    String? filePath,

    CanvasItem item,

    Color tintColor,

    List<Color> grad,

    bool hasGradient,

    double gradientAngle,
  ) {
    final String? imageUrl = item.properties['imageUrl'] as String?;

    final double? displayW = (item.properties['displayWidth'] as double?);

    final double? displayH = (item.properties['displayHeight'] as double?);

    Widget imageWidget;

    if (filePath != null) {
      imageWidget = Image.file(File(filePath), fit: BoxFit.contain);
    } else if (imageUrl != null) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,

        fit: BoxFit.contain,

        placeholder: (context, url) =>
            const Center(child: CircularProgressIndicator()),

        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      imageWidget = Icon(
        (item.properties['icon'] as IconData?) ?? Icons.image,

        size: 90.sp,

        color:
            (item.properties['color'] as HiveColor?)?.toColor() ?? Colors.blue,
      );
    }

    if (hasGradient) {
      // For images, if Color B is transparent, only use Color A (no gradient)
      if (grad.length >= 2 && grad.last == Colors.transparent) {
        // Use only Color A as a solid color tint
        imageWidget = ColorFiltered(
          colorFilter: ColorFilter.mode(grad.first, BlendMode.srcIn),
          child: imageWidget,
        );
      } else {
        // Use normal gradient
        final double rad = gradientAngle * math.pi / 185.0;

        final double cx = math.cos(rad);

        final double sy = math.sin(rad);

        final Alignment begin = Alignment(-cx, -sy);

        final Alignment end = Alignment(cx, sy);

        // Check if any gradient color is transparent
        final bool hasTransparent = grad.any(
          (color) => color == Colors.transparent,
        );

        imageWidget = ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: grad,

            begin: begin,

            end: end,
          ).createShader(bounds),

          blendMode: hasTransparent ? BlendMode.srcATop : BlendMode.srcIn,
          child: imageWidget,
        );
      }
    } else {
      imageWidget = ColorFiltered(
        colorFilter: ColorFilter.mode(tintColor, BlendMode.overlay),

        child: imageWidget,
      );
    }

    return SizedBox(
      width: (displayW ?? 185.0).w,

      height: (displayH ?? 185.0).h,

      child: imageWidget,
    );
  }

  BoxDecoration _buildShapeDecoration(Map<String, dynamic> props) {
    final String shape = (props['shape'] as String?) ?? 'rectangle';

    return BoxDecoration(
      color: (props['hasGradient'] == true)
          ? null
          : (props['fillColor'] as Color? ?? Colors.green),

      gradient: (props['hasGradient'] == true)
          ? LinearGradient(
              colors:
                  (props['gradientColors'] as List<Color>?) ??
                  [Colors.green, Colors.purple],
            )
          : null,

      border: Border.all(
        color: (props['strokeColor'] as Color?) ?? Colors.black,

        width: (props['strokeWidth'] as double?) ?? 2.0,
      ),

      borderRadius: shape == 'rectangle'
          ? BorderRadius.circular((props['cornerRadius'] as double?) ?? 12.0)
          : null,

      shape: shape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
    );
  }

  Widget _buildControlButton(
    IconData icon,

    VoidCallback onTap,

    Color color,

    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,

      preferBelow: false,

      child: GestureDetector(
        onTap: onTap,

        child: Container(
          padding: EdgeInsets.all(12.w),

          decoration: BoxDecoration(
            color: color.withOpacity(0.15),

            borderRadius: BorderRadius.circular(20.r),

            border: Border.all(color: color.withOpacity(0.3), width: 1),

            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),

                blurRadius: 8,

                offset: const Offset(0, 2),
              ),
            ],
          ),

          child: Icon(icon, size: 20.sp, color: color),
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    if (!showBottomSheet || selectedItem == null) return const SizedBox();

    return AnimatedBuilder(
      animation: _bottomSheetAnimation,

      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _bottomSheetAnimation.value) * 320.h),

          child: Container(
            height: 320.h,

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.r),

                topRight: Radius.circular(32.r),
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),

                  blurRadius: 32,

                  offset: const Offset(0, -12),
                ),
              ],
            ),

            child: Column(
              children: [
                Container(
                  width: 60.w,

                  height: 6.h,

                  margin: EdgeInsets.symmetric(vertical: 16.h),

                  decoration: BoxDecoration(
                    color: Colors.grey[300],

                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),

                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),

                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),

                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,

                              Colors.blue.shade600,
                            ],
                          ),

                          borderRadius: BorderRadius.circular(16.r),
                        ),

                        child: Icon(
                          _getItemTypeIcon(selectedItem!.type),

                          color: Colors.white,

                          size: 24.sp,
                        ),
                      ),

                      SizedBox(width: 16.w),

                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            '${selectedItem!.type.name.toUpperCase()} PROPERTIES',

                            style: TextStyle(
                              fontSize: 16.sp,

                              fontWeight: FontWeight.bold,

                              color: Colors.grey[800],

                              letterSpacing: 0.5,
                            ),
                          ),

                          Text(
                            'Customize your ${selectedItem!.type.name}',

                            style: TextStyle(
                              fontSize: 12.sp,

                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20.h),

                Expanded(child: _buildBottomSheetContent()),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getItemTypeIcon(CanvasItemType type) {
    switch (type) {
      case CanvasItemType.text:
        return Icons.text_fields_rounded;

      case CanvasItemType.image:
        return Icons.image_rounded;

      case CanvasItemType.sticker:
        return Icons.emoji_emotions_rounded;

      case CanvasItemType.shape:
        return Icons.category_rounded;

      case CanvasItemType.drawing:
        return Icons.brush;
    }
  }

  Widget _buildBottomSheetContent() {
    if (selectedItem == null) return const SizedBox();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),

      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            _buildCommonOptions(),

            SizedBox(height: 24.h),

            Divider(color: Colors.grey[200], thickness: 1),

            SizedBox(height: 24.h),

            _buildTypeSpecificOptions(),

            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildCommonOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          'GENERAL',

          style: TextStyle(
            fontSize: 12.sp,

            fontWeight: FontWeight.bold,

            color: Colors.grey[600],

            letterSpacing: 1,
          ),
        ),

        SizedBox(height: 16.h),

        _buildSliderOption(
          'Opacity',

          selectedItem!.opacity,

          0.1,

          1.0,

          (value) => setState(() => selectedItem!.opacity = value),

          Icons.opacity_rounded,
        ),

        SizedBox(height: 16.h),

        _buildSliderOption(
          'Scale',

          selectedItem!.scale,

          0.3,

          10.0,

          (value) => setState(() => selectedItem!.scale = value),

          Icons.zoom_out_map_rounded,
        ),

        SizedBox(height: 16.h),

        _buildSliderOption(
          'Rotation',

          selectedItem!.rotation * 185 / 3.14159,

          -185,

          185,

          (value) =>
              setState(() => selectedItem!.rotation = value * 3.14159 / 185),

          Icons.rotate_right_rounded,
        ),
      ],
    );
  }

  Widget _buildTypeSpecificOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          '${selectedItem!.type.name.toUpperCase()} OPTIONS',

          style: TextStyle(
            fontSize: 12.sp,

            fontWeight: FontWeight.bold,

            color: Colors.grey[600],

            letterSpacing: 1,
          ),
        ),

        SizedBox(height: 16.h),

        _buildSpecificOptionsContent(),
      ],
    );
  }

  Widget _buildSpecificOptionsContent() {
    switch (selectedItem!.type) {
      case CanvasItemType.text:
        return _buildTextOptions();

      case CanvasItemType.image:
        return _buildImageOptions();

      case CanvasItemType.sticker:
        return _buildStickerOptions();

      case CanvasItemType.shape:
        return _buildShapeOptions();

      case CanvasItemType.drawing:
        return _buildDrawingOptions();
    }
  }

  Widget _buildDrawingOptions() {
    if (selectedItem == null || selectedItem!.type != CanvasItemType.drawing) {
      return const SizedBox();
    }

    final props = selectedItem!.properties;

    final Color currentColor =
        (props['color'] as HiveColor?)?.toColor() ?? Colors.black;

    final double strokeWidth = (props['strokeWidth'] as double?) ?? 2.0;

    final DrawingTool tool =
        (props['tool'] as DrawingTool?) ?? DrawingTool.brush;

    return Container(
      padding: EdgeInsets.all(16.w),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            'Drawing Properties',

            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 16.h),

          // Color picker
          Row(
            children: [
              Text(
                'Color:',

                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),

              SizedBox(width: 16.w),

              GestureDetector(
                onTap: _showDrawingColorPicker,

                child: Container(
                  width: 40.w,

                  height: 40.h,

                  decoration: BoxDecoration(
                    color: currentColor,

                    borderRadius: BorderRadius.circular(8.r),

                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Stroke width
          Row(
            children: [
              Text(
                'Stroke Width:',

                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),

              SizedBox(width: 16.w),

              Expanded(
                child: Slider(
                  value: strokeWidth,

                  min: 1.0,

                  max: 20.0,

                  divisions: 19,

                  onChanged: (value) {
                    setState(() {
                      selectedItem!.properties['strokeWidth'] = value;

                      final List<Map<String, dynamic>>? strokes =
                          (selectedItem!.properties['strokes']
                                  as List<dynamic>?)
                              ?.map((e) => e as Map<String, dynamic>)
                              .toList();

                      if (strokes != null) {
                        for (final stroke in strokes) {
                          stroke['strokeWidth'] = value;
                        }

                        selectedItem!.properties['strokes'] = strokes;
                      }
                    });
                  },
                ),
              ),

              Text('${strokeWidth.toInt()}', style: TextStyle(fontSize: 12.sp)),
            ],
          ),

          SizedBox(height: 16.h),

          // Tool type display
          Row(
            children: [
              Text(
                'Tool:',

                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),

              SizedBox(width: 16.w),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,

                  borderRadius: BorderRadius.circular(8.r),

                  border: Border.all(color: Colors.grey.shade300),
                ),

                child: Text(
                  _getDrawingToolName(tool),

                  style: TextStyle(
                    fontSize: 12.sp,

                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDrawingToolName(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.brush:
        return 'Brush';

      case DrawingTool.pencil:
        return 'Pencil';

      case DrawingTool.eraser:
        return 'Eraser';

      case DrawingTool.rectangle:
        return 'Rectangle';

      case DrawingTool.circle:
        return 'Circle';

      case DrawingTool.triangle:
        return 'Triangle';

      case DrawingTool.line:
        return 'Line';

      case DrawingTool.arrow:
        return 'Arrow';

      case DrawingTool.dottedLine:
        return 'Dotted Line';

      case DrawingTool.dottedArrow:
        return 'Dotted Arrow';

      case DrawingTool.textPath:
        return 'Text Path';
    }
  }

  Widget _buildTextOptions() {
    final props = selectedItem!.properties;

    final controller = TextEditingController(
      text: props['text'] as String? ?? '',
    );

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],

            borderRadius: BorderRadius.circular(16.r),

            border: Border.all(color: Colors.grey.shade200),
          ),

          child: TextField(
            decoration: InputDecoration(
              labelText: 'Text Content',

              labelStyle: TextStyle(color: Colors.grey[600]),

              border: InputBorder.none,

              contentPadding: EdgeInsets.symmetric(
                horizontal: 20.w,

                vertical: 16.h,
              ),
            ),

            onChanged: (value) => setState(() => props['text'] = value),

            controller: controller,
          ),
        ),

        SizedBox(height: 20.h),

        _buildSliderOption(
          'Font Size',

          (props['fontSize'] as double?) ?? 24.0,

          10.0,

          72.0,

          (value) => setState(() => props['fontSize'] = value),

          Icons.format_size_rounded,
        ),

        SizedBox(height: 16.h),

        _buildSliderOption(
          'Letter Spacing',

          (props['letterSpacing'] as double?) ?? 0.0,

          -2.0,

          5.0,

          (value) => setState(() => props['letterSpacing'] = value),

          Icons.space_bar_rounded,
        ),

        SizedBox(height: 20.h),

        _buildFontSelectionSection(props),

        SizedBox(height: 20.h),

        _buildColorSection(props),

        SizedBox(height: 20.h),

        _buildTextStyleOptions(props),

        SizedBox(height: 20.h),

        _buildTextEffectsOptions(props),
      ],
    );
  }

  Widget _buildColorSection(Map<String, dynamic> props) {
    return Column(
      children: [
        _buildColorOption('Text Color', 'color', props),

        SizedBox(height: 16.h),

        _buildToggleOption(
          'Gradient',

          (props['hasGradient'] as bool?) ?? false,

          Icons.gradient_rounded,

          (value) => setState(() {
            final bool newVal = !((props['hasGradient'] as bool?) ?? false);
            props['hasGradient'] = newVal;
            if (newVal) {
              props['hasShadow'] = false;
            }

            // Initialize gradient colors if not present
            if (newVal &&
                (props['gradientColors'] == null ||
                    (props['gradientColors'] as List).isEmpty)) {
              props['gradientColors'] = [
                HiveColor.fromColor(Colors.green),

                HiveColor.fromColor(Colors.purple),
              ];
            }
          }),
        ),

        if (props['hasGradient'] == true) ...[
          SizedBox(height: 16.h),

          _buildGradientPicker(props),
        ],
      ],
    );
  }

  Widget _buildGradientPicker(Map<String, dynamic> props) {
    final List<Color> grad =
        (props['gradientColors'] as List<Color>?) ??
        [Colors.blue, Colors.purple];

    return Row(
      children: [
        Text(
          'Gradient Colors',

          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
        ),

        const Spacer(),

        Row(
          children: [
            GestureDetector(
              onTap: () => _showColorPicker('gradientColor1', isGradient: true),

              child: Container(
                width: 32.w,

                height: 32.h,

                decoration: BoxDecoration(
                  color: grad.first == Colors.transparent
                      ? Colors.white
                      : grad.first,
                  borderRadius: BorderRadius.circular(8.r),

                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),

                child: grad.first == Colors.transparent
                    ? Stack(
                        children: [
                          CustomPaint(
                            painter: CheckerboardPainter(),
                            size: Size(32.w, 32.h),
                          ),
                          Center(
                            child: Container(
                              width: 20.w,
                              height: 2.h,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(1.r),
                              ),
                              transform: Matrix4.rotationZ(
                                0.785398,
                              ), // 45 degrees
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            SizedBox(width: 8.w),

            Icon(
              Icons.arrow_forward_rounded,

              size: 16.sp,

              color: Colors.grey[600],
            ),

            SizedBox(width: 8.w),

            GestureDetector(
              onTap: () => _showColorPicker('gradientColor2', isGradient: true),

              child: Container(
                width: 32.w,

                height: 32.h,

                decoration: BoxDecoration(
                  color: grad.last == Colors.transparent
                      ? Colors.white
                      : grad.last,
                  borderRadius: BorderRadius.circular(8.r),

                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),

                child: grad.last == Colors.transparent
                    ? Stack(
                        children: [
                          CustomPaint(
                            painter: CheckerboardPainter(),
                            size: Size(32.w, 32.h),
                          ),
                          Center(
                            child: Container(
                              width: 20.w,
                              height: 2.h,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(1.r),
                              ),
                              transform: Matrix4.rotationZ(
                                0.785398,
                              ), // 45 degrees
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),

            SizedBox(width: 12.w),

            Row(
              children: [
                Icon(
                  Icons.rotate_right_rounded,

                  size: 16.sp,

                  color: Colors.grey[600],
                ),

                SizedBox(width: 6.w),

                Text(
                  'Angle',

                  style: TextStyle(
                    fontSize: 12.sp,

                    color: Colors.grey[700],

                    fontWeight: FontWeight.w600,
                  ),
                ),

                SizedBox(width: 8.w),

                SizedBox(
                  width: 185.w,

                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,

                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8.0,
                      ),

                      activeTrackColor: Colors.blue.shade400,

                      inactiveTrackColor: Colors.blue.shade100,

                      thumbColor: Colors.blue.shade600,
                    ),

                    child: Slider(
                      value: ((props['gradientAngle'] as double?) ?? 0.0).clamp(
                        -185.0,

                        185.0,
                      ),

                      min: -185.0,

                      max: 185.0,

                      onChanged: (v) =>
                          setState(() => props['gradientAngle'] = v),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextEffectsOptions(Map<String, dynamic> props) {
    return Column(
      children: [
        _buildToggleOption(
          'Shadow',

          (props['hasShadow'] as bool?) ?? false,

          CupertinoIcons.moon_stars,

          (value) => setState(() => props['hasShadow'] = value),
        ),

        if (props['hasShadow'] == true) ...[
          SizedBox(height: 16.h),

          _buildColorOption('Shadow Color', 'shadowColor', props),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Blur',

            (props['shadowBlur'] as double?) ?? 4.0,

            0.0,

            20.0,

            (value) => setState(() => props['shadowBlur'] = value),

            Icons.blur_on_rounded,
          ),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Opacity',

            (props['shadowOpacity'] as double?) ?? 0.6,

            0.0,

            1.0,

            (value) => setState(() => props['shadowOpacity'] = value),

            Icons.opacity_rounded,
          ),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Offset X',

            (props['shadowOffset'] as Offset?)?.dx ?? 2.0,

            -50.0,

            50.0,

            (value) {
              setState(() {
                final Offset cur =
                    (props['shadowOffset'] as Offset?) ?? const Offset(2, 2);

                props['shadowOffset'] = Offset(value, cur.dy);
              });
            },

            Icons.swap_horiz_rounded,
          ),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Offset Y',

            (props['shadowOffset'] as Offset?)?.dy ?? 2.0,

            -50.0,

            50.0,

            (value) {
              setState(() {
                final Offset cur =
                    (props['shadowOffset'] as Offset?) ?? const Offset(2, 2);

                props['shadowOffset'] = Offset(cur.dx, value);
              });
            },

            Icons.swap_vert_rounded,
          ),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Size',

            (props['shadowSize'] as double?) ?? 0.0,

            0.0,

            100.0,

            (value) => setState(() => props['shadowSize'] = value),

            Icons.zoom_out_map_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildTextStyleOptions(Map<String, dynamic> props) {
    return Row(
      children: [
        Expanded(
          child: _buildToggleButton(
            'Bold',

            props['fontWeight'] == FontWeight.bold,

            Icons.format_bold_rounded,

            () => setState(() {
              props['fontWeight'] = (props['fontWeight'] == FontWeight.bold)
                  ? FontWeight.normal
                  : FontWeight.bold;
            }),
          ),
        ),

        SizedBox(width: 12.w),

        Expanded(
          child: _buildToggleButton(
            'Italic',

            props['fontStyle'] == FontStyle.italic,

            Icons.format_italic_rounded,

            () => setState(() {
              props['fontStyle'] = (props['fontStyle'] == FontStyle.italic)
                  ? FontStyle.normal
                  : FontStyle.italic;
            }),
          ),
        ),

        SizedBox(width: 12.w),

        Expanded(
          child: _buildToggleButton(
            'Underline',

            props['decoration'] == TextDecoration.underline,

            Icons.format_underlined_rounded,

            () => setState(() {
              props['decoration'] =
                  (props['decoration'] == TextDecoration.underline)
                  ? TextDecoration.none
                  : TextDecoration.underline;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildFontSelectionSection(Map<String, dynamic> props) {
    final currentFont = props['fontFamily'] as String? ?? 'Roboto';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Row(
          children: [
            Icon(
              Icons.font_download_rounded,

              size: 20.sp,

              color: Colors.grey[600],
            ),

            SizedBox(width: 8.w),

            Text(
              'Font Family',

              style: TextStyle(
                fontSize: 16.sp,

                fontWeight: FontWeight.bold,

                color: Colors.grey[800],
              ),
            ),
          ],
        ),

        SizedBox(height: 12.h),

        GestureDetector(
          onTap: _showFontSelectionDialog,

          child: Container(
            width: double.infinity,

            padding: EdgeInsets.all(16.w),

            decoration: BoxDecoration(
              color: Colors.grey[50],

              borderRadius: BorderRadius.circular(12.r),

              border: Border.all(color: Colors.grey.shade200),
            ),

            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        currentFont,

                        style: TextStyle(
                          fontSize: 16.sp,

                          fontWeight: FontWeight.w600,

                          color: Colors.grey[800],

                          fontFamily: currentFont,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      Text(
                        'The quick brown fox jumps',

                        style: TextStyle(
                          fontSize: 12.sp,

                          color: Colors.grey[600],

                          fontFamily: currentFont,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: EdgeInsets.all(8.w),

                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,

                    borderRadius: BorderRadius.circular(8.r),
                  ),

                  child: Icon(
                    Icons.keyboard_arrow_right_rounded,

                    color: Colors.blue.shade600,

                    size: 20.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton(
    String label,

    bool isActive,

    IconData icon,

    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),

        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [Colors.blue.shade400, Colors.blue.shade600],
                )
              : null,

          color: isActive ? null : Colors.grey[50],

          borderRadius: BorderRadius.circular(16.r),

          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey.shade200,
          ),

          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),

                    blurRadius: 8,

                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),

        child: Icon(
          icon,

          color: isActive ? Colors.white : Colors.grey.shade600,

          size: 22.sp,
        ),
      ),
    );
  }

  Widget _buildToggleOption(
    String label,

    bool value,

    IconData icon,

    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Colors.grey[600]),

        SizedBox(width: 12.w),

        Text(
          label,

          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),

        const Spacer(),

        Switch.adaptive(
          value: value,

          onChanged: onChanged,

          activeColor: Colors.blue.shade400,
        ),
      ],
    );
  }

  Widget _buildImageOptions() {
    final props = selectedItem!.properties;

    return Column(
      children: [
        _buildOptionButton(
          'Edit Image',

          Icons.edit_rounded,

          Colors.purple.shade400,

          _editSelectedImage,
        ),

        SizedBox(height: 20.h),

        _buildOptionButton(
          'Remove Background',

          Icons.auto_fix_high_rounded,

          Colors.orange.shade400,

          _removeBackground,
        ),

        SizedBox(height: 16.h),

        _buildOptionButton(
          'Add Stroke',

          Icons.border_outer_rounded,

          Colors.purple.shade400,

          _showStrokeSettingsDialog,
        ),

        SizedBox(height: 20.h),

        _buildColorOption('Tint Color', 'tint', props),

        SizedBox(height: 16.h),

        _buildSliderOption(
          'Blur',

          (props['blur'] as double?) ?? 0.0,

          0.0,

          10.0,

          (value) => setState(() => props['blur'] = value),

          Icons.blur_on_rounded,
        ),

        SizedBox(height: 20.h),

        _buildOptionButton(
          'Replace Image',

          Icons.photo_library_rounded,

          Colors.blue.shade400,

          () {
            _pickImage(replace: true);
          },
        ),

        SizedBox(height: 20.h),

        _buildToggleOption(
          'Gradient',

          (props['hasGradient'] as bool?) ?? false,

          Icons.gradient_rounded,

          (value) => setState(() {
            final bool newVal = !((props['hasGradient'] as bool?) ?? false);
            props['hasGradient'] = newVal;
            if (newVal) {
              props['hasShadow'] = false;
            }

            // Initialize gradient colors if not present
            if (newVal &&
                (props['gradientColors'] == null ||
                    (props['gradientColors'] as List).isEmpty)) {
              props['gradientColors'] = [
                HiveColor.fromColor(Colors.blue),

                HiveColor.fromColor(Colors.purple),
              ];
            }
          }),
        ),

        if (props['hasGradient'] == true) ...[
          SizedBox(height: 16.h),

          _buildGradientPicker(props),
        ],

        SizedBox(height: 16.h),

        _buildSliderOption(
          'Shadow Opacity',

          (props['shadowOpacity'] as double?) ?? 0.6,

          0.0,

          1.0,

          (value) => setState(() => props['shadowOpacity'] = value),

          Icons.opacity_rounded,
        ),

        SizedBox(height: 20.h),

        _buildToggleOption(
          'Shadow',

          (props['hasShadow'] as bool?) ?? false,

          CupertinoIcons.moon_stars,

          (value) => setState(() => props['hasShadow'] = value),
        ),

        if (props['hasShadow'] == true) ...[
          SizedBox(height: 16.h),

          _buildColorOption('Shadow Color', 'shadowColor', props),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Blur',

            (props['shadowBlur'] as double?) ?? 8.0,

            0.0,

            40.0,

            (value) => setState(() => props['shadowBlur'] = value),

            Icons.blur_on_rounded,
          ),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Offset X',

            (props['shadowOffset'] as Offset?)?.dx ?? 4.0,

            -100.0,

            100.0,

            (v) => setState(() {
              final cur =
                  (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);

              props['shadowOffset'] = Offset(v, cur.dy);
            }),

            Icons.swap_horiz_rounded,
          ),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Offset Y',

            (props['shadowOffset'] as Offset?)?.dy ?? 4.0,

            -100.0,

            100.0,

            (v) => setState(() {
              final cur =
                  (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);

              props['shadowOffset'] = Offset(cur.dx, v);
            }),

            Icons.swap_vert_rounded,
          ),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Size',

            (props['shadowSize'] as double?) ?? 0.0,

            0.0,

            100.0,

            (v) => setState(() => props['shadowSize'] = v),

            Icons.zoom_out_map_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildStickerOptions() {
    final props = selectedItem!.properties;

    return Column(
      children: [
        _buildColorOption('Sticker Color', 'color', props),

        SizedBox(height: 20.h),

        _buildOptionButton(
          'Change Sticker',

          Icons.emoji_emotions_rounded,

          Colors.orange.shade400,

          () {},
        ),
      ],
    );
  }

  Widget _buildShapeOptions() {
    final props = selectedItem!.properties;

    return Column(
      children: [
        _buildColorOption('Fill Color', 'fillColor', props),

        SizedBox(height: 16.h),

        _buildColorOption('Stroke Color', 'strokeColor', props),

        SizedBox(height: 16.h),

        _buildSliderOption(
          'Stroke Width',

          (props['strokeWidth'] as double?) ?? 2.0,

          0.0,

          10.0,

          (v) => setState(() => props['strokeWidth'] = v),

          Icons.line_weight_rounded,
        ),

        SizedBox(height: 16.h),

        _buildSliderOption(
          'Width',

          (props['width'] as double?) ?? 100.0,

          20.0,

          500.0,

          (v) => setState(() => props['width'] = v),

          Icons.width_full_rounded,
        ),

        SizedBox(height: 16.h),

        _buildSliderOption(
          'Height',

          (props['height'] as double?) ?? 100.0,

          20.0,

          500.0,

          (v) => setState(() => props['height'] = v),

          Icons.height_rounded,
        ),

        SizedBox(height: 16.h),

        // Individual side length controls for rectangle/square shapes
        if ((props['shape'] as String?) == 'rectangle' ||
            (props['shape'] as String?) == 'square') ...[
          Text(
            'Individual Side Lengths',

            style: TextStyle(
              fontSize: 16.sp,

              fontWeight: FontWeight.w600,

              color: Colors.grey[700],
            ),
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildSliderOption(
                  'Top Side',

                  (props['topSide'] as double?) ?? 100.0,

                  20.0,

                  500.0,

                  (v) => setState(() => props['topSide'] = v),

                  Icons.keyboard_arrow_up_rounded,
                ),
              ),

              SizedBox(width: 8.w),

              Expanded(
                child: _buildSliderOption(
                  'Right Side',

                  (props['rightSide'] as double?) ?? 100.0,

                  20.0,

                  500.0,

                  (v) => setState(() => props['rightSide'] = v),

                  Icons.keyboard_arrow_right_rounded,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildSliderOption(
                  'Bottom Side',

                  (props['bottomSide'] as double?) ?? 100.0,

                  20.0,

                  500.0,

                  (v) => setState(() => props['bottomSide'] = v),

                  Icons.keyboard_arrow_down_rounded,
                ),
              ),

              SizedBox(width: 8.w),

              Expanded(
                child: _buildSliderOption(
                  'Left Side',

                  (props['leftSide'] as double?) ?? 100.0,

                  20.0,

                  500.0,

                  (v) => setState(() => props['leftSide'] = v),

                  Icons.keyboard_arrow_left_rounded,
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),
        ],

        _buildSliderOption(
          'Corner Radius',

          (props['cornerRadius'] as double?) ?? 12.0,

          0.0,

          50.0,

          (v) => setState(() {
            props['cornerRadius'] = v;

            // Clear individual corner radius values when using uniform radius

            props.remove('topRadius');

            props.remove('bottomRightRadius');

            props.remove('bottomLeftRadius');

            props.remove('topLeftRadius');

            props.remove('topRightRadius');
          }),

          Icons.rounded_corner_rounded,
        ),

        SizedBox(height: 16.h),

        // Individual corner radius controls for rectangle/square shapes
        if ((props['shape'] as String?) == 'rectangle' ||
            (props['shape'] as String?) == 'square') ...[
          Text(
            'Individual Corner Radius',

            style: TextStyle(
              fontSize: 16.sp,

              fontWeight: FontWeight.w600,

              color: Colors.grey[700],
            ),
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildSliderOption(
                  'Top Left',

                  (props['topLeftRadius'] as double?) ?? 0.0,

                  0.0,

                  50.0,

                  (v) => setState(() => props['topLeftRadius'] = v),

                  Icons.crop_square_rounded,
                ),
              ),

              SizedBox(width: 8.w),

              Expanded(
                child: _buildSliderOption(
                  'Top Right',

                  (props['topRightRadius'] as double?) ?? 0.0,

                  0.0,

                  50.0,

                  (v) => setState(() => props['topRightRadius'] = v),

                  Icons.crop_square_rounded,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildSliderOption(
                  'Bottom Left',

                  (props['bottomLeftRadius'] as double?) ?? 0.0,

                  0.0,

                  50.0,

                  (v) => setState(() => props['bottomLeftRadius'] = v),

                  Icons.crop_square_rounded,
                ),
              ),

              SizedBox(width: 8.w),

              Expanded(
                child: _buildSliderOption(
                  'Bottom Right',

                  (props['bottomRightRadius'] as double?) ?? 0.0,

                  0.0,

                  50.0,

                  (v) => setState(() => props['bottomRightRadius'] = v),

                  Icons.crop_square_rounded,
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),
        ],

        // Individual corner radius controls for triangle shapes
        if ((props['shape'] as String?) == 'triangle') ...[
          Text(
            'Triangle Corner Radius',

            style: TextStyle(
              fontSize: 16.sp,

              fontWeight: FontWeight.w600,

              color: Colors.grey[700],
            ),
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildSliderOption(
                  'Top Corner',

                  (props['topRadius'] as double?) ?? 0.0,

                  0.0,

                  50.0,

                  (v) => setState(() => props['topRadius'] = v),

                  Icons.keyboard_arrow_up_rounded,
                ),
              ),

              SizedBox(width: 8.w),

              Expanded(
                child: _buildSliderOption(
                  'Bottom Right',

                  (props['bottomRightRadius'] as double?) ?? 0.0,

                  0.0,

                  50.0,

                  (v) => setState(() => props['bottomRightRadius'] = v),

                  Icons.crop_square_rounded,
                ),
              ),
            ],
          ),

          SizedBox(height: 12.h),

          Row(
            children: [
              Expanded(
                child: _buildSliderOption(
                  'Bottom Left',

                  (props['bottomLeftRadius'] as double?) ?? 0.0,

                  0.0,

                  50.0,

                  (v) => setState(() => props['bottomLeftRadius'] = v),

                  Icons.crop_square_rounded,
                ),
              ),

              SizedBox(width: 8.w),

              Expanded(
                child: Container(), // Empty space for alignment
              ),
            ],
          ),

          SizedBox(height: 20.h),
        ],

        _buildToggleOption(
          'Gradient Fill',

          (props['hasGradient'] as bool?) ?? false,

          Icons.gradient_rounded,

          (value) => setState(() => props['hasGradient'] = value),
        ),

        SizedBox(height: 16.h),

        _buildOptionButton(
          'Pick Image Inside Shape',

          Icons.photo_library_rounded,

          Colors.blue.shade400,

          _pickShapeImage,
        ),

        if (props['image'] != null) ...[
          SizedBox(height: 12.h),

          _buildOptionButton(
            'Clear Image',

            Icons.delete_sweep_rounded,

            Colors.red.shade400,

            () => setState(() => props['image'] = null),
          ),
        ],

        if (props['hasGradient'] == true) ...[
          SizedBox(height: 16.h),

          _buildGradientPicker(props),
        ],

        SizedBox(height: 16.h),

        _buildToggleOption(
          'Shadow',

          (props['hasShadow'] as bool?) ?? false,

          CupertinoIcons.moon_stars,

          (value) => setState(() => props['hasShadow'] = value),
        ),

        if (props['hasShadow'] == true) ...[
          SizedBox(height: 16.h),

          _buildColorOption('Shadow Color', 'shadowColor', props),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Blur',

            (props['shadowBlur'] as double?) ?? 8.0,

            0.0,

            40.0,

            (v) => setState(() => props['shadowBlur'] = v),

            Icons.blur_on_rounded,
          ),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Opacity',

            (props['shadowOpacity'] as double?) ?? 0.6,

            0.0,

            1.0,

            (v) => setState(() => props['shadowOpacity'] = v),

            Icons.opacity_rounded,
          ),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Offset X',

            (props['shadowOffset'] as Offset?)?.dx ?? 4.0,

            -100.0,

            100.0,

            (v) => setState(() {
              final Offset cur =
                  (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);

              props['shadowOffset'] = Offset(v, cur.dy);
            }),

            Icons.swap_horiz_rounded,
          ),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Offset Y',

            (props['shadowOffset'] as Offset?)?.dy ?? 4.0,

            -100.0,

            100.0,

            (v) => setState(() {
              final Offset cur =
                  (props['shadowOffset'] as Offset?) ?? const Offset(4, 4);

              props['shadowOffset'] = Offset(cur.dx, v);
            }),

            Icons.swap_vert_rounded,
          ),

          SizedBox(height: 16.h),

          _buildSliderOption(
            'Shadow Size',

            (props['shadowSize'] as double?) ?? 0.0,

            0.0,

            100.0,

            (v) => setState(() => props['shadowSize'] = v),

            Icons.zoom_out_map_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildColorOption(
    String label,

    String property,

    Map<String, dynamic> props,
  ) {
    return Row(
      children: [
        Icon(Icons.palette_rounded, size: 20.sp, color: Colors.grey[600]),

        SizedBox(width: 12.w),

        Text(
          label,

          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
        ),

        const Spacer(),

        GestureDetector(
          onTap: () => _showColorPicker(property),

          child: Container(
            width: 44.w,

            height: 44.h,

            decoration: BoxDecoration(
              color: (props[property] is HiveColor)
                  ? (props[property] as HiveColor).toColor()
                  : (props[property] is int)
                  ? HiveColor(props[property] as int).toColor()
                  : (props[property] as Color?) ?? Colors.blue,

              borderRadius: BorderRadius.circular(12.r),

              border: Border.all(color: Colors.grey.shade300, width: 2),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),

                  blurRadius: 8,

                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionButton(
    String label,

    IconData icon,

    Color color,

    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),

        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),

          borderRadius: BorderRadius.circular(16.r),

          border: Border.all(color: color.withOpacity(0.3)),

          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),

              blurRadius: 8,

              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),

              decoration: BoxDecoration(
                color: color.withOpacity(0.15),

                borderRadius: BorderRadius.circular(12.r),
              ),

              child: Icon(icon, size: 20.sp, color: color),
            ),

            SizedBox(width: 16.w),

            Text(
              label,

              style: TextStyle(
                fontSize: 16.sp,

                fontWeight: FontWeight.w600,

                color: color.withOpacity(0.8),
              ),
            ),

            const Spacer(),

            Icon(
              Icons.arrow_forward_ios_rounded,

              size: 16.sp,

              color: color.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderOption(
    String label,

    double value,

    double min,

    double max,

    ValueChanged<double> onChanged,

    IconData icon,
  ) {
    return EnhancedSlider(
      label: label,
      value: value,
      min: min,
      max: max,
      onChanged: onChanged,
      icon: icon,
      isMini: false,
      step: 0.05, // 5% of the range
    );
  }

  void _showColorPicker(String property, {bool isGradient = false}) {
    final predefinedColors = <Color>[
      Colors.transparent, // Add transparent as first option
      Colors.black,

      Colors.white,

      Colors.redAccent,

      Colors.blueAccent,

      Colors.greenAccent,

      Colors.orangeAccent,

      Colors.purpleAccent,

      Colors.tealAccent,

      Colors.pinkAccent,

      Colors.indigoAccent,

      Colors.amberAccent,

      Colors.cyanAccent,
    ];

    Color _selectedColorInPicker = isGradient
        ? Colors.blue
        : (recentColors.isNotEmpty ? recentColors.last : Colors.black);

    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      isScrollControlled: true,

      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return Container(
            height: 280.h,

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32.r),

                topRight: Radius.circular(32.r),
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),

                  blurRadius: 20,

                  offset: const Offset(0, -8),
                ),
              ],
            ),

            child: Column(
              children: [
                Container(
                  width: 60.w,

                  height: 6.h,

                  margin: EdgeInsets.symmetric(vertical: 16.h),

                  decoration: BoxDecoration(
                    color: Colors.grey[300],

                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),

                  child: Row(
                    children: [
                      Icon(
                        Icons.palette_rounded,

                        color: Colors.blue.shade400,

                        size: 24.sp,
                      ),

                      SizedBox(width: 12.w),

                      Text(
                        'Choose Color',

                        style: TextStyle(
                          fontSize: 20.sp,

                          fontWeight: FontWeight.bold,

                          color: Colors.grey[800],
                        ),
                      ),

                      SizedBox(width: 12.w),

                      Container(
                        width: 48.w,

                        height: 48.h,

                        decoration: BoxDecoration(
                          color: _selectedColorInPicker,

                          shape: BoxShape.circle,

                          border: Border.all(
                            color: Colors.grey.shade300,

                            width: 2,
                          ),
                        ),
                      ),

                      const Spacer(),

                      IconButton(
                        icon: Icon(
                          Icons.add_circle,

                          color: Colors.green,

                          size: 24.sp,
                        ),

                        onPressed: () async {
                          // Show advanced color picker in a new modal bottom sheet

                          final pickedColor = await showColorPickerBottomSheet(
                            context: context,

                            initialColor: _selectedColorInPicker,

                            onPreview: (color) {
                              if (selectedItem == null) return;

                              // Live update without committing to history

                              setState(() {
                                if (isGradient) {
                                  final List<Color> currentGradient =
                                      _getDisplayGradientColors();

                                  final Color first = currentGradient.first;

                                  final Color last = currentGradient.last;

                                  final Map<String, dynamic> newProperties =
                                      Map.from(selectedItem!.properties);

                                  if (property == 'gradientColor1') {
                                    newProperties['gradientColors'] = [
                                      HiveColor.fromColor(color),

                                      HiveColor.fromColor(last),
                                    ];
                                  } else if (property == 'gradientColor2') {
                                    newProperties['gradientColors'] = [
                                      HiveColor.fromColor(first),

                                      HiveColor.fromColor(color),
                                    ];
                                  } else {
                                    // Fallback: replace first color

                                    newProperties['gradientColors'] = [
                                      HiveColor.fromColor(color),

                                      HiveColor.fromColor(last),
                                    ];
                                  }

                                  selectedItem = selectedItem!.copyWith(
                                    properties: newProperties,
                                  );
                                } else {
                                  final Map<String, dynamic> newProperties =
                                      Map.from(selectedItem!.properties);

                                  newProperties[property] = HiveColor.fromColor(
                                    color,
                                  );

                                  selectedItem = selectedItem!.copyWith(
                                    properties: newProperties,
                                  );
                                }
                              });
                            },
                          );

                          if (pickedColor != null) {
                            // Update state and save

                            setState(() {
                              _selectedColorInPicker = pickedColor;

                              if (!recentColors.contains(pickedColor)) {
                                recentColors.add(
                                  pickedColor,
                                ); // or however you manage recentColors
                              }
                            });

                            _selectColor(
                              property,

                              pickedColor,

                              isGradient: isGradient,
                            );

                            Navigator.pop(
                              context,
                            ); // Close the original bottom sheet
                          }
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24.h),

                if (recentColors.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),

                    child: Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        'RECENT',

                        style: TextStyle(
                          fontSize: 12.sp,

                          fontWeight: FontWeight.bold,

                          color: Colors.grey[600],

                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  SizedBox(
                    height: 50.h,

                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,

                      padding: EdgeInsets.symmetric(horizontal: 24.w),

                      itemCount: recentColors.length,

                      itemBuilder: (context, index) {
                        final color = recentColors[index];

                        return Padding(
                          padding: EdgeInsets.only(right: 12.w),

                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedColorInPicker = color;
                              });

                              _selectColor(
                                property,

                                color,

                                isGradient: isGradient,
                              );

                              Navigator.pop(context);
                            },

                            child: Container(
                              width: 50.h,

                              height: 50.h,

                              decoration: BoxDecoration(
                                color: color == Colors.transparent
                                    ? Colors.white
                                    : color,
                                borderRadius: BorderRadius.circular(12.r),

                                border: Border.all(
                                  color: Colors.grey.shade300,

                                  width: 2,
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),

                                    blurRadius: 4,

                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),

                              child: color == Colors.transparent
                                  ? Stack(
                                      children: [
                                        CustomPaint(
                                          painter: CheckerboardPainter(),
                                          size: Size(50.h, 50.h),
                                        ),
                                        Center(
                                          child: Container(
                                            width: 30.w,
                                            height: 3.h,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(1.5.r),
                                            ),
                                            transform: Matrix4.rotationZ(
                                              0.785398,
                                            ), // 45 degrees
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 20.h),
                ],

                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),

                    child: BlockPicker(
                      pickerColor: _selectedColorInPicker,

                      onColorChanged: (color) {
                        setState(() {
                          _selectedColorInPicker = color;
                        });
                      },

                      availableColors: predefinedColors,

                      layoutBuilder: (context, colors, child) {
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,

                                crossAxisSpacing: 16.w,

                                mainAxisSpacing: 16.h,
                              ),

                          itemCount: colors.length,

                          itemBuilder: (context, index) {
                            return child(colors[index]);
                          },
                        );
                      },

                      itemBuilder: (color, isCurrentColor, changeColor) {
                        return GestureDetector(
                          onTap: () {
                            changeColor();

                            _selectColor(
                              property,

                              color,

                              isGradient: isGradient,
                            );

                            Navigator.pop(context);
                          },

                          child: Container(
                            decoration: BoxDecoration(
                              color: color == Colors.transparent
                                  ? Colors.white
                                  : color,
                              borderRadius: BorderRadius.circular(16.r),

                              border: Border.all(
                                color: Colors.grey.shade300,

                                width: 2,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),

                                  blurRadius: 8,

                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),

                            child: color == Colors.transparent
                                ? Stack(
                                    children: [
                                      CustomPaint(
                                        painter: CheckerboardPainter(),
                                        size: Size(50.w, 50.h),
                                      ),
                                      Center(
                                        child: Container(
                                          width: 30.w,
                                          height: 3.h,
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(
                                              1.5.r,
                                            ),
                                          ),
                                          transform: Matrix4.rotationZ(
                                            0.785398,
                                          ), // 45 degrees
                                        ),
                                      ),
                                    ],
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Color?> showColorPickerBottomSheet({
    required BuildContext context,

    required Color initialColor,

    ValueChanged<Color>? onPreview,
  }) async {
    Color currentColor = initialColor;

    return await showModalBottomSheet<Color>(
      context: context,

      isScrollControlled: true,

      backgroundColor: Colors.transparent,

      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,

          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),

                topRight: Radius.circular(32),
              ),
            ),

            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),

              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 60,

                    height: 6,

                    decoration: BoxDecoration(
                      color: Colors.grey[300],

                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  SizedBox(height: 20),

                  Text(
                    'Pick a Color',

                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 20),

                  // Advanced Color Picker
                  Expanded(
                    child: ColorPicker(
                      pickerColor: currentColor,

                      onColorChanged: (Color color) {
                        currentColor = color;

                        if (onPreview != null) {
                          onPreview(color);
                        }
                      },

                      colorPickerWidth: 300,

                      pickerAreaHeightPercent: 0.7,

                      showLabel: true,

                      displayThumbColor: true,

                      paletteType: PaletteType.hsv,
                    ),
                  ),

                  SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, currentColor);
                    },

                    child: Text('Select'),
                  ),

                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage({bool replace = false}) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (picked == null) return;

      // Decode intrinsic dimensions to preserve original aspect ratio

      final File file = File(picked.path);

      final Uint8List bytes = await file.readAsBytes();

      final ui.Image decoded = await decodeImageFromList(bytes);

      final double intrinsicW = decoded.width.toDouble();

      final double intrinsicH = decoded.height.toDouble();

      // Set an initial displayed size that fits within a reasonable box while keeping ratio

      const double maxEdge = 240.0; // logical px baseline before user scaling

      double displayW = intrinsicW;

      double displayH = intrinsicH;

      if (intrinsicW > intrinsicH && intrinsicW > maxEdge) {
        displayW = maxEdge;

        displayH = maxEdge * (intrinsicH / intrinsicW);
      } else if (intrinsicH >= intrinsicW && intrinsicH > maxEdge) {
        displayH = maxEdge;

        displayW = maxEdge * (intrinsicW / intrinsicH);
      }

      if (replace &&
          selectedItem != null &&
          selectedItem!.type == CanvasItemType.image) {
        final previous = selectedItem!.copyWith();

        setState(() {
          selectedItem!.properties['filePath'] = picked.path;

          selectedItem!.properties['intrinsicWidth'] = intrinsicW;

          selectedItem!.properties['intrinsicHeight'] = intrinsicH;

          selectedItem!.properties['displayWidth'] = displayW;

          selectedItem!.properties['displayHeight'] = displayH;
        });

        _addAction(
          CanvasAction(
            type: 'modify',

            item: selectedItem,

            previousState: previous,

            timestamp: DateTime.now(),
          ),
        );
      } else {
        _addCanvasItem(
          CanvasItemType.image,

          properties: {
            'filePath': picked.path,

            'tint': Colors.transparent,

            'blur': 0.0,

            'intrinsicWidth': intrinsicW,

            'intrinsicHeight': intrinsicH,

            'displayWidth': displayW,

            'displayHeight': displayH,
          },
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

  Future<void> _pickShapeImage() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (picked == null ||
          selectedItem == null ||
          selectedItem?.type != CanvasItemType.shape)
        return;

      final Uint8List bytes = await File(picked.path).readAsBytes();

      final ui.Codec codec = await ui.instantiateImageCodec(bytes);

      final ui.FrameInfo frame = await codec.getNextFrame();

      final ui.Image image = frame.image;

      final previous = selectedItem!.copyWith();

      setState(() {
        // Store both the ui.Image object and the file path

        selectedItem!.properties['image'] = image;

        selectedItem!.properties['imagePath'] = picked.path;

        // Also store base64 so exports are portable across devices
        try {
          final String base64Str = base64Encode(bytes);
          selectedItem!.properties['imageBase64'] = base64Str;
          // Mirror under nested shapeProperties when available
          if (selectedItem!.properties['shapeProperties']
              is Map<String, dynamic>) {
            final Map<String, dynamic> sp = Map<String, dynamic>.from(
              selectedItem!.properties['shapeProperties'] as Map,
            );
            sp['imageBase64'] = base64Str;
            sp['imagePath'] = picked.path;
            selectedItem!.properties['shapeProperties'] = sp;
          }
        } catch (_) {}

        // Disable gradient when using image fill

        selectedItem!.properties['hasGradient'] = false;
      });

      _addAction(
        CanvasAction(
          type: 'modify',

          item: selectedItem,

          previousState: previous,

          timestamp: DateTime.now(),
        ),
      );

      // Trigger auto-save if enabled

      if (userPreferences.autoSave) {
        _saveProject();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load image for shape')),
      );
    }
  }

  void _selectColor(String property, Color color, {bool isGradient = false}) {
    if (selectedItem == null) return;

    final previous = selectedItem!.copyWith();

    setState(() {
      if (selectedItem != null) {
        if (isGradient) {
          final currentGradient =
              (selectedItem!.properties['gradientColors'] as List<dynamic>?)
                  ?.map((e) => (e as HiveColor).toColor())
                  .toList() ??
              [Colors.blue, Colors.purple];

          final Map<String, dynamic> newProperties = Map.from(
            selectedItem!.properties,
          );

          if (property == 'gradientColor1') {
            newProperties['gradientColors'] = [
              HiveColor.fromColor(color),

              HiveColor.fromColor(currentGradient.last),
            ];
          } else if (property == 'gradientColor2') {
            newProperties['gradientColors'] = [
              HiveColor.fromColor(currentGradient.first),

              HiveColor.fromColor(color),
            ];
          }

          selectedItem = selectedItem!.copyWith(properties: newProperties);
        } else {
          final Map<String, dynamic> newProperties = Map.from(
            selectedItem!.properties,
          );

          newProperties[property] = HiveColor.fromColor(color);

          selectedItem = selectedItem!.copyWith(properties: newProperties);
        }

        if (!recentColors.contains(color)) {
          recentColors.insert(0, color);

          if (recentColors.length > 8) {
            recentColors.removeLast();
          }

          userPreferences.recentColors = recentColors
              .map((e) => HiveColor.fromColor(e))
              .toList();

          _userPreferencesBox.put('user_prefs_id', userPreferences);
        }
      }
    });

    // Add to action history for undo/redo

    if (selectedItem != null) {
      _addAction(
        CanvasAction(
          type: 'modify',

          item: selectedItem,

          previousState: previous,

          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Widget _buildActionBar() {
    return ActionBar(
      canUndo: currentActionIndex >= 0,
      canRedo: currentActionIndex < actionHistory.length - 1,
      onUndo: _undo,
      onRedo: _redo,
      hasItems: canvasItems.isNotEmpty,
      onShowLayers: _showLayerPanel,
      onExport: _exportPoster,
      onBack: () => Navigator.pop(context),
      isAutoSaving: _isAutoSaving,
    );
  }

  void _showLayerPanel() {
    showModalBottomSheet(
      context: context,

      backgroundColor: Colors.transparent,

      isScrollControlled: true,

      builder: (context) => Container(
        height: 400.h,

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32.r),

            topRight: Radius.circular(32.r),
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),

              blurRadius: 20,

              offset: const Offset(0, -8),
            ),
          ],
        ),

        child: Column(
          children: [
            Container(
              width: 60.w,

              height: 6.h,

              margin: EdgeInsets.symmetric(vertical: 16.h),

              decoration: BoxDecoration(
                color: Colors.grey[300],

                borderRadius: BorderRadius.circular(3.r),
              ),
            ),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),

              child: Row(
                children: [
                  Icon(
                    Icons.layers_rounded,

                    color: Colors.blue.shade400,

                    size: 24.sp,
                  ),

                  SizedBox(width: 12.w),

                  Text(
                    'Layers',

                    style: TextStyle(
                      fontSize: 20.sp,

                      fontWeight: FontWeight.bold,

                      color: Colors.grey[800],
                    ),
                  ),

                  const Spacer(),

                  Text(
                    '${canvasItems.length} items',

                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),

                child: _buildReorderableLayersList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReorderableLayersList() {
    // Top-most first list

    final List<CanvasItem> layersTopFirst = [...canvasItems]
      ..sort((a, b) => b.layerIndex.compareTo(a.layerIndex));

    return ReorderableListView.builder(
      proxyDecorator: (child, index, animation) =>
          Material(color: Colors.transparent, child: child),

      itemCount: layersTopFirst.length,

      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex -= 1;

          final item = layersTopFirst.removeAt(oldIndex);

          layersTopFirst.insert(newIndex, item);

          // After reordering, recompute layerIndex where index 0 is top-most

          final int n = layersTopFirst.length;

          for (int i = 0; i < n; i++) {
            layersTopFirst[i].layerIndex = n - 1 - i;
          }

          // Update the original canvasItems list with the new layer indices

          for (final item in layersTopFirst) {
            final originalIndex = canvasItems.indexWhere(
              (it) => it.id == item.id,
            );

            if (originalIndex != -1) {
              canvasItems[originalIndex].layerIndex = item.layerIndex;
            }
          }
        });
      },

      itemBuilder: (context, index) {
        final item = layersTopFirst[index];

        final isSelected = selectedItem == item;

        return Container(
          key: ValueKey(item.id),

          margin: EdgeInsets.only(bottom: 12.h),

          padding: EdgeInsets.all(16.w),

          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [Colors.blue.shade50!, Colors.blue.shade100!],
                  )
                : null,

            color: isSelected ? null : Colors.grey[50],

            borderRadius: BorderRadius.circular(16.r),

            border: Border.all(
              color: isSelected ? Colors.blue.shade200 : Colors.grey.shade200,

              width: isSelected ? 2 : 1,
            ),
          ),

          child: Row(
            children: [
              Icon(
                _getItemTypeIcon(item.type),

                color: isSelected ? Colors.blue.shade400 : Colors.grey.shade600,

                size: 24.sp,
              ),

              SizedBox(width: 16.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Text(
                      '${item.type.name.toUpperCase()} Layer',

                      style: TextStyle(
                        fontSize: 14.sp,

                        fontWeight: FontWeight.w600,

                        color: isSelected
                            ? Colors.blue.shade700
                            : Colors.grey[800],
                      ),
                    ),

                    Text(
                      'Layer ${item.layerIndex + 1}',

                      style: TextStyle(
                        fontSize: 12.sp,

                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              Row(
                mainAxisSize: MainAxisSize.min,

                children: [
                  IconButton(
                    onPressed: () => setState(() {
                      item.isVisible = !item.isVisible;
                    }),

                    icon: Icon(
                      item.isVisible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,

                      color: Colors.grey[600],

                      size: 20.sp,
                    ),
                  ),

                  IconButton(
                    onPressed: () {
                      _selectItem(item);

                      Navigator.pop(context);
                    },

                    icon: Icon(
                      Icons.edit_rounded,

                      color: Colors.blue.shade400,

                      size: 20.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportPoster() async {
    // Show export options dialog
    final export_dialog.ExportOptions? options =
        await showDialog<export_dialog.ExportOptions>(
          context: context,
          builder: (context) => const export_dialog.ExportDialog(),
        );

    if (options == null) return;

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildProgressDialog(options),
    );

    try {
      if (options.type == export_dialog.ExportType.image) {
        await _exportImage(options);
      } else {
        await _exportProject(options);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog
      _showErrorSnackBar('Export failed: ${e.toString()}');
    }
  }

  Widget _buildProgressDialog(export_dialog.ExportOptions options) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                options.type == export_dialog.ExportType.image
                    ? Colors.blue[600]!
                    : Colors.purple[600]!,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              options.type == export_dialog.ExportType.image
                  ? 'Exporting Image...'
                  : 'Exporting Project...',
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Please wait while we process your ${options.type == export_dialog.ExportType.image ? 'image' : 'project'}',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportImage(export_dialog.ExportOptions options) async {
    try {
      // Persist the latest edits before exporting
      _saveProject(showIndicator: false, saveThumbnail: false);
      // Export the image
      final String? filePath = await ExportManager.exportImage(
        _canvasRepaintKey,
        options,
      );

      if (filePath == null) {
        throw Exception('Failed to export image');
      }

      // Save to gallery
      final bool savedToGallery = await ExportManager.saveToGallery(filePath);

      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      if (savedToGallery) {
        _showSuccessSnackBar('Image exported and saved to gallery!');
      } else {
        // If gallery save failed, offer to share
        await ExportManager.shareImage(filePath);
        _showSuccessSnackBar('Image exported and shared!');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog
      _showErrorSnackBar('Failed to export image: ${e.toString()}');
    }
  }

  Future<void> _exportProject(export_dialog.ExportOptions options) async {
    try {
      // Persist the latest edits before exporting
      _saveProject(showIndicator: false, saveThumbnail: false);
      print('Starting project export...');

      // Get current project data
      final PosterProject project = _getCurrentProject(options);
      print('Project data prepared: ${project.canvasItems.length} items');

      // Export the project
      print('Calling ExportManager.exportProject...');
      final String? filePath = await ExportManager.exportProject(project);

      if (filePath == null) {
        print('ExportManager.exportProject returned null');
        throw Exception('Failed to export project');
      }

      print('Project exported successfully to: $filePath');

      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      // Share the project file
      print('Sharing project file...');
      await Share.shareXFiles([XFile(filePath)], text: 'My LamLayers Project');
      _showSuccessSnackBar('Project exported and shared!');
    } catch (e) {
      print('Error in _exportProject: $e');
      print('Stack trace: ${StackTrace.current}');
      if (!mounted) return;
      Navigator.of(context).pop(); // Close progress dialog
      _showErrorSnackBar('Failed to export project: ${e.toString()}');
    }
  }

  PosterProject _getCurrentProject(export_dialog.ExportOptions options) {
    // Convert current canvas items to HiveCanvasItem format
    final List<HiveCanvasItem> hiveItems = canvasItems.map((item) {
      return HiveCanvasItem(
        id: item.id,
        type: _convertCanvasItemType(item.type),
        position: item.position,
        scale: item.scale,
        rotation: item.rotation,
        opacity: item.opacity,
        layerIndex: item.layerIndex,
        isVisible: item.isVisible,
        isLocked: item.isLocked,
        properties: _convertProperties(item),
        createdAt: item.createdAt,
        lastModified: item.lastModified,
        groupId: item.groupId,
      );
    }).toList();

    // Use current project data if available, otherwise create new
    final currentProject = _currentProject;
    if (currentProject != null) {
      return currentProject.copyWith(
        canvasItems: hiveItems,
        settings: currentProject.settings.copyWith(
          exportSettings: ExportSettings(
            format: _convertExportFormat(options.format),
            quality: _convertExportQuality(options.clarity),
          ),
        ),
      );
    } else {
      return PosterProject(
        id:
            widget.projectId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Current Project',
        description: 'Exported project',
        createdAt: DateTime.now(),
        lastModified: DateTime.now(),
        canvasItems: hiveItems,
        settings: ProjectSettings(
          exportSettings: ExportSettings(
            format: _convertExportFormat(options.format),
            quality: _convertExportQuality(options.clarity),
          ),
        ),
        canvasWidth: widget.initialCanvasWidth ?? 1080,
        canvasHeight: widget.initialCanvasHeight ?? 1920,
        canvasBackgroundColor: const HiveColor(0xFFFFFFFF),
        backgroundImagePath: widget.initialBackgroundImagePath,
      );
    }
  }

  HiveCanvasItemType _convertCanvasItemType(CanvasItemType type) {
    switch (type) {
      case CanvasItemType.text:
        return HiveCanvasItemType.text;
      case CanvasItemType.image:
        return HiveCanvasItemType.image;
      case CanvasItemType.sticker:
        return HiveCanvasItemType.sticker;
      case CanvasItemType.shape:
        return HiveCanvasItemType.shape;
      case CanvasItemType.drawing:
        return HiveCanvasItemType.drawing;
    }
  }

  Map<String, dynamic> _convertProperties(CanvasItem item) {
    try {
      print('Converting properties for item ${item.id} of type ${item.type}');
      // Build a fresh properties map to avoid mutating during iteration
      final Map<String, dynamic> hiveProperties = <String, dynamic>{};
      item.properties.forEach((key, value) {
        if (value is ui.Image) {
          // Skip non-serializable runtime image objects
          return;
        }
        if (value is Color) {
          hiveProperties[key] = HiveColor.fromColor(value);
          return;
        }
        if (value is Offset) {
          hiveProperties[key] = {'dx': value.dx, 'dy': value.dy};
          return;
        }
        if (value is List<Color>) {
          hiveProperties[key] = value
              .map((color) => HiveColor.fromColor(color))
              .toList();
          return;
        }
        // Pass through all other values as-is
        hiveProperties[key] = value;
      });

      // Handle image-specific properties
      if (item.type == CanvasItemType.image) {
        // Ensure imageProperties is properly structured
        final String? filePath = item.properties['filePath'] as String?;
        if (filePath != null && filePath.isNotEmpty) {
          print('Processing image properties for file: $filePath');
          hiveProperties['imageProperties'] = HiveImageProperties(
            filePath: filePath,
            tint: (item.properties['tint'] is HiveColor)
                ? item.properties['tint'] as HiveColor
                : HiveColor.fromColor(
                    item.properties['tint'] as Color? ?? Colors.transparent,
                  ),
            blur: (item.properties['blur'] as double?) ?? 0.0,
            hasGradient: (item.properties['hasGradient'] as bool?) ?? false,
            gradientColors:
                (item.properties['gradientColors'] as List<dynamic>?)
                    ?.map(
                      (e) =>
                          e is HiveColor ? e : HiveColor.fromColor(e as Color),
                    )
                    .toList() ??
                [],
            gradientAngle: (item.properties['gradientAngle'] as double?) ?? 0.0,
            hasShadow: (item.properties['hasShadow'] as bool?) ?? false,
            shadowColor: (item.properties['shadowColor'] is HiveColor)
                ? item.properties['shadowColor'] as HiveColor
                : HiveColor.fromColor(
                    item.properties['shadowColor'] as Color? ?? Colors.black54,
                  ),
            shadowOffset:
                item.properties['shadowOffset'] as Offset? ??
                const Offset(8, 8),
            shadowBlur: (item.properties['shadowBlur'] as double?) ?? 8.0,
            shadowOpacity: (item.properties['shadowOpacity'] as double?) ?? 0.6,
            displayWidth: (item.properties['displayWidth'] as double?),
            displayHeight: (item.properties['displayHeight'] as double?),
          );
        }
      }

      // Handle text-specific properties
      if (item.type == CanvasItemType.text) {
        print('Processing text properties');
        hiveProperties['textProperties'] = HiveTextProperties(
          text: (item.properties['text'] as String?) ?? 'Sample Text',
          fontSize: (item.properties['fontSize'] as double?) ?? 24.0,
          color: (item.properties['color'] is HiveColor)
              ? item.properties['color'] as HiveColor
              : HiveColor.fromColor(
                  item.properties['color'] as Color? ?? Colors.black,
                ),
          fontWeight: (item.properties['fontWeight'] is FontWeight)
              ? item.properties['fontWeight'] as FontWeight
              : FontWeight.values[(item.properties['fontWeight'] as int?) ?? 0],
          fontStyle: (item.properties['fontStyle'] is FontStyle)
              ? item.properties['fontStyle'] as FontStyle
              : FontStyle.values[(item.properties['fontStyle'] as int?) ?? 0],
          textAlign: (item.properties['textAlign'] is TextAlign)
              ? item.properties['textAlign'] as TextAlign
              : TextAlign.values[(item.properties['textAlign'] as int?) ?? 0],
          hasGradient: (item.properties['hasGradient'] as bool?) ?? false,
          gradientColors:
              (item.properties['gradientColors'] as List<dynamic>?)
                  ?.map(
                    (e) => e is HiveColor ? e : HiveColor.fromColor(e as Color),
                  )
                  .toList() ??
              [],
          gradientAngle: (item.properties['gradientAngle'] as double?) ?? 0.0,
          decoration: (item.properties['decoration'] as int?) ?? 0,
          letterSpacing: (item.properties['letterSpacing'] as double?) ?? 0.0,
          hasShadow: (item.properties['hasShadow'] as bool?) ?? false,
          shadowColor: (item.properties['shadowColor'] is HiveColor)
              ? item.properties['shadowColor'] as HiveColor
              : HiveColor.fromColor(
                  item.properties['shadowColor'] as Color? ?? Colors.black54,
                ),
          shadowOffset:
              item.properties['shadowOffset'] as Offset? ?? const Offset(4, 4),
          shadowBlur: (item.properties['shadowBlur'] as double?) ?? 4.0,
          shadowOpacity: (item.properties['shadowOpacity'] as double?) ?? 0.6,
          fontFamily: (item.properties['fontFamily'] as String?),
        );
      }

      // Handle shape-specific color/stroke normalization
      if (item.type == CanvasItemType.shape) {
        // Ensure colors are HiveColor for export
        final dynamic rawFill = item.properties['fillColor'];
        if (rawFill is Color) {
          hiveProperties['fillColor'] = HiveColor.fromColor(rawFill);
        }
        final dynamic rawStroke = item.properties['strokeColor'];
        if (rawStroke is Color) {
          hiveProperties['strokeColor'] = HiveColor.fromColor(rawStroke);
        }
        // Preserve strokeWidth if present
        if (item.properties.containsKey('strokeWidth')) {
          hiveProperties['strokeWidth'] = item.properties['strokeWidth'];
        }
      }

      // Ensure shape image base64 is preserved if present
      if (item.type == CanvasItemType.shape) {
        // If nested shapeProperties exists, mirror base64 to top-level for exporter compatibility
        if (hiveProperties['shapeProperties'] is Map<String, dynamic>) {
          final Map<String, dynamic> sp = Map<String, dynamic>.from(
            hiveProperties['shapeProperties'] as Map,
          );
          final String? nestedB64 = sp['imageBase64'] as String?;
          if (nestedB64 != null && nestedB64.isNotEmpty) {
            hiveProperties['imageBase64'] = nestedB64;
          }
        }
      }

      print('Properties conversion completed for item ${item.id}');
      return hiveProperties;
    } catch (e) {
      print('Error converting properties for item ${item.id}: $e');
      print('Stack trace: ${StackTrace.current}');
      // Return a basic properties map to avoid breaking the export
      return {
        'error': 'Failed to convert properties: $e',
        'originalProperties': item.properties.toString(),
      };
    }
  }

  hive_model.ExportFormat _convertExportFormat(
    export_dialog.ExportFormat format,
  ) {
    switch (format) {
      case export_dialog.ExportFormat.png:
        return hive_model.ExportFormat.png;
      case export_dialog.ExportFormat.jpg:
        return hive_model.ExportFormat.jpg;
    }
  }

  hive_model.ExportQuality _convertExportQuality(
    export_dialog.ExportClarity clarity,
  ) {
    switch (clarity) {
      case export_dialog.ExportClarity.high:
        return hive_model.ExportQuality.high;
      case export_dialog.ExportClarity.medium:
        return hive_model.ExportQuality.medium;
      case export_dialog.ExportClarity.low:
        return hive_model.ExportQuality.low;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _navigateToPixabayImages() async {
    final PixabayImage? selectedImage = await Navigator.push(
      context,

      MaterialPageRoute(builder: (context) => PixabayImagesPage()),
    );

    if (selectedImage != null) {
      _addCanvasItem(
        CanvasItemType.image,

        properties: {
          'imageUrl':
              selectedImage.webformatURL, // Use imageUrl for network images

          'tint': Colors.transparent,

          'blur': 0.0,

          'intrinsicWidth': selectedImage.views
              .toDouble(), // Using views as a placeholder for intrinsic width

          'intrinsicHeight': selectedImage.downloads
              .toDouble(), // Using downloads as a placeholder for intrinsic height

          'displayWidth': 240.0,

          'displayHeight':
              240.0 * (selectedImage.downloads / selectedImage.views),
        },
      );
    }
  }

  List<Color> _getDisplayGradientColors() {
    final dynamic rawGradientColors =
        selectedItem!.properties['gradientColors'];

    if (rawGradientColors is List) {
      final List<Color> convertedColors = rawGradientColors
          .map((e) {
            if (e is HiveColor) return e.toColor();

            if (e is Color) return e;

            if (e is int) return HiveColor(e).toColor();

            return Colors.transparent;
          })
          .whereType<Color>()
          .toList();

      if (convertedColors.isNotEmpty) {
        if (convertedColors.length == 1) {
          return [convertedColors.first, convertedColors.first];
        }

        return convertedColors;
      }
    }

    return [Colors.lightBlue, Colors.blueAccent];
  }

  Future<void> _editSelectedImage() async {
    if (selectedItem == null || selectedItem!.type != CanvasItemType.image)
      return;

    try {
      final String? filePath = selectedItem!.properties['filePath'] as String?;

      final String? imageUrl = selectedItem!.properties['imageUrl'] as String?;

      Uint8List? imageBytes;

      // Get image bytes based on source

      if (filePath != null) {
        imageBytes = await File(filePath).readAsBytes();
      } else if (imageUrl != null) {
        // For network images, download first

        final response = await http.get(Uri.parse(imageUrl));

        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        }
      }

      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load image for editing')),
        );

        return;
      }

      // Navigate to image editor with white background theme

      final Uint8List? editedBytes = await Navigator.push(
        context,

        MaterialPageRoute(
          builder: (context) => Theme(
            data: ThemeData.light().copyWith(
              // Set scaffold background to white
              scaffoldBackgroundColor: Colors.white,

              // Set app bar background to white
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,

                foregroundColor: Colors.black,

                elevation: 0,
              ),

              // Set bottom sheet background to white
              bottomSheetTheme: const BottomSheetThemeData(
                backgroundColor: Colors.white,
              ),

              // Set dialog background to white
              dialogTheme: const DialogThemeData(backgroundColor: Colors.white),

              // Set card background to white
              cardTheme: const CardThemeData(color: Colors.white),

              // Set color scheme with white surfaces
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,

                brightness: Brightness.light,

                surface: Colors.white,

                background: Colors.white,
              ),
            ),

            child: ImageEditor(image: imageBytes!),
          ),
        ),
      );

      // If user edited and saved the image

      if (editedBytes != null) {
        // Save edited image to temporary file

        final Directory tempDir = await getTemporaryDirectory();

        final String editedFilePath =
            '${tempDir.path}/edited_image_${DateTime.now().millisecondsSinceEpoch}.png';

        final File editedFile = File(editedFilePath);

        await editedFile.writeAsBytes(editedBytes);

        // Get new image dimensions

        final ui.Image decoded = await decodeImageFromList(editedBytes);

        final double intrinsicW = decoded.width.toDouble();

        final double intrinsicH = decoded.height.toDouble();

        // Calculate display size maintaining aspect ratio

        const double maxEdge = 240.0;

        double displayW = intrinsicW;

        double displayH = intrinsicH;

        if (intrinsicW > intrinsicH && intrinsicW > maxEdge) {
          displayW = maxEdge;

          displayH = maxEdge * (intrinsicH / intrinsicW);
        } else if (intrinsicH >= intrinsicW && intrinsicH > maxEdge) {
          displayH = maxEdge;

          displayW = maxEdge * (intrinsicW / intrinsicH);
        }

        // Update the canvas item with edited image

        final previous = selectedItem!.copyWith();

        setState(() {
          selectedItem!.properties['filePath'] = editedFilePath;

          selectedItem!.properties['imageUrl'] =
              null; // Clear network URL since we now have local file

          selectedItem!.properties['intrinsicWidth'] = intrinsicW;

          selectedItem!.properties['intrinsicHeight'] = intrinsicH;

          selectedItem!.properties['displayWidth'] = displayW;

          selectedItem!.properties['displayHeight'] = displayH;
        });

        _addAction(
          CanvasAction(
            type: 'modify',

            item: selectedItem,

            previousState: previous,

            timestamp: DateTime.now(),
          ),
        );

        // Show success message

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),

                SizedBox(width: 12.w),

                Text(
                  'Image edited successfully!',

                  style: TextStyle(
                    fontSize: 16.sp,

                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            backgroundColor: Colors.green.shade400,

            behavior: SnackBarBehavior.floating,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),

            margin: EdgeInsets.all(16.w),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to edit image')));
    }
  }

  Future<void> _removeBackground() async {
    if (selectedItem == null || selectedItem!.type != CanvasItemType.image) {
      return;
    }

    try {
      // Show loading indicator

      showDialog(
        context: context,

        barrierDismissible: false,

        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final String? filePath = selectedItem!.properties['filePath'] as String?;

      final String? imageUrl = selectedItem!.properties['imageUrl'] as String?;

      Uint8List? imageBytes;

      // Get image bytes based on source

      if (filePath != null) {
        imageBytes = await File(filePath).readAsBytes();
      } else if (imageUrl != null) {
        // For network images, download first

        final response = await http.get(Uri.parse(imageUrl));

        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        }
      }

      if (imageBytes == null) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not load image for background removal'),
          ),
        );

        return;
      }

      // Remove background

      ui.Image resultImage = await BackgroundRemover.instance.removeBg(
        imageBytes,
      );

      // Convert ui.Image back to Uint8List

      final ByteData? byteData = await resultImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process image')),
        );

        return;
      }

      final Uint8List processedBytes = byteData.buffer.asUint8List();

      // Save processed image to temporary file

      final Directory tempDir = await getTemporaryDirectory();

      final String processedFilePath =
          '${tempDir.path}/bg_removed_${DateTime.now().millisecondsSinceEpoch}.png';

      final File processedFile = File(processedFilePath);

      await processedFile.writeAsBytes(processedBytes);

      // Get new image dimensions

      final double intrinsicW = resultImage.width.toDouble();

      final double intrinsicH = resultImage.height.toDouble();

      // Calculate display size maintaining aspect ratio

      const double maxEdge = 240.0;

      double displayW = intrinsicW;

      double displayH = intrinsicH;

      if (intrinsicW > intrinsicH && intrinsicW > maxEdge) {
        displayW = maxEdge;

        displayH = maxEdge * (intrinsicH / intrinsicW);
      } else if (intrinsicH >= intrinsicW && intrinsicH > maxEdge) {
        displayH = maxEdge;

        displayW = maxEdge * (intrinsicW / intrinsicH);
      }

      // Update the canvas item with processed image

      final previous = selectedItem!.copyWith();

      setState(() {
        selectedItem!.properties['filePath'] = processedFilePath;

        selectedItem!.properties['imageUrl'] =
            null; // Clear network URL since we now have local file

        selectedItem!.properties['intrinsicWidth'] = intrinsicW;

        selectedItem!.properties['intrinsicHeight'] = intrinsicH;

        selectedItem!.properties['displayWidth'] = displayW;

        selectedItem!.properties['displayHeight'] = displayH;
      });

      _addAction(
        CanvasAction(
          type: 'modify',

          item: selectedItem,

          previousState: previous,

          timestamp: DateTime.now(),
        ),
      );

      Navigator.pop(context); // Close loading dialog

      // Show success message

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),

              SizedBox(width: 12.w),

              Text(
                'Background removed successfully!',

                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          backgroundColor: Colors.green.shade400,

          behavior: SnackBarBehavior.floating,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),

          margin: EdgeInsets.all(16.w),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove background: $e')),
      );
    }
  }

  Widget _buildImageShadow(
    Widget image,

    Color shadowColor,

    double blurRadius,

    double width,

    double height,

    double shadowSize,
  ) {
    // Calculate the scaled dimensions for shadow size

    final double shadowWidth = width * (1.0 + shadowSize / 100.0);

    final double shadowHeight = height * (1.0 + shadowSize / 100.0);

    return SizedBox(
      width: shadowWidth,

      height: shadowHeight,

      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: blurRadius,

          sigmaY: blurRadius,
        ),

        child: ColorFiltered(
          colorFilter: ColorFilter.mode(shadowColor, BlendMode.srcATop),

          child: Transform.scale(scale: 1.0 + shadowSize / 100.0, child: image),
        ),
      ),
    );
  }

  /// Applies stroke effect to the selected image using distance transform (like Photoshop)

  Future<void> _applyStrokeToSelectedImage({
    int strokeWidth = 10,

    Color strokeColor = Colors.black,

    int threshold = 0,
  }) async {
    if (selectedItem == null || selectedItem!.type != CanvasItemType.image) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );

      return;
    }

    // Show loading dialog

    showDialog(
      context: context,

      barrierDismissible: false,

      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),

            SizedBox(width: 16.w),

            Text(
              'Applying stroke effect...',

              style: TextStyle(fontSize: 16.sp),
            ),
          ],
        ),
      ),
    );

    try {
      // Store previous state for undo

      final CanvasItem previous = CanvasItem(
        id: selectedItem!.id,

        type: selectedItem!.type,

        properties: Map<String, dynamic>.from(selectedItem!.properties),

        createdAt: selectedItem!.createdAt,

        lastModified: selectedItem!.lastModified,
      );

      // Get image bytes

      Uint8List? imageBytes;

      // Check if it's a local file or network image

      if (selectedItem!.properties['filePath'] != null) {
        final File imageFile = File(selectedItem!.properties['filePath']);

        imageBytes = await imageFile.readAsBytes();
      } else if (selectedItem!.properties['imageUrl'] != null) {
        final response = await http.get(
          Uri.parse(selectedItem!.properties['imageUrl']),
        );

        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
        }
      }

      if (imageBytes == null) {
        Navigator.pop(context); // Close loading dialog

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load image')));

        return;
      }

      // Apply stroke effect using distance transform processor

      final ui.Image strokedImage =
          await ImageStrokeProcessor.addStrokeToImageFromBytes(
            imageBytes,

            strokeWidth: strokeWidth,

            strokeColor: ui.Color(strokeColor.value),

            threshold: threshold,
          );

      // Convert back to bytes

      final Uint8List strokedBytes = await ImageStrokeProcessor.imageToBytes(
        strokedImage,
      );

      // Save processed image to temporary file

      final Directory tempDir = await getTemporaryDirectory();

      final String strokedFilePath =
          '${tempDir.path}/stroked_${DateTime.now().millisecondsSinceEpoch}.png';

      final File strokedFile = File(strokedFilePath);

      await strokedFile.writeAsBytes(strokedBytes);

      // Update canvas item properties

      final double intrinsicW = strokedImage.width.toDouble();

      final double intrinsicH = strokedImage.height.toDouble();

      // Maintain aspect ratio for display

      final double aspectRatio = intrinsicH / intrinsicW;

      final double currentDisplayWidth =
          selectedItem!.properties['displayWidth'] ?? 240.0;

      final double newDisplayHeight = currentDisplayWidth * aspectRatio;

      setState(() {
        selectedItem!.properties['filePath'] = strokedFilePath;

        selectedItem!.properties['imageUrl'] = null; // Clear network URL

        selectedItem!.properties['intrinsicWidth'] = intrinsicW;

        selectedItem!.properties['intrinsicHeight'] = intrinsicH;

        selectedItem!.properties['displayWidth'] = currentDisplayWidth;

        selectedItem!.properties['displayHeight'] = newDisplayHeight;
      });

      _addAction(
        CanvasAction(
          type: 'modify',

          item: selectedItem,

          previousState: previous,

          timestamp: DateTime.now(),
        ),
      );

      Navigator.pop(context); // Close loading dialog

      // Show success message

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),

              SizedBox(width: 12.w),

              Text(
                'Stroke effect applied successfully!',

                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
              ),
            ],
          ),

          backgroundColor: Colors.green.shade400,

          behavior: SnackBarBehavior.floating,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),

          margin: EdgeInsets.all(16.w),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to apply stroke: $e')));
    }
  }

  /// Shows dialog to customize stroke settings

  void _showStrokeSettingsDialog() {
    if (selectedItem == null || selectedItem!.type != CanvasItemType.image) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );

      return;
    }

    int strokeWidth = 10;

    Color strokeColor = Colors.black;

    int threshold = 0;

    showDialog(
      context: context,

      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Stroke Settings'),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            children: [
              // Stroke width slider
              Text('Stroke Width: $strokeWidth'),

              Slider(
                value: strokeWidth.toDouble(),

                min: 1,

                max: 50,

                divisions: 49,

                onChanged: (value) {
                  setDialogState(() {
                    strokeWidth = value.round();
                  });
                },
              ),

              SizedBox(height: 16.h),

              // Threshold slider
              Text('Threshold: $threshold'),

              Slider(
                value: threshold.toDouble(),

                min: 0,

                max: 255,

                divisions: 255,

                onChanged: (value) {
                  setDialogState(() {
                    threshold = value.round();
                  });
                },
              ),

              SizedBox(height: 16.h),

              // Stroke color picker
              const Text('Stroke Color:'),

              SizedBox(height: 8.h),

              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,

                    builder: (context) => AlertDialog(
                      title: const Text('Pick Stroke Color'),

                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: strokeColor,

                          onColorChanged: (color) {
                            setDialogState(() {
                              strokeColor = color;
                            });
                          },
                        ),
                      ),

                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),

                          child: const Text('Done'),
                        ),
                      ],
                    ),
                  );
                },

                child: Container(
                  width: 50,

                  height: 50,

                  decoration: BoxDecoration(
                    color: strokeColor,

                    border: Border.all(color: Colors.grey),

                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),

              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                _applyStrokeToSelectedImage(
                  strokeWidth: strokeWidth,

                  strokeColor: strokeColor,

                  threshold: threshold,
                );
              },

              child: const Text('Apply Stroke'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            // === Canvas always at the bottom ===
            SizedBox(
              height: double.infinity,

              width: double.infinity,
              child: Column(
                children: [
                  SizedBox(height: 70.h),
                  _buildCanvas(),
                  Container(height: 102.5.h, color: Colors.white),
                  Container(height: 102.5.h, color: Colors.white),
                ],
              ),
            ),

            // === Action bar at the very top ===
            Positioned(top: 0, left: 0, right: 0, child: _buildActionBar()),

            // === Top Toolbar (overlayed, not pushing canvas) ===
            Positioned(
              bottom: selectedItem != null
                  ? 30.h
                  : 140.h, // leaves space for the ad banner
              left: 0,
              right: 0,
              child: _buildTopToolbar(),
            ),

            // === Bottom Controls (only if no item selected) ===
            if (selectedItem == null)
              Positioned(
                bottom: 70.h, // leaves space for the ad banner
                left: 0,
                right: 0,
                child: Container(
                  height: (selectedTabIndex == 3)
                      ? (showDrawingToolSelection ? 50.h : 95.h)
                      : 50.h,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  decoration: const BoxDecoration(color: Colors.white),
                  child: selectedTabIndex == 3
                      ? _buildDrawingControls()
                      : _buildTabContent(),
                ),
              ),

            // === Fixed Ad Banner at very bottom ===
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.white,
                alignment: Alignment.center,
                height: 40.h,
                child: const AdBanner320x50(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for checkerboard pattern to indicate transparency
class CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint1 = Paint()..color = Colors.grey[300]!;
    final Paint paint2 = Paint()..color = Colors.grey[200]!;

    const double squareSize = 4.0;
    final int rows = (size.height / squareSize).ceil();
    final int cols = (size.width / squareSize).ceil();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final Paint paint = (row + col) % 2 == 0 ? paint1 : paint2;
        canvas.drawRect(
          Rect.fromLTWH(
            col * squareSize,
            row * squareSize,
            squareSize,
            squareSize,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Replaced inline banner with shared AdBanner320x50 widget
