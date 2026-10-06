import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Renders a reusable photo pin PNG for a Mapbox point annotation.
abstract final class PhotoMarker {
  static Future<Uint8List> imageFor(
    String assetPath, {
    int memoryCount = 1,
    Uint8List? photoBytes,
  }) async {
    ui.Image? photo;
    try {
      final bytes =
          photoBytes ?? (await rootBundle.load(assetPath)).buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 160);
      photo = (await codec.getNextFrame()).image;
      codec.dispose();
    } catch (_) {
      // A missing demo asset still produces a tappable, visible marker.
    }

    const width = 144.0;
    const height = 164.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(6, 5, 132, 132),
      const Radius.circular(22),
    );
    final pin = Path()
      ..addRRect(body)
      ..moveTo(59, 132)
      ..lineTo(72, 158)
      ..lineTo(85, 132)
      ..close();
    canvas.drawShadow(pin, Colors.black.withValues(alpha: 0.23), 5, false);
    canvas.drawPath(pin, Paint()..color = Colors.white);

    final imageRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 11, 120, 120),
      const Radius.circular(17),
    );
    canvas.save();
    canvas.clipRRect(imageRect);
    if (photo != null) {
      canvas.drawImageRect(
        photo,
        Rect.fromLTWH(0, 0, photo.width.toDouble(), photo.height.toDouble()),
        imageRect.outerRect,
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      canvas.drawRect(
        imageRect.outerRect,
        Paint()..color = const Color(0xFFB9CBC1),
      );
      canvas.drawCircle(
        const Offset(100, 43),
        13,
        Paint()..color = const Color(0xFFEAF0E9),
      );
      canvas.drawPath(
        Path()
          ..moveTo(12, 117)
          ..lineTo(55, 61)
          ..lineTo(82, 94)
          ..lineTo(101, 73)
          ..lineTo(132, 115)
          ..close(),
        Paint()..color = const Color(0xFF719584),
      );
    }
    canvas.restore();

    if (memoryCount > 1) {
      canvas.drawCircle(
        const Offset(120, 120),
        16,
        Paint()..color = const Color(0xFF304C42),
      );
      final label = TextPainter(
        text: TextSpan(
          text: '$memoryCount',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(
        canvas,
        Offset(120 - label.width / 2, 120 - label.height / 2),
      );
      label.dispose();
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    photo?.dispose();
    image.dispose();
    picture.dispose();
    return bytes!.buffer.asUint8List();
  }
}
