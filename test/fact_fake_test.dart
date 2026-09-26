import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokequiz/data/ash_facts.dart';
import 'package:pokequiz/screens/fact_fake_screen.dart';

void main() {
  test('50 afirmações únicas, com explicação e mistura de fatos e fakes', () {
    expect(ashFacts, hasLength(50));
    expect(ashFacts.map((f) => f.$1).toSet(), hasLength(50));
    expect(ashFacts.every((f) => f.$3.isNotEmpty), isTrue);
    final facts = ashFacts.where((f) => f.$2).length;
    expect(facts, inInclusiveRange(20, 30));
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: FactFakeScreen()));
  }

  testWidgets('responder mostra a explicação e desconta vida se errar', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.byIcon(Icons.favorite), findsNWidgets(3));
    expect(find.text('10s'), findsOneWidget);
    await tester.tap(find.text('FATO'));
    await tester.pump();
    final wrong = find.text('Errou!').evaluate().isNotEmpty;
    expect(find.byIcon(Icons.favorite), findsNWidgets(wrong ? 2 : 3));
    expect(find.textContaining('É F'), findsOneWidget);
    await tester.tap(find.text('Próxima'));
    await tester.pump();
    expect(find.text('Afirmação 2 de 50'), findsOneWidget);
  });

  testWidgets('tempo esgotado conta como erro', (tester) async {
    await pumpScreen(tester);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('5s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    expect(find.text('Tempo esgotado!'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNWidgets(2));
    expect(find.text('FATO'), findsNothing);
  });
}
