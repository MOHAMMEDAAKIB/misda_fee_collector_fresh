// lib/providers/payment_provider.dart
import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import '../models/student.dart';
import '../services/auth_service.dart';
import '../services/sheets_service.dart';

class AlreadyPaidException implements Exception {
  AlreadyPaidException(this.payment);
  final Payment payment;
}

class PaymentProvider extends ChangeNotifier {
  PaymentProvider(this._sheets, this._auth);
  final SheetsService _sheets;
  final AuthService _auth;

  List<Payment> payments = [];
  num monthlyFee = 0;
  bool loading = false;
  String? error;

  Future<List<Payment>> _fetchPayments() async {
    final rows = await _sheets.read('Payments!A2:F');
    return rows.where((r) => r.isNotEmpty).map(Payment.fromRow).toList();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      payments = await _fetchPayments();
      final fee = await _sheets.read('Settings!B2');
      if (fee.isNotEmpty && fee[0].isNotEmpty) {
        monthlyFee = num.tryParse(
                fee[0][0].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ??
            0;
      }
    } catch (e) {
      error = 'Could not load payments: $e';
    }
    loading = false;
    notifyListeners();
  }

  Payment? paymentFor(String regNo, String month) {
    for (final p in payments) {
      if (p.regNo == regNo && p.month == month) return p;
    }
    return null;
  }

  Future<Payment> markPaid(Student s, String month) async {
    if (monthlyFee <= 0) {
      throw Exception('Set monthly_fee in Settings!B2 first.');
    }
    // Fresh read right before writing, so a stale screen can't double-mark.
    payments = await _fetchPayments();
    final existing = paymentFor(s.regNo, month);
    if (existing != null) {
      notifyListeners();
      throw AlreadyPaidException(existing);
    }

    final p = Payment(
      id: 'P${DateTime.now().millisecondsSinceEpoch}',
      regNo: s.regNo,
      month: month,
      amount: monthlyFee,
      paidDate: DateTime.now().toIso8601String().substring(0, 10),
      collectedBy: _auth.user?.email ?? '',
    );
    await _sheets.append('Payments!A:F', p.toRow(), raw: true);
    payments = [...payments, p];
    notifyListeners();
    return p;
  }
}
