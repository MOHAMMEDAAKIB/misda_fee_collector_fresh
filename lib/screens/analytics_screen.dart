// lib/screens/analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../providers/payment_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/student_provider.dart';
import '../services/analytics.dart';
import '../services/whatsapp_service.dart';
import 'settings_screen.dart';
import 'student_detail_screen.dart';
import 'widgets/monthly_bar_chart.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _State();
}

class _State extends State<AnalyticsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String get _key => monthKey(_month);
  bool get _isCurrent => _key == monthKey(DateTime.now());

  void _shift(int d) =>
      setState(() => _month = DateTime(_month.year, _month.month + d));

  Future<void> _refresh() async {
    await Future.wait([
      context.read<StudentProvider>().load(),
      context.read<PaymentProvider>().load(),
    ]);
  }

  Future<void> _remind(String phone, String name, num balance) async {
    final text = 'Hello $name, this is a reminder that the class fee for '
        '${monthLabel(_key)} is still pending. Balance: Rs. ${money(balance)}. '
        'Please ignore this message if you have already paid.';
    try {
      await WhatsAppService.openText(phone, text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp could not be opened.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudentProvider>();
    final pp = context.watch<PaymentProvider>();
    final st = context.watch<SettingsProvider>();
    final loading = sp.loading || pp.loading || st.loading;


    final a = Analytics(sp.students, pp.payments, st.feeBook);
    final billed = a.billed(_key);
    final paid = a.countOf(_key, FeeStatus.paid);
    final pending = a.pending(_key);
    final classes = a.byClass(_key);
    final noFee = a.noFeeClasses(_key);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1)),
            Text(monthLabel(_key), style: t.titleLarge),
            IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _isCurrent ? null : () => _shift(1)),
          ]),
          if (noFee.isNotEmpty)
            Card(
              color: Colors.orange.shade50,
              child: ListTile(
                leading: const Icon(Icons.warning_amber),
                title: Text('Fee not set for: ${noFee.join(', ')}'),
                subtitle: const Text('Tap to open Settings'),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _Num('Collected', 'Rs. ${money(a.monthTotal(_key))}'),
                    _Num('Outstanding', 'Rs. ${money(a.outstanding(_key))}'),
                    _Num('Paid', '$paid / $billed'),
                  ]),
            ),
          ),
          const SizedBox(height: 16),
          Text('Last 6 months', style: t.titleMedium),
          const SizedBox(height: 8),
          MonthlyBarChart(data: a.lastMonths(6), selected: _key),
          const SizedBox(height: 16),
          Text('By class', style: t.titleMedium),
          if (classes.isEmpty) const ListTile(title: Text('No data yet')),
          for (final c in classes)
            ListTile(
              title: Text(c.name),
              subtitle: Text('${c.paid} paid • ${c.partial} partial • ${c.unpaid} unpaid'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Rs. ${money(c.collected)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('of ${money(c.expected)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text('Pending (${pending.length})', style: t.titleMedium),
          if (pending.isEmpty && billed > 0)
            const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('Everyone has paid')),
          for (final s in pending)
            ListTile(
              title: Text(s.name),
              subtitle: Text('${s.regNo} • ${s.className}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text('Rs. ${money(a.balanceOf(s, _key))}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  tooltip: 'Remind on WhatsApp',
                  icon: const Icon(Icons.chat),
                  onPressed: () => _remind(s.phone, s.name,
                      a.balanceOf(s, _key)),
                ),
              ]),
              onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => StudentDetailScreen(student: s))),
            ),
        ]),
      ),
    );
  }
}

class _Num extends StatelessWidget {
  const _Num(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ]);
}