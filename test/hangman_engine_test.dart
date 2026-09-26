import 'package:flutter_test/flutter_test.dart';
import 'package:pokequiz/models/pokemon.dart';
import 'package:pokequiz/services/hangman_engine.dart';

HangmanRound roundFor(String name) => HangmanRound(Pokemon.byName(name)!);

void main() {
  test('vitória ao descobrir todas as letras', () {
    final r = roundFor('Ekans');
    expect(r.masked, '_____');
    for (final l in 'EKANS'.split('')) {
      expect(r.guess(l), isTrue);
    }
    expect(r.isWon, isTrue);
    expect(r.errors, 0);
    expect(r.points, 10 + 5 * 5);
  });

  test('derrota com 5 erros; letra repetida não conta de novo', () {
    final r = roundFor('Mew');
    expect(r.guess('Z'), isFalse);
    expect(r.guess('z'), isFalse);
    expect(r.errors, 1);
    for (final l in 'QXYV'.split('')) {
      r.guess(l);
    }
    expect(r.isLost, isTrue);
    expect(r.points, 0);
    expect(r.masked, 'Mew', reason: 'na derrota o nome é revelado');
    r.guess('M');
    expect(r.guessed, isNot(contains('M')), reason: 'rodada encerrada');
  });

  test(
    'pontuação, espaços, dígitos e acentos já vêm revelados/normalizados',
    () {
      expect(roundFor('Mr. Mime').masked, '__. ____');
      expect(roundFor('Porygon2').lettersToFind, {
        'P',
        'O',
        'R',
        'Y',
        'G',
        'N',
      });
      expect(roundFor('Nidoran♀').masked, '_______♀');
      final flabebe = roundFor('Flabébé');
      expect(flabebe.lettersToFind, {'F', 'L', 'A', 'B', 'E'});
      flabebe.guess('E');
      expect(flabebe.masked, '____é_é');
    },
  );

  test('tempo esgotado conta como erro', () {
    final r = roundFor('Mew');
    r.timeout();
    r.guess('Z');
    expect(r.errors, 2);
    expect(r.livesLeft, 3);
    for (var i = 0; i < 3; i++) {
      r.timeout();
    }
    expect(r.isLost, isTrue);
    r.timeout();
    expect(r.errors, 5, reason: 'rodada encerrada não soma mais erros');
  });
}
