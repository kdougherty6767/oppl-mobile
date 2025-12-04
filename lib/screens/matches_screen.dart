import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/match_model.dart';
import '../services/match_service.dart';
import '../services/team_service.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key, required this.teamId});

  final String teamId;

  bool _goLineup(String status) {
    return status == 'notStarted' || status == 'scheduled';
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    DateTime? dt;
    if (date is DateTime) {
      dt = date;
    } else if (date is String) {
      dt = DateTime.tryParse(date);
    } else if (date is int) {
      dt = DateTime.fromMillisecondsSinceEpoch(date);
    }
    if (dt == null) return '';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesStream = ref.watch(matchServiceProvider).watchMatchesForTeam(teamId);

    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder(
          future: ref.read(teamServiceProvider).fetchTeam(teamId),
          builder: (context, snap) => Text(snap.data?.name ?? 'Matches'),
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
              final dateText = _formatDate(m.date);
              return ListTile(
                title: Text('Week ${m.week} · $opponent'),
                subtitle: Text(
                  [
                    if (dateText.isNotEmpty) dateText,
                    'Status: ${m.status}',
                  ].join(' • '),
                ),
                trailing: Text(isHome ? 'Home' : 'Away'),
                onTap: () {
                  if (_goLineup(m.status)) {
                    context.push('/lineup/${m.id}');
                  } else {
                    context.push('/score/${m.id}');
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
