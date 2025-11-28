import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/user_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool _isStrong(String pwd) {
    return pwd.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(pwd) &&
        RegExp(r'[a-z]').hasMatch(pwd) &&
        RegExp(r'[0-9]').hasMatch(pwd);
  }

  Future<void> _register() async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    final pwd = _password.text.trim();
    if (!_isStrong(pwd)) {
      setState(() {
        _busy = false;
        _error = 'Password must be at least 8 chars with upper, lower, and a number.';
      });
      return;
    }

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: pwd,
      );

      final db = ref.read(firestoreProvider);
      final uid = cred.user?.uid;
      if (uid == null) {
        throw Exception('Registration failed: missing user id');
      }
      await db.collection('users').doc(uid).set({
        'firstName': _firstName.text.trim(),
        'lastName': _lastName.text.trim(),
        'email': _email.text.trim(),
        'handicap': 0,
        'role': 'user',
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (cred.user != null) {
        await cred.user!.sendEmailVerification();
      }
      setState(() {
        _info = 'Account created. Please verify your email to continue.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? e.code);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _password,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              if (_info != null)
                Text(
                  _info!,
                  style: const TextStyle(color: Colors.green),
                ),
              ElevatedButton(
                onPressed: _busy ? null : _register,
                child: _busy ? const CircularProgressIndicator() : const Text('Register'),
              ),
              TextButton(
                onPressed: _busy ? null : () => context.pop(),
                child: const Text('Back to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
