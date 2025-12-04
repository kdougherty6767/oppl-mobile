import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/match_model.dart';
import '../providers/selection_providers.dart';
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
  StreamSubscription<Match?>? _matchSub;

  @override
  void initState() {
    super.initState();
    _subscribeToMatch();
  }

  @override
  void dispose() {
    _matchSub?.cancel();
    super.dispose();
  }

  void _subscribeToMatch() {
    _matchSub?.cancel();
    _matchSub = ref.read(matchServiceProvider).watchMatch(widget.matchId).listen((m) async {
      if (!mounted) return;
      if (m == null) {
        setState(() {
          _match = null;
          _loading = false;
        });
        return;
      }
      await _loadFromMatch(m, forceServer: false);
    });
  }

  Future<void> _load({bool forceServer = false}) async {
    final m = await ref.read(matchServiceProvider).fetchMatch(widget.matchId, serverOnly: forceServer);
    if (m != null) {
      await _loadFromMatch(m, forceServer: forceServer);
    } else {
      if (!mounted) return;
      setState(() {
        _match = null;
        _loading = false;
      });
    }
  }

  Future<void> _loadFromMatch(Match m, {bool forceServer = false}) async {
    debugPrint('[Score] load start forceServer=$forceServer matchId=${m.id}');
    setState(() => _loading = true);
    final playerSvc = ref.read(playerServiceProvider);
    final homePlayers = forceServer
        ? await playerSvc.fetchPlayersForTeam(m.homeTeamId)
        : await playerSvc.watchPlayersForTeam(m.homeTeamId).first;
    final awayPlayers = forceServer
        ? await playerSvc.fetchPlayersForTeam(m.awayTeamId)
        : await playerSvc.watchPlayersForTeam(m.awayTeamId).first;
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
    if (!mounted) return;
    setState(() {
      _match = m;
      _playerNameById = playerNameById;
      _loading = false;
    });
    debugPrint('[Score] load complete match=${m.id} players=${_playerNameById.length}');
  }

  Future<void> _saveScore({
    required int roundIdx,
    required int gameIdx,
    required int? homeScore,
    required int? awayScore,
    required bool br,
  }) async {
    if (_match == null) return;

    // Validation: no ties, no 9s, enforce caps
    if (homeScore != null && awayScore != null) {
      if (homeScore == awayScore) {
        _showMessage('Scores cannot tie.');
        return;
      }
      if (homeScore == 9 || awayScore == 9) {
        _showMessage('Score of 9 is not allowed.');
        return;
      }
    }

    setState(() => _saving = true);
    final payload = Map<String, dynamic>.from(_match!.scorecard?['payload'] ?? {});
    final rounds = (payload['rounds'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    final games = List<dynamic>.from(rounds[roundIdx]['games'] as List);
    final game = Map<String, dynamic>.from(games[gameIdx]);
    final homeCap = game['homeShortHandCap'] == true || game['shortHandedWinCap'] == true;
    final awayCap = game['awayShortHandCap'] == true || game['shortHandedWinCap'] == true;
    final homeWinValue = homeCap ? 8 : 10;
    final awayWinValue = awayCap ? 8 : 10;

    // Enforce winner scores
    if (homeScore != null && awayScore != null) {
      if (homeScore > awayScore && homeScore != homeWinValue) {
        _showMessage('Home win must be ${homeWinValue == 8 ? "8" : "10"} points.');
        setState(() => _saving = false);
        return;
      }
      if (awayScore > homeScore && awayScore != awayWinValue) {
        _showMessage('Away win must be ${awayWinValue == 8 ? "8" : "10"} points.');
        setState(() => _saving = false);
        return;
      }
    }

    game['homeScore'] = homeScore;
    game['awayScore'] = awayScore;
    if (homeScore != null && awayScore != null && homeScore != awayScore && br) {
      game['homeBreakRun'] = homeScore > awayScore;
      game['awayBreakRun'] = awayScore > homeScore;
    } else {
      game['homeBreakRun'] = false;
      game['awayBreakRun'] = false;
    }
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

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openScoreDialog(
    int roundIdx,
    int gameIdx,
    Map<String, dynamic> game,
    bool isHomeTeam,
  ) {
    final initialHome = game['homeScore'] as int?;
    final initialAway = game['awayScore'] as int?;
    final homeCap = game['homeShortHandCap'] == true || game['shortHandedWinCap'] == true;
    final awayCap = game['awayShortHandCap'] == true || game['shortHandedWinCap'] == true;
    final myCap = isHomeTeam ? homeCap : awayCap;
    final oppCap = isHomeTeam ? awayCap : homeCap;

    final myWinValue = myCap ? 8 : 10;
    final oppWinValue = oppCap ? 8 : 10;

    List<int> myOptions = List.generate(8, (i) => i); // 0..7
    myOptions.add(myWinValue);
    myOptions = myOptions.where((v) => v != 9).toSet().toList()..sort();

    final myInitial = isHomeTeam ? initialHome : initialAway;
    final oppInitial = isHomeTeam ? initialAway : initialHome;
    int? myScore = myInitial;
    int? oppScore = oppInitial;
    bool br = (game['homeBreakRun'] == true) || (game['awayBreakRun'] == true);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Enter Score'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: myScore,
                    decoration: InputDecoration(
                      labelText: isHomeTeam ? 'Your score (Home)' : 'Your score (Away)',
                    ),
                    items: myOptions
                        .map((v) => DropdownMenuItem(value: v, child: Text(v.toString())))
                        .toList(),
                    onChanged: (v) => setLocalState(() => myScore = v),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Opponent score: ${oppScore?.toString() ?? "-"} '
                    '(only ${isHomeTeam ? "away" : "home"} can edit)',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Checkbox(
                        value: br,
                        onChanged: (v) => setLocalState(() => br = v ?? false),
                      ),
                      const Text('Break & Run'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Win = ${myWinValue == 8 ? "8 (short-handed cap)" : "10"}, '
                    'Lose = 0-7, no ties, no 9.',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                    final initialOpponent = oppInitial;
                    final initialMine = myInitial;
                    final myFinal = myScore ?? initialMine;
                    final oppFinal = oppScore ?? initialOpponent;
                    if (myFinal == null) {
                      _showMessage('Pick a score.');
                      return;
                    }
                    Navigator.of(context).pop();
                    _saveScore(
                      roundIdx: roundIdx,
                      gameIdx: gameIdx,
                      homeScore: isHomeTeam ? myFinal : oppFinal,
                      awayScore: isHomeTeam ? oppFinal : myFinal,
                      br: br,
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
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
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    final isHomeTeam = selectedTeamId == null ? true : selectedTeamId == _match!.homeTeamId;

    return Scaffold(
      appBar: AppBar(
        title: Text('Score: ${_match!.homeTeamName} vs ${_match!.awayTeamName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload',
            onPressed: () => _load(forceServer: true),
          ),
          TextButton(
            onPressed: () async {
              final result = await context.push('/lineup/${_match!.id}');
              // small delay to allow Firestore write to land, then force server reload
              await Future.delayed(const Duration(milliseconds: 250));
              await _load(forceServer: true);
            },
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
                        _GameCard(
                          game: games[i],
                          gameNumber: games[i]['gameNumber'] as int?,
                          homeName: _playerNameById[games[i]['homePlayerId']] ?? '-',
                          awayName: _playerNameById[games[i]['awayPlayerId']] ?? '-',
                          onTap: () => _openScoreDialog(roundIdx, i, games[i], isHomeTeam),
                          homeTeamName: _match!.homeTeamName,
                          awayTeamName: _match!.awayTeamName,
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
        if (gm['homeScore'] == null || gm['awayScore'] == null) return false;
        if (gm['homeScore'] == gm['awayScore']) return false;
      }
    }
    return true;
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.game,
    required this.gameNumber,
    required this.homeName,
    required this.awayName,
    required this.onTap,
    required this.homeTeamName,
    required this.awayTeamName,
  });

  final Map<String, dynamic> game;
  final int? gameNumber;
  final String homeName;
  final String awayName;
  final VoidCallback onTap;
  final String homeTeamName;
  final String awayTeamName;

  @override
  Widget build(BuildContext context) {
    final homeScore = game['homeScore'] as int?;
    final awayScore = game['awayScore'] as int?;
    final breakerKey = game['breaker'];
    final breakerName = breakerKey == 'home'
        ? homeName
        : breakerKey == 'away'
            ? awayName
            : null;

    String status = 'Not started';
    Color statusColor = Colors.grey;
    String? winner;
    if (homeScore != null && awayScore != null) {
      if (homeScore > awayScore) {
        winner = homeName;
      } else if (awayScore > homeScore) {
        winner = awayName;
      } else {
        winner = 'Tie';
      }
      status = 'Complete';
      statusColor = Colors.green;
    } else if (homeScore != null || awayScore != null) {
      final waiting = homeScore == null ? homeTeamName : awayTeamName;
      status = 'Waiting for $waiting';
      statusColor = Colors.orange;
    }

    final hasBreakRun = game['homeBreakRun'] == true || game['awayBreakRun'] == true;

    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: statusColor.withOpacity(0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Game ${gameNumber ?? "-"}', style: Theme.of(context).textTheme.titleSmall),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('$homeName vs $awayName', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              '${homeScore ?? "-"} - ${awayScore ?? "-"}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                if (breakerName != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports, size: 16),
                        const SizedBox(width: 4),
                        Text('Break: $breakerName'),
                      ],
                    ),
                  ),
                if (hasBreakRun)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.flash_on, size: 16),
                      SizedBox(width: 4),
                      Text('Break & Run'),
                    ],
                  ),
              ],
            ),
            if (winner != null) ...[
              const SizedBox(height: 6),
              Text('Winner: $winner', style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
    );
  }
}
