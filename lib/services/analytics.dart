// lib/services/analytics.dart
import '../models/payment.dart';
import '../models/student.dart';

class ClassStat {
  ClassStat(this.name);
  final String name;
  int students = 0;
  int paid = 0;
  num collected = 0;
  int get unpaid => students - paid;
}

String money(num n) => n
    .round()
    .toString()
    .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

class Analytics {
  Analytics(this.students, this.payments)
      : _byReg = {for (final s in students) s.regNo: s};

  final List<Student> students;
  final List<Payment> payments;
  final Map<String, Student> _byReg;

  static String todayKey() =>
      DateTime.now().toIso8601String().substring(0, 10);

  num _sum(Iterable<Payment> ps) => ps.fold<num>(0, (s, p) => s + p.amount);

  // ---- collection totals ----
  Iterable<Payment> get _today => payments.where((p) => p.paidDate == todayKey());
  num get todayTotal => _sum(_today);
  int get todayCount => _today.length;

  Iterable<Payment> _inMonth(String m) => payments.where((p) => p.month == m);
  num monthTotal(String m) => _sum(_inMonth(m));
  int monthCount(String m) => _inMonth(m).length;

  // ---- paid vs unpaid ----
  /// Active students who were already registered in month [m].
  bool _eligible(Student s, String m) {
    if (s.status.toLowerCase() != 'active') return false;
    final reg = RegExp(r'^\d{4}-\d{2}').stringMatch(s.registeredDate);
    return reg == null || reg.compareTo(m) <= 0; // unparsable date = include
  }

  List<Student> eligible(String m) =>
      students.where((s) => _eligible(s, m)).toList();

  Set<String> _paidRegs(String m) => _inMonth(m).map((p) => p.regNo).toSet();

  int paidCount(String m) {
    final paid = _paidRegs(m);
    return eligible(m).where((s) => paid.contains(s.regNo)).length;
  }

  List<Student> unpaid(String m) {
    final paid = _paidRegs(m);
    return eligible(m).where((s) => !paid.contains(s.regNo)).toList()
      ..sort((a, b) => a.regNo.compareTo(b.regNo));
  }

  // ---- charts and class table ----
  List<MapEntry<String, num>> lastMonths(int n) {
    final now = DateTime.now();
    final out = <MapEntry<String, num>>[];
    for (var i = n - 1; i >= 0; i--) {
      final key = monthKey(DateTime(now.year, now.month - i));
      out.add(MapEntry(key, monthTotal(key)));
    }
    return out;
  }

  List<ClassStat> byClass(String m) {
    final map = <String, ClassStat>{};
    ClassStat stat(String raw) {
      final key = raw.isEmpty ? '(no class)' : raw;
      return map.putIfAbsent(key, () => ClassStat(key));
    }

    final paid = _paidRegs(m);
    for (final s in eligible(m)) {
      final c = stat(s.className.trim());
      c.students++;
      if (paid.contains(s.regNo)) c.paid++;
    }
    for (final p in _inMonth(m)) {
      final cls = _byReg[p.regNo]?.className.trim() ?? '(unknown)';
      stat(cls).collected += p.amount;
    }
    return map.values.toList()
      ..sort((a, b) => b.collected.compareTo(a.collected));
  }
}
