import 'dart:async';
import 'package:challo/helpers/share_service.dart';
import 'package:challo/models/comment_model.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/community_page.dart';
import 'package:challo/pages/post_text.dart';
import 'package:challo/pages/preview_text_image.dart';
import 'package:challo/pages/profilepage.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/comment_bottom.dart';
import 'package:challo/widgets/updownvotewidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:math';
import 'package:timeago/timeago.dart' as tago;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class TextContentPage extends StatefulWidget {
  final String docName;
  final bool whetherjustcreated;
  final bool showcomments;
  //final bool whethercommunitypost;
  final bool? hideNavLinkReturn;
  const TextContentPage({
    required this.docName,
    required this.whetherjustcreated,
    required this.showcomments,
    //required this.whethercommunitypost,
    this.hideNavLinkReturn,
  });
  @override
  State<TextContentPage> createState() => _TextContentPageState();
}

class _TextContentPageState extends State<TextContentPage> {
  bool postdataexists = false;
  bool commentdataexists = false;
  late String opuid, opusername, oppic;
  late String fullUrl, textStatus, textTopic, featuredimage, briefdescription;
  late String contentText;
  late bool whethercommunitypost;
  late List<String> textLikes, textDislikes, textViews;
  late String onlineuid, onlinepic, onlineusername;
  late dynamic timeofposting;
  late bool likedpost, dislikedpost;
  late int totallikes, totaldislikes, totalcomments, updownratio;
  String? communityName, communitypic;
  int selectedCommentRadioNo = 1;
  int selectedContentRadioNo = 1;
  String commentReportReason = 'Spam or misleading';
  String contentReportReason = 'Spam or misleading';
  bool whethercommentreportsubmitted = false;
  bool whethercontentreportsubmitted = false;
  bool checkwhetherblocked = false;
  bool checkwhetherdeleted = false;
  bool showPublishButton = false;
  bool showReplies = false;
  CommentModel? whichComment;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _editingController = TextEditingController();
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateRandomDocName(String username) {
    String newDocName = (username + getRandomString(5));
    return newDocName;
  }

  //comments' variables
  late String commentsPath;
  late StreamSubscription commentStreamSubscription;
  late List<CommentModel> commentsList;
  late Map<String?, List<CommentModel>?> repliesMap;

  @override
  void initState() {
    super.initState();
    gettextdata();
    getcommentdata();
  }

  getcommentdata() async {
    commentsList = [];
    repliesMap = {};
    commentsPath = 'commentsdb/${widget.docName}';
    commentStreamSubscription = FirebaseDatabase.instance
        .ref()
        .child(commentsPath)
        .orderByChild('time')
        .onChildAdded
        .listen((event) {
      commentsList.add(CommentModel.fromJson(event.snapshot));
      setState(() {});
    });
    setState(() {
      commentdataexists = true;
    });
  }

  clearComment() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _commentController.clear());
  }

  Future<void> _pulltoRefreshPage() async {
    setState(() {
      gettextdata();
      getcommentdata();
    });
  }

  gettextdata() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateString = dateFormat.format(DateTime.now());
    onlineuid = FirebaseAuth.instance.currentUser!.uid;

    var onlineuserdoc = await usercollection.doc(onlineuid).get();

    onlineusername = onlineuserdoc['username'];

    onlinepic = onlineuserdoc['profilepic'];

    await contentcollection.doc(widget.docName).update({
      'totalviews': FieldValue.arrayUnion(["$onlineuid $dateString"])
    });

    var textdoc = await contentcollection.doc(widget.docName).get();

    List<String> blockedbylist = List.from(textdoc['blockedby']);

    if (blockedbylist.contains(onlineuid)) {
      setState(() {
        checkwhetherblocked = true;
      });
    }

    fullUrl = textdoc['link'];
    textTopic = textdoc['topic'];
    briefdescription = textdoc['description'];
    featuredimage = textdoc['image'];

    textLikes = List.from(textdoc['likes']); //likes
    textDislikes = List.from(textdoc['dislikes']); //dislikes
    textViews = List.from(textdoc['totalviews']); //totalviews
    timeofposting = textdoc['time'];

    whethercommunitypost = textdoc['whethercommunitypost'];
    communityName = textdoc['communityName'];
    communitypic = textdoc['communitypic'];

    opuid = textdoc['opuid'];
    opusername = textdoc['opusername'];
    oppic = textdoc['oppic'];

    totallikes = textLikes.length;
    totaldislikes = textDislikes.length;

    if (textLikes.contains(onlineuid)) {
      setState(() {
        likedpost = true;
      });
    } else {
      likedpost = false;
    }

    if (textDislikes.contains(onlineuid)) {
      setState(() {
        dislikedpost = true;
      });
    } else {
      dislikedpost = false;
    }

    updownratio = totallikes - totaldislikes;

    /*var commentdocs = await contentcollection
        .doc(widget.docName)
        .collection('comments')
        .get();*/

    totalcomments = textdoc['commentcount'];

    Reference ref = FirebaseStorage.instance
        .ref()
        .child('text_posts')
        .child(widget.docName)
        .child('${widget.docName}.txt');
    await ref.getData().then((value) {
      setState(() {
        contentText = utf8.decode(value!.toList());
      });
    });

    setState(() {
      postdataexists = true;
    });
  }

  unblockReportedContent() async {
    await contentcollection.doc(widget.docName).update({
      'blockedby': FieldValue.arrayRemove([onlineuid])
    });
    var contentinuserdocs = await usercollection
        .doc(opuid)
        .collection('content')
        .doc(widget.docName)
        .get();

    if (!contentinuserdocs.exists) {
    } else {
      await usercollection
          .doc(opuid)
          .collection('content')
          .doc(widget.docName)
          .update({
        'blockedby': FieldValue.arrayRemove([onlineuid])
      });
    }
    setState(() {
      checkwhetherblocked = false;
    });
  }

  contentReportSubmit(String reason) async {
    await contentcollection.doc(widget.docName).update({
      'blockedby': FieldValue.arrayUnion([onlineuid])
    });
    var contentinuserdocs = await usercollection
        .doc(opuid)
        .collection('content')
        .doc(widget.docName)
        .get();

    if (!contentinuserdocs.exists) {
    } else {
      await usercollection
          .doc(opuid)
          .collection('content')
          .doc(widget.docName)
          .update({
        'blockedby': FieldValue.arrayUnion([onlineuid])
      });
    }
    await contentreportcollection
        .doc(generateRandomDocName(onlineusername))
        .set({
      'type': 'textpost',
      'status': 'reported', //reported -> deleted/noaction/pending
      'reporter': onlineuid,
      'docName': widget.docName,
      'reason': reason,
      'time': DateTime.now(),
    });
    setState(() {
      checkwhetherblocked = true;
    });
  }

  reportContentSheet() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalsetState) {
            return Container(
              child: (whethercontentreportsubmitted == false)
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: [
                          Text(
                            "Report content",
                            style: Theme.of(context)
                                .textTheme
                                .headline2!
                                .copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 1,
                                groupValue: selectedContentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val;
                                    contentReportReason = "Spam or misleading";
                                  });
                                },
                              ),
                              Text("Spam or misleading",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 2,
                                groupValue: selectedContentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val;
                                    contentReportReason =
                                        "Sexually explicit material";
                                  });
                                },
                              ),
                              Text("Sexually explicit material",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 3,
                                groupValue: selectedContentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val;
                                    contentReportReason =
                                        "Hate speech or graphic violence";
                                  });
                                },
                              ),
                              Text("Hate speech or graphic violence",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 4,
                                groupValue: selectedContentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val;
                                    contentReportReason =
                                        "Harassment or bullying";
                                  });
                                },
                              ),
                              Text("Harassment or bullying",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 5,
                                groupValue: selectedContentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val;
                                    contentReportReason =
                                        "Copyrighted material";
                                  });
                                },
                              ),
                              Text("Copyrighted material",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 6,
                                groupValue: selectedContentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val;
                                    contentReportReason = "Other";
                                  });
                                },
                              ),
                              Text("Other",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  print("Content Report Canceled");
                                },
                                child: Text("Cancel",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryColorTint2,
                                        )),
                              ),
                              const SizedBox(width: 10),
                              TextButton(
                                  onPressed: () {
                                    contentReportSubmit(contentReportReason);
                                    print("Content Reported...");
                                    modalsetState(() {
                                      whethercontentreportsubmitted = true;
                                    });
                                  },
                                  child: Text("Submit",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: kPrimaryColorTint2,
                                          ))),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Wrap(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 30,
                            color: kPrimaryColor,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              "Thank you for reporting. We will look into this ASAP and take immediate action.",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: Colors.white, fontSize: 15.0),
                            ),
                          ),
                        ],
                      )),
            );
          });
        }).whenComplete(() {
      setState(() {
        whethercontentreportsubmitted = false;
      });
    });
  }

  Widget moreOptions() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: InkWell(
        onTap: () {
          if (onlineuid == opuid) {
            showMoreOptionsPopUpForOP();
          } else {
            showMoreOptionsPopUpForViewers();
          }
        },
        child: const Icon(
          Icons.more_horiz,
          color: kIconSecondaryColorDark,
        ),
      ),
    );
  }

  showMoreOptionsPopUpForViewers() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("More Options",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kSubTextColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                )),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            //isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              reportContentSheet();
            },
            child: Text(
              'Report',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 20.0,
                    color: kWarningColorDarkTint,
                    fontStyle: FontStyle.normal,
                  ),
            ),
          ),
          /*CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Edit',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 20.0,
                    color: kPrimaryColorTint2,
                    fontStyle: FontStyle.normal,
                  ),
            ),
          ),*/
        ],
        cancelButton: CupertinoActionSheetAction(
          child: Text(
            "Close",
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

  showMoreOptionsPopUpForOP() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("More Options",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kSubTextColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                )),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostText(
                    whetherediting: true,
                    whetherfrompost: true,
                    docName: widget.docName,
                    whethercommunitypost: whethercommunitypost,
                    communityName: communityName,
                    communitypic: communitypic,
                    onlineuser: UserInfoModel(
                      uid: onlineuid,
                      pic: onlinepic,
                      username: onlineusername,
                    ),
                  ),
                  fullscreenDialog: true,
                ),
              ).then((whetheredited) => (whetheredited != null)
                  ? setState(() {
                      gettextdata();
                      print("updating post...");
                    })
                  : null);
            },
            child: Text(
              'Edit',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 20.0,
                    color: kPrimaryColorTint2,
                    fontStyle: FontStyle.normal,
                  ),
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            //isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              showDeleteConfirmation();
            },
            child: Text(
              'Delete',
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
            "Close",
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

  showDeleteConfirmation() {
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
              await usercollection
                  .doc(opuid)
                  .collection('content')
                  .where('docName', isEqualTo: widget.docName)
                  .get()
                  .then((value) {
                for (var element in value.docs) {
                  usercollection
                      .doc(opuid)
                      .collection('content')
                      .doc(element.id)
                      .delete()
                      .then((value) {
                    print("deleted from user profile");
                  });
                }
              }).then((_) async => {
                        await contentcollection.doc(widget.docName).update({
                          'status': 'deleted',
                        }).then((_) async => {
                              if (whethercommunitypost == true)
                                {
                                  await communitycollection
                                      .doc(communityName)
                                      .collection('content')
                                      .where('docName',
                                          isEqualTo: widget.docName)
                                      .get()
                                      .then((value) {
                                    for (var element in value.docs) {
                                      communitycollection
                                          .doc(communityName)
                                          .collection('content')
                                          .doc(element.id)
                                          .delete()
                                          .then((value) {
                                        print("deleted from community");
                                      });
                                    }
                                  }).then(
                                    (_) => setState(() {
                                      checkwhetherdeleted = true;
                                    }),
                                  ),
                                }
                              else
                                {
                                  setState(() {
                                    checkwhetherdeleted = true;
                                  }),
                                }
                            }),
                      });
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
          /*CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(
              'Edit',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 20.0,
                    color: kPrimaryColorTint2,
                    fontStyle: FontStyle.normal,
                  ),
            ),
          ),*/
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

  int updowncount() {
    return (totallikes - totaldislikes);
  }

  void _checkUpvotePost() async {
    var postdoc = await contentcollection.doc(widget.docName).get();

    if (postdoc['likes'].contains(onlineuid)) {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayRemove([onlineuid])
      });
      setState(() {
        likedpost = false;
        dislikedpost = false;
        totallikes = totallikes - 1;
        updownratio = updowncount();
      });
    } else if (postdoc['dislikes'].contains(onlineuid)) {
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayRemove([onlineuid])
      });
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayUnion([onlineuid])
      });
      setState(() {
        likedpost = true;
        dislikedpost = false;
        totaldislikes = totaldislikes - 1;
        totallikes = totallikes + 1;
        updownratio = updowncount();
      });
    } else {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayUnion([onlineuid])
      });
      setState(() {
        likedpost = true;
        dislikedpost = false;
        totallikes = totallikes + 1;
        updownratio = updowncount();
      });
    }
  }

  void _checkDownvotePost() async {
    var postdoc = await contentcollection.doc(widget.docName).get();

    if (postdoc['dislikes'].contains(onlineuid)) {
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayRemove([onlineuid])
      });
      setState(() {
        likedpost = false;
        dislikedpost = false;
        totaldislikes = totaldislikes - 1;
        updownratio = updowncount();
      });
    } else if (postdoc['likes'].contains(onlineuid)) {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayRemove([onlineuid])
      });
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayUnion([onlineuid])
      });
      setState(() {
        likedpost = false;
        dislikedpost = true;
        totallikes = totallikes - 1;
        totaldislikes = totaldislikes + 1;
        updownratio = updowncount();
      });
    } else {
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayUnion([onlineuid])
      });
      setState(() {
        likedpost = false;
        dislikedpost = true;
        totaldislikes = totaldislikes + 1;
        updownratio = updowncount();
      });
    }
  }

  commentUnblockSubmit(CommentModel c) async {
    var commentdocs = await commentsdb.child(c.path).get();

    final List<String> blockedByLatest =
        ((commentdocs.value as Map)['blockedBy'] != null)
            ? List.from((commentdocs.value as Map)['blockedBy'])
            : [];
    if (blockedByLatest.contains(onlineuid)) {
      blockedByLatest.remove(onlineuid);
    }
    await commentsdb.child(c.path).update({
      'blockedBy': blockedByLatest,
    }).then((_) => {
          setState(() {
            c.blockedBy = blockedByLatest;
          })
        });
  }

  showCommentOptionsForOthers(CommentModel c) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("More Options",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kSubTextColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                )),
        actions: <CupertinoActionSheetAction>[
          (c.blockedBy.contains(onlineuid))
              ? CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    commentUnblockSubmit(c);
                  },
                  child: Text(
                    'Unblock',
                    style: Theme.of(context).textTheme.button!.copyWith(
                          fontSize: 20.0,
                          color: kPrimaryColorTint2,
                          fontStyle: FontStyle.normal,
                        ),
                  ),
                )
              : CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.pop(context);
                    commentReportSheet(c);
                  },
                  child: Text(
                    'Report',
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
            "Close",
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

  showCommentOptionsForOP(CommentModel c) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("More Options",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kSubTextColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                )),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              editComment(c);
            },
            child: Text(
              'Edit',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 20.0,
                    color: kPrimaryColorTint2,
                    fontStyle: FontStyle.normal,
                  ),
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            //isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              showCommentDeleteConfirmation(c);
            },
            child: Text(
              'Delete',
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
            "Close",
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

  editComment(CommentModel c) {
    setState(() {
      _editingController.text = c.content;
    });
    showCommentSheet('Edit', c.parentCommentId, c.indentLevel, c.repliesCount,
        _editingController, c);
  }

  deleteComment(CommentModel c) async {
    await commentsdb.child(c.path).update({
      'status': 'deleted',
    }).then((_) => {
          setState(() {
            c.status = 'deleted';
          })
        });
  }

  updateComment(CommentModel c) async {
    final String editedComment = _editingController.text;
    _editingController.clear();
    await commentsdb
        .child(c.path)
        .update({
          'content': editedComment,
        })
        .then((_) => {
              Navigator.pop(context),
            })
        .then((_) => {
              setState(() {
                c.content = editedComment;
              }),
            });
  }

  showCommentDeleteConfirmation(CommentModel c) {
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
              deleteComment(c);
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

  commentReportSheet(CommentModel c) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalsetState) {
            return Container(
              child: (whethercommentreportsubmitted == false)
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: [
                          Text(
                            "Report comment",
                            style: Theme.of(context)
                                .textTheme
                                .headline2!
                                .copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white),
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 1,
                                groupValue: selectedCommentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommentRadioNo = val;
                                    commentReportReason = "Spam or misleading";
                                  });
                                },
                              ),
                              Text("Spam or misleading",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 2,
                                groupValue: selectedCommentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommentRadioNo = val;
                                    commentReportReason =
                                        "Sexually explicit material";
                                  });
                                },
                              ),
                              Text("Sexually explicit material",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 3,
                                groupValue: selectedCommentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommentRadioNo = val;
                                    commentReportReason =
                                        "Hate speech or graphic violence";
                                  });
                                },
                              ),
                              Text("Hate speech or graphic violence",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 4,
                                groupValue: selectedCommentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommentRadioNo = val;
                                    commentReportReason =
                                        "Harassment or bullying";
                                  });
                                },
                              ),
                              Text("Harassment or bullying",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 5,
                                groupValue: selectedCommentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommentRadioNo = val;
                                    commentReportReason =
                                        "Copyrighted material";
                                  });
                                },
                              ),
                              Text("Copyrighted material",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 6,
                                groupValue: selectedCommentRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommentRadioNo = val;
                                    commentReportReason = "Other";
                                  });
                                },
                              ),
                              Text("Other",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        fontSize: 12,
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text("Cancel",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryColorTint2,
                                        )),
                              ),
                              const SizedBox(width: 10),
                              TextButton(
                                  onPressed: () {
                                    commentReportSubmit(c, commentReportReason);
                                    print("Comment Report Submitted");
                                    modalsetState(() {
                                      whethercommentreportsubmitted = true;
                                    });
                                  },
                                  child: Text("Submit",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: kPrimaryColorTint2,
                                          ))),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Wrap(
                        //mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 30,
                            color: kPrimaryColor,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              "Thank you for reporting. We will look into this ASAP and take immediate action.",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: Colors.white, fontSize: 15.0),
                            ),
                          ),
                        ],
                      )),
            );
          });
        }).whenComplete(() {
      setState(() {
        whethercommentreportsubmitted = false;
      });
    });
  }

  commentReportSubmit(CommentModel c, String reason) async {
    var commentdocs = await commentsdb.child(c.path).get();

    final List<String> blockedByLatest =
        ((commentdocs.value as Map)['blockedBy'] != null)
            ? List.from((commentdocs.value as Map)['blockedBy'])
            : [];
    blockedByLatest.add(onlineuid);
    await commentsdb.child(c.path).update({
      'blockedBy': blockedByLatest,
    }).then((_) async => {
          await commentreportcollection
              .doc(generateRandomDocName(onlineusername))
              .set({
            'type': 'textcomment',
            'status': 'reported', //reported -> deleted/noaction/pending
            'reporter': onlineuid,
            'contentdocName': c.docName,
            'commentid': c.commentId,
            'commentPath': c.path,
            'reason': reason,
            'time': DateTime.now(),
          }).then((_) => {
                    setState(() {
                      c.blockedBy = blockedByLatest;
                    })
                  }),
        });
  }

  Widget commentHeaderWidget(String image, String username) {
    return Row(
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: Colors.white,
          backgroundImage: NetworkImage(image),
        ),
        const SizedBox(
          width: 3,
        ),
        Text(
          username,
          style: Theme.of(context).textTheme.subtitle1!.copyWith(
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
                color: kSubTextColor,
              ),
        ),
      ],
    );
  }

  Widget commentHeaderStream(String? uid) {
    return (uid == '' || uid == null)
        ? commentHeaderWidget(
            'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/profilepics%2Fdefault-profile-pic.jpg?alt=media&token=cb615f5f-0f4d-41ea-b267-60912482d645',
            'loading...')
        : StreamBuilder<QuerySnapshot>(
            stream: usercollection.where('uid', isEqualTo: uid).snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) {
                print("getting info");
                return commentHeaderWidget(
                    'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/profilepics%2Fdefault-profile-pic.jpg?alt=media&token=cb615f5f-0f4d-41ea-b267-60912482d645',
                    'loading...');
              }
              if (snapshot.data.docs.length == 0) {
                return commentHeaderWidget(
                    'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/profilepics%2Fdefault-profile-pic.jpg?alt=media&token=cb615f5f-0f4d-41ea-b267-60912482d645',
                    'loading...');
              }

              var userdocsforcomments = snapshot.data.docs[0];
              String updatedimage = userdocsforcomments['profilepic'];
              String updatedusername = userdocsforcomments['username'];

              return commentHeaderWidget(updatedimage, updatedusername);
            });
  }

  Widget commentCardNew() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        children: [
          for (CommentModel c in commentsList.reversed)
            commentCardWidget(c, true),
        ],
        reverse: true,
      ),
    );
  }

  upvotePost(CommentModel c) async {
    var commentdocs = await commentsdb.child(c.path).get();

    final List<String> likes = ((commentdocs.value as Map)['likes'] != null)
        ? List.from((commentdocs.value as Map)['likes'])
        : [];
    final List<String> dislikes =
        ((commentdocs.value as Map)['dislikes'] != null)
            ? List.from((commentdocs.value as Map)['dislikes'])
            : [];
    if (likes.contains(onlineuid)) {
      likes.remove(onlineuid);
      await commentsdb.child(c.path).update({
        'likes': likes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else if (dislikes.contains(onlineuid)) {
      dislikes.remove(onlineuid);
      likes.add(onlineuid);
      await commentsdb.child(c.path).update({
        'dislikes': dislikes,
        'likes': likes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else {
      likes.add(onlineuid);
      await commentsdb.child(c.path).update({
        'likes': likes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    }
  }

  downvotePost(CommentModel c) async {
    var commentdocs = await commentsdb.child(c.path).get();

    final List<String> likes = ((commentdocs.value as Map)['likes'] != null)
        ? List.from((commentdocs.value as Map)['likes'])
        : [];
    final List<String> dislikes =
        ((commentdocs.value as Map)['dislikes'] != null)
            ? List.from((commentdocs.value as Map)['dislikes'])
            : [];
    if (dislikes.contains(onlineuid)) {
      dislikes.remove(onlineuid);
      await commentsdb.child(c.path).update({
        'dislikes': dislikes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else if (likes.contains(onlineuid)) {
      likes.remove(onlineuid);
      dislikes.add(onlineuid);
      await commentsdb.child(c.path).update({
        'likes': likes,
        'dislikes': dislikes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else {
      dislikes.add(onlineuid);
      await commentsdb.child(c.path).update({
        'dislikes': dislikes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    }
  }

  Widget commentCardWidget(CommentModel c, bool whetherParentComment) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(
          thickness: 1,
          color: kBackgroundColorDark2,
        ),
        GestureDetector(
          onTap: () {
            showUserQuickInfo(c.posterUsername, c.posterUid);
          },
          child: Row(
            children: [
              commentHeaderStream(c.posterUid),
              const SizedBox(width: 5.0),
              Text(
                "• ${tago.format(c.time)}",
                style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: kSubTextColor,
                    ),
              ),
            ],
          ),
        ),
        CommentBottom(
          moreOptionsForOP: () => showCommentOptionsForOP(c),
          moreOptionsForOthers: () => showCommentOptionsForOthers(c),
          upvoteCount: c.likes.length,
          downvoteCount: c.dislikes.length,
          whetherUpvoted: c.likes.contains(onlineuid),
          whetherDownvoted: c.dislikes.contains(onlineuid),
          onReply: () {
            showCommentSheet('Reply', c.parentCommentId, c.indentLevel,
                c.repliesCount, _commentController, c);
          },
          onlineuid: onlineuid,
          comment: c,
          onUpvoted: () => upvotePost(c),
          onDownvoted: () => downvotePost(c),
        ),
        (whetherParentComment == true) ? replyShowWidget(c) : Container(),
      ],
    );
  }

  Future loadReplies(CommentModel c) async {
    print('loading replies');
    repliesMap[c.commentId] = [];
    final String repliesPath =
        'commentsdb/${widget.docName}/${c.commentId}/replies';
    //StreamSubscription replyStreamSubscription;

    FirebaseDatabase.instance
        .ref()
        .child(repliesPath)
        .orderByChild('time')
        .onChildAdded
        .listen((event) {
      repliesMap[c.commentId]?.add(CommentModel.fromJson(event.snapshot));
    });
    setState(() {
      c.showReplies = true;
    });
  }

  Widget replyShowWidget(CommentModel c) {
    return (c.repliesCount == 0)
        ? Container()
        : (c.showReplies == false)
            ? InkWell(
                onTap: () {
                  loadReplies(c).then((_) =>
                      Future.delayed(const Duration(milliseconds: 500), () {
                        setState(() {});
                      }));
                },
                child: Row(
                  children: [
                    const Icon(
                      Icons.arrow_drop_down,
                      color: kPrimaryColorTint2,
                    ),
                    Text("View ${c.repliesCount} replies",
                        style: Theme.of(context).textTheme.button!.copyWith(
                              color: kPrimaryColorTint2,
                              fontSize: 15.0,
                            )),
                  ],
                ),
              )
            : (repliesMap[c.commentId] == null ||
                    repliesMap[c.commentId]!.isEmpty)
                ? const CupertinoActivityIndicator(color: kDarkPrimaryColor)
                : Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: repliesMap[c.commentId]!.length,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (BuildContext context, int index) {
                        return commentCardWidget(
                            repliesMap[c.commentId]![index], false);
                      },
                      reverse: false,
                    ),
                  );
  }

  /* Widget commentCard(CommentModel c) {
    return (c.blockedBy.contains(onlineuid))
        ? Container()
        : Card(
            child: ListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      commentHeaderStream(c.posterUid),
                      const SizedBox(width: 5.0),
                      Text(
                        tago.format(c.time),
                        style: Theme.of(context).textTheme.caption!.copyWith(
                            fontSize: 10.0, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  Text(
                    c.content,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              subtitle: (c.posterUid == onlineuid)
                  ? Padding(
                      padding: const EdgeInsets.only(right: 5.0, top: 5.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            primary: Colors.white70,
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                                context: context,
                                builder: (builder) => Container(
                                      height:
                                          (MediaQuery.of(context).size.height) /
                                              6,
                                      width:
                                          (MediaQuery.of(context).size.width),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 20),
                                      child: Column(
                                        children: [
                                          const Text(
                                              'Are you sure you want to delete this comment?',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white)),
                                          const SizedBox(height: 20),
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child: const Text(
                                                          "Cancel",
                                                          style: TextStyle(
                                                            color:
                                                                kPrimaryColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ))),
                                                ),
                                                Container(
                                                  color: Colors.grey[500],
                                                  width: 0.5,
                                                  height: 22,
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: TextButton(
                                                      onPressed: () async {
                                                        /*
                                                        Navigator.pop(context);
                                                        snapshot
                                                            .data
                                                            .docs[index]
                                                            .reference
                                                            .delete();
                                                        var contentdocs =
                                                            await contentcollection
                                                                .doc(widget
                                                                    .docName)
                                                                .get();
                                                        int commentcount =
                                                            contentdocs[
                                                                'commentcount'];
                                                        contentcollection
                                                            .doc(widget.docName)
                                                            .update({
                                                          'commentcount':
                                                              commentcount - 1,
                                                        });
                                                        setState(() {
                                                          totalcomments =
                                                              totalcomments - 1;
                                                        });*/
                                                      },
                                                      child: const Text("Yes",
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color:
                                                                kPrimaryColor,
                                                          ))),
                                                )
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ));
                          },
                          child: Text(
                            "Delete this comment",
                            style: Theme.of(context).textTheme.button!.copyWith(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: 5.0, top: 5.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            primary: Colors.white70,
                            minimumSize: Size.zero,
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            print(
                                "Bottom sheet for selecting reason for reporting comment...");
                            commentReportSheet(c.docName, c.commentId);
                          },
                          child: Text(
                            "Report this comment",
                            style: Theme.of(context).textTheme.button!.copyWith(
                                color: Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ),
              trailing: Column(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _upvoteComment(c.commentId),
                      child: Icon(Icons.arrow_upward_outlined,
                          size: 20,
                          color: (c.likes.contains(onlineuid))
                              ? kPrimaryColor
                              : Colors.white),
                    ),
                  ),
                  Text("${c.likes.length - c.dislikes.length}",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontSize: 10.0, color: Colors.white70)),
                  Expanded(
                    child: InkWell(
                      onTap: () => _downvoteComment(c.commentId),
                      child: Icon(Icons.arrow_downward,
                          size: 20,
                          color: (c.dislikes.contains(onlineuid))
                              ? kPrimaryColor
                              : Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
  }*/

  /* Widget commentCardDeleted() {
    return Container(
      //color: Theme.of(context).primaryIconTheme.color,
      child: StreamBuilder<QuerySnapshot>(
        stream: commentStream,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            print("getting comments");
            return const Center(
                child: CupertinoActivityIndicator(
              color: kDarkPrimaryColor,
            ));
          }
          return ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            //reverse: true,
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            //controller: controller,
            itemCount: snapshot.data.docs.length,
            itemBuilder: (BuildContext context, int index) {
              var comment = snapshot.data.docs[index];
              if (comment['blockedby'].contains(onlineuid)) {
                return Container();
              } else {
                return Card(
                  color: kBackgroundColorDark,
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            commentHeaderStream(comment['uid']),
                            const SizedBox(width: 5.0),
                            Text(
                              tago.format(comment['time'].toDate()),
                              style: Theme.of(context)
                                  .textTheme
                                  .caption!
                                  .copyWith(
                                      fontSize: 10.0,
                                      color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        Text(
                          "${comment['comment']}",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    subtitle: (comment['uid'] == onlineuid)
                        ? Padding(
                            padding:
                                const EdgeInsets.only(right: 5.0, top: 5.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  primary: Colors.white70,
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  showModalBottomSheet(
                                      context: context,
                                      builder: (builder) => Container(
                                            height: (MediaQuery.of(context)
                                                    .size
                                                    .height) /
                                                6,
                                            width: (MediaQuery.of(context)
                                                .size
                                                .width),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 20, vertical: 20),
                                            child: Column(
                                              children: [
                                                const Text(
                                                    'Are you sure you want to delete this comment?',
                                                    style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Colors.white)),
                                                const SizedBox(height: 20),
                                                Expanded(
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10.0),
                                                        child: TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                "Cancel",
                                                                style:
                                                                    TextStyle(
                                                                  color:
                                                                      kPrimaryColor,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ))),
                                                      ),
                                                      Container(
                                                        color: Colors.grey[500],
                                                        width: 0.5,
                                                        height: 22,
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10.0),
                                                        child: TextButton(
                                                            onPressed:
                                                                () async {
                                                              Navigator.pop(
                                                                  context);
                                                              snapshot
                                                                  .data
                                                                  .docs[index]
                                                                  .reference
                                                                  .delete();
                                                              var contentdocs =
                                                                  await contentcollection
                                                                      .doc(widget
                                                                          .docName)
                                                                      .get();
                                                              int commentcount =
                                                                  contentdocs[
                                                                      'commentcount'];
                                                              contentcollection
                                                                  .doc(widget
                                                                      .docName)
                                                                  .update({
                                                                'commentcount':
                                                                    commentcount -
                                                                        1,
                                                              });
                                                              setState(() {
                                                                totalcomments =
                                                                    totalcomments -
                                                                        1;
                                                              });
                                                            },
                                                            child: const Text(
                                                                "Yes",
                                                                style:
                                                                    TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      kPrimaryColor,
                                                                ))),
                                                      )
                                                    ],
                                                  ),
                                                )
                                              ],
                                            ),
                                          ));
                                },
                                child: Text(
                                  "Delete this comment",
                                  style: Theme.of(context)
                                      .textTheme
                                      .button!
                                      .copyWith(
                                          color: Colors.redAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          )
                        : Padding(
                            padding:
                                const EdgeInsets.only(right: 5.0, top: 5.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  primary: Colors.white70,
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  print(
                                      "Bottom sheet for selecting reason for reporting comment...");
                                  commentReportSheet(
                                      comment['docName'], comment['id']);
                                },
                                child: Text(
                                  "Report this comment",
                                  style: Theme.of(context)
                                      .textTheme
                                      .button!
                                      .copyWith(
                                          color: Colors.redAccent,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                          ),
                    trailing: Column(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _upvoteComment(comment['id']),
                            child: Icon(Icons.arrow_upward_outlined,
                                size: 20,
                                color: (comment['likes'].contains(onlineuid))
                                    ? kPrimaryColor
                                    : Colors.white),
                          ),
                        ),
                        Text(
                            "${comment['likes'].length - comment['dislikes'].length}",
                            style: Theme.of(context)
                                .textTheme
                                .subtitle2!
                                .copyWith(
                                    fontSize: 10.0, color: Colors.white70)),
                        Expanded(
                          child: InkWell(
                            onTap: () => _downvoteComment(comment['id']),
                            child: Icon(Icons.arrow_downward,
                                size: 20,
                                color: (comment['dislikes'].contains(onlineuid))
                                    ? kPrimaryColor
                                    : Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }*/

  Widget _commentBox() {
    return Container(
      color: kBackgroundColorDark2,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 5.0,
          right: 5.0,
          top: 5.0,
          bottom: 10.0,
        ),
        child: new TextFormField(
          readOnly: true,
          onTap: () {
            showCommentSheet('Comment', '', 0, 0, _commentController, null);
          },
          cursorColor: Colors.black,
          style: const TextStyle(
            color: kHeadlineColorDark,
          ),
          controller: _commentController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: "Add your comment...",
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
            fillColor: kBackgroundColorDark,
            contentPadding: const EdgeInsets.only(left: 16),
          ),
        ),
      ),
    );
  }

  showCommentSheet(
      String typingWhat,
      String parentCommentId,
      int parentIndentLevel,
      int repliesCount,
      TextEditingController _textEditingController,
      CommentModel? c) {
    showModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalsetState) {
            return Container(
              color: kBackgroundColorDark,
              height: double.infinity,
              width: double.infinity,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 50.0, left: 10, right: 10, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.arrow_back,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text("Add $typingWhat"),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0),
                          child: (showPublishButton == false)
                              ? Text(
                                  (typingWhat == 'Edit') ? 'Update' : "Publish",
                                  style: Theme.of(context)
                                      .textTheme
                                      .button!
                                      .copyWith(
                                        color: kIconSecondaryColorDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                )
                              : InkWell(
                                  onTap: () {
                                    if (typingWhat == 'Edit') {
                                      if (_editingController.text.isNotEmpty) {
                                        updateComment(c!);
                                      }
                                    } else {
                                      if (_commentController.text.isNotEmpty) {
                                        if (typingWhat == 'Comment') {
                                          publishComment();
                                        } else if (typingWhat == 'Reply') {
                                          replyComment(
                                              parentCommentId,
                                              parentIndentLevel,
                                              repliesCount,
                                              c!);
                                        }
                                      }
                                    }
                                  },
                                  child: Text(
                                    (typingWhat == 'Edit')
                                        ? 'Update'
                                        : "Publish",
                                    style: Theme.of(context)
                                        .textTheme
                                        .button!
                                        .copyWith(
                                          color: kPrimaryColorTint2,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    thickness: 1,
                    color: Colors.grey.shade800,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        onChanged: (text) {
                          String trimmedText = text.trim();
                          if (trimmedText.isEmpty) {
                            if (showPublishButton == true) {
                              modalsetState(() {
                                showPublishButton = false;
                                print("hiding send button!");
                              });
                            }
                          } else {
                            if (showPublishButton == false) {
                              modalsetState(() {
                                showPublishButton = true;
                                print("showing Publish button!");
                              });
                            }
                          }
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: _textEditingController,
                        //maxLength: maxLength,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1!
                            .copyWith(color: Colors.white),
                        decoration: const InputDecoration.collapsed(
                          hintText: 'Start typing comment...',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          });
        });
  }

  Future<int> getRepliesCount(String parentCommentId) async {
    var commentdocs =
        await commentsdb.child(widget.docName).child(parentCommentId).get();

    final int repliesCount = (commentdocs.value as Map)['repliesCount'];
    print('Replies Count is $repliesCount');
    return repliesCount;
  }

  void replyComment(String parentCommentId, int parentIndentLevel,
      int repliesCount, CommentModel c) async {
    int latestRepliesCount;
    final String commentContent = _commentController.text;
    _commentController.clear();
    setState(() {
      showPublishButton = false;
    });
    final String commentId = generateRandomDocName(onlineusername);
    final time = DateTime.now();
    final timestamp = time.millisecondsSinceEpoch;

    await commentsdb
        .child(widget.docName)
        .child(parentCommentId)
        .child('replies')
        .child(commentId)
        .set({
      'content': commentContent,
      'commentId': commentId,
      'parentCommentId': parentCommentId,
      'docName': widget.docName,
      'time': timestamp,
      'type': 'text',
      'status': 'published',
      'posterUid': onlineuid,
      'posterUsername': onlineusername,
      'likes': [],
      'dislikes': [],
      'blockedBy': [],
      'repliesCount': 0,
      'path': '${widget.docName}/$parentCommentId/replies/$commentId',
      'indentLevel': (parentIndentLevel + 1),
    }).then(
      (_) async => getRepliesCount(parentCommentId).then((value) async => {
            latestRepliesCount = value + 1,
            setState(() {
              c.repliesCount = latestRepliesCount;
            }),
            await commentsdb
                .child(widget.docName)
                .child(parentCommentId)
                .update({
              'repliesCount': latestRepliesCount,
            }).then((_) async => {
                      await contentcollection
                          .doc(widget.docName)
                          .update({
                            'commentcount': FieldValue.increment(1),
                          })
                          .then((_) => {
                                if (latestRepliesCount == 1)
                                  {
                                    loadReplies(c).then((_) => Future.delayed(
                                        const Duration(milliseconds: 500),
                                        () {})),
                                  }
                              })
                          .then((_) => {
                                setState(() {
                                  c.showReplies = true;
                                })
                              })
                          .then((_) => {
                                Navigator.pop(context),
                              })
                    }),
          }),
    );
  }

  /*.then((value) async => {
              await commentsdb
                  .child(widget.docName)
                  .child(parentCommentId)
                  .update({
                'repliesCount': repliesCount + 1,
              }).then((_) => {
                        contentcollection.doc(widget.docName).update({
                          'commentcount': FieldValue.increment(1),
                        }).then((_) => {
                              Navigator.pop(context),
                            }),
                      })
            });*/

  void publishComment() async {
    final String commentContent = _commentController.text;
    _commentController.clear();
    setState(() {
      showPublishButton = false;
    });
    final String commentId = generateRandomDocName(onlineusername);
    final time = DateTime.now();
    final timestamp = time.millisecondsSinceEpoch;

    await commentsdb.child(widget.docName).child(commentId).set({
      'content': commentContent,
      'commentId': commentId,
      'parentCommentId': commentId,
      'docName': widget.docName,
      'time': timestamp,
      'type': 'text',
      'status': 'published',
      'posterUid': onlineuid,
      'posterUsername': onlineusername,
      'likes': [],
      'dislikes': [],
      'blockedBy': [],
      'repliesCount': 0,
      'path': '${widget.docName}/$commentId',
      'indentLevel': 1,
    }).then((_) async => {
          contentcollection.doc(widget.docName).update({
            'commentcount': FieldValue.increment(1),
          }).then((_) => {
                Navigator.pop(context),
              }),
        });
  }

  /*
  void _upvoteComment(String? id) async {
    var doc = await contentcollection
        .doc(widget.docName)
        .collection('comments')
        .doc(id)
        .get();
    if (doc['likes'].contains(onlineuid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'likes': FieldValue.arrayRemove([onlineuid])
      });
    } else if (doc['dislikes'].contains(onlineuid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'dislikes': FieldValue.arrayRemove([onlineuid]),
        'likes': FieldValue.arrayUnion([onlineuid])
      });
    } else {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'likes': FieldValue.arrayUnion([onlineuid])
      });
    }
  }

  void _downvoteComment(String? id) async {
    var doc = await contentcollection
        .doc(widget.docName)
        .collection('comments')
        .doc(id)
        .get();
    if (doc['dislikes'].contains(onlineuid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'dislikes': FieldValue.arrayRemove([onlineuid])
      });
    } else if (doc['likes'].contains(onlineuid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'likes': FieldValue.arrayRemove([onlineuid]),
        'dislikes': FieldValue.arrayUnion([onlineuid])
      });
    } else {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'dislikes': FieldValue.arrayUnion([onlineuid])
      });
    }
  }
  */

  showUserQuickInfo(String userName, String uid) {
    showCupertinoModalPopup(
        useRootNavigator: false,
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
              title: Text(
                "Go To",
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: kSubTextColor,
                      fontSize: 17.0,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              actions: <CupertinoActionSheetAction>[
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: ((context) => ProfilePage(
                                  uid: uid,
                                  whetherShowArrow: true,
                                ))));
                    //removepicture();
                  },
                  child: Text(
                    '$userName\'s profile',
                    style: Theme.of(context).textTheme.button!.copyWith(
                          fontSize: 17.0,
                          color: kPrimaryColorTint2,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                child: Text(
                  "Close",
                  style: Theme.of(context).textTheme.button!.copyWith(
                        fontSize: 17.0,
                        color: kPrimaryColorTint2,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ));
  }

  showCommunityQuickInfo(String communityName, String userName, String uid) {
    showCupertinoModalPopup(
        useRootNavigator: false,
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
              title: Text(
                "Go To",
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: kSubTextColor,
                      fontSize: 17.0,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              actions: <CupertinoActionSheetAction>[
                CupertinoActionSheetAction(
                  //isDefaultAction: true,
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: ((context) => CommunityPage(
                                whetherjustcreated: false,
                                communityname: communityName))));
                  },
                  child: Text(
                    'c/$communityName page',
                    style: Theme.of(context).textTheme.button!.copyWith(
                          fontSize: 17.0,
                          color: kPrimaryColorTint2,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                CupertinoActionSheetAction(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: ((context) => ProfilePage(
                                  uid: uid,
                                  whetherShowArrow: true,
                                ))));
                  },
                  child: Text(
                    '$userName\'s profile',
                    style: Theme.of(context).textTheme.button!.copyWith(
                          fontSize: 17.0,
                          color: kPrimaryColorTint2,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
              cancelButton: CupertinoActionSheetAction(
                child: Text(
                  "Close",
                  style: Theme.of(context).textTheme.button!.copyWith(
                        fontSize: 17.0,
                        color: kPrimaryColorTint2,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ));
  }

  Widget postHeader() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 10.0,
          //top: 5.0,
          bottom: 5.0,
        ),
        child: GestureDetector(
          onTap: () {
            if (whethercommunitypost == true) {
              showCommunityQuickInfo(communityName!, opusername, opuid);
            } else {
              showUserQuickInfo(opusername, opuid);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: new BoxDecoration(
                  shape: BoxShape.circle,
                  border: new Border.all(
                    color: kIconSecondaryColorDark,
                    width: 2.0,
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.grey.shade500,
                  radius: 15.0,
                  backgroundImage:
                      const AssetImage('assets/images/default-profile-pic.png'),
                  child: CircleAvatar(
                    radius: 15.0,
                    backgroundColor: Colors.transparent,
                    backgroundImage: (whethercommunitypost == false)
                        ? NetworkImage(oppic)
                        : NetworkImage(communitypic!),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (whethercommunitypost == false)
                          ? opusername
                          : "c/$communityName",
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            fontSize: 15.0,
                            color: kHeadlineColorDark,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.24,
                          ),
                    ),
                    Text(
                      (whethercommunitypost == false)
                          ? "• ${tago.format(timeofposting.toDate())} •"
                          : "$opusername • ${tago.format(timeofposting.toDate())} •",
                      style: Theme.of(context).textTheme.caption!.copyWith(
                            fontSize: 13.0,
                            color: kSubTextColor,
                            letterSpacing: -0.08,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final double topPadding = MediaQuery.of(context).padding.top;
    return WillPopScope(
      onWillPop: () {
        if (widget.hideNavLinkReturn != null) {
          print("returning from link");
          hidenav = widget.hideNavLinkReturn!;
          AppBuilder.of(context)!.rebuild();
          Navigator.pop(context);
        } else {
          if (widget.whetherjustcreated == false) {
            setState(() {
              hidenav = false;
            });
            AppBuilder.of(context)!.rebuild();
            Navigator.pop(context);
          } else {
            if (whethercommunitypost == false) {
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
              int count = 0;
              Navigator.of(context).popUntil((_) => count++ >= 2);
            }
          }
        }
        return Future.value(false);
      },
      child: (postdataexists == false)
          ? Scaffold(
              appBar: AppBar(
                leading: GestureDetector(
                  onTap: () {
                    if (widget.hideNavLinkReturn != null) {
                      print("returning from link");
                      hidenav = widget.hideNavLinkReturn!;
                      AppBuilder.of(context)!.rebuild();
                      Navigator.pop(context);
                    } else {
                      if (widget.whetherjustcreated == false) {
                        setState(() {
                          hidenav = false;
                        });
                        AppBuilder.of(context)!.rebuild();
                        Navigator.pop(context);
                      } else {
                        if (whethercommunitypost == false) {
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
                          int count = 0;
                          Navigator.of(context).popUntil((_) => count++ >= 2);
                        }
                      }
                    }
                  },
                  child: const Icon(
                    Icons.arrow_back,
                  ),
                ),
              ),
              body: const SafeArea(
                  child: Center(
                child: CupertinoActivityIndicator(
                  color: kPrimaryColor,
                ),
              )),
            )
          : (checkwhetherblocked == true)
              ? Scaffold(
                  appBar: AppBar(
                    leading: GestureDetector(
                      onTap: () {
                        if (widget.hideNavLinkReturn != null) {
                          print("returning from link");
                          hidenav = widget.hideNavLinkReturn!;
                          AppBuilder.of(context)!.rebuild();
                          Navigator.pop(context);
                        } else {
                          if (widget.whetherjustcreated == false) {
                            setState(() {
                              hidenav = false;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.pop(context);
                          } else {
                            if (whethercommunitypost == false) {
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
                              int count = 0;
                              Navigator.of(context)
                                  .popUntil((_) => count++ >= 2);
                            }
                          }
                        }
                      },
                      child: const Icon(
                        Icons.arrow_back,
                      ),
                    ),
                  ),
                  resizeToAvoidBottomInset: false,
                  body: SafeArea(
                    child: Center(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.block_outlined,
                          color: Colors.redAccent,
                          size: 50,
                        ),
                        Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: Text("Post hidden for you after reporting.",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(color: Colors.white)),
                        ),
                        TextButton(
                            child: Text("Show anyway",
                                style: Theme.of(context)
                                    .textTheme
                                    .button!
                                    .copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: kPrimaryColor,
                                        fontSize: 15.0)),
                            onPressed: () {
                              unblockReportedContent();
                            }),
                      ],
                    )),
                  ),
                )
              : (checkwhetherdeleted == true)
                  ? Scaffold(
                      appBar: AppBar(
                        leading: GestureDetector(
                          onTap: () {
                            if (widget.hideNavLinkReturn != null) {
                              print("returning from link");
                              hidenav = widget.hideNavLinkReturn!;
                              AppBuilder.of(context)!.rebuild();
                              Navigator.pop(context);
                            } else {
                              if (widget.whetherjustcreated == false) {
                                setState(() {
                                  hidenav = false;
                                });
                                AppBuilder.of(context)!.rebuild();
                                Navigator.pop(context);
                              } else {
                                if (whethercommunitypost == false) {
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
                                  int count = 0;
                                  Navigator.of(context)
                                      .popUntil((_) => count++ >= 2);
                                }
                              }
                            }
                          },
                          child: const Icon(
                            Icons.arrow_back,
                          ),
                        ),
                      ),
                      resizeToAvoidBottomInset: false,
                      body: SafeArea(
                        child: Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.delete,
                              color: Colors.redAccent,
                              size: 50,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(30.0),
                              child: Text("Post deleted.",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(color: Colors.white)),
                            ),
                          ],
                        )),
                      ),
                    )
                  : Scaffold(
                      extendBodyBehindAppBar: true,
                      appBar: PreferredSize(
                        preferredSize: const Size.fromHeight(0),
                        child: AppBar(
                          elevation: 0,
                          backgroundColor: kBackgroundColorDark2,
                          systemOverlayStyle: const SystemUiOverlayStyle(
                            statusBarColor: kBackgroundColorDark2,
                            statusBarBrightness: Brightness.dark,
                          ),
                        ),
                      ),
                      bottomNavigationBar: _commentBox(),
                      body: SafeArea(
                        child: RefreshIndicator(
                          onRefresh: _pulltoRefreshPage,
                          child: (postdataexists == false)
                              ? const Center(
                                  child: CupertinoActivityIndicator(
                                    color: kDarkPrimaryColor,
                                  ),
                                )
                              : Container(
                                  child: CustomScrollView(
                                    slivers: [
                                      SliverAppBar(
                                        toolbarHeight: 80,
                                        actions: [
                                          moreOptions(),
                                        ],
                                        leading: GestureDetector(
                                          onTap: () {
                                            if (widget.hideNavLinkReturn !=
                                                null) {
                                              print("returning from link");
                                              hidenav =
                                                  widget.hideNavLinkReturn!;
                                              AppBuilder.of(context)!.rebuild();
                                              Navigator.pop(context);
                                            } else {
                                              if (widget.whetherjustcreated ==
                                                  false) {
                                                setState(() {
                                                  hidenav = false;
                                                });
                                                AppBuilder.of(context)!
                                                    .rebuild();
                                                Navigator.pop(context);
                                              } else {
                                                if (whethercommunitypost ==
                                                    false) {
                                                  setState(() {
                                                    hidenav = false;
                                                  });
                                                  AppBuilder.of(context)!
                                                      .rebuild();
                                                  Navigator.of(context)
                                                      .popUntil((route) =>
                                                          route.isFirst);
                                                } else {
                                                  setState(() {
                                                    hidenav = false;
                                                  });
                                                  AppBuilder.of(context)!
                                                      .rebuild();
                                                  int count = 0;
                                                  Navigator.of(context)
                                                      .popUntil(
                                                          (_) => count++ >= 2);
                                                }
                                              }
                                            }
                                          },
                                          child: (featuredimage == '')
                                              ? const Icon(Icons.arrow_back)
                                              : const Icon(
                                                  CupertinoIcons
                                                      .arrow_left_circle_fill,
                                                  size: 30,
                                                ),

                                          /*Center(
                                          child: Image.asset(
                                              'assets/icons/arrow_back_circle_ios.png',
                                              width: 30.0,
                                              height: 30.0),
                                        ),*/

                                          /*const Icon(
                                          Icons.arrow_back,
                                          color: kIconSecondaryColorDark,
                                        ),*/
                                        ),
                                        bottom: PreferredSize(
                                            child: Container(
                                                color: kBackgroundColorDark2,
                                                width: double.maxFinite,
                                                child: postHeader()),
                                            preferredSize:
                                                const Size.fromHeight(20)),
                                        pinned: true,
                                        backgroundColor: kBackgroundColorDark2,
                                        expandedHeight:
                                            (featuredimage == '') ? 0 : 200,
                                        flexibleSpace: (featuredimage == '')
                                            ? null
                                            : FlexibleSpaceBar(
                                                background: InkWell(
                                                  onTap: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          PreviewTextImage(
                                                        whetherfromtextpost:
                                                            true,
                                                        docName: widget.docName,
                                                        upvoteCount: totallikes,
                                                        downvoteCount:
                                                            totaldislikes,
                                                        commentCount:
                                                            totalcomments,
                                                        whetherUpvoted:
                                                            likedpost,
                                                        whetherDownvoted:
                                                            dislikedpost,
                                                        imageUrl: featuredimage,
                                                        infotext: textTopic,
                                                        infoDescription:
                                                            briefdescription,
                                                        onlineuid: onlineuid,
                                                      ),
                                                      fullscreenDialog: true,
                                                    ),
                                                  ),
                                                  child: Image.network(
                                                    featuredimage,
                                                    width: double.maxFinite,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      SliverToBoxAdapter(
                                        child: Column(
                                          children: [
                                            Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 10.0,
                                                    right: 10.0,
                                                    top: 10.0,
                                                  ),
                                                  child: Text(
                                                    textTopic,
                                                    style: styleTitleSmall(),
                                                  ),
                                                ),
                                                const SizedBox(height: 10.0),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: Container(
                                                    //height: 200,
                                                    child: MarkdownBody(
                                                      data: contentText,
                                                      styleSheet:
                                                          styleSheetforMarkdown(
                                                              context),
                                                      onTapLink: (text, url,
                                                          title) async {
                                                        openBrowserURL(
                                                            url: url!);
                                                      },
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 10.0,
                                                          right: 10.0),
                                                  child: UpDownVoteWidget(
                                                      whetherIconsBig: true,
                                                      upvoteCount: totallikes,
                                                      downvoteCount:
                                                          totaldislikes,
                                                      commentCount:
                                                          totalcomments,
                                                      onUpvoted: () =>
                                                          _checkUpvotePost(),
                                                      onDownvoted: () =>
                                                          _checkDownvotePost(),
                                                      onShared: () =>
                                                          ShareService
                                                              .shareContent(
                                                            widget.docName,
                                                            'textpost',
                                                            textTopic,
                                                            briefdescription,
                                                            featuredimage,
                                                          ),
                                                      whetherUpvoted: likedpost,
                                                      whetherDownvoted:
                                                          dislikedpost,
                                                      onComment: () {}),
                                                ),
                                                //actionCard(),
                                              ],
                                            ),
                                            const SizedBox(height: 10.0),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  //crossAxisAlignment: CrossAxisAlignment.center,
                                                  //mainAxisSize: MainAxisSize.max,
                                                  children: [
                                                    Text(
                                                      'Comments',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subtitle1!
                                                          .copyWith(
                                                            color:
                                                                kSubTextColor,
                                                            fontSize: 15.0,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            letterSpacing:
                                                                -0.24,
                                                          ),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        showDialog(
                                                          context: context,
                                                          barrierDismissible:
                                                              true,
                                                          builder: (context) {
                                                            return AlertDialog(
                                                              contentPadding:
                                                                  const EdgeInsets
                                                                          .only(
                                                                      left: 10,
                                                                      right:
                                                                          10),
                                                              title: Column(
                                                                  children: [
                                                                    GestureDetector(
                                                                      onTap:
                                                                          () {
                                                                        //print("closing...");
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      },
                                                                      child:
                                                                          const Align(
                                                                        alignment:
                                                                            Alignment.topRight,
                                                                        child:
                                                                            Icon(
                                                                          Icons
                                                                              .close,
                                                                          size:
                                                                              25.0,
                                                                          color:
                                                                              kPrimaryColorTint2,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const Center(
                                                                      child:
                                                                          Text(
                                                                        "UGC Policy",
                                                                        style: TextStyle(
                                                                            fontSize:
                                                                                15.0,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: Colors.white),
                                                                      ),
                                                                    ),
                                                                  ]),
                                                              shape:
                                                                  const RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .all(
                                                                  Radius
                                                                      .circular(
                                                                          20.0),
                                                                ),
                                                              ),
                                                              content:
                                                                  Container(
                                                                height: (MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .height) /
                                                                    1.2,
                                                                width: (MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width) /
                                                                    1.2,
                                                                child: Column(
                                                                  children: [
                                                                    Container(
                                                                      child:
                                                                          Expanded(
                                                                        child: SingleChildScrollView(
                                                                            child: Text(
                                                                          ugcRules,
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                12.0,
                                                                            color:
                                                                                Colors.white70,
                                                                          ),
                                                                        )),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                      },
                                                      child: Text(
                                                        "UGC Policy",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .subtitle1!
                                                            .copyWith(
                                                              color: Colors
                                                                  .blueGrey,
                                                              fontSize: 15.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              letterSpacing:
                                                                  -0.24,
                                                            ),
                                                      ),
                                                    ),
                                                  ]),
                                            ),
                                            (commentdataexists == false)
                                                ? const CupertinoActivityIndicator(
                                                    color: kDarkPrimaryColor,
                                                  )
                                                : commentCardNew(),
                                          ],
                                        ),
                                      ),
                                      /* SliverFillRemaining(
                          hasScrollBody: true,
                          //fillOverscroll: true,
                          child: 
                        )*/
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
    );
  }
}
