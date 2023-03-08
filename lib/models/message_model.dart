import 'package:firebase_database/firebase_database.dart';

class MessageModel {
  final String content;
  final String senderuid;
  final DateTime timestamp;
  final String messageDocName;
  final String type;
  final String status;
  List<String> deletedBy;

  MessageModel({
    required this.content,
    required this.senderuid,
    required this.timestamp,
    required this.messageDocName,
    required this.type,
    required this.status,
    required this.deletedBy,
  });
  factory MessageModel.fromJson(DataSnapshot snapshot) => MessageModel(
        content: (snapshot.value as Map)['content'] ?? 'Loading',
        senderuid: (snapshot.value as Map)['senderuid'] ?? '00',
        timestamp: ((snapshot.value as Map)['time'] != null)
            ? DateTime.fromMillisecondsSinceEpoch(
                (snapshot.value as Map)['time'])
            : DateTime.now(),
        messageDocName: (snapshot.value as Map)['messageDocName'] ?? '',
        type: (snapshot.value as Map)['type'] ?? 'text',
        status: (snapshot.value as Map)['status'] ?? 'published',
        deletedBy: ((snapshot.value as Map)['deletedBy'] != null)
            ? List.from((snapshot.value as Map)['deletedBy'])
            : [],
      );
}
