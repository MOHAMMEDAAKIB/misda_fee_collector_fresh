// lib/screens/register_student_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/student.dart';
import '../providers/student_provider.dart';
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
  final _class = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _name.dispose(); _phone.dispose(); _class.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (!_key.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final s = await context.read<StudentProvider>().register(
          name: _name.text, phone: _phone.text, className: _class.text);
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
            TextFormField(
              controller: _class,
              decoration: const InputDecoration(labelText: 'Class'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter the class' : null,
            ),
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