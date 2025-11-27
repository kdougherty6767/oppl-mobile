import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/match_service.dart';

class ScoreScreen extends ConsumerWidget {
  const ScoreScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(matchServiceProvider).fetchMatch(matchId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final match = snap.data;
        if (match == null) {
          return const Scaffold(body: Center(child: Text('Match not found')));
        }
        return Scaffold(
          appBar: AppBar(title: Text('Score: ${match.homeTeamName} vs ${match.awayTeamName}')),
          body: Center(
            child: Text('Scorecard UI goes here for match ${match.id}'),
          ),
        );
      },
    );
  }
}
