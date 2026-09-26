// Configuração do Firebase (projeto pokequiz-575ea): Android a partir do
// android/app/google-services.json e Web a partir do app "PokeQuiz Web". Estes valores não são segredos: o acesso
// aos dados é protegido pelas regras em firestore.rules.
//
// Para adicionar o iOS no futuro: registre o app iOS no console e rode
// `flutterfire configure --project=pokequiz-575ea`, que regenera este arquivo.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    if (defaultTargetPlatform == TargetPlatform.android) return android;
    throw UnsupportedError(
      'Firebase configurado para Android e Web. Registre o app iOS no '
      'console e rode "flutterfire configure".',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA2O7Sm4Sl9qNx1E7PMUnhB71Fi8Aq0pe8',
    appId: '1:442550622701:web:4f8459b17d53de7b2f2fe4',
    messagingSenderId: '442550622701',
    projectId: 'pokequiz-575ea',
    authDomain: 'pokequiz-575ea.firebaseapp.com',
    storageBucket: 'pokequiz-575ea.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCjEu3LGxSLrLdMdf2EKwaPNYsqxRwg92c',
    appId: '1:442550622701:android:bd8dcd4389bdb84e2f2fe4',
    messagingSenderId: '442550622701',
    projectId: 'pokequiz-575ea',
    storageBucket: 'pokequiz-575ea.firebasestorage.app',
  );
}
