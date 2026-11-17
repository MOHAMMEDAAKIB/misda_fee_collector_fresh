// lib/screens/register_student_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/settings_provider.dart';
import '../providers/student_provider.dart';
import '../services/reg_number.dart';
import 'student_qr_screen.dart';

class RegisterStudentScreen extends StatefulWidget {
  const RegisterStudentScreen({super.key});
  @override
  State<RegisterStudentScreen> createState() => _State();
}

class _State extends State<RegisterStudentScreen> {
  final _key = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _clsName;
  bool _saving = false;

  @override
  void dispose() { _name.dispose(); _phone.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_key.currentState!.validate() || _saving) return;
    if (_clsName == null) {
      _snack('Select a class');
      return;
    }
    setState(() => _saving = true);
    try {
      final cls = context.read<SettingsProvider>().activeClasses
          .firstWhere((c) => c.name == _clsName);
      final s = await context.read<StudentProvider>().register(
          name: _name.text, phone: _phone.text, cls: cls);
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => StudentQrScreen(student: s)));
    } on DuplicateStudentException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Registration failed. Check your internet and try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final classes = context.watch<SettingsProvider>().activeClasses;
    final students = context.watch<StudentProvider>().students;
    final sel = classes.where((c) => c.name == _clsName);
    final preview = sel.isEmpty
        ? null
        : RegNumber.next(sel.first.code, students.map((s) => s.regNo));

    return Scaffold(
      appBar: AppBar(title: const Text('Register student')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _key,
          child: ListView(children: [
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) =>
                  (v == null || v.trim().length < 2) ? 'Enter the name' : null,
            ),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'WhatsApp number', hintText: '077 123 4567'),
              validator: (v) => isValidLkPhone(normalizePhone(v ?? ''))
                  ? null : 'Enter a valid Sri Lankan number',
            ),
            if (classes.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.warning_amber),
                  title: Text('No classes yet'),
                  subtitle: Text('Add classes in Settings first.'),
                ),
              )
            else ...[
              DropdownButtonFormField<String>(
                value: _clsName,
                decoration: const InputDecoration(labelText: 'Class'),
                items: [
                  for (final c in classes)
                    DropdownMenuItem(value: c.name, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _clsName = v),
                validator: (v) => v == null ? 'Select a class' : null,
              ),
              if (preview != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Reg number: $preview',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Register'),
            ),
          ]),
        ),
      ),
    );
  }
}