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
  final int? scheduleVersion;
  final Map<String, dynamic>? scorecard;
  final int? createdAt;
  final bool? homeAgrees;
  final bool? awayAgrees;
  final String? scorecardStatus; // pending | submitted | confirmed

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
    this.scheduleVersion,
    this.date,
    this.tableNumber,
    this.scorecard,
    this.createdAt,
    this.homeAgrees,
    this.awayAgrees,
    this.scorecardStatus,
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
      scheduleVersion: (data['scheduleVersion'] as num?)?.toInt(),
      scorecard: data['scorecard'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as num?)?.toInt(),
      homeAgrees: data['homeAgrees'] as bool?,
      awayAgrees: data['awayAgrees'] as bool?,
      scorecardStatus: data['scorecardStatus'] as String?,
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
      'scheduleVersion': scheduleVersion,
      'scorecard': scorecard,
      'createdAt': createdAt,
      'homeAgrees': homeAgrees,
      'awayAgrees': awayAgrees,
      'scorecardStatus': scorecardStatus,
    }..removeWhere((k, v) => v == null);
  }

  Match copyWith({
    String? id,
    String? hallSeasonId,
    int? week,
    dynamic date,
    int? tableNumber,
    String? homeTeamId,
    String? awayTeamId,
    String? homeTeamName,
    String? awayTeamName,
    String? format,
    String? status,
    int? scheduleVersion,
    Map<String, dynamic>? scorecard,
    int? createdAt,
    bool? homeAgrees,
    bool? awayAgrees,
    String? scorecardStatus,
  }) {
    return Match(
      id: id ?? this.id,
      hallSeasonId: hallSeasonId ?? this.hallSeasonId,
      week: week ?? this.week,
      date: date ?? this.date,
      tableNumber: tableNumber ?? this.tableNumber,
      homeTeamId: homeTeamId ?? this.homeTeamId,
      awayTeamId: awayTeamId ?? this.awayTeamId,
      homeTeamName: homeTeamName ?? this.homeTeamName,
      awayTeamName: awayTeamName ?? this.awayTeamName,
      format: format ?? this.format,
      status: status ?? this.status,
      scheduleVersion: scheduleVersion ?? this.scheduleVersion,
      scorecard: scorecard ?? this.scorecard,
      createdAt: createdAt ?? this.createdAt,
      homeAgrees: homeAgrees ?? this.homeAgrees,
      awayAgrees: awayAgrees ?? this.awayAgrees,
      scorecardStatus: scorecardStatus ?? this.scorecardStatus,
    );
  }
}
