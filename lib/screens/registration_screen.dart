import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/hall_season_model.dart';
import '../models/player_model.dart';
import '../services/auth_providers.dart';
import '../services/hall_season_service.dart';
import '../services/player_service.dart';

class RegistrationScreen extends ConsumerWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    final uid = user?.uid;
    final hallSeasonsStream = ref.watch(hallSeasonServiceProvider).watchRegistrationHallSeasons();
    final myTeamsStream = uid == null
        ? const Stream<List<Player>>.empty()
        : ref.watch(playerServiceProvider).watchPlayersForUser(uid);

    return Scaffold(
      appBar: AppBar(title: const Text('Registration')),
      body: StreamBuilder<List<HallSeason>>(
        stream: hallSeasonsStream,
        builder: (context, hsSnap) {
          if (hsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final hallSeasons = hsSnap.data ?? [];
          return StreamBuilder<List<Player>>(
            stream: myTeamsStream,
            builder: (context, teamSnap) {
              final myTeams = teamSnap.data ?? [];
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Sessions Open for Registration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Join an existing team or create a new one.'),
                  const SizedBox(height: 16),
                  if (hallSeasons.isEmpty)
                    const Text('No sessions currently open.')
                  else
                    ...hallSeasons.map((hs) {
                      final alreadyOnTeam = myTeams.any((p) => p.hallSeasonId == hs.id && (p.status ?? 'active') != 'pending');
                      final status = hs.status;
                      final canJoin = status != 'seasonComplete';
                      final canCreate = status == 'openRegistration';
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(hs.displayName),
                          subtitle: Text(status),
                          trailing: alreadyOnTeam
                              ? const Text(
                                  'You are already on a team',
                                  style: TextStyle(color: Colors.red),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: canJoin
                                          ? () => context.push('/registration/join/${hs.id}')
                                          : null,
                                      child: const Text('Join Team'),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: canCreate
                                          ? () => context.push('/registration/create/${hs.id}')
                                          : null,
                                      child: const Text('Create Team'),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    })
                ],
              );
            },
          );
        },
      ),
    );
  }
}
