import 'package:challo/models/content_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/selectformat.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/top_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:challo/pages/participantpage.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:timeago/timeago.dart' as tago;
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:io' show Platform;

class PendingSession extends StatefulWidget {
  final UserInfoModel? onlineuser;
  final String? docName;
  final bool whethervideoprocessing;
  final String? whostarted;
  final int? guestsno;
  final ContentInfoModel? contentinfo;
  final dynamic time;
  final String opusername;
  final String oppic;
  //final String opponentuid, onlineselectedRadioStand, docName;
  //final bool didonlinestart, whetheraccepted;
  const PendingSession({
    required this.onlineuser,
    required this.docName,
    required this.whethervideoprocessing,
    this.whostarted,
    this.guestsno,
    this.contentinfo,
    this.time,
    required this.opusername,
    required this.oppic,
  });
  @override
  State<PendingSession> createState() => _PendingSessionState();
}

class _PendingSessionState extends State<PendingSession>
    with SingleTickerProviderStateMixin {
  final _chatMsgTextController = TextEditingController();

  bool dataisthere = false;

  bool videoprocessed = false;

  bool usersdataisthere = false;

  bool exitprocessing = false;

  bool canceledcompleted = false;

  bool acceptedUpdated = false;

  bool whethercanceled = false;

  bool showbottommsg = false;

  String errorHeading = '';
  String errorMessage = '';

  UserInfoModel? user0, user1, user2, user3;

  List<String> uidList = [];

  List<String> blockedby = [];

  int? guestsno;
  ContentInfoModel? contentinfo;

  String? whostarted,
      formattype,
      sessionstatus,
      videolink,
      camerastatus,
      micstatus;

  List<String> sessionupdates = [];

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateAlertDocString(String docName) {
    String newAlertDocString = ("alert$docName${getRandomString(3)}");
    return newAlertDocString;
  }

  bool showsendbutton = false;

  @override
  void initState() {
    super.initState();
    if (widget.whethervideoprocessing == false) {
      getinitialdata();
    } else {
      performProcessing();
    }
  }

  @override
  void dispose() {
    super.dispose();
    _chatMsgTextController.dispose();
  }

  clearChat() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _chatMsgTextController.clear());
  }

  getinitialdata() async {
    print("fetching initial data for PendingSession...");
    var channeldocs = await contentcollection.doc(widget.docName).get();
    print("Channel Name is ${widget.docName}");

    formattype = channeldocs['type'];

    guestsno = channeldocs['guestsno'];

    String? contentsubject = channeldocs['topic'];

    String? contentdescription = channeldocs['description'];

    String? contentcategory = channeldocs['category'];

    whostarted = channeldocs['whostarted'];

    sessionstatus = channeldocs['status'];

    videolink = channeldocs['link'];

    uidList = List.from(channeldocs['requesteduids']);

    contentinfo = ContentInfoModel(
        subject: contentsubject,
        description: contentdescription,
        category: contentcategory,
        formattype: formattype);

    var user0docs = await contentcollection
        .doc(widget.docName)
        .collection('users')
        .doc('user 0')
        .get();

    if (formattype == 'Debate') {
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
    } else if (formattype == 'Podcast') {
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
    } else {
      print("For QNA, no need for pending window");
    }

    setState(() {
      //initiatorUid = whostarted;
      dataisthere = true;
    });
    print("finished fetching initial data for PendingSession...");
  }

  performProcessing() async {
    if (widget.onlineuser!.uid == widget.whostarted) {
      print("Inside Processing Page; OP exited...");
      await contentcollection.doc(widget.docName).update(
        {
          'status': 'completed',
          'unexiteduids': FieldValue.arrayRemove([widget.onlineuser!.uid]),
        },
      );
      await usercollection
          .doc(widget.onlineuser!.uid)
          .collection('alerts001')
          .doc(generateAlertDocString(widget.docName!))
          .set({
        'text':
            'The complete livestream may take a while to show up on your profile.',
        'time': DateTime.now(),
        'type': widget.contentinfo!.formattype,
      });

      updateStatus();
    } else {
      print("Inside Processing Page; non-OP exited");
      await usercollection
          .doc(widget.onlineuser!.uid)
          .update({'isLive': false, 'pendingvideo': false});
      await contentcollection.doc(widget.docName).update({
        'unexiteduids': FieldValue.arrayRemove([widget.onlineuser!.uid])
      });
      await usercollection
          .doc(widget.onlineuser!.uid)
          .collection('alerts001')
          .doc(generateAlertDocString(widget.docName!))
          .set({
        'text':
            'The complete livestream will be listed on your profile shortly after the initiator exits the streaming session',
        'time': DateTime.now(),
        'type': widget.contentinfo!.formattype,
      });
    }
    setState(() {
      videoprocessed = true;
    });
  }

  updateStatus() async {
    var channeldocs = await contentcollection.doc(widget.docName).get();
    List<String> accepteduids,
        participatedpics,
        participateduids,
        nonparticipateduids,
        participatedusernames = [];

    blockedby = List.from(channeldocs['blockedby']);
    final bool portraitonly = channeldocs['portraitonly'];

    accepteduids = List.from(channeldocs['accepteduids']);
    for (String i in accepteduids) {
      print("accepteduids are $i'");
    }
    participateduids = List.from(channeldocs['participateduids']);
    for (String i in participateduids) {
      print("participateduids uids are $i'");
    }
    participatedpics = List.from(channeldocs['participatedpics']);
    for (String i in participatedpics) {
      print("participatedpics are $i'");
    }
    nonparticipateduids =
        accepteduids.toSet().difference(participateduids.toSet()).toList();
    for (String i in nonparticipateduids) {
      print("nonparticipantsuids uids are $i'");
    }
    participatedusernames = List.from(channeldocs['participatedusernames']);
    if (participateduids.isNotEmpty) {
      for (String uid in participateduids) {
        await usercollection.doc(uid).update({
          'pendingvideo': false,
          'isLive': false,
        });
      }
    }
    if (nonparticipateduids.isNotEmpty) {
      for (String uid in nonparticipateduids) {
        await usercollection.doc(uid).update({
          'pendingvideo': false,
        });
      }
    }

    final String apiUrl = transcodingAPIURL; // Video transcoding API
    final transcoderesponse =
        await http.get(Uri.parse('$apiUrl/${widget.docName}'));
    if (transcoderesponse.statusCode == 200) {
      print("transcoding success");
      await contentcollection
          .doc(widget.docName)
          .update({'status': 'published'});
      if (participatedpics.length == 1) {
        print("Inside listvideo function with participant number == 1");
        /* var user0docs = await usercollection
            .doc(participateduids[0])
            .collection('content')
            .get();

        int videolength0 = user0docs.docs.length;*/

        await usercollection
            .doc(participateduids[0])
            .collection('content')
            .doc(widget.docName)
            .set({
          'opusername': widget.opusername,
          'oppic': widget.oppic,
          'participateduids': participateduids,
          'participatedpics': participatedpics,
          'participatedusernames': participatedusernames,
          'type': widget.contentinfo!.formattype,
          'topic': widget.contentinfo!.subject,
          'description': widget.contentinfo!.description,
          'category': widget.contentinfo!.category,
          'time': widget.time,
          'docName': widget.docName,
          'link':
              '', // AWS link where the video will be stored; for instance https://${bucket-name}.${region}.amazonaws.com/${widget.docName}.mp4
          'blockedby': blockedby,
          'portraitonly': portraitonly,
          'whostarted': widget.whostarted,
          'whethercommunitypost': false,
          'communityName': '',
          'communitypic': '',
        });
      } else if (participatedpics.length == 2) {
        print("Inside listvideo function with guestsno == 2");
        /*var user0docs = await usercollection
            .doc(participateduids[0])
            .collection('content')
            .get();

        int videolength0 = user0docs.docs.length;*/

        await usercollection
            .doc(participateduids[0])
            .collection('content')
            .doc(widget.docName)
            .set({
          'opusername': widget.opusername,
          'oppic': widget.oppic,
          'participateduids': participateduids,
          'participatedpics': participatedpics,
          'participatedusernames': participatedusernames,
          'type': widget.contentinfo!.formattype,
          'topic': widget.contentinfo!.subject,
          'description': widget.contentinfo!.description,
          'category': widget.contentinfo!.category,
          'time': widget.time,
          'docName': widget.docName,
          'link':
              '', // AWS link where the video will be stored; for instance https://${bucket-name}.${region}.amazonaws.com/${widget.docName}.mp4
          'blockedby': blockedby,
          'portraitonly': portraitonly,
          'whostarted': widget.whostarted,
          'whethercommunitypost': false,
          'communityName': '',
          'communitypic': '',
        });

        /*var user1docs = await usercollection
            .doc(participateduids[1])
            .collection('content')
            .get();

        int videolength1 = user1docs.docs.length;*/

        await usercollection
            .doc(participateduids[1])
            .collection('content')
            .doc(widget.docName)
            .set({
          'opusername': widget.opusername,
          'oppic': widget.oppic,
          'participateduids': participateduids,
          'participatedpics': participatedpics,
          'participatedusernames': participatedusernames,
          'type': widget.contentinfo!.formattype,
          'topic': widget.contentinfo!.subject,
          'description': widget.contentinfo!.description,
          'category': widget.contentinfo!.category,
          'time': widget.time,
          'docName': widget.docName,
          'link':
              '', // AWS link where the video will be stored; for instance https://${bucket-name}.${region}.amazonaws.com/${widget.docName}.mp4
          'blockedby': blockedby,
          'portraitonly': portraitonly,
          'whostarted': widget.whostarted,
          'whethercommunitypost': false,
          'communityName': '',
          'communitypic': '',
        });
      } else if (participatedpics.length == 3) {
        print("Inside listvideo function with guestsno == 3");
        /*var user0docs = await usercollection
            .doc(participateduids[0])
            .collection('content')
            .get();

        int videolength0 = user0docs.docs.length;*/

        await usercollection
            .doc(participateduids[0])
            .collection('content')
            .doc(widget.docName)
            .set({
          'opusername': widget.opusername,
          'oppic': widget.oppic,
          'participateduids': participateduids,
          'participatedpics': participatedpics,
          'participatedusernames': participatedusernames,
          'type': widget.contentinfo!.formattype,
          'topic': widget.contentinfo!.subject,
          'description': widget.contentinfo!.description,
          'category': widget.contentinfo!.category,
          'time': widget.time,
          'docName': widget.docName,
          'link':
              '', // AWS link where the video will be stored; for instance https://${bucket-name}.${region}.amazonaws.com/${widget.docName}.mp4
          'blockedby': blockedby,
          'portraitonly': portraitonly,
          'whostarted': widget.whostarted,
          'whethercommunitypost': false,
          'communityName': '',
          'communitypic': '',
        });

        /*var user1docs = await usercollection
            .doc(participateduids[1])
            .collection('content')
            .get();

        int videolength1 = user1docs.docs.length;*/

        await usercollection
            .doc(participateduids[1])
            .collection('content')
            .doc(widget.docName)
            .set({
          'opusername': widget.opusername,
          'oppic': widget.oppic,
          'participateduids': participateduids,
          'participatedpics': participatedpics,
          'participatedusernames': participatedusernames,
          'type': widget.contentinfo!.formattype,
          'topic': widget.contentinfo!.subject,
          'description': widget.contentinfo!.description,
          'category': widget.contentinfo!.category,
          'time': widget.time,
          'docName': widget.docName,
          'link':
              '', // AWS link where the video will be stored; for instance https://${bucket-name}.${region}.amazonaws.com/${widget.docName}.mp4
          'blockedby': blockedby,
          'portraitonly': portraitonly,
          'whostarted': widget.whostarted,
          'whethercommunitypost': false,
          'communityName': '',
          'communitypic': '',
        });

        /*var user2docs = await usercollection
            .doc(participateduids[2])
            .collection('content')
            .get();

        int videolength2 = user2docs.docs.length;*/

        await usercollection
            .doc(participateduids[2])
            .collection('content')
            .doc(widget.docName)
            .set({
          'opusername': widget.opusername,
          'oppic': widget.oppic,
          'participateduids': participateduids,
          'participatedpics': participatedpics,
          'participatedusernames': participatedusernames,
          'type': widget.contentinfo!.formattype,
          'topic': widget.contentinfo!.subject,
          'description': widget.contentinfo!.description,
          'category': widget.contentinfo!.category,
          'time': widget.time,
          'docName': widget.docName,
          'link':
              '', // AWS link where the video will be stored; for instance https://${bucket-name}.${region}.amazonaws.com/${widget.docName}.mp4
          'blockedby': blockedby,
          'portraitonly': portraitonly,
          'whostarted': widget.whostarted,
          'whethercommunitypost': false,
          'communityName': '',
          'communitypic': '',
        });
      }
    } else {
      //show error dialog
      print("transcoding failed");
    }
  }

  /*void _onClickComplete(BuildContext context) async {
    if (widget.onlineuser.uid == whostarted) {
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

  void _showPermissionDenied(String status) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text("Permission Error"),
        content: Text(
          (status == 'permanentlydenied')
              ? "Allow camera and mic access in Settings to enter a live session."
              : "Allow camera and mic access to enter a live session.",
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Close"),
            textStyle: Theme.of(context).textTheme.button!.copyWith(
                  color: kPrimaryColorTint2,
                  fontSize: 15.0,
                ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> onCreate() async {
    await _handleCamera(Permission.camera);
    await _handleMic(Permission.microphone);
    // push video page with given channel name

    if (camerastatus == 'granted' && micstatus == 'granted') {
      if (guestsno == 0) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParticipantPage(
              oppic: widget.oppic,
              opusername: widget.opusername,
              guestsno: guestsno,
              user0: user0,
              whostarted: whostarted,
              docName: widget.docName,
              formattype: "QnA",
              role: ClientRole.Broadcaster,
              onlineuser: widget.onlineuser,
              contentinfo: contentinfo,
            ),
            fullscreenDialog: true,
          ),
        );
      } else if (guestsno == 1) {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParticipantPage(
              oppic: widget.oppic,
              opusername: widget.opusername,
              guestsno: guestsno,
              user0: user0,
              user1: user1,
              whostarted: whostarted,
              docName: widget.docName,
              formattype: (formattype == 'Debate') ? "Debate" : "Podcast",
              role: ClientRole.Broadcaster,
              onlineuser: widget.onlineuser,
              contentinfo: contentinfo,
            ),
            fullscreenDialog: true,
          ),
        );
      } else {
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ParticipantPage(
              oppic: widget.oppic,
              opusername: widget.opusername,
              guestsno: guestsno,
              user0: user0,
              user1: user1,
              user2: user2,
              whostarted: whostarted,
              docName: widget.docName,
              formattype: (formattype == 'Debate') ? "Debate" : "Podcast",
              role: ClientRole.Broadcaster,
              onlineuser: widget.onlineuser,
              contentinfo: contentinfo,
            ),
            fullscreenDialog: true,
          ),
        );
      }
    } else if (camerastatus == 'permanentlydenied' ||
        micstatus == 'permanentlydenied') {
      _showPermissionDenied('permanentlydenied');
    } else {
      _showPermissionDenied('denied');
    }
  }

  Future<void> _handleCamera(Permission permission) async {
    final status = await permission.request();
    if (status == PermissionStatus.granted) {
      setState(() {
        camerastatus = 'granted';
      });
    } else if (status == PermissionStatus.permanentlyDenied) {
      setState(() {
        camerastatus = 'permanentlydenied';
      });
    } else {
      setState(() {
        camerastatus = 'denied';
      });
    }
  }

  Future<void> _handleMic(Permission permission) async {
    final status = await permission.request();
    if (status == PermissionStatus.granted) {
      setState(() {
        micstatus = 'granted';
      });
    } else if (status == PermissionStatus.permanentlyDenied) {
      setState(() {
        micstatus = 'permanentlydenied';
      });
    } else {
      setState(() {
        micstatus = 'denied';
      });
    }
  }

  messageAlert(String heading, String message, String buttonText) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(heading,
                style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    color: Colors.white,
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold)),
            content: Text(message,
                style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      color: Colors.white70,
                      fontSize: 14.0,
                    )),
            actions: <Widget>[
              // usually buttons at the bottom of the dialog
              new TextButton(
                //highlightColor: Colors.white,
                child: new Text(buttonText,
                    style: const TextStyle(color: kPrimaryColor)),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }

  Widget goLiveWidget() {
    return (widget.onlineuser!.uid == whostarted)
        ? Padding(
            padding: const EdgeInsets.all(14.0),
            child: TopButton(
                text: "Go Live", color: kPrimaryColor, onPress: onCreate),
          )
        : StreamBuilder<QuerySnapshot>(
            stream: contentcollection
                .where('docName', isEqualTo: widget.docName)
                .snapshots(),
            builder: (context, AsyncSnapshot snapshot) {
              if (!snapshot.hasData) {
                print("getting info");
                return Container();
              }
              if (snapshot.data.docs.length == 0) {
                return Container();
              }

              var postdocs = snapshot.data.docs[0];
              String? poststatus = postdocs['status'];
              if (poststatus == 'accepted') {
                return Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: TopButton(
                      text: "Go Live",
                      color: Colors.grey,
                      onPress: () => messageAlert(
                          'Loading...',
                          'The initiator has to go live first for you to join. Loading for the button to turn blue.',
                          'Okay')),
                );
              } else if (poststatus == 'started') {
                return Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: TopButton(
                      text: "Go Live", color: kPrimaryColor, onPress: onCreate),
                );
              } else if (poststatus == 'initiatorcanceled') {
                if (whethercanceled == false) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      whethercanceled = true;
                      errorHeading = 'Stream canceled...';
                      errorMessage =
                          'Initiator has left the livestream session, and so it has been canceled.';
                      showbottommsg = true;
                    });
                  });
                }

                return Container();
              } else if (poststatus == 'guestscanceled') {
                if (whethercanceled == false) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      whethercanceled = true;
                      errorHeading = 'Stream canceled...';
                      errorMessage =
                          'None of the invited guests have joined the livestream session, and so it has been canceled.';
                      showbottommsg = true;
                    });
                  });
                }

                return Container();
              } else if (poststatus == 'completed') {
                if (whethercanceled == false) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      whethercanceled = true;
                      errorHeading = 'Streaming completed...';
                      errorMessage =
                          'Initiator has ended the livestream session.';
                      showbottommsg = true;
                    });
                  });
                }

                return Container();
              } else {
                return Container();
              }
            });
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
          controller: _chatMsgTextController,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            suffixIcon: (showsendbutton == false)
                ? null
                : Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: InkWell(
                      onTap: () => publishchat(),
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
      //color: Colors.grey.shade500,
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
                controller: _chatMsgTextController,
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
              onPressed: publishchat,
              child: const Icon(
                Icons.send,
                color: kPrimaryColor,
                size: 20.0,
              ),
              shape: const CircleBorder(),
              elevation: 2.0,
              color: Colors.grey.shade400,
              padding: const EdgeInsets.all(8.0),
            ),
          ),
        ],
      ),
    );
  }*/

  void publishchat() async {
    final String messageContent = _chatMsgTextController.text;
    _chatMsgTextController.clear();
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

  Widget _allMessages() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
          //color: Colors.white,
          child: StreamBuilder<QuerySnapshot>(
              stream: contentcollection
                  .doc(widget.docName)
                  .collection('chats')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CupertinoActivityIndicator(
                    color: kDarkPrimaryColor,
                  ));
                }
                if (snapshot.data.docs.length == 0) {
                  return const Center(
                    child: Text('Send the first message.',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        )),
                  );
                }
                return ListView.builder(
                    shrinkWrap: true,
                    reverse: true,
                    physics: const ScrollPhysics(),
                    scrollDirection: Axis.vertical,
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
                                      color: Colors.grey.shade500,
                                    ),
                              ),
                              const SizedBox(width: 5.0),
                              Text(
                                "• ${tago.format(chat['time'].toDate())} •",
                                style: Theme.of(context)
                                    .textTheme
                                    .caption!
                                    .copyWith(
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
                    });
              })),
    );
  }

  Widget fullChatWidget() {
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
                    'Private Chats',
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          color: kSubTextColor,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.24,
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
                        messageAlert(
                            'Why use Private Chat?',
                            'Livestream participants can use the Private Chat feature to decide on the time, duration, topics, etc. prior to going live. Messages in Private Chat are not visible to the audience.',
                            'Okay');
                      },
                      child: const Icon(
                        Icons.info,
                        size: 25,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ]),
          ),
          Expanded(child: _allMessages()),
          _chatBoxNew(),
        ],
      ),
    );
  }

  /* Widget disposedStreamBuilder<QuerySnapshot>() {
    return StreamBuilder<QuerySnapshot>(
        stream: contentcollection.doc(widget.docName).snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CupertinoActivityIndicator(
                  color: kDarkPrimaryColor,
                ));
          }
          var liveData = snapshot.data;
          WidgetsBinding.instance!.addPostFrameCallback((_) async {
            setState(() {
              guestsno = liveData['guestsno'];
            });
            if (liveData['status'] == 'accepted' ||
                liveData['status'] == 'started') {
              setState(() {
                sessionstatus = liveData['status'];
              });
            }

            if ((liveData['status'] == 'completed') &&
                ((formattype == 'Debate') || (formattype == 'Podcast'))) {
              print("Debate/Podcast is completed");
              setState(() {
                exitprocessing = true;
              });
              if ((liveData['unexiteduids'].contains(widget.onlineuser.uid)) &&
                  (widget.onlineuser.uid != whostarted)) {
                //livestreamendeddialog('completed', 'Streaming has finished');
                await contentcollection.doc(widget.docName).update({
                  'unexiteduids':
                      FieldValue.arrayRemove([widget.onlineuser.uid])
                });
                await usercollection
                    .doc(widget.onlineuser.uid)
                    .update({'pendingvideo': false});
              }
              Future.delayed(Duration(milliseconds: 5000), () {
                setState(() {
                  canceledcompleted = true;
                });
              });
            } else if ((liveData['status'] == 'initiatorcanceled') ||
                (liveData['status'] == 'guestscanceled')) {
              print("Stream status canceled because ${liveData['status']}");
              setState(() {
                exitprocessing = true;
              });
              Future.delayed(Duration(milliseconds: 5000), () {
                setState(() {
                  canceledcompleted = true;
                });
              });
            }
          });
          return (dataisthere == false)
              ? Scaffold(
                  body: Center(
                    child: CupertinoActivityIndicator(
                  color: kDarkPrimaryColor,
                ),
                  ),
                )
              : (sessionstatus == 'pending')
                  ? Scaffold(
                      appBar: AppBar(
                        title: Text((formattype == 'Debate')
                            ? "Debate Hall"
                            : "Podcast Studio"),
                        centerTitle: true,
                      ),
                      body: SafeArea(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics()),
                            child: (exitprocessing == false)
                                ? Container() //this was where notaccepted thingy existed
                                : livestreamendeddialog(),
                          ),
                        ),
                      ),
                    )
                  : (usersdataisthere == false)
                      ? Scaffold(
                          body: Center(
                            child: CupertinoActivityIndicator(
                  color: kDarkPrimaryColor,
                ),
                          ),
                        )
                      : Scaffold(
                          appBar: AppBar(
                            title: Text((formattype == 'Debate')
                                ? "Debate Hall"
                                : "Podcast Studio"),
                            centerTitle: true,
                            bottom: TabBar(
                              indicatorColor: kPrimaryColor,
                              unselectedLabelColor: Colors.grey.shade500,
                              labelColor: Colors.white,
                              indicatorWeight: 3.0,
                              indicatorSize: TabBarIndicatorSize.tab,
                              tabs: [
                                Tab(
                                  text: "Chat",
                                  icon: Icon(Icons.chat_outlined),
                                ),
                                Tab(
                                  text: "Info",
                                  icon: Icon(Icons.info_outlined),
                                ),
                              ],
                            ),
                            actions: [
                              goLiveWidget(),
                            ],
                          ),
                          body: SafeArea(
                              child: (exitprocessing == false)
                                  ? TabBarView(
                                      children: [
                                        RoomChat(
                                          docName: widget.docName,
                                          onlineuser: widget.onlineuser,
                                        ),
                                        Column(
                                          children: [
                                            (formattype == 'Debate')
                                                ? (widget.onlineuser.uid ==
                                                        whostarted)
                                                    ? ContentInfoWidget(
                                                        formattype: 'Debate',
                                                        user0: user0,
                                                        user1: user1,
                                                        contentinfo:
                                                            contentinfo,
                                                      )
                                                    : ContentInfoWidget(
                                                        formattype: 'Debate',
                                                        user0: user1,
                                                        user1: user0,
                                                        contentinfo:
                                                            contentinfo,
                                                      )
                                                : (guestsno == 1)
                                                    ? PodcastInfoWidget(
                                                        guestsno: guestsno,
                                                        user0: user0,
                                                        user1: user1,
                                                        contentinfo:
                                                            contentinfo,
                                                      )
                                                    : PodcastInfoWidget(
                                                        guestsno: guestsno,
                                                        user0: user0,
                                                        user1: user1,
                                                        user2: user2,
                                                        contentinfo:
                                                            contentinfo,
                                                      )
                                          ],
                                        ),
                                      ],
                                    )
                                  : (canceledcompleted = false)
                                      ? Center(
                                          child: CupertinoActivityIndicator(
                  color: kDarkPrimaryColor,
                ),
                                        )
                                      : livestreamendeddialog()),
                        );
        });
  }*/

  Widget bottomSheetMessage() {
    return Container(
      height: (MediaQuery.of(context).size.height) / 5,
      width: (MediaQuery.of(context).size.width),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              errorHeading,
              style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: Text(
              errorMessage,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    hidenav = false;
                  });
                  AppBuilder.of(context)!.rebuild();
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => SelectFormat()),
                      (route) => false);
                },
                child: Text("Okay",
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        color: kPrimaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return (widget.whethervideoprocessing == false)
        ? (dataisthere == false)
            ? (Platform.isIOS)
                ? WillPopScope(
                    onWillPop: () async => false,
                    child: Scaffold(
                      resizeToAvoidBottomInset: false,
                      appBar: AppBar(
                        leading: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: kPrimaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              hidenav = false;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.of(context).pop();
                            // return Future.value(false);
                          },
                        ),
                        title: Text((formattype == 'Debate')
                            ? "Debate Hall"
                            : "Podcast Studio"),
                        centerTitle: true,
                      ),
                      body: const SafeArea(
                        child: Center(
                          child: CupertinoActivityIndicator(
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                  )
                : WillPopScope(
                    onWillPop: () {
                      setState(() {
                        hidenav = false;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.of(context).pop();
                      return Future.value(false);
                    },
                    child: Scaffold(
                      resizeToAvoidBottomInset: false,
                      appBar: AppBar(
                        leading: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: kPrimaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              hidenav = false;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.of(context).pop();
                            // return Future.value(false);
                          },
                        ),
                        title: Text((formattype == 'Debate')
                            ? "Debate Hall"
                            : "Podcast Studio"),
                        centerTitle: true,
                      ),
                      body: const SafeArea(
                        child: Center(
                          child: CupertinoActivityIndicator(
                            color: kPrimaryColor,
                          ),
                        ),
                      ),
                    ),
                  )
            : (Platform.isIOS)
                ? WillPopScope(
                    onWillPop: () async => false,
                    child: Scaffold(
                      bottomSheet: (showbottommsg == false)
                          ? null
                          : bottomSheetMessage(),
                      resizeToAvoidBottomInset: false,
                      appBar: AppBar(
                        leading: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: kPrimaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              hidenav = false;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.of(context).pop();
                          },
                        ),
                        title: Text((formattype == 'Debate')
                            ? "Debate Hall"
                            : "Podcast Studio"),
                        centerTitle: true,
                        actions: [
                          goLiveWidget(),
                        ],
                      ),
                      body: SafeArea(
                        child: fullChatWidget(),
                      ),
                    ),
                  )
                : WillPopScope(
                    onWillPop: () {
                      setState(() {
                        hidenav = false;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.of(context).pop();
                      return Future.value(false);
                    },
                    child: Scaffold(
                      bottomSheet: (showbottommsg == false)
                          ? null
                          : bottomSheetMessage(),
                      resizeToAvoidBottomInset: false,
                      appBar: AppBar(
                        leading: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: kPrimaryColor,
                          ),
                          onPressed: () {
                            setState(() {
                              hidenav = false;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.of(context).pop();
                          },
                        ),
                        title: Text((formattype == 'Debate')
                            ? "Debate Hall"
                            : "Podcast Studio"),
                        centerTitle: true,
                        actions: [
                          goLiveWidget(),
                        ],
                      ),
                      body: SafeArea(
                        child: fullChatWidget(),
                      ),
                    ),
                  )
        : (videoprocessed == false)
            ? (Platform.isIOS)
                ? WillPopScope(
                    //Removed ConditionalWillPopScope for iOS, but Ok for Android
                    //video processing
                    onWillPop: () async => false,
                    child: Scaffold(
                      resizeToAvoidBottomInset: false,
                      body: SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CupertinoActivityIndicator(
                                color: kPrimaryColor,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text("Loading...",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        )),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text("Uploading livestream...",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                            color: Colors.white, fontSize: 15)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : WillPopScope(
                    onWillPop: () {
                      showDialog(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: Text('Just a moment...',
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                          content: Text(
                              "Loading a few seconds while we finish processing the livestream.",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                    color: Colors.white70,
                                    fontSize: 14.0,
                                  )),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(c, false),
                                child: const Text('Okay',
                                    style: TextStyle(color: kPrimaryColor))),
                          ],
                        ),
                      );
                      return Future.value(false);
                    },
                    child: Scaffold(
                      resizeToAvoidBottomInset: false,
                      body: SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CupertinoActivityIndicator(
                                color: kPrimaryColor,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text("Loading...",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        )),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text("Uploading livestream...",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                            color: Colors.white, fontSize: 15)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
            : (Platform.isIOS)
                ? WillPopScope(
                    //Removed ConditionalWillPopScope for iOS, but OK for Android
                    onWillPop: () async => false,
                    child: Scaffold(
                      resizeToAvoidBottomInset: false,
                      body: SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: kPrimaryColor,
                                size: 30,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text("Upload successful.",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize: 15,
                                          //fontWeight: FontWeight.bold,
                                        )),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      hidenav = false;
                                    });
                                    AppBuilder.of(context)!.rebuild();
                                    Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                SelectFormat()),
                                        (route) => false);
                                  },
                                  child: Text("Return to Main Menu",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                            color: kPrimaryColorTint2,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          )),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                : WillPopScope(
                    onWillPop: () {
                      setState(() {
                        hidenav = false;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => SelectFormat()),
                          (route) => false);
                      return Future.value(false);
                    },
                    child: Scaffold(
                      resizeToAvoidBottomInset: false,
                      body: SafeArea(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                color: kPrimaryColor,
                                size: 30,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: Text("Upload successful.",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize: 15,
                                          //fontWeight: FontWeight.bold,
                                        )),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(5.0),
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      hidenav = false;
                                    });
                                    AppBuilder.of(context)!.rebuild();
                                    Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                SelectFormat()),
                                        (route) => false);
                                  },
                                  child: Text("Return to Main Menu",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                            color: kPrimaryColorTint2,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          )),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
  }
}
