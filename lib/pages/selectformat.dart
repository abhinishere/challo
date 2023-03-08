import 'dart:async';
import 'package:challo/models/content_info_model.dart';
import 'package:challo/models/link_to.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/community_page.dart';
import 'package:challo/pages/createcommunity.dart';
import 'package:challo/pages/debate_screen1.dart';
import 'package:challo/pages/image_page_2.dart';
import 'package:challo/pages/linkpage.dart';
import 'package:challo/pages/nonlive_video_player.dart';
import 'package:challo/pages/pending_session.dart';
import 'package:challo/pages/podcast_screen1.dart';
import 'package:challo/pages/post_image.dart';
import 'package:challo/pages/post_text.dart';
import 'package:challo/pages/postlink.dart';
import 'package:challo/pages/profilepage.dart';
import 'package:challo/pages/qna_screen1.dart';
import 'package:challo/pages/requestspage.dart';
import 'package:challo/pages/text_content_page.dart';
import 'package:challo/pages/upload_video.dart';
import 'package:challo/pages/videoplayerpage.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/icon_text_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SelectFormat extends StatefulWidget {
  @override
  State<SelectFormat> createState() => _SelectFormatState();
}

class _SelectFormatState extends State<SelectFormat> {
  bool? pendingvideo = false;
  String? onlineuid, onlineusername, onlinename, onlineemail, onlinepic;
  String? docName;
  bool? onlineprofileverified;
  bool dataisthere = false;
  bool stoploading = false;
  bool firstcheckover = false;
  bool whetheraccepted = false;
  bool didonlinestart = false;
  UserInfoModel? onlineuser;
  ContentInfoModel? contentinfo;
  Timer? timer;
  TextEditingController linkController = TextEditingController();
  bool whethercanceled = false;
  String howcanceled = '';
  bool showugcpolicy = false;
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
    checkPending();
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

  checkPending() async {
    print("fetching user data for SelectFormat");
    bool closedugc = true;
    onlineuid = FirebaseAuth.instance.currentUser!.uid;

    await usercollection.doc(onlineuid).get().then((onlineuserdoc) => {
          onlineusername = onlineuserdoc['username'],
          onlinename = onlineuserdoc['name'],
          onlineemail = onlineuserdoc['email'],
          onlinepic = onlineuserdoc['profilepic'],
          onlineprofileverified = onlineuserdoc['profileverified'],
          pendingvideo = onlineuserdoc['pendingvideo'],
          closedugc = onlineuserdoc['closedugc'],
          if (pendingvideo == true)
            {
              docName = onlineuserdoc['docName'],
            }
        });

    if (closedugc == true) {
      showugcpolicy = false;
    } else {
      showugcpolicy = true;
    }

    onlineuser = UserInfoModel(
      uid: onlineuid,
      username: onlineusername,
      name: onlinename,
      email: onlineemail,
      pic: onlinepic,
      profileverified: onlineprofileverified,
    );

    if (!mounted) return;
    setState(() {
      dataisthere = true;
    });
  }

  void messageAlert(
      BuildContext context, String heading, String message, String buttonText) {
    showDialog(
        context: context,
        builder: (context) {
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

  chooseLivestreamFormat() {
    showCupertinoModalPopup(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          "Choose Livestream Format",
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
              setState(() {
                hidenav = true;
              });
              AppBuilder.of(context)!.rebuild();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QnAScreen1(
                    whetherediting: false,
                    onlineuser: onlineuser,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Text(
              'Q&A',
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
              setState(() {
                hidenav = true;
              });
              AppBuilder.of(context)!.rebuild();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DebateScreen1(
                    whetherediting: false,
                    onlineuser: onlineuser,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Text(
              'Debate',
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
              setState(() {
                hidenav = true;
              });
              AppBuilder.of(context)!.rebuild();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PodcastScreen1(
                    whetherediting: false,
                    onlineuser: onlineuser,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Text(
              'Podcast',
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

  Widget exitSessionSheet(String? docName, String? whostarted, int? guestsno) {
    return Container(
      height: (MediaQuery.of(context).size.height) / 5,
      width: (MediaQuery.of(context).size.width),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Text(
            "Are you sure you want to exit?",
            style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: Colors.white,
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextButton(
                      onPressed: () {
                        exitLiveStream(docName, whostarted, guestsno);
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "Yes",
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                              color: kPrimaryColor,
                              //fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.grey.shade500,
                    width: 0.5,
                    height: 22,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        "No",
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                              color: kPrimaryColor,
                              //fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget pendingCard() {
    return StreamBuilder<QuerySnapshot>(
      stream:
          contentcollection.where('docName', isEqualTo: docName).snapshots(),
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting info");
          return Container();
        }
        if (snapshot.data.docs.length == 0) {
          return Center(
            child: Container(),
          );
        }
        var postdocs = snapshot.data.docs[0];
        if (postdocs['status'] == 'pending' ||
            postdocs['status'] == 'accepted' ||
            postdocs['status'] == 'started') {
          return InkWell(
            onTap: () {
              if (postdocs['status'] == 'pending') {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    "All Invitee(s) have not yet responded to the ${postdocs['type']} request. You can join the session when the status changes to Accepted or Started.",
                  ),
                ));
              } else {
                setState(() {
                  hidenav = true;
                });
                AppBuilder.of(context)!.rebuild();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PendingSession(
                      oppic: postdocs['oppic'],
                      whethervideoprocessing: false,
                      onlineuser: onlineuser,
                      docName: postdocs['docName'],
                      opusername: postdocs['opusername'],
                    ),
                    fullscreenDialog: true,
                  ),
                ).then((whethercanceled) => (whethercanceled == true)
                    ? setState(() {
                        //livestreamendeddialog();
                      })
                    : null);
              }
            },
            child: pendingCardWidget(
                postdocs['topic'],
                postdocs['type'],
                postdocs['status'],
                postdocs['docName'],
                postdocs['whostarted'],
                postdocs['guestsno']),
          );
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              pendingvideo = false;
            });
          });
          return Container();
        }
      },
    );
  }

  Widget messageCardWidget() {
    return ((whethercanceled == true) && (pendingvideo == false))
        ? Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            color: Theme.of(context).primaryIconTheme.color,
            child: Container(
              child: (howcanceled == 'initiatorcanceled')
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            mainAxisSize: MainAxisSize.max,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("Stream canceled...",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                          color: Colors.white,
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.bold)),
                              ButtonTheme(
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
                                    setState(() {
                                      print("closed messageCardWidget");
                                      whethercanceled = false;
                                      howcanceled = '';
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 17,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: 10.0, left: 10.0, right: 10.0),
                          child: Text(
                              "Initiator has left the livestream session, and so it has been canceled.",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                    color: Colors.white70,
                                    fontSize: 14.0,
                                  )),
                        ),
                      ],
                    )
                  : (howcanceled == 'guestscanceled')
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                mainAxisSize: MainAxisSize.max,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text("Stream canceled...",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                              color: Colors.white,
                                              fontSize: 15.0,
                                              fontWeight: FontWeight.bold)),
                                  ButtonTheme(
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
                                        setState(() {
                                          print("closed messageCardWidget");
                                          whethercanceled = false;
                                          howcanceled = '';
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        size: 17,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(
                                  bottom: 10.0, left: 10.0, right: 10.0),
                              child: Text(
                                  "None of the invited guests have joined the livestream session, and so it has been canceled.",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 14.0,
                                      )),
                            ),
                          ],
                        )
                      : (howcanceled == 'completed')
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text("Streaming completed...",
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: Colors.white,
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.bold)),
                                      ButtonTheme(
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
                                            setState(() {
                                              print("closed messageCardWidget");
                                              whethercanceled = false;
                                              howcanceled = '';
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 17,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 10.0, left: 10.0, right: 10.0),
                                  child: Text(
                                      "Initiator has ended the livestream session.",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                            color: Colors.white70,
                                            fontSize: 14.0,
                                          )),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text("Streaming error...",
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: Colors.white,
                                                  fontSize: 15.0,
                                                  fontWeight: FontWeight.bold)),
                                      ButtonTheme(
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
                                            setState(() {
                                              print("closed messageCardWidget");
                                              whethercanceled = false;
                                              howcanceled = '';
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 17,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 10.0, left: 10.0, right: 10.0),
                                  child: Text(
                                      "Streaming session has been canceled due to an unknown reason.",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                            color: Colors.white70,
                                            fontSize: 14.0,
                                          )),
                                ),
                              ],
                            ),
            ),
          )
        : Container();
  }

  Widget pendingCardWidget(String topic, String? type, String? status,
      String? docName, String? whostarted, int? guestsno) {
    return Card(
      color: Theme.of(context).primaryIconTheme.color,
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        title: Text(
          topic,
          style: Theme.of(context).textTheme.subtitle1!.copyWith(
                fontSize: 15,
                //fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        ),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  (type == 'QnA') ? "Q&A •" : "$type •",
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        fontSize: 12,
                        //fontWeight: FontWeight.bold,
                        fontWeight: FontWeight.w900,
                        color: kBodyTextColorDark,
                      ),
                ),
                const SizedBox(
                  width: 5.0,
                ),
                Text(
                  (status == 'pending')
                      ? "Pending •"
                      : (status == 'accepted')
                          ? "Accepted •"
                          : "Started •",
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
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
            Text(
              (status == 'pending')
                  ? "Waiting for other participant(s) to accept the request..."
                  : "Click here to start the livestream session...",
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    fontSize: 12,
                    //fontWeight: FontWeight.bold,
                    fontWeight: FontWeight.w900,
                    color: kPrimaryColor,
                  ),
            ),
          ],
        ),
        trailing: InkWell(
          onTap: () {
            showModalBottomSheet(
                context: context,
                builder: (builder) =>
                    exitSessionSheet(docName, whostarted, guestsno));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(8))),
            child: const Text(
              'EXIT',
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  exitLiveStream(String? docName, String? whostarted, int? guestsno) async {
    print("Inside exitLiveStream function");
    if (onlineuser!.uid == whostarted) {
      await usercollection.doc(onlineuser!.uid).update({'pendingvideo': false});
      await contentcollection
          .doc(docName)
          .update({'status': 'initiatorcanceled'});
      canceledUpdate(docName);
      setState(() {
        pendingvideo = false;
      });
    } else {
      setState(() {
        guestsno = guestsno! - 1;
      });
      contentcollection.doc(docName).update({'guestsno': guestsno});
      print("A participant has exited. Guestsno is $guestsno");
      if (guestsno == 0) {
        setState(() {});
        await contentcollection
            .doc(docName)
            .update({'status': 'guestscanceled'});
        await usercollection
            .doc(onlineuser!.uid)
            .update({'pendingvideo': false});
        canceledUpdate(docName);
        setState(() {});
      } else {
        var channeluserscollection =
            contentcollection.doc(docName).collection('users');

        var userslistSnapshot = await channeluserscollection
            .where('username', isEqualTo: onlineuser!.username)
            .get();

        await userslistSnapshot.docs.first.reference.delete();

        await contentcollection.doc(docName).update({
          'accepteduids': FieldValue.arrayRemove([onlineuser!.uid]),
          'unexiteduids': FieldValue.arrayRemove([onlineuser!.uid]),
          'declineduids': FieldValue.arrayUnion([onlineuser!.uid]),
        });
        await usercollection
            .doc(onlineuser!.uid)
            .update({'pendingvideo': false}).then((_) => {
                  Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => SelectFormat()),
                      (route) => false),
                });
      }
    }
  }

  canceledUpdate(String? docName) async {
    print("Inside canceledUpdate function");
    var channeldocs = await contentcollection.doc(docName).get();
    List<String> unexiteduids = [];
    unexiteduids = List.from(channeldocs['unexiteduids']);
    if (unexiteduids.isNotEmpty) {
      for (String uid in unexiteduids) {
        await usercollection.doc(uid).update({'pendingvideo': false});
      }
    }
    List<String> pendinguids = [];
    pendinguids = List.from(channeldocs['pendinguids']);
    if (pendinguids.isNotEmpty) {
      for (String uid in pendinguids) {
        //remove the request from each uids
        var requestCollection = usercollection.doc(uid).collection('requests');
        var requestSnapshot =
            await requestCollection.where('docName', isEqualTo: docName).get();
        await requestSnapshot.docs.first.reference.delete();
        await contentcollection.doc(docName).update({
          'pendinguids': FieldValue.arrayRemove([uid])
        });
      }
    }
  }

  Widget ugcNotice() {
    return Card(
      color: Theme.of(context).primaryIconTheme.color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              InkWell(
                onTap: () async {
                  await usercollection.doc(onlineuid).update({
                    'closedugc': true,
                  });
                  setState(() {
                    showugcpolicy = false;
                  });
                },
                child: const Icon(Icons.close, size: 18),
              ),
              Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(right: 2.0),
                    child: Icon(
                      Icons.rule_outlined,
                    ),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                          text:
                              "By creating and/or uploading content, you agree to have read and accepted our ",
                          style:
                              Theme.of(context).textTheme.subtitle1!.copyWith(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                          children: <TextSpan>[
                            TextSpan(
                                text: "User Generated Content (UGC) Policy",
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1!
                                    .copyWith(
                                      color: Colors.blueGrey,
                                      fontSize: 12,
                                    ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: true,
                                      builder: (context) {
                                        return AlertDialog(
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
                                            const Center(
                                              child: Text(
                                                "UGC Policy",
                                                style: TextStyle(
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
                                            height: (MediaQuery.of(context)
                                                    .size
                                                    .height) /
                                                1.2,
                                            width: (MediaQuery.of(context)
                                                    .size
                                                    .width) /
                                                1.2,
                                            child: Column(
                                              children: [
                                                Container(
                                                  child: Expanded(
                                                    child:
                                                        SingleChildScrollView(
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
                                  }),
                            TextSpan(
                              text: ". ",
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontStyle: FontStyle.italic),
                            ),
                          ]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (linkedPage != null &&
        selectedTabIndex == 2 &&
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
        : (dataisthere == false)
            ? const Scaffold(
                body: Center(
                    child: CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              )))
            : Scaffold(
                appBar: AppBar(
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: InkWell(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(5),
                        ),
                        onTap: () => {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RequestsPage(),
                            ),
                          ).then((pendingvideo) => (pendingvideo == true)
                              ? setState(() {
                                  checkPending();
                                })
                              : null),
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 15, vertical: 6),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.all(
                              Radius.circular(5.0),
                            ),
                            border: Border.all(
                              width: 2.0,
                              color: kPrimaryColorTint2,
                            ),
                          ),
                          child: Text(
                            'Livestream Requests',
                            style: Theme.of(context).textTheme.button!.copyWith(
                                  fontSize: 15.0,
                                  color: kPrimaryColorTint2,
                                  fontWeight: FontWeight.bold,
                                  //letterSpacing: 0.2,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        //mainAxisSize: MainAxisSize.min,
                        children: [
                          //(showugcpolicy == false) ? Container() : ugcNotice(),
                          (pendingvideo == false) ? Container() : pendingCard(),

                          Padding(
                            padding: const EdgeInsets.only(
                              left: 10.0,
                              top: 20.0,
                            ),
                            child: Text(
                              "Select an option below to get started.",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                    color: kHeadlineColorDark,
                                    fontSize: 15.0,
                                    letterSpacing: -0.24,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          IconTextButton(
                              mainText: 'Start a livestream',
                              subText: 'for QnAs, debates, or podcasts.',
                              icon: Icons.live_tv,
                              onPress: () {
                                if (pendingvideo == false) {
                                  chooseLivestreamFormat();
                                } else {
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(const SnackBar(
                                    content: Text(
                                      "Exit the ongoing debate/podcast session before starting a new one.",
                                    ),
                                  ));
                                }
                              }),
                          IconTextButton(
                            mainText: 'Share a link',
                            subText: 'to a news article or a cool blog.',
                            icon: Icons.link,
                            onPress: () {
                              setState(() {
                                hidenav = true;
                              });
                              AppBuilder.of(context)!.rebuild();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: ((context) => PostLink(
                                          onlineuser: onlineuser,
                                          whethercommunitypost: false,
                                          whetherediting: false))));
                            },
                          ),
                          IconTextButton(
                              mainText: 'Publish your thoughts',
                              subText: 'in good old text format.',
                              icon: Icons.create,
                              onPress: () {
                                setState(() {
                                  hidenav = true;
                                });
                                AppBuilder.of(context)!.rebuild();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostText(
                                      whetherediting: false,
                                      onlineuser: onlineuser,
                                      whethercommunitypost: false,
                                    ),
                                    fullscreenDialog: true,
                                  ),
                                );
                              }),
                          IconTextButton(
                              mainText: 'Post an image',
                              subText: 'or a cool GIF maybe?',
                              icon: Icons.image,
                              onPress: () {
                                setState(() {
                                  hidenav = true;
                                });
                                AppBuilder.of(context)!.rebuild();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PostImage(
                                      whetherediting: false,
                                      onlineuser: onlineuser,
                                      whethercommunitypost: false,
                                    ),
                                    fullscreenDialog: true,
                                  ),
                                );
                              }),
                          IconTextButton(
                              mainText: 'Upload a video',
                              subText: 'and reap internet points.',
                              icon: Icons.video_collection,
                              onPress: () {
                                setState(() {
                                  hidenav = true;
                                });
                                AppBuilder.of(context)!.rebuild();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: ((context) => UploadVideoPage(
                                          onlineuser: onlineuser,
                                          whethercommunitypost: false,
                                          whetherediting: false,
                                        )),
                                    fullscreenDialog: true,
                                  ),
                                );
                              }),
                          IconTextButton(
                              whetherborderbottom: true,
                              mainText: 'Create a community',
                              subText: 'and bring people together.',
                              icon: Icons.group,
                              onPress: () {
                                setState(() {
                                  hidenav = true;
                                });
                                AppBuilder.of(context)!.rebuild();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: ((context) => CreateCommunity(
                                          onlineuser: onlineuser,
                                          whetherediting: false,
                                        )),
                                    fullscreenDialog: true,
                                  ),
                                );
                              }),
                        ],
                      ),
                    ),
                  ),
                ),
              );
  }
}
