// lib/services/analytics.dart
import '../models/fees.dart';
import '../models/payment.dart';
import '../models/student.dart';

enum FeeStatus { paid, partial, unpaid, noFee }

class ClassStat {
  ClassStat(this.name);
  final String name;
  int students = 0, paid = 0, partial = 0;
  num collected = 0, expected = 0, outstanding = 0;
  int get unpaid => students - paid - partial;
}

String money(num n) => n
    .round()
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

class Analytics {
  Analytics(this.students, this.payments, this.fees)
      : _byReg = {for (final s in students) s.regNo: s} {
    for (final p in payments) {
      final k = '${p.regNo}|${p.month}';
      _received[k] = (_received[k] ?? 0) + p.amount;
    }
  }

  final List<Student> students;
  final List<Payment> payments;
  final FeeBook fees;
  final Map<String, Student> _byReg;
  final Map<String, num> _received = {};

  static String todayKey() =>
      DateTime.now().toIso8601String().substring(0, 10);

  num _sum(Iterable<Payment> ps) => ps.fold<num>(0, (s, p) => s + p.amount);

  // ---- cash collected (real money, includes inactive students) ----
  Iterable<Payment> get _today => payments.where((p) => p.paidDate == todayKey());
  num get todayTotal => _sum(_today);
  int get todayCount => _today.length;

  Iterable<Payment> _inMonth(String m) => payments.where((p) => p.month == m);
  num monthTotal(String m) => _sum(_inMonth(m));
  int monthCount(String m) => _inMonth(m).length;

  // ---- who owes what ----
  bool _registeredBy(Student s, String m) {
    final reg = RegExp(r'^\d{4}-\d{2}').stringMatch(s.registeredDate);
    return reg == null || reg.compareTo(m) <= 0;
  }

  List<Student> eligible(String m) =>
      students.where((s) => s.isActive && _registeredBy(s, m)).toList();

  num feeOf(Student s, String m) => fees.feeFor(s.className, m);
  num receivedBy(Student s, String m) => _received['${s.regNo}|$m'] ?? 0;
  num balanceOf(Student s, String m) => feeOf(s, m) - receivedBy(s, m);

  FeeStatus statusOf(Student s, String m) {
    final fee = feeOf(s, m);
    if (fee <= 0) return FeeStatus.noFee;
    final got = receivedBy(s, m);
    if (got >= fee) return FeeStatus.paid;
    return got > 0 ? FeeStatus.partial : FeeStatus.unpaid;
  }

  int countOf(String m, FeeStatus st) =>
      eligible(m).where((s) => statusOf(s, m) == st).length;

  /// Students that have a fee set (the ones counted in paid/unpaid).
  int billed(String m) =>
      eligible(m).where((s) => statusOf(s, m) != FeeStatus.noFee).length;

  num expected(String m) =>
      eligible(m).fold<num>(0, (a, s) => a + feeOf(s, m));

  num outstanding(String m) => eligible(m).fold<num>(0, (a, s) {
        final b = balanceOf(s, m);
        return feeOf(s, m) > 0 && b > 0 ? a + b : a;
      });

  List<Student> pending(String m) => eligible(m).where((s) {
        final st = statusOf(s, m);
        return st == FeeStatus.unpaid || st == FeeStatus.partial;
      }).toList()
        ..sort((a, b) => a.regNo.compareTo(b.regNo));

  Set<String> noFeeClasses(String m) => {
        for (final s in eligible(m))
          if (statusOf(s, m) == FeeStatus.noFee)
            s.className.isEmpty ? '(no class)' : s.className,
      };

  // ---- charts and class table ----
  List<MapEntry<String, num>> lastMonths(int n) {
    final now = DateTime.now();
    return [
      for (var i = n - 1; i >= 0; i--)
        () {
          final key = monthKey(DateTime(now.year, now.month - i));
          return MapEntry<String, num>(key, monthTotal(key));
        }(),
    ];
  }

  List<ClassStat> byClass(String m) {
    final map = <String, ClassStat>{};
    ClassStat stat(String raw) {
      final key = raw.trim().isEmpty ? '(no class)' : raw.trim();
      return map.putIfAbsent(key, () => ClassStat(key));
    }

    for (final s in eligible(m)) {
      final st = statusOf(s, m);
      if (st == FeeStatus.noFee) continue;
      final c = stat(s.className);
      c.students++;
      c.expected += feeOf(s, m);
      if (st == FeeStatus.paid) c.paid++;
      if (st == FeeStatus.partial) c.partial++;
      final b = balanceOf(s, m);
      if (b > 0) c.outstanding += b;
    }
    for (final p in _inMonth(m)) {
      stat(_byReg[p.regNo]?.className ?? '(unknown)').collected += p.amount;
    }
    return map.values.toList()
      ..sort((a, b) => b.collected.compareTo(a.collected));
  }
}
