class Player {
  final String id;
  final String hallSeasonId;
  final String teamId;
  final String userId;
  final bool isCaptain;
  final String status; // active | pending...
  final int? createdAt;

  Player({
    required this.id,
    required this.hallSeasonId,
    required this.teamId,
    required this.userId,
    required this.isCaptain,
    required this.status,
    this.createdAt,
  });

  factory Player.fromMap(String id, Map<String, dynamic> data) {
    return Player(
      id: id,
      hallSeasonId: data['hallSeasonId'] as String? ?? '',
      teamId: data['teamId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      isCaptain: data['isCaptain'] as bool? ?? false,
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hallSeasonId': hallSeasonId,
      'teamId': teamId,
      'userId': userId,
      'isCaptain': isCaptain,
      'status': status,
      'createdAt': createdAt,
    }..removeWhere((k, v) => v == null);
  }
}
