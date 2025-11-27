class Team {
  final String id;
  final String hallSeasonId;
  final String name;
  final String status; // active | pending...
  final int? createdAt;

  Team({
    required this.id,
    required this.hallSeasonId,
    required this.name,
    required this.status,
    this.createdAt,
  });

  factory Team.fromMap(String id, Map<String, dynamic> data) {
    return Team(
      id: id,
      hallSeasonId: data['hallSeasonId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      createdAt: (data['createdAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hallSeasonId': hallSeasonId,
      'name': name,
      'status': status,
      'createdAt': createdAt,
    }..removeWhere((k, v) => v == null);
  }
}
