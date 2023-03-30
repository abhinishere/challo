import 'package:firebase_database/firebase_database.dart';

class LastMessageModel {
  final String content;
  final DateTime timestamp;

  LastMessageModel({
    required this.content,
    required this.timestamp,
  });

  factory LastMessageModel.fromJson(DataSnapshot snapshot) => LastMessageModel(
        content: (snapshot.value as Map)['content'] ?? '',
        timestamp: ((snapshot.value as Map)['time'] != null)
            ? DateTime.fromMillisecondsSinceEpoch(
                (snapshot.value as Map)['time'])
            : DateTime.now(),
      );
}
