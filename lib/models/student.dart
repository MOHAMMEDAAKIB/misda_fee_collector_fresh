// lib/models/student.dart
class Student {
  Student({
    required this.regNo,
    required this.name,
    required this.phone,
    required this.className,
    required this.registeredDate,
    this.status = 'active',
    this.rowNumber = 0,
  });

  final String regNo, name, phone, className, registeredDate, status;
  final int rowNumber;

  bool get isActive => status.toLowerCase() == 'active';

  // Sheets drops trailing empty cells, so never assume a row has 6 items.
  factory Student.fromRow(List<Object?> r, [int rowNumber = 0]) {
    String c(int i) => i < r.length ? r[i].toString() : '';
    return Student(
      regNo: c(0), name: c(1), phone: c(2),
      className: c(3), registeredDate: c(4),
      status: c(5).isEmpty ? 'active' : c(5),
      rowNumber: rowNumber,
    );
  }

  List<Object?> toRow() =>
      [regNo, name, phone, className, registeredDate, status];
}

/// Sri Lankan numbers -> 94XXXXXXXXX (the format wa.me needs on Day 3).
String normalizePhone(String input) {
  var d = input.replaceAll(RegExp(r'\D'), '');
  if (d.startsWith('0094')) {
    d = d.substring(2);                 // 0094771234567 -> 94771234567
  } else if (d.startsWith('0')) {
    d = '94${d.substring(1)}';          // 0771234567   -> 94771234567
  } else if (d.length == 9) {
    d = '94$d';                         // 771234567    -> 94771234567
  }
  return d;                             // +94771234567 already works
}

bool isValidLkPhone(String normalized) =>
    RegExp(r'^94\d{9}$').hasMatch(normalized);