import 'dart:async';
import 'dart:math';

import 'package:challo/models/message_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

//Chat With for each chat

class ChatWith extends StatefulWidget {
  final String chatDocName;
  final String otheruid;
  final bool whetherjustcreated;
  final String onlineuid;
  final String onlineusername;
  final String onlinepic;

  const ChatWith({
    required this.chatDocName,
    required this.otheruid,
    required this.whetherjustcreated,
    required this.onlineuid,
    required this.onlineusername,
    required this.onlinepic,
  });

  @override
  State<ChatWith> createState() => _ChatWithState();
}

class _ChatWithState extends State<ChatWith> {
  @override
  void dispose() {
    _streamSubscription.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getchatdata();
  }

  late DateTime lastDeletedOn;
  final currentTime = DateTime.now();
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generatedocName() {
    final String time = DateTime.now().toString();
    final String newDocName =
        widget.chatDocName + getRandomString(5) + time.substring(0, 10);
    return newDocName;
  }

  getchatdata() async {
    messagePath = 'chatsdb/${widget.chatDocName}';

    _streamSubscription = FirebaseDatabase.instance
        .ref()
        .child(messagePath)
        .orderByChild('time')
        //.limitToLast(10)
        .onChildAdded
        .listen((event) async {
      messagesList.add(MessageModel.fromJson(event.snapshot));
      await usercollection
          .doc(widget.onlineuid)
          .collection('chats')
          .doc(widget.otheruid)
          .update({
        'lastReadOn': DateTime.now(),
        'unreadCount': 0,
      });
      setState(() {});
    });

    var onlineuserdocs = await usercollection
        .doc(widget.onlineuid)
        .collection('chats')
        .doc(widget.otheruid)
        .get();

    lastDeletedOn = onlineuserdocs['lastDeletedOn'].toDate();

    chatStatus = onlineuserdocs['status'];

    otheruid = onlineuserdocs['uid'];

    var otheruserdocs = await usercollection.doc(otheruid).get();

    otherusername = otheruserdocs['username'];
    otherpic = otheruserdocs['profilepic'];

    setState(() {
      dataisthere = true;
    });
  }

  String dateTimeShow(DateTime timestamp) {
    String displaytime = DateTime.now().toString();
    int yearDiff = currentTime.year - timestamp.year;
    int monthDiff = currentTime.month - timestamp.month;
    int dayDiff = currentTime.difference(timestamp).inDays;
    int hourDiff = currentTime.difference(timestamp).inHours;

    if (yearDiff > 1) {
      displaytime = DateFormat('yyyy-MM-dd h:mm a').format(timestamp);
    } else if ((monthDiff > 1) || (dayDiff > 7)) {
      displaytime = DateFormat('MM-dd h:mm a').format(timestamp);
    } else if (dayDiff > 1) {
      displaytime = DateFormat('EEE, h:mm a').format(timestamp);
    } else if (hourDiff > 24) {
      displaytime = DateFormat('EEE, h:mm a').format(timestamp);
    } else {
      displaytime = DateFormat('h:mm a').format(timestamp);
    }
    return displaytime;
  }

  final selectedMessageColor = const Color(0xFFb190f6);

  late String otheruid;
  late String otherusername;
  late String otherpic;
  late String chatStatus;
  late String messagePath;
  late StreamSubscription _streamSubscription;
  List<MessageModel> messagesList = [];
  bool dataisthere = false;
  bool showsendbutton = false;
  List<MessageModel> selectedMessages = [];
  //show options when selectedmessages not empty
  final TextEditingController _chatController = TextEditingController();

  Widget messageBubble(MessageModel m) {
    return (m.deletedBy.contains(widget.onlineuid) ||
            m.timestamp.isBefore(lastDeletedOn))
        ? Container()
        : InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onLongPress: () {
              setState(() {
                selectedMessages.add(m);
              });

              print("Message selected");
            },
            onTap: () {
              if (selectedMessages.contains(m)) {
                setState(() {
                  selectedMessages.remove(m);
                });
                print("Message removed");
              } else {
                if (selectedMessages.isNotEmpty) {
                  setState(() {
                    selectedMessages.add(m);
                  });
                }
              }
            },
            child: Container(
              color: (selectedMessages.contains(m))
                  ? kPrimaryColor
                  : Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.only(
                  top: 10.0,
                  left: 20.0,
                  right: 20.0,
                ),
                child: Column(
                  //mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: (m.senderuid == widget.onlineuid)
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: (m.senderuid == widget.onlineuid)
                            ? kMessageBubbleColor2
                            : kMessageBubbleColor1,
                        borderRadius: (m.senderuid == widget.onlineuid)
                            ? const BorderRadius.only(
                                topLeft: Radius.circular(20.0),
                                bottomLeft: Radius.circular(20.0),
                                bottomRight: Radius.circular(20.0),
                              )
                            : const BorderRadius.only(
                                topRight: Radius.circular(20.0),
                                bottomLeft: Radius.circular(20.0),
                                bottomRight: Radius.circular(20.0),
                              ),
                      ),
                      child: Text(
                        m.content,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 14.0,
                            color: (m.senderuid == widget.onlineuid)
                                ? kHeadlineColorDark
                                : kHeadlineColorDarkShade),
                      ),
                    ),
                    const SizedBox(
                      height: 2.0,
                    ),
                    Text(
                      dateTimeShow(m.timestamp),
                      style: Theme.of(context).textTheme.displaySmall!.copyWith(
                            fontSize: 10.0,
                            color: kSubTextColor,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
  }

  Widget messageStreamWidget() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 15),
      children: [
        for (MessageModel m in messagesList.reversed) messageBubble(m),
      ],
      reverse: true,
    );
  }

  sendMessage() async {
    final String messageContent = _chatController.text;
    _chatController.clear();
    setState(() {
      showsendbutton = false;
    });
    final String messageDocName = generatedocName();
    final time = DateTime.now();
    final timestamp = time.millisecondsSinceEpoch;
    List<String> deletedBy = [];

    await chatsdb.child(widget.chatDocName).child(messageDocName).set({
      'messageDocName': messageDocName,
      'type': 'text',
      'senderuid': widget.onlineuid,
      'content': messageContent,
      'time': timestamp,
      'deletedBy': deletedBy,
    }).then((_) async => {
          await usercollection
              .doc(otheruid)
              .collection('chats')
              .doc(widget.onlineuid)
              .update({
            'unreadCount': FieldValue.increment(1),
            'lastMessagedOn': time,
            'whetherDeleted': false,
          }).then((_) async => {
                    await usercollection
                        .doc(widget.onlineuid)
                        .collection('chats')
                        .doc(otheruid)
                        .update({
                      'lastMessagedOn': time,
                      'whetherDeleted': false,
                    }).then((_) async => {
                              if (chatStatus == 'pending')
                                {
                                  chatStatus = 'published',
                                  await chatscollection
                                      .doc(widget.chatDocName)
                                      .update({
                                    'status': chatStatus,
                                  }).then((_) async => {
                                            await usercollection
                                                .doc(widget.onlineuid)
                                                .collection('chats')
                                                .doc(otheruid)
                                                .update({
                                              'status': chatStatus,
                                            }).then((_) => {
                                                      usercollection
                                                          .doc(otheruid)
                                                          .collection('chats')
                                                          .doc(widget.onlineuid)
                                                          .update({
                                                        'status': chatStatus,
                                                      }),
                                                    })
                                          }),
                                  print('chatStatus is $chatStatus'),
                                }
                            })
                  })
        });
  }

  Widget _chatBox() {
    return Container(
      color: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10.0,
          right: 10.0,
          //top: 5.0,
          bottom: 10.0,
        ),
        child: TextFormField(
          onChanged: (text) {
            String trimmedText = text.trim();
            if (trimmedText.isEmpty) {
              if (showsendbutton == true) {
                setState(() {
                  showsendbutton = false;
                  print("hiding send button!");
                });
              }
            } else {
              if (showsendbutton == false) {
                setState(() {
                  showsendbutton = true;
                  print("showing send button!");
                });
              }
            }
          },
          maxLines: 5,
          minLines: 1,
          cursorColor: kHeadlineColorDark,
          style: const TextStyle(
            color: kHeadlineColorDark,
          ),
          controller: _chatController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            suffixIcon: (showsendbutton == false)
                ? null
                : Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: InkWell(
                      onTap: () => sendMessage(),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kIconSecondaryColorDark,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: kHeadlineColorDark,
                        ),
                      ),
                    ),
                  ),
            hintText: "Type message...",
            hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                  fontSize: 14,
                  color: kSubTextColor,
                  fontWeight: FontWeight.w200,
                ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(5),
              borderSide: const BorderSide(
                width: 0,
                style: BorderStyle.none,
              ),
            ),
            filled: true,
            fillColor: kBackgroundColorDark2,
            contentPadding: const EdgeInsets.only(left: 16),
          ),
        ),
      ),
    );
  }

  copyMessage() {
    String selectedMessage = selectedMessages[0].content;
    Clipboard.setData(ClipboardData(text: selectedMessage));
    setState(() {
      selectedMessages.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Message copied to clipboard."),
      dismissDirection: DismissDirection.horizontal,
    ));
  }

  deleteMessagesConfirmation() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("Sure you want to delete?",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kSubTextColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                )),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            //isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(context);
              deleteMessages();
            },
            child: Text(
              'Yes',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 20.0,
                    color: kWarningColorDarkTint,
                    fontStyle: FontStyle.normal,
                  ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(
            "Cancel",
            style: Theme.of(context).textTheme.button!.copyWith(
                  fontSize: 20.0,
                  color: kPrimaryColorTint2,
                  fontStyle: FontStyle.normal,
                ),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  deleteMessages() async {
    List<MessageModel> selectedMessagesList = selectedMessages;

    for (MessageModel m in selectedMessagesList) {
      var chatdocs =
          await chatsdb.child(widget.chatDocName).child(m.messageDocName).get();

      final List<String> deletedByNew =
          ((chatdocs.value as Map)['deletedBy'] != null)
              ? List.from((chatdocs.value as Map)['deletedBy'])
              : [];
      deletedByNew.add(widget.onlineuid);
      await chatsdb.child(widget.chatDocName).child(m.messageDocName).update({
        'deletedBy': deletedByNew,
      }).then((_) => {
            m.deletedBy.add(widget.onlineuid),
          });
    }
    setState(() {
      selectedMessages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (widget.whetherjustcreated == true) {
          setState(() {
            hidenav = false;
          });
          AppBuilder.of(context)!.rebuild();
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else {
          setState(() {
            hidenav = false;
          });
          AppBuilder.of(context)!.rebuild();
          Navigator.pop(context);
        }
        return Future.value(false);
      },
      child: (dataisthere == false)
          ? Scaffold(
              appBar: AppBar(
                leading: GestureDetector(
                  onTap: () {
                    if (widget.whetherjustcreated == true) {
                      setState(() {
                        hidenav = false;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    } else {
                      setState(() {
                        hidenav = false;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.pop(context);
                    }
                  },
                  child: const Icon(Icons.arrow_back),
                ),
              ),
            )
          : Scaffold(
              //bottomNavigationBar: ,
              appBar: AppBar(
                leading: Container(),
                actions: [
                  Flexible(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          child: Row(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 15.0),
                                child: GestureDetector(
                                  onTap: () {
                                    if (widget.whetherjustcreated == true) {
                                      setState(() {
                                        hidenav = false;
                                      });
                                      AppBuilder.of(context)!.rebuild();
                                      Navigator.of(context)
                                          .popUntil((route) => route.isFirst);
                                    } else {
                                      setState(() {
                                        hidenav = false;
                                      });
                                      AppBuilder.of(context)!.rebuild();
                                      Navigator.pop(context);
                                    }
                                  },
                                  child: const Icon(
                                    Icons.arrow_back,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10.0,
                              ),
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: kHeadlineColorDark,
                                backgroundImage: NetworkImage(otherpic),
                              ),
                              const SizedBox(
                                width: 5.0,
                              ),
                              Text(
                                otherusername,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(
                                      color: kHeadlineColorDark,
                                      fontSize: 15.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        (selectedMessages.isEmpty)
                            ? Container()
                            : (selectedMessages.length == 1)
                                ? Row(
                                    children: [
                                      InkWell(
                                        onTap: () => copyMessage(),
                                        customBorder: const CircleBorder(),
                                        child: const Padding(
                                          padding: EdgeInsets.all(10.0),
                                          child: Icon(
                                            Icons.copy,
                                            size: 20.0,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(right: 8.0),
                                        child: InkWell(
                                          onTap: () =>
                                              deleteMessagesConfirmation(),
                                          customBorder: const CircleBorder(),
                                          child: const Padding(
                                            padding: EdgeInsets.all(10.0),
                                            child: Icon(
                                              CupertinoIcons.trash_fill,
                                              size: 20.0,
                                              color: kWarningColorDarkTint,
                                            ),
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                : Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: InkWell(
                                      onTap: () => deleteMessagesConfirmation(),
                                      customBorder: const CircleBorder(),
                                      child: const Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: Icon(
                                          CupertinoIcons.trash_fill,
                                          size: 20.0,
                                          color: kWarningColorDarkTint,
                                        ),
                                      ),
                                    ),
                                  )
                      ],
                    ),
                  ),
                ],
              ),
              body: (dataisthere == false)
                  ? const CupertinoActivityIndicator(
                      color: kDarkPrimaryColor,
                    )
                  : Column(
                      children: [
                        Expanded(child: messageStreamWidget()),
                        _chatBox()
                      ],
                    ),
            ),
    );
  }
}
