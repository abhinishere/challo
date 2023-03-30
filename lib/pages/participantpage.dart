import 'package:challo/models/comment_model.dart';
import 'package:challo/models/content_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/community_page.dart';
import 'package:challo/pages/pending_session.dart';
import 'package:challo/pages/profilepage.dart';
import 'package:challo/pages/selectformat.dart';
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
import 'dart:async';
import 'package:timeago/timeago.dart' as tago;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io' show Platform;
import 'dart:math';

class ParticipantPage extends StatefulWidget {
  /// non-modifiable channel name of the page
  final int? guestsno;

  final String? whostarted;

  final String? docName;

  final String formattype;

  /// non-modifiable client role of the page
  final ClientRole role;

  final UserInfoModel? onlineuser, user0, user1, user2;

  final ContentInfoModel? contentinfo;

  final String opusername, oppic;

  /// Creates a call page with given channel name.
  const ParticipantPage({
    Key? key,
    this.whostarted,
    required this.guestsno,
    required this.docName,
    required this.formattype,
    required this.role,
    required this.onlineuser,
    required this.user0,
    this.user1,
    this.user2,
    required this.contentinfo,
    required this.opusername,
    required this.oppic,
  }) : super(key: key);

  @override
  State<ParticipantPage> createState() => _ParticipantPageState();
}

class _ParticipantPageState extends State<ParticipantPage>
    with WidgetsBindingObserver {
  //String uid1, uid2;
  //int parseduid1; //agora's uid should be int

  //bool _visible = true;

  final _commentController = TextEditingController();

  final _chatController = TextEditingController();

  bool commentsheetopen = false;

  bool chatsheetopen = false;

  bool updatedlive = false;

  bool showexitdialog = false;

  bool exitLoading = false;

  int? uid1, uid2;

  String? rid, sid;
  int? recUid;

  String? appId;

  late String baseUrl;

  dynamic generatedtoken, generateduid;

  dynamic time;

  final _users = <int>[];
  final _liveids = <int>[];
  //var _sortedliveids = <int>[];
  bool muted = false;
  bool liked = false;
  int? liveviews;
  late RtcEngine _engine;

  bool split = false;

  bool whetherexited = false; //participants' exit after OP's exit

  bool showcomments = false;

  bool showchats = false;

  List<String>? participantsuids, participantspics;

  bool showPublishButton = false;

  bool commentdataexists = false;
  bool showsendbutton = false;

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

  bool whethercommentreportsubmitted = false;

  int? selectedCommentRadioNo = 1;
  String commentReportReason = "Spam or misleading";

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // clear users
    _users.clear();
    _liveids.clear();
    // destroy sdk
    _engine.leaveChannel();
    _engine.destroy();

    _commentController.dispose();

    _chatController.dispose();

    timer?.cancel();

    super.dispose();
  }

  //comments' variables
  late String commentsPath;
  late StreamSubscription commentStreamSubscription;
  late List<CommentModel> commentsList;
  late Map<String?, List<CommentModel>?> repliesMap;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    updateliveandinitialize();
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

  void _commentsClicked() {
    setState(() {
      showcomments = true;
    });
  }

  void _chatsClicked() {
    setState(() {
      showchats = true;
    });
  }

  /*void _starttoggle() {
    setState(() {
      _visible = !_visible;
    });
  }*/

  updateliveandinitialize() async {
    whetherStreaming = true;
    print("Inside updateliveandinitialize function");
    if (widget.formattype == 'QnA') {
      baseUrl = tokenServerUrl;
    } else {
      baseUrl = tokenServerUrl;
    }

    var setupinfodocs =
        await FirebaseFirestore.instance.collection('setupinfo').doc('').get();

    appId = setupinfodocs['appId'];

    await usercollection.doc(widget.onlineuser!.uid).update({'isLive': true});

    if ((widget.onlineuser!.uid == widget.whostarted) ||
        (widget.formattype == 'QnA')) {
      //add date & time
      time = DateTime.now();
      await contentcollection.doc(widget.docName).update({
        'status': 'started',
        'time': time,
        'participateduids': FieldValue.arrayUnion([widget.onlineuser!.uid]),
        'participatedpics': FieldValue.arrayUnion([widget.onlineuser!.pic]),
        'participatedusernames':
            FieldValue.arrayUnion([widget.onlineuser!.username]),
      });
    } else {
      var channeldocs = await contentcollection.doc(widget.docName).get();

      time = (channeldocs['time'].toDate());

      if (channeldocs['participatedpics'].contains(widget.onlineuser!.pic)) {
        //if this participant and other participant(s) use the same default picture
        print("Another profile is using the same default picture");
        final picslist = List.from(channeldocs['participatedpics']);
        print("picslist length is ${picslist.length}");
        picslist.add(widget.onlineuser!.pic);
        print("New picslist length is ${picslist.length}");
        await contentcollection.doc(widget.docName).update({
          'participateduids': FieldValue.arrayUnion([widget.onlineuser!.uid]),
          'participatedpics': picslist,
          'participatedusernames':
              FieldValue.arrayUnion([widget.onlineuser!.username]),
        });
      } else {
        await contentcollection.doc(widget.docName).update({
          'participateduids': FieldValue.arrayUnion([widget.onlineuser!.uid]),
          'participatedpics': FieldValue.arrayUnion([widget.onlineuser!.pic]),
          'participatedusernames':
              FieldValue.arrayUnion([widget.onlineuser!.username]),
        });
      }
    }

    setState(() {
      updatedlive = true;
    });
    if (updatedlive == true) {
      // initialize agora sdk
      initialize();
    } else {
      _setupError();
    }

    if (updatedlive == true) {
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
              //highlightColor: Colors.white,
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

  // "$baseUrl/api/get/rtc/${widget.docName!}"

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

  Future<void> _startRecording(String? docName) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/start/call"),
      body: {"channel": docName},
    );

    /*
 final response = await http.post(
      Uri.parse(baseUrl + '/api/start/call'),
      body: {"channel": docName},
    );
    */

    if (response.statusCode == 200) {
      print('Recording Started');
      setState(() {
        rid = jsonDecode(response.body)['data']['rid'];
        recUid = jsonDecode(response.body)['data']['uid'];
        sid = jsonDecode(response.body)['data']['sid'];
      });
    } else {
      print('Couldn\'t start the recording : ${response.statusCode}');
    }
  }

  // add stoprecording to pendingsession page for debate and podcasts
  Future<void> _stopRecording(
      String? mdocName, String? mRid, String? mSid, int? mRecUid) async {
    final response = await http.post(
      Uri.parse("$baseUrl/api/stop/call"),
      body: {
        "channel": mdocName,
        "rid": mRid,
        "sid": mSid,
        "uid": mRecUid.toString()
      },
    );

    if (response.statusCode == 200) {
      print('Recording Ended');
    } else {
      print('Couldn\'t end the recording : ${response.statusCode}');
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
    configuration.dimensions = const VideoDimensions(width: 480, height: 848);
    configuration.frameRate = VideoFrameRate.Fps24;
    configuration.minFrameRate = VideoFrameRate.Fps15;
    await _engine.setVideoEncoderConfiguration(configuration);
    await _getToken();
    await _engine.joinChannel(
        generatedtoken, widget.docName!, null, generateduid);

    //recording only for initiator or qna's
    if ((widget.onlineuser!.uid == widget.whostarted) ||
        (widget.formattype == "QnA")) {
      await _startRecording(widget.docName);
    }
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
          rtc_remote_view.SurfaceView(channelId: widget.docName!, uid: uid));
    }
    //changed for dart upgrade
    /* _users
        .forEach((int uid) => list.add(rtc_remote_view.SurfaceView(uid: uid)));*/
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view) {
    return Expanded(child: Container(child: view));
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

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
              child: Column(
            children: <Widget>[_videoView(views[0])],
          )),
        );

      case 2:
        return AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
              child: Column(
            children: <Widget>[
              _expandedVideoRow([views[0]]),
              _expandedVideoRow([views[1]])
            ],
          )),
        );

      case 3:
        return AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
              child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _expandedVideoRow(views.sublist(2, 3))
            ],
          )),
        );
      case 4:
        return AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
              child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _expandedVideoRow(views.sublist(2, 4))
            ],
          )),
        );
      default:
    }
    return Container();
  }

  Widget _viewMultipleRows() {
    //final MediaQueryData mediaQueryData = MediaQuery.of(context);
    final views = _getRenderViews();
    switch (views.length) {
      case 1:
        return AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            child: Column(
              children: <Widget>[_videoView(views[0])],
            ),
          ),
        );

      case 2:
        return AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            child: new Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    children: <Widget>[
                      _expandedVideoRow([views[0]]),
                    ],
                  ),
                ),
                (showcomments == false && showchats == false)
                    ? Align(
                        alignment: Alignment.topRight,
                        child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 8,
                                color: Colors.white38,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.fromLTRB(15, 35, 10, 15),
                            width: 110,
                            height: 140,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                _expandedVideoRow([views[1]]),
                              ],
                            )))
                    : Align(
                        alignment: Alignment.topRight,
                        child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                width: 4,
                                color: Colors.white38,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.fromLTRB(10, 10, 5, 10),
                            width: 55,
                            height: 70,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                _expandedVideoRow([views[1]]),
                              ],
                            )))
              ],
            ),
          ),
        );

      case 3:
        return AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
            child: new Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.topLeft,
                  child: Column(
                    children: <Widget>[
                      _expandedVideoRow([views[0]]),
                    ],
                  ),
                ),
                (showcomments == false && showchats == false)
                    ? Column(children: [
                        Align(
                            alignment: Alignment.topRight,
                            child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 8,
                                    color: Colors.white38,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin:
                                    const EdgeInsets.fromLTRB(15, 35, 10, 5),
                                width: 110,
                                height: 140,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    _expandedVideoRow([views[1]]),
                                  ],
                                ))),
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 8,
                                  color: Colors.white38,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.fromLTRB(15, 5, 10, 15),
                              width: 110,
                              height: 140,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _expandedVideoRow([views[2]]),
                                ],
                              )),
                        )
                      ])
                    : Column(children: [
                        Align(
                            alignment: Alignment.topRight,
                            child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    width: 2,
                                    color: Colors.white38,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: const EdgeInsets.fromLTRB(5, 5, 3, 1),
                                width: 35,
                                height: 45,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    _expandedVideoRow([views[1]]),
                                  ],
                                ))),
                        Align(
                          alignment: Alignment.topRight,
                          child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  width: 2,
                                  color: Colors.white38,
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              margin: const EdgeInsets.fromLTRB(5, 1, 3, 5),
                              width: 35,
                              height: 45,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  _expandedVideoRow([views[2]]),
                                ],
                              )),
                        )
                      ])
              ],
            ),
          ),
        );

      case 4:
        return AspectRatio(
          aspectRatio: 9 / 16,
          child: Container(
              child: Column(
            children: <Widget>[
              _expandedVideoRow(views.sublist(0, 2)),
              _expandedVideoRow(views.sublist(2, 4))
            ],
          )),
        );
      default:
    }
    return Container();
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
              onPressed: _onToggleMute,
              child: Icon(
                muted ? Icons.mic_off : Icons.mic,
                color: muted ? Colors.white : kPrimaryColor,
                size: 20.0,
              ),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: muted ? kPrimaryColor : Colors.white,
              padding: const EdgeInsets.all(10.0),
            ),
            RawMaterialButton(
              onPressed: () => _onClickEnd(context),
              child: const Icon(
                Icons.exit_to_app_rounded,
                color: Colors.white,
                size: 20.0,
              ),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.redAccent,
              padding: const EdgeInsets.all(10.0),
            ),
          ],
        ),
      ),
    );
  }

  /// Toolbar layout
  Widget _toolbarforparticipants() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        height: (MediaQuery.of(context).size.height) / 2,
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: RawMaterialButton(
                onPressed: _onToggleMute,
                child: Icon(
                  muted ? Icons.mic_off : Icons.mic,
                  color: muted ? Colors.white : kPrimaryColor,
                  size: 20.0,
                ),
                shape: const CircleBorder(),
                elevation: 2.0,
                fillColor: muted ? kPrimaryColor : Colors.white,
                padding: const EdgeInsets.all(12.0),
              ),
            ),
            Expanded(
              child: RawMaterialButton(
                onPressed: _onSwitchCamera,
                child: const Icon(
                  Icons.switch_camera,
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
                onPressed: () => _onClickEnd(context),
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
              padding: const EdgeInsets.only(
                right: 10.0,
              ),
              child: InkWell(
                onTap: () => showMoreOptionsPopUpForParticipants(),
                child: const Icon(
                  Icons.more_vert,
                  size: 25,
                  color: kHeadlineColorDark,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  showMoreOptionsPopUpForParticipants() {
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
        actions: (widget.formattype == 'QnA')
            ? <CupertinoActionSheetAction>[
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
              ]
            : <CupertinoActionSheetAction>[
                CupertinoActionSheetAction(
                  //isDefaultAction: true,
                  onPressed: () {
                    Navigator.pop(context);
                    _chatsClicked();
                  },
                  child: Text(
                    'Private Chat',
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
                    "${widget.formattype} Info",
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
                  (widget.formattype == "Debate")
                      ? (widget.onlineuser!.uid == widget.whostarted)
                          ? ContentInfoWidget(
                              formattype: "Debate",
                              user0: widget.user0,
                              user1: widget.user1,
                              contentinfo: widget.contentinfo,
                            )
                          : ContentInfoWidget(
                              formattype: "Debate",
                              user0: widget.user1,
                              user1: widget.user0,
                              contentinfo: widget.contentinfo,
                            )
                      : (widget.formattype == "Podcast")
                          ? (widget.guestsno == 1)
                              ? PodcastInfoWidget(
                                  guestsno: widget.guestsno,
                                  user0: widget.user0,
                                  user1: widget.user1,
                                  contentinfo: widget.contentinfo)
                              : PodcastInfoWidget(
                                  guestsno: widget.guestsno,
                                  user0: widget.user0,
                                  user1: widget.user1,
                                  user2: widget.user2,
                                  contentinfo: widget.contentinfo)
                          : ContentInfoWidget(
                              formattype: "QnA",
                              user0: widget.onlineuser,
                              contentinfo: widget.contentinfo,
                            ),
                ],
              ),
            ),
          );
        });
  }

  /*void _onClickComplete(BuildContext context) async {
    if (widget.onlineuser.uid == widget.whostarted) {
      if (widget.guestsno == 0) {
        setState(() {
          exitLoading = true;
        });
        print(
            "Part 1 is working -- for QnAs & debates, podcasts with 0 guests");
        _stopRecording(widget.docName, rid, sid, recUid);
        await contentcollection
            .doc(widget.docName)
            .update({'status': 'completed'});
        var channeldocs =
            await contentcollection.doc(widget.docName).get();
        participantsuids = List.from(channeldocs['participateduids']);
        participantspics = List.from(channeldocs['participatedpics']);
        await usercollection
            .doc(widget.user0.uid)
            .update({'isLive': false, 'pendingvideo': false});
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TranscodingPage(
                      participantsuids: participantsuids,
                      participantspics: participantspics,
                      docName: widget.docName,
                      formattype: widget.formattype,
                      contentinfo: widget.contentinfo,
                      time: time,
                    )));
      } else {
        setState(() {
          exitLoading = true;
        });
        print("Part 2 is working -- for debates and podcasts");
        _stopRecording(widget.docName, rid, sid, recUid);
        await contentcollection
            .doc(widget.docName)
            .update({'status': 'completed'});
        var channeldocs =
            await contentcollection.doc(widget.docName).get();
        participantsuids = List.from(channeldocs['participateduids']);
        participantspics = List.from(channeldocs['participatedpics']);
        await usercollection
            .doc(widget.user0.uid)
            .update({'isLive': false, 'pendingvideo': false});
        if (participantsuids.length == 1) {
          //only OP went live
          completedUpdate();
        }
        await contentcollection.doc(widget.docName).update({
          'unexiteduids': FieldValue.arrayRemove([widget.onlineuser.uid])
        });
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => TranscodingPage(
                      participantsuids: participantsuids,
                      participantspics: participantspics,
                      docName: widget.docName,
                      formattype: widget.formattype,
                      contentinfo: widget.contentinfo,
                      time: time,
                    )));
      }
    } else {
      print("Part 3 is working -- for other participants");
      print("Online uid is ${widget.onlineuser.uid}");
      print("Who Started uid is ${widget.whostarted}");
      await usercollection
          .doc(widget.onlineuser.uid)
          .update({'isLive': false, 'pendingvideo': false});
      await contentcollection.doc(widget.docName).update({
        'unexiteduids': FieldValue.arrayRemove([widget.onlineuser.uid])
      });

      setState(() {
        hidenav = false;
      });
      AppBuilder.of(context).rebuild();
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => SelectFormat()),
          (route) => false);
    }
  }*/

  void _onClickEnd(BuildContext context) async {
    if (widget.onlineuser!.uid == widget.whostarted) {
      print("Exited user is OP. Ending recording...");
      whetherexited = true;
      whetherStreaming = false;
      _stopRecording(widget.docName, rid, sid, recUid);
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => PendingSession(
              oppic: widget.oppic,
              opusername: widget.opusername,
              whethervideoprocessing: true,
              onlineuser: widget.onlineuser,
              docName: widget.docName,
              whostarted: widget.whostarted,
              guestsno: widget.guestsno,
              contentinfo: widget.contentinfo,
              time: time,
            ),
            fullscreenDialog: true,
          ),
          (Route<dynamic> route) => false);
    } else {
      print("Exited user is NOT OP. Exiting...");
      whetherexited = true;
      whetherStreaming = false;
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => PendingSession(
              oppic: widget.oppic,
              opusername: widget.opusername,
              whethervideoprocessing: true,
              onlineuser: widget.onlineuser,
              docName: widget.docName,
              whostarted: widget.whostarted,
              guestsno: widget.guestsno,
              contentinfo: widget.contentinfo,
              time: time,
            ),
            fullscreenDialog: true,
          ),
          (Route<dynamic> route) => false);
    }
  }

  void _onToggleMute() {
    setState(() {
      muted = !muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
  }

  clearComment() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _commentController.clear());
  }

  clearChat() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _chatController.clear());
  }

  /*void publishComment() async {
    final String commentContent = _commentController.text;
    _commentController.clear();
    setState(() {
      showPublishButton = false;
    });
    final String commentId =
        generateRandomDocName(widget.onlineuser!.username!);
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
      'posterUid': widget.onlineuser!.uid,
      'posterUsername': widget.onlineuser!.username,
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
  }*/

  /*void publishComment2() async {
    List<String> blockedby = [];
    /*var videodocs = await contentcollection
        .doc(widget.docName)
        .collection('comments')
        .get();
    int commentlength = videodocs.docs.length;*/
    String commentDocName = generateRandomDocName(widget.onlineuser!.username!);
    contentcollection
        .doc(widget.docName)
        .collection('comments')
        .doc(commentDocName)
        .set({
      'username': widget.onlineuser!.username,
      'uid': widget.onlineuser!.uid,
      'pic': widget.onlineuser!.pic,
      'comment': _commentController.text,
      'likes': [],
      'dislikes': [],
      'time': DateTime.now(),
      'id': commentDocName,
      'docName': widget.docName,
      'status': 'published',
      'blockedby': blockedby,
    });
    _commentController.clear();
    var doc = await contentcollection.doc(widget.docName).get();
    contentcollection
        .doc(widget.docName)
        .update({'commentcount': doc['commentcount'] + 1});
  }*/

  void publishChat() async {
    final String messageContent = _chatController.text;
    _chatController.clear();
    setState(() {
      showsendbutton = false;
    });
    var chatdocs =
        await contentcollection.doc(widget.docName).collection('chats').get();
    int chatlength = chatdocs.docs.length;
    contentcollection
        .doc(widget.docName)
        .collection('chats')
        .doc('Chat $chatlength')
        .set({
      'username': widget.onlineuser!.username,
      'uid': widget.onlineuser!.uid,
      'pic': widget.onlineuser!.pic,
      'chat': messageContent,
      'time': DateTime.now(),
      'id': 'Chat $chatlength'
    });
  }

  /* void _upvoteComment(String? id) async {
    var doc = await contentcollection
        .doc(widget.docName)
        .collection('comments')
        .doc(id)
        .get();
    if (doc['likes'].contains(widget.onlineuser!.uid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'likes': FieldValue.arrayRemove([widget.onlineuser!.uid])
      });
    } else if (doc['dislikes'].contains(widget.onlineuser!.uid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'dislikes': FieldValue.arrayRemove([widget.onlineuser!.uid]),
        'likes': FieldValue.arrayUnion([widget.onlineuser!.uid])
      });
    } else {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'likes': FieldValue.arrayUnion([widget.onlineuser!.uid])
      });
    }
  }

  void _downvoteComment(String? id) async {
    var doc = await contentcollection
        .doc(widget.docName)
        .collection('comments')
        .doc(id)
        .get();
    if (doc['dislikes'].contains(widget.onlineuser!.uid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'dislikes': FieldValue.arrayRemove([widget.onlineuser!.uid])
      });
    } else if (doc['likes'].contains(widget.onlineuser!.uid)) {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'likes': FieldValue.arrayRemove([widget.onlineuser!.uid]),
        'dislikes': FieldValue.arrayUnion([widget.onlineuser!.uid])
      });
    } else {
      contentcollection
          .doc(widget.docName)
          .collection('comments')
          .doc(id)
          .update({
        'dislikes': FieldValue.arrayUnion([widget.onlineuser!.uid])
      });
    }
  }*/

  livestreamendeddialog(String livestatus) {
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: Text('Stream $livestatus',
            style: Theme.of(context).textTheme.subtitle1!.copyWith(
                color: Colors.white,
                fontSize: 15.0,
                fontWeight: FontWeight.bold)),
        content: Text('Streaming has finished. Press okay to go back.',
            style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: Colors.white70,
                  fontSize: 14.0,
                )),
        actions: <Widget>[
          // usually buttons at the bottom of the dialog
          new TextButton(
            //highlightColor: Colors.white,
            child: const Text("Okay", style: TextStyle(color: kPrimaryColor)),
            onPressed: () {
              //AppBuilder.of(context).rebuild();
              Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => SelectFormat()),
                  (route) => false);
            },
          ),
        ],
      ),
    );
  }

  completedUpdate() async {
    print("Inside completedUpdate function");
    var channeldocs = await contentcollection.doc(widget.docName).get();
    List<String> accepteduids, participateduids, nonparticipantsuids = [];
    accepteduids = List.from(channeldocs['accepteduids']);
    for (String i in accepteduids) {
      print("accepteduids are $i'");
    }
    participateduids = List.from(channeldocs['participateduids']);
    for (String i in participateduids) {
      print("participateduids uids are $i'");
    }
    nonparticipantsuids =
        accepteduids.toSet().difference(participateduids.toSet()).toList();
    for (String i in nonparticipantsuids) {
      print("nonparticipantsuids uids are $i'");
    }
    if (participateduids.isNotEmpty) {
      for (String uid in participateduids) {
        await usercollection.doc(uid).update({
          'pendingvideo': false,
          'isLive': false,
        });
      }
    }
    if (nonparticipantsuids.isNotEmpty) {
      for (String uid in nonparticipantsuids) {
        await usercollection.doc(uid).update({
          'pendingvideo': false,
        });
      }
    }
  }

  Widget _liveViewersWidget(int? updownratio, int? viewersno) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Row(
        children: [
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

  Widget _liveUpdates() {
    return StreamBuilder(
        stream: contentcollection.doc(widget.docName).snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return (showcomments == true || showchats == true)
                ? Container()
                : const Center(
                    child: CupertinoActivityIndicator(
                    color: kDarkPrimaryColor,
                  ));
          }
          var liveDocument = snapshot.data;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (((liveDocument['status'] == 'completed') ||
                    (liveDocument['status'] == 'published')) &&
                ((widget.formattype == 'Debate') ||
                    (widget.formattype == 'Podcast'))) {
              if (whetherexited == false) {
                print("OP has exited...now exiting other participants");
                whetherexited = true;
                whetherStreaming = false;
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => PendingSession(
                        oppic: widget.oppic,
                        opusername: widget.opusername,
                        whethervideoprocessing: true,
                        onlineuser: widget.onlineuser,
                        docName: widget.docName,
                        whostarted: widget.whostarted,
                        guestsno: widget.guestsno,
                        contentinfo: widget.contentinfo,
                        time: time,
                      ),
                      fullscreenDialog: true,
                    ),
                    (Route<dynamic> route) => false);
              }
            }
          });
          return (showcomments == true || showchats == true)
              ? Container()
              : _liveViewersWidget(
                  liveDocument['likes'].length -
                      liveDocument['dislikes'].length,
                  liveDocument['liveviews'].length);
        });
  }

  Widget _chatCard() {
    return Container(
      //height: MediaQuery.of(context).size.height / 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //crossAxisAlignment: CrossAxisAlignment.center,
              //mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'Private Chats',
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        color: kSubTextColor,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.24,
                      ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      showchats = false;
                    });
                  },
                  child: const Icon(
                    Icons.close,
                    size: 25,
                  ),
                ),
              ]),
        ),
        Expanded(
          child: Container(
            //color: Theme.of(context).primaryIconTheme.color,
            child: StreamBuilder<QuerySnapshot>(
              stream: contentcollection
                  .doc(widget.docName)
                  .collection('chats')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData) {
                  print("getting chats");
                  return const Center(
                      child: CupertinoActivityIndicator(
                    color: kDarkPrimaryColor,
                  ));
                }
                return ListView.builder(
                  physics: const ScrollPhysics(),
                  reverse: true,
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  //controller: controller,
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    var chat = snapshot.data.docs[index];
                    return Card(
                      color: kBackgroundColorDark,
                      child: ListTile(
                        title: Row(
                          children: [
                            Text(
                              "${chat['username']}",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle2!
                                  .copyWith(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: -0.08,
                                      color: Colors.grey.shade500),
                            ),
                            const SizedBox(width: 5.0),
                            Text(
                              "• ${tago.format(chat['time'].toDate())} •",
                              style:
                                  Theme.of(context).textTheme.caption!.copyWith(
                                        fontSize: 10.0,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                        letterSpacing: 0.12,
                                        //fontWeight: FontWeight.w500,
                                      ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          "${chat['chat']}",
                          style:
                              Theme.of(context).textTheme.subtitle1!.copyWith(
                                    color: kHeadlineColorDark,
                                    fontSize: 15.0,
                                    letterSpacing: -0.24,
                                    //fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
        _chatBoxNew(),
      ]),
    );
  }

  Widget _chatBoxNew() {
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
                      onTap: () => publishChat(),
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

  /*Widget _chatBox() {
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
                controller: _chatController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Start typing...',
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
                    onPressed: () => clearChat(),
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
                publishChat();
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

  /* Widget commentCard() {
    return Container(
      //height: MediaQuery.of(context).size.height / 2,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //crossAxisAlignment: CrossAxisAlignment.center,
              //mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  'Comments',
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        color: Colors.grey.shade500,
                        fontSize: 13.0,
                        fontWeight: FontWeight.w900,
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
                              title: Stack(children: [
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
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.red,
                                          size: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const Center(
                                  child: Text(
                                    "UGC Policy",
                                    style: TextStyle(color: Colors.white),
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
                              fontSize: 13.0,
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
                          setState(() {
                            showcomments = false;
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          size: 17,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
        ),
        Expanded(
          child: Container(
            //color: Theme.of(context).primaryIconTheme.color,
            child: StreamBuilder<QuerySnapshot>(
              stream: contentcollection
                  .doc(widget.docName)
                  .collection('comments')
                  .orderBy('time', descending: false)
                  .snapshots(),
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
                    if (comment['blockedby'].contains(widget.onlineuser!.uid)) {
                      return Container();
                    } else {
                      return Card(
                        color: kBackgroundColorDark,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(comment['pic']),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    "${comment['username']}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade500),
                                  ),
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
                          subtitle: (comment['uid'] == widget.onlineuser!.uid)
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
                                        );
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
                                      color: (comment['likes']
                                              .contains(widget.onlineuser!.uid))
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
                                              .contains(widget.onlineuser!.uid))
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

  /* Widget _commentBox2() {
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
    blockedByLatest.add(widget.onlineuser!.uid!);
    await commentsdb.child(c.path).update({
      'blockedBy': blockedByLatest,
    }).then((_) async => {
          await commentreportcollection
              .doc(generateRandomDocName(widget.onlineuser!.username!))
              .set({
            'type': 'livevideocomment',
            'status': 'reported', //reported -> deleted/noaction/pending
            'reporter': widget.onlineuser!.uid,
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

  Widget streamExitProgress() {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          CupertinoActivityIndicator(
            color: kDarkPrimaryColor,
          ),
          SizedBox(height: 8.0),
          Text("Loading...",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold)),
          Text("Exiting stream; Preparing to upload",
              style: TextStyle(
                color: Colors.white,
              ))
        ],
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
    if (blockedByLatest.contains(widget.onlineuser!.uid)) {
      blockedByLatest.remove(widget.onlineuser!.uid);
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
          (c.blockedBy.contains(widget.onlineuser!.uid))
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

  upvotePost(CommentModel c) async {
    var commentdocs = await commentsdb.child(c.path).get();

    final List<String> likes = ((commentdocs.value as Map)['likes'] != null)
        ? List.from((commentdocs.value as Map)['likes'])
        : [];
    final List<String> dislikes =
        ((commentdocs.value as Map)['dislikes'] != null)
            ? List.from((commentdocs.value as Map)['dislikes'])
            : [];
    if (likes.contains(widget.onlineuser!.uid)) {
      likes.remove(widget.onlineuser!.uid);
      await commentsdb.child(c.path).update({
        'likes': likes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else if (dislikes.contains(widget.onlineuser!.uid)) {
      dislikes.remove(widget.onlineuser!.uid);
      likes.add(widget.onlineuser!.uid!);
      await commentsdb.child(c.path).update({
        'dislikes': dislikes,
        'likes': likes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else {
      likes.add(widget.onlineuser!.uid!);
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
    if (dislikes.contains(widget.onlineuser!.uid)) {
      dislikes.remove(widget.onlineuser!.uid);
      await commentsdb.child(c.path).update({
        'dislikes': dislikes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else if (likes.contains(widget.onlineuser!.uid)) {
      likes.remove(widget.onlineuser!.uid);
      dislikes.add(widget.onlineuser!.uid!);
      await commentsdb.child(c.path).update({
        'likes': likes,
        'dislikes': dislikes,
      });
      setState(() {
        c.likes = likes;
        c.dislikes = dislikes;
      });
    } else {
      dislikes.add(widget.onlineuser!.uid!);
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
          whetherUpvoted: c.likes.contains(widget.onlineuser!.uid),
          whetherDownvoted: c.dislikes.contains(widget.onlineuser!.uid),
          onReply: null,
          onlineuid: widget.onlineuser!.uid!,
          comment: c,
          onUpvoted: () => upvotePost(c),
          onDownvoted: () => downvotePost(c),
        ),
        replyShowWidget(c),
      ],
    );
  }

  void replyComment(
      String parentCommentId, int parentIndentLevel, int repliesCount) async {
    final String commentContent = _commentController.text;
    _commentController.clear();
    setState(() {
      showPublishButton = false;
    });
    final String commentId =
        generateRandomDocName(widget.onlineuser!.username!);
    final time = DateTime.now();
    final timestamp = time.millisecondsSinceEpoch;

    await commentsdb
        .child(widget.docName!)
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
      'posterUid': widget.onlineuser!.uid,
      'posterUsername': widget.onlineuser!.username,
      'likes': [],
      'dislikes': [],
      'blockedBy': [],
      'repliesCount': 0,
      'path': '${widget.docName}/$parentCommentId/replies/$commentId',
      'indentLevel': (parentIndentLevel + 1),
    }).then((_) async =>
            getRepliesCount(parentCommentId).then((value) async => {
                  await commentsdb
                      .child(widget.docName!)
                      .child(parentCommentId)
                      .update({
                    'repliesCount': value + 1,
                  }).then((_) => {
                            contentcollection.doc(widget.docName).update({
                              'commentcount': FieldValue.increment(1),
                            }).then((value) => {
                                  FocusManager.instance.primaryFocus?.unfocus(),
                                })
                          })
                }));
  }

  Future<int> getRepliesCount(String parentCommentId) async {
    var commentdocs =
        await commentsdb.child(widget.docName!).child(parentCommentId).get();

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
    final String commentId =
        generateRandomDocName(widget.onlineuser!.username!);
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
      'posterUid': widget.onlineuser!.uid,
      'posterUsername': widget.onlineuser!.username,
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
  Widget build(BuildContext context) {
    // for participants
    return (updatedlive == false)
        ? const Scaffold(
            body: Center(
              child: CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              ),
            ),
          )
        : (Platform.isIOS)
            ? WillPopScope(
                //Removed ConditionalWillPopScope for iOS, but OK for Android
                onWillPop: () async => false,
                /*onWillPop: () {
              //when back button pressed
              showDialog(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text('Warning',
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold)),
                  content: Text(
                      (widget.formattype == 'QnA')
                          ? "Would you like to exit this QnA session?"
                          : (widget.formattype == 'Debate')
                              ? "Would you like to exit this debate?"
                              : "Would you like to exit this podcast?",
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: Colors.white70,
                            fontSize: 14.0,
                          )),
                  actions: [
                    TextButton(
                        onPressed: () => _onClickEnd(context),
                        child: Text('Yes')),
                    TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: Text('No'))
                  ],
                ),
              );

              return Future.value(false);
            },*/
                child: Scaffold(
                  //resizeToAvoidBottomInset: true,
                  resizeToAvoidBottomInset: false,
                  body: SafeArea(
                    child: Center(
                      child: (exitLoading == false)
                          ? (widget.formattype == "QnA")
                              ? (showcomments == false)
                                  ? Stack(
                                      //fit: StackFit.expand,
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
                                            //alignment: Alignment.topCenter,
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
                                            alignment: Alignment.bottomCenter,
                                            child: _toolbarforparticipants(),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0.0,
                                          top: 0.0,
                                          child: _liveUpdates(),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Stack(
                                          //when comments open for QnAs
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
                                                alignment: Alignment.topCenter,
                                                height: MediaQuery.of(context)
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
                                              child: _liveUpdates(),
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
                                            : Expanded(child: commentCardNew()),
                                        _commentBox(),
                                      ],
                                    )
                              : (showcomments == false && showchats == false)
                                  ? Stack(
                                      //for podcasts, debates without comments, chats
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if (showcomments == true ||
                                                showchats == true) {
                                              setState(() {
                                                showcomments = false;
                                                showchats = false;
                                              });
                                            }
                                          },
                                          child: Container(
                                            //alignment: Alignment.topCenter,
                                            height: MediaQuery.of(context)
                                                .size
                                                .height,
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            child: _viewMultipleRows(),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: _toolbarforparticipants(),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0.0,
                                          top: 0.0,
                                          child: _liveUpdates(),
                                        ),
                                      ],
                                    )
                                  : (showcomments == true && showchats == false)
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Stack(
                                              //when comments open for QnAs
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (showcomments == true ||
                                                        showchats == true) {
                                                      setState(() {
                                                        showcomments = false;
                                                        showchats = false;
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
                                                    child: _viewMultipleRows(),
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
                                                  child: _liveUpdates(),
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
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Stack(
                                              //when comments open for QnAs
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (showcomments == true ||
                                                        showchats == true) {
                                                      setState(() {
                                                        showcomments = false;
                                                        showchats = false;
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
                                                    child: _viewMultipleRows(),
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
                                                  child: _liveUpdates(),
                                                ),
                                              ],
                                            ),
                                            Expanded(
                                              child: _chatCard(),
                                            ),
                                          ],
                                        )
                          : (showexitdialog == false)
                              ? streamExitProgress()
                              : livestreamendeddialog('complete'),
                    ),
                  ),
                ),
              )
            : WillPopScope(
                onWillPop: () {
                  //when back button pressed
                  showDialog(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: Text('Warning',
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(
                                  color: Colors.white,
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold)),
                      content: Text(
                          (widget.formattype == 'QnA')
                              ? "Would you like to exit this QnA session?"
                              : (widget.formattype == 'Debate')
                                  ? "Would you like to exit this debate?"
                                  : "Would you like to exit this podcast?",
                          style:
                              Theme.of(context).textTheme.subtitle1!.copyWith(
                                    color: Colors.white70,
                                    fontSize: 14.0,
                                  )),
                      actions: [
                        TextButton(
                            onPressed: () {
                              Navigator.pop(c, true);
                              _onClickEnd(context);
                            },
                            child: const Text('Yes')),
                        TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('No'))
                      ],
                    ),
                  );

                  return Future.value(false);
                },
                child: Scaffold(
                  //resizeToAvoidBottomInset: true,
                  resizeToAvoidBottomInset: false,
                  body: SafeArea(
                    child: Center(
                      child: (exitLoading == false)
                          ? (widget.formattype == "QnA")
                              ? (showcomments == false)
                                  ? Stack(
                                      //fit: StackFit.expand,
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
                                            //alignment: Alignment.topCenter,
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
                                            alignment: Alignment.bottomCenter,
                                            child: _toolbarforparticipants(),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0.0,
                                          top: 0.0,
                                          child: _liveUpdates(),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Stack(
                                          //when comments open for QnAs
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
                                                alignment: Alignment.topCenter,
                                                height: MediaQuery.of(context)
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
                                              child: _liveUpdates(),
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
                                            : Expanded(child: commentCardNew()),
                                        _commentBox(),
                                      ],
                                    )
                              : (showcomments == false && showchats == false)
                                  ? Stack(
                                      //for podcasts, debates without comments, chats
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if (showcomments == true ||
                                                showchats == true) {
                                              setState(() {
                                                showcomments = false;
                                                showchats = false;
                                              });
                                            }
                                          },
                                          child: Container(
                                            //alignment: Alignment.topCenter,
                                            height: MediaQuery.of(context)
                                                .size
                                                .height,
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            child: _viewMultipleRows(),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: Align(
                                            alignment: Alignment.bottomCenter,
                                            child: _toolbarforparticipants(),
                                          ),
                                        ),
                                        Positioned(
                                          left: 0.0,
                                          top: 0.0,
                                          child: _liveUpdates(),
                                        ),
                                      ],
                                    )
                                  : (showcomments == true && showchats == false)
                                      ? Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Stack(
                                              //when comments open for QnAs
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (showcomments == true ||
                                                        showchats == true) {
                                                      setState(() {
                                                        showcomments = false;
                                                        showchats = false;
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
                                                    child: _viewMultipleRows(),
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
                                                  child: _liveUpdates(),
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
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Stack(
                                              //when comments open for QnAs
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (showcomments == true ||
                                                        showchats == true) {
                                                      setState(() {
                                                        showcomments = false;
                                                        showchats = false;
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
                                                    child: _viewMultipleRows(),
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
                                                  child: _liveUpdates(),
                                                ),
                                              ],
                                            ),
                                            Expanded(
                                              child: _chatCard(),
                                            ),
                                          ],
                                        )
                          : (showexitdialog == false)
                              ? streamExitProgress()
                              : livestreamendeddialog('complete'),
                    ),
                  ),
                ),
              );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if ((state == AppLifecycleState.paused) ||
        (state == AppLifecycleState.detached)) {
      setState(() {
        hidenav = false;
      });
      AppBuilder.of(context)!.rebuild();
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => SelectFormat()),
          (route) => false);
    }
  }
}
