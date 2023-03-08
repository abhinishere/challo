import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/helpers/link_preview.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/linkpage.dart';
import 'package:challo/variables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class PostLink extends StatefulWidget {
  final UserInfoModel? onlineuser;
  final String? url;
  final bool
      whethercommunitypost; //if community post, publish on community collection and profile
  final String? communityName, communityPic;
  final bool whetherediting;
  final bool? whetherfrompost;
  final String? docName;
  const PostLink({
    required this.onlineuser,
    this.url,
    required this.whethercommunitypost,
    this.communityName,
    this.communityPic,
    required this.whetherediting,
    this.whetherfrompost,
    this.docName,
  });
  @override
  State<PostLink> createState() => _PostLinkState();
}

class _PostLinkState extends State<PostLink> {
  String? docName;
  dynamic time;
  final _linkKey = GlobalKey<FormState>();
  TextEditingController linkcontroller = TextEditingController();
  TextEditingController titlecontroller = TextEditingController();
  String? linktitle, linkimage, linkdescription;
  final String placeholderimage =
      'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/images%2Fimage_not_found.jpg?alt=media&token=71a5af40-b121-46fb-abb1-8a2759b9dfbc';
  //String finallinktitle;
  bool dataisthere = false;
  late dynamic data;
  bool linkdatacollected = false;
  RegExp exp = RegExp(r'[\s,;/.!:?({\[&)\]}]+');
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();
  String? domainname;
  bool showLinkDataLoading = false;
  Map<String, String> placesMap = {};
  List<String> placesList = [];
  String selectedPlace = 'profile';
  bool whethercommunitypost = false;
  String communityName = '';
  String communityPic = '';

  @override
  void initState() {
    super.initState();
    //extractLinkData();
    getalldata();
  }

  getalldata() async {
    placesMap['profile'] = widget.onlineuser!.pic!;
    whethercommunitypost = widget.whethercommunitypost;
    if (whethercommunitypost == true) {
      communityName = widget.communityName!;
      communityPic = widget.communityPic!;
      placesMap["c/$communityName"] = communityPic;
      setState(() {
        selectedPlace = "c/$communityName";
      });
    }

    //get communities that user follow
    await communitycollection
        .where('status', isEqualTo: 'published')
        .get()
        .then((value) => {
              for (var element in value.docs)
                {
                  placesMap['c/${element.id}'] = element['mainimage'],
                }
            });

    placesList = placesMap.keys.toList();

    if (widget.whetherediting == false) {
      setState(() {
        dataisthere = true;
      });
    } else {
      var linkdocs = await contentcollection.doc(widget.docName).get();
      final String linktopic = linkdocs['topic'];
      final String linkurl = linkdocs['link'];
      linkcontroller.text = linkurl;
      titlecontroller.text = linktopic;
      setState(() {
        dataisthere = true;
      });
    }
  }

  extractDataFromLink(String url) async {
    setState(() {
      showLinkDataLoading = true;
    });
    Uri? uri;
    FetchPreview()
        .fetch(url)
        .then((res) {
          setState(() {
            data = res;
          });
        })
        .then((_) => {
              print("Inside linkdatacollected true if statement"),
              linktitle = data['title'] ?? 'No title',
              linkimage = (data['image'] == '')
                  ? placeholderimage
                  : data['image'] ?? placeholderimage,
              linkdescription = data['description'] ?? 'nothing...',
              uri = Uri.parse(_validateUrl(url)),
              domainname = (uri?.host == '')
                  ? 'domainError'
                  : uri?.host ?? 'domainError',
              print('domainname is $domainname'),
              if (titlecontroller.text.isEmpty)
                titlecontroller.text = linktitle ?? 'No title',
            })
        .then((_) => {
              setState(() {
                showLinkDataLoading = false;
              }),
            });
  }

  /* extractLinkData(String fullUrl) async {
    setState(() {
      showLinkDataLoading = true;
    });
    print("Inside extractLinkData function...");
    if (widget.whetherediting == false) {
      FetchPreview().fetch(fullUrl).then((res) {
        setState(() {
          data = res;
        });
      });
      setState(() {
        linkdatacollected = true;
        print("linkdatacollected is true");
      });

      Future.delayed(const Duration(milliseconds: 5000), () {
        if (linkdatacollected == true) {
          print("Inside linkdatacollected true if statement");
          linktitle = data['title'] ?? 'No title';
          setState(() {
            linkcontroller.text = fullUrl;
            titlecontroller.text = linktitle!;
          });
          linkimage = (data['image'] == '')
              ? placeholderimage
              : data['image'] ?? placeholderimage;
          linkdescription = data['description'] ?? 'nothing...';
          final Uri? uri = Uri.parse(_validateUrl(fullUrl));
          domainname =
              (uri?.host == '') ? 'domainError' : uri?.host ?? 'domainError';
          print('domainname is $domainname');
          setState(() {
            dataisthere = true;
          });
        } else {
          print("Link data collection error...");
          //try second time
          extractLinkData2(fullUrl);
        }
        if (dataisthere == false) {
          extractLinkData2(fullUrl);
        }
      });
    } else {
      //when editing the post
      var linkdocforediting = await contentcollection.doc(widget.docName).get();
      String linktitleforediting = linkdocforediting['topic'];
      final String urlforediting = linkdocforediting['link'];
      titlecontroller.text = linktitleforediting;
      linkcontroller.text = urlforediting;
      setState(() {
        dataisthere = true;
      });
    }
    setState(() {
      showLinkDataLoading = false;
    });
  }

  extractLinkData2(String fullUrl) async {
    print("Inside extractLinkData2 function...");
    FetchPreview().fetch(fullUrl).then((res) {
      setState(() {
        data = res;
      });
    });
    setState(() {
      linkdatacollected = true;
      print("linkdatacollected is true");
    });

    Future.delayed(const Duration(milliseconds: 10000), () {
      if (linkdatacollected == true) {
        print("Inside linkdatacollected true if statement");
        linktitle = data['title'] ?? 'No title';
        setState(() {
          linkcontroller.text = fullUrl;
          titlecontroller.text = linktitle!;
        });
        linkimage = data['image'] ?? placeholderimage;
        linkdescription = data['description'] ?? 'nothing...';
        final Uri? uri = Uri.parse(_validateUrl(fullUrl));
        domainname = uri?.host ?? 'domainError';
        print('domainname is $domainname');
        setState(() {
          dataisthere = true;
        });
      } else {
        print("Link data collection error...");
        //error message
      }
    });
  }*/

  _validateUrl(String url) {
    if (url.startsWith('http://') == true ||
        url.startsWith('https://') == true) {
      return url;
    } else {
      return 'http://$url';
    }
  }

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateDocName() {
    String newDocName = (widget.onlineuser!.username! + getRandomString(5));
    return newDocName;
  }

  List<String> stringtoList(String videoinfostring) {
    final List<String> infoinlist0 = videoinfostring.split(exp);
    final List<String> infoinlist =
        infoinlist0.map((email) => email.toLowerCase()).toList();
    infoinlist.removeWhere((value) => value == "");
    return (infoinlist);
  }

  showTextSheet(
    String typingWhat,
    int minLength,
    int maxLength,
    bool whetherMultiLine,
    TextEditingController _textEditingController,
  ) {
    showModalBottomSheet(
        enableDrag: false,
        isDismissible: false,
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return WillPopScope(
            onWillPop: () {
              if (typingWhat == 'Link') {
                if (linkcontroller.text.isNotEmpty) {
                  setState(() {
                    extractDataFromLink(linkcontroller.text);
                  });
                }
              }
              Navigator.pop(context);
              return Future.value(false);
            },
            child: Container(
              color: kBackgroundColorDark,
              height: double.infinity,
              width: double.infinity,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 50.0, left: 10, right: 10, bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (typingWhat == 'Link') {
                                  if (linkcontroller.text.isNotEmpty) {
                                    setState(() {
                                      extractDataFromLink(linkcontroller.text);
                                    });
                                  }
                                }
                                Navigator.pop(context);
                              },
                              child: const Icon(
                                Icons.arrow_back,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Text("Add $typingWhat"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    thickness: 2,
                    color: kBackgroundColorDark2,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: TextFormField(
                        validator: (text) {
                          if (text == null || text.isEmpty) {
                            return "$typingWhat cannot be empty";
                          } else if (text.length < minLength) {
                            return "$typingWhat can't be less than ${minLength.toString()} chars";
                          } else if (text.length > maxLength) {
                            return "$typingWhat can't be more than ${maxLength.toString()} chars";
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: _textEditingController,
                        maxLength: maxLength,
                        keyboardType: (whetherMultiLine == true)
                            ? TextInputType.multiline
                            : TextInputType.text,
                        maxLines: null,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1!
                            .copyWith(color: Colors.white),
                        decoration: InputDecoration.collapsed(
                          hintText: 'Start Typing $typingWhat...',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).whenComplete(() {
      setState(() {});
    });
  }

  publishPost() async {
    docName = generateDocName();
    time = DateTime.now();
    List<String> blockedby = [];

    await contentcollection.doc(docName).set({
      'type': 'linkpost',
      'status': 'published',
      'docName': docName,
      'whethercommunitypost': whethercommunitypost,
      'communityName': (whethercommunitypost == false) ? '' : communityName,
      'communitypic': (whethercommunitypost == false) ? '' : communityPic,
      'topic': titlecontroller.text,
      'topicinlist': stringtoList(titlecontroller.text),
      'domainname': domainname,
      'description': linkdescription,
      'descriptioninlist': stringtoList(linkdescription!),
      'image': linkimage,
      'likes': [],
      'dislikes': [],
      'commentcount': 0,
      'totalviews': [],
      'link': linkcontroller.text,
      'opuid': widget.onlineuser!.uid,
      'oppic': widget.onlineuser!.pic,
      'opusername': widget.onlineuser!.username,
      'time': time,
      'blockedby': blockedby,
      'topfeaturedpriority': 0,
      'trendingpriority': 0,
      'communitypostpriority': 0,
    });

    await usercollection
        .doc(widget.onlineuser!.uid)
        .collection('content')
        .doc(docName)
        .set({
      'type': 'linkpost',
      'docName': docName,
      'whethercommunitypost': whethercommunitypost,
      'communityName': (whethercommunitypost == false) ? '' : communityName,
      'communitypic': (whethercommunitypost == false) ? '' : communityPic,
      'topic': titlecontroller.text,
      'domainname': domainname,
      'description': linkdescription,
      'image': linkimage,
      'link': linkcontroller.text,
      'time': time,
      'blockedby': blockedby,
    });

    if (whethercommunitypost == true) {
      await communitycollection
          .doc(communityName)
          .collection('content')
          .doc(docName)
          .set({
        'type': 'linkpost',
        'docName': docName,
        'whethercommunitypost': whethercommunitypost,
        'communityName': (whethercommunitypost == false) ? '' : communityName,
        'communitypic': (whethercommunitypost == false) ? '' : communityPic,
        'topic': titlecontroller.text,
        'domainname': domainname,
        'description': linkdescription,
        'image': linkimage,
        'link': linkcontroller.text,
        'opuid': widget.onlineuser!.uid,
        'oppic': widget.onlineuser!.pic,
        'opusername': widget.onlineuser!.username,
        'time': time,
        'blockedby': blockedby,
        'trendingpriority': 0,
        'topfeaturedpriority': 0,
        'communitypostpriority': 0,
      });
    }

    await contentcollection.doc(docName).get().then((value) => {
          if (value.exists)
            {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LinkPage(
                    showcomments: false,
                    docName: docName!,
                    whetherjustcreated: true,
                  ),
                  fullscreenDialog: true,
                ),
              )
            }
          else
            {
              //error message
            }
        });
  }

  updatePost() async {
    await contentcollection.doc(widget.docName).update({
      'topic': titlecontroller.text,
      'topicinlist': stringtoList(titlecontroller.text),
    }).then((_) async => {
          await usercollection
              .doc(widget.onlineuser!.uid)
              .collection('content')
              .doc(widget.docName)
              .update({
            'topic': titlecontroller.text,
          })
        });

    await contentcollection.doc(widget.docName).get().then((value) => {
          if (value.exists)
            {
              if (widget.whetherfrompost == false)
                {
                  setState(() {
                    hidenav = false;
                  }),
                  AppBuilder.of(context)!.rebuild(),
                  Navigator.pop(context, true),
                }
              else
                {
                  Navigator.pop(context, true),
                }
            }
          else
            {
              //error message
            }
        });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (widget.whetherediting == false) {
          setState(() {
            hidenav = false;
          });
          AppBuilder.of(context)!.rebuild();
          Navigator.pop(context);
        } else {
          if (widget.whetherfrompost == false) {
            setState(() {
              hidenav = false;
            });
            AppBuilder.of(context)!.rebuild();
            Navigator.pop(context);
          } else {
            Navigator.pop(context);
          }
        }
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            (dataisthere == false)
                ? Container()
                : (widget.whetherediting == false)
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: TextButton(
                          onPressed: () {
                            if (_linkKey.currentState!.validate()) {
                              publishPost();
                            }
                          },
                          child: Text(
                            "Publish",
                            style: Theme.of(context).textTheme.button!.copyWith(
                                  color: kPrimaryColorTint2,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: TextButton(
                          onPressed: () => updatePost(),
                          child: Text(
                            "Update",
                            style: Theme.of(context).textTheme.button!.copyWith(
                                  color: kPrimaryColorTint2,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ),
          ],
          leading: GestureDetector(
            onTap: () {
              if (widget.whetherediting == false) {
                setState(() {
                  hidenav = false;
                });
                AppBuilder.of(context)!.rebuild();
                Navigator.pop(context);
              } else {
                if (widget.whetherfrompost == false) {
                  setState(() {
                    hidenav = false;
                  });
                  AppBuilder.of(context)!.rebuild();
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                }
              }
            },
            child: const Icon(
              Icons.arrow_back,
            ),
          ),
          title: const Text(
            "Link Post",
          ),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: (dataisthere == false)
            ? const Center(
                child: CupertinoActivityIndicator(
                  color: kDarkPrimaryColor,
                ),
              )
            : (showLinkDataLoading == true)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: const [
                        CupertinoActivityIndicator(
                          color: kPrimaryColor,
                        ),
                        SizedBox(height: 10.0),
                        Text(
                          "Getting link data...",
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : Form(
                    key: _linkKey,
                    child: SafeArea(
                      child: Container(
                        child: ListView(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Divider(
                                  thickness: 2,
                                  color: kBackgroundColorDark2,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 10.0, right: 10.0),
                                  child: InputDecorator(
                                    decoration: InputDecoration(
                                      prefixIconConstraints:
                                          const BoxConstraints(),
                                      prefixIcon: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 10.0),
                                        child: CachedNetworkImage(
                                          imageUrl: placesMap[selectedPlace]!,
                                          progressIndicatorBuilder: (context,
                                                  url, downloadProgress) =>
                                              Container(
                                            decoration: new BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: new Border.all(
                                                color: Colors.grey.shade600,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: const CircleAvatar(
                                              child: CupertinoActivityIndicator(
                                                color: kPrimaryColorTint2,
                                              ),
                                              radius: 13.0,
                                              backgroundColor:
                                                  kBackgroundColorDark2,
                                            ),
                                          ),
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Container(
                                            decoration: new BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: new Border.all(
                                                color: Colors.grey.shade600,
                                                width: 1.0,
                                              ),
                                            ),
                                            child: CircleAvatar(
                                              backgroundImage: imageProvider,
                                              radius: 13.0,
                                              backgroundColor:
                                                  kBackgroundColorDark2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      labelText: "Post on...",
                                      labelStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: kSubTextColor,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: Theme(
                                        data: ThemeData(
                                          brightness: Brightness.dark,
                                          splashColor: Colors.transparent,
                                          highlightColor: Colors.transparent,
                                          scrollbarTheme: ScrollbarThemeData(
                                            thumbColor: MaterialStateProperty
                                                .all<Color>(Colors.white70),
                                          ),
                                        ),
                                        child: Container(
                                          height: 35,
                                          child: DropdownButton(
                                              isDense: true,
                                              focusColor: Colors.transparent,
                                              menuMaxHeight:
                                                  MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      2,
                                              icon: (widget.whetherediting ==
                                                      false)
                                                  ? const Icon(
                                                      CupertinoIcons
                                                          .arrowtriangle_down_circle_fill,
                                                      //size: 25,
                                                      color: kPrimaryColorTint2,
                                                    )
                                                  : Container(),
                                              dropdownColor:
                                                  kBackgroundColorDark2,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1!
                                                  .copyWith(
                                                    color: kHeadlineColorDark,
                                                  ),
                                              items: placesList
                                                  .map((e) => DropdownMenuItem(
                                                        child: Text(e),
                                                        value: e,
                                                      ))
                                                  .toList(),
                                              value: selectedPlace,
                                              onChanged:
                                                  (widget.whetherediting ==
                                                          true)
                                                      ? null
                                                      : (val) {
                                                          setState(() {
                                                            selectedPlace =
                                                                val as String;
                                                          });
                                                          if (selectedPlace ==
                                                              'profile') {
                                                            whethercommunitypost =
                                                                false;
                                                            communityName = '';
                                                            communityPic = '';
                                                          } else {
                                                            whethercommunitypost =
                                                                true;
                                                            communityName =
                                                                selectedPlace
                                                                    .replaceFirst(
                                                                        "c/",
                                                                        ""); //remove c/
                                                            communityPic =
                                                                placesMap[
                                                                    selectedPlace]!;
                                                          }
                                                        }),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const Divider(
                                  thickness: 2,
                                  color: kBackgroundColorDark2,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.link),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Flexible(
                                        child: TextFormField(
                                          validator: (text) {
                                            if (text == null || text.isEmpty) {
                                              return "Link cannot be empty";
                                            } else if (text.length < 3) {
                                              return "Link can't be less than 3 chars";
                                            } else if (text.length > 2048) {
                                              return "Link can't be more than 2048 chars";
                                            }
                                            return null;
                                          },
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          controller: linkcontroller,
                                          maxLength: 2048,
                                          readOnly: true,
                                          maxLines: 2,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(
                                                color: kHeadlineColorDark,
                                              ),
                                          decoration:
                                              const InputDecoration.collapsed(
                                            hintText: 'Add a link...',
                                          ),
                                          onTap: () {
                                            if (widget.whetherediting ==
                                                false) {
                                              showTextSheet("Link", 3, 2048,
                                                  false, linkcontroller);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'You cannot make changes to the URL.',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const Divider(
                                  thickness: 2,
                                  color: kBackgroundColorDark2,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.title),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Flexible(
                                        child: TextFormField(
                                          validator: (text) {
                                            if (text == null || text.isEmpty) {
                                              return "Title cannot be empty";
                                            } else if (text.length < 5) {
                                              return "Title can't be less than 5 chars";
                                            } else if (text.length > 150) {
                                              return "Title can't be more than 150 chars";
                                            }
                                            return null;
                                          },
                                          autovalidateMode: AutovalidateMode
                                              .onUserInteraction,
                                          controller: titlecontroller,
                                          maxLength: 150,
                                          readOnly: true,
                                          maxLines: 2,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyText1!
                                              .copyWith(
                                                color: kHeadlineColorDark,
                                              ),
                                          decoration:
                                              const InputDecoration.collapsed(
                                            hintText: 'Add a title...',
                                          ),
                                          onTap: () {
                                            showTextSheet("Title", 5, 150,
                                                false, titlecontroller);
                                          },
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                const Divider(
                                  thickness: 2,
                                  color: kBackgroundColorDark2,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
      ),
    );
  }
}
