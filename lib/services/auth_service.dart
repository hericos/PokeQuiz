import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_profile.dart';
import 'database_service.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Login local (e-mail/senha guardados no aparelho) e login com Google.
class AuthService extends ChangeNotifier {
  AuthService(this._db, this._prefs);

  static const _sessionKey = 'session_user_id';

  /// Client ID "Web" do Google Cloud, exigido pelo Android (Credential Manager).
  /// Informe com: --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
  static const _serverClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  final DatabaseService _db;
  final SharedPreferences _prefs;
  UserProfile? _user;
  Future<void>? _googleInit;

  UserProfile? get currentUser => _user;
  bool get isLoggedIn => _user != null;

  Future<void> restoreSession() async {
    final id = _prefs.getInt(_sessionKey);
    if (id != null) {
      _user = await _db.findUserById(id);
      if (_user == null) await _prefs.remove(_sessionKey);
    }
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    email = email.trim().toLowerCase();
    if (await _db.findUserRowByEmail(email) != null) {
      throw const AuthException('Já existe uma conta com esse e-mail.');
    }
    final salt = _randomSalt();
    final id = await _db.insertUser(
      email: email,
      provider: AuthProvider.local,
      name: name.trim(),
      passwordHash: hashPassword(password, salt),
      salt: salt,
    );
    await _startSession(id);
  }

  Future<void> login({required String email, required String password}) async {
    final row = await _db.findUserRowByEmail(email.trim());
    if (row == null) {
      throw const AuthException('E-mail ou senha inválidos.');
    }
    if (row['provider'] == AuthProvider.google.name) {
      throw const AuthException(
          'Essa conta foi criada com o Google. Use "Entrar com Google".');
    }
    final expected = row['password_hash'] as String;
    if (hashPassword(password, row['salt'] as String) != expected) {
      throw const AuthException('E-mail ou senha inválidos.');
    }
    await _startSession(row['id'] as int);
  }

  bool get googleSupported => GoogleSignIn.instance.supportsAuthenticate();

  Future<void> loginWithGoogle() async {
    final signIn = GoogleSignIn.instance;
    _googleInit ??= signIn.initialize(
      serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
    );
    try {
      await _googleInit;
    } catch (_) {
      _googleInit = null;
      rethrow;
    }

    final GoogleSignInAccount account;
    try {
      account = await signIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthException('Login com Google cancelado.');
      }
      throw AuthException('Falha no login com Google: ${e.description ?? e.code.name}');
    }

    final existing = await _db.findUserRowByEmail(account.email);
    int id;
    if (existing == null) {
      id = await _db.insertUser(
        email: account.email,
        provider: AuthProvider.google,
        name: account.displayName ?? account.email.split('@').first,
        photo: account.photoUrl,
      );
    } else {
      id = existing['id'] as int;
    }
    await _startSession(id);
  }

  Future<void> logout() async {
    if (_user?.provider == AuthProvider.google && _googleInit != null) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    _user = null;
    await _prefs.remove(_sessionKey);
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile updated) async {
    await _db.updateProfile(updated);
    _user = updated;
    notifyListeners();
  }

  Future<void> _startSession(int id) async {
    _user = await _db.findUserById(id);
    await _prefs.setInt(_sessionKey, id);
    notifyListeners();
  }

  static String _randomSalt() {
    final rnd = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => rnd.nextInt(256)));
  }

  /// SHA-256 iterado (10.000x) com salt aleatório por usuário.
  @visibleForTesting
  static String hashPassword(String password, String salt) {
    List<int> digest = utf8.encode('$salt:$password');
    for (var i = 0; i < 10000; i++) {
      digest = sha256.convert(digest).bytes;
    }
    return base64Encode(digest);
  }
}
