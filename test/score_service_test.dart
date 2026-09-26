import 'package:flutter_test/flutter_test.dart';
import 'package:pokequiz/models/game.dart';
import 'package:pokequiz/services/auth_service.dart';
import 'package:pokequiz/services/score_service.dart';

void main() {
  group('applyScore', () {
    test('primeira partida vira recorde e soma no total', () {
      final u = ScoreService.applyScore(null, GameId.hangman, 45, '3 Pokémon');
      expect(u, {
        'best': {'hangman': 45},
        'detail': {'hangman': '3 Pokémon'},
        'total': 45,
      });
    });

    test('só grava quando supera o recorde; total soma todos os jogos', () {
      final data = {
        'best': {'whosThat': 900, 'hangman': 45},
        'detail': {'whosThat': '30/40', 'hangman': '3'},
        'total': 945,
      };
      expect(ScoreService.applyScore(data, GameId.hangman, 45, 'x'), isNull);
      expect(ScoreService.applyScore(data, GameId.hangman, 10, 'x'), isNull);
      final u = ScoreService.applyScore(data, GameId.hangman, 100, '7')!;
      expect(u['best'], {'whosThat': 900, 'hangman': 100});
      expect(u['detail'], {'whosThat': '30/40', 'hangman': '7'});
      expect(u['total'], 1000);
    });

    test('zero pontos não entra no ranking', () {
      expect(ScoreService.applyScore(null, GameId.whosThat, 0, ''), isNull);
    });
  });

  test('mensagens de erro do Firebase em português', () {
    expect(
      AuthService.messageFor('invalid-credential'),
      'E-mail ou senha inválidos.',
    );
    expect(
      AuthService.messageFor('email-already-in-use'),
      contains('Já existe'),
    );
    expect(AuthService.messageFor('xyz'), contains('xyz'));
  });
}
