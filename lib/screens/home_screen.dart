import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/selection_providers.dart';
import '../services/auth_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('OPPL Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(firebaseAuthProvider).signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user == null ? 'No user' : 'Hello ${user.email ?? user.uid}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('Selected team: ${selectedTeamId ?? "none"}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.push('/team-select'),
              child: const Text('Choose Team'),
            ),
            if (selectedTeamId != null)
              ElevatedButton(
                onPressed: () => context.push('/matches/$selectedTeamId'),
                child: const Text('View Matches'),
              ),
          ],
        ),
      ),
    );
  }
}
