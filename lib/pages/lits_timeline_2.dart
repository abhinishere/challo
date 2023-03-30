import 'dart:async';
import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/pages/add_lits.dart';
import 'package:challo/helpers/share_service.dart';
import 'package:challo/models/comment_model.dart';
import 'package:challo/models/lits_model.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/community_page.dart';
import 'package:challo/pages/lits_update.dart';
import 'package:challo/pages/profilepage.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/comment_bottom.dart';
import 'package:challo/widgets/event_widget.dart';
import 'package:challo/widgets/updownvotewidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as tago;

class LitsTimeline2 extends StatefulWidget {
  final String docName;
  final bool whetherJustCreated;
  final bool? hideNavLinkReturn;
  const LitsTimeline2({
    required this.docName,
    required this.whetherJustCreated,
    this.hideNavLinkReturn,
  });

  @override
  State<LitsTimeline2> createState() => _LitsTimeline2State();
}

class _LitsTimeline2State extends State<LitsTimeline2>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    getlitsdata();
    getLitsUpdateData();
    getCommentData();
  }

  final ScrollController _myController = ScrollController();

  bool popAnyChanges = false;

  String selectedTab = 'Timeline';

  bool dataisthere = false;

  bool litsupdatedataisthere = false;

  bool commentdataexists = false;
  bool showsendbutton = false;

  bool whetherLitsDeleted = false;
  bool whetherLitsBlocked = false;

  late String litsTopic, litsDescription, featuredImage, litsType, litsStatus;

  late List<String> litsLikes, litsDislikes, litsViews;

  late dynamic timeofposting;

  late bool likedpost, dislikedpost;
  late int totallikes, totaldislikes, totalcomments, updownratio;
  late bool whethercommunitypost;
  late String communityName, communitypic;
  late String opuid, opusername, oppic;
  late String onlineuid, onlinepic, onlineusername;

  late TabController _tabController;

  //comments' variables
  late String commentsPath;
  late StreamSubscription commentStreamSubscription;
  late List<CommentModel> commentsList;
  late Map<String?, List<CommentModel>?> repliesMap;

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateRandomDocName(String username) {
    String newDocName = (username + getRandomString(5));
    return newDocName;
  }

  int selectedCommentRadioNo = 1;
  int selectedContentRadioNo = 1;
  String commentReportReason = 'Spam or misleading';
  String contentReportReason = 'Spam or misleading';
  bool whethercommentreportsubmitted = false;
  bool whethercontentreportsubmitted = false;

  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _editingController = TextEditingController();

  late String litsUpdatePath;
  //late StreamSubscription _litsStreamSubscription;
  List<LitsModel> litsUpdatesList = [];

  getlitsdata() async {
    _tabController = new TabController(vsync: this, length: 2);
    _tabController.addListener(() {
      if (selectedTab == 'Timeline' && _tabController.index == 1) {
        setState(() {
          selectedTab = 'Chats';
        });
      } else if (selectedTab == 'Chats' && _tabController.index == 0) {
        FocusScope.of(context).unfocus();
        setState(() {
          selectedTab = 'Timeline';
        });
      }
    });

    onlineuid = FirebaseAuth.instance.currentUser!.uid;

    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateString = dateFormat.format(DateTime.now());
    await litscollection.doc(widget.docName).update({
      'totalviews': FieldValue.arrayUnion(["$onlineuid $dateString"])
    });

    var onlineuserdoc = await usercollection.doc(onlineuid).get();

    onlineusername = onlineuserdoc['username'];

    onlinepic = onlineuserdoc['profilepic'];

    var litsDoc = await litscollection.doc(widget.docName).get();

    List<String> blockedbylist = List.from(litsDoc['blockedby']);

    if (blockedbylist.contains(onlineuid)) {
      setState(() {
        whetherLitsBlocked = true;
      });
    }

    litsTopic = litsDoc['topic'];
    litsDescription = litsDoc['description'];
    featuredImage = litsDoc['image'];
    litsType = litsDoc['type'];
    litsStatus = litsDoc['status'];

    if (litsStatus == 'deleted') {
      whetherLitsDeleted = true;
    }

    litsLikes = List.from(litsDoc['likes']);
    litsDislikes = List.from(litsDoc['dislikes']);
    litsViews = List.from(litsDoc['totalviews']);
    timeofposting = litsDoc['time'];

    whethercommunitypost = litsDoc['whethercommunitypost'];
    communityName = litsDoc['communityName'];
    communitypic = litsDoc['communitypic'];

    opuid = litsDoc['opuid'];
    opusername = litsDoc['opusername'];
    oppic = litsDoc['oppic'];

    totallikes = litsLikes.length;
    totaldislikes = litsDislikes.length;

    if (litsLikes.contains(onlineuid)) {
      setState(() {
        likedpost = true;
      });
    } else {
      likedpost = false;
    }

    if (litsDislikes.contains(onlineuid)) {
      setState(() {
        dislikedpost = true;
      });
    } else {
      dislikedpost = false;
    }

    updownratio = totallikes - totaldislikes;

    totalcomments = litsDoc['commentcount'];

    setState(() {
      dataisthere = true;
    });
  }

  getLitsUpdateData() async {
    litsUpdatePath = 'litsdb/${widget.docName}';
    FirebaseDatabase.instance
        .ref()
        .child(litsUpdatePath)
        .orderByChild('time')
        .onChildAdded
        .listen((event) async {
      setState(() {
        final LitsModel newLit = LitsModel.fromJson(event.snapshot);
        if (newLit.status == 'published') {
          litsUpdatesList.add(newLit);
        }
      });
    });
    setState(() {});
    setState(() {
      litsupdatedataisthere = true;
    });
  }

  getCommentData() async {
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

  Widget commentCardNew() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        children: [
          for (CommentModel c in commentsList.reversed) commentCardWidget(c),
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

  Widget commentCardWidget(CommentModel c) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
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
          onReply: null,
          onlineuid: onlineuid,
          comment: c,
          onUpvoted: () => upvotePost(c),
          onDownvoted: () => downvotePost(c),
        ),
        replyShowWidget(c),
        const Divider(
          thickness: 1,
          color: kBackgroundColorDark2,
        ),
      ],
    );
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

  contentReportSubmit(String reason) async {
    await litscollection.doc(widget.docName).update({
      'blockedby': FieldValue.arrayUnion([onlineuid])
    });
    var contentinuserdocs = await usercollection
        .doc(opuid)
        .collection('lits')
        .doc(widget.docName)
        .get();

    if (!contentinuserdocs.exists) {
    } else {
      await usercollection
          .doc(opuid)
          .collection('lits')
          .doc(widget.docName)
          .update({
        'blockedby': FieldValue.arrayUnion([onlineuid])
      });
    }
    await contentreportcollection
        .doc(generateRandomDocName(onlineusername))
        .set({
      'type': 'litspost',
      'status': 'reported', //reported -> deleted/noaction/pending
      'reporter': onlineuid,
      'docName': widget.docName,
      'reason': reason,
      'time': DateTime.now(),
    });
    setState(() {
      popAnyChanges = true;
      whetherLitsBlocked = true;
    });
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
          /*CupertinoActionSheetAction(
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
          ),*/
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
    /*setState(() {
      _editingController.text = c.content;
    });
    showCommentSheet('Edit', c.parentCommentId, c.indentLevel, c.repliesCount,
        _editingController, c);*/
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
                            repliesMap[c.commentId]![index]);
                      },
                      reverse: false,
                    ),
                  );
  }

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

  @override
  void dispose() {
    _tabController.dispose();
    _myController.dispose();
    super.dispose();
  }

  Widget tabButton(String buttonText, int whichIndex, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (selectedTab == 'Chats' && buttonText == 'Timeline') {
          FocusScope.of(context).unfocus();
        }
        setState(() {
          selectedTab = buttonText;
          _tabController.animateTo(whichIndex);
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        margin: const EdgeInsets.only(left: 8),
        height: 30,
        decoration: BoxDecoration(
            color: isSelected ? kPrimaryColorTint : const Color(0xFF7f7f7f),
            borderRadius: BorderRadius.circular(5)),
        child: Text(
          buttonText,
          style: TextStyle(
            color: isSelected ? kHeadlineColorDark : kHeadlineColorDarkShade,
          ),
        ),
      ),
    );
  }

  void _checkUpvotePost() async {
    var postdoc = await litscollection.doc(widget.docName).get();

    if (postdoc['likes'].contains(onlineuid)) {
      litscollection.doc(widget.docName).update({
        'likes': FieldValue.arrayRemove([onlineuid])
      });
      setState(() {
        likedpost = false;
        dislikedpost = false;
        totallikes = totallikes - 1;
        updownratio = updowncount();
      });
    } else if (postdoc['dislikes'].contains(onlineuid)) {
      litscollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayRemove([onlineuid])
      });
      litscollection.doc(widget.docName).update({
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
      litscollection.doc(widget.docName).update({
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
    var postdoc = await litscollection.doc(widget.docName).get();

    if (postdoc['dislikes'].contains(onlineuid)) {
      litscollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayRemove([onlineuid])
      });
      setState(() {
        likedpost = false;
        dislikedpost = false;
        totaldislikes = totaldislikes - 1;
        updownratio = updowncount();
      });
    } else if (postdoc['likes'].contains(onlineuid)) {
      litscollection.doc(widget.docName).update({
        'likes': FieldValue.arrayRemove([onlineuid])
      });
      litscollection.doc(widget.docName).update({
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
      litscollection.doc(widget.docName).update({
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

  int updowncount() {
    return (totallikes - totaldislikes);
  }

  void publishComment() async {
    final String commentContent = _commentController.text;
    _commentController.clear();
    setState(() {
      showsendbutton = false;
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
          litscollection.doc(widget.docName).update({
            'commentcount': FieldValue.increment(1),
          })
        });
  }

  Widget postHeader() {
    return Container(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 15.0,
          top: 5.0,
          bottom: 5.0,
        ),
        child: GestureDetector(
          onTap: () {
            if (whethercommunitypost == true) {
              showCommunityQuickInfo(communityName, opusername, opuid);
            } else {
              showUserQuickInfo(opusername, opuid);
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CachedNetworkImage(
                imageUrl:
                    (whethercommunitypost == false) ? oppic : communitypic,
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    Container(
                  decoration: new BoxDecoration(
                    shape: BoxShape.circle,
                    border: new Border.all(
                      color: kIconSecondaryColorDark,
                      width: 2.0,
                    ),
                  ),
                  child: const CircleAvatar(
                    child: CupertinoActivityIndicator(
                      color: kPrimaryColorTint2,
                    ),
                    radius: 15.0,
                    backgroundColor: kBackgroundColorDark2,
                  ),
                ),
                imageBuilder: (context, imageProvider) => Container(
                  decoration: new BoxDecoration(
                    shape: BoxShape.circle,
                    border: new Border.all(
                      color: kIconSecondaryColorDark,
                      width: 2.0,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundImage: imageProvider,
                    radius: 15.0,
                    backgroundColor: kBackgroundColorDark2,
                  ),
                ),
              ),

              /*Container(
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
                        : NetworkImage(communitypic),
                  ),
                ),
              ),*/
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

  Widget _commentBox() {
    return Container(
      color: kBackgroundColorDark2,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 5.0,
          right: 5.0,
          top: 5.0,
          bottom: 15.0,
        ),
        child: new TextFormField(
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
          cursorColor: Colors.white,
          style: const TextStyle(
            color: kHeadlineColorDark,
          ),
          controller: _commentController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            suffixIcon: (showsendbutton == false)
                ? null
                : Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: InkWell(
                      onTap: () => publishComment(),
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
            hintText: "Add a live chat message...",
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

  showPostOptionsForOthers() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("More Options",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kSubTextColor,
                  fontSize: 17.0,
                  fontWeight: FontWeight.w500,
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
              'Report Lits',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 17.0,
                    color: kWarningColorDarkTint,
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
      ),
    );
  }

  showPostOptionsForOP() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("More Options",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kSubTextColor,
                  fontSize: 17.0,
                  fontWeight: FontWeight.w500,
                )),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context); //closing the bottom sheet
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddLits(
                    docName: widget.docName,
                    onlineuser: UserInfoModel(
                        uid: onlineuid,
                        username: onlineusername,
                        pic: onlinepic),
                    whetherEditing: true,
                    whetherFromPost: true,
                  ),
                  fullscreenDialog: true,
                ),
              ).then((whetherchanged) async => {
                    if (whetherchanged != null)
                      {
                        await litscollection
                            .doc(widget.docName)
                            .get()
                            .then((value) {
                          setState(() {
                            litsTopic = value['topic'];
                            litsDescription = value['description'];
                            featuredImage = value['image'];
                          });
                        }),
                      }
                  });
            },
            child: Text(
              'Edit Lits',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 17.0,
                    color: kPrimaryColorTint2,
                    fontWeight: FontWeight.w600,
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
              'Delete Lits',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 17.0,
                    color: kWarningColorDarkTint,
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
              await litscollection.doc(widget.docName).update({
                'status': 'deleted',
              }).then((_) async => {
                    await usercollection
                        .doc(onlineuid)
                        .collection('lits')
                        .doc(widget.docName)
                        .update({
                      'status': 'deleted',
                    }).then((_) => {
                              setState(() {
                                popAnyChanges = true;
                                whetherLitsDeleted = true;
                              })
                            })
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

  editDeleteLitsUpdate(int? index) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("More Options",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kSubTextColor,
                  fontSize: 17.0,
                  fontWeight: FontWeight.w500,
                )),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context); //closing the bottom sheet
              if (index == null || index < 0) {
                //error
              } else {
                final LitsModel lit = litsUpdatesList[index];

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LitsUpdate(
                      docName: widget.docName,
                      onlineuser: UserInfoModel(
                          uid: onlineuid,
                          username: onlineusername,
                          pic: onlinepic),
                      whetherEditing: true,
                      lit: lit,
                    ),
                    fullscreenDialog: true,
                  ),
                ).then((popAnyChanges) async => {
                      if (popAnyChanges != null)
                        {
                          setState(() {
                            litsupdatedataisthere = false;
                          }),
                          litsUpdatesList = [],
                          getLitsUpdateData(),
                        }
                    });
              }
            },
            child: Text(
              'Edit Lits event',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 17.0,
                    color: kPrimaryColorTint2,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            //isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              showDeleteEventConfirmation(index!);
            },
            child: Text(
              'Delete Lits event',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 17.0,
                    color: kWarningColorDarkTint,
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
      ),
    );
  }

  showDeleteEventConfirmation(int index) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("Sure you want to delete this event?",
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
              final LitsModel tbdlit = litsUpdatesList[index];
              Navigator.pop(context);
              await litsdb
                  .child(widget.docName)
                  .child(tbdlit.updateDocName)
                  .update({
                'status': 'deleted',
              }).then((_) => {
                        setState(() {
                          litsupdatedataisthere = false;
                        }),
                        litsUpdatesList = [],
                        getLitsUpdateData(),
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

  unblockReportedContent() async {
    await litscollection.doc(widget.docName).update({
      'blockedby': FieldValue.arrayRemove([onlineuid])
    });
    var contentinuserdocs = await usercollection
        .doc(opuid)
        .collection('lits')
        .doc(widget.docName)
        .get();

    if (!contentinuserdocs.exists) {
    } else {
      await usercollection
          .doc(opuid)
          .collection('lits')
          .doc(widget.docName)
          .update({
        'blockedby': FieldValue.arrayRemove([onlineuid])
      });
    }
    setState(() {
      whetherLitsBlocked = false;
    });
  }

  Widget showAllEvents() {
    return (litsupdatedataisthere == false)
        ? const Center(
            child: CupertinoActivityIndicator(color: kDarkPrimaryColor))
        : (litsUpdatesList.isEmpty)
            ? (onlineuid == opuid)
                ? const Center(
                    child: Text(
                        "Click the Add (+) icon at the bottom to get started"),
                  )
                : const Center(
                    child: Text("The poster hasn't added any events yet."))
            : Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Scrollbar(
                  controller: _myController,
                  child: ListView.builder(
                    controller: _myController,
                    shrinkWrap: true,
                    itemCount: litsUpdatesList.length,
                    physics: const ScrollPhysics(),
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: EventWidget(
                            editEvent: () {
                              editDeleteLitsUpdate(index);
                            },
                            whetherOP: (onlineuid == opuid),
                            lit: litsUpdatesList[index]),
                      );
                    },
                    reverse: false,
                  ),
                ),
              );
  }

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_myController.hasClients) {
        _myController.animateTo(
          _myController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: (selectedTab == 'Timeline')
            ? kBackgroundColorDark
            : kBackgroundColorDark2,
      ),
      child: (dataisthere == false)
          ? WillPopScope(
              onWillPop: () {
                setState(() {
                  hidenav = false;
                });
                AppBuilder.of(context)!.rebuild();
                if (widget.whetherJustCreated == false) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
                return Future.value(false);
              },
              child: Scaffold(
                appBar: AppBar(
                  systemOverlayStyle: const SystemUiOverlayStyle(
                    statusBarColor: kBackgroundColorDark,
                    statusBarBrightness: Brightness.dark,
                  ),
                  backgroundColor: Colors.transparent,
                  leading: GestureDetector(
                    child: InkWell(
                        onTap: () {
                          setState(() {
                            hidenav = false;
                          });
                          AppBuilder.of(context)!.rebuild();
                          if (widget.whetherJustCreated == false) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                        },
                        child:
                            const Icon(CupertinoIcons.arrow_left_circle_fill)),
                  ),
                ),
                body: const SafeArea(
                  child: Center(
                    child: CupertinoActivityIndicator(
                      color: kDarkPrimaryColor,
                    ),
                  ),
                ),
              ),
            )
          : (whetherLitsDeleted == true)
              ? WillPopScope(
                  onWillPop: () {
                    setState(() {
                      hidenav = false;
                    });
                    AppBuilder.of(context)!.rebuild();
                    if (widget.whetherJustCreated == false) {
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                    return Future.value(false);
                  },
                  child: Scaffold(
                    appBar: AppBar(
                      systemOverlayStyle: const SystemUiOverlayStyle(
                        statusBarColor: kBackgroundColorDark,
                        statusBarBrightness: Brightness.dark,
                      ),
                      leading: GestureDetector(
                        child: InkWell(
                            onTap: () {
                              setState(() {
                                hidenav = false;
                              });
                              AppBuilder.of(context)!.rebuild();
                              if (widget.whetherJustCreated == false) {
                                Navigator.pop(context, popAnyChanges);
                              } else {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              }
                            },
                            child: const Icon(
                                CupertinoIcons.arrow_left_circle_fill)),
                      ),
                      backgroundColor: Colors.transparent,
                    ),
                    body: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: const [
                            Icon(
                              CupertinoIcons.trash_fill,
                              color: kWarningColorDark,
                              size: 30.0,
                            ),
                            SizedBox(height: 10.0),
                            Text("This post appears to be deleted."),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : (whetherLitsBlocked == true)
                  ? WillPopScope(
                      onWillPop: () {
                        setState(() {
                          hidenav = false;
                        });
                        AppBuilder.of(context)!.rebuild();
                        if (widget.whetherJustCreated == false) {
                          Navigator.of(context).pop();
                        } else {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                        return Future.value(false);
                      },
                      child: Scaffold(
                        appBar: AppBar(
                          systemOverlayStyle: const SystemUiOverlayStyle(
                            statusBarColor: kBackgroundColorDark,
                            statusBarBrightness: Brightness.dark,
                          ),
                          leading: GestureDetector(
                            child: InkWell(
                                onTap: () {
                                  setState(() {
                                    hidenav = false;
                                  });
                                  AppBuilder.of(context)!.rebuild();
                                  if (widget.whetherJustCreated == false) {
                                    Navigator.pop(context, popAnyChanges);
                                  } else {
                                    Navigator.of(context)
                                        .popUntil((route) => route.isFirst);
                                  }
                                },
                                child: const Icon(
                                    CupertinoIcons.arrow_left_circle_fill)),
                          ),
                          backgroundColor: Colors.transparent,
                        ),
                        body: SafeArea(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.block,
                                  color: kWarningColorDark,
                                  size: 30.0,
                                ),
                                const SizedBox(height: 10.0),
                                const Text("You may have blocked this post."),
                                const SizedBox(height: 20.0),
                                TextButton(
                                    onPressed: () {
                                      unblockReportedContent();
                                    },
                                    child: Text("Show anyway",
                                        style: Theme.of(context)
                                            .textTheme
                                            .button!
                                            .copyWith(
                                              color: kPrimaryColorTint2,
                                              fontSize: 20.0,
                                            ))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : DefaultTabController(
                      length: 2,
                      child: WillPopScope(
                        onWillPop: () {
                          setState(() {
                            hidenav = false;
                          });
                          AppBuilder.of(context)!.rebuild();
                          if (widget.whetherJustCreated == false) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                          return Future.value(false);
                        },
                        child: Scaffold(
                          floatingActionButton: (onlineuid == opuid &&
                                  dataisthere == true &&
                                  litsupdatedataisthere == true &&
                                  selectedTab == 'Timeline')
                              ? Padding(
                                  padding: const EdgeInsets.only(bottom: 50.0),
                                  child: FloatingActionButton(
                                    tooltip: "Add an update",
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => LitsUpdate(
                                          onlineuser: UserInfoModel(
                                              uid: onlineuid,
                                              username: onlineusername,
                                              pic: onlinepic),
                                          whetherEditing: false,
                                          docName: widget.docName,
                                        ),
                                        fullscreenDialog: true,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: kHeadlineColorDark,
                                    ),
                                    backgroundColor: kPrimaryColor,
                                  ),
                                )
                              : null,
                          resizeToAvoidBottomInset: false,
                          appBar: AppBar(
                            leading: Container(),
                            backgroundColor: Colors.transparent,
                            systemOverlayStyle: const SystemUiOverlayStyle(
                              statusBarColor: kBackgroundColorDark,
                              statusBarBrightness: Brightness.dark,
                            ),
                            /* leading: GestureDetector(
                                  child: InkWell(
                                      onTap: () {
                                        setState(() {
                        hidenav = false;
                                        });
                                        AppBuilder.of(context)!.rebuild();
                                        Navigator.pop(context);
                                      },
                                      child: const Icon(CupertinoIcons.arrow_left_circle_fill)),
                                ),*/
                            actions: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        child: InkWell(
                                            onTap: () {
                                              setState(() {
                                                hidenav = false;
                                              });
                                              AppBuilder.of(context)!.rebuild();
                                              if (widget.whetherJustCreated ==
                                                  false) {
                                                Navigator.of(context).pop();
                                              } else {
                                                Navigator.of(context).popUntil(
                                                    (route) => route.isFirst);
                                              }
                                            },
                                            child: const Icon(CupertinoIcons
                                                .arrow_left_circle_fill)),
                                      ),
                                      Row(
                                        children: [
                                          tabButton('Timeline', 0,
                                              selectedTab == 'Timeline'),
                                          tabButton('Chats', 1,
                                              selectedTab == 'Chats'),
                                        ],
                                      ),
                                      GestureDetector(
                                        child: InkWell(
                                          highlightColor: Colors.transparent,
                                          splashColor: Colors.transparent,
                                          onTap: () {
                                            if (onlineuid == opuid) {
                                              showPostOptionsForOP();
                                            } else {
                                              showPostOptionsForOthers();
                                            }
                                          },
                                          child: const Icon(
                                            Icons.more_horiz,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                          body: SafeArea(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    postHeader(),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 15.0,
                                        right: 15.0,
                                      ),
                                      child: ListTileTheme(
                                        contentPadding: const EdgeInsets.all(0),
                                        dense: true,
                                        horizontalTitleGap: 0.0,
                                        minLeadingWidth: 0,
                                        child: ExpansionTile(
                                          title: Text(
                                            litsTopic,
                                            style: styleReallyLargeTitle(
                                              fontSize: 25.0,
                                            ),
                                          ),
                                          children: [
                                            ListTile(
                                              title: Text(
                                                litsDescription,
                                                style: styleSubTitleSmall(
                                                    //fontSize: 17.0,
                                                    //letterSpacing: -0.41,
                                                    ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    Expanded(child: showAllEvents()),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 15.0),
                                      child: UpDownVoteWidget(
                                          whetherIconsBig: true,
                                          upvoteCount: totallikes,
                                          downvoteCount: totaldislikes,
                                          commentCount: totalcomments,
                                          onUpvoted: () => _checkUpvotePost(),
                                          onDownvoted: () =>
                                              _checkDownvotePost(),
                                          onShared: () =>
                                              ShareService.shareContent(
                                                  widget.docName,
                                                  'litspost',
                                                  litsTopic,
                                                  litsDescription,
                                                  featuredImage),
                                          whetherUpvoted: likedpost,
                                          whetherDownvoted: dislikedpost,
                                          onComment: () {
                                            setState(() {
                                              selectedTab = 'Chats';
                                              _tabController.animateTo(1);
                                            });
                                          }),
                                    )
                                  ],
                                ),
                                //tab2
                                CustomScrollView(
                                  physics: const NeverScrollableScrollPhysics(),
                                  slivers: [
                                    SliverFillRemaining(
                                      child: Column(
                                        children: [
                                          (commentdataexists == false)
                                              ? const CupertinoActivityIndicator(
                                                  color: kDarkPrimaryColor,
                                                )
                                              : Expanded(
                                                  child: commentCardNew()),
                                          _commentBox(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }
}
