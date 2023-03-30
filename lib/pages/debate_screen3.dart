import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/variables.dart';
import 'package:flutter/material.dart';
import 'package:challo/widgets/profile_widget.dart';
import 'package:challo/widgets/top_button.dart';
import 'package:challo/pages/selectformat.dart';
import 'dart:math';
import 'package:challo/models/content_info_model.dart';

class DebateScreen3 extends StatefulWidget {
  final UserInfoModel? onlineuser;
  final UserInfoModel? opponentuser;
  final ContentInfoModel? contentinfo;

  const DebateScreen3({
    required this.onlineuser,
    required this.opponentuser,
    required this.contentinfo,
  });
  @override
  State<DebateScreen3> createState() => _DebateScreen3State();
}

class _DebateScreen3State extends State<DebateScreen3> {
  String? docName;
  bool pendingvideo = false;
  dynamic time;
  bool channelcreated = false;
  bool channelupdated = false;
  RegExp exp = RegExp(r'[\s,;/.!:?({\[&)\]}]+');
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generatedocName() {
    String newdocName = (widget.onlineuser!.username! + getRandomString(5));
    return newdocName;
  }

  void _channelError() {
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

  List<String> stringtoList(String videoinfostring) {
    final List<String> infoinlist0 = videoinfostring.split(exp);
    final List<String> infoinlist =
        infoinlist0.map((email) => email.toLowerCase()).toList();
    infoinlist.removeWhere((value) => value == "");
    return (infoinlist);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: TopButton(
                text: 'Cancel',
                color: Colors.transparent,
                onPress: () {
                  setState(() {
                    hidenav = false;
                  });
                  AppBuilder.of(context)!.rebuild();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }),
          ),
          Padding(
            padding: const EdgeInsets.all(14.0),
            child: TopButton(
                text: 'Invite',
                color: kPrimaryColor,
                onPress: () async {
                  setState(() {
                    pendingvideo = true;
                  });
                  List<String> blockedby = [];
                  docName = generatedocName();
                  time = DateTime.now();
                  await usercollection.doc(widget.onlineuser!.uid).update({
                    'pendingvideo': pendingvideo,
                    'docName': docName,
                  });

                  var userdocs = await usercollection
                      .doc(widget.opponentuser!.uid)
                      .collection('requests')
                      .get();
                  int requestlength = userdocs.docs.length;

                  await usercollection
                      .doc(widget.opponentuser!.uid)
                      .collection('requests')
                      .doc('request $requestlength')
                      .set({
                    'docName': docName,
                    'type': 'Debate',
                    'guestsno': 1,
                    'uid0': widget.onlineuser!.uid,
                    'username0': widget.onlineuser!.username,
                    'pic0': widget.onlineuser!.pic,
                    'stand': (widget.onlineuser!.selectedRadioStand ==
                            'For the motion'
                        ? "Against the motion"
                        : "For the motion"),
                    'topic': widget.contentinfo!.subject,
                    'description': widget.contentinfo!.description,
                    'category': widget.contentinfo!.category,
                    'time': time,
                  });

                  await contentcollection.doc(docName).set({
                    'type': 'Debate',
                    'guestsno': 1,
                    'status': 'pending',
                    'docName': docName,
                    'whethercommunitypost': false,
                    'communityName': '',
                    'communitypic': '',
                    'topic': widget.contentinfo!.subject,
                    'topicinlist': stringtoList(widget.contentinfo!.subject!),
                    'description': widget.contentinfo!.description,
                    'descriptioninlist':
                        stringtoList(widget.contentinfo!.description!),
                    'category': widget.contentinfo!.category,
                    //'time': DateTime.now(),
                    'likes': [],
                    'dislikes': [],
                    'commentcount': 0,
                    'liveviews': [],
                    'totalviews': [],
                    'whostarted': widget.onlineuser!.uid,
                    'opusername': widget.onlineuser!.username,
                    'oppic': widget.onlineuser!.pic,
                    'requesteduids': [widget.opponentuser!.uid],
                    'accepteduids': [],
                    'declineduids': [],
                    'pendinguids': [widget.opponentuser!.uid],
                    //'precanceleduids': [],
                    //'postcanceleduids': [],
                    'participateduids': [],
                    'unexiteduids': [widget.onlineuser!.uid],
                    'link':
                        "$mergedBucketBaseUrl/$docName.mp4", // pre-generated AWS link where the video will be stored; for instance https://${bucket-name}.${region}.amazonaws.com/$docName.mp4
                    //'initiatorlive': false,
                    'portraitonly': false,
                    'blockedby': blockedby,
                    'whetherlive': false,
                    'topfeaturedpriority': 0,
                    'trendingpriority': 0,
                    'communitypostpriority': 0,
                  });

                  await contentcollection.doc(docName).get().then((value) => {
                        if (value.exists)
                          {
                            setState(() {
                              channelcreated = true;
                            })
                          }
                      });

                  if (channelcreated == true) {
                    await contentcollection
                        .doc(docName)
                        .collection('users')
                        .doc('user 0')
                        .set({
                      'uid': widget.onlineuser!.uid,
                      'username': widget.onlineuser!.username,
                      'name': widget.onlineuser!.name,
                      'email': widget.onlineuser!.email,
                      'pic': widget.onlineuser!.pic,
                      'stand': widget.onlineuser!.selectedRadioStand,
                    });
                    setState(() {
                      channelupdated = true;
                    });
                    if (channelupdated == true) {
                      setState(() {
                        hidenav = false;
                      });
                      if (!mounted) return;
                      AppBuilder.of(context)!.rebuild();
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                              builder: (context) => SelectFormat()),
                          (route) => false);
                    }
                  } else {
                    _channelError();
                  }
                }),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "Send Invite!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 16, right: 16, left: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ProfileWidget(
                          showverifiedtick: true,
                          profileverified: widget.onlineuser!.profileverified,
                          imageUrl: widget.onlineuser!.pic,
                          username: widget.onlineuser!.username,
                          variation: true,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text("vs.",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: ProfileWidget(
                          showverifiedtick: true,
                          profileverified: widget.opponentuser!.profileverified,
                          imageUrl: widget.opponentuser!.pic,
                          username: widget.opponentuser!.username,
                          variation: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 16, right: 16, left: 16),
                  child: Card(
                    color: kCardBackgroundColor,
                    child: Container(
                      alignment: Alignment.topLeft,
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...ListTile.divideTiles(
                            color: Colors.grey,
                            tiles: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                title: const Text(
                                  "Topic:",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(widget.contentinfo!.subject!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                              ListTile(
                                title: const Text("Description:",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18)),
                                subtitle: Text(widget.contentinfo!.description!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                              ListTile(
                                title: const Text("You're debating...",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18)),
                                subtitle: Text(
                                    widget.onlineuser!.selectedRadioStand!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                              ListTile(
                                title: const Text("Category:",
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 18)),
                                subtitle: Text(widget.contentinfo!.category!,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
