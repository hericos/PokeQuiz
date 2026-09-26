import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/user_profile.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Conta por e-mail e senha no Firebase Auth; perfil no Firestore.
class AuthService extends ChangeNotifier {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance {
    _sub = _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  late final StreamSubscription<User?> _sub;

  UserProfile? _user;
  bool _initializing = true;

  UserProfile? get currentUser => _user;
  bool get isLoggedIn => _user != null;

  /// true até sabermos se há uma sessão salva no aparelho.
  bool get initializing => _initializing;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  DocumentReference<Map<String, dynamic>> _boardDoc(String uid) =>
      _db.collection('leaderboard').doc(uid);

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _user = null;
    } else {
      try {
        final doc = await _userDoc(user.uid).get();
        // Logo após o cadastro o documento pode ainda não existir; nesse caso
        // mantém o perfil que o register() acabou de montar.
        if (!doc.exists && _user?.id == user.uid) {
          _finishInit();
          return;
        }
        _user = doc.exists
            ? UserProfile.fromDoc(doc)
            : UserProfile(
                id: user.uid,
                email: user.email ?? '',
                name: user.displayName ?? 'Treinador',
              );
      } catch (_) {
        // Sem rede e sem cache: entra com o mínimo; o perfil carrega depois.
        _user = UserProfile(
          id: user.uid,
          email: user.email ?? '',
          name: user.displayName ?? '',
        );
      }
    }
    _finishInit();
  }

  void _finishInit() {
    _initializing = false;
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) => _guard(() async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    await cred.user!.updateDisplayName(name.trim());
    final profile = UserProfile(
      id: uid,
      email: email.trim(),
      name: name.trim(),
    );
    final batch = _db.batch()
      ..set(_userDoc(uid), {
        ...profile.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      })
      ..set(_boardDoc(uid), {
        'name': profile.name,
        'thumb': null,
        'total': 0,
        'best': <String, int>{},
        'detail': <String, String>{},
      });
    await batch.commit();
    _user = profile;
    notifyListeners();
  });

  Future<void> login({required String email, required String password}) =>
      _guard(
        () => _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );

  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  Future<void> logout() => _auth.signOut();

  Future<void> updateProfile(UserProfile updated) async {
    final batch = _db.batch()
      ..set(_userDoc(updated.id), updated.toMap(), SetOptions(merge: true))
      // Nome e miniatura também aparecem no ranking.
      ..set(_boardDoc(updated.id), {
        'name': updated.name,
        'thumb': updated.photoThumb,
      }, SetOptions(merge: true));
    await batch.commit();
    _user = updated;
    notifyListeners();
  }

  /// Exclui a conta e os dados (exigência da Play Store). O Firebase pede
  /// login recente, por isso a senha é confirmada antes.
  Future<void> deleteAccount(String password) => _guard(() async {
    final user = _auth.currentUser!;
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: password),
    );
    final batch = _db.batch()
      ..delete(_userDoc(user.uid))
      ..delete(_boardDoc(user.uid));
    await batch.commit();
    await user.delete();
  });

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthException(messageFor(e.code));
    } on FirebaseException catch (e) {
      throw AuthException('Erro no servidor: ${e.message ?? e.code}');
    }
  }

  @visibleForTesting
  static String messageFor(String code) => switch (code) {
    'invalid-email' => 'E-mail inválido.',
    'user-disabled' => 'Essa conta foi desativada.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'E-mail ou senha inválidos.',
    'email-already-in-use' => 'Já existe uma conta com esse e-mail.',
    'weak-password' => 'Senha fraca: use pelo menos 6 caracteres.',
    'too-many-requests' =>
      'Muitas tentativas. Tente de novo em alguns minutos.',
    'network-request-failed' => 'Sem conexão com a internet.',
    'requires-recent-login' =>
      'Por segurança, entre de novo e repita a operação.',
    _ => 'Não foi possível concluir ($code).',
  };

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
