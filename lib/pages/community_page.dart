import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/helpers/share_service.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/community_mods.dart';
import 'package:challo/pages/communityabout.dart';
import 'package:challo/pages/communityrules.dart';
import 'package:challo/pages/createcommunity.dart';
import 'package:challo/pages/debate_screen1.dart';
import 'package:challo/pages/image_page_2.dart';
import 'package:challo/pages/linkpage.dart';
import 'package:challo/pages/nonlive_video_player.dart';
import 'package:challo/pages/podcast_screen1.dart';
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
import 'package:challo/variables.dart';
import 'package:challo/widgets/contentformatcard.dart';
import 'package:challo/widgets/customcreatefield.dart';
import 'package:challo/widgets/featured_text_card.dart';
import 'package:challo/widgets/featured_video_card.dart';
import 'package:challo/widgets/featuredlinkcard.dart';
import 'package:challo/widgets/rounded_label.dart';
import 'package:challo/widgets/updownvotewidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'package:timeago/timeago.dart' as tago;

class CommunityPage extends StatefulWidget {
  final bool whetherjustcreated;
  final String? communityname;
  final bool? hideNavLinkReturn;
  const CommunityPage({
    required this.whetherjustcreated,
    required this.communityname,
    this.hideNavLinkReturn,
  });
  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  late String backgroundimage, mainimage, communityname, communitydescription;
  late String createdby, longdescriptionurl, rulesurl;
  late List<String> moduids;
  UserInfoModel? onlineuser;
  int? membercount;
  bool whetherjoined = false;
  bool dataisthere = false;
  bool whethercommunityreportrequested = false;
  int? selectedCommunityReportRadioNo = 1;
  String communityReportReason = 'A lot of spams';
  bool checkwhetherblocked = false;
  bool checkwhetherdeleted = false;
  String? communityrules = '';
  TextEditingController linkController = TextEditingController();
  List<String> blockedusers = [];
  List<String> hiddenusers = [];
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();
  bool whethercontentreportsubmitted = false;
  int? selectedContentRadioNo = 1;
  String contentReportReason = "Spam or misleading";

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateRandomDocName(String username) {
    String newDocName = (username + getRandomString(5));
    return newDocName;
  }

  //for content selection
  String selectedContentFormat = '';

  @override
  void initState() {
    super.initState();
    getcommunitydata();
  }

  getcommunitydata() async {
    String onlineuid = FirebaseAuth.instance.currentUser!.uid;
    var onlineuserdoc = await usercollection.doc(onlineuid).get();
    String? onlineusername = onlineuserdoc['username'];
    String? onlinepic = onlineuserdoc['profilepic'];
    String? onlinename = onlineuserdoc['name'];
    blockedusers = List.from(onlineuserdoc['blockedusers']);
    hiddenusers = List.from(onlineuserdoc['hiddenusers']);
    onlineuser = UserInfoModel(
      uid: onlineuid,
      username: onlineusername,
      pic: onlinepic,
      name: onlinename,
    );
    var communitydocs =
        await communitycollection.doc(widget.communityname).get();
    communityname = communitydocs['name'];
    communitydescription = communitydocs['description'];
    mainimage = communitydocs['mainimage'];
    backgroundimage = communitydocs['backgroundimage'];
    communityrules = communitydocs['communityrules'];
    communityrules!.replaceAll("/n", " ");
    List<String> memberuids = List.from(communitydocs['memberuids']);
    List<String> blockedby = List.from(communitydocs['blockedby']);
    createdby = communitydocs['createdby'];
    longdescriptionurl = communitydocs['longdescription'];
    rulesurl = communitydocs['rules'];
    moduids = List.from(communitydocs['moduids']);
    membercount = memberuids.length;
    if (memberuids.contains(onlineuid)) {
      setState(() {
        whetherjoined = true;
      });
    }
    if (blockedby.contains(onlineuid)) {
      setState(() {
        checkwhetherblocked = true;
      });
    }
    setState(() {
      dataisthere = true;
    });
  }

  @override
  void dispose() {
    linkController.dispose();
    super.dispose();
  }

  Widget moreOptions() {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () {
          if (moduids.contains(onlineuser!.uid)) {
            showMoreOptionsPopUpForMods();
          } else {
            showMoreOptionsPopUpForMembers();
          }
        },
        child: const Icon(
          CupertinoIcons.ellipsis_circle_fill,
          size: 30,
          color: Colors.white70,
        ),
      ),
    );
  }

  shareCommunity() async {
    ShareService.shareContent(
      widget.communityname!,
      'community',
      'Join c/${widget.communityname} on Challo',
      communitydescription,
      mainimage,
    );
  }

  showMoreOptionsPopUpForMembers() {
    showCupertinoModalPopup(
      //useRootNavigator: false,
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
              shareCommunity();
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
            //isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CommunityAbout(
                            communityName: communityname,
                            longdescriptionurl: longdescriptionurl,
                          )));
            },
            child: Text(
              'About',
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
                      builder: (context) => CommunityRules(
                            communityName: communityname,
                            rulesurl: rulesurl,
                          )));
            },
            child: Text(
              'Rules',
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
                      builder: ((context) =>
                          CommunityMods(communityName: communityname))));
            },
            child: Text(
              'Mods',
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
              reportCommunitySheet();
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

  showMoreOptionsPopUpForMods() {
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
              shareCommunity();
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
            //isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CommunityAbout(
                            communityName: communityname,
                            longdescriptionurl: longdescriptionurl,
                          )));
            },
            child: Text(
              'About',
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
                      builder: (context) => CommunityRules(
                            communityName: communityname,
                            rulesurl: rulesurl,
                          )));
            },
            child: Text(
              'Rules',
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
                      builder: ((context) =>
                          CommunityMods(communityName: communityname))));
            },
            child: Text(
              'Mods',
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
              setState(() {
                hidenav = true;
              });
              AppBuilder.of(context)!.rebuild();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: ((context) => CreateCommunity(
                        whetherediting: true,
                        onlineuser: onlineuser,
                        docName: communityname,
                      )),
                  fullscreenDialog: true,
                ),
              );
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
            onPressed: () async {
              Navigator.pop(context);
              showCommunityDeleteConfirmation();
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

  showCommunityDeleteConfirmation() {
    showCupertinoModalPopup(
      useRootNavigator: false,
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
              await communitycollection.doc(widget.communityname).update({
                'status': 'deleted',
              }).then((_) => {
                    setState(() {
                      checkwhetherdeleted = true;
                    })
                  });
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

  communityReportSubmit(String reason) async {
    await communitycollection.doc(communityname).update({
      'blockedby': FieldValue.arrayUnion([onlineuser!.uid]),
    });
    await usercollection.doc(onlineuser!.uid).update({
      'blockedcommunities': FieldValue.arrayUnion([communityname]),
    });
    await communityreportcollection
        .doc(generateRandomDocName(onlineuser!.uid!))
        .set({
      'type': 'communityreport',
      'status': 'reported',
      'reporter': onlineuser!.uid,
      'reason': reason,
      'time': DateTime.now(),
    });
    await usercollection
        .doc(onlineuser!.uid)
        .collection('blockedcommunitieslist')
        .doc(communityname)
        .set({
      'time': DateTime.now(),
      'type': 'communityreport',
      'status': 'reported',
      'reason': reason,
      'communityName': communityname,
      'communitypic': mainimage,
      'description': communitydescription,
    });
    setState(() {
      checkwhetherblocked = true;
    });
  }

  unblockCommunity() async {
    await communitycollection.doc(communityname).update({
      'blockedby': FieldValue.arrayRemove([onlineuser!.uid]),
    });
    await usercollection.doc(onlineuser!.uid).update({
      'blockedcommunities': FieldValue.arrayRemove([communityname]),
    });
    var blockeddoc = await usercollection
        .doc(onlineuser!.uid)
        .collection('blockedcommunitieslist')
        .doc(communityname)
        .get();

    if (!blockeddoc.exists) {
      //do nothing if doc doesn't exist for some reason
    } else {
      usercollection
          .doc(onlineuser!.uid)
          .collection('blockedcommunitieslist')
          .doc(communityname)
          .delete();
    }
    setState(() {
      checkwhetherblocked = false;
    });
  }

  reportCommunitySheet() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalsetState) {
            return Container(
              child: (whethercommunityreportrequested == false)
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Wrap(
                        //crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Report community",
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
                                groupValue: selectedCommunityReportRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommunityReportRadioNo = val;
                                    communityReportReason = "A lot of spams";
                                  });
                                },
                              ),
                              Text("A lot of spams",
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
                                groupValue: selectedCommunityReportRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommunityReportRadioNo = val;
                                    communityReportReason =
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
                                groupValue: selectedCommunityReportRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommunityReportRadioNo = val;
                                    communityReportReason =
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
                                groupValue: selectedCommunityReportRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommunityReportRadioNo = val;
                                    communityReportReason =
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
                                groupValue: selectedCommunityReportRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommunityReportRadioNo = val;
                                    communityReportReason =
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
                                        color: Colors.white70,
                                      )),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 6,
                                groupValue: selectedCommunityReportRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommunityReportRadioNo = val;
                                    communityReportReason =
                                        "Promotes self-harm";
                                  });
                                },
                              ),
                              Text("Promotes self-harm",
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
                                value: 7,
                                groupValue: selectedCommunityReportRadioNo,
                                activeColor: kPrimaryColor,
                                onChanged: (dynamic val) {
                                  modalsetState(() {
                                    selectedCommunityReportRadioNo = val;
                                    communityReportReason = "Other";
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
                                  print("User Report Canceled");
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
                                    communityReportSubmit(
                                        communityReportReason);
                                    print("User Reported...");
                                    modalsetState(() {
                                      whethercommunityreportrequested = true;
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
                              "Thank you for reporting. We will look into this ASAP and take immediate action. We've also blocked this user for you so you don't come across their posts and comments.",
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
        whethercommunityreportrequested = false;
      });
    });
  }

  joinCommunity() async {
    var communitydocs =
        await communitycollection.doc(widget.communityname).get();
    List<String> memberuids = List.from(communitydocs['memberuids']);
    if (memberuids.contains(onlineuser!.uid)) {
      //remove the user from community
      communitycollection.doc(widget.communityname).update({
        'memberuids': FieldValue.arrayRemove([onlineuser!.uid])
      });
      var usercommunitydocs = await usercollection
          .doc(onlineuser!.uid)
          .collection('communities')
          .doc(communityname)
          .get();
      if (usercommunitydocs.exists) {
        usercollection
            .doc(onlineuser!.uid)
            .collection('communities')
            .doc(communityname)
            .delete();
      }
      setState(() {
        whetherjoined = false;
      });
    } else {
      var time = DateTime.now();
      //add user to community
      communitycollection.doc(widget.communityname).update({
        'memberuids': FieldValue.arrayUnion([onlineuser!.uid])
      });
      var usercommunitydocs = await usercollection
          .doc(onlineuser!.uid)
          .collection('communities')
          .doc(communityname)
          .get();
      if (!usercommunitydocs.exists) {
        usercollection
            .doc(onlineuser!.uid)
            .collection('communities')
            .doc(communityname)
            .set({
          'name': communityname,
          'mainimage': mainimage,
          'backgroundimage': backgroundimage,
          'joinedSince': time,
          'description': communitydescription,
        });
      }
      setState(() {
        whetherjoined = true;
      });
    }
  }

  showCommunityLeaveAlert() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("Sure you want to leave?",
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
              Navigator.of(context).pop();
              joinCommunity();
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

  Future<void> _pulltoRefreshCommunity() async {
    setState(() {
      getcommunitydata();
    });
  }

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  upvoteContent(String? docName) async {
    var postdoc = await contentcollection.doc(docName).get();

    if (postdoc['likes'].contains(onlineuser!.uid)) {
      contentcollection.doc(docName).update({
        'likes': FieldValue.arrayRemove([onlineuser!.uid])
      });
    } else if (postdoc['dislikes'].contains(onlineuser!.uid)) {
      contentcollection.doc(docName).update({
        'dislikes': FieldValue.arrayRemove([onlineuser!.uid])
      });
      contentcollection.doc(docName).update({
        'likes': FieldValue.arrayUnion([onlineuser!.uid])
      });
    } else {
      contentcollection.doc(docName).update({
        'likes': FieldValue.arrayUnion([onlineuser!.uid])
      });
    }
  }

  downvoteContent(String? docName) async {
    var postdoc = await contentcollection.doc(docName).get();

    if (postdoc['dislikes'].contains(onlineuser!.uid)) {
      contentcollection.doc(docName).update({
        'dislikes': FieldValue.arrayRemove([onlineuser!.uid])
      });
    } else if (postdoc['likes'].contains(onlineuser!.uid)) {
      contentcollection.doc(docName).update({
        'likes': FieldValue.arrayRemove([onlineuser!.uid])
      });
      contentcollection.doc(docName).update({
        'dislikes': FieldValue.arrayUnion([onlineuser!.uid])
      });
    } else {
      contentcollection.doc(docName).update({
        'dislikes': FieldValue.arrayUnion([onlineuser!.uid])
      });
    }
  }

  contentReportSubmit(String? docName, String? type,
      List<String> participateduids, String reason) async {
    await contentcollection.doc(docName).update({
      'blockedby': FieldValue.arrayUnion([onlineuser!.uid])
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
          'blockedby': FieldValue.arrayUnion([onlineuser!.uid])
        });
      }
    }

    await contentreportcollection
        .doc(generateRandomDocName(onlineuser!.username!))
        .set({
      'type': type,
      'status': 'reported', //reported -> deleted/noaction/pending
      'reporter': onlineuser!.uid,
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
                                  onPressed: () {},
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
                        color: Colors.white)),
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

  showPostDeleteConfirmation(docName) {
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
                  .doc(onlineuser!.uid)
                  .collection('content')
                  .where('docName', isEqualTo: docName)
                  .get()
                  .then((value) {
                for (var element in value.docs) {
                  usercollection
                      .doc(onlineuser!.uid)
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
                uid: onlineuser!.uid,
                username: onlineuser!.username,
                pic: onlineuser!.pic),
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
                uid: onlineuser!.uid,
                username: onlineuser!.username,
                pic: onlineuser!.pic),
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
                uid: onlineuser!.uid,
                username: onlineuser!.username,
                pic: onlineuser!.pic),
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
              uid: onlineuser!.uid,
              pic: onlineuser!.pic,
              username: onlineuser!.username,
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
              uid: onlineuser!.uid,
              pic: onlineuser!.pic,
              username: onlineuser!.username,
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
              uid: onlineuser!.uid,
              username: onlineuser!.username,
              pic: onlineuser!.pic,
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
              showPostDeleteConfirmation(docName);
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
                    showUserQuickInfo(opusername, opuid);
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
                (onlineuser!.uid == opuid)
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
                                              onlineuid: onlineuser!.uid!,
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
                                  onlineuid: onlineuser!.uid!,
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

  /*Widget featuredImageCard2(
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
                Row(
                  children: [
                    Container(
                      decoration: new BoxDecoration(
                        shape: BoxShape.circle,
                        border: new Border.all(
                          color: Colors.white70,
                          width: 2.0,
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.grey.shade500,
                        radius: 12,
                        backgroundImage: const AssetImage(
                            'assets/images/default-profile-pic.png'),
                        child: CircleAvatar(
                          radius: 12,
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
                                        fontSize: 12.0,
                                        color: Colors.white,
                                      ))
                              : Text(opusername,
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2!
                                      .copyWith(
                                        fontSize: 12.0,
                                        color: Colors.white,
                                      )),
                          (whethercommunitypost == true)
                              ? Text(
                                  "$opusername • ${tago.format(time.toDate())} •",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                          fontSize: 10.0,
                                          color: Colors.grey.shade500),
                                )
                              : Text(
                                  "• ${tago.format(time.toDate())} •",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                          fontSize: 10.0,
                                          color: Colors.grey.shade500),
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
                (onlineuser!.uid == opuid)
                    ? PopupMenuButton<contentOptionsForOP>(
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
                                          getcommunitydata();
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
                      )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Text(
              topic,
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    fontSize: 15,
                    //fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
          ),
          (imageslist.length > 1)
              ? Container(
                  height: 200,
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
                                              whetherfromtextpost: false,
                                              docName: docName,
                                              imageUrl: imageslist[index],
                                            ))));
                              },
                              child: Image.network(imageslist[index]),
                            ),
                          ),
                        ),
                        Positioned(
                            child: Align(
                          alignment: Alignment.topCenter,
                          child: Card(
                            color: kCardBackgroundColor,
                            child: Text(" $index/${imageslist.length - 1} "),
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
                                  whetherfromtextpost: false,
                                  docName: docName,
                                  imageUrl: imageslist[0],
                                ))));
                  },
                  child: Container(
                    width: double.infinity,
                    child: Image.network(imageslist[0]),
                  ),
                ),
        ],
      ),
    );
  }*/

  Widget communityContentStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: contentcollection
          .orderBy('communitypostpriority', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting trending community content");
          return const Center(
              child: CupertinoActivityIndicator(
            color: kDarkPrimaryColor,
          ));
        }
        if (snapshot.data.docs.length == 0) {
          return Center(child: Container());
        }
        return ListView.builder(
          reverse: false,
          physics: const ScrollPhysics(),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: snapshot.data.docs.length,
          itemBuilder: (BuildContext context, int index) {
            var content = snapshot.data.docs[index];
            if ((content['type'] == 'linkpost') &&
                (content['status'] == 'published') &&
                (content['whethercommunitypost'] == true) &&
                (content['communityName'] == communityname) &&
                (!content['blockedby'].contains(onlineuser!.uid)) &&
                (!blockedusers.contains(content['opuid'])) &&
                (!hiddenusers.contains(content['opuid']))) {
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
                            showUserQuickInfo(
                                content['opusername'], content['opuid']);
                          },
                          whethercommunitypost: content['whethercommunitypost'],
                          communityname: content['communityName'],
                          communitypic: content['communitypic'],
                          onlineuid: onlineuser!.uid,
                          opuid: content['opuid'],
                          opusername: content['opusername'],
                          oppic: content['oppic'],
                          image: content['image'],
                          topic: content['topic'],
                          timeofposting: content['time'],
                          domainname: content['domainname'],
                          launchBrowser: () async {
                            print("opening link in browser");
                            openBrowserURL(url: content['link']);
                          },
                          onReport: () {
                            showPostOptionsForViewers(content['docName'],
                                content['type'], [content['opuid']]);
                          },
                          onDelete: () {
                            showPostOptionsForOP(
                              content['opuid'],
                              content['opusername'],
                              content['oppic'],
                              content['docName'],
                              content['whethercommunitypost'],
                              content['communityName'],
                              content['communitypic'],
                              content['type'],
                              [content['opuid']],
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
                                    uid: content['opuid'],
                                    pic: content['oppic'],
                                    username: content['opusername'],
                                  ),
                                ),
                                fullscreenDialog: true,
                              ),
                            ).then((whetheredited) => (whetheredited != null)
                                ? setState(() {
                                    getcommunitydata();
                                    print("updating post...");
                                  })
                                : null);
                          },
                        ),
                        const SizedBox(height: 10.0),
                        UpDownVoteWidget(
                          whetherUpvoted:
                              content['likes'].contains(onlineuser!.uid),
                          whetherDownvoted:
                              content['dislikes'].contains(onlineuser!.uid),
                          onUpvoted: () {
                            upvoteContent(content['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(content['docName']);
                          },
                          onShared: () => ShareService.shareContent(
                            content['docName'],
                            'linkpost',
                            content['topic'],
                            content['description'],
                            content['image'],
                          ),
                          upvoteCount: (content['likes']).length,
                          downvoteCount: (content['dislikes']).length,
                          commentCount: content['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            (content['type'] == 'linkpost')
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LinkPage(
                                        docName: content['docName'],
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
                                        docName: content['docName'],
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

              /* InkWell(
                onTap: () {
                  setState(() {
                    hidenav = true;
                  });
                  AppBuilder.of(context)!.rebuild();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LinkPage(
                        whethercommunitypost: content['whethercommunitypost'],
                        docName: content['docName'],
                        whetherjustcreated: false,
                        showcomments: false,
                      ),
                      fullscreenDialog: true,
                    ),
                  );
                },
                child: Card(
                    color: kCardBackgroundColor,
                    child: Column(
                      children: [
                        FeaturedLinkCard(
                          userInfoClicked: () => showUserQuickInfo(
                              content['opusername'], content['opuid']),
                          whethercommunitypost: content['whethercommunitypost'],
                          communityname: content['communityName'],
                          communitypic: content['communitypic'],
                          onlineuid: onlineuser!.uid,
                          opuid: content['opuid'],
                          opusername: content['opusername'],
                          oppic: content['oppic'],
                          image: content['image'],
                          topic: content['topic'],
                          timeofposting: content['time'],
                          domainname: content['domainname'],
                          launchBrowser: () async {
                            print("opening link in browser");
                            openBrowserURL(url: content['link']);
                          },
                          onReport: () {
                            reportContentSheet(content['docName'],
                                content['type'], ['${content['opuid']}']);
                          },
                          onDelete: () {
                            deleteContentSheet(
                                content['opuid'],
                                content['docName'],
                                content['whethercommunitypost'],
                                content['communityName']);
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
                                    uid: content['opuid'],
                                    pic: content['oppic'],
                                    username: content['opusername'],
                                  ),
                                ),
                                fullscreenDialog: true,
                              ),
                            ).then((whetheredited) => (whetheredited != null)
                                ? setState(() {
                                    getcommunitydata();
                                    print("updating post...");
                                  })
                                : null);
                          },
                        ),
                        UpDownVoteWidget(
                          whetherUpvoted:
                              content['likes'].contains(onlineuser!.uid),
                          whetherDownvoted:
                              content['dislikes'].contains(onlineuser!.uid),
                          onUpvoted: () {
                            upvoteContent(content['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(content['docName']);
                          },
                          onShared: shareContent,
                          upvoteCount: (content['likes']).length,
                          downvoteCount: (content['dislikes']).length,
                          commentCount: content['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            (content['type'] == 'linkpost')
                                ? Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LinkPage(
                                        whethercommunitypost:
                                            content['whethercommunitypost'],
                                        docName: content['docName'],
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
                                        portraitonly: content['portraitonly'],
                                        docName: content['docName'],
                                        videourl: content['link'],
                                        formattype: content['type'],
                                        showcomments: true,
                                      ),
                                      fullscreenDialog: true,
                                    ),
                                  );
                          },
                        ),
                      ],
                    )),
              );*/
            } else if ((content['type'] == 'textpost') &&
                (content['status'] == 'published') &&
                (content['whethercommunitypost'] == true) &&
                (content['communityName'] == communityname) &&
                (!content['blockedby'].contains(onlineuser!.uid)) &&
                (!blockedusers.contains(content['opuid'])) &&
                (!hiddenusers.contains(content['opuid']))) {
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
                              showUserQuickInfo(
                                  content['opusername'], content['opuid']);
                            },
                            opuid: content['opuid'],
                            onlineuid: onlineuser!.uid,
                            onDelete: () {
                              showPostOptionsForOP(
                                content['opuid'],
                                content['opusername'],
                                content['oppic'],
                                content['docName'],
                                content['whethercommunitypost'],
                                content['communityName'],
                                content['communitypic'],
                                content['type'],
                                [content['opuid']],
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
                                      onlineuid: onlineuser!.uid!,
                                    ),
                                    fullscreenDialog: true,
                                  ));
                            },
                            onReport: () {
                              showPostOptionsForViewers(content['docName'],
                                  content['type'], [content['opuid']]);
                            },
                            whethercommunitypost:
                                content['whethercommunitypost'],
                            communityName: content['communityName'],
                            communitypic: content['communitypic'],
                            opusername: content['opusername'],
                            oppic: content['oppic'],
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
                                      uid: content['opuid'],
                                      pic: content['oppic'],
                                      username: content['opusername'],
                                    ),
                                  ),
                                  fullscreenDialog: true,
                                ),
                              ).then((whetheredited) => (whetheredited != null)
                                  ? setState(() {
                                      getcommunitydata();
                                      print("updating post...");
                                    })
                                  : null);
                            },
                          ),
                          const SizedBox(height: 10.0),
                          UpDownVoteWidget(
                            whetherUpvoted:
                                content['likes'].contains(onlineuser!.uid),
                            whetherDownvoted:
                                content['dislikes'].contains(onlineuser!.uid),
                            onUpvoted: () {
                              upvoteContent(content['docName']);
                            },
                            onDownvoted: () {
                              downvoteContent(content['docName']);
                            },
                            onShared: () => ShareService.shareContent(
                              content['docName'],
                              'textpost',
                              content['topic'],
                              content['description'],
                              content['image'],
                            ),
                            upvoteCount: (content['likes']).length,
                            downvoteCount: (content['dislikes']).length,
                            commentCount: content['commentcount'],
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
                                    docName: content['docName'],
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

              /* InkWell(
                onTap: () {
                  setState(() {
                    hidenav = true;
                  });
                  AppBuilder.of(context)!.rebuild();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TextContentPage(
                        whethercommunitypost: content['whethercommunitypost'],
                        showcomments: false,
                        docName: content['docName'],
                        whetherjustcreated: false,
                      ),
                      fullscreenDialog: true,
                    ),
                  );
                },
                child: Card(
                    child: Column(
                  children: [
                    FeaturedTextCard(
                      userInfoClicked: () => showUserQuickInfo(
                          content['opusername'], content['opuid']),
                      opuid: content['opuid'],
                      onlineuid: onlineuser!.uid,
                      onDelete: () {
                        deleteContentSheet(
                            content['opuid'],
                            content['docName'],
                            content['whethercommunitypost'],
                            content['communityName']);
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
                              ),
                              fullscreenDialog: true,
                            ));
                      },
                      onReport: () {
                        reportContentSheet(content['docName'], content['type'],
                            ['${content['opuid']}']);
                      },
                      whethercommunitypost: content['whethercommunitypost'],
                      communityName: content['communityName'],
                      communitypic: content['communitypic'],
                      opusername: content['opusername'],
                      oppic: content['oppic'],
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
                                uid: content['opuid'],
                                pic: content['oppic'],
                                username: content['opusername'],
                              ),
                            ),
                            fullscreenDialog: true,
                          ),
                        ).then((whetheredited) => (whetheredited != null)
                            ? setState(() {
                                getcommunitydata();
                                print("updating post...");
                              })
                            : null);
                      },
                    ),
                    UpDownVoteWidget(
                      whetherUpvoted:
                          content['likes'].contains(onlineuser!.uid),
                      whetherDownvoted:
                          content['dislikes'].contains(onlineuser!.uid),
                      onUpvoted: () {
                        upvoteContent(content['docName']);
                      },
                      onDownvoted: () {
                        downvoteContent(content['docName']);
                      },
                      onShared: shareContent,
                      upvoteCount: (content['likes']).length,
                      downvoteCount: (content['dislikes']).length,
                      commentCount: content['commentcount'],
                      onComment: () {
                        setState(() {
                          hidenav = true;
                        });
                        AppBuilder.of(context)!.rebuild();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TextContentPage(
                              whethercommunitypost:
                                  content['whethercommunitypost'],
                              showcomments: false,
                              docName: content['docName'],
                              whetherjustcreated: false,
                            ),
                            fullscreenDialog: true,
                          ),
                        );
                      },
                    ),
                  ],
                )),
              );*/
            } else if ((content['type'] == 'imagepost') &&
                (content['status'] == 'published') &&
                (content['whethercommunitypost'] == true) &&
                (content['communityName'] == communityname) &&
                (!content['blockedby'].contains(onlineuser!.uid)) &&
                (!blockedusers.contains(content['opuid'])) &&
                (!hiddenusers.contains(content['opuid']))) {
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
                          content['opuid'], //opuid
                          content['opusername'], //opusername
                          content['oppic'], //oppic
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
                        UpDownVoteWidget(
                          whetherUpvoted:
                              content['likes'].contains(onlineuser!.uid),
                          whetherDownvoted:
                              content['dislikes'].contains(onlineuser!.uid),
                          onUpvoted: () {
                            upvoteContent(content['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(content['docName']);
                          },
                          onShared: () => ShareService.shareContent(
                            content['docName'],
                            'imagepost',
                            content['topic'],
                            content['description'],
                            List.from(content['imageslist'])[0],
                          ),
                          upvoteCount: (content['likes']).length,
                          downvoteCount: (content['dislikes']).length,
                          commentCount: content['commentcount'],
                          onComment: () {
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
                        ),
                      ],
                    ),
                  ),
                ),
              );

              /* InkWell(
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
                    color: kCardBackgroundColor,
                    child: Column(
                      children: [
                        featuredImageCard(
                          content['docName'], //docName
                          content['opuid'], //opuid
                          content['opusername'], //opusername
                          content['oppic'], //oppic
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
                          child: UpDownVoteWidget(
                            whetherUpvoted:
                                content['likes'].contains(onlineuser!.uid),
                            whetherDownvoted:
                                content['dislikes'].contains(onlineuser!.uid),
                            onUpvoted: () {
                              upvoteContent(content['docName']);
                            },
                            onDownvoted: () {
                              downvoteContent(content['docName']);
                            },
                            onShared: shareContent,
                            upvoteCount: (content['likes']).length,
                            downvoteCount: (content['dislikes']).length,
                            commentCount: content['commentcount'],
                            onComment: () {
                              setState(() {
                                hidenav = true;
                              });
                              AppBuilder.of(context)!.rebuild();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ImagePage2(
                                    whatToDo: 'preview',
                                    whethercommunitypost:
                                        content['whethercommunitypost'],
                                    communityName: content['communityName'],
                                    communitypic: content['communitypic'],
                                    docName: content['docName'],
                                    whetherjustcreated: false,
                                  ),
                                  fullscreenDialog: true,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    )),
              );*/
            } else if ((content['type'] == 'videopost') &&
                (content['status'] == 'published') &&
                (content['whethercommunitypost'] == true) &&
                (content['communityName'] == communityname) &&
                (!content['blockedby'].contains(onlineuser!.uid)) &&
                (!blockedusers.contains(content['opuid'])) &&
                (!hiddenusers.contains(content['opuid']))) {
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
                          thumbnailAspectRatio: content['thumbnailAspectRatio'],
                          userInfoClicked: () {
                            if (content['whethercommunitypost'] == false) {
                              showUserQuickInfo(
                                  content['opusername'], content['opuid']);
                            }
                          },
                          onlineuid: onlineuser!.uid!,
                          opuid: content['opuid'],
                          opusername: content['opusername'],
                          oppic: content['oppic'],
                          thumbnail: content['thumbnail'],
                          whethercommunitypost: content['whethercommunitypost'],
                          communityName: content['communityName'],
                          communitypic: content['communitypic'],
                          topic: content['topic'],
                          timeofposting: content['time'],
                          onReport: () {
                            showPostOptionsForViewers(
                              content['docName'],
                              content['type'],
                              [content['opuid']],
                            );
                          },
                          onDelete: () {
                            showPostOptionsForOP(
                              content['opuid'],
                              content['opusername'],
                              content['oppic'],
                              content['docName'],
                              content['whethercommunitypost'],
                              content['communityName'],
                              content['communitypic'],
                              content['type'],
                              [content['opuid']],
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
                                            uid: content['opuid'],
                                            pic: content['oppic'],
                                            username: content['opusername'],
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
                                        getcommunitydata();
                                        print("updating post...");
                                      })
                                    : null);
                          },
                        ),
                        const SizedBox(height: 10.0),
                        UpDownVoteWidget(
                          whetherUpvoted:
                              content['likes'].contains(onlineuser!.uid),
                          whetherDownvoted:
                              content['dislikes'].contains(onlineuser!.uid),
                          onUpvoted: () {
                            upvoteContent(content['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(content['docName']);
                          },
                          onShared: () => ShareService.shareContent(
                            content['docName'],
                            'videopost',
                            content['topic'],
                            content['description'],
                            content['thumbnail'],
                          ),
                          upvoteCount: (content['likes']).length,
                          downvoteCount: (content['dislikes']).length,
                          commentCount: content['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NonliveVideoPlayer(
                                  docName: content['docName'],
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

              /*   InkWell(
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
                  color: kCardBackgroundColor,
                  child: Column(
                    children: [
                      FeaturedVideoCard(
                        userInfoClicked: () => showUserQuickInfo(
                            content['opusername'], content['opuid']),
                        onlineuid: onlineuser!.uid!,
                        opuid: content['opuid'],
                        opusername: content['opusername'],
                        oppic: content['oppic'],
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
                                          uid: content['opuid'],
                                          pic: content['oppic'],
                                          username: content['opusername'],
                                        ),
                                        whethercommunitypost:
                                            content['whethercommunitypost'],
                                        communityName: content['communityName'],
                                        communitypic: content['communitypic'],
                                        whetherediting: true,
                                        whetherfrompost: false,
                                        docName: content['docName'],
                                      )))).then(
                              (whetheredited) => (whetheredited != null)
                                  ? setState(() {
                                      getcommunitydata();
                                      print("updating post...");
                                    })
                                  : null);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: UpDownVoteWidget(
                          whetherUpvoted:
                              content['likes'].contains(onlineuser!.uid),
                          whetherDownvoted:
                              content['dislikes'].contains(onlineuser!.uid),
                          onUpvoted: () {
                            upvoteContent(content['docName']);
                          },
                          onDownvoted: () {
                            downvoteContent(content['docName']);
                          },
                          onShared: shareContent,
                          upvoteCount: (content['likes']).length,
                          downvoteCount: (content['dislikes']).length,
                          commentCount: content['commentcount'],
                          onComment: () {
                            setState(() {
                              hidenav = true;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NonliveVideoPlayer(
                                  whethercommunitypost:
                                      content['whethercommunitypost'],
                                  communityName: content['communityName'],
                                  communitypic: content['communitypic'],
                                  docName: content['docName'],
                                  videourl: content['link'],
                                  portraitonly: content['portraitonly'],
                                  showcomments: false,
                                  whetherjustcreated: false,
                                ),
                                fullscreenDialog: true,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );*/
            } else {
              return Container();
            }
          },
        );
      },
    );
  }

  selectContentFormat() {
    showCupertinoModalPopup(
      useRootNavigator: false,
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("What'd you like to post?",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kSubTextColor,
                  fontSize: 17.0,
                  fontWeight: FontWeight.w500,
                )),
        actions: <CupertinoActionSheetAction>[
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
                  builder: (context) => PostLink(
                    onlineuser: onlineuser,
                    whethercommunitypost: true,
                    communityName: communityname,
                    communityPic: mainimage,
                    whetherediting: false,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Text(
              'Link',
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
                  builder: (context) => PostText(
                    whetherediting: false,
                    onlineuser: onlineuser,
                    whethercommunitypost: true,
                    communityName: communityname,
                    communitypic: mainimage,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Text(
              'Text',
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
                  builder: (context) => PostImage(
                    whetherediting: false,
                    onlineuser: onlineuser,
                    whethercommunitypost: true,
                    communityName: communityname,
                    communitypic: mainimage,
                  ),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Text(
              'Image',
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
                  builder: ((context) => UploadVideoPage(
                        onlineuser: onlineuser,
                        whethercommunitypost: true,
                        communityName: communityname,
                        communitypic: mainimage,
                        whetherediting: false,
                      )),
                  fullscreenDialog: true,
                ),
              );
            },
            child: Text(
              'Video',
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
      ),
    );
  }

  contentBottomSheet() {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalsetState) {
            return Container(
              color: Colors.black,
              child: (selectedContentFormat == '')
                  ? Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Wrap(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 100.0, right: 100.0),
                            child: Divider(
                              thickness: 4,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: ContentFormatCard(
                              whetherupcoming: false,
                              onPress: () {
                                modalsetState(() {
                                  selectedContentFormat = 'linkpost';
                                });
                              },
                              icon: Icons.link,
                              title: 'Share a link',
                              subtitle: 'to a news article or a cool blog.',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: ContentFormatCard(
                              whetherupcoming: false,
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
                                      whethercommunitypost: true,
                                      communityName: communityname,
                                      communitypic: mainimage,
                                    ),
                                    fullscreenDialog: true,
                                  ),
                                );
                              },
                              icon: Icons.create,
                              title: 'Publish your thoughts',
                              subtitle: 'in good old text format.',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: ContentFormatCard(
                              whetherupcoming: false,
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
                                      whethercommunitypost: true,
                                      communityName: communityname,
                                      communitypic: mainimage,
                                    ),
                                    fullscreenDialog: true,
                                  ),
                                );
                              },
                              icon: Icons.image,
                              title: 'Post an image',
                              subtitle: 'or a cool GIF maybe?',
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: ContentFormatCard(
                              whetherupcoming: false,
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
                                          whethercommunitypost: true,
                                          communityName: communityname,
                                          communitypic: mainimage,
                                          whetherediting: false,
                                        )),
                                    fullscreenDialog: true,
                                  ),
                                );
                              },
                              icon: Icons.video_collection,
                              title: 'Upload a video',
                              subtitle: 'and reap internet points.',
                            ),
                          ),
                        ],
                      ),
                    )
                  : (selectedContentFormat == 'linkpost')
                      ? Wrap(
                          //mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                  left: 100.0, right: 100.0),
                              child: Divider(
                                thickness: 5,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: CustomCreateField(
                                  whetherreadonly: false,
                                  maxlines: 1,
                                  mincharlength: 3,
                                  maxcharlength: 2048,
                                  maxlength: null,
                                  controller: linkController,
                                  label: "Paste link here",
                                  iconData: Icons.link_outlined),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.center,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: TextButton(
                                  onPressed: () {
                                    setState(() {
                                      hidenav = true;
                                    });
                                    AppBuilder.of(context)!.rebuild();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PostLink(
                                          whetherediting: false,
                                          onlineuser: onlineuser,
                                          whethercommunitypost: true,
                                          communityName: widget.communityname,
                                          communityPic: mainimage,
                                        ),
                                        fullscreenDialog: true,
                                      ),
                                    );
                                  },
                                  child: Text("Next",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                            color: kPrimaryColor,
                                            fontWeight: FontWeight.bold,
                                          )),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(),
            );
          });
        }).whenComplete(() {
      setState(() {
        selectedContentFormat = '';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (widget.hideNavLinkReturn != null) {
          print("returning from link");
          hidenav = widget.hideNavLinkReturn!;
          AppBuilder.of(context)!.rebuild();
          Navigator.pop(context);
        } else {
          if (widget.whetherjustcreated == false) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
        return Future.value(false);
      },
      child: (dataisthere == false)
          ? Scaffold(
              appBar: AppBar(
                leading: GestureDetector(
                  onTap: () {
                    if (widget.hideNavLinkReturn != null) {
                      print("returning from link");
                      hidenav = widget.hideNavLinkReturn!;
                      AppBuilder.of(context)!.rebuild();
                      Navigator.pop(context);
                    } else {
                      if (widget.whetherjustcreated == false) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      }
                    }
                  },
                  child: const Icon(
                    Icons.arrow_back,
                  ),
                ),
              ),
              body: const Center(
                  child: CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              )),
            )
          : (checkwhetherblocked == true)
              ? Scaffold(
                  appBar: AppBar(
                    leading: GestureDetector(
                      onTap: () {
                        if (widget.hideNavLinkReturn != null) {
                          print("returning from link");
                          hidenav = widget.hideNavLinkReturn!;
                          AppBuilder.of(context)!.rebuild();
                          Navigator.pop(context);
                        } else {
                          if (widget.whetherjustcreated == false) {
                            Navigator.of(context).pop();
                          } else {
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          }
                        }
                      },
                      child: const Icon(
                        Icons.arrow_back,
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
                          child: Text(
                              "You have blocked or reported c/$communityname community. Unblock the user first to view profile.",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(color: Colors.white)),
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
                              unblockCommunity();
                            }),
                      ],
                    )),
                  ),
                )
              : (checkwhetherdeleted == true)
                  ? Scaffold(
                      appBar: AppBar(
                        leading: GestureDetector(
                          onTap: () {
                            if (widget.hideNavLinkReturn != null) {
                              print("returning from link");
                              hidenav = widget.hideNavLinkReturn!;
                              AppBuilder.of(context)!.rebuild();
                              Navigator.pop(context);
                            } else {
                              if (widget.whetherjustcreated == false) {
                                Navigator.of(context).pop();
                              } else {
                                Navigator.of(context)
                                    .popUntil((route) => route.isFirst);
                              }
                            }
                          },
                          child: const Icon(
                            Icons.arrow_back,
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
                              child: Text("c/${widget.communityname} deleted.",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(color: Colors.white)),
                            ),
                          ],
                        )),
                      ),
                    )
                  : Scaffold(
                      appBar: PreferredSize(
                        preferredSize: const Size.fromHeight(0),
                        child: AppBar(
                          backgroundColor: kBackgroundColorDark2,
                          systemOverlayStyle: const SystemUiOverlayStyle(
                            statusBarColor: kBackgroundColorDark2,
                            statusBarBrightness: Brightness.dark,
                          ),
                        ),
                      ),
                      body: SafeArea(
                        child: RefreshIndicator(
                          onRefresh: _pulltoRefreshCommunity,
                          child: CustomScrollView(
                            slivers: [
                              //
                              SliverAppBar(
                                toolbarHeight: 50,
                                actions: [
                                  moreOptions(),
                                ],
                                leading: GestureDetector(
                                  onTap: () {
                                    if (widget.hideNavLinkReturn != null) {
                                      print("returning from link");
                                      hidenav = widget.hideNavLinkReturn!;
                                      AppBuilder.of(context)!.rebuild();
                                      Navigator.pop(context);
                                    } else {
                                      if (widget.whetherjustcreated == false) {
                                        Navigator.of(context).pop();
                                      } else {
                                        Navigator.of(context)
                                            .popUntil((route) => route.isFirst);
                                      }
                                    }
                                  },
                                  child: (backgroundimage == '')
                                      ? const Icon(Icons.arrow_back)
                                      : const Icon(
                                          CupertinoIcons.arrow_left_circle_fill,
                                          size: 30,
                                          color: Colors.white70,
                                        ),
                                ),
                                pinned: true,
                                backgroundColor: kBackgroundColorDark2,
                                expandedHeight:
                                    (backgroundimage == '') ? 0 : 200,
                                flexibleSpace: (backgroundimage == '')
                                    ? null
                                    : FlexibleSpaceBar(
                                        background: Image.network(
                                          backgroundimage,
                                          width: double.maxFinite,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                              ),
                              //
                              SliverToBoxAdapter(
                                //height: MediaQuery.of(context).size.height,
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                height: 60,
                                                width: 60,
                                                decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                    image:
                                                        NetworkImage(mainimage),
                                                    fit: BoxFit.cover,
                                                  ),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 16,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      "c/$communityname",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyText2!
                                                          .copyWith(
                                                              fontSize: 16.0,
                                                              color:
                                                                  Colors.white,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                    ),
                                                    Text(
                                                        (membercount == 1)
                                                            ? "$membercount member"
                                                            : "$membercount members",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .subtitle2!
                                                            .copyWith(
                                                              fontSize: 12.0,
                                                              letterSpacing:
                                                                  0.5,
                                                              color: Colors.grey
                                                                  .shade500,
                                                            )),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 16,
                                              ),
                                              (whetherjoined == false)
                                                  ? RoundedLabel(
                                                      onPress: joinCommunity,
                                                      small: true,
                                                      bordercolor:
                                                          kPrimaryColorTint2,
                                                      textcolor:
                                                          kPrimaryColorTint2,
                                                      text: "Join",
                                                    )
                                                  : RoundedLabel(
                                                      onPress:
                                                          showCommunityLeaveAlert,
                                                      small: true,
                                                      bordercolor:
                                                          kPrimaryColorTint2,
                                                      textcolor:
                                                          kPrimaryColorTint2,
                                                      text: "Joined",
                                                    ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Text(communitydescription,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .subtitle2!
                                                  .copyWith(
                                                    fontSize: 12.0,
                                                    letterSpacing: 0.5,
                                                    color: Colors.white,
                                                  )),
                                          const SizedBox(
                                            height: 5.0,
                                          ),
                                        ],
                                      ),
                                    ),
                                    communityContentStream(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      floatingActionButton: FloatingActionButton(
                        onPressed: () {
                          selectContentFormat();
                        },
                        child: const Icon(
                          Icons.add,
                          color: kHeadlineColorDark,
                        ),
                        backgroundColor: kPrimaryColor,
                      ),
                    ),
    );
  }
}
