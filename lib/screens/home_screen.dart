// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'register_student_screen.dart';
import 'scan_screen.dart';
import 'student_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void go(Widget w) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return Scaffold(
      appBar: AppBar(title: const Text('Fee Collector')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(children: [
          SizedBox(
            width: double.infinity,
            height: 90,
            child: FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 32),
              label: const Text('Scan & collect',
                  style: TextStyle(fontSize: 20)),
              onPressed: () => go(const ScanScreen()),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Register student'),
              onPressed: () => go(const RegisterStudentScreen()),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text('Students'),
              onPressed: () => go(const StudentListScreen()),
            ),
          ),
        ]),
      ),
    );
  }
}
