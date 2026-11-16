// lib/models/payment.dart
class Payment {
  Payment({
    required this.id,
    required this.regNo,
    required this.month,
    required this.amount,
    required this.paidDate,
    required this.collectedBy,
  });

  final String id, regNo, month, paidDate, collectedBy;
  final num amount;

  factory Payment.fromRow(List<Object?> r) {
    String c(int i) => i < r.length ? r[i].toString() : '';
    return Payment(
      id: c(0),
      regNo: c(1),
      month: c(2),
      amount: num.tryParse(c(3).replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
      paidDate: c(4),
      collectedBy: c(5),
    );
  }

  List<Object?> toRow() => [id, regNo, month, amount, paidDate, collectedBy];
}

String monthKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}';

const _names = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String monthLabel(String key) {
  final p = key.split('-');
  if (p.length != 2) return key;
  final m = int.tryParse(p[1]) ?? 1;
  return '${_names[(m - 1).clamp(0, 11)]} ${p[0]}';
}
