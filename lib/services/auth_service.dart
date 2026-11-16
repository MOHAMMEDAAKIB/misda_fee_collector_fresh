// lib/services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const _scopes = ['https://www.googleapis.com/auth/spreadsheets'];
const allowedAdmins = ['misda0029@gmail.com', 'aakibriyal@gmail.com']; // later: read from the Settings tab

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  GoogleSignInAccount? user;

  http.Client? _cached;
  DateTime? _cachedAt;

  Future<void> init() async {
    // Load client IDs from the .env file at the project root
    await dotenv.load(fileName: ".env");

    if (kIsWeb) {
      // Google Sign-In for Chrome / Web
      await GoogleSignIn.instance.initialize(
        clientId: dotenv.env['webclientId'] ?? '',
      );
    } else {
      // Google Sign-In for Android
      await GoogleSignIn.instance.initialize(
        serverClientId: dotenv.env['serverClientId'] ?? '',
      );
    }
  }

  Future<bool> signIn() async {
    _cached = null; // clear cached token on fresh sign-in
    user = await GoogleSignIn.instance.authenticate();
    if (!allowedAdmins.contains(user!.email)) {
      await GoogleSignIn.instance.signOut();
      user = null;
      return false;
    }
    return true;
  }

  /// Fresh authenticated HTTP client. Caches the token for up to 45 minutes
  /// so repeated API calls don't re-authorize every time.
  Future<http.Client> client() async {
    if (_cached != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < const Duration(minutes: 45)) {
      return _cached!;
    }
    final auth = await user!.authorizationClient.authorizeScopes(_scopes);
    _cached = _BearerClient(auth.accessToken);
    _cachedAt = DateTime.now();
    return _cached!;
  }
}

class _BearerClient extends http.BaseClient {
  _BearerClient(this._token);
  final String _token;
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest r) {
    r.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(r);
  }
}