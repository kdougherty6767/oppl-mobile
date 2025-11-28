import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _busy = false;
  String? _info;
  String? _error;

  Future<void> _resend() async {
    setState(() {
      _busy = true;
      _info = null;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
      setState(() => _info = 'Verification email sent.');
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    await FirebaseAuth.instance.currentUser?.reload();
    final user = FirebaseAuth.instance.currentUser;
    // Force token refresh to trigger userChanges stream
    await user?.getIdToken(true);
    setState(() => _busy = false);
    if (user != null && user.emailVerified && mounted) {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user?.email == null
                  ? 'Check your email for a verification link.'
                  : 'A verification link was sent to ${user!.email}. Please verify to continue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_info != null)
              Text(_info!, style: const TextStyle(color: Colors.green)),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _busy ? null : _resend,
              child: _busy ? const CircularProgressIndicator() : const Text('Resend Email'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _busy ? null : _refresh,
              child: const Text('I have verified'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _busy
                  ? null
                  : () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) context.go('/login');
                    },
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
