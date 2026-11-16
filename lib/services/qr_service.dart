// lib/services/qr_service.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrService {
  /// QR contains ONLY the reg number, never personal data.
  static Future<File> createPng(String regNo, {double size = 1024}) async {
    const margin = 80.0;
    final painter = QrPainter(
      data: regNo,
      version: QrVersions.auto,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      gapless: true,
      eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square, color: Colors.black),
      dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square, color: Colors.black),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size, size), Paint()..color = Colors.white);
    canvas.translate(margin, margin);
    painter.paint(canvas, Size(size - margin * 2, size - margin * 2));

    final image =
        await recorder.endRecording().toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$regNo.png');
    return file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
  }
}
