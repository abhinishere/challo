import 'package:challo/models/message_model.dart';

class MessagesList {
  final String chatDocName;
  final List<MessageModel> messages;

  MessagesList({
    required this.chatDocName,
    required this.messages,
  });
}
