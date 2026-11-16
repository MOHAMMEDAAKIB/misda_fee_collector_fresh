// lib/providers/student_provider.dart
import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../services/sheets_service.dart';

class DuplicateStudentException implements Exception {
  DuplicateStudentException(this.message);
  final String message;
}

class StudentProvider extends ChangeNotifier {
  StudentProvider(this._sheets);
  final SheetsService _sheets;

  List<Student> students = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await _sheets.read('Students!A2:F'); // skip header
      students = rows.where((r) => r.isNotEmpty).map(Student.fromRow).toList();
    } catch (e) {
      error = 'Could not load students: $e';
    }
    loading = false;
    notifyListeners();
  }

  String _fmt(int n) => 'REG${n.toString().padLeft(4, '0')}';

  Future<Student> register({
    required String name,
    required String phone,
    required String className,
  }) async {
    final p = normalizePhone(phone);
    final n = name.trim();

    await load(); // fresh copy right before checking, reduces clashes
    if (error != null) throw Exception(error);

    final dup = students.any(
      (s) => s.phone == p && s.name.toLowerCase() == n.toLowerCase(),
    );
    if (dup) {
      throw DuplicateStudentException(
        'This student is already registered with this phone number.',
      );
    }

    final c = await _sheets.read('Settings!B1');
    var next = (c.isNotEmpty && c[0].isNotEmpty)
        ? int.tryParse(c[0][0].toString()) ?? 1
        : 1;
    final used = students.map((s) => s.regNo).toSet();
    while (used.contains(_fmt(next))) {
      next++; // self-heals if counter lagged
    }

    final s = Student(
      regNo: _fmt(next),
      name: n,
      phone: p,
      className: className.trim(),
      registeredDate: DateTime.now().toIso8601String().substring(0, 10),
    );

    await _sheets.append('Students!A:F', s.toRow()); // student first
    await _sheets.update('Settings!B1', [next + 1]); // then the counter

    students = [...students, s];
    notifyListeners();
    return s;
  }
}
