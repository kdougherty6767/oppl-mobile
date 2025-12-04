import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/hall_season_model.dart';
import 'firestore_paths.dart';
import 'user_service.dart';

class HallSeasonService {
  HallSeasonService(this._db);
  final FirebaseFirestore _db;

  Stream<List<HallSeason>> watchRegistrationHallSeasons() {
    // Mirror web: openRegistration, teamsFinalized, scheduleFinalized are visible
    final allowedStatuses = ['openRegistration', 'teamsFinalized', 'scheduleFinalized'];
    return _db
        .collection(FsPaths.hallSeasons)
        .where('status', whereIn: allowedStatuses)
        .snapshots()
        .map((snap) => snap.docs.map((d) => HallSeason.fromMap(d.id, d.data())).toList());
  }

  Stream<HallSeason?> watchHallSeason(String id) {
    return _db.collection(FsPaths.hallSeasons).doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return HallSeason.fromMap(snap.id, data);
    });
  }

  Future<HallSeason?> fetchHallSeason(String id) async {
    final snap = await _db.collection(FsPaths.hallSeasons).doc(id).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return HallSeason.fromMap(snap.id, data);
  }
}

final hallSeasonServiceProvider = Provider<HallSeasonService>((ref) {
  return HallSeasonService(ref.watch(firestoreProvider));
});
