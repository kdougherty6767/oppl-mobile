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

  Future<List<Player>> fetchPlayersForHallSeason(String hallSeasonId) async {
    final snap = await _db
        .collection(FsPaths.players)
        .where('hallSeasonId', isEqualTo: hallSeasonId)
        .get(const GetOptions(source: Source.server));
    return snap.docs.map((d) => Player.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Player>> watchPlayersForTeam(String teamId) {
    return _db
        .collection(FsPaths.players)
        .where('teamId', isEqualTo: teamId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Player.fromMap(d.id, d.data())).toList());
  }

  Future<List<Player>> fetchPlayersForTeam(String teamId) async {
    final snap = await _db
        .collection(FsPaths.players)
        .where('teamId', isEqualTo: teamId)
        .get(const GetOptions(source: Source.server));
    return snap.docs.map((d) => Player.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Player>> watchPlayersForUser(String userId) {
    return _db
        .collection(FsPaths.players)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Player.fromMap(d.id, d.data())).toList());
  }

  Future<void> requestJoinTeam({
    required String hallSeasonId,
    required String teamId,
    required String userId,
  }) async {
    await _db.collection(FsPaths.players).add({
      'hallSeasonId': hallSeasonId,
      'teamId': teamId,
      'userId': userId,
      'isCaptain': false,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<String> createPendingTeamAndCaptain({
    required String hallSeasonId,
    required String teamName,
    required String userId,
  }) async {
    final teamRef = await _db.collection(FsPaths.teams).add({
      'hallSeasonId': hallSeasonId,
      'name': teamName,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    await _db.collection(FsPaths.players).add({
      'hallSeasonId': hallSeasonId,
      'teamId': teamRef.id,
      'userId': userId,
      'isCaptain': true,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    return teamRef.id;
  }
}

final playerServiceProvider = Provider<PlayerService>((ref) {
  return PlayerService(ref.watch(firestoreProvider));
});
