import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokequiz/models/quiz.dart';
import 'package:pokequiz/screens/whos_that_screen.dart';

void main() {
  testWidgets('modo infinito mostra vidas, encerrar e segue após responder', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: WhosThatScreen(endlessLevel: QuizLevel.full)),
    );
    expect(find.text('Level 1 • Infinito'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNWidgets(3));
    expect(find.text('Encerrar'), findsOneWidget);

    // Responde a primeira alternativa e avança.
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pump();
    final wrong = find.textContaining('Era o').evaluate().isNotEmpty;
    expect(find.byIcon(Icons.favorite), findsNWidgets(wrong ? 2 : 3));
    expect(find.byIcon(Icons.favorite_border), findsNWidgets(wrong ? 1 : 0));
    await tester.tap(find.text('Próximo'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(OutlinedButton), findsNWidgets(3));
  });

  testWidgets('tempo esgotado conta como erro e tira uma vida', (tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(home: WhosThatScreen(endlessLevel: QuizLevel.full)),
    );
    await tester.pump(const Duration(seconds: 11));
    expect(find.text('Tempo esgotado!'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNWidgets(2));
    expect(find.text('Próximo'), findsOneWidget);
  });
}
