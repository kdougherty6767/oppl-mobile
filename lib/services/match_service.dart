import 'package:async/async.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_model.dart';
import 'firestore_paths.dart';
import 'user_service.dart';

class MatchService {
  MatchService(this._db);
  final FirebaseFirestore _db;

  Stream<List<Match>> watchMatchesForTeam(String teamId) {
    final homeStream = _db
        .collection(FsPaths.matches)
        .where('homeTeamId', isEqualTo: teamId)
        .snapshots();
    final awayStream = _db
        .collection(FsPaths.matches)
        .where('awayTeamId', isEqualTo: teamId)
        .snapshots();

    return StreamGroup.merge([homeStream, awayStream]).map((query) {
      final matches = query.docs.map((d) => Match.fromMap(d.id, d.data())).toList();
      matches.sort((a, b) => a.week.compareTo(b.week));
      return matches;
    });
  }

  Future<void> updateMatch(String id, Map<String, dynamic> data) {
    return _db.collection(FsPaths.matches).doc(id).update(data);
  }

  Future<Match?> fetchMatch(String id) async {
    final snap = await _db.collection(FsPaths.matches).doc(id).get();
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return Match.fromMap(snap.id, data);
  }
}

final matchServiceProvider = Provider<MatchService>((ref) {
  return MatchService(ref.watch(firestoreProvider));
});
