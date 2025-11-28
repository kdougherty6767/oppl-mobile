import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/selection_providers.dart';
import '../services/auth_providers.dart';
import '../services/player_service.dart';
import '../services/team_service.dart';
import '../services/user_service.dart';

class TeamSelectScreen extends ConsumerWidget {
  const TeamSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    final userId = user?.uid;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    final playersStream = ref.watch(playerServiceProvider).watchPlayersForUser(userId);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Team')),
      body: StreamBuilder(
        stream: playersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final players = snapshot.data ?? [];
          if (players.isEmpty) {
            return const Center(child: Text('No teams assigned.'));
          }

          return ListView.separated(
            itemCount: players.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final p = players[index];
              return FutureBuilder(
                future: ref.read(teamServiceProvider).fetchTeam(p.teamId),
                builder: (context, teamSnap) {
                  final teamName = teamSnap.data?.name ?? 'Team ${p.teamId}';
                  return ListTile(
                    title: Text(teamName),
                    subtitle: Text('Status: ${p.status}'),
                    onTap: () {
                      ref.read(selectedTeamIdProvider.notifier).state = p.teamId;
                      if (context.mounted) {
                        context.go('/matches/${p.teamId}');
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
