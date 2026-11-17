// lib/providers/payment_provider.dart
import 'package:flutter/foundation.dart';
import '../models/payment.dart';
import '../models/student.dart';
import '../services/auth_service.dart';
import '../services/sheets_service.dart';

class AlreadyPaidException implements Exception {}

class OverpaymentException implements Exception {
  OverpaymentException(this.balance);
  final num balance;
}

class PaymentProvider extends ChangeNotifier {
  PaymentProvider(this._sheets, this._auth);
  final SheetsService _sheets;
  final AuthService _auth;

  List<Payment> payments = [];
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
    } catch (e) {
      error = 'Could not load payments: $e';
    }
    loading = false;
    notifyListeners();
  }

  num paidFor(String regNo, String month) => payments
      .where((p) => p.regNo == regNo && p.month == month)
      .fold<num>(0, (s, p) => s + p.amount);

  List<Payment> paymentsFor(String regNo, String month) =>
      payments.where((p) => p.regNo == regNo && p.month == month).toList();

  Future<Payment> addPayment(Student s, String month, num amount, num fee) async {
    if (fee <= 0) {
      throw Exception(
          'Fee is not set for ${s.className} ($month). Set it in Settings.');
    }
    if (amount <= 0) throw Exception('Enter an amount above 0.');

    payments = await _fetchPayments(); // fresh read right before writing
    final balance = fee - paidFor(s.regNo, month);
    if (balance <= 0) {
      notifyListeners();
      throw AlreadyPaidException();
    }
    if (amount > balance) throw OverpaymentException(balance);

    final p = Payment(
      id: 'P${DateTime.now().millisecondsSinceEpoch}',
      regNo: s.regNo, month: month, amount: amount,
      paidDate: DateTime.now().toIso8601String().substring(0, 10),
      collectedBy: _auth.user?.email ?? '',
    );
    await _sheets.append('Payments!A:F', p.toRow(), raw: true);
    payments = [...payments, p];
    notifyListeners();
    return p;
  }
}
