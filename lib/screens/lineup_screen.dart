import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/user_model.dart';
import '../providers/selection_providers.dart';
import '../services/match_service.dart';
import '../services/player_service.dart';
import '../services/user_service.dart';

class LineupScreen extends ConsumerStatefulWidget {
  const LineupScreen({super.key, required this.matchId});

  final String matchId;

  @override
  ConsumerState<LineupScreen> createState() => _LineupScreenState();
}

class _LineupScreenState extends ConsumerState<LineupScreen> {
  Match? _match;
  Map<String, Player> _playerById = {};
  Map<String, AppUser> _userById = {};
  bool _loading = true;
  bool _saving = false;
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
    _matchSub = ref.read(matchServiceProvider).watchMatch(widget.matchId).listen((match) async {
      if (!mounted) return;
      if (match == null) {
        setState(() => _loading = false);
        return;
      }
      await _applyMatch(match);
    });
  }

  Future<void> _load() async {
    final match = await ref.read(matchServiceProvider).fetchMatch(widget.matchId);
    if (match != null) {
      await _applyMatch(match);
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _applyMatch(Match match) async {
    final hallSeasonPlayers =
        await ref.read(playerServiceProvider).fetchPlayersForHallSeason(match.hallSeasonId);

    // Also fetch by team to tolerate data that may be missing hallSeasonId
    final homeByTeam = await ref.read(playerServiceProvider).fetchPlayersForTeam(match.homeTeamId);
    final awayByTeam = await ref.read(playerServiceProvider).fetchPlayersForTeam(match.awayTeamId);

    List<Player> homePlayers = [
      ...hallSeasonPlayers.where((p) => p.teamId == match.homeTeamId),
      ...homeByTeam.where((p) => p.hallSeasonId == match.hallSeasonId && p.teamId == match.homeTeamId),
    ];
    List<Player> awayPlayers = [
      ...hallSeasonPlayers.where((p) => p.teamId == match.awayTeamId),
      ...awayByTeam.where((p) => p.hallSeasonId == match.hallSeasonId && p.teamId == match.awayTeamId),
    ];

    homePlayers = _dedupPlayers(homePlayers);
    awayPlayers = _dedupPlayers(awayPlayers);

    debugPrint(
        '[Lineup] match=${match.id} hs=${match.hallSeasonId} home=${match.homeTeamId} away=${match.awayTeamId}');
    debugPrint(
        '[Lineup] hallSeasonPlayers=${hallSeasonPlayers.length} homePlayers=${homePlayers.length} awayPlayers=${awayPlayers.length}');
    for (final p in [...homePlayers, ...awayPlayers]) {
      debugPrint('[Lineup] player ${p.id} user=${p.userId} team=${p.teamId} status=${p.status}');
    }

    final allPlayers = [...homePlayers, ...awayPlayers];
    final userSvc = ref.read(userServiceProvider);
    final ids = allPlayers.map((p) => p.userId).toSet();
    final userMap = <String, AppUser>{};
    for (final uid in ids) {
      final u = await userSvc.fetchUser(uid);
      if (u != null) userMap[uid] = u;
    }
    if (!mounted) return;
    setState(() {
      _match = match;
      _playerById = {for (final p in allPlayers) p.id: p};
      _userById = userMap;
      _loading = false;
    });
  }

  List<String?> _slotsForRound(int roundIdx, bool home) {
    final rounds = _match?.scorecard?['payload']?['rounds'] as List<dynamic>? ?? [];
    if (roundIdx >= rounds.length) return [];
    final slotsKey = home ? 'homeSlots' : 'awaySlots';
    final slots = rounds[roundIdx][slotsKey] as List<dynamic>? ?? [];
    return slots.map<String?>((e) => e as String?).toList();
  }

  bool _gameScored(int roundIdx, int slotIdx, bool home) {
    final rounds = _match?.scorecard?['payload']?['rounds'] as List<dynamic>? ?? [];
    if (roundIdx >= rounds.length) return false;
    final games = rounds[roundIdx]['games'] as List<dynamic>? ?? [];
    for (final gRaw in games) {
      final g = gRaw as Map<String, dynamic>;
      final scored = g['homeScore'] != null || g['awayScore'] != null;
      if (scored) {
        if (home && (g['homeSlot'] as int?) == slotIdx + 1) return true;
        if (!home && (g['awaySlot'] as int?) == slotIdx + 1) return true;
      }
    }
    return false;
  }

  Map<String, dynamic>? _gameFor(int roundIdx, int slotIdx, bool isHome) {
    final rounds = _match?.scorecard?['payload']?['rounds'] as List<dynamic>? ?? [];
    if (roundIdx >= rounds.length) return null;
    final games = rounds[roundIdx]['games'] as List<dynamic>? ?? [];
    for (final gRaw in games) {
      final g = gRaw as Map<String, dynamic>;
      if (isHome && (g['homeSlot'] as int?) == slotIdx + 1) return g;
      if (!isHome && (g['awaySlot'] as int?) == slotIdx + 1) return g;
    }
    return null;
  }

  Future<void> _setSlot({
    required bool isHome,
    required int slotIdx,
    required int roundIdx,
    required String? playerId,
    required bool autofillAllRounds,
  }) async {
    if (_match == null) return;
    final payload = Map<String, dynamic>.from(_match!.scorecard?['payload'] ?? {});
    final rounds = (payload['rounds'] as List).map((e) => Map<String, dynamic>.from(e)).toList();

    for (var r = 0; r < rounds.length; r++) {
      if (!autofillAllRounds && r != roundIdx) continue;
      if (autofillAllRounds && _gameScored(r, slotIdx, isHome)) continue; // respect locked games
      final slotsKey = isHome ? 'homeSlots' : 'awaySlots';
      final slots = List<dynamic>.from(rounds[r][slotsKey] as List);

      // Disallow duplicates unless one of the slots is slot 3.
      if (playerId != null) {
        int existingIdx = -1;
        for (var i = 0; i < slots.length; i++) {
          if (i == slotIdx) continue;
          if (slots[i] != null && slots[i] == playerId) {
            existingIdx = i;
            break;
          }
        }
        final conflicting = existingIdx != -1 && existingIdx != 2 && slotIdx != 2;
        if (conflicting) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Player already in this round. Only slot 3 may repeat.')),
            );
          }
          return;
        }
      }

      final games = List<dynamic>.from(rounds[r]['games'] as List);
      slots[slotIdx] = playerId;
      rounds[r][slotsKey] = slots;
      for (var g = 0; g < games.length; g++) {
        final game = Map<String, dynamic>.from(games[g]);
        if (isHome && (game['homeSlot'] as int?) == slotIdx + 1) {
          game['homePlayerId'] = playerId;
        }
        if (!isHome && (game['awaySlot'] as int?) == slotIdx + 1) {
          game['awayPlayerId'] = playerId;
        }
        games[g] = game;
      }
      rounds[r]['games'] = games;
    }

    payload['rounds'] = _applyShortHandFlags(rounds);
    final newScorecard = Map<String, dynamic>.from(_match!.scorecard ?? {});
    newScorecard['payload'] = payload;
    await ref.read(matchServiceProvider).updateScorecard(_match!.id, newScorecard);
    setState(() {
      _match = _match!.copyWith(scorecard: newScorecard);
    });
  }

  Future<void> _quickAssignSlot({
    required bool isHome,
    required int slotIdx,
    required List<Player> options,
  }) async {
    if (options.isEmpty) return;
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView(
          children: [
            const ListTile(
              title: Text('Quick assign to all rounds'),
            ),
            ...options.map(
              (p) => ListTile(
                title: Text(_playerName(p.id)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _setSlot(
                    isHome: isHome,
                    slotIdx: slotIdx,
                    roundIdx: 0,
                    playerId: p.id,
                    autofillAllRounds: true,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveLineup() async {
    if (_match == null) return;
    setState(() => _saving = true);
    await ref.read(matchServiceProvider).updateStatus(_match!.id, 'inProgress');
    setState(() => _saving = false);
    if (!mounted) return;
    // Give Firestore a brief moment to finish the write before returning to score.
    await Future.delayed(const Duration(milliseconds: 200));
    if (context.canPop()) {
      context.pop(true);
    } else {
      context.go('/score/${_match!.id}');
    }
  }

  String _playerName(String? playerId) {
    if (playerId == null) return '-';
    final p = _playerById[playerId];
    if (p == null) return playerId;
    final u = _userById[p.userId];
    final name = [u?.firstName, u?.lastName].where((e) => (e ?? '').isNotEmpty).join(' ').trim();
    return name.isNotEmpty ? name : (u?.email ?? playerId);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_match == null) {
      return const Scaffold(body: Center(child: Text('Match not found')));
    }

    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    final myTeamId = selectedTeamId ?? _match!.homeTeamId;
    final isHomeTeam = myTeamId == _match!.homeTeamId;

    final payload = _match!.scorecard?['payload'] as Map<String, dynamic>? ?? {};
    final rounds = payload['rounds'] as List<dynamic>? ?? [];
    final playersPerRound = payload['playersPerRound'] as int? ?? 1;

    final myOptions = _playerById.values
        .where((p) => p.teamId == (isHomeTeam ? _match!.homeTeamId : _match!.awayTeamId))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Lineup: ${_match!.homeTeamName} vs ${_match!.awayTeamName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _teamGrid(
            context: context,
            rounds: rounds,
            playersPerRound: playersPerRound,
            options: myOptions,
            editable: true,
            isHome: isHomeTeam,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: _saving ? null : _saveLineup,
            child: _saving ? const CircularProgressIndicator() : const Text('Done - Start Scoring'),
          ),
        ),
      ),
    );
  }

  Widget _teamGrid({
    required BuildContext context,
    required List<dynamic> rounds,
    required int playersPerRound,
    required List<Player> options,
    required bool editable,
    required bool isHome,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your lineup (shows opponent if set)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: math.max(MediaQuery.of(context).size.width, 80 + rounds.length * 160.0),
                child: Table(
                  defaultColumnWidth: const FixedColumnWidth(160),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: FixedColumnWidth(100),
                  },
                  children: [
                    TableRow(
                      children: [
                        const SizedBox(),
                        ...List.generate(
                          rounds.length,
                          (ri) => Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text('R${ri + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    ...List.generate(playersPerRound, (slotIdx) {
                      return TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: editable
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    ),
                                    onPressed: () => _quickAssignSlot(
                                      isHome: isHome,
                                      slotIdx: slotIdx,
                                      options: options,
                                    ),
                                    child: Text('Slot ${slotIdx + 1}'),
                                  )
                                : Text('Slot ${slotIdx + 1}'),
                          ),
                          ...List.generate(rounds.length, (roundIdx) {
                            final slots = _slotsForRound(roundIdx, isHome);
                            final value = slots.isNotEmpty ? slots[slotIdx] : null;
                            final currentGame = _gameFor(roundIdx, slotIdx, isHome);
                            final opponentId = currentGame == null
                                ? null
                                : (isHome ? currentGame['awayPlayerId'] : currentGame['homePlayerId']);
                            final opponentText =
                                opponentId == null ? 'vs Not set' : 'vs ${_playerName(opponentId)}';
                            final disabled = !editable || _gameScored(roundIdx, slotIdx, isHome);
                            return Padding(
                              padding: const EdgeInsets.all(4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  editable
                                      ? DropdownButton<String?>(
                                          isExpanded: true,
                                          isDense: true,
                                          value: value,
                                          items: options
                                              .map(
                                                (p) => DropdownMenuItem(
                                                  value: p.id,
                                                  child: Text(_playerName(p.id),
                                                      overflow: TextOverflow.ellipsis),
                                                ),
                                              )
                                              .toList(),
                                          onChanged: disabled
                                              ? null
                                              : (val) => _setSlot(
                                                    isHome: isHome,
                                                    slotIdx: slotIdx,
                                                    roundIdx: roundIdx,
                                                    playerId: val,
                                                    autofillAllRounds: false,
                                                  ),
                                        )
                                      : Text(_playerName(value)),
                                  const SizedBox(height: 2),
                                  Text(
                                    opponentText,
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (disabled)
                                    const Text(
                                      'Locked (scored)',
                                      style: TextStyle(fontSize: 10, color: Colors.redAccent),
                                    ),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Player> _dedupPlayers(List<Player> players) {
    final seen = <String>{};
    final result = <Player>[];
    for (final p in players) {
      if (seen.add(p.id)) {
        result.add(p);
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _applyShortHandFlags(List<Map<String, dynamic>> rounds) {
    for (var r = 0; r < rounds.length; r++) {
      final round = rounds[r];
      final homeSlots = (round['homeSlots'] as List).map((e) => e as String?).toList();
      final awaySlots = (round['awaySlots'] as List).map((e) => e as String?).toList();

      final homeCap = homeSlots.length >= 3 &&
          homeSlots[2] != null &&
          (homeSlots[2] == homeSlots[0] || homeSlots[2] == homeSlots[1]);
      final awayCap = awaySlots.length >= 3 &&
          awaySlots[2] != null &&
          (awaySlots[2] == awaySlots[0] || awaySlots[2] == awaySlots[1]);

      final games = List<dynamic>.from(round['games'] as List);
      for (var g = 0; g < games.length; g++) {
        final game = Map<String, dynamic>.from(games[g]);
        final homeFlag = homeCap && (game['homeSlot'] as int?) == 3;
        final awayFlag = awayCap && (game['awaySlot'] as int?) == 3;
        game['homeShortHandCap'] = homeFlag;
        game['awayShortHandCap'] = awayFlag;
        game['shortHandedWinCap'] = homeFlag || awayFlag;
        games[g] = game;
      }
      round['games'] = games;
      rounds[r] = round;
    }
    return rounds;
  }
}
