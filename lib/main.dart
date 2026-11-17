
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/sheets_service.dart';
import 'providers/student_provider.dart';
import 'providers/payment_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Initialize Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Sign-In (singleton, same instance used everywhere)
  final auth = AuthService.instance;
  await auth.init();
  final sheets = SheetsService(auth);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>.value(value: auth),
        ChangeNotifierProvider(create: (_) => StudentProvider(sheets)),
        ChangeNotifierProvider(create: (_) => PaymentProvider(sheets, auth)),
        ChangeNotifierProvider(create: (_) => SettingsProvider(sheets)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MISDA Fee Collector',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const SignInScreen(),
    );
  }
}

/// Sign-in screen shown as the app entry point.
/// After successful sign-in, the user is taken to the StudentListScreen (Day 2).
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final AuthService _auth = AuthService.instance;
  bool _isSigningIn = false;
  String _status = 'Ready to sign in';

  Future<void> _signIn() async {
    setState(() {
      _isSigningIn = true;
      _status = 'Signing in...';
    });

    try {
      final signedIn = await _auth.signIn();
      if (!signedIn) {
        setState(() {
          _status = 'Sign in failed: email not in allowed admins list';
          _isSigningIn = false;
        });
        return;
      }

      setState(() {
        _status = 'Signed in as ${_auth.user!.email}';
      });

      // Navigate to the home screen after successful sign-in
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isSigningIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                  'assets/images/icon.png',
                  width: 100,
                  height: 100,
                  fit: BoxFit.contain,
                ),
              const SizedBox(height: 24),
              const Text(
                'MISDA Fee Collector',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign in with Google to continue',
                style: TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_auth.user != null)
                Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Signed in: ${_auth.user!.email}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ElevatedButton.icon(
                onPressed: _isSigningIn ? null : _signIn,
                icon: _isSigningIn
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: Text(
                  _isSigningIn ? 'Signing in...' : 'Sign in with Google',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 16),
              if (_status.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    _status,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
