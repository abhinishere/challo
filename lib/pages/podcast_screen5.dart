import 'package:challo/models/content_info_model.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/variables.dart';
import 'package:flutter/material.dart';
import 'package:challo/widgets/profile_widget.dart';
import 'package:challo/widgets/top_button.dart';
import 'package:challo/pages/selectformat.dart';
import 'dart:math';

class PodcastScreen5 extends StatefulWidget {
  final UserInfoModel? onlineuser, guest1, guest2, guest3;
  final ContentInfoModel? contentinfo;
  final int? guestsno;

  const PodcastScreen5(
      {required this.onlineuser,
      required this.guest1,
      this.guest2,
      this.guest3,
      required this.contentinfo,
      required this.guestsno});
  @override
  State<PodcastScreen5> createState() => _PodcastScreen5State();
}

class _PodcastScreen5State extends State<PodcastScreen5> {
  String? docName;
  bool pendingvideo = false;
  dynamic time;
  bool channelcreated = false;
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

  /*void updateChannel() async {
    var channeldocs =
        await contentcollection.doc(docName).collection('users').get();

    int userlength = channeldocs.docs.length;

    await contentcollection
        .doc(docName)
        .collection('users')
        .doc('user $userlength')
        .set({
      'uid': widget.onlineuser.uid,
      'username': widget.onlineuser.username,
      'name': widget.onlineuser.name,
      'email': widget.onlineuser.email,
      'pic': widget.onlineuser.pic
    });

    if (widget.guestsno == 1) {
      await contentcollection
          .doc(docName)
          .collection('users')
          .doc('user ${userlength + 1}')
          .set({
        'uid': widget.guest1.uid,
        'username': widget.guest1.username,
        'name': widget.guest1.name,
        'email': widget.guest1.email,
        'pic': widget.guest1.pic
      });
    } else if (widget.guestsno == 2) {
      await contentcollection
          .doc(docName)
          .collection('users')
          .doc('user ${userlength + 1}')
          .set({
        'uid': widget.guest1.uid,
        'username': widget.guest1.username,
        'name': widget.guest1.name,
        'email': widget.guest1.email,
        'pic': widget.guest1.pic
      });

      await contentcollection
          .doc(docName)
          .collection('users')
          .doc('user ${userlength + 2}')
          .set({
        'uid': widget.guest2.uid,
        'username': widget.guest2.username,
        'name': widget.guest2.name,
        'email': widget.guest2.email,
        'pic': widget.guest2.pic
      });
    } else {
      await contentcollection
          .doc(docName)
          .collection('users')
          .doc('user ${userlength + 1}')
          .set({
        'uid': widget.guest1.uid,
        'username': widget.guest1.username,
        'name': widget.guest1.name,
        'email': widget.guest1.email,
        'pic': widget.guest1.pic
      });

      await contentcollection
          .doc(docName)
          .collection('users')
          .doc('user ${userlength + 2}')
          .set({
        'uid': widget.guest2.uid,
        'username': widget.guest2.username,
        'name': widget.guest2.name,
        'email': widget.guest2.email,
        'pic': widget.guest2.pic
      });

      await contentcollection
          .doc(docName)
          .collection('users')
          .doc('user ${userlength + 3}')
          .set({
        'uid': widget.guest3.uid,
        'username': widget.guest3.username,
        'name': widget.guest3.name,
        'email': widget.guest3.email,
        'pic': widget.guest3.pic
      });
    }
  }

  */

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

                  if (widget.guestsno == 1) {
                    var guest1docs = await usercollection
                        .doc(widget.guest1!.uid)
                        .collection('requests')
                        .get();
                    int requestlength = guest1docs.docs.length;

                    await usercollection
                        .doc(widget.guest1!.uid)
                        .collection('requests')
                        .doc('request $requestlength')
                        .set({
                      'docName': docName,
                      'type': 'Podcast',
                      'guestsno': widget.guestsno,
                      'uid0': widget.onlineuser!.uid,
                      'username0': widget.onlineuser!.username,
                      'pic0': widget.onlineuser!.pic,
                      'uid1': widget.guest1!.uid,
                      'username1': widget.guest1!.username,
                      'pic1': widget.guest1!.pic,
                      'topic': widget.contentinfo!.subject,
                      'description': widget.contentinfo!.description,
                      'category': widget.contentinfo!.category,
                      'time': time,
                    });
                  } else if (widget.guestsno == 2) {
                    var guest1docs = await usercollection
                        .doc(widget.guest1!.uid)
                        .collection('requests')
                        .get();
                    int requestlength = guest1docs.docs.length;

                    await usercollection
                        .doc(widget.guest1!.uid)
                        .collection('requests')
                        .doc('request $requestlength')
                        .set({
                      'docName': docName,
                      'type': 'Podcast',
                      'guestsno': widget.guestsno,
                      'uid0': widget.onlineuser!.uid,
                      'username0': widget.onlineuser!.username,
                      'pic0': widget.onlineuser!.pic,
                      'uid1': widget.guest1!.uid,
                      'username1': widget.guest1!.username,
                      'pic1': widget.guest1!.pic,
                      'uid2': widget.guest2!.uid,
                      'username2': widget.guest2!.username,
                      'pic2': widget.guest2!.pic,
                      'topic': widget.contentinfo!.subject,
                      'description': widget.contentinfo!.description,
                      'category': widget.contentinfo!.category,
                      'time': time,
                    });

                    var guest2docs = await usercollection
                        .doc(widget.guest2!.uid)
                        .collection('requests')
                        .get();
                    int requestlength2 = guest2docs.docs.length;

                    await usercollection
                        .doc(widget.guest2!.uid)
                        .collection('requests')
                        .doc('request $requestlength2')
                        .set({
                      'docName': docName,
                      'type': 'Podcast',
                      'guestsno': widget.guestsno,
                      'uid0': widget.onlineuser!.uid,
                      'username0': widget.onlineuser!.username,
                      'pic0': widget.onlineuser!.pic,
                      'uid1': widget.guest1!.uid,
                      'username1': widget.guest1!.username,
                      'pic1': widget.guest1!.pic,
                      'uid2': widget.guest2!.uid,
                      'username2': widget.guest2!.username,
                      'pic2': widget.guest2!.pic,
                      'topic': widget.contentinfo!.subject,
                      'description': widget.contentinfo!.description,
                      'category': widget.contentinfo!.category,
                      'time': time,
                    });
                  } else {
                    var guest1docs = await usercollection
                        .doc(widget.guest1!.uid)
                        .collection('requests')
                        .get();
                    int requestlength = guest1docs.docs.length;

                    await usercollection
                        .doc(widget.guest1!.uid)
                        .collection('requests')
                        .doc('request $requestlength')
                        .set({
                      'docName': docName,
                      'type': 'Podcast',
                      'guestsno': widget.guestsno,
                      'uid0': widget.onlineuser!.uid,
                      'username0': widget.onlineuser!.username,
                      'pic0': widget.onlineuser!.pic,
                      'uid1': widget.guest1!.uid,
                      'username1': widget.guest1!.username,
                      'pic1': widget.guest1!.pic,
                      'uid2': widget.guest2!.uid,
                      'username2': widget.guest2!.username,
                      'pic2': widget.guest2!.pic,
                      'uid3': widget.guest3!.uid,
                      'username3': widget.guest3!.username,
                      'pic3': widget.guest3!.pic,
                      'topic': widget.contentinfo!.subject,
                      'description': widget.contentinfo!.description,
                      'category': widget.contentinfo!.category,
                      'time': time,
                    });

                    var guest2docs = await usercollection
                        .doc(widget.guest2!.uid)
                        .collection('requests')
                        .get();
                    int requestlength2 = guest2docs.docs.length;

                    await usercollection
                        .doc(widget.guest2!.uid)
                        .collection('requests')
                        .doc('request $requestlength2')
                        .set({
                      'docName': docName,
                      'type': 'Podcast',
                      'guestsno': widget.guestsno,
                      'uid0': widget.onlineuser!.uid,
                      'username0': widget.onlineuser!.username,
                      'pic0': widget.onlineuser!.pic,
                      'uid1': widget.guest1!.uid,
                      'username1': widget.guest1!.username,
                      'pic1': widget.guest1!.pic,
                      'uid2': widget.guest2!.uid,
                      'username2': widget.guest2!.username,
                      'pic2': widget.guest2!.pic,
                      'uid3': widget.guest3!.uid,
                      'username3': widget.guest3!.username,
                      'pic3': widget.guest3!.pic,
                      'topic': widget.contentinfo!.subject,
                      'description': widget.contentinfo!.description,
                      'category': widget.contentinfo!.category,
                      'time': time,
                    });

                    var guest3docs = await usercollection
                        .doc(widget.guest3!.uid)
                        .collection('requests')
                        .get();
                    int requestlength3 = guest3docs.docs.length;

                    await usercollection
                        .doc(widget.guest3!.uid)
                        .collection('requests')
                        .doc('request $requestlength3')
                        .set({
                      'docName': docName,
                      'type': 'Podcast',
                      'guestsno': widget.guestsno,
                      'uid0': widget.onlineuser!.uid,
                      'username0': widget.onlineuser!.username,
                      'pic0': widget.onlineuser!.pic,
                      'uid1': widget.guest1!.uid,
                      'username1': widget.guest1!.username,
                      'pic1': widget.guest1!.pic,
                      'uid2': widget.guest2!.uid,
                      'username2': widget.guest2!.username,
                      'pic2': widget.guest2!.pic,
                      'uid3': widget.guest3!.uid,
                      'username3': widget.guest3!.username,
                      'pic3': widget.guest3!.pic,
                      'topic': widget.contentinfo!.subject,
                      'description': widget.contentinfo!.description,
                      'category': widget.contentinfo!.category,
                      'time': time,
                    });
                  }

                  await contentcollection.doc(docName).set({
                    'type': 'Podcast',
                    'guestsno': widget.guestsno,
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
                    'requesteduids': (widget.guestsno == 1)
                        ? [widget.guest1!.uid]
                        : (widget.guestsno == 2)
                            ? [
                                widget.guest1!.uid,
                                widget.guest2!.uid,
                              ]
                            : [
                                widget.guest1!.uid,
                                widget.guest2!.uid,
                                widget.guest3!.uid
                              ],
                    'accepteduids': [],
                    'declineduids': [],
                    'pendinguids': (widget.guestsno == 1)
                        ? [widget.guest1!.uid]
                        : (widget.guestsno == 2)
                            ? [
                                widget.guest1!.uid,
                                widget.guest2!.uid,
                              ]
                            : [
                                widget.guest1!.uid,
                                widget.guest2!.uid,
                                widget.guest3!.uid
                              ],
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

                  (channelcreated == true)
                      ? await contentcollection
                          .doc(docName)
                          .collection('users')
                          .doc('user 0')
                          .set({
                          'uid': widget.onlineuser!.uid,
                          'username': widget.onlineuser!.username,
                          'name': widget.onlineuser!.name,
                          'email': widget.onlineuser!.email,
                          'pic': widget.onlineuser!.pic
                        })
                      : _channelError();
                  setState(() {
                    hidenav = false;
                  });
                  if (!mounted) return;
                  AppBuilder.of(context)!.rebuild();
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => SelectFormat()),
                      (route) => false);
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
                  padding: const EdgeInsets.only(right: 16, left: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ProfileWidget(
                          showverifiedtick: true,
                          imageUrl: widget.onlineuser!.pic,
                          username: widget.onlineuser!.username,
                          profileverified: widget.onlineuser!.profileverified,
                          variation: true,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: ProfileWidget(
                          showverifiedtick: true,
                          profileverified: widget.guest1!.profileverified,
                          imageUrl: widget.guest1!.pic,
                          username: widget.guest1!.username,
                          variation: true,
                        ),
                      ),
                    ],
                  ),
                ),
                (widget.guestsno == 2)
                    ? Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, right: 16, left: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ProfileWidget(
                                showverifiedtick: true,
                                profileverified: widget.guest2!.profileverified,
                                imageUrl: widget.guest2!.pic,
                                username: widget.guest2!.username,
                                variation: true,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                                child: Container(
                              height: 140,
                            )),
                          ],
                        ),
                      )
                    : Container(),
                (widget.guestsno == 3)
                    ? Padding(
                        padding: const EdgeInsets.only(
                            top: 8.0, right: 16, left: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: ProfileWidget(
                                showverifiedtick: true,
                                profileverified: widget.guest2!.profileverified,
                                imageUrl: widget.guest2!.pic,
                                username: widget.guest2!.username,
                                variation: true,
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Expanded(
                              child: ProfileWidget(
                                showverifiedtick: true,
                                profileverified: widget.guest3!.profileverified,
                                imageUrl: widget.guest3!.pic,
                                username: widget.guest3!.username,
                                variation: true,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 16, right: 16, left: 16),
                  child: Card(
                    color: Colors.grey.shade800,
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
