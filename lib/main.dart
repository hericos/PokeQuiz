import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await DatabaseService.open();
  final prefs = await SharedPreferences.getInstance();
  final auth = AuthService(db, prefs);
  await auth.restoreSession();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: db),
        ChangeNotifierProvider<AuthService>.value(value: auth),
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
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: Consumer<AuthService>(
        builder: (context, auth, _) =>
            auth.isLoggedIn ? const HomeScreen() : const LoginScreen(),
      ),
    );
  }
}
