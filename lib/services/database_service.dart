import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

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
      version: 1,
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
        await db.execute('''
          CREATE TABLE scores (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
            level INTEGER NOT NULL,
            correct INTEGER NOT NULL,
            total INTEGER NOT NULL,
            score INTEGER NOT NULL,
            elapsed_ms INTEGER NOT NULL,
            played_at INTEGER NOT NULL
          )''');
        await db.execute('CREATE INDEX idx_scores_level ON scores(level, score DESC)');
      },
    );
    return DatabaseService._(db);
  }

  // ---------- Usuários ----------

  Future<Map<String, Object?>?> findUserRowByEmail(String email) async {
    final rows = await _db.query('users',
        where: 'email = ?', whereArgs: [email.toLowerCase()], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<UserProfile?> findUserById(int id) async {
    final rows =
        await _db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
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

  Future<void> updateProfile(UserProfile user) =>
      _db.update('users', user.toProfileMap(),
          where: 'id = ?', whereArgs: [user.id]);

  // ---------- Pontuações ----------

  Future<void> insertScore(int userId, QuizResult r) => _db.insert('scores', {
        'user_id': userId,
        'level': r.level.number,
        'correct': r.correct,
        'total': r.total,
        'score': r.score,
        'elapsed_ms': r.elapsed.inMilliseconds,
        'played_at': DateTime.now().millisecondsSinceEpoch,
      });

  /// Melhor pontuação de cada usuário em um level. (No SQLite, colunas
  /// "soltas" junto de MAX() vêm da mesma linha do máximo.)
  Future<List<RankingEntry>> levelRanking(int level, {int limit = 50}) async {
    final rows = await _db.rawQuery('''
      SELECT u.id AS user_id, u.name, u.photo,
             MAX(s.score) AS score, s.correct AS correct
      FROM scores s JOIN users u ON u.id = s.user_id
      WHERE s.level = ?
      GROUP BY u.id
      ORDER BY score DESC, u.name ASC
      LIMIT ?''', [level, limit]);
    return rows.map(_rankingFromRow).toList();
  }

  /// Soma das melhores pontuações de cada level, por usuário.
  Future<List<RankingEntry>> overallRanking({int limit = 50}) async {
    final rows = await _db.rawQuery('''
      SELECT u.id AS user_id, u.name, u.photo, SUM(b.best) AS score
      FROM (SELECT user_id, level, MAX(score) AS best
            FROM scores GROUP BY user_id, level) b
      JOIN users u ON u.id = b.user_id
      GROUP BY u.id
      ORDER BY score DESC, u.name ASC
      LIMIT ?''', [limit]);
    return rows.map(_rankingFromRow).toList();
  }

  /// Melhor pontuação do usuário por level (level -> score).
  Future<Map<int, int>> bestScoresFor(int userId) async {
    final rows = await _db.rawQuery(
        'SELECT level, MAX(score) AS best FROM scores WHERE user_id = ? GROUP BY level',
        [userId]);
    return {for (final r in rows) r['level'] as int: r['best'] as int};
  }

  RankingEntry _rankingFromRow(Map<String, Object?> r) => RankingEntry(
        userId: r['user_id'] as int,
        name: r['name'] as String,
        photo: r['photo'] as String?,
        score: (r['score'] as num).toInt(),
        correct: r['correct'] as int?,
      );
}
