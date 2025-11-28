import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/match_model.dart';
import '../models/player_model.dart';
import '../models/user_model.dart';
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

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final match = await ref.read(matchServiceProvider).fetchMatch(widget.matchId);
    if (match == null) {
      setState(() => _loading = false);
      return;
    }
    final homePlayers = await ref.read(playerServiceProvider).watchPlayersForTeam(match.homeTeamId).first;
    final awayPlayers = await ref.read(playerServiceProvider).watchPlayersForTeam(match.awayTeamId).first;
    final allPlayers = [...homePlayers, ...awayPlayers];
    final userSvc = ref.read(userServiceProvider);
    final ids = allPlayers.map((p) => p.userId).toSet();
    final userMap = <String, AppUser>{};
    for (final uid in ids) {
      final u = await userSvc.fetchUser(uid);
      if (u != null) userMap[uid] = u;
    }
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
      final slotsKey = isHome ? 'homeSlots' : 'awaySlots';
      final slots = List<dynamic>.from(rounds[r][slotsKey] as List);
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

    payload['rounds'] = rounds;
    final newScorecard = Map<String, dynamic>.from(_match!.scorecard ?? {});
    newScorecard['payload'] = payload;
    await ref.read(matchServiceProvider).updateScorecard(_match!.id, newScorecard);
    setState(() {
      _match = _match!.copyWith(scorecard: newScorecard);
    });
  }

  Future<void> _saveLineup() async {
    if (_match == null) return;
    setState(() => _saving = true);
    await ref.read(matchServiceProvider).updateStatus(_match!.id, 'inProgress');
    setState(() => _saving = false);
    if (mounted) context.go('/score/${_match!.id}');
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

    final payload = _match!.scorecard?['payload'] as Map<String, dynamic>? ?? {};
    final rounds = payload['rounds'] as List<dynamic>? ?? [];
    final playersPerRound = payload['playersPerRound'] as int? ?? 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('Lineup: ${_match!.homeTeamName} vs ${_match!.awayTeamName}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (var slotIdx = 0; slotIdx < playersPerRound; slotIdx++)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Slot ${slotIdx + 1}', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (var roundIdx = 0; roundIdx < rounds.length; roundIdx++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: _slotDropdown(
                                label: 'R${roundIdx + 1} Home',
                                value: _slotsForRound(roundIdx, true).elementAt(slotIdx),
                                options: _playerById.values
                                    .where((p) => p.teamId == _match!.homeTeamId)
                                    .toList(),
                                disabled: _gameScored(roundIdx, slotIdx, true),
                                onChanged: (val) => _setSlot(
                                  isHome: true,
                                  slotIdx: slotIdx,
                                  roundIdx: roundIdx,
                                  playerId: val,
                                  autofillAllRounds: roundIdx == 0,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _slotDropdown(
                                label: 'R${roundIdx + 1} Away',
                                value: _slotsForRound(roundIdx, false).elementAt(slotIdx),
                                options: _playerById.values
                                    .where((p) => p.teamId == _match!.awayTeamId)
                                    .toList(),
                                disabled: _gameScored(roundIdx, slotIdx, false),
                                onChanged: (val) => _setSlot(
                                  isHome: false,
                                  slotIdx: slotIdx,
                                  roundIdx: roundIdx,
                                  playerId: val,
                                  autofillAllRounds: roundIdx == 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text('Preview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...rounds.map((r) {
            final ri = (r['roundNumber'] as int? ?? 1) - 1;
            final games = (r['games'] as List<dynamic>? ?? []).map((e) => e as Map<String, dynamic>).toList();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Round ${ri + 1}', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    for (final g in games)
                      Text(
                        'G${g['gameNumber']}: ${_playerName(g['homePlayerId'])} vs ${_playerName(g['awayPlayerId'])}',
                      ),
                  ],
                ),
              ),
            );
          }),
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

  Widget _slotDropdown({
    required String label,
    required String? value,
    required List<Player> options,
    required bool disabled,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        DropdownButton<String?>(
          isExpanded: true,
          value: value,
          items: options
              .map(
                (p) => DropdownMenuItem(
                  value: p.id,
                  child: Text(_userById[p.userId]?.firstName ?? p.userId),
                ),
              )
              .toList(),
          onChanged: disabled ? null : onChanged,
        ),
        if (disabled)
          const Text(
            'Locked (game scored)',
            style: TextStyle(fontSize: 10, color: Colors.redAccent),
          ),
      ],
    );
  }
}
