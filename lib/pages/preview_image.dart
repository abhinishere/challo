import 'package:challo/helpers/share_service.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PreviewImage extends StatefulWidget {
  final bool whetherfrompost;
  final String docName;
  final int? upvoteCount;
  final int? downvoteCount;
  final int? commentCount;
  final bool? whetherUpvoted;
  final bool? whetherDownvoted;
  final String imageUrl;
  final String? infotext;
  final String onlineuid;

  const PreviewImage({
    required this.whetherfrompost,
    required this.docName,
    this.upvoteCount,
    this.downvoteCount,
    this.commentCount,
    this.whetherUpvoted,
    this.whetherDownvoted,
    required this.imageUrl,
    this.infotext,
    required this.onlineuid,
  });

  @override
  State<PreviewImage> createState() => _PreviewImageState();
}

class _PreviewImageState extends State<PreviewImage> {
  bool dataisthere = false;
  late String onlineuid;
  late String infotext;
  late String imageUrl;
  late bool whetherDownvoted, whetherUpvoted;
  late int commentCount, downvoteCount, upvoteCount;

  @override
  void initState() {
    super.initState();
    settingthingsup();
  }

  settingthingsup() async {
    if (widget.whetherfrompost == true) {
      upvoteCount = widget.upvoteCount!;
      downvoteCount = widget.downvoteCount!;
      commentCount = widget.commentCount!;
      whetherUpvoted = widget.whetherUpvoted!;
      whetherDownvoted = widget.whetherDownvoted!;
      imageUrl = widget.imageUrl;
      infotext = widget.infotext!;
      onlineuid = widget.onlineuid;

      /* likedpost = widget.likedpost!;
      dislikedpost = widget.dislikedpost!;
      updownratio = widget.updownratio!;
      infotext = widget.infotext!;
      //optionaldescription = widget.optionaldescription!;
      totalcomments = widget.totalcomments!;
      imageUrl = widget.imageUrl;
      onlineuid = widget.onlineuid!;
      opuid = widget.opuid!;
      opusername = widget.opusername!;
      oppic = widget.oppic!;*/

      setState(() {
        dataisthere = true;
      });
    } else {
      onlineuid = FirebaseAuth.instance.currentUser!.uid;
      var textdoc = await contentcollection.doc(widget.docName).get();
      List<String> textLikes = List.from(textdoc['likes']); //likes
      List<String> textDislikes = List.from(textdoc['dislikes']); //dislikes
      upvoteCount = textLikes.length;
      downvoteCount = textDislikes.length;
      commentCount = textdoc['commentcount'];
      whetherUpvoted = (textLikes.contains(onlineuid));
      whetherDownvoted = (textDislikes.contains(onlineuid));
      imageUrl = widget.imageUrl;
      infotext = textdoc['topic'];

      // optionaldescription = textdoc['description'];

      setState(() {
        dataisthere = true;
      });
    }
  }

  void _checkUpvotePost() async {
    var postdoc = await contentcollection.doc(widget.docName).get();

    if (postdoc['likes'].contains(onlineuid)) {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayRemove([onlineuid])
      });
      setState(() {
        whetherUpvoted = false;
        whetherDownvoted = false;
        upvoteCount = upvoteCount - 1;
      });
    } else if (postdoc['dislikes'].contains(onlineuid)) {
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayRemove([onlineuid])
      });
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayUnion([onlineuid])
      });
      setState(() {
        whetherUpvoted = true;
        whetherDownvoted = false;
        downvoteCount = downvoteCount - 1;
        upvoteCount = upvoteCount + 1;
      });
    } else {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayUnion([onlineuid])
      });
      setState(() {
        whetherUpvoted = true;
        whetherDownvoted = false;
        upvoteCount = upvoteCount + 1;
      });
    }
  }

  void _checkDownvotePost() async {
    var postdoc = await contentcollection.doc(widget.docName).get();

    if (postdoc['dislikes'].contains(onlineuid)) {
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayRemove([onlineuid])
      });
      setState(() {
        whetherUpvoted = false;
        whetherDownvoted = false;
        downvoteCount = downvoteCount - 1;
      });
    } else if (postdoc['likes'].contains(onlineuid)) {
      contentcollection.doc(widget.docName).update({
        'likes': FieldValue.arrayRemove([onlineuid])
      });
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayUnion([onlineuid])
      });
      setState(() {
        whetherUpvoted = false;
        whetherDownvoted = true;
        upvoteCount = upvoteCount - 1;
        downvoteCount = downvoteCount + 1;
      });
    } else {
      contentcollection.doc(widget.docName).update({
        'dislikes': FieldValue.arrayUnion([onlineuid])
      });
      setState(() {
        whetherUpvoted = false;
        whetherDownvoted = true;
        downvoteCount = downvoteCount + 1;
      });
    }
  }

  Widget actionCard() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0),
            child: Text(
              infotext,
              style: Theme.of(context)
                  .textTheme
                  .bodyText1!
                  .copyWith(fontSize: 15.0, color: Colors.white),
            ),
          ),
          Container(
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Row(
                  //mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _checkUpvotePost(),
                      child: /*Image.asset(
                      "assets/icons/arrow-up_rounded_outlined.png",
                      color: kSubTextColor,
                      height: 25,
                      width: 25,
                    )*/

                          Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Stack(children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (whetherUpvoted)
                                    ? Colors.white
                                    : Colors.transparent,
                              ),
                              margin: const EdgeInsets.all(7.0),
                            ),
                          ),
                          Icon(
                            CupertinoIcons.arrow_up_circle_fill,
                            size: 30,
                            color: whetherUpvoted
                                ? kPrimaryColor
                                : kIconSecondaryColorDark,
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Container(
                      alignment: Alignment.center,
                      height: 15,
                      width: 23,
                      //color: Colors.blueAccent,
                      child: Text(
                        "$upvoteCount",
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: kIconSecondaryColorDark,
                            ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _checkDownvotePost(),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Stack(children: [
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: (whetherDownvoted)
                                    ? Colors.white
                                    : Colors.transparent,
                              ),
                              margin: const EdgeInsets.all(7.0),
                            ),
                          ),
                          Icon(
                            CupertinoIcons.arrow_down_circle_fill,
                            size: 30,
                            color: whetherDownvoted
                                ? kPrimaryColor
                                : kIconSecondaryColorDark,
                          ),
                        ]),
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Container(
                      alignment: Alignment.center,
                      height: 15,
                      width: 23,
                      //color: Colors.blueAccent,
                      child: Text(
                        "$downvoteCount",
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                              fontSize: 12.0,
                              color: kIconSecondaryColorDark,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.message,
                          size: 20,
                          color: kIconSecondaryColorDark,
                        ),
                        const SizedBox(width: 5.0),
                        Container(
                          height: 15,
                          width: 23,
                          child: Text(
                            "$commentCount",
                            style:
                                Theme.of(context).textTheme.subtitle2!.copyWith(
                                      fontSize: 12.0,
                                      color: kIconSecondaryColorDark,
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => ShareService.shareContent(
                      widget.docName, 'imagepost', infotext, '', imageUrl),
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.share_solid,
                          size: 20,
                          color: kIconSecondaryColorDark,
                        ),
                        /*Image.asset(
                      "assets/icons/share_thick_outlined.png",
                      height: 20,
                      width: 20,
                      color: kSubTextColor,
                    ),*/
                        const SizedBox(width: 5.0),
                        Text(
                          'Share',
                          style: Theme.of(context).textTheme.button!.copyWith(
                                fontSize: 12.0,
                                color: kIconSecondaryColorDark,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget arrowbackWidget() {
    return ButtonTheme(
      padding: const EdgeInsets.symmetric(
          vertical: 4.0, horizontal: 8.0), //adds padding inside the button
      materialTapTargetSize: MaterialTapTargetSize
          .shrinkWrap, //limits the touch area to the button area
      minWidth: 0, //wraps child's width
      height: 0, //wraps child's height

      child: TextButton(
        onPressed: () {
          if (widget.whetherfrompost == false) {
            setState(() {
              hidenav = false;
            });
            AppBuilder.of(context)!.rebuild();
            Navigator.pop(context);
          } else {
            Navigator.pop(context);
          }
        },
        child: const Icon(
          Icons.arrow_back,
          size: 25,
          color: Colors.white,
        ),
      ),
    );
  }

  final _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      // For a 3x zoom
      _transformationController.value = Matrix4.identity()
        ..translate(-position.dx * 2, -position.dy * 2)
        ..scale(3.0);
      // Fox a 2x zoom
      // ..translate(-position.dx, -position.dy)
      // ..scale(2.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (widget.whetherfrompost == false) {
          setState(() {
            hidenav = false;
          });
          AppBuilder.of(context)!.rebuild();
          Navigator.pop(context);
        } else {
          Navigator.pop(context);
        }
        return Future.value(false);
      },
      child: (dataisthere == false)
          ? Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: GestureDetector(
                  onTap: () {
                    if (widget.whetherfrompost == false) {
                      setState(() {
                        hidenav = false;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Icon(
                    Icons.arrow_back,
                    color: kHeadlineColorDark,
                  ),
                ),
              ),
              body: const SafeArea(
                child: Center(
                  child: CupertinoActivityIndicator(
                    color: kDarkPrimaryColor,
                  ),
                ),
              ),
            )
          : Scaffold(
              body: SafeArea(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        onDoubleTapDown: _handleDoubleTapDown,
                        onDoubleTap: _handleDoubleTap,
                        child: InteractiveViewer(
                          transformationController: _transformationController,
                          panEnabled: true,
                          boundaryMargin: const EdgeInsets.all(0),
                          minScale: 0.5,
                          maxScale: 2,
                          child: Image.network(imageUrl),
                        ),
                      ),
                    ),

                    /* Positioned.fill(
                      child: InteractiveViewer(
                          panEnabled: true,
                          boundaryMargin: const EdgeInsets.all(100),
                          minScale: 0.5,
                          maxScale: 2,
                          child: Image.network(imgUrl)),
                    ),*/
                    Positioned.fill(
                      bottom: 20.0,
                      child: Align(
                          alignment: Alignment.bottomCenter,
                          child: actionCard()),
                    ),
                    Positioned(
                      left: 0.0,
                      top: 0.0,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: arrowbackWidget(),
                      ),
                    ),
                  ],
                ),
              ),
            )),
    );
  }
}
