import 'package:cloud_firestore/cloud_firestore.dart';

class Participant {
  final String id;
  final String name;
  final int score;
  final int answered;
  final DateTime? lastAnswerAt;

  Participant({
    required this.id,
    required this.name,
    required this.score,
    required this.answered,
    this.lastAnswerAt,
  });

  factory Participant.fromMap(String id, Map<String, dynamic> m) {
    final last = m['lastAnswerAt'];
    DateTime? lastDt;
    if (last is Timestamp) lastDt = last.toDate();
    return Participant(
      id: id,
      name: (m['displayName'] ?? 'Player') as String,
      score: (m['score'] ?? 0) as int,
      answered: (m['answered'] ?? 0) as int,
      lastAnswerAt: lastDt,
    );
  }
}
