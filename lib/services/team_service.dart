import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/team_model.dart';
import 'firestore_paths.dart';
import 'user_service.dart';

class TeamService {
  TeamService(this._db);
  final FirebaseFirestore _db;

  Stream<List<Team>> watchTeamsForHallSeason(String hallSeasonId) {
    return _db
        .collection(FsPaths.teams)
        .where('hallSeasonId', isEqualTo: hallSeasonId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Team.fromMap(d.id, d.data()))
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)));
  }

  Future<Team?> fetchTeam(String id) async {
    final snap = await _db.collection(FsPaths.teams).doc(id).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return Team.fromMap(snap.id, data);
  }

  Stream<Team?> watchTeam(String id) {
    return _db.collection(FsPaths.teams).doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return Team.fromMap(snap.id, data);
    });
  }
}

final teamServiceProvider = Provider<TeamService>((ref) {
  return TeamService(ref.watch(firestoreProvider));
});
