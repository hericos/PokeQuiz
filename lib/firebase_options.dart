// PLACEHOLDER — este arquivo é substituído ao rodar:
//
//   flutterfire configure --project=<seu-projeto> --platforms=android,ios
//
// (veja o README). Enquanto isso, o app abre uma tela explicando a configuração.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase ainda não configurado. Rode "flutterfire configure".',
  );
}
