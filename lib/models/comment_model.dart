import 'package:firebase_database/firebase_database.dart';

class CommentModel {
  String content;
  final String commentId;
  final String parentCommentId;
  final String docName;
  final DateTime time;
  final String type;
  String status;
  final String posterUid;
  String posterUsername;
  List<String> likes;
  List<String> dislikes;
  List<String> blockedBy;
  int repliesCount;
  final String path;
  bool showReplies;
  final int indentLevel;

  CommentModel({
    required this.content,
    required this.commentId,
    required this.parentCommentId,
    required this.docName,
    required this.time,
    required this.type,
    required this.status,
    required this.posterUid,
    required this.posterUsername,
    required this.likes,
    required this.dislikes,
    required this.blockedBy,
    required this.repliesCount,
    required this.path,
    required this.showReplies,
    required this.indentLevel,
  });

  factory CommentModel.fromJson(DataSnapshot snapshot) => CommentModel(
        content: (snapshot.value as Map)['content'] ?? "Loading",
        commentId: (snapshot.value as Map)['commentId'] ?? '00',
        parentCommentId: (snapshot.value as Map)['parentCommentId'] ?? '00',
        docName: (snapshot.value as Map)['docName'] ?? '00',
        time: ((snapshot.value as Map)['time'] != null)
            ? DateTime.fromMillisecondsSinceEpoch(
                (snapshot.value as Map)['time'])
            : DateTime.now(),
        type: (snapshot.value as Map)['type'] ?? 'text',
        status: (snapshot.value as Map)['status'] ?? 'published',
        posterUid: (snapshot.value as Map)['posterUid'] ?? '00',
        posterUsername: (snapshot.value as Map)['posterUsername'] ?? '',
        likes: ((snapshot.value as Map)['likes'] != null)
            ? List.from((snapshot.value as Map)['likes'])
            : [],
        dislikes: ((snapshot.value as Map)['dislikes'] != null)
            ? List.from((snapshot.value as Map)['dislikes'])
            : [],
        blockedBy: ((snapshot.value as Map)['blockedBy'] != null)
            ? List.from((snapshot.value as Map)['blockedBy'])
            : [],
        repliesCount: (snapshot.value as Map)['repliesCount'] ?? 0,
        path: (snapshot.value as Map)['path'] ?? '',
        showReplies: false,
        indentLevel: (snapshot.value as Map)['indentLevel'] ?? 1,
      );
}
