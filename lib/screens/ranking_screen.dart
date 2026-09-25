import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quiz.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/user_avatar.dart';

class RankingScreen extends StatelessWidget {
  const RankingScreen({super.key, this.initialLevel = 0});

  /// 0 = ranking geral, 1..4 = level.
  final int initialLevel;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: QuizLevel.values.length + 1,
      initialIndex: initialLevel,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ranking'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              const Tab(text: 'Geral'),
              for (final l in QuizLevel.values) Tab(text: l.label),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _RankingList(level: 0),
            for (final l in QuizLevel.values) _RankingList(level: l.number),
          ],
        ),
      ),
    );
  }
}

class _RankingList extends StatefulWidget {
  const _RankingList({required this.level});

  final int level;

  @override
  State<_RankingList> createState() => _RankingListState();
}

class _RankingListState extends State<_RankingList> {
  late final Future<List<RankingEntry>> _entries;

  @override
  void initState() {
    super.initState();
    final db = context.read<DatabaseService>();
    _entries = widget.level == 0 ? db.overallRanking() : db.levelRanking(widget.level);
  }

  @override
  Widget build(BuildContext context) {
    final me = context.read<AuthService>().currentUser?.id;
    return FutureBuilder<List<RankingEntry>>(
      future: _entries,
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final entries = snap.data!;
        if (entries.isEmpty) {
          return const Center(child: Text('Ninguém jogou ainda. Seja o primeiro!'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(8),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final e = entries[i];
            final medal = switch (i) {
              0 => '🥇',
              1 => '🥈',
              2 => '🥉',
              _ => '${i + 1}º',
            };
            return ListTile(
              selected: e.userId == me,
              leading: SizedBox(
                width: 90,
                child: Row(children: [
                  SizedBox(
                      width: 36,
                      child: Text(medal,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20))),
                  const SizedBox(width: 6),
                  UserAvatar(name: e.name, photo: e.photo, radius: 20),
                ]),
              ),
              title: Text(e.name),
              subtitle: Text(widget.level == 0
                  ? trainerTitle(e.score)
                  : '${e.correct ?? 0}/10 acertos (melhor rodada)'),
              trailing: Text('${e.score} pts',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            );
          },
        );
      },
    );
  }
}
