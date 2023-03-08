import 'package:firebase_database/firebase_database.dart';

class LitsModel {
  final String title;
  final String description;
  final String link;
  final String domainName;
  final List images;
  final DateTime timestamp;
  final String updateDocName;
  final String status;

  const LitsModel({
    required this.title,
    required this.description,
    required this.link,
    required this.domainName,
    required this.images,
    required this.timestamp,
    required this.updateDocName,
    required this.status,
  });
  factory LitsModel.fromJson(DataSnapshot snapshot) => LitsModel(
        title: (snapshot.value as Map)['title'] ?? 'Loading',
        description: (snapshot.value as Map)['description'] ?? 'Loading',
        link: (snapshot.value as Map)['link'] ?? '',
        domainName: (snapshot.value as Map)['domainName'] ?? '',
        images: ((snapshot.value as Map)['images'] != null)
            ? List.from((snapshot.value as Map)['images'])
            : [],
        timestamp: ((snapshot.value as Map)['time'] != null)
            ? DateTime.fromMillisecondsSinceEpoch(
                (snapshot.value as Map)['time'])
            : DateTime.now(),
        updateDocName: (snapshot.value as Map)['updateDocName'] ?? '',
        status: (snapshot.value as Map)['status'] ?? 'published',
      );
}
