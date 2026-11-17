// lib/screens/student_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../models/student.dart';
import '../providers/payment_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/student_provider.dart';
import '../services/analytics.dart';
import '../services/whatsapp_service.dart';
import 'student_qr_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key, required this.student});
  final Student student;
  @override
  State<StudentDetailScreen> createState() => _State();
}

class _State extends State<StudentDetailScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _busy = false;

  String get _key => monthKey(_month);
  bool get _isCurrent => _key == monthKey(DateTime.now());
  void _shift(int d) =>
      setState(() => _month = DateTime(_month.year, _month.month + d));

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<num?> _askAmount(num balance) {
    final c = TextEditingController(text: balance.toString());
    return showDialog<num>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final text = c.text.trim();
        final v = num.tryParse(text);
        String? err;
        if (text.isNotEmpty) {
          if (v == null || v <= 0) {
            err = 'Enter a valid amount';
          } else if (v > balance) {
            err = 'More than the balance (Rs. ${money(balance)})';
          }
        }
        final ok = v != null && v > 0 && v <= balance;
        return AlertDialog(
          title: const Text('Amount received'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: c,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  InputDecoration(prefixText: 'Rs. ', errorText: err),
              onChanged: (_) => setS(() {}),
            ),
            const SizedBox(height: 8),
            Text(ok
                ? 'Balance after: Rs. ${money(balance - v)}'
                : 'Balance now: Rs. ${money(balance)}'),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: ok ? () => Navigator.pop(ctx, v) : null,
                child: const Text('Save')),
          ],
        );
      }),
    );
  }

  Future<void> _addPayment(Student s, num fee, num balance) async {
    final amount = await _askAmount(balance);
    if (amount == null || !mounted) return;

    final pp = context.read<PaymentProvider>();
    setState(() => _busy = true);
    try {
      await pp.addPayment(s, _key, amount, fee);
      if (mounted) _snack('Payment saved');
    } on AlreadyPaidException {
      if (mounted) _snack('Already fully paid for this month.');
    } on OverpaymentException catch (e) {
      if (mounted) {
        _snack('The balance is only Rs. ${money(e.balance)}. Try again.');
      }
    } catch (e) {
      if (mounted) {
        _snack(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendReceipt(Student s, num fee, num paid, Payment last) async {
    try {
      final ok = await WhatsAppService.openText(s.phone,
          WhatsAppService.receipt(s, last, fee: fee, totalPaid: paid));
      if (!ok && mounted) _snack('WhatsApp could not be opened.');
    } catch (_) {
      if (mounted) _snack('WhatsApp could not be opened.');
    }
  }

  Future<void> _setStatus(Student s, String status) async {
    try {
      await context.read<StudentProvider>().setStatus([s.regNo], status);
    } catch (e) {
      if (mounted) _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _row(String a, num v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(a),
          Text('Rs. ${money(v)}',
              style: TextStyle(
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudentProvider>();
    final pp = context.watch<PaymentProvider>();
    final st = context.watch<SettingsProvider>();
    final s = sp.students.firstWhere((x) => x.regNo == widget.student.regNo,
        orElse: () => widget.student);

    final fee = st.feeBook.feeFor(s.className, _key);
    final paid = pp.paidFor(s.regNo, _key);
    final balance = fee - paid;
    final list = pp.paymentsFor(s.regNo, _key);

    String label;
    Color bg;
    if (fee <= 0) {
      label = 'FEE NOT SET';
      bg = Colors.orange.shade50;
    } else if (balance <= 0) {
      label = 'PAID';
      bg = Colors.green.shade50;
    } else if (paid > 0) {
      label = 'PARTIALLY PAID';
      bg = Colors.amber.shade50;
    } else {
      label = 'NOT PAID';
      bg = Colors.red.shade50;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.regNo),
        actions: [
          IconButton(
            tooltip: 'QR code',
            icon: const Icon(Icons.qr_code),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => StudentQrScreen(student: s))),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(s.name, style: Theme.of(context).textTheme.headlineSmall),
        Text('${s.className} • ${s.phone}'),
        const SizedBox(height: 12),
        if (!s.isActive)
          Card(
            color: Colors.orange.shade50,
            child: ListTile(
              title: const Text('Inactive student'),
              trailing: FilledButton.tonal(
                  onPressed: () => _setStatus(s, 'active'),
                  child: const Text('Reactivate')),
            ),
          ),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _shift(-1)),
          Text(monthLabel(_key),
              style: Theme.of(context).textTheme.titleMedium),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _isCurrent ? null : () => _shift(1)),
        ]),
        Card(
          color: bg,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20)),
              const SizedBox(height: 8),
              if (fee <= 0)
                Text('Set the fee for ${s.className} in Settings → Fees.')
              else ...[
                _row('Fee', fee),
                _row('Paid', paid),
                _row('Balance', balance < 0 ? 0 : balance, bold: true),
              ],
            ]),
          ),
        ),
        for (final p in list)
          ListTile(
            dense: true,
            leading: const Icon(Icons.payments_outlined),
            title: Text('Rs. ${money(p.amount)}'),
            subtitle: Text('${p.paidDate} • ${p.collectedBy}'),
          ),
        const SizedBox(height: 12),
        if (s.isActive && fee > 0 && balance > 0)
          FilledButton.icon(
            icon: _busy
                ? const SizedBox(
                    height: 18, width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.payments),
            label: Text(paid > 0 ? 'Add payment' : 'Record payment'),
            onPressed: _busy ? null : () => _addPayment(s, fee, balance),
          ),
        if (list.isNotEmpty) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.receipt_long),
            label: const Text('Send receipt on WhatsApp'),
            onPressed: () => _sendReceipt(s, fee, paid, list.last),
          ),
        ],
        if (s.isActive)
          TextButton(
              onPressed: () => _setStatus(s, 'inactive'),
              child: const Text('Mark student as inactive')),
      ]),
    );
  }
}
