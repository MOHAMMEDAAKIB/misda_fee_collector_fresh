// lib/screens/student_qr_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/qr_service.dart';
import '../services/whatsapp_service.dart';

class StudentQrScreen extends StatefulWidget {
  const StudentQrScreen({super.key, required this.student});
  final Student student;
  @override
  State<StudentQrScreen> createState() => _State();
}

class _State extends State<StudentQrScreen> {
  late final Future<File> _png = QrService.createPng(widget.student.regNo);

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _shareQr(File png) async {
    try {
      await WhatsAppService.shareQr(widget.student, png);
    } catch (_) {
      _snack('Could not open the share sheet.');
    }
  }

  Future<void> _openChat() async {
    try {
      final ok = await WhatsAppService.openChat(widget.student);
      if (!ok) _snack('WhatsApp could not be opened.');
    } catch (_) {
      _snack('WhatsApp could not be opened.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    return Scaffold(
      appBar: AppBar(title: Text(s.regNo)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          Text(s.name, style: Theme.of(context).textTheme.titleLarge),
          Text('${s.regNo} • ${s.className} • ${s.phone}'),
          const SizedBox(height: 20),
          Expanded(
            child: FutureBuilder<File>(
              future: _png,
              builder: (_, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Could not create QR'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return Column(children: [
                  Expanded(child: Image.file(snap.data!)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Send QR on WhatsApp'),
                      onPressed: () => _shareQr(snap.data!),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text('Open chat (text only)'),
                      onPressed: _openChat,
                    ),
                  ),
                ]);
              },
            ),
          ),
        ]),
      ),
    );
  }
}
