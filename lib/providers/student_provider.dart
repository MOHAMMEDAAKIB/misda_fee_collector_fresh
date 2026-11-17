// lib/providers/student_provider.dart
import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/fees.dart';
import '../services/sheets_service.dart';
import '../services/reg_number.dart';

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
      students = [
        for (var i = 0; i < rows.length; i++)
          if (rows[i].isNotEmpty &&
              rows[i][0].toString().trim().isNotEmpty)
            Student.fromRow(rows[i], i + 2),
      ];
    } catch (e) {
      error = 'Could not load students: $e';
    }
    loading = false;
    notifyListeners();
  }

  /// Register a student under an existing [cls]. The reg number is decided at
  /// save time after a fresh read of the sheet.
  Future<Student> register({
    required String name,
    required String phone,
    required ClassInfo cls,
  }) async {
    final p = normalizePhone(phone);
    final n = name.trim();

    await load();
    if (error != null) throw Exception(error);

    if (students.any((s) =>
        s.phone == p && s.name.toLowerCase() == n.toLowerCase())) {
      throw DuplicateStudentException(
          'This student is already registered with this phone number.');
    }

    final s = Student(
      regNo: RegNumber.next(cls.code, students.map((x) => x.regNo)),
      name: n, phone: p, className: cls.name,
      registeredDate: DateTime.now().toIso8601String().substring(0, 10),
    );
    await _sheets.append('Students!A:F', s.toRow(), raw: true);
    students = [...students, s];
    notifyListeners();
    return s;
  }

  /// Activate or deactivate students by reg number. Reloads first so row
  /// numbers are never stale.
  Future<void> setStatus(Iterable<String> regNos, String status) async {
    await load();
    if (error != null) throw Exception(error);
    final wanted = regNos.toSet();
    await _sheets.batchUpdate({
      for (final s in students)
        if (wanted.contains(s.regNo)) 'Students!F${s.rowNumber}': status,
    });
    await load();
  }
}
