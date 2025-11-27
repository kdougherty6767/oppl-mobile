import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_model.dart';
import '../services/match_service.dart';
import '../services/team_service.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key, required this.teamId});

  final String teamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesStream = ref.watch(matchServiceProvider).watchMatchesForTeam(teamId);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: ref.read(teamServiceProvider).fetchTeam(teamId),
          builder: (context, snap) =>
              Text(snap.data?.name ?? 'Matches'),
        ),
      ),
      body: StreamBuilder<List<Match>>(
        stream: matchesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('No matches found.'));
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final m = items[index];
              final isHome = m.homeTeamId == teamId;
              final opponent = isHome ? m.awayTeamName : m.homeTeamName;
              return ListTile(
                title: Text('Week ${m.week} vs $opponent'),
                subtitle: Text('Status: ${m.status}'),
                onTap: () {
                  Navigator.of(context).pushNamed('/score/${m.id}', arguments: {'matchId': m.id});
                },
              );
            },
          );
        },
      ),
    );
  }
}
