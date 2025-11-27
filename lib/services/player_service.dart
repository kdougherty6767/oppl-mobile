import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player_model.dart';
import 'firestore_paths.dart';
import 'user_service.dart';

class PlayerService {
  PlayerService(this._db);
  final FirebaseFirestore _db;

  Stream<List<Player>> watchPlayersForHallSeason(String hallSeasonId) {
    return _db
        .collection(FsPaths.players)
        .where('hallSeasonId', isEqualTo: hallSeasonId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Player.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Player>> watchPlayersForTeam(String teamId) {
    return _db
        .collection(FsPaths.players)
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Player.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Player>> watchPlayersForUser(String userId) {
    return _db
        .collection(FsPaths.players)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Player.fromMap(d.id, d.data())).toList());
  }
}

final playerServiceProvider = Provider<PlayerService>((ref) {
  return PlayerService(ref.watch(firestoreProvider));
});
