class LeaderboardEntry {
  final String studentName;
  final double scorePercentage;
  final int timeTakenSeconds;

  LeaderboardEntry({
    required this.studentName,
    required this.scorePercentage,
    required this.timeTakenSeconds,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      studentName: json['student_name'] ?? 'Unknown',
      scorePercentage: double.tryParse(json['score_percentage']?.toString() ?? '0') ?? 0.0,
      timeTakenSeconds: int.tryParse(json['time_taken_seconds']?.toString() ?? '0') ?? 0,
    );
  }
}
