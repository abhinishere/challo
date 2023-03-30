import 'dart:async';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/helpers/share_service.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/audiencepage.dart';
import 'package:challo/pages/community_page.dart';
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
import 'package:challo/widgets/featured_live_card.dart';
import 'package:challo/widgets/featured_text_card.dart';
import 'package:challo/widgets/featured_video_card.dart';
import 'package:challo/widgets/featuredlinkcard.dart';
import 'package:challo/widgets/updownvotewidget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tago;
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

//whetherretainsearch is true if the user clicks on...
//text box for pushing the String to new ContentResults page
//whetheretainsearch is false when user clicks on clear after making...
//a search -- also push to new ContentResults page;...
//but if not searched, just clear textcontroller

class ContentResults extends StatefulWidget {
  final bool whetherretainsearch;
  final bool notonfirstpage;
  final String searchedstring;
  final String filterBy;
  const ContentResults({
    required this.filterBy,
    required this.whetherretainsearch,
    required this.notonfirstpage,
    required this.searchedstring, //empty string when whethersuggestions == true
  });
  @override
  State<ContentResults> createState() => _ContentResultsState();
}

class _ContentResultsState extends State<ContentResults> {
  TextEditingController videosearchcontroller = TextEditingController();
  Future<QuerySnapshot>? postsuggestions;
  Future<QuerySnapshot>? communitysuggestions;
  Future<QuerySnapshot>? usersuggestions;
  Future<QuerySnapshot>? postsearchresult;
  Future<QuerySnapshot>? communitysearchresult;
  Future<QuerySnapshot>? usersearchresult;
  bool showloading = false;

  //Future<QuerySnapshot>? videosuggestionsresult;
  late String filterBy;
  //String selectedSearchType = "Posts";
  List<String> filterTypes = [
    "Posts",
    "Communities",
    "Users",
  ];
  RegExp exp = RegExp(r'[\s,;/.!:?({\[&)\]}]+');
  bool whethersuggestions = true;
  bool whethersearched =
      false; //if whethersearched true, navigate to a new ContentResults page
  bool dataisthere = false;
  bool fieldreadonly = false;
  bool whetherretainsearch = true;
  bool backbuttonretain = false;
  String? onlineuid, onlineusername, onlinepic;
  List<String> blockedusers = [];
  List<String> hiddenusers = [];
  bool whethercontentreportsubmitted = false;
  int? selectedContentRadioNo = 1;
  String contentReportReason = "Spam or misleading";
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateRandomDocName(String username) {
    String newDocName = (username + getRandomString(5));
    return newDocName;
  }

  searchcontent(String searchquery) {
    setState(() {
      showloading = true;
    });

    final String searchqueryinlowercase = searchquery.toLowerCase();
    final List<String> searchqueryinlist = searchqueryinlowercase.split(exp);
    searchqueryinlist.removeWhere((value) => value == "");
    if (filterBy == "Posts") {
      postsuggestions = null;
      whethersuggestions = false;
      postsearchresult = contentcollection
          .where('topicinlist', arrayContainsAny: searchqueryinlist)
          //.where('topicinlist', isLessThan: typedqueryinlowercase + 'z')
          .get()
          .whenComplete(() => {
                setState(() {
                  showloading = false;
                })
              });
    } else if (filterBy == "Communities") {
      communitysuggestions = null;
      whethersuggestions = false;
      communitysearchresult = communitycollection
          .where('nameinlowercase', whereIn: searchqueryinlist)
          .get()
          .whenComplete(() => {
                setState(() {
                  showloading = false;
                })
              });
    } else {
      //users
      usersuggestions = null;
      whethersuggestions = false;
      usersearchresult = usercollection
          .where('username', isGreaterThanOrEqualTo: searchqueryinlowercase)
          .where('username', isLessThan: "${searchqueryinlowercase}z")
          .get()
          .whenComplete(() => {
                setState(() {
                  showloading = false;
                })
              });
    }
  }

  givesuggestions(String typedquery) {
    setState(() {
      showloading = true;
    });
    final String typedqueryinlowercase = typedquery.toLowerCase();

    if (filterBy == "Posts") {
      postsuggestions = suggestionscollection
          .where('keyword', isGreaterThanOrEqualTo: typedqueryinlowercase)
          .where('keyword', isLessThan: "${typedqueryinlowercase}z")
          .get()
          .whenComplete(() => {
                setState(() {
                  showloading = false;
                })
              });
    } else if (filterBy == "Communities") {
      communitysuggestions = communitycollection
          .where('nameinlowercase',
              isGreaterThanOrEqualTo: typedqueryinlowercase)
          .where('nameinlowercase', isLessThan: "${typedqueryinlowercase}z")
          .get()
          .whenComplete(() => {
                setState(() {
                  showloading = false;
                })
              });
    } else {
      usersuggestions = usercollection
          .where('username', isGreaterThanOrEqualTo: typedqueryinlowercase)
          .where('username', isLessThan: "${typedqueryinlowercase}z")
          .where('username', isNotEqualTo: onlineusername)
          .get()
          .whenComplete(() => {
                setState(() {
                  showloading = false;
                })
              });
    }
  }

  clearSearch() {
    if (whethersearched == true) {
      setState(() {
        whetherretainsearch = false;
      });
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ContentResults(
                  filterBy: filterBy,
                  whetherretainsearch: whetherretainsearch,
                  //whethersuggestions: true,
                  notonfirstpage: true,
                  searchedstring: videosearchcontroller.text))).then((value) {
        if (value == true) {
          setState(() {
            whetherretainsearch = true;
          });
        }
      });
    } else {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => videosearchcontroller.clear());
      setState(() {
        postsuggestions = null;
        communitysuggestions = null;
        usersuggestions = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getalldata();
    /*setState(() {
      whethersuggestions = widget.whethersuggestions;
    });
    if (whethersuggestions == false) {
      setState(() {
        videosearchcontroller.text = widget.searchedstring;
      });
      searchvideo(widget.searchedstring);
    }*/
  }

  getalldata() async {
    filterBy = widget.filterBy;
    onlineuid = FirebaseAuth.instance.currentUser!.uid;

    var onlineuserdocs = await usercollection.doc(onlineuid).get();

    onlineusername = onlineuserdocs['username'];
    onlinepic = onlineuserdocs['profilepic'];
    blockedusers = List.from(onlineuserdocs['blockedusers']);
    hiddenusers = List.from(onlineuserdocs['hiddenusers']);

    if (widget.whetherretainsearch == true) {
      setState(() {
        videosearchcontroller.text = widget.searchedstring;
      });
    }
    setState(() {
      dataisthere = true;
    });
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

  /*Widget featuredImageCard(
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
                (onlineuid == opuid)
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
                                          getalldata();
                                          print("updating post...");
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

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
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
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalsetState) {
            return Container(
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
                                      color: Colors.white, fontSize: 15.0),
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

  Widget filterButton(String newfilter, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (videosearchcontroller.text.isEmpty) {
          if (filterBy != newfilter) {
            setState(() {
              filterBy = newfilter;
            });
          }
        } else {
          if (filterBy != newfilter) {
            setState(() {
              filterBy = newfilter;
            });
            if (whethersearched == false) {
              givesuggestions(videosearchcontroller.text);
            } else {
              searchcontent(videosearchcontroller.text);
            }
          }
        }
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        margin: const EdgeInsets.only(left: 8),
        height: 30,
        decoration: BoxDecoration(
            color: isSelected ? kPrimaryColorTint : const Color(0xFF7f7f7f),
            borderRadius: BorderRadius.circular(5)),
        child: Text(
          newfilter,
          style: TextStyle(
            color: isSelected ? kHeadlineColorDark : kHeadlineColorDarkShade,
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Container(),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
            child: Row(
              children: [
                Text("Filter by",
                    style: Theme.of(context).textTheme.displayMedium!.copyWith(
                          fontSize: 12.0,
                          color: kParaColorDark,
                          fontWeight: FontWeight.normal,
                        )),
                Expanded(
                  child: Container(
                    height: 30,
                    child: ListView.builder(
                        itemCount: filterTypes.length,
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemBuilder: ((context, index) {
                          return filterButton(
                            filterTypes[index],
                            filterBy == filterTypes[index],
                          );
                        })),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              if (widget.notonfirstpage == true) {
                backbuttonretain = true;
                Navigator.pop(context, backbuttonretain);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.arrow_back,
              ),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                top: 5.0,
                bottom: 5.0,
              ),
              child: TextFormField(
                readOnly: whethersearched,
                onTap: () {
                  if (whethersearched == true) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ContentResults(
                                filterBy: filterBy,
                                whetherretainsearch: whetherretainsearch,
                                //whethersuggestions: true,
                                notonfirstpage: true,
                                searchedstring:
                                    videosearchcontroller.text))).then((value) {
                      if (value == true) {
                        setState(() {
                          whetherretainsearch = true;
                        });
                      }
                    });
                    print("whethersearched is $whethersearched");
                    print(
                        "videosearchcontroller is ${videosearchcontroller.text}");
                    print(
                        "whetherretainsearch is ${widget.whetherretainsearch} and $whetherretainsearch");
                  }
                },
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (text) {
                  if (text == null || text.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        postsuggestions = null;
                        communitysuggestions = null;
                        usersuggestions = null;
                      });
                    });

                    return null;
                  }
                  return null;
                },
                onFieldSubmitted: (searchquery) {
                  searchcontent(searchquery);
                  setState(() {
                    whethersearched = true;
                  });
                },
                autofocus: true,
                cursorColor: kHeadlineColorDark,
                controller: videosearchcontroller,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: "Search $filterBy...",
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
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 5.0, left: 5.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                      onPressed: () => clearSearch(),
                    ),
                  ),
                ),
                onChanged: (input) {
                  if (input.isNotEmpty) {
                    setState(() {
                      givesuggestions(input);
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: (dataisthere == false)
          ? const Center(
              child: CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    (whethersuggestions == true)
                        ? Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: (postsuggestions == null &&
                                      communitysuggestions == null &&
                                      usersuggestions == null)
                                  ? Center(
                                      child: Container(
                                      child: SingleChildScrollView(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.search,
                                              color: kIconSecondaryColorDark,
                                              size: 100,
                                            ),
                                            const SizedBox(height: 10),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10),
                                              child: Text(
                                                'Select from suggestions or press enter to complete search',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .displayMedium!
                                                    .copyWith(
                                                      color: kSubTextColor,
                                                      fontSize: 13.0,
                                                    ),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ))
                                  : (filterBy == "Posts")
                                      ? (showloading == true)
                                          ? const Center(
                                              child: CupertinoActivityIndicator(
                                              color: kDarkPrimaryColor,
                                            ))
                                          : FutureBuilder<QuerySnapshot>(
                                              future: postsuggestions,
                                              builder: (BuildContext context,
                                                  AsyncSnapshot snapshot) {
                                                if (!snapshot.hasData) {
                                                  return const Center(
                                                      child:
                                                          CupertinoActivityIndicator(
                                                    color: kDarkPrimaryColor,
                                                  ));
                                                }
                                                if (snapshot.data.docs.length ==
                                                    0) {
                                                  return Center(
                                                    child: Container(),
                                                  );
                                                }
                                                return ListView.builder(
                                                  keyboardDismissBehavior:
                                                      ScrollViewKeyboardDismissBehavior
                                                          .onDrag,
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  shrinkWrap: true,
                                                  itemCount:
                                                      snapshot.data.docs.length,
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    var suggestion = snapshot
                                                        .data.docs[index];
                                                    return Column(
                                                      children: [
                                                        InkWell(
                                                          onTap: () {
                                                            searchcontent(
                                                                suggestion[
                                                                    'keyword']);
                                                            videosearchcontroller
                                                                    .text =
                                                                suggestion[
                                                                    'keyword'];

                                                            setState(() {
                                                              whethersuggestions =
                                                                  false;
                                                              whethersearched =
                                                                  true;
                                                            });
                                                          },
                                                          child: ListTile(
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15.0),
                                                            ),
                                                            title: Text(
                                                              "${suggestion['keyword']}",
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ),
                                                        ),
                                                        Divider(
                                                          height: 1.0,
                                                          indent: 1.0,
                                                          color: Colors
                                                              .grey.shade700,
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              })
                                      : (filterBy == "Communities")
                                          ? (showloading == true)
                                              ? const Center(
                                                  child:
                                                      CupertinoActivityIndicator(
                                                  color: kDarkPrimaryColor,
                                                ))
                                              : FutureBuilder<QuerySnapshot>(
                                                  future: communitysuggestions,
                                                  builder: (BuildContext
                                                          context,
                                                      AsyncSnapshot snapshot) {
                                                    if (!snapshot.hasData) {
                                                      return const Center(
                                                          child:
                                                              CupertinoActivityIndicator(
                                                        color:
                                                            kDarkPrimaryColor,
                                                      ));
                                                    }
                                                    if (snapshot
                                                            .data.docs.length ==
                                                        0) {
                                                      return Center(
                                                        child: Container(),
                                                      );
                                                    }
                                                    return ListView.builder(
                                                      keyboardDismissBehavior:
                                                          ScrollViewKeyboardDismissBehavior
                                                              .onDrag,
                                                      scrollDirection:
                                                          Axis.vertical,
                                                      shrinkWrap: true,
                                                      itemCount: snapshot
                                                          .data.docs.length,
                                                      itemBuilder:
                                                          (BuildContext context,
                                                              int index) {
                                                        var suggestion =
                                                            snapshot.data
                                                                .docs[index];
                                                        return Column(
                                                          children: [
                                                            InkWell(
                                                              onTap: () {
                                                                searchcontent(
                                                                    suggestion[
                                                                        'name']);
                                                                videosearchcontroller
                                                                        .text =
                                                                    suggestion[
                                                                        'name'];

                                                                setState(() {
                                                                  whethersuggestions =
                                                                      false;
                                                                  whethersearched =
                                                                      true;
                                                                });
                                                              },
                                                              child: ListTile(
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              15.0),
                                                                ),
                                                                title: Text(
                                                                  "${suggestion['name']}",
                                                                  style: const TextStyle(
                                                                      color: Colors
                                                                          .white),
                                                                ),
                                                              ),
                                                            ),
                                                            Divider(
                                                              height: 1.0,
                                                              indent: 1.0,
                                                              color: Colors.grey
                                                                  .shade700,
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  })
                                          : (showloading == true)
                                              ? const Center(
                                                  child:
                                                      CupertinoActivityIndicator(
                                                  color: kDarkPrimaryColor,
                                                ))
                                              : FutureBuilder(
                                                  future: usersuggestions,
                                                  builder: (BuildContext
                                                          context,
                                                      AsyncSnapshot snapshot) {
                                                    if (!snapshot.hasData) {
                                                      return const Center(
                                                          child:
                                                              CupertinoActivityIndicator(
                                                        color:
                                                            kDarkPrimaryColor,
                                                      ));
                                                    }
                                                    if (snapshot
                                                            .data.docs.length ==
                                                        0) {
                                                      return Center(
                                                        child: Container(),
                                                      );
                                                    }
                                                    return ListView.builder(
                                                        keyboardDismissBehavior:
                                                            ScrollViewKeyboardDismissBehavior
                                                                .onDrag,
                                                        scrollDirection:
                                                            Axis.vertical,
                                                        shrinkWrap: true,
                                                        itemCount: snapshot
                                                            .data.docs.length,
                                                        itemBuilder:
                                                            (BuildContext
                                                                    context,
                                                                int index) {
                                                          var user = snapshot
                                                              .data.docs[index];
                                                          if (!blockedusers
                                                                  .contains(user[
                                                                      'uid']) &&
                                                              (user['accountStatus'] !=
                                                                  'deleted')) {
                                                            return InkWell(
                                                              onTap: () {
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder: (context) =>
                                                                            ProfilePage(
                                                                              uid: user['uid'],
                                                                              whetherShowArrow: true,
                                                                            )));
                                                              },
                                                              child: ListTile(
                                                                leading:
                                                                    CircleAvatar(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white,
                                                                  backgroundImage:
                                                                      NetworkImage(
                                                                          user[
                                                                              'profilepic']),
                                                                ),
                                                                title: Text(
                                                                  user[
                                                                      'username'],
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            return Container();
                                                          }
                                                        });
                                                  }),
                            ),
                          )
                        : (filterBy == "Posts")
                            ? (showloading == true)
                                ? const Center(
                                    child: CupertinoActivityIndicator(
                                    color: kDarkPrimaryColor,
                                  ))
                                : Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: (showloading == true)
                                          ? const Center(
                                              child: CupertinoActivityIndicator(
                                              color: kDarkPrimaryColor,
                                            ))
                                          : FutureBuilder<QuerySnapshot>(
                                              future: postsearchresult,
                                              builder: (BuildContext context,
                                                  AsyncSnapshot snapshot) {
                                                if (!snapshot.hasData) {
                                                  return const Center(
                                                      child:
                                                          CupertinoActivityIndicator(
                                                    color: kDarkPrimaryColor,
                                                  ));
                                                }
                                                if (snapshot.data.docs.length ==
                                                    0) {
                                                  return const Center(
                                                    child: Text('No results.',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          color: Colors.white,
                                                        )),
                                                  );
                                                }
                                                return ListView.builder(
                                                  keyboardDismissBehavior:
                                                      ScrollViewKeyboardDismissBehavior
                                                          .onDrag,
                                                  //reverse: true,
                                                  physics:
                                                      const ScrollPhysics(),
                                                  scrollDirection:
                                                      Axis.vertical,
                                                  shrinkWrap: true,
                                                  itemCount:
                                                      snapshot.data.docs.length,
                                                  itemBuilder:
                                                      (BuildContext context,
                                                          int index) {
                                                    var video = snapshot
                                                        .data.docs[index];
                                                    if (((video['type'] ==
                                                                'QnA') ||
                                                            (video['type'] ==
                                                                'Debate') ||
                                                            (video['type'] ==
                                                                'Podcast')) &&
                                                        (video['status'] ==
                                                            'published') &&
                                                        (!video['blockedby']
                                                            .contains(
                                                                onlineuid)) &&
                                                        (!List.from(video['participateduids'])
                                                            .any((e) =>
                                                                blockedusers
                                                                    .contains(
                                                                        e))) &&
                                                        (!List.from(video['participateduids'])
                                                            .any((e) =>
                                                                hiddenusers
                                                                    .contains(
                                                                        e)))) {
                                                      return Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          border: Border(
                                                            top: BorderSide(
                                                                width: 5.0,
                                                                color:
                                                                    kBackgroundColorDark2),
                                                          ),
                                                        ),
                                                        child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              hidenav = true;
                                                            });
                                                            AppBuilder.of(
                                                                    context)!
                                                                .rebuild();
                                                            (video['whetherlive'] ==
                                                                    false)
                                                                ? Navigator
                                                                    .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (context) =>
                                                                              VideoPlayerPage(
                                                                        whetherjustcreated:
                                                                            false,
                                                                        docName:
                                                                            video['docName'],
                                                                        showcomments:
                                                                            false,
                                                                      ),
                                                                      fullscreenDialog:
                                                                          true,
                                                                    ),
                                                                  )
                                                                : Navigator
                                                                    .push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder: (context) => AudiencePage(
                                                                          docName: video[
                                                                              'docName'],
                                                                          role:
                                                                              ClientRole.Audience),
                                                                      fullscreenDialog:
                                                                          true,
                                                                    ),
                                                                  );
                                                          },
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                              left: 5.0,
                                                              right: 5.0,
                                                              bottom: 5.0,
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                FeaturedLiveCard(
                                                                  topic: video[
                                                                      'topic'],
                                                                  status: video[
                                                                      'status'],
                                                                  participatedusernames:
                                                                      video[
                                                                          'participatedusernames'],
                                                                  participatedpics:
                                                                      video[
                                                                          'participatedpics'],
                                                                  whethercommunitypost:
                                                                      video[
                                                                          'whethercommunitypost'],
                                                                  communityname:
                                                                      video[
                                                                          'communityName'],
                                                                  communitypic:
                                                                      video[
                                                                          'communitypic'],
                                                                  type: video[
                                                                      'type'],
                                                                  opuid: video[
                                                                      'whostarted'],
                                                                  onlineuid:
                                                                      onlineuid,
                                                                  opusername: video[
                                                                      'opusername'],
                                                                  oppic: video[
                                                                      'oppic'],
                                                                  userInfoClicked:
                                                                      () {
                                                                    if (video[
                                                                            'whethercommunitypost'] ==
                                                                        true) {
                                                                      showCommunityQuickInfo(
                                                                          video[
                                                                              'communityName'],
                                                                          video[
                                                                              'opusername'],
                                                                          video[
                                                                              'whostarted']);
                                                                    } else {
                                                                      showUserQuickInfo(
                                                                          video[
                                                                              'opusername'],
                                                                          video[
                                                                              'whostarted']);
                                                                    }
                                                                  },
                                                                  timeofposting:
                                                                      video[
                                                                          'time'],
                                                                  onReport: () {
                                                                    showPostOptionsForViewers(
                                                                        video[
                                                                            'docName'],
                                                                        video[
                                                                            'type'],
                                                                        video[
                                                                            'participateduids']);
                                                                  },
                                                                  onDelete: () {
                                                                    showPostOptionsForOP(
                                                                      video[
                                                                          'whostarted'],
                                                                      video[
                                                                          'opusername'],
                                                                      video[
                                                                          'oppic'],
                                                                      video[
                                                                          'docName'],
                                                                      video[
                                                                          'whethercommunitypost'],
                                                                      video[
                                                                          'communityName'],
                                                                      video[
                                                                          'communitypic'],
                                                                      video[
                                                                          'type'],
                                                                      video[
                                                                          'participateduids'],
                                                                      [],
                                                                    );
                                                                  },
                                                                ),
                                                                const SizedBox(
                                                                    height:
                                                                        10.0),
                                                                UpDownVoteWidget(
                                                                  whetherUpvoted: video[
                                                                          'likes']
                                                                      .contains(
                                                                          onlineuid),
                                                                  whetherDownvoted: video[
                                                                          'dislikes']
                                                                      .contains(
                                                                          onlineuid),
                                                                  onUpvoted:
                                                                      () {
                                                                    upvoteContent(
                                                                        video[
                                                                            'docName']);
                                                                  },
                                                                  onDownvoted:
                                                                      () {
                                                                    downvoteContent(
                                                                        video[
                                                                            'docName']);
                                                                  },
                                                                  onShared: () => ShareService.shareContent(
                                                                      video[
                                                                          'docName'],
                                                                      'streampost',
                                                                      video[
                                                                          'topic'],
                                                                      video[
                                                                          'description'],
                                                                      ''),
                                                                  upvoteCount:
                                                                      (video['likes'])
                                                                          .length,
                                                                  downvoteCount:
                                                                      (video['dislikes'])
                                                                          .length,
                                                                  commentCount:
                                                                      video[
                                                                          'commentcount'],
                                                                  onComment:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      hidenav =
                                                                          true;
                                                                    });
                                                                    AppBuilder.of(
                                                                            context)!
                                                                        .rebuild();
                                                                    (video['type'] ==
                                                                            'linkpost')
                                                                        ? Navigator
                                                                            .push(
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
                                                                        : Navigator
                                                                            .push(
                                                                            context,
                                                                            MaterialPageRoute(
                                                                              builder: (context) => VideoPlayerPage(
                                                                                docName: video['docName'],
                                                                                whetherjustcreated: false,
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
                                                    } else if ((video['type'] ==
                                                            'linkpost') &&
                                                        (video['status'] ==
                                                            'published') &&
                                                        (!video['blockedby']
                                                            .contains(
                                                                onlineuid)) &&
                                                        (!blockedusers.contains(
                                                            video['opuid'])) &&
                                                        (!hiddenusers.contains(
                                                            video['opuid']))) {
                                                      return Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          border: Border(
                                                            top: BorderSide(
                                                                width: 5.0,
                                                                color:
                                                                    kBackgroundColorDark2),
                                                          ),
                                                        ),
                                                        child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              hidenav = true;
                                                            });
                                                            AppBuilder.of(
                                                                    context)!
                                                                .rebuild();
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        LinkPage(
                                                                  docName: video[
                                                                      'docName'],
                                                                  whetherjustcreated:
                                                                      false,
                                                                  showcomments:
                                                                      false,
                                                                ),
                                                                fullscreenDialog:
                                                                    true,
                                                              ),
                                                            );
                                                          },
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                              left: 5.0,
                                                              right: 5.0,
                                                              bottom: 5.0,
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                FeaturedLinkCard(
                                                                  userInfoClicked:
                                                                      () {
                                                                    if (video[
                                                                            'whethercommunitypost'] ==
                                                                        true) {
                                                                      showCommunityQuickInfo(
                                                                          video[
                                                                              'communityName'],
                                                                          video[
                                                                              'opusername'],
                                                                          video[
                                                                              'opuid']);
                                                                    } else {
                                                                      showUserQuickInfo(
                                                                          video[
                                                                              'opusername'],
                                                                          video[
                                                                              'opuid']);
                                                                    }
                                                                  },
                                                                  whethercommunitypost:
                                                                      video[
                                                                          'whethercommunitypost'],
                                                                  communityname:
                                                                      video[
                                                                          'communityName'],
                                                                  communitypic:
                                                                      video[
                                                                          'communitypic'],
                                                                  onlineuid:
                                                                      onlineuid,
                                                                  opuid: video[
                                                                      'opuid'],
                                                                  opusername: video[
                                                                      'opusername'],
                                                                  oppic: video[
                                                                      'oppic'],
                                                                  image: video[
                                                                      'image'],
                                                                  topic: video[
                                                                      'topic'],
                                                                  timeofposting:
                                                                      video[
                                                                          'time'],
                                                                  domainname: video[
                                                                      'domainname'],
                                                                  launchBrowser:
                                                                      () async {
                                                                    print(
                                                                        "opening link in browser");
                                                                    openBrowserURL(
                                                                        url: video[
                                                                            'link']);
                                                                  },
                                                                  onReport: () {
                                                                    showPostOptionsForViewers(
                                                                      video[
                                                                          'docName'],
                                                                      video[
                                                                          'type'],
                                                                      [
                                                                        '${video['opuid']}'
                                                                      ],
                                                                    );
                                                                  },
                                                                  onDelete: () {
                                                                    showPostOptionsForOP(
                                                                      video[
                                                                          'opuid'],
                                                                      video[
                                                                          'opusername'],
                                                                      video[
                                                                          'oppic'],
                                                                      video[
                                                                          'docName'],
                                                                      video[
                                                                          'whethercommunitypost'],
                                                                      video[
                                                                          'communityName'],
                                                                      video[
                                                                          'communitypic'],
                                                                      video[
                                                                          'type'],
                                                                      [
                                                                        '${video['opuid']}'
                                                                      ],
                                                                      [
                                                                        video[
                                                                            'link']
                                                                      ],
                                                                    );
                                                                  },
                                                                  onEdit: () {
                                                                    setState(
                                                                        () {
                                                                      hidenav =
                                                                          true;
                                                                    });
                                                                    AppBuilder.of(
                                                                            context)!
                                                                        .rebuild();
                                                                    Navigator
                                                                        .push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                PostLink(
                                                                          url: video[
                                                                              'link'],
                                                                          whetherediting:
                                                                              true,
                                                                          whetherfrompost:
                                                                              false,
                                                                          docName:
                                                                              video['docName'],
                                                                          whethercommunitypost:
                                                                              video['whethercommunitypost'],
                                                                          communityName:
                                                                              video['communityName'],
                                                                          communityPic:
                                                                              video['communitypic'],
                                                                          onlineuser:
                                                                              UserInfoModel(
                                                                            uid:
                                                                                video['opuid'],
                                                                            pic:
                                                                                video['oppic'],
                                                                            username:
                                                                                video['opusername'],
                                                                          ),
                                                                        ),
                                                                        fullscreenDialog:
                                                                            true,
                                                                      ),
                                                                    ).then((whetheredited) => (whetheredited !=
                                                                            null)
                                                                        ? setState(
                                                                            () {
                                                                            getalldata();
                                                                            print("updating post...");
                                                                          })
                                                                        : null);
                                                                  },
                                                                ),
                                                                const SizedBox(
                                                                    height:
                                                                        10.0),
                                                                UpDownVoteWidget(
                                                                  whetherUpvoted: video[
                                                                          'likes']
                                                                      .contains(
                                                                          onlineuid),
                                                                  whetherDownvoted: video[
                                                                          'dislikes']
                                                                      .contains(
                                                                          onlineuid),
                                                                  onUpvoted:
                                                                      () {
                                                                    upvoteContent(
                                                                        video[
                                                                            'docName']);
                                                                  },
                                                                  onDownvoted:
                                                                      () {
                                                                    downvoteContent(
                                                                        video[
                                                                            'docName']);
                                                                  },
                                                                  onShared: () =>
                                                                      ShareService
                                                                          .shareContent(
                                                                    video[
                                                                        'docName'],
                                                                    'linkpost',
                                                                    video[
                                                                        'topic'],
                                                                    video[
                                                                        'description'],
                                                                    video[
                                                                        'image'],
                                                                  ),
                                                                  upvoteCount:
                                                                      (video['likes'])
                                                                          .length,
                                                                  downvoteCount:
                                                                      (video['dislikes'])
                                                                          .length,
                                                                  commentCount:
                                                                      video[
                                                                          'commentcount'],
                                                                  onComment:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      hidenav =
                                                                          true;
                                                                    });
                                                                    AppBuilder.of(
                                                                            context)!
                                                                        .rebuild();
                                                                    (video['type'] ==
                                                                            'linkpost')
                                                                        ? Navigator
                                                                            .push(
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
                                                                        : Navigator
                                                                            .push(
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
                                                    } else if ((video['type'] ==
                                                            'textpost') &&
                                                        (video['status'] ==
                                                            'published') &&
                                                        (!video['blockedby']
                                                            .contains(
                                                                onlineuid)) &&
                                                        (!blockedusers.contains(
                                                            video['opuid'])) &&
                                                        (!hiddenusers.contains(
                                                            video['opuid']))) {
                                                      return Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          border: Border(
                                                            top: BorderSide(
                                                                width: 5.0,
                                                                color:
                                                                    kBackgroundColorDark2),
                                                          ),
                                                        ),
                                                        child: InkWell(
                                                            onTap: () {
                                                              setState(() {
                                                                hidenav = true;
                                                              });
                                                              AppBuilder.of(
                                                                      context)!
                                                                  .rebuild();
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          TextContentPage(
                                                                    showcomments:
                                                                        false,
                                                                    docName: video[
                                                                        'docName'],
                                                                    whetherjustcreated:
                                                                        false,
                                                                  ),
                                                                  fullscreenDialog:
                                                                      true,
                                                                ),
                                                              );
                                                            },
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                left: 5.0,
                                                                right: 5.0,
                                                                bottom: 5.0,
                                                              ),
                                                              child: Column(
                                                                children: [
                                                                  FeaturedTextCard(
                                                                    userInfoClicked:
                                                                        () {
                                                                      if (video[
                                                                              'whethercommunitypost'] ==
                                                                          true) {
                                                                        showCommunityQuickInfo(
                                                                            video['communityName'],
                                                                            video['opusername'],
                                                                            video['opuid']);
                                                                      } else {
                                                                        showUserQuickInfo(
                                                                            video['opusername'],
                                                                            video['opuid']);
                                                                      }
                                                                    },
                                                                    opuid: video[
                                                                        'opuid'],
                                                                    onlineuid:
                                                                        onlineuid,
                                                                    onDelete:
                                                                        () {
                                                                      showPostOptionsForOP(
                                                                        video[
                                                                            'opuid'],
                                                                        video[
                                                                            'opusername'],
                                                                        video[
                                                                            'oppic'],
                                                                        video[
                                                                            'docName'],
                                                                        video[
                                                                            'whethercommunitypost'],
                                                                        video[
                                                                            'communityName'],
                                                                        video[
                                                                            'communitypic'],
                                                                        video[
                                                                            'type'],
                                                                        [
                                                                          '${video['opuid']}'
                                                                        ],
                                                                        [
                                                                          video[
                                                                              'link']
                                                                        ],
                                                                      );
                                                                    },
                                                                    onTapImage:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        hidenav =
                                                                            true;
                                                                      });
                                                                      AppBuilder.of(
                                                                              context)!
                                                                          .rebuild();
                                                                      Navigator.push(
                                                                          context,
                                                                          MaterialPageRoute(
                                                                            builder: (context) =>
                                                                                PreviewTextImage(
                                                                              whetherfromtextpost: false,
                                                                              docName: video['docName'],
                                                                              imageUrl: video['image'],
                                                                              onlineuid: onlineuid!,
                                                                            ),
                                                                            fullscreenDialog:
                                                                                true,
                                                                          ));
                                                                    },
                                                                    onReport:
                                                                        () {
                                                                      showPostOptionsForViewers(
                                                                        video[
                                                                            'docName'],
                                                                        video[
                                                                            'type'],
                                                                        [
                                                                          '${video['opuid']}'
                                                                        ],
                                                                      );
                                                                    },
                                                                    whethercommunitypost:
                                                                        video[
                                                                            'whethercommunitypost'],
                                                                    communityName:
                                                                        video[
                                                                            'communityName'],
                                                                    communitypic:
                                                                        video[
                                                                            'communitypic'],
                                                                    opusername:
                                                                        video[
                                                                            'opusername'],
                                                                    oppic: video[
                                                                        'oppic'],
                                                                    image: video[
                                                                        'image'],
                                                                    topic: video[
                                                                        'topic'],
                                                                    description:
                                                                        video[
                                                                            'description'],
                                                                    timeofposting:
                                                                        video[
                                                                            'time'],
                                                                    onEdit: () {
                                                                      setState(
                                                                          () {
                                                                        hidenav =
                                                                            true;
                                                                      });
                                                                      AppBuilder.of(
                                                                              context)!
                                                                          .rebuild();
                                                                      Navigator
                                                                          .push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              PostText(
                                                                            whetherediting:
                                                                                true,
                                                                            whetherfrompost:
                                                                                false,
                                                                            docName:
                                                                                video['docName'],
                                                                            whethercommunitypost:
                                                                                video['whethercommunitypost'],
                                                                            communityName:
                                                                                video['communityName'],
                                                                            communitypic:
                                                                                video['communitypic'],
                                                                            onlineuser:
                                                                                UserInfoModel(
                                                                              uid: video['opuid'],
                                                                              pic: video['oppic'],
                                                                              username: video['opusername'],
                                                                            ),
                                                                          ),
                                                                          fullscreenDialog:
                                                                              true,
                                                                        ),
                                                                      ).then((whetheredited) => (whetheredited !=
                                                                              null)
                                                                          ? setState(
                                                                              () {
                                                                              getalldata();
                                                                              print("updating post...");
                                                                            })
                                                                          : null);
                                                                    },
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          10.0),
                                                                  UpDownVoteWidget(
                                                                    whetherUpvoted: video[
                                                                            'likes']
                                                                        .contains(
                                                                            onlineuid),
                                                                    whetherDownvoted: video[
                                                                            'dislikes']
                                                                        .contains(
                                                                            onlineuid),
                                                                    onUpvoted:
                                                                        () {
                                                                      upvoteContent(
                                                                          video[
                                                                              'docName']);
                                                                    },
                                                                    onDownvoted:
                                                                        () {
                                                                      downvoteContent(
                                                                          video[
                                                                              'docName']);
                                                                    },
                                                                    onShared: () =>
                                                                        ShareService
                                                                            .shareContent(
                                                                      video[
                                                                          'docName'],
                                                                      'textpost',
                                                                      video[
                                                                          'topic'],
                                                                      video[
                                                                          'description'],
                                                                      video[
                                                                          'image'],
                                                                    ),
                                                                    upvoteCount:
                                                                        (video['likes'])
                                                                            .length,
                                                                    downvoteCount:
                                                                        (video['dislikes'])
                                                                            .length,
                                                                    commentCount:
                                                                        video[
                                                                            'commentcount'],
                                                                    onComment:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        hidenav =
                                                                            true;
                                                                      });
                                                                      AppBuilder.of(
                                                                              context)!
                                                                          .rebuild();
                                                                      Navigator
                                                                          .push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder: (context) =>
                                                                              TextContentPage(
                                                                            showcomments:
                                                                                false,
                                                                            docName:
                                                                                video['docName'],
                                                                            whetherjustcreated:
                                                                                false,
                                                                          ),
                                                                          fullscreenDialog:
                                                                              true,
                                                                        ),
                                                                      );
                                                                    },
                                                                  ),
                                                                ],
                                                              ),
                                                            )),
                                                      );
                                                    } else if ((video['type'] ==
                                                            'imagepost') &&
                                                        (video['status'] ==
                                                            'published') &&
                                                        (!video['blockedby']
                                                            .contains(
                                                                onlineuid)) &&
                                                        (!blockedusers.contains(
                                                            video['opuid'])) &&
                                                        (!hiddenusers.contains(
                                                            video['opuid']))) {
                                                      return Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          border: Border(
                                                            top: BorderSide(
                                                                width: 5.0,
                                                                color:
                                                                    kBackgroundColorDark2),
                                                          ),
                                                        ),
                                                        child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              hidenav = true;
                                                            });
                                                            AppBuilder.of(
                                                                    context)!
                                                                .rebuild();
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        ImagePage2(
                                                                  docName: video[
                                                                      'docName'],
                                                                  whetherjustcreated:
                                                                      false,
                                                                  showcomments:
                                                                      false,
                                                                ),
                                                                fullscreenDialog:
                                                                    true,
                                                              ),
                                                            );
                                                          },
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                              left: 5.0,
                                                              right: 5.0,
                                                              bottom: 5.0,
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                featuredImageCard(
                                                                  video[
                                                                      'docName'], //docName
                                                                  video[
                                                                      'opuid'], //opuid
                                                                  video[
                                                                      'opusername'], //opusername
                                                                  video[
                                                                      'oppic'], //oppic
                                                                  video[
                                                                      'whethercommunitypost'], //whethercommunitypost
                                                                  video[
                                                                      'communityName'], //communityName
                                                                  video[
                                                                      'communitypic'], //communitypic
                                                                  video[
                                                                      'type'], //type
                                                                  video[
                                                                      'topic'], //topic
                                                                  List.from(video[
                                                                      'imageslist']), //imageslist
                                                                  video[
                                                                      'time'], //time
                                                                ),
                                                                const SizedBox(
                                                                    height:
                                                                        10.0),
                                                                UpDownVoteWidget(
                                                                  whetherUpvoted: video[
                                                                          'likes']
                                                                      .contains(
                                                                          onlineuid),
                                                                  whetherDownvoted: video[
                                                                          'dislikes']
                                                                      .contains(
                                                                          onlineuid),
                                                                  onUpvoted:
                                                                      () {
                                                                    upvoteContent(
                                                                        video[
                                                                            'docName']);
                                                                  },
                                                                  onDownvoted:
                                                                      () {
                                                                    downvoteContent(
                                                                        video[
                                                                            'docName']);
                                                                  },
                                                                  onShared: () =>
                                                                      ShareService
                                                                          .shareContent(
                                                                    video[
                                                                        'docName'],
                                                                    'imagepost',
                                                                    video[
                                                                        'topic'],
                                                                    video[
                                                                        'description'],
                                                                    List.from(video[
                                                                        'imageslist'])[0],
                                                                  ),
                                                                  upvoteCount:
                                                                      (video['likes'])
                                                                          .length,
                                                                  downvoteCount:
                                                                      (video['dislikes'])
                                                                          .length,
                                                                  commentCount:
                                                                      video[
                                                                          'commentcount'],
                                                                  onComment:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      hidenav =
                                                                          true;
                                                                    });
                                                                    AppBuilder.of(
                                                                            context)!
                                                                        .rebuild();
                                                                    Navigator
                                                                        .push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                ImagePage2(
                                                                          docName:
                                                                              video['docName'],
                                                                          whetherjustcreated:
                                                                              false,
                                                                          showcomments:
                                                                              false,
                                                                        ),
                                                                        fullscreenDialog:
                                                                            true,
                                                                      ),
                                                                    );
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    } else if ((video['type'] ==
                                                            'videopost') &&
                                                        (video['status'] ==
                                                            'published') &&
                                                        (!video['blockedby']
                                                            .contains(
                                                                onlineuid)) &&
                                                        (!blockedusers.contains(
                                                            video['opuid'])) &&
                                                        (!hiddenusers.contains(
                                                            video['opuid']))) {
                                                      return Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          border: Border(
                                                            top: BorderSide(
                                                                width: 5.0,
                                                                color:
                                                                    kBackgroundColorDark2),
                                                          ),
                                                        ),
                                                        child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              hidenav = true;
                                                            });
                                                            AppBuilder.of(
                                                                    context)!
                                                                .rebuild();
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        NonliveVideoPlayer(
                                                                  whetherjustcreated:
                                                                      false,
                                                                  docName: video[
                                                                      'docName'],
                                                                  showcomments:
                                                                      false,
                                                                ),
                                                                fullscreenDialog:
                                                                    true,
                                                              ),
                                                            );
                                                          },
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                              left: 5.0,
                                                              right: 5.0,
                                                              bottom: 5.0,
                                                            ),
                                                            child: Column(
                                                              children: [
                                                                FeaturedVideoCard(
                                                                  thumbnailAspectRatio:
                                                                      video[
                                                                          'thumbnailAspectRatio'],
                                                                  userInfoClicked:
                                                                      () {
                                                                    if (video[
                                                                            'whethercommunitypost'] ==
                                                                        true) {
                                                                      showCommunityQuickInfo(
                                                                          video[
                                                                              'communityName'],
                                                                          video[
                                                                              'opusername'],
                                                                          video[
                                                                              'opuid']);
                                                                    } else {
                                                                      showUserQuickInfo(
                                                                          video[
                                                                              'opusername'],
                                                                          video[
                                                                              'opuid']);
                                                                    }
                                                                  },
                                                                  onlineuid:
                                                                      onlineuid!,
                                                                  opuid: video[
                                                                      'opuid'],
                                                                  opusername: video[
                                                                      'opusername'],
                                                                  oppic: video[
                                                                      'oppic'],
                                                                  thumbnail: video[
                                                                      'thumbnail'],
                                                                  whethercommunitypost:
                                                                      video[
                                                                          'whethercommunitypost'],
                                                                  communityName:
                                                                      video[
                                                                          'communityName'],
                                                                  communitypic:
                                                                      video[
                                                                          'communitypic'],
                                                                  topic: video[
                                                                      'topic'],
                                                                  timeofposting:
                                                                      video[
                                                                          'time'],
                                                                  onReport: () {
                                                                    showPostOptionsForViewers(
                                                                      video[
                                                                          'docName'],
                                                                      video[
                                                                          'type'],
                                                                      [
                                                                        '${video['opuid']}'
                                                                      ],
                                                                    );
                                                                  },
                                                                  onDelete: () {
                                                                    showPostOptionsForOP(
                                                                      video[
                                                                          'opuid'],
                                                                      video[
                                                                          'opusername'],
                                                                      video[
                                                                          'oppic'],
                                                                      video[
                                                                          'docName'],
                                                                      video[
                                                                          'whethercommunitypost'],
                                                                      video[
                                                                          'communityName'],
                                                                      video[
                                                                          'communitypic'],
                                                                      video[
                                                                          'type'],
                                                                      [
                                                                        '${video['opuid']}'
                                                                      ],
                                                                      [
                                                                        video[
                                                                            'link']
                                                                      ],
                                                                    );
                                                                  },
                                                                  onEdit: () {
                                                                    setState(
                                                                        () {
                                                                      hidenav =
                                                                          true;
                                                                    });
                                                                    AppBuilder.of(
                                                                            context)!
                                                                        .rebuild();
                                                                    Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                            builder: ((context) => UploadVideoPage(
                                                                                  onlineuser: UserInfoModel(
                                                                                    uid: video['opuid'],
                                                                                    pic: video['oppic'],
                                                                                    username: video['opusername'],
                                                                                  ),
                                                                                  whethercommunitypost: video['whethercommunitypost'],
                                                                                  communityName: video['communityName'],
                                                                                  communitypic: video['communitypic'],
                                                                                  whetherediting: true,
                                                                                  whetherfrompost: false,
                                                                                  docName: video['docName'],
                                                                                )))).then((whetheredited) => (whetheredited != null)
                                                                        ? setState(() {
                                                                            getalldata();
                                                                            print("updating post...");
                                                                          })
                                                                        : null);
                                                                  },
                                                                ),
                                                                const SizedBox(
                                                                    height:
                                                                        10.0),
                                                                UpDownVoteWidget(
                                                                  whetherUpvoted: video[
                                                                          'likes']
                                                                      .contains(
                                                                          onlineuid),
                                                                  whetherDownvoted: video[
                                                                          'dislikes']
                                                                      .contains(
                                                                          onlineuid),
                                                                  onUpvoted:
                                                                      () {
                                                                    upvoteContent(
                                                                        video[
                                                                            'docName']);
                                                                  },
                                                                  onDownvoted:
                                                                      () {
                                                                    downvoteContent(
                                                                        video[
                                                                            'docName']);
                                                                  },
                                                                  onShared: () =>
                                                                      ShareService
                                                                          .shareContent(
                                                                    video[
                                                                        'docName'],
                                                                    'videopost',
                                                                    video[
                                                                        'topic'],
                                                                    video[
                                                                        'description'],
                                                                    video[
                                                                        'thumbnail'],
                                                                  ),
                                                                  upvoteCount:
                                                                      (video['likes'])
                                                                          .length,
                                                                  downvoteCount:
                                                                      (video['dislikes'])
                                                                          .length,
                                                                  commentCount:
                                                                      video[
                                                                          'commentcount'],
                                                                  onComment:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      hidenav =
                                                                          true;
                                                                    });
                                                                    AppBuilder.of(
                                                                            context)!
                                                                        .rebuild();
                                                                    Navigator
                                                                        .push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                NonliveVideoPlayer(
                                                                          docName:
                                                                              video['docName'],
                                                                          showcomments:
                                                                              true,
                                                                          whetherjustcreated:
                                                                              false,
                                                                        ),
                                                                        fullscreenDialog:
                                                                            true,
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
                                            ),
                                    ),
                                  )
                            : (filterBy == "Communities")
                                ? (showloading == true)
                                    ? const Center(
                                        child: CupertinoActivityIndicator(
                                        color: kDarkPrimaryColor,
                                      ))
                                    : Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          child: (showloading == true)
                                              ? const Center(
                                                  child:
                                                      CupertinoActivityIndicator(
                                                  color: kDarkPrimaryColor,
                                                ))
                                              : FutureBuilder<QuerySnapshot>(
                                                  future: communitysearchresult,
                                                  builder: (BuildContext
                                                          context,
                                                      AsyncSnapshot snapshot) {
                                                    if (!snapshot.hasData) {
                                                      return const Center(
                                                          child:
                                                              CupertinoActivityIndicator(
                                                        color:
                                                            kDarkPrimaryColor,
                                                      ));
                                                    }
                                                    if (snapshot
                                                            .data.docs.length ==
                                                        0) {
                                                      return const Center(
                                                        child: Text(
                                                            'No results.',
                                                            style: TextStyle(
                                                              fontSize: 20,
                                                              color:
                                                                  Colors.white,
                                                            )),
                                                      );
                                                    }
                                                    return ListView.builder(
                                                      keyboardDismissBehavior:
                                                          ScrollViewKeyboardDismissBehavior
                                                              .onDrag,
                                                      reverse: false,
                                                      physics:
                                                          const ScrollPhysics(),
                                                      scrollDirection:
                                                          Axis.vertical,
                                                      shrinkWrap: true,
                                                      itemCount: snapshot
                                                          .data.docs.length,
                                                      itemBuilder:
                                                          (BuildContext context,
                                                              int index) {
                                                        var community = snapshot
                                                            .data.docs[index];
                                                        if (community[
                                                                'status'] ==
                                                            'published') {
                                                          return InkWell(
                                                            onTap: () {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          CommunityPage(
                                                                    whetherjustcreated:
                                                                        false,
                                                                    communityname:
                                                                        community[
                                                                            'name'],
                                                                  ),
                                                                ),
                                                              );
                                                            },
                                                            child: Card(
                                                              color:
                                                                  kCardBackgroundColor,
                                                              child: Container(
                                                                //height: 100,
                                                                //width: 150,
                                                                child: Column(
                                                                  mainAxisSize:
                                                                      MainAxisSize
                                                                          .min,
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Container(
                                                                      margin: const EdgeInsets
                                                                              .only(
                                                                          bottom:
                                                                              10.0),
                                                                      child: Stack(
                                                                          clipBehavior: Clip
                                                                              .none,
                                                                          alignment:
                                                                              Alignment.center,
                                                                          children: [
                                                                            Container(
                                                                              color: Colors.grey,
                                                                              child: Image.network(
                                                                                community['backgroundimage'],
                                                                                fit: BoxFit.fitWidth,
                                                                                height: 100,
                                                                                width: MediaQuery.of(context).size.width,
                                                                              ),
                                                                            ),
                                                                            Positioned(
                                                                              top: 85,
                                                                              left: 10.0,
                                                                              child: CircleAvatar(
                                                                                radius: 15,
                                                                                backgroundColor: Colors.grey.shade800,
                                                                                backgroundImage: NetworkImage(
                                                                                  community['mainimage'],
                                                                                ),
                                                                              ),
                                                                            ),
                                                                          ]),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                              .only(
                                                                          left:
                                                                              10.0,
                                                                          right:
                                                                              10.0),
                                                                      child:
                                                                          Row(
                                                                        mainAxisAlignment:
                                                                            MainAxisAlignment.spaceBetween,
                                                                        crossAxisAlignment:
                                                                            CrossAxisAlignment.center,
                                                                        children: [
                                                                          Text(
                                                                              "c/${community['name']}",
                                                                              style: Theme.of(context).textTheme.subtitle2!.copyWith(
                                                                                    fontSize: 12.0,
                                                                                    fontWeight: FontWeight.bold,
                                                                                    color: Colors.white,
                                                                                  )),
                                                                          TextButton(
                                                                            onPressed:
                                                                                () async {
                                                                              if (community['memberuids'].contains(onlineuid)) {
                                                                                communitycollection.doc(community['name']).update({
                                                                                  'memberuids': FieldValue.arrayRemove([
                                                                                    onlineuid
                                                                                  ])
                                                                                });
                                                                                var usercommunitydocs = await usercollection.doc(onlineuid).collection('communities').doc(community['name']).get();
                                                                                if (usercommunitydocs.exists) {
                                                                                  usercollection.doc(onlineuid).collection('communities').doc(community['name']).delete();
                                                                                }
                                                                              } else {
                                                                                communitycollection.doc(community['name']).update({
                                                                                  'memberuids': FieldValue.arrayUnion([
                                                                                    onlineuid
                                                                                  ])
                                                                                });
                                                                                var usercommunitydocs = await usercollection.doc(onlineuid).collection('communities').doc(community['name']).get();
                                                                                if (!usercommunitydocs.exists) {
                                                                                  usercollection.doc(onlineuid).collection('communities').doc(community['name']).set({});
                                                                                }
                                                                              }
                                                                            },
                                                                            child: Text((community['memberuids'].contains(onlineuid)) ? "Leave" : "Join",
                                                                                style: Theme.of(context).textTheme.subtitle2!.copyWith(
                                                                                      fontSize: 12.0,
                                                                                      fontWeight: FontWeight.bold,
                                                                                      color: kPrimaryColor,
                                                                                    )),
                                                                          )
                                                                        ],
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                              .only(
                                                                          left:
                                                                              10.0,
                                                                          right:
                                                                              10.0),
                                                                      child:
                                                                          Text(
                                                                        (community['memberuids'].length ==
                                                                                1)
                                                                            ? "${community['memberuids'].length} member"
                                                                            : "${community['memberuids'].length} members",
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .subtitle2!
                                                                            .copyWith(
                                                                              fontSize: 10,
                                                                              //fontWeight: FontWeight.bold,
                                                                              //fontWeight: FontWeight.w900,
                                                                              color: kBodyTextColorDark,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    Padding(
                                                                      padding: const EdgeInsets
                                                                              .only(
                                                                          left:
                                                                              10.0,
                                                                          right:
                                                                              10.0,
                                                                          bottom:
                                                                              10.0),
                                                                      child:
                                                                          Text(
                                                                        "${community['description']}",
                                                                        maxLines:
                                                                            1,
                                                                        style: Theme.of(context)
                                                                            .textTheme
                                                                            .subtitle2!
                                                                            .copyWith(
                                                                              fontSize: 10,
                                                                              //fontWeight: FontWeight.bold,
                                                                              //fontWeight: FontWeight.w900,
                                                                              color: Colors.white70,
                                                                            ),
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
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
                                                ),
                                        ),
                                      )
                                : (showloading == true)
                                    ? const Center(
                                        child: CupertinoActivityIndicator(
                                        color: kDarkPrimaryColor,
                                      ))
                                    : Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          child: (showloading == true)
                                              ? const Center(
                                                  child:
                                                      CupertinoActivityIndicator(
                                                  color: kDarkPrimaryColor,
                                                ))
                                              : FutureBuilder<QuerySnapshot>(
                                                  future: usersearchresult,
                                                  builder: (BuildContext
                                                          context,
                                                      AsyncSnapshot snapshot) {
                                                    if (!snapshot.hasData) {
                                                      return const Center(
                                                          child:
                                                              CupertinoActivityIndicator(
                                                        color:
                                                            kDarkPrimaryColor,
                                                      ));
                                                    }
                                                    if (snapshot
                                                            .data.docs.length ==
                                                        0) {
                                                      return const Center(
                                                        child: Text(
                                                            'No results.',
                                                            style: TextStyle(
                                                              fontSize: 20,
                                                              color:
                                                                  Colors.white,
                                                            )),
                                                      );
                                                    }
                                                    return ListView.builder(
                                                        keyboardDismissBehavior:
                                                            ScrollViewKeyboardDismissBehavior
                                                                .onDrag,
                                                        scrollDirection:
                                                            Axis.vertical,
                                                        shrinkWrap: true,
                                                        itemCount: snapshot
                                                            .data.docs.length,
                                                        itemBuilder:
                                                            (BuildContext
                                                                    context,
                                                                int index) {
                                                          var user = snapshot
                                                              .data.docs[index];
                                                          if (!blockedusers
                                                              .contains(user[
                                                                  'uid'])) {
                                                            return InkWell(
                                                              onTap: () {
                                                                Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                        builder: (context) =>
                                                                            ProfilePage(
                                                                              uid: user['uid'],
                                                                              whetherShowArrow: true,
                                                                            )));
                                                              },
                                                              child: ListTile(
                                                                leading:
                                                                    CircleAvatar(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .white,
                                                                  backgroundImage:
                                                                      NetworkImage(
                                                                          user[
                                                                              'profilepic']),
                                                                ),
                                                                title: Text(
                                                                  user[
                                                                      'username'],
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        14,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          } else {
                                                            return Container();
                                                          }
                                                        });
                                                  },
                                                ),
                                        ),
                                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
