import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/sheets_service.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final AuthService _auth = AuthService.instance;
  final SheetsService _sheets = SheetsService(AuthService.instance);

  bool _isLoading = false;
  String _status = 'Ready to sign in';
  List<List<Object?>> _headerRow = [];

  Future<void> _signInAndTest() async {
    setState(() {
      _isLoading = true;
      _status = 'Signing in...';
    });

    try {
      // Step 1: Sign in
      final signedIn = await _auth.signIn();
      if (!signedIn) {
        setState(() {
          _status = 'Sign in failed: email not in allowed admins list';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _status = 'Signed in as ${_auth.user!.email}. Reading sheet...';
      });

      // Step 2: Read header row
      final header = await _sheets.read('Students!A1:F1');
      setState(() {
        _headerRow = header;
        _status = 'Header row read. Appending test row...';
      });

      // Step 3: Append test row
      await _sheets.append(
        'Students!A:F',
        ['TEST001', 'Test', '94771234567', 'A', '2026-11-10', 'active'],
      );

      setState(() {
        _status = 'SUCCESS: Test row appended to sheet!';
        _isLoading = false;
      });

      // Print results to console
      debugPrint('=== DAY 1 TEST RESULTS ===');
      debugPrint('Signed in user: ${_auth.user!.email}');
      debugPrint('Header row: $header');
      debugPrint('Appended row: TEST001, Test, 94771234567, A, 2026-11-10, active');
      debugPrint('==========================');
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
      debugPrint('DAY 1 TEST ERROR: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Day 1 Test - Fee Collector'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Day 1 Test Screen',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Test Google Sign-In and Google Sheets integration',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            if (_auth.user != null)
              Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Signed in: ${_auth.user!.email}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _signInAndTest,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.login),
              label: Text(_isLoading ? 'Testing...' : 'Sign in & Test'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _status,
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (_headerRow.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Header Row:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _headerRow.first.toString(),
                      style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}