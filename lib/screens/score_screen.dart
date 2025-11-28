import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/match_model.dart';
import '../services/match_service.dart';
import '../services/player_service.dart';
import '../services/user_service.dart';

class ScoreScreen extends ConsumerStatefulWidget {
  const ScoreScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends ConsumerState<ScoreScreen> {
  Match? _match;
  bool _loading = true;
  bool _saving = false;
  Map<String, String> _playerNameById = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final m = await ref.read(matchServiceProvider).fetchMatch(widget.matchId);
    if (m != null) {
      final homePlayers =
          await ref.read(playerServiceProvider).watchPlayersForTeam(m.homeTeamId).first;
      final awayPlayers =
          await ref.read(playerServiceProvider).watchPlayersForTeam(m.awayTeamId).first;
      final allPlayers = [...homePlayers, ...awayPlayers];
      final userSvc = ref.read(userServiceProvider);
      final userIds = allPlayers.map((p) => p.userId).toSet();
      final userMap = <String, String>{};
      for (final uid in userIds) {
        final u = await userSvc.fetchUser(uid);
        if (u != null) {
          final name = [u.firstName, u.lastName]
              .where((e) => (e ?? '').isNotEmpty)
              .join(' ')
              .trim();
          userMap[uid] = name.isNotEmpty ? name : (u.email ?? uid);
        }
      }
      final playerNameById = <String, String>{};
      for (final p in allPlayers) {
        playerNameById[p.id] = userMap[p.userId] ?? p.id;
      }
      _playerNameById = playerNameById;
    }
    setState(() {
      _match = m;
      _loading = false;
    });
  }

  Future<void> _saveScore({
    required int roundIdx,
    required int gameIdx,
    required int homeScore,
    required int awayScore,
    required bool br,
  }) async {
    if (_match == null) return;
    setState(() => _saving = true);
    final payload = Map<String, dynamic>.from(_match!.scorecard?['payload'] ?? {});
    final rounds = (payload['rounds'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    final games = List<dynamic>.from(rounds[roundIdx]['games'] as List);
    final game = Map<String, dynamic>.from(games[gameIdx]);
    game['homeScore'] = homeScore;
    game['awayScore'] = awayScore;
    game['homeBreakRun'] = br && homeScore > awayScore;
    game['awayBreakRun'] = br && awayScore > homeScore;
    games[gameIdx] = game;
    rounds[roundIdx]['games'] = games;
    payload['rounds'] = rounds;
    final newScorecard = Map<String, dynamic>.from(_match!.scorecard ?? {});
    newScorecard['payload'] = payload;
    await ref.read(matchServiceProvider).updateScorecard(_match!.id, newScorecard);
    final status = _allGamesScored(payload) ? 'complete' : 'inProgress';
    await ref.read(matchServiceProvider).updateStatus(_match!.id, status);
    setState(() {
      _match = _match!.copyWith(scorecard: newScorecard, status: status);
      _saving = false;
    });
  }

  void _openScoreDialog(int roundIdx, int gameIdx, Map<String, dynamic> game) {
    final homeController = TextEditingController(
      text: game['homeScore'] == null ? '' : game['homeScore'].toString(),
    );
    final awayController = TextEditingController(
      text: game['awayScore'] == null ? '' : game['awayScore'].toString(),
    );
    bool br = (game['homeBreakRun'] == true) || (game['awayBreakRun'] == true);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Score'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: homeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Home'),
              ),
              TextField(
                controller: awayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Away'),
              ),
              Row(
                children: [
                  Checkbox(
                    value: br,
                    onChanged: (v) {
                      br = v ?? false;
                      setState(() {});
                    },
                  ),
                  const Text('Break & Run'),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final h = int.tryParse(homeController.text) ?? 0;
                final a = int.tryParse(awayController.text) ?? 0;
                Navigator.of(context).pop();
                _saveScore(roundIdx: roundIdx, gameIdx: gameIdx, homeScore: h, awayScore: a, br: br);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_match == null) {
      return const Scaffold(body: Center(child: Text('Match not found')));
    }
    final rounds = _match!.scorecard?['payload']?['rounds'] as List<dynamic>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Score: ${_match!.homeTeamName} vs ${_match!.awayTeamName}'),
        actions: [
          TextButton(
            onPressed: () => context.push('/lineup/${_match!.id}'),
            child: const Text('Edit Lineup', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: rounds.length,
        itemBuilder: (context, roundIdx) {
          final r = rounds[roundIdx] as Map<String, dynamic>;
          final games = (r['games'] as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>).toList();
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Round ${r['roundNumber']}', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      for (var i = 0; i < games.length; i++)
                        ListTile(
                          title: Text(
                              'Game ${games[i]['gameNumber']}: ${_playerNameById[games[i]['homePlayerId']] ?? "-"} vs ${_playerNameById[games[i]['awayPlayerId']] ?? "-"}'),
                          subtitle: Text(
                            '${games[i]['homeScore'] ?? '-'} / ${games[i]['awayScore'] ?? '-'} '
                            '${games[i]['breaker'] != null ? "(Break: ${games[i]['breaker']})" : ""}'
                            '${games[i]['homeBreakRun'] == true || games[i]['awayBreakRun'] == true ? " • BR" : ""}',
                          ),
                          onTap: () => _openScoreDialog(roundIdx, i, games[i]),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _saving
          ? const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(),
              ),
            )
          : null,
    );
  }

  bool _allGamesScored(Map<String, dynamic> payload) {
    final rounds = payload['rounds'] as List<dynamic>? ?? [];
    for (final r in rounds) {
      final games = r['games'] as List<dynamic>? ?? [];
      for (final g in games) {
        final gm = g as Map<String, dynamic>;
        if (gm['homeScore'] == null && gm['awayScore'] == null) return false;
      }
    }
    return true;
  }
}
