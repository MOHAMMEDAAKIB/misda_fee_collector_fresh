// lib/services/reg_number.dart
class RegNumber {
  static String prefix(String code, [DateTime? now]) {
    final yy = ((now ?? DateTime.now()).year % 100).toString().padLeft(2, '0');
    return 'REG$yy$code'; // e.g. REG26G10
  }

  /// Next number for this class and year: REG26G10 + 0001 = REG26G100001
  static String next(String code, Iterable<String> existing, [DateTime? now]) {
    final p = prefix(code, now);
    final re = RegExp('^${RegExp.escape(p)}(\\d{4})\$');
    var max = 0;
    for (final r in existing) {
      final m = re.firstMatch(r.toUpperCase());
      if (m != null) {
        final n = int.parse(m.group(1)!);
        if (n > max) max = n;
      }
    }
    return '$p${(max + 1).toString().padLeft(4, '0')}';
  }

  /// "Grade 10" -> G10, "Grade 11 Maths" -> GM11 (admin can edit it).
  static String suggestCode(String className) {
    final letters = StringBuffer();
    final digits = StringBuffer();
    for (final w in className.trim().split(RegExp(r'\s+'))) {
      final l = RegExp(r'[A-Za-z]').firstMatch(w)?.group(0);
      if (l != null) letters.write(l.toUpperCase());
      digits.write(RegExp(r'\d+').allMatches(w).map((m) => m.group(0)).join());
    }
    return '$letters$digits';
  }
}