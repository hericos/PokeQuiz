// Configuração do Firebase (projeto pokequiz-575ea), montada a partir do
// android/app/google-services.json. Estes valores não são segredos: o acesso
// aos dados é protegido pelas regras em firestore.rules.
//
// Para adicionar o iOS no futuro: registre o app iOS no console e rode
// `flutterfire configure --project=pokequiz-575ea`, que regenera este arquivo.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return android;
    }
    throw UnsupportedError(
      'Firebase configurado apenas para Android. Registre o app iOS no '
      'console e rode "flutterfire configure".',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCjEu3LGxSLrLdMdf2EKwaPNYsqxRwg92c',
    appId: '1:442550622701:android:bd8dcd4389bdb84e2f2fe4',
    messagingSenderId: '442550622701',
    projectId: 'pokequiz-575ea',
    storageBucket: 'pokequiz-575ea.firebasestorage.app',
  );
}
