// lib/screens/scan_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/payment_provider.dart';
import '../providers/student_provider.dart';
import 'student_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});
  @override
  State<ScanScreen> createState() => _State();
}

class _State extends State<ScanScreen> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final _search = TextEditingController();
  bool _busy = false;
  String _q = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().load();   // warm the cache so a
      context.read<PaymentProvider>().load();   // scan opens instantly
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _search.dispose();
    super.dispose();
  }

  void _snack(String m) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  Student? _find(String code) {
    final c = code.trim().toUpperCase();
    for (final s in context.read<StudentProvider>().students) {
      if (s.regNo.toUpperCase() == c) return s;
    }
    return null;
  }

  Future<void> _open(Student s) async {
    _busy = true;
    FocusScope.of(context).unfocus();
    _search.clear();
    setState(() => _q = '');
    await _controller.stop();
    if (!mounted) return;
    await Navigator.push(context,
        MaterialPageRoute(builder: (_) => StudentDetailScreen(student: s)));
    if (!mounted) return;
    _busy = false;
    await _controller.start();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy || capture.barcodes.isEmpty) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;

    _busy = true;
    final sp = context.read<StudentProvider>();
    if (sp.students.isEmpty) await sp.load();
    if (!mounted) return;

    final s = _find(raw);
    if (s == null) {
      _snack('Unknown QR: $raw');
      await Future.delayed(const Duration(seconds: 2));
      _busy = false;
      return;
    }
    _busy = false; // _open sets it again
    await _open(s);
  }

  void _submitSearch(String v) {
    final s = _find(v);
    if (s != null) {
      _open(s);
    } else {
      _snack('No student found for "$v"');
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = context.watch<StudentProvider>().students;
    final q = _q.trim().toLowerCase();
    final matches = q.length < 2
        ? <Student>[]
        : all.where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.regNo.toLowerCase().contains(q) ||
            s.phone.contains(q)).take(4).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Scan & collect'), actions: [
        IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch()),
      ]),
      body: Column(children: [
        Expanded(
          child: MobileScanner(controller: _controller, onDetect: _onDetect),
        ),
        Material(
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: _search,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Reg number, name or phone',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _q = v),
                onSubmitted: _submitSearch,
              ),
              for (final s in matches)
                ListTile(
                  dense: true,
                  title: Text(s.name),
                  subtitle: Text('${s.regNo} • ${s.className}'),
                  onTap: () => _open(s),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
