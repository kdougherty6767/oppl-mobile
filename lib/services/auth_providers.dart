import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Stream of auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  // userChanges emits on sign-in/out AND profile changes (including emailVerified after reload)
  return ref.watch(firebaseAuthProvider).userChanges();
});
