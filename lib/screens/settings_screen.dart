// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/fees.dart';
import '../models/payment.dart';
import '../providers/settings_provider.dart';
import '../providers/student_provider.dart';
import '../services/analytics.dart';
import '../services/reg_number.dart';

void _err(BuildContext c, Object e) => ScaffoldMessenger.of(c).showSnackBar(
    SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));

void _ok(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Settings'),
            bottom: const TabBar(tabs: [
              Tab(text: 'Classes'), Tab(text: 'Fees'), Tab(text: 'Cleanup'),
            ]),
          ),
          body: TabBarView(
              children: [_ClassesTab(), _FeesTab(), _CleanupTab()]),
        ),
      );
}

// ---------------------------------------------------------------- Classes
class _ClassesTab extends StatelessWidget {
  const _ClassesTab();

  Future<void> _add(BuildContext context) async {
    final name = TextEditingController();
    final code = TextEditingController();
    var codeEdited = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add class'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
                labelText: 'Class name', hintText: 'Grade 10'),
            onChanged: (v) {
              if (!codeEdited) code.text = RegNumber.suggestCode(v);
            },
          ),
          TextField(
            controller: code,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
                labelText: 'Code (used in reg number)', hintText: 'G10'),
            onChanged: (_) => codeEdited = true,
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await context.read<SettingsProvider>().addClass(name.text, code.text);
    } catch (e) {
      if (context.mounted) _err(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<SettingsProvider>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _add(context),
        icon: const Icon(Icons.add),
        label: const Text('Add class'),
      ),
      body: RefreshIndicator(
        onRefresh: st.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            if (st.classes.isEmpty)
              const ListTile(
                title: Text('No classes yet'),
                subtitle: Text('Tap "Add class" to create the first one.'),
              ),
            for (final c in st.classes)
              SwitchListTile(
                title: Text(c.name),
                subtitle: Text(
                    'Code: ${c.code}  •  ${c.active ? 'Active' : 'Archived'}'),
                value: c.active,
                onChanged: (v) async {
                  try {
                    await st.setArchived(c, !v);
                  } catch (e) {
                    if (context.mounted) _err(context, e);
                  }
                },
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
// ------------------------------------------------------------------- Fees
class _FeesTab extends StatefulWidget {
  const _FeesTab();
  @override
  State<_FeesTab> createState() => _FeesState();
}

class _FeesState extends State<_FeesTab> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String get _key => monthKey(_month);
  void _shift(int d) =>
      setState(() => _month = DateTime(_month.year, _month.month + d));

  Future<void> _setFee(ClassInfo c, num current) async {
    final ctl =
        TextEditingController(text: current > 0 ? current.toString() : '');
    final fee = await showDialog<num>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${c.name} fee'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctl,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  prefixText: 'Rs. ', labelText: 'Monthly fee'),
            ),
            const SizedBox(height: 8),
            Text(
              'Applies from ${monthLabel(_key)} onward, until you set a new '
              'fee for a later month. Earlier months are not changed.',
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, num.tryParse(ctl.text.trim())),
              child: const Text('Save')),
        ],
      ),
    );
    if (fee == null || !mounted) return;
    try {
      await context.read<SettingsProvider>().setFee(c.name, _key, fee);
      if (mounted) _ok(context, 'Fee saved');
    } catch (e) {
      if (mounted) _err(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<SettingsProvider>();
    return RefreshIndicator(
      onRefresh: st.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _shift(-1)),
            Text(monthLabel(_key),
                style: Theme.of(context).textTheme.titleLarge),
            IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _shift(1)),
          ]),
          if (st.activeClasses.isEmpty)
            const ListTile(
                title: Text('Add a class first (Classes tab).')),
          for (final c in st.activeClasses)
            Builder(builder: (_) {
              final rule = st.feeBook.ruleFor(c.name, _key);
              final fee = rule?.fee ?? 0;
              final history = st.feeBook.rules
                  .where((r) =>
                      r.className.toLowerCase() == c.name.toLowerCase())
                  .toList()
                ..sort((a, b) => b.fromMonth.compareTo(a.fromMonth));
              return ExpansionTile(
                title: Text(c.name),
                subtitle: Text(rule == null
                    ? 'Not set for ${monthLabel(_key)}'
                    : 'Since ${monthLabel(rule.fromMonth)}'),
                trailing: Text(fee > 0 ? 'Rs. ${money(fee)}' : '—',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  for (final r in history)
                    ListTile(
                      dense: true,
                      title: Text('From ${monthLabel(r.fromMonth)}'),
                      trailing: Text('Rs. ${money(r.fee)}'),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: FilledButton.tonal(
                      onPressed: () => _setFee(c, fee),
                      child: Text('Set fee from ${monthLabel(_key)}'),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Cleanup
class _CleanupTab extends StatefulWidget {
  const _CleanupTab();
  @override
  State<_CleanupTab> createState() => _CleanupState();
}

class _CleanupState extends State<_CleanupTab> {
  String? _cls;
  bool _busy = false;

  Future<void> _deactivate() async {
    final sp = context.read<StudentProvider>();
    setState(() => _busy = true);
    try {
      await sp.load(); // fresh data before deciding who to change
      final targets = sp.students
          .where((s) => s.isActive && s.className == _cls)
          .toList();
      if (targets.isEmpty) {
        if (mounted) _err(context, Exception('No active students in $_cls.'));
        return;
      }
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Deactivate ${targets.length} students?'),
          content: Text(
              'All active students in $_cls will be marked inactive. Their '
              'payment history stays in the sheet, and you can reactivate '
              'any student later.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Deactivate')),
          ],
        ),
      );
      if (ok != true) return;
      await sp.setStatus(targets.map((s) => s.regNo), 'inactive');
      if (mounted) _ok(context, '${targets.length} students deactivated');
    } catch (e) {
      if (mounted) _err(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<SettingsProvider>();
    final students = context.watch<StudentProvider>().students;

    final names = {
      ...st.classes.map((c) => c.name),
      ...students.map((s) => s.className).where((n) => n.isNotEmpty),
    }.toList()
      ..sort();

    int active(String n) =>
        students.where((s) => s.isActive && s.className == n).length;

    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('End-of-year cleanup',
          style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text(
          'Mark every student of a finished class as inactive. Inactive '
          'students disappear from lists and unpaid counts, but their '
          'payments are kept and still count in the collection totals.'),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: _cls,
        decoration: const InputDecoration(
            labelText: 'Class', border: OutlineInputBorder()),
        items: [
          for (final n in names)
            DropdownMenuItem(value: n, child: Text('$n (${active(n)} active)')),
        ],
        onChanged: (v) => setState(() => _cls = v),
      ),
      const SizedBox(height: 16),
      FilledButton.tonalIcon(
        icon: _busy
            ? const SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.archive),
        label: const Text('Deactivate all students in this class'),
        onPressed: (_cls == null || _busy) ? null : _deactivate,
      ),
    ]);
  }
}