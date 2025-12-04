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

    // Emit combined home+away on every change, filtering to latest scheduleVersion.
    return StreamZip([homeStream, awayStream]).map((snaps) {
      final allDocs = [...snaps[0].docs, ...snaps[1].docs];
      final allMatches = allDocs.map((d) => Match.fromMap(d.id, d.data())).toList();
      int maxVersion = 0;
      for (final m in allMatches) {
        final v = m.scheduleVersion ?? 0;
        if (v > maxVersion) maxVersion = v;
      }
      final filtered = allMatches.where((m) => (m.scheduleVersion ?? 0) == maxVersion).toList();
      filtered.sort((a, b) => a.week.compareTo(b.week));
      return filtered;
    });
  }

  Future<void> updateMatch(String id, Map<String, dynamic> data) {
    return _db.collection(FsPaths.matches).doc(id).update(data);
  }

  Future<Match?> fetchMatch(String id, {bool serverOnly = false}) async {
    final snap = await _db
        .collection(FsPaths.matches)
        .doc(id)
        .get(serverOnly ? const GetOptions(source: Source.server) : null);
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    return Match.fromMap(snap.id, data);
  }

  Future<void> updateScorecard(String id, Map<String, dynamic> scorecard) {
    return _db.collection(FsPaths.matches).doc(id).update({'scorecard': scorecard});
  }

  Future<void> updateStatus(String id, String status) {
    return _db.collection(FsPaths.matches).doc(id).update({'status': status});
  }

  Stream<Match?> watchMatch(String id) {
    return _db.collection(FsPaths.matches).doc(id).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return Match.fromMap(snap.id, data);
    });
  }
}

final matchServiceProvider = Provider<MatchService>((ref) {
  return MatchService(ref.watch(firestoreProvider));
});
