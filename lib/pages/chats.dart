import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/models/link_to.dart';
import 'package:challo/models/message_model.dart';
import 'package:challo/pages/add_to_chats.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/chatwith.dart';
import 'package:challo/pages/community_page.dart';
import 'package:challo/pages/image_page_2.dart';
import 'package:challo/pages/linkpage.dart';
import 'package:challo/pages/nonlive_video_player.dart';
import 'package:challo/pages/profilepage.dart';
import 'package:challo/pages/text_content_page.dart';
import 'package:challo/pages/videoplayerpage.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController searchcontroller = TextEditingController();
  Future<QuerySnapshot>? searchresult;
  bool stoploading = false;
  bool firstcheckover = false;
  Timer? timer;
  late String onlineuid;
  late String onlineusername;
  late String onlinepic;
  late List<String> blockedusers;
  late List<String> hiddenusers;
  late Stream<QuerySnapshot> chatStream;
  bool metadataisthere = false; //usernames, images, etc
  List<String> selectedChatDocNames = [];
  List<String> publishedChatDocNames = [];
  List<String> trackedMessageDocNames = [];
  List<Map> allMessagesList = [];
  List<Map> unreadMessagesList = [];

  late DateTime currentTime;
  Map<String, String> lastMessage = {};
  Map<String, String> lastMessageDate = {};

  bool linkDataLoading = false;

  @override
  void initState() {
    super.initState();
    if (stoploading == false) {
      firstcheckconnected();
    }
    if (firstcheckover == true && stoploading == false) {
      timer = Timer.periodic(const Duration(seconds: 5), (Timer t) {
        checkconnected();
      });
    }
    getonlineuserdata();
  }

  getonlineuserdata() async {
    onlineuid = FirebaseAuth.instance.currentUser!.uid;

    await usercollection.doc(onlineuid).get().then((onlineuserdocs) => {
          onlineusername = onlineuserdocs['username'],
          onlinepic = onlineuserdocs['profilepic'],
        });

    chatStream = usercollection
        .doc(onlineuid)
        .collection('chats')
        .orderBy('lastMessagedOn')
        .snapshots();

    usercollection
        .doc(onlineuid)
        .collection('chats')
        .where('status', isEqualTo: 'published')
        .snapshots()
        .listen((QuerySnapshot querySnapshot) {
      for (var document in querySnapshot.docs) {
        String chatDocName = document['chatDocName'];
        lastMessage[chatDocName] = '';
        lastMessageDate[chatDocName] = '';
        chatsdb
            .child(chatDocName)
            .orderByChild('time')
            .limitToLast(1)
            .onChildAdded
            .listen((event) {
          if (event.snapshot.exists) {
            final String message = (event.snapshot.value as Map)['content'];
            final DateTime messagedateinDateTime =
                DateTime.fromMillisecondsSinceEpoch(
                    (event.snapshot.value as Map)['time']);
            final String messagedate = dateTimeConvert(messagedateinDateTime);
            if (!mounted) return;
            setState(() {
              lastMessage[chatDocName] = message;
              lastMessageDate[chatDocName] = messagedate;
            });

            //print("message datatime is ${lastMessageDate[chatDocName]}");
          }
        });
      }
    });

    if (!mounted) return;
    setState(() {
      metadataisthere = true;
    });
  }

  String getLastMessage(Map<String, MessageModel>? messages) {
    if (messages != null) {
      List<String> messagesList = [];
      String lastMessage = '';
      for (MessageModel m in messages.values) {
        messagesList.add(m.content);
      }
      lastMessage = messagesList.last;

      return lastMessage;
    } else {
      return '';
    }
  }

  String getLastMessageDate(Map<String, MessageModel>? messages) {
    if (messages != null) {
      List<DateTime> messagesList = [];
      String lastMessageDate = '';
      for (MessageModel m in messages.values) {
        messagesList.add(m.timestamp);
      }
      lastMessageDate = dateTimeConvert(messagesList.last);

      return lastMessageDate;
    } else {
      return '';
    }
  }

  firstcheckconnected() {
    if (connected == true) {
      stoploading = true;
    }

    firstcheckover = true;
  }

  checkconnected() {
    if (connected == true) {
      stoploading = true;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    searchcontroller.dispose();
    super.dispose();
  }

  Widget chatsHeaderWidget(String image, String username, String lastmsg,
      String time, String unreadMessageCount) {
    return Row(children: [
      CachedNetworkImage(
        imageUrl: image,
        progressIndicatorBuilder: (context, url, downloadProgress) => Container(
          child: const CircleAvatar(
            child: CupertinoActivityIndicator(
              color: kPrimaryColorTint2,
            ),
            radius: 25.0,
            backgroundColor: kBackgroundColorDark2,
          ),
        ),
        imageBuilder: (context, imageProvider) => Container(
          child: CircleAvatar(
            backgroundImage: imageProvider,
            radius: 25.0,
            backgroundColor: kBackgroundColorDark2,
          ),
        ),
      ),
      /*CircleAvatar(
        radius: 25,
        backgroundColor: kBackgroundColorDark,
        backgroundImage: NetworkImage(image),
      ),*/
      const SizedBox(
        width: 10.0,
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  username,
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        fontSize: 17.0,
                        fontWeight: FontWeight.w600,
                        color: kHeadlineColorDark,
                      ),
                ),
                (unreadMessageCount == '' || unreadMessageCount.isEmpty)
                    ? Container()
                    : CircleAvatar(
                        backgroundColor: kTertiaryColor,
                        radius: 12,
                        child: Text(
                          unreadMessageCount,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall!
                              .copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 10.0,
                                color: kHeadlineColorDark,
                              ),
                        ),
                      )
              ],
            ),
            const SizedBox(
              height: 5.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    lastmsg,
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          fontSize: 15.0,
                          color: kSubTextColor,
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Text(
                  time,
                  style: Theme.of(context).textTheme.displaySmall!.copyWith(
                        fontSize: 10.0,
                        color: kParaColorDark,
                      ),
                ),
              ],
            )
          ],
        ),
      ),
    ]);
  }

  Widget chatsHeaderStream(
      String? uid, String lastmsg, String time, int unreadMessageCount) {
    return (uid == '' || uid == null)
        ? chatsHeaderWidget(
            'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/profilepics%2Fdefault-profile-pic.jpg?alt=media&token=cb615f5f-0f4d-41ea-b267-60912482d645',
            'loading...',
            '',
            '',
            '',
          )
        : StreamBuilder<QuerySnapshot>(
            stream: usercollection.where('uid', isEqualTo: uid).snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) {
                print("getting info");
                return chatsHeaderWidget(
                  'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/profilepics%2Fdefault-profile-pic.jpg?alt=media&token=cb615f5f-0f4d-41ea-b267-60912482d645',
                  'loading...',
                  '',
                  '',
                  '',
                );
              }
              if (snapshot.data.docs.length == 0) {
                return chatsHeaderWidget(
                  'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/profilepics%2Fdefault-profile-pic.jpg?alt=media&token=cb615f5f-0f4d-41ea-b267-60912482d645',
                  'loading...',
                  '',
                  '',
                  '',
                );
              }
              var userdocsforchats = snapshot.data.docs[0];
              String updatedimage = userdocsforchats['profilepic'];
              String updatedusername = userdocsforchats['username'];
              //String updatedmessage = userdocsforchats['lastMsg'];

              return chatsHeaderWidget(
                updatedimage,
                updatedusername,
                lastmsg,
                time,
                (unreadMessageCount == 0)
                    ? ''
                    : (unreadMessageCount > 10)
                        ? '10+'
                        : '$unreadMessageCount',
              );
            },
          );
  }

  Widget allchatsStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: chatStream,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting chats data");
          return const Center(
            child: CupertinoActivityIndicator(
              color: kDarkPrimaryColor,
            ),
          );
        }
        if (snapshot.data.docs.length == 0) {
          return Center(child: Container());
        }
        return ListView.builder(
          reverse: true,
          physics: const ScrollPhysics(),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: snapshot.data.docs.length,
          itemBuilder: (BuildContext context, int index) {
            var chat = snapshot.data.docs[index];
            if (chat['status'] == 'published' &&
                (chat['whetherDeleted'] == false)) {
              return Container(
                decoration: BoxDecoration(
                  color: (selectedChatDocNames.contains(chat['chatDocName']))
                      ? kPrimaryColor
                      : kBackgroundColorDark,
                  border: const Border(
                    bottom:
                        BorderSide(width: 0.5, color: kBackgroundColorDark2),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: InkWell(
                  onLongPress: () {
                    setState(() {
                      selectedChatDocNames.add(chat['chatDocName']);
                    });
                  },
                  onTap: () {
                    if (selectedChatDocNames.isEmpty) {
                      setState(() {
                        hidenav = true;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatWith(
                            chatDocName: chat['chatDocName'],
                            otheruid: chat['uid'],
                            onlinepic: onlinepic,
                            whetherjustcreated: false,
                            onlineuid: onlineuid,
                            onlineusername: onlineusername,
                          ),
                          fullscreenDialog: true,
                        ),
                      );
                    } else {
                      if (selectedChatDocNames.contains(chat['chatDocName'])) {
                        setState(() {
                          selectedChatDocNames.remove(chat['chatDocName']);
                        });
                      } else {
                        setState(() {
                          selectedChatDocNames.add(chat['chatDocName']);
                        });
                      }
                    }
                  },
                  child: Card(
                    shadowColor: Colors.transparent,
                    color: Colors.transparent,
                    child: ListTile(
                      /*shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),*/
                      title: chatsHeaderStream(
                        chat['uid'],
                        lastMessage[chat['chatDocName']] ?? "",
                        lastMessageDate[chat['chatDocName']] ?? "",
                        chat['unreadCount'],
                      ),
                    ),
                  ),
                ),
              );
            } else {
              return Container();
            }
          },
        );
      },
    );
  }

  String dateTimeConvert(DateTime timestamp) {
    currentTime = DateTime.now();
    String displaytime = DateTime.now().toString();
    int yearDiff = currentTime.year - timestamp.year;
    int monthDiff = currentTime.month - timestamp.month;
    int dayDiff = currentTime.difference(timestamp).inDays;
    int hourDiff = currentTime.difference(timestamp).inHours;

    if (yearDiff > 1) {
      displaytime = DateFormat('yyyy-MM').format(timestamp);
    } else if (monthDiff > 1 || dayDiff > 7) {
      displaytime = DateFormat('MMM-dd').format(timestamp);
    } else if (dayDiff > 1) {
      displaytime = DateFormat('EEE').format(timestamp);
    } else if (hourDiff > 24) {
      displaytime = DateFormat('EEE').format(timestamp);
    } else {
      displaytime = DateFormat('h:mm a').format(timestamp);
    }
    return displaytime;
  }

  deleteChatsConfirmation() {
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
              deleteChats();
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

  deleteChats() async {
    final time = DateTime.now();
    for (String doc in selectedChatDocNames) {
      var chatdocs = await chatscollection.doc(doc).get();
      final List<String> uids = List.from(chatdocs['uids']);
      uids.remove(onlineuid);
      final String otheruid = uids[0];
      await chatscollection.doc(doc).update({
        'deletedUntil.$onlineuid': time,
        'deletedBy': FieldValue.arrayUnion([onlineuid]),
      }).then((_) async => {
            await usercollection
                .doc(onlineuid)
                .collection('chats')
                .doc(otheruid)
                .update({
              'whetherDeleted': true,
              'lastDeletedOn': time,
            }),
          });
    }
    setState(() {
      selectedChatDocNames.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (linkedPage != null &&
        selectedTabIndex == 1 &&
        whetherStreaming == false) {
      print("Loading link data");
      final LinkTo linkData = linkedPage!;
      linkedPage = null;
      bool hidenavBackup = false;
      setState(() {
        hidenav = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppBuilder.of(context)!.rebuild();
        Navigator.of(context).popUntil((route) => route.isFirst);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            linkDataLoading = true;
          });
          if (linkData.type == 'linkpost') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LinkPage(
                          docName: linkData.docName!,
                          whetherjustcreated: false,
                          showcomments: false,
                          hideNavLinkReturn: hidenavBackup,
                        ))).then((_) => {
                  setState(() {
                    linkDataLoading = false;
                  })
                });
          } else if (linkData.type == 'textpost') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TextContentPage(
                          docName: linkData.docName!,
                          whetherjustcreated: false,
                          showcomments: false,
                          hideNavLinkReturn: hidenavBackup,
                        ))).then((_) => {
                  setState(() {
                    linkDataLoading = false;
                  })
                });
          } else if (linkData.type == 'imagepost') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ImagePage2(
                          docName: linkData.docName!,
                          whetherjustcreated: false,
                          showcomments: false,
                          hideNavLinkReturn: hidenavBackup,
                        ))).then((_) => {
                  setState(() {
                    linkDataLoading = false;
                  })
                });
          } else if (linkData.type == 'videopost') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NonliveVideoPlayer(
                          docName: linkData.docName!,
                          whetherjustcreated: false,
                          showcomments: false,
                          hideNavLinkReturn: hidenavBackup,
                        ))).then((_) => {
                  setState(() {
                    linkDataLoading = false;
                  })
                });
          } else if (linkData.type == 'streampost') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => VideoPlayerPage(
                          docName: linkData.docName!,
                          whetherjustcreated: false,
                          showcomments: false,
                          hideNavLinkReturn: hidenavBackup,
                        ))).then((_) => {
                  setState(() {
                    linkDataLoading = false;
                  })
                });
          } else if (linkData.type == 'community') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CommunityPage(
                          communityname: linkData.docName!,
                          whetherjustcreated: false,
                          hideNavLinkReturn: hidenavBackup,
                        ))).then((_) => {
                  setState(() {
                    linkDataLoading = false;
                  })
                });
          } else if (linkData.type == 'profile') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ProfilePage(
                          whetherShowArrow: true,
                          uid: linkData.docName!,
                          hideNavLinkReturn: hidenavBackup,
                        ))).then((_) => {
                  setState(() {
                    linkDataLoading = false;
                  }),
                });
          }
        });
      });
    }
    return (linkDataLoading == true)
        ? Scaffold(
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CupertinoActivityIndicator(
                      color: kDarkPrimaryColor,
                    ),
                    SizedBox(
                      height: 10.0,
                    ),
                    Text("Loading linked page..."),
                  ],
                ),
              ),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              title: const Text("Chats"),
              centerTitle: true,
              actions: [
                (selectedChatDocNames.isEmpty)
                    ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();

                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: ((context) =>
                                        const AddToChats())));
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Icon(
                              Icons.person_add,
                            ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () => deleteChatsConfirmation(),
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Icon(
                              Icons.delete,
                              color: kWarningColorDarkTint,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
            body: SafeArea(
              child: (metadataisthere == false)
                  ? const Center(
                      child: CupertinoActivityIndicator(
                      color: kDarkPrimaryColor,
                    ))
                  : allchatsStream(),
            ),
          );
  }
}
