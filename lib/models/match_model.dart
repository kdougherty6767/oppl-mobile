class Match {
  final String id;
  final String hallSeasonId;
  final int week;
  final dynamic date; // stored as whatever the web uses (timestamp/string)
  final int? tableNumber;
  final String homeTeamId;
  final String awayTeamId;
  final String homeTeamName;
  final String awayTeamName;
  final String format;
  final String status;
  final Map<String, dynamic>? scorecard;
  final int? createdAt;

  Match({
    required this.id,
    required this.hallSeasonId,
    required this.week,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.homeTeamName,
    required this.awayTeamName,
    required this.format,
    required this.status,
    this.date,
    this.tableNumber,
    this.scorecard,
    this.createdAt,
  });

  factory Match.fromMap(String id, Map<String, dynamic> data) {
    return Match(
      id: id,
      hallSeasonId: data['hallSeasonId'] as String? ?? '',
      week: (data['week'] as num?)?.toInt() ?? 0,
      date: data['date'],
      tableNumber: (data['tableNumber'] as num?)?.toInt(),
      homeTeamId: data['homeTeamId'] as String? ?? '',
      awayTeamId: data['awayTeamId'] as String? ?? '',
      homeTeamName: data['homeTeamName'] as String? ?? '',
      awayTeamName: data['awayTeamName'] as String? ?? '',
      format: data['format'] as String? ?? '1man',
      status: data['status'] as String? ?? 'scheduled',
      scorecard: data['scorecard'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hallSeasonId': hallSeasonId,
      'week': week,
      'date': date,
      'tableNumber': tableNumber,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeTeamName': homeTeamName,
      'awayTeamName': awayTeamName,
      'format': format,
      'status': status,
      'scorecard': scorecard,
      'createdAt': createdAt,
    }..removeWhere((k, v) => v == null);
  }
}
