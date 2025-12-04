import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hall_season_model.dart';
import '../models/team_model.dart';
import '../services/auth_providers.dart';
import '../services/hall_season_service.dart';
import '../services/player_service.dart';
import '../services/team_service.dart';

class JoinTeamScreen extends ConsumerStatefulWidget {
  const JoinTeamScreen({super.key, required this.hallSeasonId});

  final String hallSeasonId;

  @override
  ConsumerState<JoinTeamScreen> createState() => _JoinTeamScreenState();
}

class _JoinTeamScreenState extends ConsumerState<JoinTeamScreen> {
  String? _selectedTeam;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final hsStream = ref.watch(hallSeasonServiceProvider).watchHallSeason(widget.hallSeasonId);
    final teamsStream = ref.watch(teamServiceProvider).watchTeamsForHallSeason(widget.hallSeasonId);

    return Scaffold(
      appBar: AppBar(title: const Text('Join Team')),
      body: StreamBuilder<HallSeason?>(
        stream: hsStream,
        builder: (context, hsSnap) {
          final hs = hsSnap.data;
          return StreamBuilder<List<Team>>(
            stream: teamsStream,
            builder: (context, teamSnap) {
              final teams = teamSnap.data ?? [];
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hs?.displayName ?? 'HallSeason', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Select team'),
                      value: _selectedTeam,
                      items: teams
                          .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedTeam = v),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () async {
                              if (_selectedTeam == null || user == null) return;
                              setState(() => _submitting = true);
                              try {
                                await ref.read(playerServiceProvider).requestJoinTeam(
                                      hallSeasonId: widget.hallSeasonId,
                                      teamId: _selectedTeam!,
                                      userId: user.uid,
                                    );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Join request submitted')),
                                  );
                                  Navigator.of(context).pop();
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to submit: $e')),
                                  );
                                }
                              } finally {
                                if (mounted) setState(() => _submitting = false);
                              }
                            },
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Request to Join'),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
