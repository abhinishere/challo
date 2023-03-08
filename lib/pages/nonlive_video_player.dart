import 'dart:async';
import 'dart:convert';
import 'package:challo/helpers/share_service.dart';
import 'package:challo/models/comment_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/community_page.dart';
import 'package:challo/pages/profilepage.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/comment_bottom.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as tago;
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:wakelock/wakelock.dart';

class NonliveVideoPlayer extends StatefulWidget {
  final String docName;
  final bool whetherjustcreated;
  final bool showcomments;
  final bool? hideNavLinkReturn;

  const NonliveVideoPlayer({
    required this.docName,
    required this.showcomments,
    required this.whetherjustcreated,
    this.hideNavLinkReturn,
  });
  @override
  State<NonliveVideoPlayer> createState() => _NonliveVideoPlayerState();
}

class _NonliveVideoPlayerState extends State<NonliveVideoPlayer> {
  bool commentdataexists = false;
  late String videourl;
  late bool portraitonly;
  late bool likedpost, dislikedpost;
  late int totallikes, totaldislikes, totalcomments, updownratio;
  late bool whethercommunitypost;
  late String? communityName, communitypic;
  late VideoPlayerController controller;
  bool _isPlaying = false;
  late Duration _duration;
  late Duration _position;
  var _progress = 0.0;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _editingController = TextEditingController();
  late int updownvoteratio;
  late int commentcount;
  bool videoinforeceived = false;
  bool whethervideoinitialized = false;
  late String onlineuid, onlinepic, onlineusername;
  dynamic userslist;
  late List<String> uidList;

  bool fullscreenenabled = false;
  bool whetherexited = false;
  bool showcomments = false;
  bool showdescription = false;
  bool hideinfo = false;
  bool whethercontentreportsubmitted = false;
  int selectedContentRadioNo = 1;
  String contentReportReason = "Spam or misleading";
  //List<String> participateduids = [];
  String? opuid, opusername, oppic;
  bool checkwhetherblocked = false;
  bool checkwhetherdeleted = false;
  bool whethercommentreportsubmitted = false;
  int selectedCommentRadioNo = 1;
  String commentReportReason = "Spam or misleading";
  late String topic, description, thumbnail, fullDescription;
  late dynamic timeofposting;
  late int totalviews;

  bool showPublishButton = false;

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateRandomDocName(String viewerusername) {
    String newDocName = (viewerusername + getRandomString(5));
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
    getOnlineData().then((_) => {
          getVideoData().then((_) => {
                loadVideoConfig().then((_) => {
                      initializeVideo(),
                    }),
              }),
        });
    Wakelock.enable();
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
          style: Theme.of(context).textTheme.subtitle2!.copyWith(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500),
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
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        children: [
          for (CommentModel c in commentsList) commentCardWidget(c, true),
        ],
        reverse: false,
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

  Future getOnlineData() async {
    showcomments = widget.showcomments;
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateString = dateFormat.format(DateTime.now());

    onlineuid = FirebaseAuth.instance.currentUser!.uid;

    var onlineuserdoc = await usercollection.doc(onlineuid).get();

    onlineusername = onlineuserdoc['username'];

    onlinepic = onlineuserdoc['profilepic'];

    await contentcollection.doc(widget.docName).update({
      'totalviews': FieldValue.arrayUnion(["$onlineuid $dateString"])
    });
  }

  Future getVideoData() async {
    var videodoc = await contentcollection.doc(widget.docName).get();

    opuid = videodoc['opuid'];
    opusername = videodoc['opusername'];
    oppic = videodoc['oppic'];
    videourl = videodoc['link'];
    portraitonly = videodoc['portraitonly'];

    whethercommunitypost = videodoc['whethercommunitypost'];

    communityName = videodoc['communityName'];
    communitypic = videodoc['communitypic'];

    List<String> blockedbylist = List.from(videodoc['blockedby']);

    final videoLikes = List.from(videodoc['likes']);

    final videoDislikes = List.from(videodoc['dislikes']);

    updownvoteratio = videoLikes.length - videoDislikes.length;

    commentcount = videodoc['commentcount'];

    topic = videodoc['topic'];
    description = videodoc['description'];
    thumbnail = videodoc['thumbnail'];

    final List<String> totalviewsList = List.from(videodoc['totalviews']);

    totalviews = totalviewsList.length;

    timeofposting = videodoc['time'];

    totallikes = videoLikes.length;
    totaldislikes = videoDislikes.length;

    if (blockedbylist.contains(onlineuid)) {
      setState(() {
        checkwhetherblocked = true;
      });
    }

    if (videoLikes.contains(onlineuid)) {
      setState(() {
        likedpost = true;
      });
    } else {
      setState(() {
        likedpost = false;
      });
    }

    if (videoDislikes.contains(onlineuid)) {
      setState(() {
        dislikedpost = true;
      });
    } else {
      setState(() {
        dislikedpost = false;
      });
    }

    updownratio = totallikes - totaldislikes;

    totalcomments = videodoc['commentcount'];

    Reference ref = FirebaseStorage.instance
        .ref()
        .child('nonlive_videos')
        .child(widget.docName)
        .child('${widget.docName}_long_description');

    await ref.getData().then((value) => {
          fullDescription = utf8.decode(value!.toList()),
        });
  }

  Future loadVideoConfig() async {
    if (portraitonly == true) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    setState(() {
      print("videoinforeceived true");
      videoinforeceived = true;
    });
  }

  Future initializeVideo() async {
    if (checkwhetherblocked == false) {
      controller = VideoPlayerController.network(videourl)
        ..initialize().then((_) => {
              controller
                ..addListener(() => _onControllerUpdate())
                ..setLooping(true).then((_) => {
                      controller.play(),
                    })
            });
    } else {
      controller = VideoPlayerController.network(videourl)
        ..initialize().then((_) => {
              controller
                ..addListener(() => _onControllerUpdate())
                ..setLooping(true).then((_) => {
                      controller.pause(),
                    })
            });
    }

    setState(() {
      print("whethervideoinitialized true");
      whethervideoinitialized = true;
    });
  }

  void _onControllerUpdate() async {
    if (!controller.value.isInitialized) {
      print("controller not initialized");
    }
    _duration = controller.value.duration;
    var duration = _duration;

    dynamic position = await controller.position;
    _position = position;

    final playing = controller.value.isPlaying;
    if (playing) {
      setState(() {
        _progress = position.inMilliseconds.ceilToDouble() /
            duration.inMilliseconds.ceilToDouble();
      });
    }
    setState(() {
      _isPlaying = playing;
    });
  }

  @override
  void dispose() {
    super.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    controller.dispose();
    _commentController.dispose();
    Wakelock.disable();
  }

  void _checkLikedVideo() async {
    //add the uid of viewer in likes array
    var videodoc = await contentcollection.doc(widget.docName).get();

    if (videodoc['likes'].contains(onlineuid)) {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayRemove([onlineuid])
      });
      setState(() {
        likedpost = false;
        dislikedpost = false;
        totallikes = totallikes - 1;
      });
    } else if (videodoc['dislikes'].contains(onlineuid)) {
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
      });
    } else {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayUnion([onlineuid])
      });
      setState(() {
        likedpost = true;
        dislikedpost = false;
        totallikes = totallikes + 1;
      });
    }
  }

  void _checkDislikedVideo() async {
    //add the uid of viewer in dislikes array
    var videodoc = await contentcollection.doc(widget.docName).get();

    if (videodoc['dislikes'].contains(onlineuid)) {
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayRemove([onlineuid])
      });
      setState(() {
        dislikedpost = false;
        likedpost = false;
        totaldislikes = totaldislikes - 1;
      });
    } else if (videodoc['likes'].contains(onlineuid)) {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayRemove([onlineuid])
      });
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayUnion([onlineuid])
      });
      setState(() {
        dislikedpost = true;
        likedpost = false;
        totallikes = totallikes - 1;
        totaldislikes = totaldislikes + 1;
      });
    } else {
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayUnion([onlineuid])
      });
      setState(() {
        dislikedpost = true;
        likedpost = false;
        totaldislikes = totaldislikes + 1;
      });
    }
  }

  void _commentsClicked() {
    setState(() {
      showcomments = true;
    });
  }

  void _descriptionClicked() {
    setState(() {
      showdescription = true;
    });
  }

  Widget playerControls() {
    return Container(
      color: Colors.white70,
      height: 50,
      padding: const EdgeInsets.only(bottom: 10),

      //padding: const EdgeInsets.symmetric(vertical: 48),
      child: Padding(
        padding: const EdgeInsets.only(top: 12.0, bottom: 12.0),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              RawMaterialButton(
                onPressed: null,
                child: Icon(Icons.replay_5),
                shape: CircleBorder(),
                elevation: 2.0,
              ),
              RawMaterialButton(
                onPressed: null,
                child: Icon(Icons.play_arrow),
                shape: CircleBorder(),
                elevation: 2.0,
              ),
              RawMaterialButton(
                onPressed: null,
                child: Icon(Icons.forward_5),
                shape: CircleBorder(),
                elevation: 2.0,
              ),
              RawMaterialButton(
                onPressed: null,
                child: Icon(Icons.volume_mute),
                shape: CircleBorder(),
                elevation: 2.0,
              ),
            ]),
      ),
    );
  }

  String convertTwo(int value) {
    return value < 10 ? "0$value" : "$value";
  }

  Widget _vidControls() {
    final noMute = (controller.value.volume > 0);
    final duration = _duration.inSeconds;
    final head = _position.inSeconds;
    final remained = max(0, duration - head);
    final mins = convertTwo(remained ~/ 60.0); //~ for taking integer part
    final secs = convertTwo(remained % 60);
    return (fullscreenenabled == false &&
            (showcomments == true || showdescription == true))
        ? Padding(
            padding: const EdgeInsets.all(10.0),
            child: Container(
              height: 35,
              child: Row(
                //mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ButtonTheme(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0), //adds padding inside the button
                    materialTapTargetSize: MaterialTapTargetSize
                        .shrinkWrap, //limits the touch area to the button area
                    minWidth: 0, //wraps child's width
                    height: 0, //wraps child's height

                    child: TextButton(
                      onPressed: () async {
                        if (_isPlaying == true) {
                          setState(() {
                            _isPlaying = false;
                          });

                          controller.pause();
                          Wakelock.disable();
                        } else {
                          setState(() {
                            _isPlaying = true;
                          });

                          controller.play();
                          Wakelock.enable();
                        }
                      },
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  ButtonTheme(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0), //adds padding inside the button
                    materialTapTargetSize: MaterialTapTargetSize
                        .shrinkWrap, //limits the touch area to the button area
                    minWidth: 0, //wraps child's width
                    height: 0, //wraps child's height

                    child: TextButton(
                      onPressed: () {
                        if (noMute == true) {
                          controller.setVolume(0);
                        } else {
                          controller.setVolume(1.0);
                        }
                        setState(() {});
                      },
                      child: Icon(
                        noMute ? Icons.volume_up : Icons.volume_off,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              height: 35,
              //color: Colors.blueAccent,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ButtonTheme(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0), //adds padding inside the button
                    materialTapTargetSize: MaterialTapTargetSize
                        .shrinkWrap, //limits the touch area to the button area
                    minWidth: 0, //wraps child's width
                    height: 0, //wraps child's height

                    child: TextButton(
                      onPressed: () async {
                        if (_isPlaying == true) {
                          setState(() {
                            _isPlaying = false;
                          });

                          controller.pause();
                        } else {
                          setState(() {
                            _isPlaying = true;
                          });

                          controller.play();
                        }
                      },
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.red[700],
                          inactiveTrackColor: Colors.red[100],
                          trackShape: const RoundedRectSliderTrackShape(),
                          trackHeight: 3.0,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 12.0),
                          thumbColor: Colors.redAccent,
                          overlayColor: Colors.red.withAlpha(32),
                          overlayShape: const RoundSliderOverlayShape(
                              overlayRadius: 28.0),
                          tickMarkShape: const RoundSliderTickMarkShape(),
                          activeTickMarkColor: Colors.red[700],
                          inactiveTickMarkColor: Colors.red[100],
                          valueIndicatorShape:
                              const PaddleSliderValueIndicatorShape(),
                          valueIndicatorColor: Colors.redAccent,
                          valueIndicatorTextStyle:
                              const TextStyle(color: Colors.white),
                        ),
                        child: Slider(
                          value: max(0, min(_progress * 100, 100)),
                          min: 0,
                          max: 100,
                          divisions: 100,
                          label: _position.toString().split(".")[0],
                          onChanged: (value) {
                            setState(() {
                              _progress = value * 0.01;
                            });
                          },
                          onChangeStart: (value) {
                            controller.pause();
                          },
                          onChangeEnd: (value) {
                            final duration = controller.value.duration;

                            var newValue = max(0, min(value, 99)) * 0.01;
                            var millis =
                                (duration.inMilliseconds * newValue).toInt();
                            controller.seekTo(Duration(milliseconds: millis));
                            controller.play();
                          },
                        ),
                      ),
                    ),
                  ),
                  Text(
                    "$mins:$secs",
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        shadows: <Shadow>[
                          const Shadow(
                            offset: Offset(0.0, 1.0),
                            blurRadius: 4.0,
                            color: Color.fromARGB(150, 0, 0, 0),
                          )
                        ]),
                  ),
                  ButtonTheme(
                    padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0), //adds padding inside the button
                    materialTapTargetSize: MaterialTapTargetSize
                        .shrinkWrap, //limits the touch area to the button area
                    minWidth: 0, //wraps child's width
                    height: 0, //wraps child's height

                    child: TextButton(
                      onPressed: () {
                        if (noMute == true) {
                          controller.setVolume(0);
                        } else {
                          controller.setVolume(1.0);
                        }
                        setState(() {});
                      },
                      child: Icon(
                        noMute ? Icons.volume_up : Icons.volume_off,
                        size: 25,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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
//

              await usercollection
                  .doc(onlineuid)
                  .collection('content')
                  .where('docName', isEqualTo: widget.docName)
                  .get()
                  .then((value) {
                for (var element in value.docs) {
                  usercollection
                      .doc(onlineuid)
                      .collection('content')
                      .doc(element.id)
                      .delete()
                      .then((value) {
                    print("Success!");
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

              //
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
          color: kHeadlineColorDark,
        ),
      ),
    );
  }

  Widget arrowBackWidget() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
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
        },
        child: const Icon(
          Icons.arrow_back,
          color: kHeadlineColorDark,
        ),
      ),
    );
  }

  Widget voteShareWidget() {
    return Padding(
      padding: const EdgeInsets.only(right: 5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _checkLikedVideo(),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Stack(children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (likedpost) ? Colors.white : Colors.transparent,
                        ),
                        margin: const EdgeInsets.all(7.0),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      size: 30,
                      color: (likedpost) ? kPrimaryColor : Colors.white,
                    ),
                  ]),
                ),
              ),
              Text(
                '$totallikes',
                style: Theme.of(context).textTheme.subtitle2!.copyWith(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: kHeadlineColorDark,
                    ),
              ),
              const SizedBox(
                height: 5,
              ),
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _checkDislikedVideo(),
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: Stack(children: [
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (dislikedpost)
                              ? Colors.white
                              : Colors.transparent,
                        ),
                        margin: const EdgeInsets.all(7.0),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.arrow_down_circle_fill,
                      size: 30,
                      color: (dislikedpost) ? kPrimaryColor : Colors.white,
                    ),
                  ]),
                ),
              ),
              Text(
                '$totaldislikes',
                style: Theme.of(context).textTheme.subtitle2!.copyWith(
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                      color: kHeadlineColorDark,
                    ),
              ),

              /* ButtonTheme(
                padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0), //adds padding inside the button
                materialTapTargetSize: MaterialTapTargetSize
                    .shrinkWrap, //limits the touch area to the button area
                minWidth: 0, //wraps child's width
                height: 0, //wraps child's height
                child: TextButton(
                  onPressed: () => _checkLikedVideo(),
                  child: Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    size: 30,
                    color: (liked) ? kPrimaryColor : Colors.white,
                  ),
                ),
              ),
             Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Container(
                  alignment: Alignment.center,
                  height: 15,
                  width: 23,
                  //color: Colors.blueAccent,
                  child: Text(
                    "$updownvoteratio",
                    style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: kIconSecondaryColorDark,
                        ),
                  ),
                ),
              ),
              ButtonTheme(
                padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 8.0), //adds padding inside the button
                materialTapTargetSize: MaterialTapTargetSize
                    .shrinkWrap, //limits the touch area to the button area
                minWidth: 0, //wraps child's width
                height: 0, //wraps child's height
                child: TextButton(
                  onPressed: () => _checkDislikedVideo(),
                  child: Icon(
                    CupertinoIcons.arrow_down_circle_fill,
                    size: 30,
                    color: (dislikedpost) ? kPrimaryColor : Colors.white,
                  ),
                ),
              ),*/
            ],
          ),
          /*ButtonTheme(
            padding: const EdgeInsets.symmetric(
                vertical: 4.0, horizontal: 8.0), //adds padding inside the button
            materialTapTargetSize: MaterialTapTargetSize
                .shrinkWrap, //limits the touch area to the button area
            minWidth: 0, //wraps child's width
            height: 0, //wraps child's height
            child: TextButton(
              onPressed: _commentsClicked,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.comment_outlined,
                      size: 25, color: Colors.white),
                  Container(
                    alignment: Alignment.center,
                    //color: Colors.blueAccent,
                    height: 15,
                    width: 23,
                    child: Text(
                      "$commentcount",
                      style: Theme.of(context)
                          .textTheme
                          .subtitle2!
                          .copyWith(fontSize: 12.0, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
          ),*/
          const SizedBox(
            height: 20.0,
          ),
          InkWell(
            onTap: () => _commentsClicked(),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.message,
                    size: 20,
                    color: kHeadlineColorDark,
                  ),
                  //const SizedBox(width: 5.0),
                  Text(
                    "$totalcomments",
                    style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          fontSize: 12.0,
                          color: kHeadlineColorDark,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20.0,
          ),
          InkWell(
            onTap: () => ShareService.shareContent(
                widget.docName, 'videopost', topic, description, thumbnail),
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    CupertinoIcons.share_solid,
                    size: 20,
                    color: kHeadlineColorDark,
                  ),
                  /*Image.asset(
                        "assets/icons/share_thick_outlined.png",
                        height: 20,
                        width: 20,
                        color: kSubTextColor,
                      ),*/
                  //const SizedBox(width: 5.0),
                  Text(
                    'Share',
                    style: Theme.of(context).textTheme.button!.copyWith(
                          fontSize: 12.0,
                          color: kHeadlineColorDark,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20.0,
          ),
        ],
      ),
    );
  }

  String truncateWithEllipsis(int cutoff, String myString) {
    return (myString.length <= cutoff)
        ? myString
        : '${myString.substring(0, cutoff)}...';
  }

  Widget titledescription() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: InkWell(
        onTap: () => _descriptionClicked(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              child: Text(
                truncateWithEllipsis(27, topic),
                style: styleTitleSmall(),
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              (totalviews == 0)
                  ? truncateWithEllipsis(30,
                      "$totalviews views • ${tago.format(timeofposting.toDate())}")
                  : (totalviews == 1)
                      ? truncateWithEllipsis(30,
                          "$totalviews view • ${tago.format(timeofposting.toDate())}")
                      : truncateWithEllipsis(30,
                          "$totalviews views • ${tago.format(timeofposting.toDate())}"),
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    fontSize: 13.0,
                    color: kSubTextColor,
                    letterSpacing: -0.08,
                  ),
            ),
            const SizedBox(width: 5.0),
          ],
        ),
      ),
    );
  }

  Widget videoPlayerWidget(VideoPlayerController controller) => controller
          .value.isInitialized
      ? Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          //alignment: Alignment.topCenter,
          child: (hideinfo == false)
              ? (fullscreenenabled == false)
                  ? (showcomments == false && showdescription == false)
                      ? Stack(children: [
                          buildVideo(),
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _vidControls(),
                            ),
                          ),
                          Positioned(
                            bottom: 50.0,
                            left: 0.0,
                            child: titledescription(),
                          ),
                          Positioned(
                            bottom: 50,
                            right: 0.0,
                            child: voteShareWidget(),
                          ),
                          Positioned(
                            left: 0.0,
                            top: 0.0,
                            child: Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: arrowBackWidget()),
                          ),
                          Positioned(
                            right: 0.0,
                            top: 0.0,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: moreOptions(),
                            ),
                          )
                        ])
                      : (showcomments == true && showdescription == false)
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      alignment: Alignment.topCenter,
                                      height:
                                          MediaQuery.of(context).size.height /
                                              4,
                                      child: buildVideo(),
                                    ),
                                    Positioned.fill(
                                      child: Align(
                                          alignment: Alignment.bottomRight,
                                          child: _vidControls()),
                                    ),
                                    Positioned(
                                      left: 0.0,
                                      top: 0.0,
                                      child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: arrowBackWidget()),
                                    ),
                                    Positioned(
                                      right: 0.0,
                                      top: 0.0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: moreOptions(),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 10.0,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          //crossAxisAlignment: CrossAxisAlignment.center,
                                          //mainAxisSize: MainAxisSize.max,
                                          children: [
                                            Text(
                                              'Comments',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle1!
                                                  .copyWith(
                                                    color: kSubTextColor,
                                                    fontSize: 15.0,
                                                    fontWeight: FontWeight.w500,
                                                    letterSpacing: -0.24,
                                                  ),
                                            ),
                                            const SizedBox(
                                              width: 10.0,
                                            ),
                                            InkWell(
                                              onTap: () {
                                                showDialog(
                                                  context: context,
                                                  barrierDismissible: true,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      contentPadding:
                                                          const EdgeInsets.only(
                                                              left: 10,
                                                              right: 10),
                                                      title: Column(children: [
                                                        GestureDetector(
                                                          onTap: () {
                                                            //print("closing...");
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Align(
                                                            alignment: Alignment
                                                                .topRight,
                                                            child: Icon(
                                                              Icons.close,
                                                              size: 25.0,
                                                              color:
                                                                  kPrimaryColorTint2,
                                                            ),
                                                          ),
                                                        ),
                                                        const Center(
                                                          child: Text(
                                                            "UGC Policy",
                                                            style: TextStyle(
                                                                fontSize: 15.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Colors
                                                                    .white),
                                                          ),
                                                        ),
                                                      ]),
                                                      shape:
                                                          const RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.all(
                                                          Radius.circular(20.0),
                                                        ),
                                                      ),
                                                      content: Container(
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
                                                              child: Expanded(
                                                                child:
                                                                    SingleChildScrollView(
                                                                        child:
                                                                            Text(
                                                                  ugcRules,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        12.0,
                                                                    color: Colors
                                                                        .white70,
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
                                                      color: Colors.blueGrey,
                                                      fontSize: 15.0,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      letterSpacing: -0.24,
                                                    ),
                                              ),
                                            ),
                                          ]),
                                      InkWell(
                                          onTap: () {
                                            setState(() {
                                              showcomments = false;
                                            });
                                          },
                                          child: const Icon(Icons.close,
                                              color: kSubTextColor, size: 25)),
                                    ],
                                  ),
                                ),
                                (commentdataexists == false)
                                    ? const Expanded(
                                        child: CupertinoActivityIndicator(
                                          color: kDarkPrimaryColor,
                                        ),
                                      )
                                    : Expanded(child: commentCardNew()),
                                _commentBox(),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      alignment: Alignment.topCenter,
                                      height:
                                          MediaQuery.of(context).size.height /
                                              4,
                                      child: buildVideo(),
                                    ),
                                    Positioned.fill(
                                      child: Align(
                                          alignment: Alignment.bottomRight,
                                          child: _vidControls()),
                                    ),
                                    Positioned(
                                      left: 0.0,
                                      top: 0.0,
                                      child: Padding(
                                          padding: const EdgeInsets.all(5.0),
                                          child: arrowBackWidget()),
                                    ),
                                    Positioned(
                                      right: 0.0,
                                      top: 0.0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(5.0),
                                        child: moreOptions(),
                                      ),
                                    )
                                  ],
                                ),
                                Expanded(child: descriptionWidget()),
                              ],
                            )
                  : Stack(children: [
                      Container(
                          height: MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          child: buildVideo()),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: _vidControls(),
                        ),
                      ),
                      Positioned(
                        left: 0.0,
                        top: 0.0,
                        child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: arrowBackWidget()),
                      ),
                      Positioned(
                        right: 0.0,
                        top: 0.0,
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: moreOptions(),
                        ),
                      )
                    ])
              : buildVideo(),
        )
      : Container(
          height: 200,
          child: const Center(
              child: CupertinoActivityIndicator(
            color: kDarkPrimaryColor,
          )));

  Widget buildVideo() {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: () {
        if (showcomments == true || showdescription == true) {
          setState(() {
            showcomments = false;
            showdescription = false;
          });
        } else {
          if (hideinfo == false) {
            setState(() {
              hideinfo = true;
            });
          } else {
            setState(() {
              hideinfo = false;
            });
          }
        }
      },
      child: Container(
        alignment: Alignment.center,
        // child: FittedBox(child: buildVideoPlayer()),
        child: buildVideoPlayer(),
      ),
    );
  }

  Widget buildVideoPlayer() => buildFullScreen(
        child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: VideoPlayer(controller)),
      );

  Widget buildFullScreen({required Widget child}) {
    final size = controller.value.size;
    final width = size.width;
    final height = size.height;
    return FittedBox(
        fit: BoxFit.cover,
        //alignment: Alignment.topCenter,
        child: SizedBox(width: width, height: height, child: child));
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
                                onChanged: (int? val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val!;
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
                                onChanged: (int? val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val!;
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
                                onChanged: (int? val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val!;
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
                                onChanged: (int? val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val!;
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
                                onChanged: (int? val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val!;
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
                                onChanged: (int? val) {
                                  modalsetState(() {
                                    selectedContentRadioNo = val!;
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
      if (portraitonly == false) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }

      setState(() {
        whethercontentreportsubmitted = false;
      });
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
      'type': 'videopost',
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

  /*contentReportSubmit2(String reason) async {
    await contentcollection.doc(widget.docName).update({
      'blockedby': FieldValue.arrayUnion([onlineuid])
    });

    for (String uid in participateduids) {
      var contentdocs = await usercollection
          .doc(uid)
          .collection('content')
          .doc(widget.docName)
          .get();

      if (!contentdocs.exists) {
      } else {
        await usercollection
            .doc(uid)
            .collection('content')
            .doc(widget.docName)
            .update({
          'blockedby': FieldValue.arrayUnion([onlineuid])
        });
      }
    }

    await contentreportcollection
        .doc(generateRandomDocName(onlineusername))
        .set({
      'type': 'videopost',
      'status': 'reported', //reported -> deleted/noaction/pending
      'reporter': onlineuid,
      'docName': widget.docName,
      'reason': reason,
      'time': DateTime.now(),
    });
    setState(() {
      controller.pause();
      checkwhetherblocked = true;
    });
  }

  unblockReportedContent2() async {
    await contentcollection.doc(widget.docName).update({
      'blockedby': FieldValue.arrayRemove([onlineuid])
    });
    for (String uid in participateduids) {
      var contentdocs = await usercollection
          .doc(uid)
          .collection('content')
          .doc(widget.docName)
          .get();

      if (!contentdocs.exists) {
      } else {
        await usercollection
            .doc(uid)
            .collection('content')
            .doc(widget.docName)
            .update({
          'blockedby': FieldValue.arrayRemove([onlineuid])
        });
      }
    }
    setState(() {
      checkwhetherblocked = false;
    });
  }*/

  Widget deleteConfirmation() {
    return Container(
      height: (MediaQuery.of(context).size.height) / 6,
      width: (MediaQuery.of(context).size.width),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(children: [
        const Text('Are you sure you want to delete this video?',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white)),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  //icon: Icon(Icons.cancel_outlined, color: kPrimaryColor),
                  child: const Text("Cancel",
                      style: TextStyle(
                        color: kPrimaryColor,
                      ))),
              Container(
                color: Colors.grey.shade500,
                width: 0.5,
                height: 22,
              ),
              TextButton(
                  onPressed: () async {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    await usercollection
                        .doc(onlineuid)
                        .collection('content')
                        .where('docName', isEqualTo: widget.docName)
                        .get()
                        .then((value) {
                      for (var element in value.docs) {
                        usercollection
                            .doc(onlineuid)
                            .collection('content')
                            .doc(element.id)
                            .delete()
                            .then((value) {
                          print("Success!");
                        });
                      }
                    });

                    await contentcollection
                        .doc(widget.docName)
                        .update({'status': 'deleted'});
                  },
                  //icon: Icon(Icons.check_circle_outlined, color: kPrimaryColor),
                  child: const Text("Yes",
                      style: TextStyle(
                        color: kPrimaryColor,
                      )))
            ],
          ),
        )
      ]),
    );
  }

  Widget unlistConfirmation() {
    return Container(
      height: (MediaQuery.of(context).size.height) / 6,
      width: (MediaQuery.of(context).size.width),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(children: [
        const Text('Are you sure you want to unlist this video?',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white)),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  //icon: Icon(Icons.cancel_outlined, color: kPrimaryColor),
                  child: const Text("Cancel",
                      style: TextStyle(
                        color: kPrimaryColor,
                      ))),
              Container(
                color: Colors.grey.shade500,
                width: 0.5,
                height: 22,
              ),
              TextButton(
                  onPressed: () async {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                    await usercollection
                        .doc(onlineuid)
                        .collection('content')
                        .where('docName', isEqualTo: widget.docName)
                        .get()
                        .then((value) {
                      for (var element in value.docs) {
                        usercollection
                            .doc(onlineuid)
                            .collection('content')
                            .doc(element.id)
                            .delete()
                            .then((value) {
                          print("Success!");
                        });
                      }
                    });
                  },
                  //icon: Icon(Icons.check_circle_outlined, color: kPrimaryColor),
                  child: const Text("Yes",
                      style: TextStyle(
                        color: kPrimaryColor,
                      )))
            ],
          ),
        )
      ]),
    );
  }

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget descriptionWidget() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //crossAxisAlignment: CrossAxisAlignment.center,
                //mainAxisSize: MainAxisSize.max,
                children: [
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          color: kSubTextColor,
                          fontSize: 13.0,
                          // fontWeight: FontWeight.w900,
                          letterSpacing: -0.08,
                        ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          showdescription = false;
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 25,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topic,
                      style: styleTitleSmall(),
                    ),
                    MarkdownBody(
                      data: fullDescription,
                      styleSheet: styleSheetforMarkdown(context),
                      onTapLink: (text, url, title) async {
                        openBrowserURL(url: url!);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /*Widget commentCard() {
    return Container(
      //height: MediaQuery.of(context).size.height / 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(
          height: 10.0,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                  //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //crossAxisAlignment: CrossAxisAlignment.center,
                  //mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: kSubTextColor,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.24,
                          ),
                    ),
                    const SizedBox(
                      width: 10.0,
                    ),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          barrierDismissible: true,
                          builder: (context) {
                            return AlertDialog(
                              contentPadding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              title: Column(children: [
                                GestureDetector(
                                  onTap: () {
                                    //print("closing...");
                                    Navigator.of(context).pop();
                                  },
                                  child: const Align(
                                    alignment: Alignment.topRight,
                                    child: Icon(
                                      Icons.close,
                                      size: 25.0,
                                      color: kPrimaryColorTint2,
                                    ),
                                  ),
                                ),
                                const Center(
                                  child: Text(
                                    "UGC Policy",
                                    style: TextStyle(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ),
                              ]),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20.0),
                                ),
                              ),
                              content: Container(
                                height:
                                    (MediaQuery.of(context).size.height) / 1.2,
                                width:
                                    (MediaQuery.of(context).size.width) / 1.2,
                                child: Column(
                                  children: [
                                    Container(
                                      child: Expanded(
                                        child: SingleChildScrollView(
                                            child: Text(
                                          ugcRules,
                                          style: const TextStyle(
                                            fontSize: 12.0,
                                            color: Colors.white70,
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
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                              color: Colors.blueGrey,
                              fontSize: 15.0,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.24,
                            ),
                      ),
                    ),
                  ]),
              InkWell(
                  onTap: () {
                    setState(() {
                      showcomments = false;
                    });
                  },
                  child:
                      const Icon(Icons.close, color: kSubTextColor, size: 25)),
            ],
          ),
        ),
        Expanded(
          child: Container(
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
                  physics: const AlwaysScrollableScrollPhysics(),
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
                                  padding: const EdgeInsets.only(
                                      right: 5.0, top: 5.0),
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
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.portraitUp,
                                        ]);
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
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      kPrimaryColor,
                                                                ))),
                                                      ),
                                                      Container(
                                                        color: Colors
                                                            .grey.shade500,
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
                                                                commentcount =
                                                                    commentcount -
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
                                          ),
                                        ).whenComplete(() {
                                          if (widget.portraitonly == false) {
                                            SystemChrome
                                                .setPreferredOrientations([
                                              DeviceOrientation.portraitUp,
                                              DeviceOrientation.landscapeLeft,
                                              DeviceOrientation.landscapeRight,
                                            ]);
                                          }
                                        });
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
                                  padding: const EdgeInsets.only(
                                      right: 5.0, top: 5.0),
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
                                        SystemChrome.setPreferredOrientations([
                                          DeviceOrientation.portraitUp,
                                        ]);

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
                                      color:
                                          (comment['likes'].contains(onlineuid))
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
                                          fontSize: 10.0,
                                          color: Colors.white70)),
                              Expanded(
                                child: InkWell(
                                  onTap: () => _downvoteComment(comment['id']),
                                  child: Icon(Icons.arrow_downward,
                                      size: 20,
                                      color: (comment['dislikes']
                                              .contains(onlineuid))
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
          ),
        ),
        _commentBox(),
      ]),
    );
  }*/

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

  Future<int> getRepliesCount(String parentCommentId) async {
    var commentdocs =
        await commentsdb.child(widget.docName).child(parentCommentId).get();

    final int repliesCount = (commentdocs.value as Map)['repliesCount'];
    print('Replies Count is $repliesCount');
    return repliesCount;
  }

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

  /* Widget _commentBox() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.065,
      //color: kSecondaryDarkColor,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(5, 5, 0, 5),
              child: new TextFormField(
                cursorColor: Colors.black,
                style: const TextStyle(
                  color: Colors.black,
                ),
                controller: _commentController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Enter your comment...',
                  hintStyle: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white70,
                  contentPadding: const EdgeInsets.only(left: 16),
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                    onPressed: () => clearComment(),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5.0, right: 5.0),
            child: MaterialButton(
              minWidth: 0,
              onPressed: () {
                FocusScope.of(context).unfocus();
                publishComment();
              },
              child: const Icon(
                Icons.send,
                color: kPrimaryColor,
                size: 20.0,
              ),
              shape: const CircleBorder(),
              elevation: 2.0,
              color: Colors.white70,
              padding: const EdgeInsets.all(8.0),
            ),
          ),
        ],
      ),
    );
  }*/

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
      if (portraitonly == false) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
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
            'type': 'nonlivevideocomment',
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
  Widget build(BuildContext context) {
    final mediaQueryData = MediaQuery.of(context);
    if (mediaQueryData.orientation == Orientation.portrait) {
      setState(() {
        fullscreenenabled = false;
      });
    } else {
      setState(() {
        fullscreenenabled = true;
        showcomments = false;
        showdescription = false;
      });
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: kBackgroundColorDark,
      ),
      child: (videoinforeceived == true &&
              whethervideoinitialized == true &&
              whetherexited == false &&
              controller.value.isInitialized)
          ? WillPopScope(
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
              child: (checkwhetherblocked == true)
                  ? Scaffold(
                      appBar: AppBar(
                        systemOverlayStyle: const SystemUiOverlayStyle(
                          statusBarColor: kBackgroundColorDark,
                          statusBarBrightness: Brightness.dark,
                        ),
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
                            color: Colors.white,
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
                                child: Text("Post hidden for you.",
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
                          ),
                        ),
                      ),
                    )
                  : (checkwhetherdeleted == true)
                      ? Scaffold(
                          appBar: AppBar(
                            systemOverlayStyle: const SystemUiOverlayStyle(
                              statusBarColor: kBackgroundColorDark,
                              statusBarBrightness: Brightness.dark,
                            ),
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
                                color: Colors.white,
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
                              ),
                            ),
                          ),
                        )
                      : Scaffold(
                          appBar: PreferredSize(
                            preferredSize: const Size.fromHeight(0),
                            child: AppBar(
                              leading: Container(),
                              backgroundColor: Colors.transparent,
                              elevation: 0,
                              systemOverlayStyle: const SystemUiOverlayStyle(
                                statusBarColor: kBackgroundColorDark,
                                statusBarBrightness: Brightness.dark,
                              ),
                            ),
                          ),
                          resizeToAvoidBottomInset: false,
                          body: SafeArea(
                            child: Center(
                              child: videoPlayerWidget(controller),
                            ),
                          ),
                        ),
            )
          : WillPopScope(
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
              child: Scaffold(
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  systemOverlayStyle: const SystemUiOverlayStyle(
                    statusBarColor: kBackgroundColorDark,
                    statusBarBrightness: Brightness.dark,
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
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
                      color: kHeadlineColorDark,
                    ),
                  ),
                ),
                resizeToAvoidBottomInset: false,
                body: const Center(
                  child: CupertinoActivityIndicator(
                    color: kDarkPrimaryColor,
                  ),
                ),
              ),
            ),
    );
  }
}
