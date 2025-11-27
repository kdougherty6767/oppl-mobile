import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import 'firestore_paths.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

class UserService {
  UserService(this._db);
  final FirebaseFirestore _db;

  Future<AppUser?> fetchUser(String uid) async {
    final snap = await _db.collection(FsPaths.users).doc(uid).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return AppUser.fromMap(snap.id, data);
  }

  Stream<AppUser?> watchUser(String uid) {
    return _db.collection(FsPaths.users).doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return AppUser.fromMap(snap.id, data);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) {
    return _db.collection(FsPaths.users).doc(uid).update(data);
  }
}

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(ref.watch(firestoreProvider));
});
