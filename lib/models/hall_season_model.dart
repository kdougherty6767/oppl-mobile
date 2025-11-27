class HallSeason {
  final String id;
  final String hallId;
  final String seasonId;
  final String displayName;
  final String? playDay;
  final List<dynamic>? weekDates;
  final String format;
  final int playersPerRound;
  final int roundsPerMatch;
  final List<dynamic>? tableNumbers;
  final List<dynamic>? reps;
  final String status;
  final int? createdAt;

  HallSeason({
    required this.id,
    required this.hallId,
    required this.seasonId,
    required this.displayName,
    required this.format,
    required this.playersPerRound,
    required this.roundsPerMatch,
    required this.status,
    this.playDay,
    this.weekDates,
    this.tableNumbers,
    this.reps,
    this.createdAt,
  });

  factory HallSeason.fromMap(String id, Map<String, dynamic> data) {
    return HallSeason(
      id: id,
      hallId: data['hallId'] as String? ?? '',
      seasonId: data['seasonId'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      format: data['format'] as String? ?? '1man',
      playersPerRound: (data['playersPerRound'] as num?)?.toInt() ?? 1,
      roundsPerMatch: (data['roundsPerMatch'] as num?)?.toInt() ?? 6,
      status: data['status'] as String? ?? 'pendingTeams',
      playDay: data['playDay'] as String?,
      weekDates: data['weekDates'] as List<dynamic>?,
      tableNumbers: data['tableNumbers'] as List<dynamic>?,
      reps: data['reps'] as List<dynamic>?,
      createdAt: (data['createdAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hallId': hallId,
      'seasonId': seasonId,
      'displayName': displayName,
      'format': format,
      'playersPerRound': playersPerRound,
      'roundsPerMatch': roundsPerMatch,
      'status': status,
      'playDay': playDay,
      'weekDates': weekDates,
      'tableNumbers': tableNumbers,
      'reps': reps,
      'createdAt': createdAt,
    }..removeWhere((k, v) => v == null);
  }
}
