// lib/models/fees.dart
class ClassInfo {
  ClassInfo({required this.name, required this.code,
      required this.active, required this.rowNumber});
  final String name, code;
  final bool active;
  final int rowNumber; // row in the Classes tab

  factory ClassInfo.fromRow(List<Object?> r, int rowNumber) {
    String c(int i) => i < r.length ? r[i].toString().trim() : '';
    return ClassInfo(
      name: c(0), code: c(1).toUpperCase(),
      active: c(2).toLowerCase() != 'archived', rowNumber: rowNumber,
    );
  }
}

class FeeRule {
  FeeRule(this.className, this.fromMonth, this.fee);
  final String className, fromMonth;
  final num fee;

  factory FeeRule.fromRow(List<Object?> r) => FeeRule(
        r[0].toString().trim(),
        r[1].toString().trim(),
        num.tryParse(r[2].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      );
}

class FeeBook {
  FeeBook(this.rules);
  final List<FeeRule> rules;

  /// Latest rule for the class with from_month <= month. Later rows win ties,
  /// so a correction is just a new row for the same month.
  FeeRule? ruleFor(String className, String month) {
    FeeRule? best;
    for (final r in rules) {
      if (r.className.toLowerCase() != className.trim().toLowerCase()) continue;
      if (r.fromMonth.compareTo(month) > 0) continue;
      if (best == null || r.fromMonth.compareTo(best.fromMonth) >= 0) best = r;
    }
    return best;
  }

  num feeFor(String className, String month) =>
      ruleFor(className, month)?.fee ?? 0;
}