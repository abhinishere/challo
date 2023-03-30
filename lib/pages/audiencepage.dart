import 'dart:io';
import 'package:challo/models/comment_model.dart';
import 'package:challo/models/content_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/widgets/audiencedebateinfowidget.dart';
import 'package:challo/widgets/comment_bottom.dart';
import 'package:challo/widgets/content_info_widget.dart';
import 'package:challo/widgets/podcastinfowidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as rtc_local_view;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as rtc_remote_view;
import 'package:challo/variables.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:timeago/timeago.dart' as tago;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:share/share.dart';
import 'dart:math';

class AudiencePage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final String? docName;

  /// non-modifiable client role of the page
  final ClientRole role;

  /// Creates a call page with given channel name.
  const AudiencePage({
    Key? key,
    required this.docName,
    required this.role,
  }) : super(key: key);

  @override
  State<AudiencePage> createState() => _AudiencePageState();
}

class _AudiencePageState extends State<AudiencePage> {
  //String uid1, uid2;
  //int parseduid1; //agora's uid should be int

  //bool _visible = true;

  final _commentController = TextEditingController();

  bool commentsheetopen = false;

  bool hidecontrols = false;

  int? uid1, uid2;

  String? rid, sid;
  int? recUid;

  late String baseUrl;

  String? appId;

  dynamic generatedtoken, generateduid;

  final _users = <int>[];
  final _liveids = <int>[];
  //var _sortedliveids = <int>[];
  bool muted = false;
  bool liked = false;
  bool disliked = false;
  late List<String> liveviews;
  List<String>? totalviews;
  late RtcEngine _engine;

  bool split = false;

  UserInfoModel? user0, user1, user2, user3;
  ContentInfoModel? contentinfo;

  String? viewerid, viewerpic, viewerusername;

  bool dataisthere = false;
  bool streamended = false;
  bool fullscreenenabled = false;

  String? formattype;

  int? guestsno;

  bool showcomments = false;

  bool commentspressedinlandscape = false;

  bool whethercontentreportsubmitted = false;

  int? selectedContentRadioNo = 1;

  String contentReportReason = "Spam or misleading";

  bool checkwhetherblocked = false;

  bool whethercommentreportsubmitted = false;

  int? selectedCommentRadioNo = 1;

  String commentReportReason = "Spam or misleading";

  dynamic time;

  Timer? timer;

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateRandomDocName(String viewerusername) {
    String newDocName = (viewerusername + getRandomString(5));
    return newDocName;
  }

  bool commentdataexists = false;
  bool showPublishButton = false;

  //comments' variables
  late String commentsPath;
  late StreamSubscription commentStreamSubscription;
  late List<CommentModel> commentsList;
  late Map<String?, List<CommentModel>?> repliesMap;

  @override
  void dispose() {
    // clear users
    _users.clear();
    _liveids.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();

    _commentController.dispose();

    timer?.cancel();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getalldataandinitialize();
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

  contentReportSubmit(String reason) async {
    await contentcollection.doc(widget.docName).update({
      'blockedby': FieldValue.arrayUnion([viewerid])
    });

    await contentreportcollection.doc(generateRandomDocName(viewerid!)).set({
      'type': formattype,
      'status': 'reported', //reported -> deleted/noaction/pending
      'reporter': viewerid,
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
      'blockedby': FieldValue.arrayRemove([viewerid])
    });
    setState(() {
      checkwhetherblocked = false;
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
                        // mainAxisAlignment: MainAxisAlignment.center,
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
      if (formattype == 'Debate' || formattype == 'Podcast') {
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

  showMoreOptionsPopUpForAudience() {
    showCupertinoModalPopup(
      useRootNavigator: false,
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
            //isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              Share.share(
                  'Challo is a Kerala-based social media where you can create and stream Malayalam debates & podcasts, read the latest news stories, and more. Proudly made in India 🇮🇳. Download on Android: https://play.google.com/store/apps/details?id=tv.challo.challo ; Download on iOS: https://apps.apple.com/us/app/challo-live-discussions/id1611176469');
            },
            child: Text(
              'Share',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 20.0,
                    color: kPrimaryColorTint2,
                    fontStyle: FontStyle.normal,
                  ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              infodialog();
            },
            child: Text(
              'Stream Info',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 20.0,
                    color: kPrimaryColorTint2,
                    fontStyle: FontStyle.normal,
                  ),
            ),
          ),
          CupertinoActionSheetAction(
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

  void _commentsClicked() {
    setState(() {
      //fullscreenenabled = false;
      showcomments = true;
    });
  }

  /*void _starttoggle() {
    setState(() {
      _visible = !_visible;
    });
  }*/

  getalldataandinitialize() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    String dateString = dateFormat.format(DateTime.now());
    viewerid = FirebaseAuth.instance.currentUser!.uid;
    var viewerdoc = await usercollection.doc(viewerid).get();
    viewerusername = viewerdoc['username'];
    viewerpic = viewerdoc['profilepic'];

    var setupinfodocs =
        await FirebaseFirestore.instance.collection('setupinfo').doc('').get();

    appId = setupinfodocs['appId'];

    var thisvideo = await contentcollection.doc(widget.docName).get();

    List<String> blockedbylist = List.from(thisvideo['blockedby']);

    if (blockedbylist.contains(viewerid)) {
      setState(() {
        checkwhetherblocked = true;
      });
    }

    time = (thisvideo['time']).toDate();

    liveviews = List.from(thisvideo['liveviews']);

    totalviews = List.from(thisvideo['totalviews']);

    formattype = thisvideo['type'];

    if (formattype == 'QnA') {
      baseUrl = tokenServerUrl;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    } else {
      baseUrl = tokenServerUrl;
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    if (liveviews.contains(viewerid)) {
      print("Viewerid already exists in liveviews array, no need to add again");
    } else {
      contentcollection.doc(widget.docName).update({
        'liveviews': FieldValue.arrayUnion([viewerid])
      });
    }

    contentcollection.doc(widget.docName).update({
      'totalviews': FieldValue.arrayUnion(["${viewerid!} $dateString"])
    });

    var user0docs = await contentcollection
        .doc(widget.docName)
        .collection('users')
        .doc('user 0')
        .get();

    if (formattype == "QnA") {
      final String? user0uid = user0docs['uid'];
      final String? user0username = user0docs['username'];
      final String? user0name = user0docs['name'];
      final String? user0email = user0docs['email'];
      final String? user0pic = user0docs['pic'];

      user0 = UserInfoModel(
        uid: user0uid,
        username: user0username,
        name: user0name,
        email: user0email,
        pic: user0pic,
      );
    } else if (formattype == "Debate") {
      String? user0uid = user0docs['uid'];
      String? user0username = user0docs['username'];
      String? user0name = user0docs['name'];
      String? user0email = user0docs['email'];
      String? user0pic = user0docs['pic'];
      String? user0stand = user0docs['stand'];

      user0 = UserInfoModel(
          uid: user0uid,
          username: user0username,
          name: user0name,
          email: user0email,
          pic: user0pic,
          selectedRadioStand: user0stand);

      var user1docs = await contentcollection
          .doc(widget.docName)
          .collection('users')
          .doc('user 1')
          .get();

      String? user1uid = user1docs['uid'];
      String? user1username = user1docs['username'];
      String? user1name = user1docs['name'];
      String? user1email = user1docs['email'];
      String? user1pic = user1docs['pic'];
      String? user1stand = user1docs['stand'];

      user1 = UserInfoModel(
        uid: user1uid,
        username: user1username,
        name: user1name,
        email: user1email,
        pic: user1pic,
        selectedRadioStand: user1stand,
      );
    } else {
      //podcasts
      String? user0uid = user0docs['uid'];
      String? user0username = user0docs['username'];
      String? user0name = user0docs['name'];
      String? user0email = user0docs['email'];
      String? user0pic = user0docs['pic'];
      user0 = UserInfoModel(
          uid: user0uid,
          username: user0username,
          name: user0name,
          email: user0email,
          pic: user0pic);

      guestsno = thisvideo['guestsno'];
      if (guestsno == 1) {
        var user1docs = await contentcollection
            .doc(widget.docName)
            .collection('users')
            .doc('user 1')
            .get();

        String? user1uid = user1docs['uid'];
        String? user1username = user1docs['username'];
        String? user1name = user1docs['name'];
        String? user1email = user1docs['email'];
        String? user1pic = user1docs['pic'];

        user1 = UserInfoModel(
          uid: user1uid,
          username: user1username,
          name: user1name,
          email: user1email,
          pic: user1pic,
        );
      } else if (guestsno == 2) {
        var user1docs = await contentcollection
            .doc(widget.docName)
            .collection('users')
            .doc('user 1')
            .get();

        String? user1uid = user1docs['uid'];
        String? user1username = user1docs['username'];
        String? user1name = user1docs['name'];
        String? user1email = user1docs['email'];
        String? user1pic = user1docs['pic'];

        var user2docs = await contentcollection
            .doc(widget.docName)
            .collection('users')
            .doc('user 2')
            .get();

        String? user2uid = user2docs['uid'];
        String? user2username = user2docs['username'];
        String? user2name = user2docs['name'];
        String? user2email = user2docs['email'];
        String? user2pic = user2docs['pic'];

        user1 = UserInfoModel(
          uid: user1uid,
          username: user1username,
          name: user1name,
          email: user1email,
          pic: user1pic,
        );

        user2 = UserInfoModel(
          uid: user2uid,
          username: user2username,
          name: user2name,
          email: user2email,
          pic: user2pic,
        );
      } else {
        var user1docs = await contentcollection
            .doc(widget.docName)
            .collection('users')
            .doc('user 1')
            .get();

        String? user1uid = user1docs['uid'];
        String? user1username = user1docs['username'];
        String? user1name = user1docs['name'];
        String? user1email = user1docs['email'];
        String? user1pic = user1docs['pic'];

        var user2docs = await contentcollection
            .doc(widget.docName)
            .collection('users')
            .doc('user 2')
            .get();

        String? user2uid = user2docs['uid'];
        String? user2username = user2docs['username'];
        String? user2name = user2docs['name'];
        String? user2email = user2docs['email'];
        String? user2pic = user2docs['pic'];

        var user3docs = await contentcollection
            .doc(widget.docName)
            .collection('users')
            .doc('user 3')
            .get();

        String? user3uid = user3docs['uid'];
        String? user3username = user3docs['username'];
        String? user3name = user3docs['name'];
        String? user3email = user3docs['email'];
        String? user3pic = user3docs['pic'];

        user1 = UserInfoModel(
          uid: user1uid,
          username: user1username,
          name: user1name,
          email: user1email,
          pic: user1pic,
        );

        user2 = UserInfoModel(
          uid: user2uid,
          username: user2username,
          name: user2name,
          email: user2email,
          pic: user2pic,
        );

        user3 = UserInfoModel(
          uid: user3uid,
          username: user3username,
          name: user3name,
          email: user3email,
          pic: user3pic,
        );
      }
    }

    final String? topic = thisvideo['topic'];
    final String? description = thisvideo['description'];
    final String? category = thisvideo['category'];

    //get data on likes and views
    final likeslist = List.from(thisvideo['likes']);
    final dislikeslist = List.from(thisvideo['dislikes']);

    if (likeslist.contains(viewerid)) {
      setState(() {
        liked = true;
      });
    } else {
      setState(() {
        liked = false;
      });
    }

    if (dislikeslist.contains(viewerid)) {
      setState(() {
        disliked = true;
      });
    } else {
      setState(() {
        disliked = false;
      });
    }

    contentinfo = ContentInfoModel(
        subject: topic, description: description, category: category);

    setState(() {
      dataisthere = true;
    });
    if (dataisthere == true) {
      print("dataisthere for audience page is true");
      // initialize agora sdk
      initialize();
    } else {
      _setupError();
    }

    if (dataisthere == true) {
      timer = Timer.periodic(const Duration(seconds: 60), (Timer t) {
        setState(() {
          time = time;
        });
      });
    }
  }

  void _setupError() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Error",
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: Colors.white,
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold)),
          content: new Text("Sorry, something went wrong. Please try again.",
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    color: Colors.white70,
                    fontSize: 14.0,
                  )),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new TextButton(
              ////highlightColor: Colors.white,
              child:
                  const Text("Close", style: TextStyle(color: kPrimaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // "${baseUrl}/api/get/rtc/${widget.docName!}"

  Future<void> _getToken() async {
    /*final response =
        await http.get(Uri.parse(baseUrl + '/api/get/rtc/' + widget.docName!));*/
    final response =
        await http.get(Uri.parse("$baseUrl/api/get/rtc/${widget.docName!}"));
    if (response.statusCode == 200) {
      print(response.body);
      setState(() {
        generatedtoken = jsonDecode(response.body)['rtc_token'];
        print('The token generated is $generatedtoken');
        generateduid = jsonDecode(response.body)['uid'];
      });
    } else {
      print(response.reasonPhrase);
      print('Failed to generate the token : ${response.statusCode}');
    }
  }

  Future<void> initialize() async {
    /*if (appId.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }*/

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    VideoEncoderConfiguration configuration = VideoEncoderConfiguration();
    if (formattype == 'QnA') {
      configuration.dimensions = const VideoDimensions(width: 480, height: 848);
    } else {
      configuration.dimensions = const VideoDimensions(width: 848, height: 480);
    }
    configuration.frameRate = VideoFrameRate.Fps24;
    configuration.minFrameRate = VideoFrameRate.Fps15;
    await _engine.setVideoEncoderConfiguration(configuration);
    /*if (widget.onlineuser.didStart == true) {
      uid1 = widget.onlineuser.uid;
      uid2 = widget.opponentuser.uid;
    } else {
      uid2 = widget.onlineuser.uid;
      uid1 = widget.opponentuser.uid;
    }*/
    await _getToken();
    await _engine.joinChannel(
        generatedtoken, widget.docName!, null, generateduid);
    //await _startRecording(widget.docName);
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    _engine = await RtcEngine.create(appId!);
    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(widget.role);
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    _engine.setEventHandler(RtcEngineEventHandler(error: (code) {
      setState(() {
        final info = 'onError: $code';
        print(info);
        //_infoStrings.add(info);
      });
    }, joinChannelSuccess: (channel, uid, elapsed) {
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        print(info);
        //_infoStrings.add(info);
        _liveids.add(uid);
        print("uid is $uid");
      });
    }, leaveChannel: (stats) {
      setState(() {
        //_infoStrings.add('onLeaveChannel');
        _users.clear();
        _liveids.clear();
      });
    }, userJoined: (uid, elapsed) {
      setState(() {
        final info = 'userJoined: $uid';
        print(info);
        //_infoStrings.add(info);
        _users.add(uid);
        _liveids.add(uid);
      });
    }, userOffline: (uid, elapsed) {
      setState(() {
        final info = 'userOffline: $uid';
        print(info);
        //_infoStrings.add(info);
        _users.remove(uid);
        _liveids.remove(uid);
      });
    }, firstRemoteVideoFrame: (uid, width, height, elapsed) {
      setState(() {
        final info = 'firstRemoteVideo: $uid ${width}x $height';
        print(info);
        print("Width is $width and height is $height");
        //_infoStrings.add(info);
      });
    }));
  }

  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    final List<StatefulWidget> list = [];
    if (widget.role == ClientRole.Broadcaster) {
      list.add(const rtc_local_view.SurfaceView());
    }
    for (int uid in _users) {
      list.add(
          rtc_remote_view.SurfaceView(uid: uid, channelId: widget.docName!));
    }
    //changed for dart upgrade
    /* _users.forEach((int uid) => list
        .add(rtc_remote_view.SurfaceView(uid: uid, channelId: widget.docName)));*/
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
  }

  Widget _thirdParticipantRow(view) {
    return Expanded(
      child: Row(
        children: [Expanded(child: Container(child: view)), const Spacer()],
      ),
    );
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views) {
    final wrappedViews = views.map<Widget>(_videoView).toList();
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  hideorshowcontrols() {
    if (hidecontrols == false) {
      setState(() {
        hidecontrols = true;
      });
    } else {
      setState(() {
        hidecontrols = false;
      });
    }
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return AspectRatio(
          aspectRatio: 9 / 16,
          child: Column(
            children: <Widget>[_videoView(views[0])],
          ),
        );

      case 2:
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
            ],
          ),
        );

      case 3:
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _expandedVideoRow(views.sublist(2, 3))
            ],
          ),
        );
      case 4:
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _expandedVideoRow(views.sublist(2, 4))
            ],
          ),
        );
      default:
    }
    return Container();
  }

  Widget _viewMultipleRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            child: views[0],
          ),
        );

      case 2:
        return AspectRatio(
            aspectRatio: 16 / 9,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[_videoView(views[0]), _videoView(views[1])],
            ));

      case 3:
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _thirdParticipantRow(views[2])
            ],
          ),
        );

      case 4:
        return AspectRatio(
          aspectRatio: 16 / 9,
          child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _expandedVideoRow(views.sublist(2, 4))
            ],
          ),
        );
      default:
    }
    return Container();
  }

  audienceexit() async {
    contentcollection.doc(widget.docName).update({
      'liveviews': FieldValue.arrayRemove([viewerid])
    });
    setState(() {
      hidenav = false;
    });
    AppBuilder.of(context)!.rebuild();
    Navigator.of(context).pop();
  }

  Widget _smallerToolbar() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        height: 35,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            RawMaterialButton(
              onPressed: _checkliked,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: liked ? kPrimaryColor : Colors.white,
              padding: const EdgeInsets.all(10.0),
              child: Icon(
                Icons.arrow_upward_outlined,
                color: liked ? Colors.white : kPrimaryColor,
                size: 20.0,
              ),
            ),
            RawMaterialButton(
              onPressed: _checkdisliked,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: disliked ? kPrimaryColor : Colors.white,
              padding: const EdgeInsets.all(10.0),
              child: Icon(
                Icons.arrow_downward_outlined,
                color: disliked ? Colors.white : kPrimaryColor,
                size: 20.0,
              ),
            ),
            RawMaterialButton(
              onPressed: () => audienceexit(),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(10.0),
              child: const Icon(
                Icons.exit_to_app_rounded,
                color: Colors.white,
                size: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toolbar layout
  Widget _toolbarforaudience() {
    return (hidecontrols == false)
        ? Container(
            height: (MediaQuery.of(context).size.height) / 2,
            padding: const EdgeInsets.only(bottom: 10),
            alignment: Alignment.bottomCenter,
            //alignment: Alignment.bottomCenter,
            //padding: const EdgeInsets.symmetric(vertical: 48),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: RawMaterialButton(
                    onPressed: _checkliked,
                    child: Icon(
                      Icons.arrow_upward_outlined,
                      color: liked ? Colors.white : kPrimaryColor,
                      size: 20.0,
                    ),
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    fillColor: liked ? kPrimaryColor : Colors.white,
                    padding: const EdgeInsets.all(12.0),
                  ),
                ),
                Expanded(
                  child: RawMaterialButton(
                    onPressed: _checkdisliked,
                    child: Icon(
                      Icons.arrow_downward_outlined,
                      color: disliked ? Colors.white : kPrimaryColor,
                      size: 20.0,
                    ),
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    fillColor: disliked ? kPrimaryColor : Colors.white,
                    padding: const EdgeInsets.all(12.0),
                  ),
                ),
                Expanded(
                  child: RawMaterialButton(
                    onPressed: _commentsClicked,
                    child: const Icon(
                      Icons.comment,
                      color: kPrimaryColor,
                      size: 20.0,
                    ),
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    fillColor: Colors.white,
                    padding: const EdgeInsets.all(12.0),
                  ),
                ),
                Expanded(
                  child: RawMaterialButton(
                    onPressed: () => audienceexit(),
                    child: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Colors.white,
                      size: 20.0,
                    ),
                    shape: const CircleBorder(),
                    elevation: 2.0,
                    fillColor: Colors.redAccent,
                    padding: const EdgeInsets.all(12.0),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: InkWell(
                    onTap: () => showMoreOptionsPopUpForAudience(),
                    child: const Icon(
                      Icons.more_vert,
                      size: 25,
                      color: kHeadlineColorDark,
                    ),
                  ),
                ),
              ],
            ),
          )
        : Container();
  }

  infodialog() {
    return showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            contentPadding: const EdgeInsets.only(left: 10, right: 10),
            title: Stack(
              children: [
                Positioned(
                  right: 0.0,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const Align(
                      alignment: Alignment.topRight,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.close, color: Colors.red, size: 15),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    "$formattype Info",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              ],
            ),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20.0))),
            content: Container(
              height: (MediaQuery.of(context).size.height) / 1.2,
              width: (MediaQuery.of(context).size.width) / 1.2,
              child: Column(
                children: [
                  (formattype == "Debate")
                      ? AudienceDebateInfoWidget(
                          user0: user0,
                          user1: user1,
                          contentinfo: contentinfo,
                        )
                      : (formattype == "Podcast")
                          ? (guestsno == 1)
                              ? PodcastInfoWidget(
                                  guestsno: guestsno,
                                  user0: user0,
                                  user1: user1,
                                  contentinfo: contentinfo)
                              : PodcastInfoWidget(
                                  guestsno: guestsno,
                                  user0: user0,
                                  user1: user1,
                                  user2: user2,
                                  contentinfo: contentinfo)
                          : ContentInfoWidget(
                              formattype: "QnA",
                              user0: user0,
                              contentinfo: contentinfo,
                            ),
                ],
              ),
            ),
          );
        });
  }

  clearComment() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _commentController.clear());
  }

  void publishComment() async {
    final String commentContent = _commentController.text;
    _commentController.clear();
    setState(() {
      showPublishButton = false;
    });
    final String commentId = generateRandomDocName(viewerusername!);
    final time = DateTime.now();
    final timestamp = time.millisecondsSinceEpoch;

    await commentsdb.child(widget.docName!).child(commentId).set({
      'content': commentContent,
      'commentId': commentId,
      'parentCommentId': commentId,
      'docName': widget.docName,
      'time': timestamp,
      'type': 'text',
      'status': 'published',
      'posterUid': viewerid,
      'posterUsername': viewerusername,
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
                FocusManager.instance.primaryFocus?.unfocus(),
              }),
        });
  }

  /*void _upvoteComment(String? id) async {
    var doc = await contentcollection
        .doc(widget.docName)
        .collection('comments')
        .doc(id)
        .get();
    if (doc['likes'].contains(viewerid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'likes': FieldValue.arrayRemove([viewerid])
      });
    } else if (doc['dislikes'].contains(viewerid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'dislikes': FieldValue.arrayRemove([viewerid]),
        'likes': FieldValue.arrayUnion([viewerid])
      });
    } else {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'likes': FieldValue.arrayUnion([viewerid])
      });
    }
  }

  void _downvoteComment(String? id) async {
    var doc = await contentcollection
        .doc(widget.docName)
        .collection('comments')
        .doc(id)
        .get();
    if (doc['dislikes'].contains(viewerid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'dislikes': FieldValue.arrayRemove([viewerid])
      });
    } else if (doc['likes'].contains(viewerid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'likes': FieldValue.arrayRemove([viewerid]),
        'dislikes': FieldValue.arrayUnion([viewerid])
      });
    } else {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'dislikes': FieldValue.arrayUnion([viewerid])
      });
    }
  }*/

  _checkliked() async {
    var videodoc = await contentcollection.doc(widget.docName).get();

    if (videodoc['likes'].contains(viewerid)) {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayRemove([viewerid])
      });
      setState(() {
        liked = false;
        disliked = false;
      });
    } else if (videodoc['dislikes'].contains(viewerid)) {
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayRemove([viewerid])
      });
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayUnion([viewerid])
      });
      setState(() {
        liked = true;
        disliked = false;
      });
    } else {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayUnion([viewerid])
      });
      setState(() {
        liked = true;
        disliked = false;
      });
    }
  }

  _checkdisliked() async {
    var videodoc = await contentcollection.doc(widget.docName).get();

    if (videodoc['dislikes'].contains(viewerid)) {
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayRemove([viewerid])
      });
      setState(() {
        disliked = false;
        liked = false;
      });
    } else if (videodoc['likes'].contains(viewerid)) {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayRemove([viewerid])
      });
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayUnion([viewerid])
      });
      setState(() {
        disliked = true;
        liked = false;
      });
    } else {
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayUnion([viewerid])
      });
      setState(() {
        disliked = true;
        liked = false;
      });
    }
  }

  Widget _liveViewersWidget(int? updownratio, int? viewersno) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
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
              onPressed: () {
                audienceexit();
              },
              child: const Icon(
                Icons.arrow_back,
                size: 25,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            decoration: const BoxDecoration(
              color: kSurfaceDarkColor,
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'LIVE',
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      fontSize: 14,
                      color: kPrimaryColor,
                      fontWeight: FontWeight.w900),
                ),
                Text(
                  ' • ${tago.format(time, locale: 'en_short')} •',
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        fontSize: 14,
                        color: Colors.white,
                        // fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(
                  width: 5.0,
                ),
                const Icon(
                  Icons.arrow_upward,
                  size: 14,
                ),
                const Icon(
                  Icons.arrow_downward,
                  size: 14,
                ),
                Text(
                  ' $updownratio',
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 5.0),
            child: Text(
              '$viewersno watching',
              style: Theme.of(context)
                  .textTheme
                  .subtitle1!
                  .copyWith(fontSize: 15.0, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liveViews() {
    return StreamBuilder(
        stream: contentcollection.doc(widget.docName).snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return (showcomments == true)
                ? Container()
                : const Center(
                    child: CupertinoActivityIndicator(
                    color: kDarkPrimaryColor,
                  ));
          }
          var liveDocument = snapshot.data;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if ((liveDocument['status'] == 'completed') ||
                (liveDocument['status'] == 'published')) {
              setState(() {
                streamended = true;
              });
            }
          });
          return (showcomments == true)
              ? Container()
              : _liveViewersWidget(
                  liveDocument['likes'].length -
                      liveDocument['dislikes'].length,
                  liveDocument['liveviews'].length);
        });
  }

  Widget commentCardNew() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Row(
                  children: [
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
                    const SizedBox(width: 20.0),
                    InkWell(
                      onTap: () {
                        setState(() {
                          showcomments = false;
                        });
                      },
                      child: const Icon(
                        Icons.close,
                        size: 25,
                      ),
                    ),
                  ],
                ),
              ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              children: [
                for (CommentModel c in commentsList) commentCardWidget(c),
              ],
              reverse: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget commentCardWidget(CommentModel c) {
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
            //showUserQuickInfo(c.posterUsername, c.posterUid);
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
          whetherUpvoted: c.likes.contains(viewerid!),
          whetherDownvoted: c.dislikes.contains(viewerid!),
          onReply: null,
          onlineuid: viewerid!,
          comment: c,
          onUpvoted: () => upvotePost(c),
          onDownvoted: () => downvotePost(c),
        ),
        replyShowWidget(c),
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
                            repliesMap[c.commentId]![index]);
                      },
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
    if (likes.contains(viewerid)) {
      likes.remove(viewerid);
      await commentsdb.child(c.path).update({
        'likes': likes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else if (dislikes.contains(viewerid)) {
      dislikes.remove(viewerid);
      likes.add(viewerid!);
      await commentsdb.child(c.path).update({
        'dislikes': dislikes,
        'likes': likes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else {
      likes.add(viewerid!);
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
    if (dislikes.contains(viewerid)) {
      dislikes.remove(viewerid);
      await commentsdb.child(c.path).update({
        'dislikes': dislikes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else if (likes.contains(viewerid)) {
      likes.remove(viewerid);
      dislikes.add(viewerid!);
      await commentsdb.child(c.path).update({
        'likes': likes,
        'dislikes': dislikes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else {
      dislikes.add(viewerid!);
      await commentsdb.child(c.path).update({
        'dislikes': dislikes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    }
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
          onChanged: (text) {
            String trimmedText = text.trim();
            if (trimmedText.isEmpty) {
              if (showPublishButton == true) {
                setState(() {
                  showPublishButton = false;
                });
              }
            } else {
              if (showPublishButton == false) {
                setState(() {
                  showPublishButton = true;
                });
              }
            }
          },
          cursorColor: kHeadlineColorDark,
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
              suffixIcon: (showPublishButton == false)
                  ? null
                  : InkWell(
                      onTap: () {
                        publishComment();
                      },
                      child: const Icon(
                        Icons.send,
                        color: kPrimaryColorTint2,
                      ),
                    )

              /*IconButton(
              icon: Icon(
                Icons.clear,
                color: Colors.grey.shade600,
                size: 24,
              ),
              onPressed: () => clearComment(),
            ),*/
              ),
        ),
      ),
    );
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

  commentUnblockSubmit(CommentModel c) async {
    var commentdocs = await commentsdb.child(c.path).get();

    final List<String> blockedByLatest =
        ((commentdocs.value as Map)['blockedBy'] != null)
            ? List.from((commentdocs.value as Map)['blockedBy'])
            : [];
    if (blockedByLatest.contains(viewerid)) {
      blockedByLatest.remove(viewerid);
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
          (c.blockedBy.contains(viewerid))
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
                                  print("Comment Report Canceled");
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
      if (formattype == 'Debate' || formattype == 'Podcast') {
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
    blockedByLatest.add(viewerid!);
    await commentsdb.child(c.path).update({
      'blockedBy': blockedByLatest,
    }).then((_) async => {
          await commentreportcollection
              .doc(generateRandomDocName(viewerusername!))
              .set({
            'type': 'livevideocomment',
            'status': 'reported', //reported -> deleted/noaction/pending
            'reporter': viewerid,
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
      });
    }
    // for audience
    return (dataisthere == false)
        ? const Scaffold(
            resizeToAvoidBottomInset: false,
            //backgroundColor: Colors.black,
            body: Center(
                child: CupertinoActivityIndicator(
              color: kDarkPrimaryColor,
            )),
          )
        : (checkwhetherblocked == true)
            ? Scaffold(
                appBar: AppBar(),
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
                          child: Text("Stream hidden for you.",
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
            : (streamended == false)
                ? (Platform.isIOS)
                    ? WillPopScope(
                        onWillPop: () async => false,
                        child: Scaffold(
                          resizeToAvoidBottomInset: false,
                          body: SafeArea(
                            child: Center(
                              child: (formattype == 'QnA')
                                  ? (showcomments == false)
                                      ? Stack(
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                if (showcomments == true) {
                                                  setState(() {
                                                    showcomments = false;
                                                  });
                                                }
                                              },
                                              child: Container(
                                                height: MediaQuery.of(context)
                                                    .size
                                                    .height,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                child: _viewRows(),
                                              ),
                                            ),
                                            Positioned.fill(
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: _toolbarforaudience(),
                                              ),
                                            ),
                                            Positioned(
                                              left: 0.0,
                                              top: 0.0,
                                              child: _liveViews(),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Stack(
                                              children: [
                                                //when comments open for QnAs
                                                InkWell(
                                                  onTap: () {
                                                    if (showcomments == true) {
                                                      setState(() {
                                                        showcomments = false;
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    alignment:
                                                        Alignment.topCenter,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height /
                                                            4,
                                                    child: _viewRows(),
                                                  ),
                                                ),
                                                Positioned.fill(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.bottomRight,
                                                    child: _smallerToolbar(),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: 0.0,
                                                  top: 0.0,
                                                  child: _liveViews(),
                                                ),
                                              ],
                                            ),
                                            (commentdataexists == false)
                                                ? const Expanded(
                                                    child:
                                                        CupertinoActivityIndicator(
                                                      color: kDarkPrimaryColor,
                                                    ),
                                                  )
                                                : Expanded(
                                                    child: commentCardNew()),
                                            _commentBox(),
                                          ],
                                        )
                                  : (fullscreenenabled == false)
                                      ? (showcomments == false)
                                          ? Stack(
                                              //podcasts, debates without comments
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (showcomments == true) {
                                                      setState(() {
                                                        showcomments = false;
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .height,
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        _viewMultipleRows(),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Positioned.fill(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child:
                                                        _toolbarforaudience(),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: 0.0,
                                                  top: 0.0,
                                                  child: _liveViews(),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Stack(
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        if (showcomments ==
                                                            true) {
                                                          setState(() {
                                                            showcomments =
                                                                false;
                                                          });
                                                        }
                                                      },
                                                      child: Container(
                                                        alignment:
                                                            Alignment.topCenter,
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height /
                                                            4,
                                                        child:
                                                            _viewMultipleRows(),
                                                      ),
                                                    ),
                                                    Positioned.fill(
                                                      child: Align(
                                                        alignment: Alignment
                                                            .bottomRight,
                                                        child:
                                                            _smallerToolbar(),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: 0.0,
                                                      top: 0.0,
                                                      child: _liveViews(),
                                                    ),
                                                  ],
                                                ),
                                                (commentdataexists == false)
                                                    ? const Expanded(
                                                        child:
                                                            CupertinoActivityIndicator(
                                                          color:
                                                              kDarkPrimaryColor,
                                                        ),
                                                      )
                                                    : Expanded(
                                                        child:
                                                            commentCardNew()),
                                                _commentBox(),
                                              ],
                                            )
                                      : Stack(
                                          children: [
                                            Container(
                                                height: MediaQuery.of(context)
                                                    .size
                                                    .height,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                child: _viewMultipleRows()),
                                            Positioned.fill(
                                                child: Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: _liveViews()))
                                          ],
                                        ),
                            ),
                          ),
                        ),
                      )
                    : WillPopScope(
                        //for Android when streamended false
                        onWillPop: () {
                          audienceexit();
                          return Future.value(false);
                        },
                        child: Scaffold(
                          resizeToAvoidBottomInset: false,
                          body: SafeArea(
                            child: Center(
                              child: (formattype == 'QnA')
                                  ? (showcomments == false)
                                      ? Stack(
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                if (showcomments == true) {
                                                  setState(() {
                                                    showcomments = false;
                                                  });
                                                }
                                              },
                                              child: Container(
                                                height: MediaQuery.of(context)
                                                    .size
                                                    .height,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                child: _viewRows(),
                                              ),
                                            ),
                                            Positioned.fill(
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: _toolbarforaudience(),
                                              ),
                                            ),
                                            Positioned(
                                              left: 0.0,
                                              top: 0.0,
                                              child: _liveViews(),
                                            ),
                                          ],
                                        )
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Stack(
                                              children: [
                                                //when comments open for QnAs
                                                InkWell(
                                                  onTap: () {
                                                    if (showcomments == true) {
                                                      setState(() {
                                                        showcomments = false;
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    alignment:
                                                        Alignment.topCenter,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height /
                                                            4,
                                                    child: _viewRows(),
                                                  ),
                                                ),
                                                Positioned.fill(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.bottomRight,
                                                    child: _smallerToolbar(),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: 0.0,
                                                  top: 0.0,
                                                  child: _liveViews(),
                                                ),
                                              ],
                                            ),
                                            (commentdataexists == false)
                                                ? const Expanded(
                                                    child:
                                                        CupertinoActivityIndicator(
                                                      color: kDarkPrimaryColor,
                                                    ),
                                                  )
                                                : Expanded(
                                                    child: commentCardNew()),
                                            _commentBox(),
                                          ],
                                        )
                                  : (fullscreenenabled == false)
                                      ? (showcomments == false)
                                          ? Stack(
                                              //podcasts, debates without comments
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (showcomments == true) {
                                                      setState(() {
                                                        showcomments = false;
                                                      });
                                                    }
                                                  },
                                                  child: Container(
                                                    height:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .height,
                                                    width:
                                                        MediaQuery.of(context)
                                                            .size
                                                            .width,
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        _viewMultipleRows(),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                Positioned.fill(
                                                  child: Align(
                                                    alignment:
                                                        Alignment.bottomCenter,
                                                    child:
                                                        _toolbarforaudience(),
                                                  ),
                                                ),
                                                Positioned(
                                                  left: 0.0,
                                                  top: 0.0,
                                                  child: _liveViews(),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Stack(
                                                  children: [
                                                    InkWell(
                                                      onTap: () {
                                                        if (showcomments ==
                                                            true) {
                                                          setState(() {
                                                            showcomments =
                                                                false;
                                                          });
                                                        }
                                                      },
                                                      child: Container(
                                                        alignment:
                                                            Alignment.topCenter,
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height /
                                                            4,
                                                        child:
                                                            _viewMultipleRows(),
                                                      ),
                                                    ),
                                                    Positioned.fill(
                                                      child: Align(
                                                        alignment: Alignment
                                                            .bottomRight,
                                                        child:
                                                            _smallerToolbar(),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      left: 0.0,
                                                      top: 0.0,
                                                      child: _liveViews(),
                                                    ),
                                                  ],
                                                ),
                                                (commentdataexists == false)
                                                    ? const Expanded(
                                                        child:
                                                            CupertinoActivityIndicator(
                                                          color:
                                                              kDarkPrimaryColor,
                                                        ),
                                                      )
                                                    : Expanded(
                                                        child:
                                                            commentCardNew()),
                                                _commentBox(),
                                              ],
                                            )
                                      : Stack(
                                          children: [
                                            Container(
                                                height: MediaQuery.of(context)
                                                    .size
                                                    .height,
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                child: _viewMultipleRows()),
                                            Positioned.fill(
                                                child: Align(
                                                    alignment:
                                                        Alignment.topLeft,
                                                    child: _liveViews()))
                                          ],
                                        ),
                            ),
                          ),
                        ),
                      )
                : (Platform.isIOS)
                    ? WillPopScope(
                        onWillPop: () async => false,
                        child: Scaffold(
                          appBar: AppBar(
                            leading: ButtonTheme(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                  horizontal:
                                      8.0), //adds padding inside the button
                              materialTapTargetSize: MaterialTapTargetSize
                                  .shrinkWrap, //limits the touch area to the button area
                              minWidth: 0, //wraps child's width
                              height: 0, //wraps child's height

                              child: TextButton(
                                onPressed: () {
                                  audienceexit();
                                },
                                child: const Icon(
                                  Icons.arrow_back,
                                  size: 25,
                                  color: kIconSecondaryColorDark,
                                ),
                              ),
                            ),
                          ),
                          //backgroundColor: Colors.black,
                          resizeToAvoidBottomInset: false,

                          body: const Center(
                            child: Text(
                              "This live stream has ended...",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      )
                    : WillPopScope(
                        //for Android when streamended true
                        onWillPop: () {
                          audienceexit();
                          return Future.value(false);
                        },
                        child: Scaffold(
                          appBar: AppBar(
                            leading: ButtonTheme(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                  horizontal:
                                      8.0), //adds padding inside the button
                              materialTapTargetSize: MaterialTapTargetSize
                                  .shrinkWrap, //limits the touch area to the button area
                              minWidth: 0, //wraps child's width
                              height: 0, //wraps child's height

                              child: TextButton(
                                onPressed: () {
                                  audienceexit();
                                },
                                child: const Icon(
                                  Icons.arrow_back,
                                  size: 25,
                                  color: kIconSecondaryColorDark,
                                ),
                              ),
                            ),
                          ),
                          //backgroundColor: Colors.black,
                          resizeToAvoidBottomInset: false,

                          body: const Center(
                            child: Text(
                              "This live stream has ended...",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      );
  }
}
