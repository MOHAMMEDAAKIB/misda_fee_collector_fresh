// lib/screens/student_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../models/student.dart';
import '../providers/payment_provider.dart';
import '../services/whatsapp_service.dart';
import 'student_qr_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  const StudentDetailScreen({super.key, required this.student});
  final Student student;
  @override
  State<StudentDetailScreen> createState() => _State();
}

class _State extends State<StudentDetailScreen> {
  late DateTime _month =
      DateTime(DateTime.now().year, DateTime.now().month);
  bool _busy = false;

  String get _key => monthKey(_month);
  bool get _isCurrent => _key == monthKey(DateTime.now());

  void _shift(int d) =>
      setState(() => _month = DateTime(_month.year, _month.month + d));

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _markPaid() async {
    final pp = context.read<PaymentProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm payment'),
        content: Text('${widget.student.name}\n'
            '${monthLabel(_key)} • Rs. ${pp.monthlyFee}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Mark paid')),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await pp.markPaid(widget.student, _key);
      if (mounted) _snack('Payment saved');
    } on AlreadyPaidException {
      if (mounted) _snack('Already marked paid for this month.');
    } catch (e) {
      if (mounted) _snack('Could not save: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendReceipt(Payment p) async {
    try {
      final ok = await WhatsAppService.openText(
          widget.student.phone, WhatsAppService.receipt(widget.student, p));
      if (!ok && mounted) _snack('WhatsApp could not be opened.');
    } catch (_) {
      if (mounted) _snack('WhatsApp could not be opened.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.student;
    final pp = context.watch<PaymentProvider>();
    final paid = pp.paymentFor(s.regNo, _key);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.regNo),
        actions: [
          IconButton(
            tooltip: 'QR code',
            icon: const Icon(Icons.qr_code),
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => StudentQrScreen(student: s))),
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Text(s.name, style: Theme.of(context).textTheme.headlineSmall),
        Text('${s.className} • ${s.phone}'),
        const SizedBox(height: 16),
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
          color: paid != null ? Colors.green.shade50 : Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: paid != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('PAID',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                    Text('Rs. ${paid.amount} on ${paid.paidDate}'),
                    Text('Collected by ${paid.collectedBy}'),
                  ])
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('NOT PAID',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                    Text('Fee: Rs. ${pp.monthlyFee}'),
                  ]),
          ),
        ),
        const SizedBox(height: 16),
        if (paid == null)
          FilledButton.icon(
            icon: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.payments),
            label: Text('Mark paid • Rs. ${pp.monthlyFee}'),
            onPressed: _busy ? null : _markPaid,
          )
        else
          FilledButton.icon(
            icon: const Icon(Icons.receipt_long),
            label: const Text('Send receipt on WhatsApp'),
            onPressed: () => _sendReceipt(paid),
          ),
      ]),
    );
  }
}
