// lib/providers/settings_provider.dart
import 'package:flutter/foundation.dart';
import '../models/fees.dart';
import '../services/sheets_service.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._sheets);
  final SheetsService _sheets;

  List<ClassInfo> classes = [];
  FeeBook feeBook = FeeBook(<FeeRule>[]);
  bool loading = false;
  String? error;

  List<ClassInfo> get activeClasses =>
      classes.where((c) => c.active).toList();

  Future<void> _fetch() async {
    final cr = await _sheets.read('Classes!A2:C');
    classes = [
      for (var i = 0; i < cr.length; i++)
        if (cr[i].isNotEmpty && cr[i][0].toString().trim().isNotEmpty)
          ClassInfo.fromRow(cr[i], i + 2),
    ];
    final fr = await _sheets.read('Fees!A2:C');
    feeBook = FeeBook([
      for (final r in fr) if (r.length >= 3) FeeRule.fromRow(r),
    ]);
  }

  Future<void> load() async {
    loading = true; error = null; notifyListeners();
    try {
      await _fetch();
    } catch (e) {
      error = 'Could not load settings: $e';
    }
    loading = false; notifyListeners();
  }

  Future<void> addClass(String name, String code) async {
    final n = name.trim();
    final c = code.trim().toUpperCase();
    if (n.isEmpty) throw Exception('Enter a class name.');
    if (!RegExp(r'^[A-Z0-9]{1,6}$').hasMatch(c)) {
      throw Exception('Code must be 1-6 letters or digits, e.g. G10.');
    }
    await _fetch(); // fresh copy before checking
    if (classes.any((x) => x.name.toLowerCase() == n.toLowerCase())) {
      throw Exception('That class already exists.');
    }
    if (classes.any((x) => x.code == c)) {
      throw Exception('The code $c is already used by another class.');
    }
    await _sheets.append('Classes!A:C', [n, c, 'active'], raw: true);
    await _fetch();
    notifyListeners();
  }

  Future<void> setArchived(ClassInfo c, bool archived) async {
    await _sheets.update(
        'Classes!C${c.rowNumber}', [archived ? 'archived' : 'active']);
    await _fetch();
    notifyListeners();
  }

  /// Appends a rule. A fee for the same class+month again = correction.
  Future<void> setFee(String className, String fromMonth, num fee) async {
    if (fee <= 0) throw Exception('Fee must be above 0.');
    await _sheets.append('Fees!A:C', [className, fromMonth, fee], raw: true);
    await _fetch();
    notifyListeners();
  }
}