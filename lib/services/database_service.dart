import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/game.dart';
import '../models/quiz.dart';
import '../models/user_profile.dart';

/// Persistência local (SQLite) de usuários e pontuações.
class DatabaseService {
  DatabaseService._(this._db);

  final Database _db;

  static Future<DatabaseService> open() async {
    final path = p.join(await getDatabasesPath(), 'pokequiz.db');
    final db = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL UNIQUE,
            provider TEXT NOT NULL,
            password_hash TEXT,
            salt TEXT,
            name TEXT NOT NULL,
            age INTEGER,
            city TEXT,
            country TEXT,
            favorite_pokemon TEXT,
            bio TEXT,
            photo TEXT,
            created_at INTEGER NOT NULL
          )''');
        await _createGameScores(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // v1 guardava pontuação por level; agora cada jogo é uma partida só.
          await db.execute('DROP TABLE IF EXISTS scores');
          await _createGameScores(db);
        }
      },
    );
    return DatabaseService._(db);
  }

  static Future<void> _createGameScores(Database db) async {
    await db.execute('''
      CREATE TABLE game_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        game TEXT NOT NULL,
        score INTEGER NOT NULL,
        detail TEXT,
        played_at INTEGER NOT NULL
      )''');
    await db.execute(
      'CREATE INDEX idx_game_scores ON game_scores(game, score DESC)',
    );
  }

  // ---------- Usuários ----------

  Future<Map<String, Object?>?> findUserRowByEmail(String email) async {
    final rows = await _db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<UserProfile?> findUserById(int id) async {
    final rows = await _db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return rows.isEmpty ? null : UserProfile.fromMap(rows.first);
  }

  Future<int> insertUser({
    required String email,
    required AuthProvider provider,
    required String name,
    String? passwordHash,
    String? salt,
    String? photo,
  }) {
    return _db.insert('users', {
      'email': email.toLowerCase(),
      'provider': provider.name,
      'name': name,
      'password_hash': passwordHash,
      'salt': salt,
      'photo': photo,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateProfile(UserProfile user) => _db.update(
    'users',
    user.toProfileMap(),
    where: 'id = ?',
    whereArgs: [user.id],
  );

  // ---------- Pontuações ----------

  Future<void> insertScore(
    int userId,
    GameId game,
    int score, {
    String? detail,
  }) => _db.insert('game_scores', {
    'user_id': userId,
    'game': game.name,
    'score': score,
    'detail': detail,
    'played_at': DateTime.now().millisecondsSinceEpoch,
  });

  /// Melhor partida de cada usuário em um jogo. (No SQLite, colunas "soltas"
  /// junto de MAX() vêm da mesma linha do máximo.)
  Future<List<RankingEntry>> gameRanking(GameId game, {int limit = 100}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT u.id AS user_id, u.name, u.photo,
             MAX(s.score) AS score, s.detail AS detail
      FROM game_scores s JOIN users u ON u.id = s.user_id
      WHERE s.game = ?
      GROUP BY u.id
      ORDER BY score DESC, u.name ASC
      LIMIT ?''',
      [game.name, limit],
    );
    return rows.map(_rankingFromRow).toList();
  }

  /// Soma dos recordes de cada jogo, por usuário.
  Future<List<RankingEntry>> overallRanking({int limit = 100}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT u.id AS user_id, u.name, u.photo, SUM(b.best) AS score
      FROM (SELECT user_id, game, MAX(score) AS best
            FROM game_scores GROUP BY user_id, game) b
      JOIN users u ON u.id = b.user_id
      GROUP BY u.id
      ORDER BY score DESC, u.name ASC
      LIMIT ?''',
      [limit],
    );
    return rows.map(_rankingFromRow).toList();
  }

  /// Recorde do usuário em cada jogo.
  Future<Map<GameId, int>> bestScoresFor(int userId) async {
    final rows = await _db.rawQuery(
      'SELECT game, MAX(score) AS best FROM game_scores WHERE user_id = ? GROUP BY game',
      [userId],
    );
    final games = GameId.values.asNameMap();
    return {
      for (final r in rows)
        if (games.containsKey(r['game'])) games[r['game']]!: r['best'] as int,
    };
  }

  RankingEntry _rankingFromRow(Map<String, Object?> r) => RankingEntry(
    userId: r['user_id'] as int,
    name: r['name'] as String,
    photo: r['photo'] as String?,
    score: (r['score'] as num).toInt(),
    detail: r['detail'] as String?,
  );
}
