import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/pages/add_lits.dart';
import 'package:challo/helpers/share_service.dart';
import 'package:challo/models/link_to.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/account_settings.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/audiencepage.dart';
import 'package:challo/pages/bug_report.dart';
import 'package:challo/pages/community_page.dart';
import 'package:challo/pages/contact_page.dart';
import 'package:challo/pages/content_results.dart';
import 'package:challo/pages/debate_screen1.dart';
import 'package:challo/pages/featured_communities.dart';
import 'package:challo/pages/image_page_2.dart';
import 'package:challo/pages/linkpage.dart';
import 'package:challo/pages/lits_timeline_2.dart';
import 'package:challo/pages/nonlive_video_player.dart';
import 'package:challo/pages/podcast_screen1.dart';
import 'package:challo/pages/policies_page.dart';
import 'package:challo/pages/post_image.dart';
import 'package:challo/pages/post_text.dart';
import 'package:challo/pages/postlink.dart';
import 'package:challo/pages/preview_image.dart';
import 'package:challo/pages/preview_text_image.dart';
import 'package:challo/pages/profilepage.dart';
import 'package:challo/pages/qna_screen1.dart';
import 'package:challo/pages/text_content_page.dart';
import 'package:challo/pages/upload_video.dart';
import 'package:challo/pages/videoplayerpage.dart';
import 'package:challo/widgets/featured_live_card.dart';
import 'package:challo/widgets/featured_text_card.dart';
import 'package:challo/widgets/featured_video_card.dart';
import 'package:challo/widgets/featuredlinkcard.dart';
import 'package:challo/widgets/gradient_icon.dart';
import 'package:challo/widgets/updownvotewidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:challo/variables.dart';
import 'package:in_app_review/in_app_review.dart';
import 'dart:async';
import 'dart:io';
import 'package:timeago/timeago.dart' as tago;
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class FeedPage extends StatefulWidget {
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage>
    with AutomaticKeepAliveClientMixin {
  final GlobalKey<ScaffoldState> _feedKey = GlobalKey();

  String? onlineuid, onlineusername, onlinepic, onlinename;
  Timer? timer;
  int currentPage = 0;
  final int _totalPages = 3;
  bool? whetherblocked;
  bool? whetherupdate;
  bool litsLoaded = false;
  bool feedloaded = false;
  bool homeloaded = false;
  bool firsttestfinished = false;
  bool stoploading = false;
  bool whethercontentreportsubmitted = false;
  int? selectedContentRadioNo = 1;
  String contentReportReason = 'Spam or misleading';
  List<String> blockedusers = [];
  List<String> hiddenusers = [];
  List<String> blockedcommunities = [];
  List<String> followingCommunities = [];
  late Stream<QuerySnapshot> communityStream;
  bool whethercommunitiesloaded = false;
  bool inAppReviewDisplayed = true;
  bool linkDataLoading = false;

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateRandomDocName(String username) {
    String newDocName = (username + getRandomString(5));
    return newDocName;
  }

  //dynamic linking

  //for LITS data
  late Future<QuerySnapshot> litsSnapshots;

  Future<void> _pulltoRefreshFeed() async {
    setState(
      () {
        loadfeed().then(
          (_) => {
            loadLits(),
          },
        );
      },
    );
  }

  Future<void> _pulltoRefreshHome() async {
    setState(() {
      loadfeed()
          .then((_) => {
                loadLits(),
              })
          .then((_) => {
                loadHome(),
              });
    });
  }

  firstInternetCheck() async {
    try {
      final result = await InternetAddress.lookup('duckduckgo.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        setState(() {
          connected = true;
          stoploading = true;
        });
      }
    } on SocketException catch (_) {
      print('not connected');
      setState(() {
        connected = false;
        stoploading = false;
      });
      if (noInternetDisplayed == false) {
        setState(() {
          noInternetDisplayed = true;
        });
        noInternetAlert();
      }
    }
    firsttestfinished = true;
    print("status of first test: $firsttestfinished");
  }

  checkInternet() async {
    try {
      final result = await InternetAddress.lookup('duckduckgo.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        setState(() {
          connected = true;
          stoploading = true;
        });
      }
    } on SocketException catch (_) {
      print('not connected');
      setState(() {
        connected = false;
        stoploading = false;
      });
      if (noInternetDisplayed == false) {
        setState(() {
          noInternetDisplayed = true;
        });
        noInternetAlert();
      }
    }
  }

  noInternetAlert() {
    print("No internet connectivity");
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text('Connection Failed!',
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                      color: Colors.white,
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold)),
              content: Text(
                  'Unable to connect to Internet. Please check your connection and try again!',
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        color: Colors.white70,
                        fontSize: 14.0,
                      )),
              actions: <Widget>[
                // usually buttons at the bottom of the dialog
                new TextButton(
                  //highlightColor: Colors.white,
                  child: const Text("Okay",
                      style: TextStyle(color: kPrimaryColorTint2)),
                  onPressed: () {
                    setState(() {
                      noInternetDisplayed = false;
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          );
        });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget offlineWidget() {
    return Center(
      child: Container(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("assets/images/loading-image.png"),
              Text(
                "You're offline...",
                style: Theme.of(context).textTheme.displayMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.0,
                    ),
              ),
              const SizedBox(
                height: 10.0,
              ),
              Text(
                "Your feed will be ready when you are connected.",
                style: Theme.of(context).textTheme.caption!.copyWith(
                      color: Colors.grey.shade800,
                    ),
              ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: CupertinoActivityIndicator(
                    color: kDarkPrimaryColor,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future loadfeed() async {
    print("Getting feed data");

    onlineuid = FirebaseAuth.instance.currentUser!.uid;

    var onlineuserdoc = await usercollection.doc(onlineuid).get();

    onlineusername = onlineuserdoc['username'];

    onlinepic = onlineuserdoc['profilepic'];

    onlinename = onlineuserdoc['name'];

    blockedusers = List.from(onlineuserdoc['blockedusers']);
    hiddenusers = List.from(onlineuserdoc['hiddenusers']);
    blockedcommunities = List.from(onlineuserdoc['blockedcommunities']);

    inAppReviewDisplayed = onlineuserdoc['inAppReviewDisplayed'];

    if (!mounted) return;
    setState(() {
      feedloaded = true;
    });
  }

  Future loadLits() async {
    print("Getting Lits data");

    litsSnapshots = litscollection.orderBy('trendingpriority').get();
    if (!mounted) return;
    setState(() {
      litsLoaded = true;
    });
  }

  Future loadCommunities() async {
    communityStream = communitycollection
        .where('featuredpriority', isGreaterThan: 100)
        .orderBy('featuredpriority', descending: true)
        .snapshots();
    if (!mounted) return;
    setState(() {
      whethercommunitiesloaded = true;
    });
  }

  Future loadHome() async {
    await usercollection
        .doc(onlineuid)
        .collection('communities')
        .get()
        .then((value) {
      for (var element in value.docs) {
        followingCommunities.add(element.id);
      }
    });

    if (!mounted) return;
    setState(() {
      homeloaded = true;
    });
  }

  checkMaintenanceorUpdate() async {
    print("Getting maintencance or update details");
    var updatedocs = await FirebaseFirestore.instance
        .collection('setupinfo')
        .doc(appVersionName)
        .get();

    whetherblocked = updatedocs['blockUsage'];
    print("Status on whether this version is blocked: $whetherblocked");

    whetherupdate = updatedocs['updateWarning'];
    print("Status on whether app should be updated: $whetherupdate");

    if (whetherblocked == true) {
      maintenanceorUpdateAlert('maintenance');
    } else if (whetherupdate == true) {
      maintenanceorUpdateAlert('update');
    }
  }

  maintenanceorUpdateAlert(String reason) {
    print("App in maintenance mode");
    return showDialog(
        barrierDismissible: false,
        context: context,
        builder: (BuildContext context) {
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: (reason == 'maintenance')
                  ? Text('App under maintenance',
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold))
                  : Text('New update',
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold)),
              content: (reason == 'maintenance')
                  ? Text(
                      'Sorry for the inconvenience, but Challo is undergoing some maintenance. Please check back later! :)',
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: Colors.white70,
                            fontSize: 14.0,
                          ))
                  : Text(
                      "A new and improved version of Challo is available for download. Please update to continue using the app.",
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            color: Colors.white70,
                            fontSize: 14.0,
                          )),
              actions: (reason == 'maintenance')
                  ? null
                  : <Widget>[
                      new TextButton(
                        ////highlightColor: Colors.white,
                        child: const Text("Update",
                            style: TextStyle(color: kPrimaryColorTint2)),
                        onPressed: () {
                          final InAppReview inAppReview = InAppReview.instance;
                          inAppReview.openStoreListing(
                              appStoreId: '1611176469');
                        },
                      ),
                    ],
            ),
          );
        });
  }

  List<Widget> buildPageIndicator() {
    List<Widget> list = [];
    for (var i = 0; i < _totalPages; i++) {
      list.add(buildIndicator(i == currentPage));
    }
    return list;
  }

  Widget buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: 8,
      decoration: BoxDecoration(
        color: isActive ? kHeadlineColorDark : kIconSecondaryColorDark,
        shape: BoxShape.circle,
      ),
    );
  }

  contentReportSubmit(String? docName, String? type, List participateduids,
      String reason) async {
    await contentcollection.doc(docName).update({
      'blockedby': FieldValue.arrayUnion([onlineuid])
    });

    for (String uid in participateduids) {
      var contentdocs = await usercollection
          .doc(uid)
          .collection('content')
          .doc(docName)
          .get();

      if (!contentdocs.exists) {
      } else {
        await usercollection
            .doc(uid)
            .collection('content')
            .doc(docName)
            .update({
          'blockedby': FieldValue.arrayUnion([onlineuid])
        });
      }
    }

    await contentreportcollection
        .doc(generateRandomDocName(onlineusername!))
        .set({
      'type': type,
      'status': 'reported', //reported -> deleted/noaction/pending
      'reporter': onlineuid,
      'docName': docName,
      'reason': reason,
      'time': DateTime.now(),
    });
  }

  unblockReportedContent(
      String? docName, String? type, List<String> participateduids) async {
    await contentcollection.doc(docName).update({
      'blockedby': FieldValue.arrayRemove([onlineuid])
    });
    for (String uid in participateduids) {
      var contentdocs = await usercollection
          .doc(uid)
          .collection('content')
          .doc(docName)
          .get();

      if (!contentdocs.exists) {
      } else {
        await usercollection
            .doc(uid)
            .collection('content')
            .doc(docName)
            .update({
          'blockedby': FieldValue.arrayRemove([onlineuid])
        });
      }
    }
  }

  hiddenreminderSheet(String whyblocked, String? docName, String? type,
      List<String> participateduids) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            height: (MediaQuery.of(context).size.height) / 4,
            width: (MediaQuery.of(context).size.width),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.block_outlined,
                    size: 30,
                    color: Colors.redAccent,
                  ),
                  (whyblocked == 'reported')
                      ? Text(
                          "This post is hidden for you because you've chosen to report or block it.",
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1!
                              .copyWith(color: Colors.white))
                      : (whyblocked == 'blocked')
                          ? Text(
                              "This post is hidden for you because you've blocked the creator(s).",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(color: Colors.white))
                          : Text(
                              "This post is hidden because the creator(s) may have set viewership restrictions.",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(color: Colors.white)),
                  (whyblocked == 'reported')
                      ? TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            unblockReportedContent(
                                docName, type, participateduids);
                          },
                          child: Text("Show anyway",
                              style: Theme.of(context)
                                  .textTheme
                                  .button!
                                  .copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryColor,
                                      fontSize: 15.0)),
                        )
                      : Container(),
                ],
              ),
            ),
          );
        });
  }

  reportContentSheet(String? docName, String? type, List participateduids) {
    showModalBottomSheet(
        useRootNavigator: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalsetState) {
            return Container(
              color: kBackgroundColorDark2,
              child: (whethercontentreportsubmitted == false)
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: [
                          Text(
                            "Report content",
                            style:
                                Theme.of(context).textTheme.headline2!.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: kHeadlineColorDark,
                                      letterSpacing: -0.41,
                                    ),
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
                                    contentReportSubmit(docName, type,
                                        participateduids, contentReportReason);
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
                                      color: kHeadlineColorDark,
                                      fontSize: 15.0),
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

  showDeleteConfirmation(docName) {
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
                  .doc(onlineuid)
                  .collection('content')
                  .where('docName', isEqualTo: docName)
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
              }).then(
                (_) async => {
                  await contentcollection.doc(docName).update(
                    {
                      'status': 'deleted',
                    },
                  ),
                },
              );
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

  bool blockedListsComparison(List<String> firstList, List<String> secondList) {
    if (secondList.every((item) => firstList.contains(item))) {
      return true;
    } else {
      return false;
    }
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

  Widget trendingPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: contentcollection
          .where('trendingpriority', isGreaterThan: 0)
          .orderBy('trendingpriority', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting trending content");
          return const Center(
            child: CupertinoActivityIndicator(
              color: kDarkPrimaryColor,
            ),
          );
        }
        if (snapshot.data.docs.length == 0) {
          return Center(child: Container());
        }
        return ListView.builder(
          reverse: false,
          physics: const NeverScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: snapshot.data.docs.length,
          itemBuilder: (BuildContext context, int index) {
            var video = snapshot.data.docs[index];

            if (((video['type'] == 'QnA') ||
                    (video['type'] == 'Debate') ||
                    (video['type'] == 'Podcast')) &&
                (video['status'] == 'published') &&
                (!video['blockedby'].contains(onlineuid)) &&
                (!List.from(video['participateduids'])
                    .any((e) => blockedusers.contains(e))) &&
                (!List.from(video['participateduids'])
                    .any((e) => hiddenusers.contains(e)))) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 5.0, color: kBackgroundColorDark2),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    (video['whetherlive'] == false)
                        ? Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerPage(
                                whetherjustcreated: false,
                                docName: video['docName'],
                                showcomments: false,
                              ),
                              fullscreenDialog: true,
                            ),
                          )
                        : Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AudiencePage(
                                  docName: video['docName'],
                                  role: ClientRole.Audience),
                              fullscreenDialog: true,
                            ),
                          );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                      bottom: 5.0,
                    ),
                    child: Column(
                      children: [
                        FeaturedLiveCard(
                          topic: video['topic'],
                          status: video['status'],
                          participatedusernames: video['participatedusernames'],
                          participatedpics: video['participatedpics'],
                          whethercommunitypost: video['whethercommunitypost'],
                          communityname: video['communityName'],
                          communitypic: video['communitypic'],
                          type: video['type'],
                          opuid: video['whostarted'],
                          onlineuid: onlineuid,
                          opusername: video['opusername'],
                          oppic: video['oppic'],
                          userInfoClicked: () {
                            if (video['whethercommunitypost'] == true) {
                              showCommunityQuickInfo(video['communityName'],
                                  video['opusername'], video['whostarted']);
                            } else {
                              showUserQuickInfo(
                                  video['opusername'], video['whostarted']);
                            }
                          },
                          timeofposting: video['time'],
                          onReport: () {
                            showPostOptionsForViewers(video['docName'],
                                video['type'], video['participateduids']);
                          },
                          onDelete: () {
                            showPostOptionsForOP(
                              video['whostarted'],
                              video['opusername'],
                              video['oppic'],
                              video['docName'],
                              video['whethercommunitypost'],
                              video['communityName'],
                              video['communitypic'],
                              video['type'],
                              video['participateduids'],
                              [],
                            );
                          },
                        ),
                        const SizedBox(height: 10.0),
                        UpDownVoteWidget(
                          whetherUpvoted: video['likes'].contains(onlineuid),
                          whetherDownvoted:
                              video['dislikes'].contains(onlineuid),
                          onUpvoted: () {
                            upvoteContent(video['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(video['docName']);
                          },
                          onShared: () => ShareService.shareContent(
                              video['docName'],
                              'streampost',
                              video['topic'],
                              video['description'],
                              ''),
                          upvoteCount: (video['likes']).length,
                          downvoteCount: (video['dislikes']).length,
                          commentCount: video['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            (video['whetherlive'] == false)
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerPage(
                                        whetherjustcreated: false,
                                        docName: video['docName'],
                                        showcomments: true,
                                      ),
                                      fullscreenDialog: true,
                                    ),
                                  )
                                : Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AudiencePage(
                                          docName: video['docName'],
                                          role: ClientRole.Audience),
                                      fullscreenDialog: true,
                                    ),
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else if ((video['type'] == 'linkpost') &&
                (video['status'] == 'published') &&
                (!video['blockedby'].contains(onlineuid)) &&
                (!blockedcommunities.contains(video['communityName'])) &&
                (!blockedusers.contains(video['opuid'])) &&
                (!hiddenusers.contains(video['opuid']))) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 5.0, color: kBackgroundColorDark2),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LinkPage(
                          docName: video['docName'],
                          whetherjustcreated: false,
                          showcomments: false,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                      bottom: 5.0,
                    ),
                    child: Column(
                      children: [
                        FeaturedLinkCard(
                          userInfoClicked: () {
                            if (video['whethercommunitypost'] == true) {
                              showCommunityQuickInfo(video['communityName'],
                                  video['opusername'], video['opuid']);
                            } else {
                              showUserQuickInfo(
                                  video['opusername'], video['opuid']);
                            }
                          },
                          whethercommunitypost: video['whethercommunitypost'],
                          communityname: video['communityName'],
                          communitypic: video['communitypic'],
                          onlineuid: onlineuid,
                          opuid: video['opuid'],
                          opusername: video['opusername'],
                          oppic: video['oppic'],
                          image: video['image'],
                          topic: video['topic'],
                          timeofposting: video['time'],
                          domainname: video['domainname'],
                          launchBrowser: () async {
                            print("opening link in browser");
                            openBrowserURL(url: video['link']);
                          },
                          onReport: () {
                            showPostOptionsForViewers(
                              video['docName'],
                              video['type'],
                              ['${video['opuid']}'],
                            );
                          },
                          onDelete: () {
                            showPostOptionsForOP(
                              video['opuid'],
                              video['opusername'],
                              video['oppic'],
                              video['docName'],
                              video['whethercommunitypost'],
                              video['communityName'],
                              video['communitypic'],
                              video['type'],
                              ['${video['opuid']}'],
                              [video['link']],
                            );
                            /*deleteContentSheet(
                                video['opuid'],
                                video['docName'],
                                video['whethercommunitypost'],
                                video['communityName']);*/
                          },
                          onEdit: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostLink(
                                  url: video['link'],
                                  whetherediting: true,
                                  whetherfrompost: false,
                                  docName: video['docName'],
                                  whethercommunitypost:
                                      video['whethercommunitypost'],
                                  communityName: video['communityName'],
                                  communityPic: video['communitypic'],
                                  onlineuser: UserInfoModel(
                                    uid: video['opuid'],
                                    pic: video['oppic'],
                                    username: video['opusername'],
                                  ),
                                ),
                                fullscreenDialog: true,
                              ),
                            ).then((whetheredited) => (whetheredited != null)
                                ? setState(() {
                                    loadfeed().then((_) => {
                                          loadLits(),
                                        });
                                    print("updating post...");
                                  })
                                : null);
                          },
                        ),
                        const SizedBox(height: 10.0),
                        UpDownVoteWidget(
                          whetherUpvoted: video['likes'].contains(onlineuid),
                          whetherDownvoted:
                              video['dislikes'].contains(onlineuid),
                          onUpvoted: () {
                            upvoteContent(video['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(video['docName']);
                          },
                          onShared: () => ShareService.shareContent(
                            video['docName'],
                            'linkpost',
                            video['topic'],
                            video['description'],
                            video['image'],
                          ),
                          upvoteCount: (video['likes']).length,
                          downvoteCount: (video['dislikes']).length,
                          commentCount: video['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            (video['type'] == 'linkpost')
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LinkPage(
                                        docName: video['docName'],
                                        whetherjustcreated: false,
                                        showcomments: true,
                                      ),
                                      fullscreenDialog: true,
                                    ),
                                  )
                                : Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerPage(
                                        whetherjustcreated: false,
                                        docName: video['docName'],
                                        showcomments: true,
                                      ),
                                      fullscreenDialog: true,
                                    ),
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else if ((video['type'] == 'textpost') &&
                (video['status'] == 'published') &&
                (!video['blockedby'].contains(onlineuid)) &&
                (!blockedcommunities.contains(video['communityName'])) &&
                (!blockedusers.contains(video['opuid'])) &&
                (!hiddenusers.contains(video['opuid']))) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 5.0, color: kBackgroundColorDark2),
                  ),
                ),
                child: InkWell(
                    onTap: () {
                      setState(() {
                        hidenav = true;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TextContentPage(
                            showcomments: false,
                            docName: video['docName'],
                            whetherjustcreated: false,
                          ),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 5.0,
                        right: 5.0,
                        bottom: 5.0,
                      ),
                      child: Column(
                        children: [
                          FeaturedTextCard(
                            userInfoClicked: () {
                              if (video['whethercommunitypost'] == true) {
                                showCommunityQuickInfo(video['communityName'],
                                    video['opusername'], video['opuid']);
                              } else {
                                showUserQuickInfo(
                                    video['opusername'], video['opuid']);
                              }
                            },
                            opuid: video['opuid'],
                            onlineuid: onlineuid,
                            onDelete: () {
                              showPostOptionsForOP(
                                video['opuid'],
                                video['opusername'],
                                video['oppic'],
                                video['docName'],
                                video['whethercommunitypost'],
                                video['communityName'],
                                video['communitypic'],
                                video['type'],
                                ['${video['opuid']}'],
                                [video['link']],
                              );
                            },
                            onTapImage: () {
                              setState(() {
                                hidenav = true;
                              });
                              AppBuilder.of(context)!.rebuild();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PreviewTextImage(
                                      whetherfromtextpost: false,
                                      docName: video['docName'],
                                      imageUrl: video['image'],
                                      onlineuid: onlineuid!,
                                    ),
                                    fullscreenDialog: true,
                                  ));
                            },
                            onReport: () {
                              showPostOptionsForViewers(
                                video['docName'],
                                video['type'],
                                ['${video['opuid']}'],
                              );
                            },
                            whethercommunitypost: video['whethercommunitypost'],
                            communityName: video['communityName'],
                            communitypic: video['communitypic'],
                            opusername: video['opusername'],
                            oppic: video['oppic'],
                            image: video['image'],
                            topic: video['topic'],
                            description: video['description'],
                            timeofposting: video['time'],
                            onEdit: () {
                              setState(() {
                                hidenav = true;
                              });
                              AppBuilder.of(context)!.rebuild();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostText(
                                    whetherediting: true,
                                    whetherfrompost: false,
                                    docName: video['docName'],
                                    whethercommunitypost:
                                        video['whethercommunitypost'],
                                    communityName: video['communityName'],
                                    communitypic: video['communitypic'],
                                    onlineuser: UserInfoModel(
                                      uid: video['opuid'],
                                      pic: video['oppic'],
                                      username: video['opusername'],
                                    ),
                                  ),
                                  fullscreenDialog: true,
                                ),
                              ).then((whetheredited) => (whetheredited != null)
                                  ? setState(() {
                                      loadfeed().then((_) => {
                                            loadLits(),
                                          });
                                      print("updating post...");
                                    })
                                  : null);
                            },
                          ),
                          const SizedBox(height: 10.0),
                          UpDownVoteWidget(
                            whetherUpvoted: video['likes'].contains(onlineuid),
                            whetherDownvoted:
                                video['dislikes'].contains(onlineuid),
                            onUpvoted: () {
                              upvoteContent(video['docName']);
                            },
                            onDownvoted: () {
                              downvoteContent(video['docName']);
                            },
                            onShared: () => ShareService.shareContent(
                              video['docName'],
                              'textpost',
                              video['topic'],
                              video['description'],
                              video['image'],
                            ),
                            upvoteCount: (video['likes']).length,
                            downvoteCount: (video['dislikes']).length,
                            commentCount: video['commentcount'],
                            onComment: () {
                              setState(() {
                                hidenav = true;
                              });
                              AppBuilder.of(context)!.rebuild();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TextContentPage(
                                    showcomments: false,
                                    docName: video['docName'],
                                    whetherjustcreated: false,
                                  ),
                                  fullscreenDialog: true,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )),
              );
            } else if ((video['type'] == 'imagepost') &&
                (video['status'] == 'published') &&
                (!video['blockedby'].contains(onlineuid)) &&
                (!blockedcommunities.contains(video['communityName'])) &&
                (!blockedusers.contains(video['opuid'])) &&
                (!hiddenusers.contains(video['opuid']))) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 5.0, color: kBackgroundColorDark2),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImagePage2(
                          docName: video['docName'],
                          whetherjustcreated: false,
                          showcomments: false,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                      bottom: 5.0,
                    ),
                    child: Column(
                      children: [
                        featuredImageCard(
                          video['docName'], //docName
                          video['opuid'], //opuid
                          video['opusername'], //opusername
                          video['oppic'], //oppic
                          video['whethercommunitypost'], //whethercommunitypost
                          video['communityName'], //communityName
                          video['communitypic'], //communitypic
                          video['type'], //type
                          video['topic'], //topic
                          List.from(video['imageslist']), //imageslist
                          video['time'], //time
                        ),
                        const SizedBox(height: 10.0),
                        UpDownVoteWidget(
                          whetherUpvoted: video['likes'].contains(onlineuid),
                          whetherDownvoted:
                              video['dislikes'].contains(onlineuid),
                          onUpvoted: () {
                            upvoteContent(video['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(video['docName']);
                          },
                          onShared: () => ShareService.shareContent(
                            video['docName'],
                            'imagepost',
                            video['topic'],
                            video['description'],
                            List.from(video['imageslist'])[0],
                          ),
                          upvoteCount: (video['likes']).length,
                          downvoteCount: (video['dislikes']).length,
                          commentCount: video['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImagePage2(
                                  docName: video['docName'],
                                  whetherjustcreated: false,
                                  showcomments: false,
                                ),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else if ((video['type'] == 'videopost') &&
                (video['status'] == 'published') &&
                (!video['blockedby'].contains(onlineuid)) &&
                (!blockedcommunities.contains(video['communityName'])) &&
                (!blockedusers.contains(video['opuid'])) &&
                (!hiddenusers.contains(video['opuid']))) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 5.0, color: kBackgroundColorDark2),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NonliveVideoPlayer(
                          whetherjustcreated: false,
                          docName: video['docName'],
                          showcomments: false,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                      bottom: 5.0,
                    ),
                    child: Column(
                      children: [
                        FeaturedVideoCard(
                          thumbnailAspectRatio: video['thumbnailAspectRatio'],
                          userInfoClicked: () {
                            if (video['whethercommunitypost'] == true) {
                              showCommunityQuickInfo(video['communityName'],
                                  video['opusername'], video['opuid']);
                            } else {
                              showUserQuickInfo(
                                  video['opusername'], video['opuid']);
                            }
                          },
                          onlineuid: onlineuid!,
                          opuid: video['opuid'],
                          opusername: video['opusername'],
                          oppic: video['oppic'],
                          thumbnail: video['thumbnail'],
                          whethercommunitypost: video['whethercommunitypost'],
                          communityName: video['communityName'],
                          communitypic: video['communitypic'],
                          topic: video['topic'],
                          timeofposting: video['time'],
                          onReport: () {
                            showPostOptionsForViewers(
                              video['docName'],
                              video['type'],
                              ['${video['opuid']}'],
                            );
                          },
                          onDelete: () {
                            showPostOptionsForOP(
                              video['opuid'],
                              video['opusername'],
                              video['oppic'],
                              video['docName'],
                              video['whethercommunitypost'],
                              video['communityName'],
                              video['communitypic'],
                              video['type'],
                              ['${video['opuid']}'],
                              [video['link']],
                            );
                          },
                          onEdit: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: ((context) => UploadVideoPage(
                                          onlineuser: UserInfoModel(
                                            uid: video['opuid'],
                                            pic: video['oppic'],
                                            username: video['opusername'],
                                          ),
                                          whethercommunitypost:
                                              video['whethercommunitypost'],
                                          communityName: video['communityName'],
                                          communitypic: video['communitypic'],
                                          whetherediting: true,
                                          whetherfrompost: false,
                                          docName: video['docName'],
                                        )))).then(
                                (whetheredited) => (whetheredited != null)
                                    ? setState(() {
                                        loadfeed().then((_) => {
                                              loadLits(),
                                            });
                                        print("updating post...");
                                      })
                                    : null);
                          },
                        ),
                        const SizedBox(height: 10.0),
                        UpDownVoteWidget(
                          whetherUpvoted: video['likes'].contains(onlineuid),
                          whetherDownvoted:
                              video['dislikes'].contains(onlineuid),
                          onUpvoted: () {
                            upvoteContent(video['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(video['docName']);
                          },
                          onShared: () => ShareService.shareContent(
                            video['docName'],
                            'videopost',
                            video['topic'],
                            video['description'],
                            video['thumbnail'],
                          ),
                          upvoteCount: (video['likes']).length,
                          downvoteCount: (video['dislikes']).length,
                          commentCount: video['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NonliveVideoPlayer(
                                  docName: video['docName'],
                                  showcomments: true,
                                  whetherjustcreated: false,
                                ),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Container();
            }
          },
        );
      },
    );
  }

  Widget personalizedPostsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: contentcollection
          .where('trendingpriority', isGreaterThan: 0)
          .orderBy('trendingpriority', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting trending content");
          return const Center(
            child: CupertinoActivityIndicator(
              color: kDarkPrimaryColor,
            ),
          );
        }
        if (snapshot.data.docs.length == 0) {
          return Center(child: Container());
        }
        return ListView.builder(
          reverse: false,
          physics: const AlwaysScrollableScrollPhysics(),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: snapshot.data.docs.length,
          itemBuilder: (BuildContext context, int index) {
            var video = snapshot.data.docs[index];

            if (((video['type'] == 'QnA') ||
                    (video['type'] == 'Debate') ||
                    (video['type'] == 'Podcast')) &&
                (video['status'] == 'published') &&
                (followingCommunities.contains(video['communityName'])) &&
                (!video['blockedby'].contains(onlineuid)) &&
                (!List.from(video['participateduids'])
                    .any((e) => blockedusers.contains(e))) &&
                (!List.from(video['participateduids'])
                    .any((e) => hiddenusers.contains(e)))) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 5.0, color: kBackgroundColorDark2),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    (video['whetherlive'] == false)
                        ? Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoPlayerPage(
                                whetherjustcreated: false,
                                docName: video['docName'],
                                showcomments: false,
                              ),
                              fullscreenDialog: true,
                            ),
                          )
                        : Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AudiencePage(
                                  docName: video['docName'],
                                  role: ClientRole.Audience),
                              fullscreenDialog: true,
                            ),
                          );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                      bottom: 5.0,
                    ),
                    child: Column(
                      children: [
                        FeaturedLiveCard(
                          topic: video['topic'],
                          status: video['status'],
                          participatedusernames: video['participatedusernames'],
                          participatedpics: video['participatedpics'],
                          whethercommunitypost: video['whethercommunitypost'],
                          communityname: video['communityName'],
                          communitypic: video['communitypic'],
                          type: video['type'],
                          opuid: video['whostarted'],
                          onlineuid: onlineuid,
                          opusername: video['opusername'],
                          oppic: video['oppic'],
                          userInfoClicked: () {
                            if (video['whethercommunitypost'] == true) {
                              showCommunityQuickInfo(video['communityName'],
                                  video['opusername'], video['whostarted']);
                            } else {
                              showUserQuickInfo(
                                  video['opusername'], video['whostarted']);
                            }
                          },
                          timeofposting: video['time'],
                          onReport: () {
                            showPostOptionsForViewers(video['docName'],
                                video['type'], video['participateduids']);
                          },
                          onDelete: () {
                            showPostOptionsForOP(
                              video['whostarted'],
                              video['opusername'],
                              video['oppic'],
                              video['docName'],
                              video['whethercommunitypost'],
                              video['communityName'],
                              video['communitypic'],
                              video['type'],
                              video['participateduids'],
                              [],
                            );
                          },
                        ),
                        const SizedBox(height: 10.0),
                        UpDownVoteWidget(
                          whetherUpvoted: video['likes'].contains(onlineuid),
                          whetherDownvoted:
                              video['dislikes'].contains(onlineuid),
                          onUpvoted: () {
                            upvoteContent(video['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(video['docName']);
                          },
                          onShared: () => ShareService.shareContent(
                              video['docName'],
                              'streampost',
                              video['topic'],
                              video['description'],
                              ''),
                          upvoteCount: (video['likes']).length,
                          downvoteCount: (video['dislikes']).length,
                          commentCount: video['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            (video['whetherlive'] == false)
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerPage(
                                        whetherjustcreated: false,
                                        docName: video['docName'],
                                        showcomments: true,
                                      ),
                                      fullscreenDialog: true,
                                    ),
                                  )
                                : Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AudiencePage(
                                          docName: video['docName'],
                                          role: ClientRole.Audience),
                                      fullscreenDialog: true,
                                    ),
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else if ((video['type'] == 'linkpost') &&
                (video['status'] == 'published') &&
                (followingCommunities.contains(video['communityName'])) &&
                (!video['blockedby'].contains(onlineuid)) &&
                (!blockedcommunities.contains(video['communityName'])) &&
                (!blockedusers.contains(video['opuid'])) &&
                (!hiddenusers.contains(video['opuid']))) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 5.0, color: kBackgroundColorDark2),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LinkPage(
                          docName: video['docName'],
                          whetherjustcreated: false,
                          showcomments: false,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                      bottom: 5.0,
                    ),
                    child: Column(
                      children: [
                        FeaturedLinkCard(
                          userInfoClicked: () {
                            if (video['whethercommunitypost'] == true) {
                              showCommunityQuickInfo(video['communityName'],
                                  video['opusername'], video['opuid']);
                            } else {
                              showUserQuickInfo(
                                  video['opusername'], video['opuid']);
                            }
                          },
                          whethercommunitypost: video['whethercommunitypost'],
                          communityname: video['communityName'],
                          communitypic: video['communitypic'],
                          onlineuid: onlineuid,
                          opuid: video['opuid'],
                          opusername: video['opusername'],
                          oppic: video['oppic'],
                          image: video['image'],
                          topic: video['topic'],
                          timeofposting: video['time'],
                          domainname: video['domainname'],
                          launchBrowser: () async {
                            print("opening link in browser");
                            openBrowserURL(url: video['link']);
                          },
                          onReport: () {
                            showPostOptionsForViewers(
                              video['docName'],
                              video['type'],
                              ['${video['opuid']}'],
                            );
                          },
                          onDelete: () {
                            showPostOptionsForOP(
                              video['opuid'],
                              video['opusername'],
                              video['oppic'],
                              video['docName'],
                              video['whethercommunitypost'],
                              video['communityName'],
                              video['communitypic'],
                              video['type'],
                              ['${video['opuid']}'],
                              [video['link']],
                            );
                            /*deleteContentSheet(
                                video['opuid'],
                                video['docName'],
                                video['whethercommunitypost'],
                                video['communityName']);*/
                          },
                          onEdit: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PostLink(
                                  url: video['link'],
                                  whetherediting: true,
                                  whetherfrompost: false,
                                  docName: video['docName'],
                                  whethercommunitypost:
                                      video['whethercommunitypost'],
                                  communityName: video['communityName'],
                                  communityPic: video['communitypic'],
                                  onlineuser: UserInfoModel(
                                    uid: video['opuid'],
                                    pic: video['oppic'],
                                    username: video['opusername'],
                                  ),
                                ),
                                fullscreenDialog: true,
                              ),
                            ).then((whetheredited) => (whetheredited != null)
                                ? setState(() {
                                    loadfeed().then((_) => {
                                          loadLits(),
                                        });
                                    print("updating post...");
                                  })
                                : null);
                          },
                        ),
                        const SizedBox(height: 10.0),
                        UpDownVoteWidget(
                          whetherUpvoted: video['likes'].contains(onlineuid),
                          whetherDownvoted:
                              video['dislikes'].contains(onlineuid),
                          onUpvoted: () {
                            upvoteContent(video['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(video['docName']);
                          },
                          onShared: () => ShareService.shareContent(
                            video['docName'],
                            'linkpost',
                            video['topic'],
                            video['description'],
                            video['image'],
                          ),
                          upvoteCount: (video['likes']).length,
                          downvoteCount: (video['dislikes']).length,
                          commentCount: video['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            (video['type'] == 'linkpost')
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LinkPage(
                                        docName: video['docName'],
                                        whetherjustcreated: false,
                                        showcomments: true,
                                      ),
                                      fullscreenDialog: true,
                                    ),
                                  )
                                : Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VideoPlayerPage(
                                        whetherjustcreated: false,
                                        docName: video['docName'],
                                        showcomments: true,
                                      ),
                                      fullscreenDialog: true,
                                    ),
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else if ((video['type'] == 'textpost') &&
                (video['status'] == 'published') &&
                (followingCommunities.contains(video['communityName'])) &&
                (!video['blockedby'].contains(onlineuid)) &&
                (!blockedcommunities.contains(video['communityName'])) &&
                (!blockedusers.contains(video['opuid'])) &&
                (!hiddenusers.contains(video['opuid']))) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 5.0, color: kBackgroundColorDark2),
                  ),
                ),
                child: InkWell(
                    onTap: () {
                      setState(() {
                        hidenav = true;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TextContentPage(
                            showcomments: false,
                            docName: video['docName'],
                            whetherjustcreated: false,
                          ),
                          fullscreenDialog: true,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 5.0,
                        right: 5.0,
                        bottom: 5.0,
                      ),
                      child: Column(
                        children: [
                          FeaturedTextCard(
                            userInfoClicked: () {
                              if (video['whethercommunitypost'] == true) {
                                showCommunityQuickInfo(video['communityName'],
                                    video['opusername'], video['opuid']);
                              } else {
                                showUserQuickInfo(
                                    video['opusername'], video['opuid']);
                              }
                            },
                            opuid: video['opuid'],
                            onlineuid: onlineuid,
                            onDelete: () {
                              showPostOptionsForOP(
                                video['opuid'],
                                video['opusername'],
                                video['oppic'],
                                video['docName'],
                                video['whethercommunitypost'],
                                video['communityName'],
                                video['communitypic'],
                                video['type'],
                                ['${video['opuid']}'],
                                [video['link']],
                              );
                            },
                            onTapImage: () {
                              setState(() {
                                hidenav = true;
                              });
                              AppBuilder.of(context)!.rebuild();
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PreviewTextImage(
                                      whetherfromtextpost: false,
                                      docName: video['docName'],
                                      imageUrl: video['image'],
                                      onlineuid: onlineuid!,
                                    ),
                                    fullscreenDialog: true,
                                  ));
                            },
                            onReport: () {
                              showPostOptionsForViewers(
                                video['docName'],
                                video['type'],
                                ['${video['opuid']}'],
                              );
                            },
                            whethercommunitypost: video['whethercommunitypost'],
                            communityName: video['communityName'],
                            communitypic: video['communitypic'],
                            opusername: video['opusername'],
                            oppic: video['oppic'],
                            image: video['image'],
                            topic: video['topic'],
                            description: video['description'],
                            timeofposting: video['time'],
                            onEdit: () {
                              setState(() {
                                hidenav = true;
                              });
                              AppBuilder.of(context)!.rebuild();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostText(
                                    whetherediting: true,
                                    whetherfrompost: false,
                                    docName: video['docName'],
                                    whethercommunitypost:
                                        video['whethercommunitypost'],
                                    communityName: video['communityName'],
                                    communitypic: video['communitypic'],
                                    onlineuser: UserInfoModel(
                                      uid: video['opuid'],
                                      pic: video['oppic'],
                                      username: video['opusername'],
                                    ),
                                  ),
                                  fullscreenDialog: true,
                                ),
                              ).then((whetheredited) => (whetheredited != null)
                                  ? setState(() {
                                      loadfeed().then((_) => {
                                            loadLits(),
                                          });
                                      print("updating post...");
                                    })
                                  : null);
                            },
                          ),
                          const SizedBox(height: 10.0),
                          UpDownVoteWidget(
                            whetherUpvoted: video['likes'].contains(onlineuid),
                            whetherDownvoted:
                                video['dislikes'].contains(onlineuid),
                            onUpvoted: () {
                              upvoteContent(video['docName']);
                            },
                            onDownvoted: () {
                              downvoteContent(video['docName']);
                            },
                            onShared: () => ShareService.shareContent(
                              video['docName'],
                              'textpost',
                              video['topic'],
                              video['description'],
                              video['image'],
                            ),
                            upvoteCount: (video['likes']).length,
                            downvoteCount: (video['dislikes']).length,
                            commentCount: video['commentcount'],
                            onComment: () {
                              setState(() {
                                hidenav = true;
                              });
                              AppBuilder.of(context)!.rebuild();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TextContentPage(
                                    showcomments: false,
                                    docName: video['docName'],
                                    whetherjustcreated: false,
                                  ),
                                  fullscreenDialog: true,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )),
              );
            } else if ((video['type'] == 'imagepost') &&
                (video['status'] == 'published') &&
                (followingCommunities.contains(video['communityName'])) &&
                (!video['blockedby'].contains(onlineuid)) &&
                (!blockedcommunities.contains(video['communityName'])) &&
                (!blockedusers.contains(video['opuid'])) &&
                (!hiddenusers.contains(video['opuid']))) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 5.0, color: kBackgroundColorDark2),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImagePage2(
                          showcomments: false,
                          docName: video['docName'],
                          whetherjustcreated: false,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                      bottom: 5.0,
                    ),
                    child: Column(
                      children: [
                        featuredImageCard(
                          video['docName'], //docName
                          video['opuid'], //opuid
                          video['opusername'], //opusername
                          video['oppic'], //oppic
                          video['whethercommunitypost'], //whethercommunitypost
                          video['communityName'], //communityName
                          video['communitypic'], //communitypic
                          video['type'], //type
                          video['topic'], //topic
                          List.from(video['imageslist']), //imageslist
                          video['time'], //time
                        ),
                        const SizedBox(height: 10.0),
                        UpDownVoteWidget(
                          whetherUpvoted: video['likes'].contains(onlineuid),
                          whetherDownvoted:
                              video['dislikes'].contains(onlineuid),
                          onUpvoted: () {
                            upvoteContent(video['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(video['docName']);
                          },
                          onShared: () => ShareService.shareContent(
                            video['docName'],
                            'imagepost',
                            video['topic'],
                            video['description'],
                            List.from(video['imageslist'])[0],
                          ),
                          upvoteCount: (video['likes']).length,
                          downvoteCount: (video['dislikes']).length,
                          commentCount: video['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImagePage2(
                                  showcomments: false,
                                  docName: video['docName'],
                                  whetherjustcreated: false,
                                ),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else if ((video['type'] == 'videopost') &&
                (video['status'] == 'published') &&
                (followingCommunities.contains(video['communityName'])) &&
                (!video['blockedby'].contains(onlineuid)) &&
                (!blockedcommunities.contains(video['communityName'])) &&
                (!blockedusers.contains(video['opuid'])) &&
                (!hiddenusers.contains(video['opuid']))) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(width: 5.0, color: kBackgroundColorDark2),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NonliveVideoPlayer(
                          whetherjustcreated: false,
                          docName: video['docName'],
                          showcomments: false,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                      bottom: 5.0,
                    ),
                    child: Column(
                      children: [
                        FeaturedVideoCard(
                          thumbnailAspectRatio: video['thumbnailAspectRatio'],
                          userInfoClicked: () {
                            if (video['whethercommunitypost'] == true) {
                              showCommunityQuickInfo(video['communityName'],
                                  video['opusername'], video['opuid']);
                            } else {
                              showUserQuickInfo(
                                  video['opusername'], video['opuid']);
                            }
                          },
                          onlineuid: onlineuid!,
                          opuid: video['opuid'],
                          opusername: video['opusername'],
                          oppic: video['oppic'],
                          thumbnail: video['thumbnail'],
                          whethercommunitypost: video['whethercommunitypost'],
                          communityName: video['communityName'],
                          communitypic: video['communitypic'],
                          topic: video['topic'],
                          timeofposting: video['time'],
                          onReport: () {
                            showPostOptionsForViewers(
                              video['docName'],
                              video['type'],
                              ['${video['opuid']}'],
                            );
                          },
                          onDelete: () {
                            showPostOptionsForOP(
                              video['opuid'],
                              video['opusername'],
                              video['oppic'],
                              video['docName'],
                              video['whethercommunitypost'],
                              video['communityName'],
                              video['communitypic'],
                              video['type'],
                              ['${video['opuid']}'],
                              [video['link']],
                            );
                          },
                          onEdit: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: ((context) => UploadVideoPage(
                                          onlineuser: UserInfoModel(
                                            uid: video['opuid'],
                                            pic: video['oppic'],
                                            username: video['opusername'],
                                          ),
                                          whethercommunitypost:
                                              video['whethercommunitypost'],
                                          communityName: video['communityName'],
                                          communitypic: video['communitypic'],
                                          whetherediting: true,
                                          whetherfrompost: false,
                                          docName: video['docName'],
                                        )))).then(
                                (whetheredited) => (whetheredited != null)
                                    ? setState(() {
                                        loadfeed().then((_) => {
                                              loadLits(),
                                            });
                                        print("updating post...");
                                      })
                                    : null);
                          },
                        ),
                        const SizedBox(height: 10.0),
                        UpDownVoteWidget(
                          whetherUpvoted: video['likes'].contains(onlineuid),
                          whetherDownvoted:
                              video['dislikes'].contains(onlineuid),
                          onUpvoted: () {
                            upvoteContent(video['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(video['docName']);
                          },
                          onShared: () => ShareService.shareContent(
                            video['docName'],
                            'videopost',
                            video['topic'],
                            video['description'],
                            video['thumbnail'],
                          ),
                          upvoteCount: (video['likes']).length,
                          downvoteCount: (video['dislikes']).length,
                          commentCount: video['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NonliveVideoPlayer(
                                  docName: video['docName'],
                                  showcomments: true,
                                  whetherjustcreated: false,
                                ),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Container();
            }
          },
        );
      },
    );
  }

  showPostOptionsForViewers(
      String? docName, String? type, List participateduids) {
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
              reportContentSheet(docName, type, participateduids);
            },
            child: Text(
              'Report Post',
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

  onEdit(
      String opuid,
      String opusername,
      String oppic,
      String docName,
      bool whethercommunitypost,
      String? communityName,
      String? communitypic,
      String type,
      List participateduids,
      List<String>? urls) {
    if (type == 'QnA') {
      setState(() {
        hidenav = true;
      });
      AppBuilder.of(context)!.rebuild();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QnAScreen1(
            onlineuser: UserInfoModel(
                uid: onlineuid, username: onlineusername, pic: onlinepic),
            whetherediting: true,
            whetherfrompost: false,
            docName: docName,
          ),
          fullscreenDialog: true,
        ),
      );
    } else if (type == 'Debate') {
      setState(() {
        hidenav = true;
      });
      AppBuilder.of(context)!.rebuild();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DebateScreen1(
            docName: docName,
            onlineuser: UserInfoModel(
                uid: onlineuid, username: onlineusername, pic: onlinepic),
            whetherediting: true,
            whetherfrompost: false,
            participateduids: participateduids,
          ),
          fullscreenDialog: true,
        ),
      );
    } else if (type == 'Podcast') {
      setState(() {
        hidenav = true;
      });
      AppBuilder.of(context)!.rebuild();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PodcastScreen1(
            onlineuser: UserInfoModel(
                uid: onlineuid, username: onlineusername, pic: onlinepic),
            whetherediting: true,
            whetherfrompost: false,
            docName: docName,
            participateduids: participateduids,
          ),
          fullscreenDialog: true,
        ),
      );
    } else if (type == 'linkpost') {
      setState(() {
        hidenav = true;
      });
      AppBuilder.of(context)!.rebuild();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostLink(
            url: urls![0],
            whetherediting: true,
            whetherfrompost: false,
            docName: docName,
            whethercommunitypost: whethercommunitypost,
            communityName: communityName,
            communityPic: communitypic,
            onlineuser: UserInfoModel(
              uid: opuid,
              pic: oppic,
              username: opusername,
            ),
          ),
          fullscreenDialog: true,
        ),
      );
      /*.then((whetheredited) => (whetheredited != null)
                    ? setState(() {
                        loadfeed();
                        print("updating post...");
                      })
                    : null);*/
    } else if (type == 'textpost') {
      setState(() {
        hidenav = true;
      });
      AppBuilder.of(context)!.rebuild();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostText(
            whetherediting: true,
            whetherfrompost: false,
            docName: docName,
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
      );
    } else if (type == 'imagepost') {
      setState(() {
        hidenav = true;
      });
      AppBuilder.of(context)!.rebuild();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostImage(
            whetherediting: true,
            whetherfrompost: false,
            docName: docName,
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
      );
    } else if (type == 'videopost') {
      setState(() {
        hidenav = true;
      });
      AppBuilder.of(context)!.rebuild();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UploadVideoPage(
            onlineuser: UserInfoModel(
              uid: onlineuid,
              username: onlineusername,
              pic: onlinepic,
            ),
            whethercommunitypost: whethercommunitypost,
            communityName: communityName,
            communitypic: communitypic,
            whetherediting: true,
            whetherfrompost: false,
            docName: docName,
          ),
          fullscreenDialog: true,
        ),
      );
    }
  }

  showPostOptionsForOP(
    String opuid,
    String opusername,
    String oppic,
    String docName,
    bool whethercommunitypost,
    String? communityName,
    String? communitypic,
    String type,
    List participateduids,
    List<String>? urls,
  ) {
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
              onEdit(opuid, opusername, oppic, docName, whethercommunitypost,
                  communityName, communitypic, type, participateduids, urls);
            },
            child: Text(
              'Edit Post',
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
              showDeleteConfirmation(docName);
            },
            child: Text(
              'Delete Post',
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

  Widget featuredImageCard(
    String docName,
    String opuid,
    String opusername,
    String oppic,
    bool whethercommunitypost,
    String? communityName,
    String? communitypic,
    String type,
    String topic,
    List<String> imageslist,
    var time,
  ) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5.0, top: 5.0, right: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () {
                    //userInfoCliked
                    if (whethercommunitypost == true) {
                      showCommunityQuickInfo(communityName!, opusername, opuid);
                    } else {
                      showUserQuickInfo(opusername, opuid);
                    }
                  },
                  child: Row(
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
                          backgroundColor: kIconSecondaryColorDark,
                          radius: 13.0,
                          backgroundImage: const AssetImage(
                              'assets/images/default-profile-pic.png'),
                          child: CircleAvatar(
                            radius: 13.0,
                            backgroundColor: Colors.transparent,
                            backgroundImage: (whethercommunitypost == true)
                                ? NetworkImage(communitypic!)
                                : NetworkImage(oppic),
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
                            (whethercommunitypost == true)
                                ? Text('c/$communityName',
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                          fontSize: 15.0,
                                          color: kHeadlineColorDark,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.24,
                                        ))
                                : Text(opusername,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                          fontSize: 15.0,
                                          color: kHeadlineColorDark,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.24,
                                        )),
                            (whethercommunitypost == true)
                                ? Text(
                                    "$opusername • ${tago.format(
                                      time.toDate(),
                                      locale: 'en_short',
                                    )} •",
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption!
                                        .copyWith(
                                          fontSize: 13.0,
                                          color: kSubTextColor,
                                          letterSpacing: -0.08,
                                        ),
                                  )
                                : Text(
                                    "• ${tago.format(
                                      time.toDate(),
                                      locale: 'en_short',
                                    )} •",
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption!
                                        .copyWith(
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
                (onlineuid == opuid)
                    ? InkWell(
                        onTap: () {
                          showPostOptionsForOP(
                            opuid,
                            opusername,
                            oppic,
                            docName,
                            whethercommunitypost,
                            communityName,
                            communitypic,
                            type,
                            [opuid],
                            imageslist,
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            color: kIconSecondaryColorDark,
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: () {
                          showPostOptionsForViewers(
                            docName,
                            type,
                            [opuid],
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            color: kIconSecondaryColorDark,
                          ),
                        ),
                      )

                /*PopupMenuButton<contentOptionsForOP>(
                        child: Container(
                          //color: Colors.red,
                          height: 20,
                          width: 20,
                          alignment: Alignment.centerRight,
                          child: const Icon(
                            Icons.more_vert_outlined,
                            size: 15,
                          ),
                        ),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Delete',
                                    style: Theme.of(context)
                                        .textTheme
                                        .button!
                                        .copyWith(
                                          color: Colors.white70,
                                          fontSize: 15,
                                        )),
                                const Icon(
                                  Icons.delete_outlined,
                                  size: 20,
                                )
                              ],
                            ),
                            value: contentOptionsForOP.delete,
                          ),
                          PopupMenuItem(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Edit',
                                    style: Theme.of(context)
                                        .textTheme
                                        .button!
                                        .copyWith(
                                          color: Colors.white70,
                                          fontSize: 15,
                                        )),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 20,
                                )
                              ],
                            ),
                            value: contentOptionsForOP.edit,
                          )
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case contentOptionsForOP.delete:
                              //onDelete();
                              deleteContentSheet(opuid, docName,
                                  whethercommunitypost, communityName);
                              break;
                            case contentOptionsForOP.edit:
                              setState(() {
                                hidenav = true;
                              });
                              AppBuilder.of(context)!.rebuild();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PostImage(
                                    whetherediting: true,
                                    whetherfrompost: false,
                                    docName: docName,
                                    whethercommunitypost: whethercommunitypost,
                                    communityName: communityName,
                                    communitypic: communitypic,
                                    onlineuser: UserInfoModel(
                                      uid: opuid,
                                      pic: oppic,
                                      username: opusername,
                                    ),
                                  ),
                                  fullscreenDialog: true,
                                ),
                              ).then((whetheredited) => {
                                    if (whetheredited != null)
                                      {
                                        setState(() {
                                          loadfeed();
                                        }),
                                      }
                                    else
                                      {}
                                  });
                              break;
                          }
                        },
                      )
                    : PopupMenuButton<contentOptions>(
                        child: Container(
                          //color: Colors.red,
                          height: 20,
                          width: 20,
                          alignment: Alignment.centerRight,
                          child: const Icon(
                            Icons.more_vert_outlined,
                            size: 15,
                          ),
                        ),
                        itemBuilder: (BuildContext context) => [
                          PopupMenuItem(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Report',
                                    style: Theme.of(context)
                                        .textTheme
                                        .button!
                                        .copyWith(
                                          color: Colors.white70,
                                          fontSize: 15,
                                        )),
                                const Icon(
                                  Icons.report_outlined,
                                  size: 20,
                                )
                              ],
                            ),
                            value: contentOptions.report,
                          )
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case contentOptions.report:
                              //onReport();
                              reportContentSheet(docName, type, [opuid]);
                              break;
                          }
                        },
                      )*/
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(
              topic,
              style: styleTitleSmall(),
            ),
          ),
          (imageslist.length > 1)
              ? Container(
                  height: 250,
                  width: double.infinity,
                  child: PageView.builder(
                    /*onPageChanged: (int page) {
                            index = page;
                          },*/
                    itemCount: imageslist.length,
                    itemBuilder: ((context, index) {
                      return Stack(children: [
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  hidenav = true;
                                });
                                AppBuilder.of(context)!.rebuild();
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: ((context) => PreviewImage(
                                              whetherfrompost: false,
                                              docName: docName,
                                              imageUrl: imageslist[index],
                                              onlineuid: onlineuid!,
                                            ))));
                              },
                              child: CachedNetworkImage(
                                imageUrl: imageslist[index],
                                progressIndicatorBuilder:
                                    (context, url, downloadProgress) =>
                                        const CupertinoActivityIndicator(
                                  color: kBackgroundColorDark2,
                                ),
                                imageBuilder: (context, imageProvider) =>
                                    Container(
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              //Image.network(imageslist[index]),
                            ),
                          ),
                        ),
                        Positioned(
                            child: Align(
                          alignment: Alignment.topCenter,
                          child: Card(
                            color: kCardBackgroundColor,
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Text(" $index/${imageslist.length - 1} "),
                            ),
                          ),
                        )),
                      ]);
                    }),
                  ),
                )
              : InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: ((context) => PreviewImage(
                                  whetherfrompost: false,
                                  docName: docName,
                                  imageUrl: imageslist[0],
                                  onlineuid: onlineuid!,
                                ))));
                  },
                  child: Container(
                    width: double.infinity,
                    child: CachedNetworkImage(
                      imageUrl: imageslist[0],
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) =>
                              const CupertinoActivityIndicator(
                        color: kBackgroundColorDark2,
                      ),
                    ),
                    //Image.network(imageslist[0]),
                  ),
                ),
        ],
      ),
    );
  }

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  upvoteContent(String? docName) async {
    var postdoc = await contentcollection.doc(docName).get();

    if (postdoc['likes'].contains(onlineuid)) {
      contentcollection.doc(docName).update({
        'likes': FieldValue.arrayRemove([onlineuid])
      });
    } else if (postdoc['dislikes'].contains(onlineuid)) {
      contentcollection.doc(docName).update({
        'dislikes': FieldValue.arrayRemove([onlineuid])
      });
      contentcollection.doc(docName).update({
        'likes': FieldValue.arrayUnion([onlineuid])
      });
    } else {
      contentcollection.doc(docName).update({
        'likes': FieldValue.arrayUnion([onlineuid])
      });
    }
  }

  downvoteContent(String? docName) async {
    var postdoc = await contentcollection.doc(docName).get();

    if (postdoc['dislikes'].contains(onlineuid)) {
      contentcollection.doc(docName).update({
        'dislikes': FieldValue.arrayRemove([onlineuid])
      });
    } else if (postdoc['likes'].contains(onlineuid)) {
      contentcollection.doc(docName).update({
        'likes': FieldValue.arrayRemove([onlineuid])
      });
      contentcollection.doc(docName).update({
        'dislikes': FieldValue.arrayUnion([onlineuid])
      });
    } else {
      contentcollection.doc(docName).update({
        'dislikes': FieldValue.arrayUnion([onlineuid])
      });
    }
  }

  logOut() async {
    try {
      FirebaseAuth firebase = FirebaseAuth.instance;
      await firebase.signOut();
    } catch (e) {
      print(e);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    initDynamicLink(context);

    if (stoploading == false) {
      firstInternetCheck();
    }

    loadfeed()
        .then(
          (_) => {
            loadLits(),
          },
        )
        .then(
          (_) => {
            loadHome(),
            loadCommunities(),
            showAppRating(),
          },
        );

    checkMaintenanceorUpdate();

    // following checks after every 10s
    timer = Timer.periodic(const Duration(seconds: 15), (Timer t) {
      checkInternet();
    });
  }

  Future<void> initDynamicLink(BuildContext context) async {
    if (preLinkedPage == null) {
      FirebaseDynamicLinks.instance.onLink.listen((dynamicLink) async {
        final Uri deepLink = dynamicLink.link;
        var isStory = deepLink.pathSegments.contains('linkToV1');
        if (isStory) {
          String docName = deepLink.queryParameters['docName'] ?? '';
          String linkType = deepLink.queryParameters['type'] ?? '';

          if (docName != '' && linkType != '') {
            try {
              print("pushing to linked post");
              setState(() {
                linkedPage = LinkTo(docName: docName, type: linkType);
              });
            } catch (e) {
              print("Error is ${e.toString()}");
            }
          }
        } else {
          //error
        }
      }).onError((error) {
        print("some error");
      });
    } else {
      setState(() {
        linkedPage = preLinkedPage;
      });
    }
  }

  Future showAppRating() async {
    if (inAppReviewDisplayed == false) {
      Future.delayed(const Duration(minutes: 5), () async {
        final InAppReview inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          Future.delayed(const Duration(seconds: 2), () async {
            if (whetherStreaming == false) {
              await usercollection.doc(onlineuid).update({
                'inAppReviewDisplayed': true,
              });
              inAppReview.requestReview();
            }
          });
        }
      });
    }
  }

  showFeedOptions() {
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
            //isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              Share.share(
                  "Challo is a one-stop-shop for live video discussions, news, pictures, and more. Join India's new social media app - https://challo.page.link/download");
            },
            child: Text(
              'Share App',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 20.0,
                    color: kPrimaryColorTint2,
                    fontStyle: FontStyle.normal,
                  ),
            ),
          ),
          CupertinoActionSheetAction(
            //isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => BugReport()));
            },
            child: Text(
              'Report Bug',
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
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ContactPage()));
            },
            child: Text(
              'Contact Us',
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
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const PoliciesPage()));
            },
            child: Text(
              'Read Policies',
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
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AccountSettings()));
            },
            child: Text(
              'Account Settings',
              style: Theme.of(context).textTheme.button!.copyWith(
                    fontSize: 20.0,
                    color: kPrimaryColorTint2,
                    fontStyle: FontStyle.normal,
                  ),
            ),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              logOut();
            },
            child: Text(
              'Log Out',
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

  Future<void> _pulltoRefreshCommunities() async {
    setState(() {
      whethercommunitiesloaded = false;
    });

    loadfeed()
        .then((_) => {
              loadLits(),
            })
        .then((_) => {
              loadCommunities(),
            });

    setState(() {
      whethercommunitiesloaded = true;
    });
  }

  Widget simpleDrawer() {
    return Drawer(
      backgroundColor: kBackgroundColorDark2,
      child: SafeArea(
          child: RefreshIndicator(
        onRefresh: _pulltoRefreshCommunities,
        child: (whethercommunitiesloaded == false)
            ? ListView(
                children: const [
                  Center(
                    child: CupertinoActivityIndicator(
                      color: kDarkPrimaryColor,
                    ),
                  )
                ],
              )
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: (whethercommunitiesloaded == false)
                      ? [
                          const Center(
                            child: CupertinoActivityIndicator(
                              color: kDarkPrimaryColor,
                            ),
                          )
                        ]
                      : [
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Challo v$appVersionName",
                              style: Theme.of(context)
                                  .textTheme
                                  .displaySmall!
                                  .copyWith(
                                    fontSize: 13.0,
                                    color: kSubTextColor,
                                    letterSpacing: -0.08,
                                  ),
                            ),
                          ),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 8.0,
                            ),
                            child: Text(
                              "Featured communities",
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium!
                                  .copyWith(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.w500,
                                    color: kHeadlineColorDark,
                                    letterSpacing: -0.24,
                                  ),
                            ),
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: communityStream,
                            builder:
                                (BuildContext context, AsyncSnapshot snapshot) {
                              if (!snapshot.hasData) {
                                print("loading communities...");
                                return const Center(
                                  child: CupertinoActivityIndicator(
                                    color: kDarkPrimaryColor,
                                  ),
                                );
                              }
                              if (snapshot.data.docs.length == 0) {
                                return Center(
                                    child: Container(
                                  child: Text(
                                    "No featured communities",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize: 15.0,
                                        ),
                                  ),
                                ));
                              }
                              return ListView.builder(
                                reverse: false,
                                physics: const NeverScrollableScrollPhysics(),
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                itemCount: snapshot.data.docs.length,
                                itemBuilder: (BuildContext context, int index) {
                                  var community = snapshot.data.docs[index];
                                  bool whetherjoined = (community['memberuids'])
                                      .contains(onlineuid);

                                  if (community['blockedby']
                                      .contains(onlineuid)) {
                                    return Container();
                                  } else {
                                    return InkWell(
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    CommunityPage(
                                                        whetherjustcreated:
                                                            false,
                                                        communityname:
                                                            community[
                                                                'name'])));
                                      },
                                      child: Card(
                                        color: kBackgroundColorDark,
                                        child: ListTile(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              5.0,
                                            ),
                                          ),
                                          leading: Container(
                                            decoration: new BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: kIconSecondaryColorDark,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  kIconSecondaryColorDark,
                                              radius: 20,
                                              backgroundImage: const AssetImage(
                                                  'assets/images/default-profile-pic.png'),
                                              child: CircleAvatar(
                                                radius: 20,
                                                backgroundColor:
                                                    Colors.transparent,
                                                backgroundImage: NetworkImage(
                                                  community['mainimage'],
                                                ),
                                              ),
                                            ),
                                          ),
                                          title: Text(
                                            "c/${community['name']}",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle1!
                                                .copyWith(
                                                  fontSize: 13.0,
                                                  color: kHeadlineColorDark,
                                                  fontWeight: FontWeight.w700,
                                                  letterSpacing: 0.3,
                                                ),
                                          ),
                                          subtitle: Text(
                                            "${community['description']}",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                            style: Theme.of(context)
                                                .textTheme
                                                .subtitle1!
                                                .copyWith(
                                                  fontSize: 11,
                                                  color: kSubTextColor,
                                                  letterSpacing: -0.08,
                                                ),
                                          ),
                                          trailing: IconButton(
                                            onPressed: () async {
                                              if (community['memberuids']
                                                  .contains(onlineuid)) {
                                                print(
                                                    "User already present; now removing...");
                                                //remove the user from community
                                                await communitycollection
                                                    .doc(community['name'])
                                                    .update({
                                                  'memberuids':
                                                      FieldValue.arrayRemove(
                                                          [onlineuid]),
                                                });
                                                var usercommunitydocs =
                                                    await usercollection
                                                        .doc(onlineuid)
                                                        .collection(
                                                            'communities')
                                                        .doc(community['name'])
                                                        .get();
                                                if (usercommunitydocs.exists) {
                                                  usercollection
                                                      .doc(onlineuid)
                                                      .collection('communities')
                                                      .doc(community['name'])
                                                      .delete();
                                                }
                                                setState(() {
                                                  followingCommunities.remove(
                                                      community['name']);
                                                });
                                              } else {
                                                var time = DateTime.now();
                                                //add user to community
                                                communitycollection
                                                    .doc(community['name'])
                                                    .update({
                                                  'memberuids':
                                                      FieldValue.arrayUnion(
                                                          [onlineuid])
                                                });
                                                var usercommunitydocs =
                                                    await usercollection
                                                        .doc(onlineuid)
                                                        .collection(
                                                            'communities')
                                                        .doc(community['name'])
                                                        .get();
                                                if (!usercommunitydocs.exists) {
                                                  usercollection
                                                      .doc(onlineuid)
                                                      .collection('communities')
                                                      .doc(community['name'])
                                                      .set({
                                                    'name': community['name'],
                                                    'mainimage':
                                                        community['mainimage'],
                                                    'backgroundimage':
                                                        community[
                                                            'backgroundimage'],
                                                    'joinedSince': time,
                                                    'description': community[
                                                        'description'],
                                                  });
                                                }
                                                setState(() {
                                                  followingCommunities
                                                      .add(community['name']);
                                                });
                                              }
                                            },
                                            icon: (whetherjoined == false)
                                                ? const Icon(
                                                    CupertinoIcons
                                                        .add_circled_solid,
                                                    color:
                                                        kIconSecondaryColorDark,
                                                  )
                                                : Stack(children: [
                                                    Positioned.fill(
                                                      child: Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: Colors.white,
                                                        ),
                                                        margin: const EdgeInsets
                                                            .all(3.0),
                                                      ),
                                                    ),
                                                    const Icon(
                                                      CupertinoIcons
                                                          .check_mark_circled_solid,
                                                      color: kPrimaryColor,
                                                    ),
                                                  ]),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(
                            height: 10.0,
                          ),
                          Align(
                            alignment: Alignment.center,
                            child: InkWell(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FeaturedCommunities(
                                          uid: onlineuid!))),
                              child: Text("See More >",
                                  style: Theme.of(context)
                                      .textTheme
                                      .button!
                                      .copyWith(color: kPrimaryColorTint2)),
                            ),
                          ),
                        ],
                ),
              ),
      )),
    );
  }

  Widget trendingLits() {
    return Container(
      height: 100,
      color: kBackgroundColorDark,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            height: 5.0,
          ),
          Row(
            children: [
              const SizedBox(
                width: 5.0,
              ),
              const GradientIcon(
                CupertinoIcons.flame_fill,
                20,
                LinearGradient(
                  colors: [
                    Colors.yellow,
                    Colors.purple,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.centerRight,
                ),
              ),
              const SizedBox(width: 2.0),
              Text(
                "Trending Lits",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontSize: 17.0,
                      letterSpacing: 0.41,
                      fontWeight: FontWeight.w600,
                      color: kHeadlineColorDark,
                    ),
              ),
              const SizedBox(width: 2.0),
              Text(
                "Beta",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontSize: 13.0,
                      letterSpacing: -0.08,
                      fontWeight: FontWeight.w400,
                      color: kBodyTextColorDark,
                    ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 10.0,
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddLits(
                            onlineuser: UserInfoModel(
                                uid: onlineuid,
                                username: onlineusername,
                                pic: onlinepic),
                            whetherEditing: false,
                            whetherFromPost: false),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(5.0),
                    child: Icon(
                      CupertinoIcons.add_circled_solid,
                      size: 30.0,
                      color: kPrimaryColorTint2,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 5.0,
                ),
                Expanded(
                  child: Padding(
                      padding: const EdgeInsets.all(
                        5.0,
                      ),
                      child: trendingLitsWidget()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  trendingLitsWidget() {
    return FutureBuilder<QuerySnapshot>(
      future: litsSnapshots,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CupertinoActivityIndicator(
              color: kDarkPrimaryColor,
            ),
          );
        }
        if (snapshot.data.docs.length == 0) {
          return Center(
            child: Container(),
          );
        }
        return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: snapshot.data.docs.length,
            itemBuilder: (BuildContext context, int index) {
              var lit = snapshot.data.docs[index];
              if ((lit['status'] != 'published') ||
                  (lit['blockedby'].contains(onlineuid))) {
                return Container();
              } else {
                return Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        hidenav = true;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LitsTimeline2(
                              docName: lit['docName'],
                              whetherJustCreated: false),
                          fullscreenDialog: true,
                        ),
                      ).then((popAnyChanges) async => {
                            if (popAnyChanges != null)
                              {
                                loadLits(),
                              }
                          });
                    },
                    child: CachedNetworkImage(
                      imageUrl: lit['image'],
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) =>
                              const CupertinoActivityIndicator(
                        color: kBackgroundColorDark2,
                      ),
                      imageBuilder: (context, imageProvider) => Container(
                        width: 100,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: Text(
                              lit['topic'],
                              style: styleTitleSmall(),
                            ),
                          ),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                      /*Container(
                      width: 100,
                      /* child: FittedBox(
                            fit: BoxFit.fill,
                            child: Image.network(
                              lit['image'],
                            ),
                          ),*/
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Text(
                            lit['topic'],
                            style: styleTitleSmall(),
                          ),
                        ),
                      ),
                      decoration: BoxDecoration(
                          //borderRadius: BorderRadius.circular(5),

                          image: DecorationImage(
                              image: CachedNetworkImageProvider(lit['image']),
                              //NetworkImage(lit['image']),
                              fit: BoxFit.fill)),
                    ),*/
                    ),
                  ),
                );
              }
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (linkedPage != null &&
        selectedTabIndex == 0 &&
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
          } else if (linkData.type == 'litspost') {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => LitsTimeline2(
                          docName: linkData.docName!,
                          whetherJustCreated: false,
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
        : (firsttestfinished == false)
            ? const Scaffold(
                body: SafeArea(
                  child: Center(
                    child: CupertinoActivityIndicator(
                      color: kDarkPrimaryColor,
                    ),
                  ),
                ),
              )
            : (stoploading == false)
                ? offlineWidget()
                : (feedloaded == false || litsLoaded == false)
                    ? const Scaffold(
                        body: SafeArea(
                          child: Center(
                            child: CupertinoActivityIndicator(
                              color: kDarkPrimaryColor,
                            ),
                          ),
                        ),
                      )
                    : DefaultTabController(
                        length: 2,
                        child: Scaffold(
                          key: _feedKey,
                          drawer: simpleDrawer(),
                          appBar: AppBar(
                            bottom: PreferredSize(
                              preferredSize: const Size.fromHeight(35),
                              child: TabBar(
                                  isScrollable: true,
                                  indicatorSize: TabBarIndicatorSize.label,
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .labelMedium!
                                      .copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15.0,
                                        color: kHeadlineColorDark,
                                        letterSpacing: -0.24,
                                      ),
                                  indicatorColor: kHeadlineColorDark,
                                  tabs: const [
                                    Tab(
                                      text: "Popular",
                                    ),
                                    Tab(
                                      text: "Home",
                                    ),
                                  ]),
                            ),
                            backgroundColor: kBackgroundColorDark2,
                            actions: [
                              InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () {
                                  /*setState(() {
                                hidenav = true;
                              });
                              AppBuilder.of(context)!.rebuild();*/
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: ((context) =>
                                              const ContentResults(
                                                  filterBy: 'Posts',
                                                  whetherretainsearch: false,
                                                  notonfirstpage: false,
                                                  searchedstring: ''))));
                                },
                                child: const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(
                                    Icons.search_outlined,
                                  ),
                                ),
                              ),
                              const SizedBox(
                                width: 10.0,
                              ),
                              InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => showFeedOptions(),
                                child: const Padding(
                                  padding: EdgeInsets.all(10.0),
                                  child: Icon(Icons.more_horiz),
                                ),
                              ),
                              const SizedBox(
                                width: 10.0,
                              ),
                            ],
                          ),
                          body: SafeArea(
                            child: TabBarView(children: [
                              RefreshIndicator(
                                onRefresh: _pulltoRefreshFeed,
                                child: ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    trendingLits(),
                                    trendingPostsList(),
                                  ],
                                ),
                              ),
                              RefreshIndicator(
                                onRefresh: _pulltoRefreshHome,
                                child: (homeloaded == false)
                                    ? ListView(
                                        physics:
                                            const AlwaysScrollableScrollPhysics(),
                                        children: const [
                                          Center(
                                            child: CupertinoActivityIndicator(
                                              color: kDarkPrimaryColor,
                                            ),
                                          ),
                                        ],
                                      )
                                    : (followingCommunities.isEmpty)
                                        ? ListView(
                                            children: [
                                              const SizedBox(
                                                height: 20.0,
                                              ),
                                              const Center(
                                                child: Text(
                                                    "You've not joined any communities."),
                                              ),
                                              Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                      10.0),
                                                  child: InkWell(
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                      Radius.circular(5),
                                                    ),
                                                    onTap: () => {
                                                      _feedKey.currentState!
                                                          .openDrawer()
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 15,
                                                          vertical: 6),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                          Radius.circular(5.0),
                                                        ),
                                                        border: Border.all(
                                                          width: 2.0,
                                                          color:
                                                              kPrimaryColorTint2,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'Show Featured Communities',
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .button!
                                                            .copyWith(
                                                              fontSize: 15.0,
                                                              color:
                                                                  kPrimaryColorTint2,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              //letterSpacing: 0.2,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : personalizedPostsList(),
                              ),
                            ]),
                          ),
                        ),
                      );
  }
}
