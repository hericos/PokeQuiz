import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/score_service.dart';
import 'theme.dart';
import 'widgets/poke_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(_FirebaseNotConfiguredApp(error: e));
    return;
  }

  runApp(
    MultiProvider(
      providers: [
        Provider<ScoreService>(create: (_) => ScoreService()),
        ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
      ],
      child: const PokeQuizApp(),
    ),
  );
}

class PokeQuizApp extends StatelessWidget {
  const PokeQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeQuiz',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: _limitWidth,
      home: Consumer<AuthService>(
        builder: (context, auth, _) {
          if (auth.initializing) {
            return const PokeScaffold(
              body: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
          }
          return auth.isLoggedIn ? const HomeShell() : const LoginScreen();
        },
      ),
    );
  }
}

/// Na web/tablet, mantém o app com largura de celular no centro da tela,
/// com o fundo de pokébolas preenchendo as laterais.
Widget _limitWidth(BuildContext context, Widget? child) => PokeBackground(
  dark: true,
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 24)],
        ),
        child: child,
      ),
    ),
  ),
);

/// Mostrado quando o app foi compilado sem a configuração do Firebase.
class _FirebaseNotConfiguredApp extends StatelessWidget {
  const _FirebaseNotConfiguredApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      builder: _limitWidth,
      home: PokeScaffold(
        body: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: 8),
                  const Text(
                    'Firebase não configurado',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Rode "flutterfire configure" no projeto e gere o app de novo. '
                    'O passo a passo está no README.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$error',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
