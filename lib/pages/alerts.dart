import 'package:challo/models/link_to.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/community_page.dart';
import 'package:challo/pages/image_page_2.dart';
import 'package:challo/pages/linkpage.dart';
import 'package:challo/pages/nonlive_video_player.dart';
import 'package:challo/pages/profilepage.dart';
import 'package:challo/pages/text_content_page.dart';
import 'package:challo/pages/videoplayerpage.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tago;
import 'dart:async';

class AlertsPage extends StatefulWidget {
  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  String? onlineuid, onlineusername, onlinepic;
  bool dataisthere = false;
  bool stoploading = false;
  bool firstcheckover = false;
  Timer? timer;
  bool linkDataLoading = false;

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
      stoploading = true;
    }

    firstcheckover = true;
  }

  checkconnected() {
    if (connected == true) {
      stoploading = true;
    }
  }

  getalldata() async {
    print("fetching user data for AlertsPage");
    onlineuid = FirebaseAuth.instance.currentUser!.uid;

    await usercollection.doc(onlineuid).get().then((onlineuserdoc) => {
          onlineusername = onlineuserdoc['username'],
          onlinepic = onlineuserdoc['profilepic'],
        });
    if (!mounted) return;
    setState(() {
      dataisthere = true;
    });
  }

  Widget alertStreamWidget() {
    return StreamBuilder<QuerySnapshot>(
      stream: usercollection
          .doc(onlineuid)
          .collection('alerts001')
          .orderBy('time', descending: true)
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
          return Center(
              child: Container(
            child: Text(
              "No new notifications.",
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    color: Colors.white,
                    fontSize: 15.0,
                  ),
            ),
          ));
        }
        return ListView.builder(
            //reverse: true,
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: snapshot.data.docs.length,
            itemBuilder: (BuildContext context, int index) {
              var alert = snapshot.data.docs[index];
              return Card(
                color: kCardBackgroundColor,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  title: Text(
                    "${alert['text']}",
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          fontSize: 15,
                          //fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  subtitle: Text(
                    "• ${tago.format(alert['time'].toDate())} •",
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          fontSize: 12,
                          //fontWeight: FontWeight.bold,
                          fontWeight: FontWeight.w900,
                          color: kBodyTextColorDark,
                        ),
                  ),
                ),
              );
            });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (linkedPage != null &&
        selectedTabIndex == 3 &&
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
        : Scaffold(
            appBar: AppBar(
              title: const Text(
                "Alerts",
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: (dataisthere == false)
                  ? const Center(
                      child: CupertinoActivityIndicator(
                      color: kDarkPrimaryColor,
                    ))
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: alertStreamWidget(),
                    ),
            ),
          );
  }
}
