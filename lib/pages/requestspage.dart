import 'dart:async';

import 'package:challo/models/content_info_model.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/widgets/podcastinfowidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:challo/variables.dart';
import 'package:timeago/timeago.dart' as tago;
import 'package:challo/widgets/content_info_widget.dart';
import 'dart:math';

class RequestsPage extends StatefulWidget {
  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  late String onlineuid, onlineusername, onlinename, onlineemail, onlinepic;
  bool dataisthere = false;
  late UserInfoModel onlineuser, user0, user1, user2, user3;
  late ContentInfoModel debateinfo, podcastinfo;
  bool stoploading = false;
  bool firstcheckover = false;
  Timer? timer;

  getalldata() async {
    onlineuid = FirebaseAuth.instance.currentUser!.uid;

    var userdoc = await usercollection.doc(onlineuid).get();

    onlineusername = userdoc['username'];

    onlinename = userdoc['name'];

    onlineemail = userdoc['email'];

    onlinepic = userdoc['profilepic'];

    setState(() {
      dataisthere = true;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

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
    getalldata();
  }

  firstcheckconnected() {
    if (connected == true) {
      setState(() {
        stoploading = true;
      });
    }
    setState(() {
      firstcheckover = true;
    });
  }

  checkconnected() {
    if (connected == true) {
      setState(() {
        stoploading = true;
      });
    }
  }

  void _pendingError() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Session Pending...",
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: Colors.white,
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold)),
          content: new Text(
              "Exit the ongoing debate/podcast session before entering a new one.",
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

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateAlertDocString(String docName) {
    String newAlertDocString = "alert$docName${getRandomString(3)}";
    return newAlertDocString;
  }

  _updateAccepted(String docName, String formattype, UserInfoModel onlineuser,
      int guestsno) async {
    await contentcollection.doc(docName).update({
      'pendinguids': FieldValue.arrayRemove([onlineuser.uid]),
      'accepteduids': FieldValue.arrayUnion([onlineuser.uid]),
      'unexiteduids': FieldValue.arrayUnion([onlineuser.uid]),
    });

    var userdocs =
        await contentcollection.doc(docName).collection('users').get();

    int userlength = userdocs.docs.length;

    (formattype == 'Debate')
        ? await contentcollection
            .doc(docName)
            .collection('users')
            .doc('user $userlength')
            .set({
            'uid': onlineuser.uid,
            'username': onlineuser.username,
            'name': onlineuser.name,
            'email': onlineuser.email,
            'pic': onlineuser.pic,
            'stand': onlineuser.selectedRadioStand,
          })
        : await contentcollection
            .doc(docName)
            .collection('users')
            .doc('user $userlength')
            .set({
            'uid': onlineuser.uid,
            'username': onlineuser.username,
            'name': onlineuser.name,
            'email': onlineuser.email,
            'pic': onlineuser.pic,
          });

    var channeldocs = await contentcollection.doc(docName).get();
    List<String> unexiteduidswithoutonlineuser = [];
    List<String> unexiteduidswithoutop = [];
    unexiteduidswithoutonlineuser = List.from(channeldocs['unexiteduids']);
    unexiteduidswithoutonlineuser.removeWhere((value) => value == onlineuid);
    unexiteduidswithoutop = List.from(channeldocs['unexiteduids']);
    unexiteduidswithoutop
        .removeWhere((value) => value == channeldocs['whostarted']);
    if (unexiteduidswithoutonlineuser.isNotEmpty) {
      for (String uid in unexiteduidswithoutonlineuser) {
        await usercollection
            .doc(uid)
            .collection('alerts001')
            .doc(generateAlertDocString(docName))
            .set({
          'text':
              '$onlineusername has accepted the request to join the ${channeldocs['type']}, ${channeldocs['topic']}.',
          'time': DateTime.now(),
          'type': channeldocs['type'],
        });
      }
    }
    if (channeldocs['accepteduids'].length == guestsno) {
      String alertAcceptedDocString = generateAlertDocString(docName);
      await contentcollection.doc(docName).update({'status': 'accepted'});
      await usercollection
          .doc(channeldocs['whostarted'])
          .collection('alerts001')
          .doc(alertAcceptedDocString)
          .set({
        'text':
            'You can now begin the ${channeldocs['type']} livestream session from the Create page with accepted user(s).',
        'time': DateTime.now(),
        'type': channeldocs['type'],
      });
      if (unexiteduidswithoutop.isNotEmpty) {
        for (String uid in unexiteduidswithoutop) {
          await usercollection
              .doc(uid)
              .collection('alerts001')
              .doc(alertAcceptedDocString)
              .set({
            'text': (channeldocs['type'] == 'Debate')
                ? 'You can join the livestream for the ${channeldocs['type']}, ${channeldocs['topic']}, from the Create page after the initiator goes live.'
                : 'Other invitee(s) have accepted to join the ${channeldocs['type']}, ${channeldocs['topic']}. You can join the livestream from the Create page after the initiator goes live.',
            'time': DateTime.now(),
            'type': channeldocs['type'],
          });
        }
      }
    } else {
      print("more pending requests");
    }
  }

  _updateDeclined(String docName) async {
    print("Inside _updateDeclined function");
    print("The name of the channel is $docName");
    var channeldocs = await contentcollection.doc(docName).get();
    int guestsno = channeldocs['guestsno'];
    String whostarted = channeldocs['whostarted'];
    List<String> unexiteduidswithoutonlineuser = [];
    unexiteduidswithoutonlineuser = List.from(channeldocs['unexiteduids']);
    if (unexiteduidswithoutonlineuser.isNotEmpty) {
      for (String uid in unexiteduidswithoutonlineuser) {
        await usercollection
            .doc(uid)
            .collection('alerts001')
            .doc(generateAlertDocString(docName))
            .set({
          'text':
              '$onlineusername has declined to join the ${channeldocs['type']}, ${channeldocs['topic']}.',
          'time': DateTime.now(),
          'type': channeldocs['type'],
        });
      }
    }

    print("Previous guestsno is $guestsno");
    setState(() {
      guestsno = guestsno - 1;
    });
    print("New guestsno: $guestsno");
    //await contentcollection.doc(docName).update({'guestsno': guestsno});

    if (guestsno == 0) {
      contentcollection.doc(docName).update({
        'status': 'guestscanceled',
        'guestsno': guestsno,
        'pendinguids': FieldValue.arrayRemove([onlineuid]),
        'declineduids': FieldValue.arrayUnion([onlineuid]),
      });
      usercollection.doc(whostarted).update({'pendingvideo': false});
    } else {
      if (channeldocs['accepteduids'].length == guestsno) {
        print("Everyone else accepted requests");
        contentcollection.doc(docName).update({
          'status': 'accepted',
          'guestsno': guestsno,
          'pendinguids': FieldValue.arrayRemove([onlineuid]),
          'declineduids': FieldValue.arrayUnion([onlineuid]),
        });
      } /*else if (channeldocs['requesteduids'].length ==
          channeldocs['declineduids'].length) {
        print("Everyone declined requests");
        await contentcollection.doc(docName).update({
          'status': 'canceled',
          'guestsno': guestsno,
          'pendinguids': FieldValue.arrayRemove([onlineuid]),
          'declineduids': FieldValue.arrayUnion([onlineuid]),
        });
      }*/
      else {
        print("more pending requests");
      }
    }
    await usercollection.doc(onlineuid).update({'pendingvideo': false});
  }

  Widget _allrequests() {
    return Container(
      //color: Colors.white,
      child: StreamBuilder<QuerySnapshot>(
        stream: usercollection
            .doc(onlineuid)
            .collection('requests')
            .orderBy('time', descending: false)
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CupertinoActivityIndicator(
              color: kDarkPrimaryColor,
            ));
          }
          if (snapshot.data.docs.length == 0) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text(
                    'If someone invites you to a podcast or debate, you will be notified here. You currently have no pending requests.',
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          fontSize: 15,
                          color: Colors.white,
                        )),
              ),
            );
          }
          return ListView.builder(
              //reverse: true,
              itemCount: snapshot.data.docs.length,
              itemBuilder: (BuildContext context, int index) {
                var request = snapshot.data.docs[index];
                return Card(
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20))),
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  elevation: 8,
                  color: Theme.of(context).primaryIconTheme.color,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 5.0),
                          child: Hero(
                              tag: 1,
                              child: ClipRRect(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(16)),
                                child: Image.network(
                                  request['pic0'],
                                  height: 36,
                                  width: 36,
                                  fit: BoxFit.fill,
                                ),
                              )),
                        ),
                        Expanded(
                          child: Text(
                            request['topic'],
                            style:
                                Theme.of(context).textTheme.subtitle1!.copyWith(
                                      fontSize: 15,
                                      //fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              "${request['type']} Request •",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                    fontWeight: FontWeight.w900,
                                    color: kBodyTextColorDark,
                                  ),
                            ),
                            const SizedBox(
                              width: 5.0,
                            ),
                            const Icon(
                              Icons.watch_later_outlined,
                              size: 10,
                            ),
                            Text(
                              tago.format(request['time'].toDate()),
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                    fontWeight: FontWeight.w900,
                                    color: kBodyTextColorDark,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          width: 5.0,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            TextButton(
                              child: const Text(
                                "Accept",
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () async {
                                var userdoc =
                                    await usercollection.doc(onlineuid).get();
                                if (userdoc['pendingvideo'] == true) {
                                  _pendingError();
                                } else {
                                  bool pendingvideo = true;
                                  int guestsno = request['guestsno'];

                                  (request['type'] == 'Debate')
                                      ? onlineuser = UserInfoModel(
                                          uid: onlineuid,
                                          username: onlineusername,
                                          name: onlinename,
                                          email: onlineemail,
                                          pic: onlinepic,
                                          selectedRadioStand: request['stand'])
                                      : onlineuser = UserInfoModel(
                                          uid: onlineuid,
                                          username: onlineusername,
                                          name: onlinename,
                                          email: onlineemail,
                                          pic: onlinepic,
                                        );
                                  String docName = request['docName'];

                                  String formattype = request['type'];

                                  usercollection.doc(onlineuid).update({
                                    'pendingvideo': true,
                                    'docName': docName,
                                  });

                                  _updateAccepted(docName, formattype,
                                      onlineuser, guestsno);

                                  snapshot.data.docs[index].reference.delete();

                                  if (!mounted) return;
                                  Navigator.pop(context, pendingvideo);
                                }
                              },
                            ),
                            TextButton(
                              child: const Text(
                                "Decline",
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  String docName = request['docName'];
                                  _updateDeclined(docName);
                                  snapshot.data.docs[index].reference.delete();
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: InkWell(
                      onTap: () {
                        if (request['type'] == 'Debate') {
                          setState(() {
                            user0 = UserInfoModel(
                                uid: request['uid0'],
                                username: request['username0'],
                                pic: request['pic0'],
                                selectedRadioStand:
                                    (request['stand'] == "For the motion")
                                        ? "Against the motion"
                                        : "For the motion");
                            user1 = UserInfoModel(
                                uid: onlineuid,
                                username: onlineusername,
                                pic: onlinepic,
                                selectedRadioStand: request['stand']);
                            debateinfo = ContentInfoModel(
                                subject: request['topic'],
                                description: request['description'],
                                category: request['category']);
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) {
                                return AlertDialog(
                                  backgroundColor: kSecondaryDarkColor,
                                  contentPadding: const EdgeInsets.only(
                                      left: 10, right: 10),
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
                                    Center(
                                      child: Text(
                                        "${request['type']} Request",
                                        style:
                                            TextStyle(color: Colors.grey[500]),
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
                                        (MediaQuery.of(context).size.height) /
                                            1.2,
                                    width: (MediaQuery.of(context).size.width) /
                                        1.2,
                                    child: Column(
                                      children: [
                                        ContentInfoWidget(
                                          formattype: request['type'],
                                          user0: user1,
                                          user1: user0,
                                          contentinfo: debateinfo,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          });
                        }
                        //now for podcasts
                        else {
                          if (request['guestsno'] == 1) {
                            setState(() {
                              user0 = UserInfoModel(
                                  uid: request['uid0'],
                                  username: request['username0'],
                                  pic: request['pic0']);
                              user1 = UserInfoModel(
                                  uid: request['uid1'],
                                  username: request['username1'],
                                  pic: request['pic1']);
                              podcastinfo = ContentInfoModel(
                                  subject: request['topic'],
                                  description: request['description'],
                                  category: request['category']);
                            });
                          } else {
                            setState(() {
                              onlineuser = UserInfoModel(
                                  uid: onlineuid,
                                  username: onlineusername,
                                  pic: onlinepic);
                              user0 = UserInfoModel(
                                  uid: request['uid0'],
                                  username: request['username0'],
                                  pic: request['pic0']);
                              user1 = UserInfoModel(
                                  uid: request['uid1'],
                                  username: request['username1'],
                                  pic: request['pic1']);
                              user2 = UserInfoModel(
                                  uid: request['uid2'],
                                  username: request['username2'],
                                  pic: request['pic2']);
                              podcastinfo = ContentInfoModel(
                                  subject: request['topic'],
                                  description: request['description'],
                                  category: request['category']);
                            });
                          }
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (context) {
                              return AlertDialog(
                                backgroundColor: kSecondaryDarkColor,
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
                                  Center(
                                    child: Text(
                                      "${request['type']} Request",
                                      style: TextStyle(
                                          color: Colors.grey.shade500),
                                    ),
                                  ),
                                ]),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(20.0),
                                  ),
                                ),
                                content: Container(
                                  height: (MediaQuery.of(context).size.height) /
                                      1.2,
                                  width:
                                      (MediaQuery.of(context).size.width) / 1.2,
                                  child: Column(
                                    children: [
                                      (request['guestsno'] == 1)
                                          ? PodcastInfoWidget(
                                              guestsno: request['guestsno'],
                                              user0: user0,
                                              user1: user1,
                                              contentinfo: podcastinfo,
                                            )
                                          : PodcastInfoWidget(
                                              guestsno: request['guestsno'],
                                              user0: user0,
                                              user1: user1,
                                              user2: user2,
                                              contentinfo: podcastinfo),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                      child: const Icon(
                        Icons.info_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
                /*return ListTile(
                  /*leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(request['profilepic']),
                  ),*/
                  title: Card(
                    shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    margin:
                        const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                    elevation: 8,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: kPrimaryColor,
                            child: Column(
                              children: <Widget>[
                                Container(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    "${request['type']} Request",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: <Widget>[
                                    Icon(
                                      Icons.watch_later,
                                      color: Colors.grey.shade100,
                                      size: 21,
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Text(
                                      tago.format(request['time'].toDate()),
                                      style: TextStyle(
                                        color: Colors.grey.shade100,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            color: Colors.white,
                            child: Column(
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Hero(
                                        tag: 1,
                                        child: ClipRRect(
                                          borderRadius: const BorderRadius.all(
                                              Radius.circular(16)),
                                          child: Image.network(
                                            request['pic0'],
                                            height: 56,
                                            width: 56,
                                            fit: BoxFit.fill,
                                          ),
                                        )),
                                    const SizedBox(
                                      width: 16,
                                    ),
                                    Expanded(
                                      child: Text(
                                        (request['type'] == 'Debate')
                                            ? "${request['username0']} has invited you to a debate!"
                                            : "${request['username0']} has invited you to a podcast!",
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        if (request['type'] == 'Debate') {
                                          setState(() {
                                            user0 = UserInfoModel(
                                                uid: request['uid0'],
                                                username: request['username0'],
                                                pic: request['pic0'],
                                                selectedRadioStand:
                                                    (request['stand'] ==
                                                            "For the motion")
                                                        ? "Against the motion"
                                                        : "For the motion");
                                            user1 = UserInfoModel(
                                                uid: onlineuid,
                                                username: onlineusername,
                                                pic: onlinepic,
                                                selectedRadioStand:
                                                    request['stand']);
                                            debateinfo = ContentInfoModel(
                                                subject: request['topic'],
                                                description:
                                                    request['description'],
                                                category: request['category']);
                                            showDialog(
                                              context: context,
                                              barrierDismissible: true,
                                              builder: (context) {
                                                return AlertDialog(
                                                  backgroundColor:
                                                      kSecondaryDarkColor,
                                                  contentPadding:
                                                      const EdgeInsets.only(
                                                          left: 10, right: 10),
                                                  title: Stack(children: [
                                                    Positioned(
                                                      right: 0.0,
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: const Align(
                                                          alignment: Alignment
                                                              .topRight,
                                                          child: CircleAvatar(
                                                            radius: 10,
                                                            backgroundColor:
                                                                Colors.white,
                                                            child: Icon(
                                                              Icons.close,
                                                              color: Colors.red,
                                                              size: 15,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Center(
                                                      child: Text(
                                                        "${request['type']} Request",
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[500]),
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
                                                    height:
                                                        (MediaQuery.of(context)
                                                                .size
                                                                .height) /
                                                            1.2,
                                                    width:
                                                        (MediaQuery.of(context)
                                                                .size
                                                                .width) /
                                                            1.2,
                                                    child: Column(
                                                      children: [
                                                        ContentInfoWidget(
                                                          formattype:
                                                              request['type'],
                                                          user0: user1,
                                                          user1: user0,
                                                          contentinfo:
                                                              debateinfo,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          });
                                        }
                                        //now for podcasts
                                        else {
                                          if (request['guestsno'] == 1) {
                                            setState(() {
                                              user0 = UserInfoModel(
                                                  uid: request['uid0'],
                                                  username:
                                                      request['username0'],
                                                  pic: request['pic0']);
                                              user1 = UserInfoModel(
                                                  uid: request['uid1'],
                                                  username:
                                                      request['username1'],
                                                  pic: request['pic1']);
                                              podcastinfo = ContentInfoModel(
                                                  subject: request['topic'],
                                                  description:
                                                      request['description'],
                                                  category:
                                                      request['category']);
                                            });
                                          } else {
                                            setState(() {
                                              onlineuser = UserInfoModel(
                                                  uid: onlineuid,
                                                  username: onlineusername,
                                                  pic: onlinepic);
                                              user0 = UserInfoModel(
                                                  uid: request['uid0'],
                                                  username:
                                                      request['username0'],
                                                  pic: request['pic0']);
                                              user1 = UserInfoModel(
                                                  uid: request['uid1'],
                                                  username:
                                                      request['username1'],
                                                  pic: request['pic1']);
                                              user2 = UserInfoModel(
                                                  uid: request['uid2'],
                                                  username:
                                                      request['username2'],
                                                  pic: request['pic2']);
                                              podcastinfo = ContentInfoModel(
                                                  subject: request['topic'],
                                                  description:
                                                      request['description'],
                                                  category:
                                                      request['category']);
                                            });
                                          }
                                          showDialog(
                                            context: context,
                                            barrierDismissible: true,
                                            builder: (context) {
                                              return AlertDialog(
                                                backgroundColor:
                                                    kSecondaryDarkColor,
                                                contentPadding:
                                                    const EdgeInsets.only(
                                                        left: 10, right: 10),
                                                title: Stack(children: [
                                                  Positioned(
                                                    right: 0.0,
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Align(
                                                        alignment:
                                                            Alignment.topRight,
                                                        child: CircleAvatar(
                                                          radius: 10,
                                                          backgroundColor:
                                                              Colors.white,
                                                          child: Icon(
                                                            Icons.close,
                                                            color: Colors.red,
                                                            size: 15,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Center(
                                                    child: Text(
                                                      "${request['type']} Request",
                                                      style: TextStyle(
                                                          color: Colors
                                                              .grey.shade500),
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
                                                  height:
                                                      (MediaQuery.of(context)
                                                              .size
                                                              .height) /
                                                          1.2,
                                                  width: (MediaQuery.of(context)
                                                          .size
                                                          .width) /
                                                      1.2,
                                                  child: Column(
                                                    children: [
                                                      (request['guestsno'] == 1)
                                                          ? PodcastInfoWidget(
                                                              guestsno: request[
                                                                  'guestsno'],
                                                              user0: user0,
                                                              user1: user1,
                                                              contentinfo:
                                                                  podcastinfo,
                                                            )
                                                          : PodcastInfoWidget(
                                                              guestsno: request[
                                                                  'guestsno'],
                                                              user0: user0,
                                                              user1: user1,
                                                              user2: user2,
                                                              contentinfo:
                                                                  podcastinfo),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        }
                                      },
                                      child: Icon(
                                        Icons.info_outline,
                                        color: kPrimaryColor,
                                        size: 25,
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: TextButton(
                                          onPressed: () async {
                                            var userdoc = await usercollection
                                                .doc(onlineuid)
                                                .get();
                                            if (userdoc['pendingvideo'] ==
                                                true) {
                                              _pendingError();
                                            } else {
                                              bool pendingvideo = true;
                                              int guestsno =
                                                  request['guestsno'];
                                              onlineuser = UserInfoModel(
                                                  uid: onlineuid,
                                                  username: onlineusername,
                                                  name: onlinename,
                                                  email: onlineemail,
                                                  pic: onlinepic,
                                                  selectedRadioStand:
                                                      request['stand']);
                                              String docName =
                                                  request['docName'];

                                              String formattype =
                                                  request['type'];

                                              usercollection
                                                  .doc(onlineuid)
                                                  .update({
                                                'pendingvideo': true,
                                                'docName': docName,
                                              });

                                              _updateAccepted(
                                                  docName,
                                                  formattype,
                                                  onlineuser,
                                                  guestsno);

                                              snapshot
                                                  .data.docs[index].reference
                                                  .delete();

                                              Navigator.pop(
                                                  context, pendingvideo);
                                            }
                                          },
                                          child: const Text(
                                            "ACCEPT",
                                          ),
                                          /*  textColor: Colors.white,
                                          color: kPrimaryColor,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(
                                                Radius.circular(20)),*/
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        child: TextButton(
                                          onPressed: () {
                                            setState(() {
                                              String docName =
                                                  request['docName'];
                                              _updateDeclined(docName);
                                              snapshot
                                                  .data.docs[index].reference
                                                  .delete();
                                            });
                                          },
                                          child: const Text(
                                            "DECLINE",
                                          ),
                                          /*   textColor: Colors.grey.shade700,
                                          color: Colors.grey.shade300,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.all(
                                                  Radius.circular(20))),*/
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                );*/
              });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back),
          onTap: () => Navigator.pop(context),
        ),
        title: const Text("Requests"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: (stoploading == false)
            ? const Center(
                child: CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              ))
            : (dataisthere == false)
                ? const Center(
                    child: CupertinoActivityIndicator(
                    color: kDarkPrimaryColor,
                  ))
                : _allrequests(),
      ),
    );
  }
}
