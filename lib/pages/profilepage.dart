import 'dart:async';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/pages/add_lits.dart';
import 'package:challo/helpers/share_service.dart';
import 'package:challo/models/link_to.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/account_settings.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/blockedcommunities.dart';
import 'package:challo/pages/blockedusers.dart';
import 'package:challo/pages/community_page.dart';
import 'package:challo/pages/debate_screen1.dart';
import 'package:challo/pages/edit_profile.dart';
import 'package:challo/pages/followers_page.dart';
import 'package:challo/pages/image_page_2.dart';
import 'package:challo/pages/linkpage.dart';
import 'package:challo/pages/lits_timeline_2.dart';
import 'package:challo/pages/nonlive_video_player.dart';
import 'package:challo/pages/podcast_screen1.dart';
import 'package:challo/pages/post_image.dart';
import 'package:challo/pages/post_text.dart';
import 'package:challo/pages/postlink.dart';
import 'package:challo/pages/preview_image.dart';
import 'package:challo/pages/preview_text_image.dart';
import 'package:challo/pages/qna_screen1.dart';
import 'package:challo/pages/text_content_page.dart';
import 'package:challo/pages/upload_video.dart';
import 'package:challo/pages/videoplayerpage.dart';
import 'package:challo/widgets/featured_live_card.dart';
import 'package:challo/widgets/featured_text_card.dart';
import 'package:challo/widgets/featured_video_card.dart';
import 'package:challo/widgets/featuredlinkcard.dart';
import 'package:challo/widgets/updownvotewidget.dart';
import 'package:challo/widgets/verifiedtick.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:challo/variables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:challo/pages/audiencepage.dart';
import 'package:timeago/timeago.dart' as tago;
import 'package:share/share.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class ProfilePage extends StatefulWidget {
  final String? uid; //this is the profile page of uid in question
  final bool whetherShowArrow;
  final bool? hideNavLinkReturn;
  const ProfilePage({
    this.uid,
    required this.whetherShowArrow,
    this.hideNavLinkReturn,
  });
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool linkDataLoading = false;

  String? username,
      email,
      name,
      onlineuid,
      onlineusername,
      onlinepic,
      onlinename,
      profilepic,
      bio,
      docName;
  String? livevideotopic, livevideotype, livelink;
  bool? liveportraitonly = false;
  dynamic livevideotime;
  late List<String> livevideopics;
  bool? isLive;
  late int followers;
  late int following;
  TextEditingController usernamecontroller = TextEditingController();
  bool isFollowing = false;
  bool dataisthere = false;
  Future<QuerySnapshot>? videoresult;
  int? videoslength;
  int? postslength;
  int? communitiesLength;
  Timer? timer;
  bool stoploading = false;
  bool firstcheckover = false;
  bool? profileverified = false;
  bool whetherblockrequested = false;
  bool whetherreportrequested = false;
  bool checkwhetherblocked = false;
  bool checkwhetherhidden = false;
  String userReportReason = 'Spams a lot';
  int? selectedReportRadioNo = 1;
  List<String> liveblockedbylist = [];
  List<String> blockedusers = [];
  List<String> hiddenusers = [];
  bool whethercontentreportsubmitted = false;
  int? selectedContentRadioNo = 1;
  String contentReportReason = "Spam or misleading";
  late String? accountStatus;
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateRandomDocName(String viewerusername) {
    String newDocName = (viewerusername + getRandomString(5));
    return newDocName;
  }

  late Future<QuerySnapshot> litsSnapshots;
  bool litsLoaded = false;

  final postScrollKey = new GlobalKey();

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
    getalldata().then((_) => {
          loadLits(),
        });
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

  Future<void> _pulltoRefreshProfile() async {
    setState(() {
      getalldata().then((_) => {
            loadLits(),
          });
    });
  }

  Future getalldata() async {
    //get online data
    onlineuid = FirebaseAuth.instance.currentUser!.uid;

    await usercollection.doc(onlineuid).get().then((onlineuserdoc) => {
          onlineusername = onlineuserdoc['username'],
          onlinepic = onlineuserdoc['profilepic'],
          onlinename = onlineuserdoc['name'],
          blockedusers = List.from(onlineuserdoc['blockedusers']),
          hiddenusers = List.from(onlineuserdoc['hiddenusers']),
        });

    if (blockedusers.contains(widget.uid)) {
      checkwhetherblocked = true;
    }

    if (hiddenusers.contains(widget.uid)) {
      checkwhetherhidden = true;
    }

    //get user data
    await usercollection.doc(widget.uid).get().then((userdoc) => {
          username = userdoc['username'],
          name = userdoc['name'],
          email = userdoc['email'],
          profilepic = userdoc['profilepic'],
          bio = userdoc['bio'],
          isLive = userdoc['isLive'],
          docName = userdoc['docName'],
          profileverified = userdoc['profileverified'],
          accountStatus = userdoc['accountStatus'],
        });

    //get followers and followings and check if already following
    var followersdocuments =
        await usercollection.doc(widget.uid).collection('followers').get();

    var followingdocuments =
        await usercollection.doc(widget.uid).collection('following').get();

    var videosdocuments =
        await usercollection.doc(widget.uid).collection('content').get();

    var postsdocuments =
        await usercollection.doc(widget.uid).collection('content').get();

    var communitiesDocuments =
        await usercollection.doc(widget.uid).collection('communities').get();

    followers = followersdocuments.docs.length;
    following = followingdocuments.docs.length;
    videoslength = videosdocuments.docs.length;
    postslength = postsdocuments.docs.length;
    communitiesLength = communitiesDocuments.docs.length;

    //check if already following
    await usercollection
        .doc(widget.uid)
        .collection('followers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((document) {
      if (!document.exists) {
        isFollowing = false;
      } else {
        isFollowing = true;
      }
    });

    if (isLive == true) {
      await contentcollection.doc(docName).get().then((channeldocs) => {
            liveblockedbylist = List.from(channeldocs['blockedby']),
            livevideotopic = channeldocs['topic'],
            livevideotype = channeldocs['type'],
            liveportraitonly = channeldocs['portraitonly'],
            livelink = channeldocs['link'],
            livevideotime = channeldocs['time'],
            livevideopics = List.from(channeldocs['participatedpics']),
          });
    }

    if (!mounted) return;
    setState(() {
      dataisthere = true;
    });
  }

  followuser() async {
    final time = DateTime.now();
    var document = await usercollection
        .doc(widget.uid)
        .collection('followers')
        .doc(onlineuid)
        .get();

    if (!document.exists) {
      usercollection
          .doc(widget.uid)
          .collection('followers')
          .doc(onlineuid)
          .set({
        'uid': onlineuid,
        'name': onlinename,
        'username': onlineusername,
        'profilepic': onlinepic,
        'followedOn': time,
      });

      usercollection
          .doc(onlineuid)
          .collection('following')
          .doc(widget.uid)
          .set({
        'uid': widget.uid,
        'name': name,
        'username': username,
        'profilepic': profilepic,
        'followingSince': time,
      });

      setState(() {
        isFollowing = true;
        followers++;
      });
    } else {
      usercollection
          .doc(widget.uid)
          .collection('followers')
          .doc(onlineuid)
          .delete();

      usercollection
          .doc(onlineuid)
          .collection('following')
          .doc(widget.uid)
          .delete();

      setState(() {
        isFollowing = false;
        followers--;
      });
    }
  }

  Widget liveNowWidget() {
    return InkWell(
      onTap: () {
        setState(() {
          hidenav = true;
        });
        AppBuilder.of(context)!.rebuild();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AudiencePage(
              role: ClientRole.Audience,
              docName: docName,
            ),
            fullscreenDialog: true,
          ),
        );
      },
      child: Card(
        color: Theme.of(context).primaryIconTheme.color,
        child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15.0),
            ),
            leading: (livevideopics.length == 1)
                ? Container(
                    decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      border: new Border.all(
                        color: kIconSecondaryColorDark,
                        width: 2.0,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey.shade500,
                      radius: 30,
                      backgroundImage: const AssetImage(
                          'assets/images/default-profile-pic.png'),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        backgroundImage: NetworkImage(livevideopics[0]),
                      ),
                    ),
                  )
                : (livevideopics.length == 2)
                    ? Container(
                        height: 60.0,
                        width: 60.0,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 20.0,
                              top: 15.0,
                              child: Container(
                                decoration: new BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: new Border.all(
                                    color: kIconSecondaryColorDark,
                                    width: 1.0,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey.shade500,
                                  radius: 19,
                                  backgroundImage: const AssetImage(
                                      'assets/images/default-profile-pic.png'),
                                  child: CircleAvatar(
                                    radius: 19,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        NetworkImage(livevideopics[1]),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              decoration: new BoxDecoration(
                                shape: BoxShape.circle,
                                border: new Border.all(
                                  color: kIconSecondaryColorDark,
                                  width: 1.0,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.grey.shade500,
                                radius: 19,
                                backgroundImage: const AssetImage(
                                    'assets/images/default-profile-pic.png'),
                                child: CircleAvatar(
                                  radius: 19,
                                  backgroundColor: Colors.transparent,
                                  backgroundImage:
                                      NetworkImage(livevideopics[0]),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        height: 60.0,
                        width: 60.0,
                        child: Stack(
                          children: [
                            Positioned(
                              //bottom
                              left: 15.0,
                              top: 22.0,
                              child: Container(
                                decoration: new BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: new Border.all(
                                    color: kIconSecondaryColorDark,
                                    width: 1.0,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey.shade500,
                                  radius: 16,
                                  backgroundImage: const AssetImage(
                                      'assets/images/default-profile-pic.png'),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        NetworkImage(livevideopics[2]),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              //pic at top right
                              left: 25.0,
                              child: Container(
                                decoration: new BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: new Border.all(
                                    color: kIconSecondaryColorDark,
                                    width: 1.0,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey.shade500,
                                  radius: 16,
                                  backgroundImage: const AssetImage(
                                      'assets/images/default-profile-pic.png'),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        NetworkImage(livevideopics[1]),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 25,
                              child: Container(
                                decoration: new BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: new Border.all(
                                    color: kIconSecondaryColorDark,
                                    width: 1.0,
                                  ),
                                ),
                                child: CircleAvatar(
                                  backgroundColor: Colors.grey.shade500,
                                  radius: 16,
                                  backgroundImage: const AssetImage(
                                      'assets/images/default-profile-pic.png'),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.transparent,
                                    backgroundImage:
                                        NetworkImage(livevideopics[0]),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
            title: Text(
              livevideotopic!,
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    fontSize: 15,
                    //fontWeight: FontWeight.bold,
                    color: kHeadlineColorDark,
                  ),
            ),
            subtitle: Row(
              children: [
                Text(
                  (livevideotype == 'QnA') ? "Q&A •" : "$livevideotype •",
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
                  tago.format(
                    livevideotime.toDate(),
                    locale: 'en_short',
                  ),
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        fontSize: 12,
                        //fontWeight: FontWeight.bold,
                        fontWeight: FontWeight.w900,
                        color: kBodyTextColorDark,
                      ),
                ),
              ],
            ),
            trailing: Container(
                padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
                decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                      fontSize: 14,
                      color: kHeadlineColorDark,
                      fontWeight: FontWeight.w900),
                ))),
      ),
    );
  }

  logOut() async {
    try {
      FirebaseAuth _firebase = FirebaseAuth.instance;
      await _firebase.signOut();
    } catch (e) {
      print(e);
    }
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

  deleteContentSheet(
    String opuid,
    String docName,
    bool whethercommunitypost,
    String? communityName,
  ) {
    showModalBottomSheet(
        context: context,
        builder: (builder) => Container(
              height: (MediaQuery.of(context).size.height) / 6,
              width: (MediaQuery.of(context).size.width),
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(children: [
                const Text('Are you sure you want to delete this post?',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: kHeadlineColorDark)),
                const SizedBox(height: 20),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            // icon: Icon(Icons.cancel_outlined, color: kPrimaryColor),
                            child: const Text("Cancel",
                                style: TextStyle(
                                  color: kPrimaryColor,
                                  fontWeight: FontWeight.bold,
                                ))),
                      ),
                      Container(
                        color: Colors.grey.shade500,
                        width: 0.5,
                        height: 22,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await usercollection
                                  .doc(opuid)
                                  .collection('content')
                                  .where('docName', isEqualTo: docName)
                                  .get()
                                  .then((value) {
                                for (var element in value.docs) {
                                  usercollection
                                      .doc(opuid)
                                      .collection('content')
                                      .doc(element.id)
                                      .delete()
                                      .then((value) {
                                    print("deleted from user profile");
                                  });
                                }
                              });

                              await contentcollection.doc(docName).update({
                                'status': 'deleted',
                              });

                              if (whethercommunitypost == true) {
                                await communitycollection
                                    .doc(communityName)
                                    .collection('content')
                                    .where('docName', isEqualTo: docName)
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
                                });
                              }
                            },
                            // icon: Icon(Icons.check_circle_outlined, color: kPrimaryColor),
                            child: const Text("Yes",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: kPrimaryColor,
                                ))),
                      )
                    ],
                  ),
                )
              ]),
            ));
  }

  showCommunityQuickInfo(String communityName) {
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

  Widget videosList() {
    return StreamBuilder<QuerySnapshot>(
      stream: usercollection
          .doc(widget.uid)
          .collection('content')
          .orderBy('time', descending: false)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting content");
          return const Center(
              child: CupertinoActivityIndicator(
            color: kDarkPrimaryColor,
          ));
        }
        if (snapshot.data.docs.length == 0) {
          return Center(child: Container());
        }
        return ListView.builder(
            reverse: true,
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: snapshot.data.docs.length,
            itemBuilder: (BuildContext context, int index) {
              var content = snapshot.data.docs[index];
              if (((content['type'] == 'QnA') ||
                      (content['type'] == 'Debate') ||
                      (content['type'] == 'Podcast')) &&
                  (!content['blockedby'].contains(onlineuid)) &&
                  (!List.from(content['participateduids'])
                      .any((e) => blockedusers.contains(e))) &&
                  (!List.from(content['participateduids'])
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerPage(
                            whetherjustcreated: false,
                            docName: content['docName'],
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
                          FeaturedLiveCard(
                            topic: content['topic'],
                            status:
                                'published', //all profile livestreams are publislhed
                            participatedusernames:
                                content['participatedusernames'],
                            participatedpics: content['participatedpics'],
                            whethercommunitypost:
                                content['whethercommunitypost'],
                            communityname: content['communityName'],
                            communitypic: content['communitypic'],
                            type: content['type'],
                            opuid: content['whostarted'],
                            onlineuid: onlineuid,
                            opusername: username,
                            oppic: profilepic,
                            userInfoClicked: () {
                              if (content['whethercommunitypost'] == true) {
                                showCommunityQuickInfo(
                                  content['communityName'],
                                );
                              }
                            },
                            timeofposting: content['time'],
                            onReport: () {
                              showPostOptionsForViewers(content['docName'],
                                  content['type'], content['participateduids']);
                            },
                            onDelete: () {
                              showPostOptionsForOP(
                                content['whostarted'],
                                content['opusername'],
                                content['oppic'],
                                content['docName'],
                                content['whethercommunitypost'],
                                content['communityName'],
                                content['communitypic'],
                                content['type'],
                                content['participateduids'],
                                [],
                              );
                            },
                          ),
                          const SizedBox(height: 10.0),
                          bottomlikecomment(content['docName'], 'streampost',
                              content['topic'], content['description'], ''),
                        ],
                      ),
                    ),
                  ),
                );

                /*InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VideoPlayerPage(
                            showcomments: false,
                            portraitonly: content['portraitonly'],
                            docName: content['docName'],
                            videourl: content['link'],
                            formattype: content['type']),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Card(
                    color: Theme.of(context).primaryIconTheme.color,
                    child: Column(
                      children: [
                        ListTile(
                          trailing: (onlineuid == widget.uid)
                              ? (content['participatedpics'].length == 1)
                                  ? ClipOval(
                                      child: Material(
                                        color:
                                            kHeadlineColorDark, // Button color
                                        child: InkWell(
                                          splashColor:
                                              Colors.red, // Splash color
                                          onTap: () {
                                            showModalBottomSheet(
                                                context: context,
                                                builder: (builder) {
                                                  return Container(
                                                    height:
                                                        (MediaQuery.of(context)
                                                                .size
                                                                .height) /
                                                            9,
                                                    width:
                                                        (MediaQuery.of(context)
                                                            .size
                                                            .width),
                                                    margin: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 20,
                                                        vertical: 20),
                                                    child: Column(children: [
                                                      const Text(
                                                        'Are you sure you want to delete this video?',
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            color:
                                                                kHeadlineColorDark),
                                                      ),
                                                      const SizedBox(
                                                          height: 20),
                                                      Expanded(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .all(
                                                                      10.0),
                                                              child: TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child: const Text(
                                                                    "Cancel",
                                                                    style: TextStyle(
                                                                        color:
                                                                            kPrimaryColor,
                                                                        fontWeight:
                                                                            FontWeight.bold)),
                                                              ),
                                                            ),
                                                            Container(
                                                              color: Colors
                                                                  .grey[500],
                                                              width: 0.5,
                                                              height: 22,
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .all(
                                                                      10.0),
                                                              child: TextButton(
                                                                  onPressed:
                                                                      () async {
                                                                    Navigator.pop(
                                                                        context);
                                                                    snapshot
                                                                        .data
                                                                        .docs[
                                                                            index]
                                                                        .reference
                                                                        .delete();

                                                                    await contentcollection
                                                                        .doc(
                                                                            '${content['docName']}')
                                                                        .update({
                                                                      'status':
                                                                          'deleted'
                                                                    });
                                                                  },
                                                                  child: const Text(
                                                                      "Yes",
                                                                      style: TextStyle(
                                                                          color:
                                                                              kPrimaryColor,
                                                                          fontWeight:
                                                                              FontWeight.bold))),
                                                            )
                                                          ],
                                                        ),
                                                      )
                                                    ]),
                                                  );
                                                });
                                          },
                                          child: SizedBox(
                                              width: 25,
                                              height: 25,
                                              child: Icon(
                                                Icons.delete,
                                                color:
                                                    Colors.red.withOpacity(0.8),
                                                size: 17.0,
                                              )),
                                        ),
                                      ),
                                    )
                                  : ClipOval(
                                      child: Material(
                                        color:
                                            kHeadlineColorDark, // Button color
                                        child: InkWell(
                                          splashColor:
                                              Colors.red, // Splash color
                                          onTap: () {
                                            showModalBottomSheet(
                                                context: context,
                                                builder: (builder) {
                                                  return Container(
                                                    height:
                                                        (MediaQuery.of(context)
                                                                .size
                                                                .height) /
                                                            9,
                                                    width:
                                                        (MediaQuery.of(context)
                                                            .size
                                                            .width),
                                                    margin: const EdgeInsets
                                                            .symmetric(
                                                        horizontal: 20,
                                                        vertical: 20),
                                                    child: Column(children: [
                                                      const Text(
                                                        'Are you sure you want to unlist this video?',
                                                        style: TextStyle(
                                                            fontSize: 15,
                                                            color:
                                                                kHeadlineColorDark,
                                                            fontWeight:
                                                                FontWeight
                                                                    .w500),
                                                      ),
                                                      const SizedBox(
                                                          height: 20),
                                                      Expanded(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .all(
                                                                      10.0),
                                                              child: TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  child: const Text(
                                                                      "Cancel",
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            kPrimaryColor,
                                                                      ))),
                                                            ),
                                                            Container(
                                                              color: Colors
                                                                  .grey[500],
                                                              width: 0.5,
                                                              height: 22,
                                                            ),
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                          .all(
                                                                      10.0),
                                                              child: TextButton(
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.pop(
                                                                        context);
                                                                    snapshot
                                                                        .data
                                                                        .docs[
                                                                            index]
                                                                        .reference
                                                                        .delete();
                                                                  },
                                                                  child: const Text(
                                                                      "Yes",
                                                                      style:
                                                                          TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            kPrimaryColor,
                                                                      ))),
                                                            )
                                                          ],
                                                        ),
                                                      )
                                                    ]),
                                                  );
                                                });
                                          },
                                          child: SizedBox(
                                              width: 25,
                                              height: 25,
                                              child: Icon(
                                                Icons.remove,
                                                color:
                                                    Colors.red.withOpacity(0.8),
                                                size: 20.0,
                                              )),
                                        ),
                                      ),
                                    )
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          leading: (content['participatedpics'].length == 1)
                              ? Container(
                                  decoration: new BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: new Border.all(
                                      color: kIconSecondaryColorDark,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.grey.shade500,
                                    radius: 30,
                                    backgroundImage: const AssetImage(
                                        'assets/images/default-profile-pic.png'),
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundColor: Colors.transparent,
                                      backgroundImage: NetworkImage(
                                          content['participatedpics'][0]),
                                    ),
                                  ),
                                )
                              : (content['participatedpics'].length == 2)
                                  ? Container(
                                      height: 60.0,
                                      width: 60.0,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            left: 20.0,
                                            top: 15.0,
                                            child: Container(
                                              decoration: new BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: new Border.all(
                                                  color:
                                                      kIconSecondaryColorDark,
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                backgroundColor:
                                                    Colors.grey.shade500,
                                                radius: 19,
                                                backgroundImage: const AssetImage(
                                                    'assets/images/default-profile-pic.png'),
                                                child: CircleAvatar(
                                                  radius: 19,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  backgroundImage: NetworkImage(
                                                      content['participatedpics']
                                                          [1]),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            decoration: new BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: new Border.all(
                                                color: kIconSecondaryColorDark,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  Colors.grey.shade500,
                                              radius: 19,
                                              backgroundImage: const AssetImage(
                                                  'assets/images/default-profile-pic.png'),
                                              child: CircleAvatar(
                                                radius: 19,
                                                backgroundColor:
                                                    Colors.transparent,
                                                backgroundImage: NetworkImage(
                                                    content['participatedpics']
                                                        [0]),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      height: 60.0,
                                      width: 60.0,
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            //bottom
                                            left: 15.0,
                                            top: 22.0,
                                            child: Container(
                                              decoration: new BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: new Border.all(
                                                  color:
                                                      kIconSecondaryColorDark,
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                backgroundColor:
                                                    Colors.grey.shade500,
                                                radius: 16,
                                                backgroundImage: const AssetImage(
                                                    'assets/images/default-profile-pic.png'),
                                                child: CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  backgroundImage: NetworkImage(
                                                      content['participatedpics']
                                                          [2]),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            //pic at top right
                                            left: 25.0,
                                            child: Container(
                                              decoration: new BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: new Border.all(
                                                  color:
                                                      kIconSecondaryColorDark,
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                backgroundColor:
                                                    Colors.grey.shade500,
                                                radius: 16,
                                                backgroundImage: const AssetImage(
                                                    'assets/images/default-profile-pic.png'),
                                                child: CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  backgroundImage: NetworkImage(
                                                      content['participatedpics']
                                                          [1]),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            right: 25,
                                            child: Container(
                                              decoration: new BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: new Border.all(
                                                  color:
                                                      kIconSecondaryColorDark,
                                                  width: 1.0,
                                                ),
                                              ),
                                              child: CircleAvatar(
                                                backgroundColor:
                                                    Colors.grey.shade500,
                                                radius: 16,
                                                backgroundImage: const AssetImage(
                                                    'assets/images/default-profile-pic.png'),
                                                child: CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor:
                                                      Colors.transparent,
                                                  backgroundImage: NetworkImage(
                                                      content['participatedpics']
                                                          [0]),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                          title: Text(
                            "${content['topic']}",
                            style:
                                Theme.of(context).textTheme.subtitle1!.copyWith(
                                      fontSize: 15,
                                      //fontWeight: FontWeight.bold,
                                      color: kHeadlineColorDark,
                                    ),
                          ),
                          subtitle: Row(
                            children: [
                              Text(
                                "${content['type']} •",
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
                              Text(
                                tago.format(content['time'].toDate()),
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
                        ),
                        bottomlikecomment(content['docName']),

                        /*
 bottomlikecomment(
                            content['docName'],
                            content['type'],
                            content['portraitonly'],
                            content['link'],
                            content['whethercommunitypost']),
                            */
                      ],
                    ),
                  ),
                );*/
              } else if ((content['type'] == 'linkpost') &&
                  (!content['blockedby'].contains(onlineuid))) {
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
                            docName: content['docName'],
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
                              if (content['whethercommunitypost'] == true) {
                                showCommunityQuickInfo(
                                  content['communityName'],
                                );
                              }
                            },
                            whethercommunitypost:
                                content['whethercommunitypost'],
                            communityname: content['communityName'],
                            communitypic: content['communitypic'],
                            onlineuid: onlineuid,
                            opuid: widget.uid,
                            opusername: username,
                            oppic: profilepic,
                            image: content['image'],
                            topic: content['topic'],
                            timeofposting: content['time'],
                            domainname: content['domainname'],
                            launchBrowser: () async {
                              print("opening link in browser");
                              openBrowserURL(url: content['link']);
                            },
                            onReport: () {
                              showPostOptionsForViewers(
                                content['docName'],
                                content['type'],
                                [widget.uid],
                              );
                            },
                            onDelete: () {
                              showPostOptionsForOP(
                                widget.uid!,
                                username!,
                                profilepic!,
                                content['docName'],
                                content['whethercommunitypost'],
                                content['communityName'],
                                content['communitypic'],
                                content['type'],
                                [widget.uid],
                                [content['link']],
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
                                  builder: (context) => PostLink(
                                    url: content['link'],
                                    whetherediting: true,
                                    whetherfrompost: false,
                                    docName: content['docName'],
                                    whethercommunitypost:
                                        content['whethercommunitypost'],
                                    communityName: content['communityName'],
                                    communityPic: content['communitypic'],
                                    onlineuser: UserInfoModel(
                                      uid: widget.uid,
                                      pic: profilepic,
                                      username: username,
                                    ),
                                  ),
                                  fullscreenDialog: true,
                                ),
                              ).then((whetheredited) => (whetheredited != null)
                                  ? setState(() {
                                      getalldata();
                                      print("updating post...");
                                    })
                                  : null);
                            },
                          ),
                          const SizedBox(height: 10.0),
                          bottomlikecomment(
                              content['docName'],
                              'linkpost',
                              content['topic'],
                              content['description'],
                              content['image']),
                        ],
                      ),
                    ),
                  ),
                );
              } else if ((content['type'] == 'textpost') &&
                  (!content['blockedby'].contains(onlineuid))) {
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
                              docName: content['docName'],
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
                                if (content['whethercommunitypost'] == true) {
                                  showCommunityQuickInfo(
                                    content['communityName'],
                                  );
                                }
                              },
                              opuid: widget.uid,
                              onlineuid: onlineuid,
                              onDelete: () {
                                showPostOptionsForOP(
                                  widget.uid!,
                                  username!,
                                  profilepic!,
                                  content['docName'],
                                  content['whethercommunitypost'],
                                  content['communityName'],
                                  content['communitypic'],
                                  content['type'],
                                  [widget.uid!],
                                  [content['link']],
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
                                        docName: content['docName'],
                                        imageUrl: content['image'],
                                        onlineuid: onlineuid!,
                                      ),
                                      fullscreenDialog: true,
                                    ));
                              },
                              onReport: () {
                                showPostOptionsForViewers(
                                  content['docName'],
                                  content['type'],
                                  [widget.uid!],
                                );
                              },
                              whethercommunitypost:
                                  content['whethercommunitypost'],
                              communityName: content['communityName'],
                              communitypic: content['communitypic'],
                              opusername: username,
                              oppic: profilepic,
                              image: content['image'],
                              topic: content['topic'],
                              description: content['description'],
                              timeofposting: content['time'],
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
                                      docName: content['docName'],
                                      whethercommunitypost:
                                          content['whethercommunitypost'],
                                      communityName: content['communityName'],
                                      communitypic: content['communitypic'],
                                      onlineuser: UserInfoModel(
                                        uid: widget.uid,
                                        pic: profilepic,
                                        username: username,
                                      ),
                                    ),
                                    fullscreenDialog: true,
                                  ),
                                ).then(
                                    (whetheredited) => (whetheredited != null)
                                        ? setState(() {
                                            getalldata();
                                            print("updating post...");
                                          })
                                        : null);
                              },
                            ),
                            const SizedBox(height: 10.0),
                            bottomlikecomment(
                                content['docName'],
                                'textpost',
                                content['topic'],
                                content['description'],
                                content['image']),
                          ],
                        ),
                      )),
                );
              } else if ((content['type'] == 'imagepost') &&
                  (!content['blockedby'].contains(onlineuid))) {
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
                            docName: content['docName'],
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
                            content['docName'], //docName
                            widget.uid!, //opuid
                            username!, //opusername
                            profilepic!, //oppic
                            content[
                                'whethercommunitypost'], //whethercommunitypost
                            content['communityName'], //communityName
                            content['communitypic'], //communitypic
                            content['type'], //type
                            content['topic'], //topic
                            List.from(content['imageslist']), //imageslist
                            content['time'], //time
                          ),
                          const SizedBox(height: 10.0),
                          bottomlikecomment(
                              content['docName'],
                              'imagepost',
                              content['topic'],
                              '',
                              List.from(content['imageslist'])[0]),
                        ],
                      ),
                    ),
                  ),
                );

                /*  InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImagePage2(
                          whatToDo: 'preview',
                          whethercommunitypost: content['whethercommunitypost'],
                          communityName: content['communityName'],
                          communitypic: content['communitypic'],
                          docName: content['docName'],
                          whetherjustcreated: false,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Card(
                      color: Theme.of(context).primaryIconTheme.color,
                      child: Column(
                        children: [
                          featuredImageCard(
                            content['docName'], //docName
                            widget.uid!, //opuid
                            username!, //opusername
                            profilepic!, //oppic
                            content[
                                'whethercommunitypost'], //whethercommunitypost
                            content['communityName'], //communityName
                            content['communitypic'], //communitypic
                            content['type'], //type
                            content['topic'], //topic
                            List.from(content['imageslist']), //imageslist
                            content['time'], //time
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 5.0),
                            child: bottomlikecomment(content['docName']),
                          ),
                        ],
                      )),
                );*/
              } else if ((content['type'] == 'videopost') &&
                  (!content['blockedby'].contains(onlineuid))) {
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
                            docName: content['docName'],
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
                            thumbnailAspectRatio:
                                content['thumbnailAspectRatio'],
                            userInfoClicked: () {
                              if (content['whethercommunitypost'] == true) {
                                showCommunityQuickInfo(
                                  content['communityName'],
                                );
                              }
                            },
                            onlineuid: onlineuid!,
                            opuid: widget.uid!,
                            opusername: username!,
                            oppic: profilepic!,
                            thumbnail: content['thumbnail'],
                            whethercommunitypost:
                                content['whethercommunitypost'],
                            communityName: content['communityName'],
                            communitypic: content['communitypic'],
                            topic: content['topic'],
                            timeofposting: content['time'],
                            onReport: () {
                              showPostOptionsForViewers(
                                content['docName'],
                                content['type'],
                                [widget.uid!],
                              );
                            },
                            onDelete: () {
                              showPostOptionsForOP(
                                widget.uid!,
                                username!,
                                profilepic!,
                                content['docName'],
                                content['whethercommunitypost'],
                                content['communityName'],
                                content['communitypic'],
                                content['type'],
                                [widget.uid!],
                                [content['link']],
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
                                              uid: widget.uid,
                                              pic: profilepic,
                                              username: username,
                                            ),
                                            whethercommunitypost:
                                                content['whethercommunitypost'],
                                            communityName:
                                                content['communityName'],
                                            communitypic:
                                                content['communitypic'],
                                            whetherediting: true,
                                            whetherfrompost: false,
                                            docName: content['docName'],
                                          )))).then(
                                  (whetheredited) => (whetheredited != null)
                                      ? setState(() {
                                          getalldata();
                                          print("updating post...");
                                        })
                                      : null);
                            },
                          ),
                          const SizedBox(height: 10.0),
                          bottomlikecomment(
                              content['docName'],
                              'videopost',
                              content['topic'],
                              content['description'],
                              content['thumbnail']),
                        ],
                      ),
                    ),
                  ),
                );

                /*  InkWell(
                  onTap: () {
                    setState(() {
                      hidenav = true;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NonliveVideoPlayer(
                          whethercommunitypost: content['whethercommunitypost'],
                          communityName: content['communityName'],
                          communitypic: content['communitypic'],
                          whetherjustcreated: false,
                          docName: content['docName'],
                          videourl: content['link'],
                          portraitonly: content['portraitonly'],
                          showcomments: false,
                        ),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Card(
                    color: Theme.of(context).primaryIconTheme.color,
                    child: Column(
                      children: [
                        FeaturedVideoCard(
                          userInfoClicked: () {
                            if (content['whethercommunitypost'] == true) {
                              showCommunityQuickInfo(
                                content['communityName'],
                              );
                            }
                          },
                          onlineuid: onlineuid!,
                          opuid: widget.uid!,
                          opusername: username!,
                          oppic: profilepic!,
                          thumbnail: content['thumbnail'],
                          whethercommunitypost: content['whethercommunitypost'],
                          communityName: content['communityName'],
                          communitypic: content['communitypic'],
                          topic: content['topic'],
                          timeofposting: content['time'],
                          onReport: () {},
                          onDelete: () {},
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
                                            uid: widget.uid!,
                                            pic: profilepic!,
                                            username: username!,
                                          ),
                                          whethercommunitypost:
                                              content['whethercommunitypost'],
                                          communityName:
                                              content['communityName'],
                                          communitypic: content['communitypic'],
                                          whetherediting: true,
                                          whetherfrompost: false,
                                          docName: content['docName'],
                                        )))).then(
                                (whetheredited) => (whetheredited != null)
                                    ? setState(() {
                                        getalldata();
                                        print("updating post...");
                                      })
                                    : null);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 5.0),
                          child: bottomlikecomment(content['docName']),
                        ),
                      ],
                    ),
                  ),
                );*/
              } else {
                return Container();
              }
            });
      },
    );
  }

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  profileContentShare(String docName, String type, String topic,
      String description, String image) {
    ShareService.shareContent(docName, type, topic, description, image);
  }

  Widget bottomlikecomment(String docName, String type, String topic,
      String description, String image) {
    return StreamBuilder<QuerySnapshot>(
        stream:
            contentcollection.where('docName', isEqualTo: docName).snapshots(),
        builder: (context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            print("getting info");
            return const UpDownVoteWidget(
              onComment: null,
              whetherDownvoted: false,
              whetherUpvoted: false,
              onUpvoted: null,
              onDownvoted: null,
              onShared: null,
              upvoteCount: 0,
              downvoteCount: 0,
              commentCount: 0,
            );
          }
          if (snapshot.data.docs.length == 0) {
            return const UpDownVoteWidget(
              onComment: null,
              whetherDownvoted: false,
              whetherUpvoted: false,
              onUpvoted: null,
              onDownvoted: null,
              onShared: null,
              upvoteCount: 0,
              downvoteCount: 0,
              commentCount: 0,
            );
          }

          var postdocs = snapshot.data.docs[0];
          String docName = postdocs['docName'];
          int likescount = (postdocs['likes']).length;
          int dislikescount = (postdocs['dislikes']).length;
          int upvotes = likescount;
          int downvotes = dislikescount;
          int commentcount = postdocs['commentcount'];
          bool whetherupvoted = postdocs['likes'].contains(onlineuid);
          bool whetherdownvoted = postdocs['dislikes'].contains(onlineuid);

          return UpDownVoteWidget(
            whetherUpvoted: whetherupvoted,
            whetherDownvoted: whetherdownvoted,
            onUpvoted: () {
              upvoteContent(docName);
            },
            onDownvoted: () {
              downvoteContent(docName);
            },
            onShared: () {
              profileContentShare(docName, type, topic, description, image);
            },
            onComment: () {
              setState(() {
                hidenav = true;
              });
              AppBuilder.of(context)!.rebuild();
              (postdocs['type'] == 'linkpost')
                  ? Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LinkPage(
                          docName: docName,
                          whetherjustcreated: false,
                          showcomments: true,
                        ),
                        fullscreenDialog: true,
                      ),
                    )
                  : (postdocs['type'] == 'textpost')
                      ? Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TextContentPage(
                              showcomments: true,
                              docName: postdocs['docName'],
                              whetherjustcreated: false,
                            ),
                            fullscreenDialog: true,
                          ),
                        )
                      : (postdocs['type'] == 'imagepost')
                          ? Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ImagePage2(
                                  docName: postdocs['docName'],
                                  whetherjustcreated: false,
                                  showcomments: false,
                                ),
                                fullscreenDialog: true,
                              ),
                            )
                          : (postdocs['type'] == 'videopost')
                              ? Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NonliveVideoPlayer(
                                      whetherjustcreated: false,
                                      docName: postdocs['docName'],
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
                                      docName: docName,
                                      showcomments: true,
                                    ),
                                    fullscreenDialog: true,
                                  ),
                                );
            },
            upvoteCount: upvotes,
            downvoteCount: downvotes,
            commentCount: commentcount,
          );
        });
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
                      showCommunityQuickInfo(communityName!);
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
                              'assets/images/background_grayish.png'),
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
                      ),
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

  userReportSubmit(String reason) async {
    //add this profile to blockusers list of online user and then submit report

    await usercollection.doc(onlineuid).update({
      'blockedusers': FieldValue.arrayUnion([widget.uid]),
    });
    await usercollection
        .doc(onlineuid)
        .collection('blockeduserslist')
        .doc(widget.uid)
        .set({
      'blockeduid': widget.uid,
      'blockedname': name,
      'blockedusername': username,
      'blockeduserpic': profilepic,
      'time': DateTime.now(),
      'type': 'userreport',
      'status': 'reported',
      'reason': reason,
    });
    //also hide online user's content/profile from profile user
    await usercollection.doc(widget.uid).update({
      'hiddenusers': FieldValue.arrayUnion([onlineuid]),
    });
    await userreportcollection.doc(generateRandomDocName(onlineuid!)).set({
      'type': 'userreport',
      'status': 'reported',
      'reporter': onlineuid,
      'uid': widget.uid,
      'reason': reason,
      'time': DateTime.now(),
    });
    setState(() {
      checkwhetherblocked = true;
    });
  }

  blockUnblockUser() async {
    if (checkwhetherblocked == false) {
      //block the user
      await usercollection.doc(onlineuid).update({
        'blockedusers': FieldValue.arrayUnion([widget.uid]),
      });
      await usercollection
          .doc(onlineuid)
          .collection('blockeduserslist')
          .doc(widget.uid)
          .set({
        'blockeduid': widget.uid,
        'blockedname': name,
        'blockedusername': username,
        'blockeduserpic': profilepic,
        'time': DateTime.now(),
        'type': 'blocked',
        'reason': '',
      });
      await usercollection.doc(widget.uid).update({
        'hiddenusers': FieldValue.arrayUnion([onlineuid]),
      });
      setState(() {
        checkwhetherblocked = true;
      });
    } else {
      //unblock
      await usercollection.doc(onlineuid).update({
        'blockedusers': FieldValue.arrayRemove([widget.uid]),
      });
      var blockeddoc = await usercollection
          .doc(onlineuid)
          .collection('blockeduserslist')
          .doc(widget.uid)
          .get();
      if (!blockeddoc.exists) {
        //do nothing if doc doesn't exist for some reason
      } else {
        usercollection
            .doc(onlineuid)
            .collection('blockeduserslist')
            .doc(widget.uid)
            .delete();
      }
      await usercollection.doc(widget.uid).update({
        'hiddenusers': FieldValue.arrayRemove([onlineuid]),
      });
      setState(() {
        checkwhetherblocked = false;
      });
    }
  }

  blockUserSheet() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalsetState) {
            return Container(
              height: MediaQuery.of(context).size.height / 5,
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: (whetherblockrequested == false)
                  ? Column(
                      children: [
                        Text(
                          "Are you sure you want to block this user?",
                          style: Theme.of(context)
                              .textTheme
                              .headline2!
                              .copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: kHeadlineColorDark),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      print("User Block Canceled");
                                    },
                                    child: Text("No",
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1!
                                            .copyWith(
                                                color: kPrimaryColor,
                                                fontWeight: FontWeight.bold))),
                              ),
                              Container(
                                color: Colors.grey.shade500,
                                width: 0.5,
                                height: 22,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: TextButton(
                                    onPressed: () {
                                      blockUnblockUser();
                                      print("User blocked");
                                      modalsetState(() {
                                        whetherblockrequested = true;
                                      });
                                    },
                                    child: Text("Yes",
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1!
                                            .copyWith(
                                                color: kPrimaryColor,
                                                fontWeight: FontWeight.bold))),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 30,
                            color: kPrimaryColor,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              "We've blocked this user for you; you will no longer be seeing their posts or comments.",
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
        whetherblockrequested = false;
      });
    });
  }

  reportUserSheet() {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalsetState) {
            return Container(
              height: MediaQuery.of(context).size.height / 2,
              width: MediaQuery.of(context).size.width,
              child: (whetherreportrequested == false)
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Report user",
                            style: Theme.of(context)
                                .textTheme
                                .headline2!
                                .copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: kHeadlineColorDark),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                  value: 1,
                                  groupValue: selectedReportRadioNo,
                                  activeColor: kPrimaryColor,
                                  onChanged: (dynamic val) {
                                    modalsetState(() {
                                      selectedReportRadioNo = val;
                                      userReportReason = "Spams a lot";
                                    });
                                  },
                                ),
                                Text("Spams a lot",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                          fontSize: 12,
                                          color: kIconSecondaryColorDark,
                                        )),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                  value: 2,
                                  groupValue: selectedReportRadioNo,
                                  activeColor: kPrimaryColor,
                                  onChanged: (dynamic val) {
                                    modalsetState(() {
                                      selectedReportRadioNo = val;
                                      userReportReason =
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
                                          color: kIconSecondaryColorDark,
                                        )),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                  value: 3,
                                  groupValue: selectedReportRadioNo,
                                  activeColor: kPrimaryColor,
                                  onChanged: (dynamic val) {
                                    modalsetState(() {
                                      selectedReportRadioNo = val;
                                      userReportReason =
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
                                          color: kIconSecondaryColorDark,
                                        )),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                  value: 4,
                                  groupValue: selectedReportRadioNo,
                                  activeColor: kPrimaryColor,
                                  onChanged: (dynamic val) {
                                    modalsetState(() {
                                      selectedReportRadioNo = val;
                                      userReportReason =
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
                                          color: kIconSecondaryColorDark,
                                        )),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                  value: 5,
                                  groupValue: selectedReportRadioNo,
                                  activeColor: kPrimaryColor,
                                  onChanged: (dynamic val) {
                                    modalsetState(() {
                                      selectedReportRadioNo = val;
                                      userReportReason =
                                          "Shares copyrighted material";
                                    });
                                  },
                                ),
                                Text("Shares copyrighted material",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                          fontSize: 12,
                                          color: kIconSecondaryColorDark,
                                        )),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                  value: 6,
                                  groupValue: selectedReportRadioNo,
                                  activeColor: kPrimaryColor,
                                  onChanged: (dynamic val) {
                                    modalsetState(() {
                                      selectedReportRadioNo = val;
                                      userReportReason = "Promotes self-harm";
                                    });
                                  },
                                ),
                                Text("Promotes self-harm",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                          fontSize: 12,
                                          color: kIconSecondaryColorDark,
                                        )),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Radio(
                                  value: 7,
                                  groupValue: selectedReportRadioNo,
                                  activeColor: kPrimaryColor,
                                  onChanged: (dynamic val) {
                                    modalsetState(() {
                                      selectedReportRadioNo = val;
                                      userReportReason = "Other";
                                    });
                                  },
                                ),
                                Text("Other",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(
                                          fontSize: 12,
                                          color: kIconSecondaryColorDark,
                                        )),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    print("User Report Canceled");
                                  },
                                  child: Text("Cancel",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: kPrimaryColor,
                                          )),
                                ),
                                const SizedBox(width: 10),
                                TextButton(
                                    onPressed: () {
                                      userReportSubmit(userReportReason);
                                      print("User Reported...");
                                      modalsetState(() {
                                        whetherreportrequested = true;
                                      });
                                    },
                                    child: Text("Submit",
                                        style: Theme.of(context)
                                            .textTheme
                                            .subtitle1!
                                            .copyWith(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: kPrimaryColor,
                                            ))),
                              ],
                            ),
                          )
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 30,
                            color: kPrimaryColor,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 10.0),
                            child: Text(
                              "Thank you for reporting. We will look into this ASAP and take immediate action. We've also blocked this user for you so you don't come across their posts and comments.",
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
        whetherreportrequested = false;
      });
    });
  }

  Widget blockedUsersIcon() {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: SizedBox(
        height: 20,
        width: 20,
        child: Stack(
          children: [
            Icon(
              Icons.person_outlined,
              color: Colors.grey.shade400,
              size: 22.0,
            ),
            const Positioned.fill(
                child: Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.block_outlined, size: 24.0)))
          ],
        ),
      ),
    );
  }

  Widget blockedCommunitiesIcon() {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: SizedBox(
        height: 20,
        width: 20,
        child: Stack(
          children: [
            Icon(
              Icons.group_outlined,
              color: Colors.grey.shade400,
              size: 22.0,
            ),
            const Positioned.fill(
                child: Align(
                    alignment: Alignment.center,
                    child: Icon(Icons.block_outlined, size: 24.0)))
          ],
        ),
      ),
    );
  }

  showProfileOptionsForVisitors() {
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
              blockUserSheet();
            },
            child: Text(
              'Block User',
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
              reportUserSheet();
            },
            child: Text(
              'Report User',
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

  shareProfile() {
    ShareService.shareContent(widget.uid!, 'profile',
        'Follow $username on Challo', bio ?? '', profilepic);
  }

  showProfileOptionsForOP() {
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
              shareProfile();
            },
            child: Text(
              'Share Profile',
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
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BlockedUsers(
                            profileuid: widget.uid,
                          )));
            },
            child: Text(
              'Blocked Users',
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
                      builder: (context) => BlockedCommunities(
                            profileuid: widget.uid,
                          )));
            },
            child: Text(
              'Blocked Communities',
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

  Future loadLits() async {
    print("Getting Lits data");

    litsSnapshots =
        usercollection.doc(widget.uid).collection('lits').orderBy('time').get();

    if (!mounted) return;
    setState(() {
      litsLoaded = true;
    });
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
                  const SizedBox(width: 10.0),
                  Text(
                    "Lits",
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
                        padding: const EdgeInsets.all(5.0),
                        child: ListView.builder(
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
                                        progressIndicatorBuilder: (context, url,
                                                downloadProgress) =>
                                            const CupertinoActivityIndicator(
                                          color: kBackgroundColorDark2,
                                        ),
                                        imageBuilder:
                                            (context, imageProvider) =>
                                                Container(
                                          width: 100,
                                          child: Align(
                                            alignment: Alignment.bottomLeft,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5.0),
                                              child: Text(
                                                lit['topic'],
                                                style: styleTitleSmall(),
                                              ),
                                            ),
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                            image: DecorationImage(
                                              image: imageProvider,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ));
                              }
                            }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (linkedPage != null &&
        selectedTabIndex == 4 &&
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
    return WillPopScope(
      onWillPop: (widget.whetherShowArrow == false)
          ? null
          : () async {
              if (widget.hideNavLinkReturn != null) {
                print("returning from link");
                hidenav = widget.hideNavLinkReturn!;
                AppBuilder.of(context)!.rebuild();
                Navigator.pop(context);
              } else if (widget.whetherShowArrow == true) {
                Navigator.pop(context);
              }
              return Future.value(false);
            },
      child: (linkDataLoading == true)
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
          : (dataisthere == false || litsLoaded == false)
              ? Scaffold(
                  appBar: AppBar(
                    leading: (widget.uid == onlineuid &&
                            widget.whetherShowArrow == false)
                        ? Container()
                        : GestureDetector(
                            onTap: () {
                              if (widget.hideNavLinkReturn != null) {
                                print("returning from link");
                                hidenav = widget.hideNavLinkReturn!;
                                AppBuilder.of(context)!.rebuild();
                                Navigator.pop(context);
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            child: const Icon(Icons.arrow_back),
                          ),
                  ),
                  resizeToAvoidBottomInset: false,
                  body: const SafeArea(
                    child: Center(
                      child: CupertinoActivityIndicator(
                        color: kDarkPrimaryColor,
                      ),
                    ),
                  ),
                )
              : (accountStatus == null || accountStatus == "deleted")
                  ? Scaffold(
                      appBar: AppBar(
                        leading: (widget.uid == onlineuid &&
                                widget.whetherShowArrow == false)
                            ? Container()
                            : GestureDetector(
                                onTap: () {
                                  if (widget.hideNavLinkReturn != null) {
                                    print("returning from link");
                                    hidenav = widget.hideNavLinkReturn!;
                                    AppBuilder.of(context)!.rebuild();
                                    Navigator.pop(context);
                                  } else {
                                    Navigator.pop(context);
                                  }
                                },
                                child: const Icon(Icons.arrow_back),
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
                              Icons.close,
                              color: Colors.redAccent,
                              size: 50,
                            ),
                            Padding(
                              padding: const EdgeInsets.all(30.0),
                              child: Text("This user account has been deleted.",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(color: kHeadlineColorDark)),
                            ),
                          ],
                        )),
                      ),
                    )
                  : (checkwhetherblocked == true)
                      //to show to online users who blocked profile owner
                      ? Scaffold(
                          appBar: AppBar(
                            leading: (widget.uid == onlineuid &&
                                    widget.whetherShowArrow == false)
                                ? Container()
                                : GestureDetector(
                                    onTap: () {
                                      if (widget.hideNavLinkReturn != null) {
                                        print("returning from link");
                                        hidenav = widget.hideNavLinkReturn!;
                                        AppBuilder.of(context)!.rebuild();
                                        Navigator.pop(context);
                                      } else {
                                        Navigator.pop(context);
                                      }
                                    },
                                    child: const Icon(Icons.arrow_back),
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
                                  child: Text(
                                      "You have blocked or reported $username's account. Unblock the user first to view profile.",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(color: kHeadlineColorDark)),
                                ),
                                TextButton(
                                    child: Text("Unblock",
                                        style: Theme.of(context)
                                            .textTheme
                                            .button!
                                            .copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: kPrimaryColor,
                                                fontSize: 15.0)),
                                    onPressed: () {
                                      blockUnblockUser();
                                    }),
                              ],
                            )),
                          ),
                        )
                      : (checkwhetherhidden == true)
                          //to show to onlineusers blocked by profile owner
                          ? Scaffold(
                              appBar: AppBar(
                                leading: (widget.uid == onlineuid &&
                                        widget.whetherShowArrow == false)
                                    ? Container()
                                    : GestureDetector(
                                        onTap: () {
                                          if (widget.hideNavLinkReturn !=
                                              null) {
                                            print("returning from link");
                                            hidenav = widget.hideNavLinkReturn!;
                                            AppBuilder.of(context)!.rebuild();
                                            Navigator.pop(context);
                                          } else {
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: const Icon(Icons.arrow_back),
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
                                      Icons.error_outline,
                                      color: Colors.redAccent,
                                      size: 50,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(30.0),
                                      child: Text(
                                          "Error loading profile data...",
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: kHeadlineColorDark)),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(30.0),
                                      child: Text(
                                          "The profile user may have set visitor restrictions.",
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: kHeadlineColorDark)),
                                    ),
                                  ],
                                )),
                              ),
                            )
                          : Scaffold(
                              resizeToAvoidBottomInset: false,
                              appBar: AppBar(
                                leading: (widget.uid == onlineuid &&
                                        widget.whetherShowArrow == false)
                                    ? Container()
                                    : GestureDetector(
                                        onTap: () {
                                          if (widget.hideNavLinkReturn !=
                                              null) {
                                            print("returning from link");
                                            hidenav = widget.hideNavLinkReturn!;
                                            AppBuilder.of(context)!.rebuild();
                                            Navigator.pop(context);
                                          } else {
                                            Navigator.pop(context);
                                          }
                                        },
                                        child: const Icon(Icons.arrow_back),
                                      ),
                                actions: [
                                  (onlineuid == widget.uid)
                                      ? Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            children: [
                                              InkWell(
                                                borderRadius:
                                                    const BorderRadius.all(
                                                  Radius.circular(5.0),
                                                ),
                                                onTap: () => {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          EditProfile(
                                                        uid: widget.uid,
                                                      ),
                                                    ),
                                                  ).then((whetherchanged) =>
                                                      (whetherchanged != null)
                                                          ? setState(() {
                                                              getalldata();
                                                              print(
                                                                  "updating profile");
                                                            })
                                                          : null)
                                                },
                                                child: Container(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 15,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                      Radius.circular(5.0),
                                                    ),
                                                    border: Border.all(
                                                      width: 2.0,
                                                      color: kPrimaryColorTint2,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    "Edit profile",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .button!
                                                        .copyWith(
                                                          fontSize: 15.0,
                                                          color:
                                                              kPrimaryColorTint2,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10.0),
                                              InkWell(
                                                customBorder:
                                                    const CircleBorder(),
                                                onTap: () =>
                                                    showProfileOptionsForOP(),
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                                  child: Icon(
                                                    Icons.more_horiz,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10.0),
                                            ],
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Row(
                                            children: [
                                              InkWell(
                                                onTap: () => followuser(),
                                                child: Container(
                                                  padding: const EdgeInsets
                                                          .symmetric(
                                                      horizontal: 20,
                                                      vertical: 6),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        const BorderRadius.all(
                                                      Radius.circular(
                                                        5.0,
                                                      ),
                                                    ),
                                                    border: Border.all(
                                                      width: 2,
                                                      color: kPrimaryColorTint2,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    isFollowing == false
                                                        ? "Follow"
                                                        : "Unfollow",
                                                    style: const TextStyle(
                                                      color: kPrimaryColorTint2,
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10.0),
                                              InkWell(
                                                customBorder:
                                                    const CircleBorder(),
                                                onTap: () =>
                                                    showProfileOptionsForVisitors(),
                                                child: const Padding(
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                                  child: Icon(
                                                    Icons.more_horiz,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10.0),
                                            ],
                                          ),
                                        ),
                                ],
                                //backgroundColor: Colors.transparent,
                                //elevation: 0.0,
                              ),
                              extendBodyBehindAppBar: true,
                              body: SafeArea(
                                child: RefreshIndicator(
                                  onRefresh: _pulltoRefreshProfile,
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(
                                        parent:
                                            AlwaysScrollableScrollPhysics()),
                                    child: Container(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: <Widget>[
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 5.0),
                                            child: (isLive == true &&
                                                    !liveblockedbylist
                                                        .contains(onlineuid))
                                                ? InkWell(
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    splashColor:
                                                        Colors.transparent,
                                                    //highlightColor:
                                                    // Colors.transparent,
                                                    onTap: () {
                                                      print(
                                                          "Go to audience page");
                                                      setState(() {
                                                        hidenav = true;
                                                      });
                                                      AppBuilder.of(context)!
                                                          .rebuild();
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              AudiencePage(
                                                            role: ClientRole
                                                                .Audience,
                                                            docName: docName,
                                                          ),
                                                          fullscreenDialog:
                                                              true,
                                                        ),
                                                      );
                                                    },
                                                    child: Stack(
                                                      children: [
                                                        Container(
                                                          decoration:
                                                              new BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            border:
                                                                new Border.all(
                                                              color: Colors.red,
                                                              width: 4.0,
                                                            ),
                                                          ),
                                                          child:
                                                              CachedNetworkImage(
                                                            imageUrl:
                                                                profilepic!,
                                                            progressIndicatorBuilder:
                                                                (context, url,
                                                                        downloadProgress) =>
                                                                    const CircleAvatar(
                                                              child:
                                                                  CupertinoActivityIndicator(
                                                                color:
                                                                    kPrimaryColorTint2,
                                                              ),
                                                              radius: 40.0,
                                                              backgroundColor:
                                                                  kBackgroundColorDark2,
                                                            ),
                                                            imageBuilder: (context,
                                                                    imageProvider) =>
                                                                CircleAvatar(
                                                              backgroundImage:
                                                                  imageProvider,
                                                              radius: 40.0,
                                                              backgroundColor:
                                                                  kBackgroundColorDark2,
                                                            ),
                                                          ),

                                                          /*CircleAvatar(
                                                            backgroundColor:
                                                                Colors.grey
                                                                    .shade500,
                                                            radius: 40,
                                                            backgroundImage:
                                                                const AssetImage(
                                                                    'assets/images/background_grayish.png'),
                                                            child: CircleAvatar(
                                                              radius: 40,
                                                              backgroundColor:
                                                                  Colors
                                                                      .transparent,
                                                              backgroundImage:
                                                                  NetworkImage(
                                                                      profilepic!),
                                                            ),
                                                          ),*/
                                                        ),
                                                        Positioned(
                                                          bottom: 10,
                                                          left: 65,
                                                          child: Container(
                                                            width: 20,
                                                            height: 20,
                                                            decoration: BoxDecoration(
                                                                color: Colors
                                                                    .green,
                                                                shape: BoxShape
                                                                    .circle,
                                                                border: Border.all(
                                                                    width: 3,
                                                                    color: Colors
                                                                        .white)),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : CachedNetworkImage(
                                                    imageUrl: profilepic!,
                                                    progressIndicatorBuilder:
                                                        (context, url,
                                                                downloadProgress) =>
                                                            Container(
                                                      decoration:
                                                          new BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: new Border.all(
                                                          color: Colors
                                                              .grey.shade600,
                                                          width: 4.0,
                                                        ),
                                                      ),
                                                      child: const CircleAvatar(
                                                        child:
                                                            CupertinoActivityIndicator(
                                                          color:
                                                              kPrimaryColorTint2,
                                                        ),
                                                        radius: 40.0,
                                                        backgroundColor:
                                                            kBackgroundColorDark2,
                                                      ),
                                                    ),
                                                    imageBuilder: (context,
                                                            imageProvider) =>
                                                        Container(
                                                      decoration:
                                                          new BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        border: new Border.all(
                                                          color: Colors
                                                              .grey.shade600,
                                                          width: 4.0,
                                                        ),
                                                      ),
                                                      child: CircleAvatar(
                                                        backgroundImage:
                                                            imageProvider,
                                                        radius: 40.0,
                                                        backgroundColor:
                                                            kBackgroundColorDark2,
                                                      ),
                                                    ),
                                                  ),

                                            /*Container(
                                                    decoration: new BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: new Border.all(
                                                        color:
                                                            Colors.grey.shade600,
                                                        width: 4.0,
                                                      ),
                                                    ),
                                                    child: CircleAvatar(
                                                      backgroundColor:
                                                          Colors.grey.shade500,
                                                      radius: 40,
                                                      backgroundImage:
                                                          const AssetImage(
                                                              'assets/images/background_grayish.png'),
                                                      child: CircleAvatar(
                                                        radius: 40,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                        backgroundImage:
                                                            NetworkImage(
                                                                profilepic!),
                                                      ),
                                                    ),
                                                  ),*/
                                          ),
                                          const SizedBox(height: 5.0),
                                          (name == '')
                                              ? Container()
                                              : (profileverified == false)
                                                  ? Padding(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 10.0),
                                                      child: Text(
                                                        name!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyText2!
                                                            .copyWith(
                                                                fontSize: 18.0,
                                                                color:
                                                                    kHeadlineColorDark,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                      ),
                                                    )
                                                  : Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Flexible(
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                              left: 10.0,
                                                              right: 5.0,
                                                            ),
                                                            child: Text(
                                                              name!,
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodyText2!
                                                                  .copyWith(
                                                                      fontSize:
                                                                          18.0,
                                                                      color: Colors
                                                                          .white,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                            ),
                                                          ),
                                                        ),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                      .only(
                                                                  right: 10.0),
                                                          child: InkWell(
                                                            onTap: () {
                                                              ScaffoldMessenger
                                                                      .of(
                                                                          context)
                                                                  .showSnackBar(
                                                                      const SnackBar(
                                                                content: Text(
                                                                  "This is a verified profile.",
                                                                ),
                                                              ));
                                                            },
                                                            child:
                                                                const VerifiedTick(
                                                              iconSize: 18,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                          (name == '')
                                              ? Text(
                                                  "@$username",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(
                                                        fontSize: 18.0,
                                                        letterSpacing: 0.5,
                                                        color:
                                                            kHeadlineColorDark,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                )
                                              : Text(
                                                  "@$username",
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .subtitle2!
                                                      .copyWith(
                                                        fontSize: 13.0,
                                                        letterSpacing: 0.5,
                                                        color:
                                                            kHeadlineColorDark,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                          (bio!.isEmpty)
                                              ? Container()
                                              : Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 15.0),
                                                  child: Text(bio!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subtitle2!
                                                          .copyWith(
                                                              fontSize: 13.0,
                                                              letterSpacing:
                                                                  0.5,
                                                              color:
                                                                  kHeadlineColorDark,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15.0,
                                              vertical: 10.0,

                                              //right: 38.0,
                                              //left: 38.0,
                                              //top: 15.0,
                                              //bottom: 12.0,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: <Widget>[
                                                InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () =>
                                                      Scrollable.ensureVisible(
                                                          postScrollKey
                                                              .currentContext!),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Text(
                                                        postslength.toString(),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displayMedium!
                                                            .copyWith(
                                                              color:
                                                                  kPrimaryColorTint2,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 20,
                                                            ),
                                                      ),
                                                      Text(
                                                        (postslength == 1)
                                                            ? "Post"
                                                            : "Posts",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displayMedium!
                                                            .copyWith(
                                                              color:
                                                                  kPrimaryColorTint2,
                                                              fontSize: 12.0,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  color: kHeadlineColorDark,
                                                  width: 0.2,
                                                  height: 22,
                                                ),
                                                InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                          builder: ((context) =>
                                                              FollowersPage(
                                                                uid:
                                                                    widget.uid!,
                                                                username:
                                                                    username!,
                                                                initialIndex: 0,
                                                              )))),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Text(
                                                        followers.toString(),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displayMedium!
                                                            .copyWith(
                                                              color:
                                                                  kPrimaryColorTint2,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 20,
                                                            ),
                                                      ),
                                                      Text(
                                                        (followers == 1)
                                                            ? "Follower"
                                                            : "Followers",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displayMedium!
                                                            .copyWith(
                                                              color:
                                                                  kPrimaryColorTint2,
                                                              fontSize: 12.0,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  color: kHeadlineColorDark,
                                                  width: 0.2,
                                                  height: 22,
                                                ),
                                                InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: ((context) =>
                                                            FollowersPage(
                                                                uid:
                                                                    widget.uid!,
                                                                username:
                                                                    username!,
                                                                initialIndex:
                                                                    1))),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Text(
                                                        following.toString(),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displayMedium!
                                                            .copyWith(
                                                              color:
                                                                  kPrimaryColorTint2,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 20,
                                                            ),
                                                      ),
                                                      Text(
                                                        "Following",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displayMedium!
                                                            .copyWith(
                                                              color:
                                                                  kPrimaryColorTint2,
                                                              fontSize: 12.0,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Container(
                                                  color: kHeadlineColorDark,
                                                  width: 0.2,
                                                  height: 22,
                                                ),
                                                InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () => Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: ((context) =>
                                                            FollowersPage(
                                                                uid:
                                                                    widget.uid!,
                                                                username:
                                                                    username!,
                                                                initialIndex:
                                                                    2))),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Text(
                                                        communitiesLength
                                                            .toString(),
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displayMedium!
                                                            .copyWith(
                                                              color:
                                                                  kPrimaryColorTint2,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 20,
                                                            ),
                                                      ),
                                                      Text(
                                                        "Communities",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .displayMedium!
                                                            .copyWith(
                                                              color:
                                                                  kPrimaryColorTint2,
                                                              fontSize: 12.0,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            color: kHeadlineColorDark,
                                            width: (MediaQuery.of(context)
                                                    .size
                                                    .width) /
                                                2,
                                            height: 0.2,
                                          ),
                                          const SizedBox(height: 10),
                                          (isLive == true &&
                                                  !liveblockedbylist
                                                      .contains(onlineuid))
                                              ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 8.0,
                                                    right: 8.0,
                                                    //bottom: 8.0,
                                                  ),
                                                  child: liveNowWidget(),
                                                )
                                              : Container(),
                                          Column(
                                            key: postScrollKey,
                                            children: [
                                              trendingLitsWidget(),
                                              videosList(),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
    );
  }
}
