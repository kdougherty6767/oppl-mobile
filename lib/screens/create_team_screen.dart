import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hall_season_model.dart';
import '../services/auth_providers.dart';
import '../services/hall_season_service.dart';
import '../services/player_service.dart';

class CreateTeamScreen extends ConsumerStatefulWidget {
  const CreateTeamScreen({super.key, required this.hallSeasonId});

  final String hallSeasonId;

  @override
  ConsumerState<CreateTeamScreen> createState() => _CreateTeamScreenState();
}

class _CreateTeamScreenState extends ConsumerState<CreateTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  String _teamName = '';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final hsStream = ref.watch(hallSeasonServiceProvider).watchHallSeason(widget.hallSeasonId);

    return Scaffold(
      appBar: AppBar(title: const Text('Create Team')),
      body: StreamBuilder<HallSeason?>(
        stream: hsStream,
        builder: (context, hsSnap) {
          final hs = hsSnap.data;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hs?.displayName ?? 'HallSeason', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Team name'),
                    onChanged: (v) => _teamName = v,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a team name' : null,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            if (user == null) return;
                            setState(() => _submitting = true);
                            try {
                              await ref.read(playerServiceProvider).createPendingTeamAndCaptain(
                                    hallSeasonId: widget.hallSeasonId,
                                    teamName: _teamName.trim(),
                                    userId: user.uid,
                                  );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Team request submitted for approval')),
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
                        : const Text('Submit Request'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
