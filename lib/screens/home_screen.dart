// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment.dart';
import '../providers/payment_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/student_provider.dart';
import '../services/analytics.dart';
import 'analytics_screen.dart';
import 'register_student_screen.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'student_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _State();
}

class _State extends State<HomeScreen> {
  DateTime? _updated;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final sp = context.read<StudentProvider>();
    final pp = context.read<PaymentProvider>();
    final st = context.read<SettingsProvider>();
    await Future.wait([sp.load(), pp.load(), st.load()]);
    if (mounted) setState(() => _updated = DateTime.now());
  }

  void _go(Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w))
          .then((_) => setState(() {})); // redraw with data changed elsewhere

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<StudentProvider>();
    final pp = context.watch<PaymentProvider>();
    final st = context.watch<SettingsProvider>();
    final loading = sp.loading || pp.loading || st.loading;
    final error = sp.error ?? pp.error ?? st.error;
    final firstLoad = loading && sp.students.isEmpty && pp.payments.isEmpty;

    final settings = context.watch<SettingsProvider>();
    final a = Analytics(sp.students, pp.payments, settings.feeBook);
    final m = monthKey(DateTime.now());
    final billed = a.billed(m);
    final paid = a.countOf(m, FeeStatus.paid);
    final partial = a.countOf(m, FeeStatus.partial);
    final unpaid = a.countOf(m, FeeStatus.unpaid);
    final noFee = a.noFeeClasses(m);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Collector'),
        actions: [
          loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                  onPressed: _refresh),
        ],
      ),
      body: firstLoad
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                if (error != null)
                  Card(
                    color: Colors.red.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.error_outline),
                      title: Text(error, maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      trailing: TextButton(
                          onPressed: _refresh, child: const Text('Retry')),
                    ),
                  ),
                Row(children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Today',
                      value: 'Rs. ${money(a.todayTotal)}',
                      sub: '${a.todayCount} payments',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: monthLabel(m),
                      value: 'Rs. ${money(a.monthTotal(m))}',
                      sub: '${a.monthCount(m)} payments',
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                if (noFee.isNotEmpty)
                  Card(
                    color: Colors.orange.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber),
                      title: Text('Fee not set for: ${noFee.join(', ')}'),
                      subtitle: const Text('Tap to open Settings'),
                      onTap: () => _go(const SettingsScreen()),
                    ),
                  ),
                Card(
                  child: InkWell(
                    onTap: () => _go(const AnalyticsScreen()),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Paid vs unpaid this month',
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text('$paid of $billed fully paid',
                                style:
                                    Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                                value: billed == 0 ? 0 : paid / billed,
                                minHeight: 8),
                            const SizedBox(height: 6),
                            Text('$partial partial • $unpaid unpaid • '
                                'Rs. ${money(a.outstanding(m))} outstanding'),
                          ]),
                    ),
                  ),
                ),
                if (_updated != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Updated ${TimeOfDay.fromDateTime(_updated!).format(context)}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.end,
                    ),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.qr_code_scanner, size: 30),
                    label: const Text('Scan & collect',
                        style: TextStyle(fontSize: 20)),
                    onPressed: () => _go(const ScanScreen()),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('Register'),
                      onPressed: () => _go(const RegisterStudentScreen()),
                    ),
                  )]),
                  const SizedBox(width: 8),
                  Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.people),
                      label: const Text('Students'),
                      onPressed: () => _go(const StudentListScreen()),
                    ),
                  ),
                  ],
                  ),
                  const SizedBox(width: 8),
                  Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bar_chart),
                      label: const Text('Analytics'),
                      onPressed: () => _go(const AnalyticsScreen()),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                    onPressed: () => _go(const SettingsScreen()),
                  ),
                ),
              ]),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.sub});
  final String title, value, sub;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: t.bodySmall),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: t.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Text(sub, style: t.bodySmall),
        ]),
      ),
    );
  }
}
