import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game.dart';
import '../models/quiz.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/user_avatar.dart';

/// Ranking geral (soma dos recordes) ou de um jogo específico.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  /// null = ranking geral.
  GameId? _game;
  late Future<List<RankingEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final db = context.read<DatabaseService>();
    _entries = _game == null ? db.overallRanking() : db.gameRanking(_game!);
  }

  void _select(GameId? game) => setState(() {
    _game = game;
    _load();
  });

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthService>().currentUser?.id;
    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _chip('Geral', null),
              for (final g in GameId.values) _chip(g.title, g),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<RankingEntry>>(
            future: _entries,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              final entries = snap.data!;
              if (entries.isEmpty) {
                return const Center(
                  child: Text(
                    'Ninguém jogou ainda. Seja o primeiro!',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: entries.length,
                itemBuilder: (context, i) =>
                    _tile(entries[i], i, entries[i].userId == me),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(String label, GameId? game) => Padding(
    padding: const EdgeInsets.only(right: 8),
    child: ChoiceChip(
      label: Text(label),
      selected: _game == game,
      onSelected: (_) => _select(game),
      backgroundColor: Colors.white70,
      selectedColor: Colors.white,
      side: BorderSide.none,
    ),
  );

  Widget _tile(RankingEntry e, int i, bool isMe) {
    final medal = switch (i) {
      0 => '🥇',
      1 => '🥈',
      2 => '🥉',
      _ => '${i + 1}º',
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: isMe
          ? RoundedRectangleBorder(
              side: const BorderSide(color: Colors.amber, width: 3),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: SizedBox(
          width: 88,
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Text(
                  medal,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: 6),
              UserAvatar(name: e.name, photo: e.photo, radius: 20),
            ],
          ),
        ),
        title: Text(
          e.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _game == null ? trainerTitle(e.score) : (e.detail ?? ''),
        ),
        trailing: Text(
          '${e.score} pts',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
