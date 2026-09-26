import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/game.dart';
import '../models/quiz.dart';

/// Resultado de salvar uma partida.
typedef SubmitResult = ({bool isRecord, int best, int total});

/// Ranking global no Firestore. Cada treinador tem um documento
/// `leaderboard/{uid}` com o recorde de cada jogo e a soma deles:
///
/// ```
/// { name, thumb, total: 1234,
///   best:   { whosThat: 900, hangman: 334 },
///   detail: { whosThat: "32/40 acertos", hangman: "7 Pokémon descobertos" } }
/// ```
class ScoreService {
  ScoreService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _board =>
      _db.collection('leaderboard');

  /// Salva a partida; só grava se for recorde do jogador naquele jogo.
  Future<SubmitResult> submit({
    required String uid,
    required String name,
    required String? thumb,
    required GameId game,
    required int score,
    required String detail,
  }) {
    final ref = _board.doc(uid);
    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final update = applyScore(snap.data(), game, score, detail);
      if (update != null) {
        tx.set(ref, {
          ...update,
          'name': name,
          'thumb': thumb,
        }, SetOptions(merge: true));
      }
      final data = {...?snap.data(), ...?update};
      return (
        isRecord: update != null,
        best: ((data['best'] as Map?)?[game.name] as num?)?.toInt() ?? score,
        total: (data['total'] as num?)?.toInt() ?? 0,
      );
    });
  }

  /// Campos a gravar se [score] superar o recorde atual em [data]; null se não.
  @visibleForTesting
  static Map<String, Object>? applyScore(
    Map<String, dynamic>? data,
    GameId game,
    int score,
    String detail,
  ) {
    final best = Map<String, dynamic>.from((data?['best'] as Map?) ?? {});
    final previous = (best[game.name] as num?)?.toInt();
    if (score <= 0 || (previous != null && score <= previous)) return null;
    final details = Map<String, dynamic>.from((data?['detail'] as Map?) ?? {});
    best[game.name] = score;
    details[game.name] = detail;
    return {
      'best': best,
      'detail': details,
      'total': best.values.fold<int>(0, (a, b) => a + (b as num).toInt()),
    };
  }

  /// Recordes do jogador em cada jogo.
  Future<Map<GameId, int>> bestScoresFor(String uid) async {
    final data = (await _board.doc(uid).get()).data();
    final best = (data?['best'] as Map?) ?? const {};
    return {
      for (final g in GameId.values)
        if (best[g.name] is num) g: (best[g.name] as num).toInt(),
    };
  }

  /// Top 100 de um jogo (ou geral, se [game] for null).
  Future<List<RankingEntry>> ranking(GameId? game, {int limit = 100}) async {
    final field = game == null ? 'total' : 'best.${game.name}';
    final snap = await _board
        .where(field, isGreaterThan: 0)
        .orderBy(field, descending: true)
        .limit(limit)
        .get();
    return [
      for (final doc in snap.docs)
        RankingEntry(
          userId: doc.id,
          name: doc.data()['name'] as String? ?? '?',
          photo: doc.data()['thumb'] as String?,
          score:
              ((game == null
                          ? doc.data()['total']
                          : (doc.data()['best'] as Map?)?[game.name])
                      as num?)
                  ?.toInt() ??
              0,
          detail: game == null
              ? null
              : (doc.data()['detail'] as Map?)?[game.name] as String?,
        ),
    ];
  }

  /// Posição (1 = primeiro) de quem fez [score] no jogo, e total de jogadores.
  Future<({int position, int players})> positionOf(
    GameId game,
    int score,
  ) async {
    final field = 'best.${game.name}';
    final above = await _board.where(field, isGreaterThan: score).count().get();
    final players = await _board.where(field, isGreaterThan: 0).count().get();
    return (position: (above.count ?? 0) + 1, players: players.count ?? 0);
  }
}
