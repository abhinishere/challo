import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/text_content_page.dart';
import 'package:challo/variables.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class PostText extends StatefulWidget {
  final UserInfoModel? onlineuser;
  final bool whethercommunitypost;
  final String? communityName;
  final String? communitypic;
  final bool whetherediting;
  final bool? whetherfrompost;
  final String? docName;
  const PostText({
    required this.onlineuser,
    required this.whethercommunitypost,
    this.communityName,
    this.communitypic,
    required this.whetherediting,
    this.whetherfrompost,
    this.docName,
  });

  //const PostText({Key? key}) : super(key: key);

  @override
  State<PostText> createState() => _PostTextState();
}

class _PostTextState extends State<PostText> {
  @override
  void initState() {
    super.initState();
    initialsetup();
  }

  initialsetup() async {
    placesMap['profile'] = widget.onlineuser!.pic!;
    whethercommunitypost = widget.whethercommunitypost;
    if (whethercommunitypost == true) {
      communityName = widget.communityName!;
      communityPic = widget.communitypic!;
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
      docName = generatedocName();
      titleFocusNode.requestFocus();
      setState(() {
        allset = true;
      });
    } else {
      //initial data for editing post
      docName = widget.docName!;
      var textdocforedits = await contentcollection.doc(docName).get();
      //final String contentUrl = textdocforedits['link'];
      final String textTopic = textdocforedits['topic'];
      final String? textImage = textdocforedits['image'];
      briefdescription = textdocforedits['description'];

      //get data from txt file
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('text_posts')
          .child(docName)
          .child('$docName.txt');
      await ref.getData().then((value) {
        setState(() {
          contentText = utf8.decode(value!.toList());
        });
      });
      if (textImage == null || textImage == '') {
        whetherfeaturedimageselected = false;
      } else {
        featuredimage = textImage;
        whetherfeaturedimageselected = true;
      }
      textposttitlecontroller.text = textTopic;
      textpostdescriptioncontroller.text = contentText!;
      customfeatureddescriptioncontroller?.text =
          (briefdescription!.length > 165)
              ? briefdescription!.substring(0, 165)
              : briefdescription!;

      setState(() {
        allset = true;
      });
    }
  }

  final FocusNode titleFocusNode = FocusNode();
  final FocusNode contentFocusNode = FocusNode();
  final _textPostKey = GlobalKey<FormState>();
  String? briefdescription = '';
  String? contentText;
  //String tempimage = '';
  TextEditingController textposttitlecontroller = TextEditingController();
  TextEditingController textpostdescriptioncontroller = TextEditingController();
  TextEditingController? customfeatureddescriptioncontroller =
      TextEditingController();
  late String docName;
  bool allset = false;
  RegExp exp = RegExp(r'[\s,;/.!:?({\[&)\]}]+');
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  //featured image data
  String featuredimage = ''; //for editing stage
  String tempImageUrl = '';
  bool whetherfeaturedimageselected = false;
  bool whetherfeaturedimagechanged = false;
  dynamic imageFilePath;

  bool whethercommunitypost = false;
  String communityName = '';
  String communityPic = '';

  Map<String, String> placesMap = {};
  List<String> placesList = [];
  String selectedPlace = 'profile';

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generatedocName() {
    String newdocName = (widget.onlineuser!.username! + getRandomString(5));
    return newdocName;
  }

  bool showpublishloading = false;

  List<String> stringtoList(String videoinfostring) {
    final List<String> infoinlist0 = videoinfostring.split(exp);
    final List<String> infoinlist =
        infoinlist0.map((email) => email.toLowerCase()).toList();
    infoinlist.removeWhere((value) => value == "");
    return (infoinlist);
  }

  uploadToStorage() async {
    briefdescription = customfeatureddescriptioncontroller?.text;
    final time = DateTime.now();
    List<String> blockedby = [];
    //String contentBodyUrl;
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('text_posts')
        .child(docName)
        .child('/$docName.txt');

    if (whetherfeaturedimageselected == true) {
      final _storage = FirebaseStorage.instance;
      await _storage
          .ref()
          .child('text_posts')
          .child(docName)
          .child(generatedocName())
          .putFile(
            imageFilePath,
            SettableMetadata(
              customMetadata: null,
            ),
          )
          .then(
            (p0) => {
              p0.ref
                  .getDownloadURL()
                  .then(
                    (value) => {
                      tempImageUrl = value,
                    },
                  )
                  .then((_) async => {
                        await ref
                            .putString(
                          textpostdescriptioncontroller.text,
                          metadata: SettableMetadata(
                            contentType: 'text/markdown',
                            customMetadata: null,
                          ),
                        )
                            .whenComplete(() async {
                          await ref.getDownloadURL().then((value) async => {
                                await contentcollection.doc(docName).set({
                                  'type': 'textpost',
                                  'status': 'published',
                                  'docName': docName,
                                  'whethercommunitypost': whethercommunitypost,
                                  'communityName':
                                      (whethercommunitypost == false)
                                          ? ''
                                          : communityName,
                                  'communitypic':
                                      (whethercommunitypost == false)
                                          ? ''
                                          : communityPic,
                                  'topic': textposttitlecontroller.text,
                                  'topicinlist': stringtoList(
                                      textposttitlecontroller.text),
                                  'description': (briefdescription == '' ||
                                          briefdescription == null)
                                      ? textpostdescriptioncontroller.text
                                      : briefdescription!,
                                  'descriptioninlist': (briefdescription ==
                                              '' ||
                                          briefdescription == null)
                                      ? stringtoList(
                                          textpostdescriptioncontroller.text)
                                      : stringtoList(briefdescription!),
                                  'image': tempImageUrl,
                                  'likes': [],
                                  'dislikes': [],
                                  'commentcount': 0,
                                  'totalviews': [],
                                  'link': value,
                                  'opuid': widget.onlineuser!.uid,
                                  'opusername': widget.onlineuser!.username,
                                  'oppic': widget.onlineuser!.pic,
                                  'time': time,
                                  'blockedby': blockedby,
                                  'topfeaturedpriority': 0,
                                  'trendingpriority': 0,
                                  'communitypostpriority': 0,
                                }).then((_) async => {
                                      await usercollection
                                          .doc(widget.onlineuser!.uid)
                                          .collection('content')
                                          .doc(docName)
                                          .set({
                                        'type': 'textpost',
                                        'docName': docName,
                                        'whethercommunitypost':
                                            whethercommunitypost,
                                        'communityName':
                                            (whethercommunitypost == false)
                                                ? ''
                                                : communityName,
                                        'communitypic':
                                            (whethercommunitypost == false)
                                                ? ''
                                                : communityPic,
                                        'topic': textposttitlecontroller.text,
                                        'description': (briefdescription ==
                                                    '' ||
                                                briefdescription == null)
                                            ? textpostdescriptioncontroller.text
                                            : briefdescription!,
                                        'image': tempImageUrl,
                                        'link': value,
                                        'time': time,
                                        'blockedby': blockedby,
                                      }).then((value) async => {
                                                await contentcollection
                                                    .doc(docName)
                                                    .get()
                                                    .then((value) => {
                                                          if (value.exists)
                                                            {
                                                              Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          TextContentPage(
                                                                    docName:
                                                                        docName,
                                                                    whetherjustcreated:
                                                                        true,
                                                                    showcomments:
                                                                        false,
                                                                  ),
                                                                  fullscreenDialog:
                                                                      true,
                                                                ),
                                                              )
                                                            }
                                                          else
                                                            {
                                                              //error message
                                                            }
                                                        }),
                                              }),
                                    }),
                              });
                        }),
                      }),
            },
          );
    } else {
      await ref
          .putString(
        textpostdescriptioncontroller.text,
        metadata: SettableMetadata(
          contentType: 'text/markdown',
          customMetadata: null,
        ),
      )
          .whenComplete(() async {
        await ref.getDownloadURL().then((value) async => {
              await contentcollection.doc(docName).set({
                'type': 'textpost',
                'status': 'published',
                'docName': docName,
                'whethercommunitypost': whethercommunitypost,
                'communityName':
                    (whethercommunitypost == false) ? '' : communityName,
                'communitypic':
                    (whethercommunitypost == false) ? '' : communityPic,
                'topic': textposttitlecontroller.text,
                'topicinlist': stringtoList(textposttitlecontroller.text),
                'description':
                    (briefdescription == '' || briefdescription == null)
                        ? textpostdescriptioncontroller.text
                        : briefdescription!,
                'descriptioninlist':
                    (briefdescription == '' || briefdescription == null)
                        ? stringtoList(textpostdescriptioncontroller.text)
                        : stringtoList(briefdescription!),
                'image': tempImageUrl,
                'likes': [],
                'dislikes': [],
                'commentcount': 0,
                'totalviews': [],
                'link': value,
                'opuid': widget.onlineuser!.uid,
                'opusername': widget.onlineuser!.username,
                'oppic': widget.onlineuser!.pic,
                'time': time,
                'blockedby': blockedby,
                'topfeaturedpriority': 0,
                'trendingpriority': 0,
                'communitypostpriority': 0,
              }).then((_) async => {
                    await usercollection
                        .doc(widget.onlineuser!.uid)
                        .collection('content')
                        .doc(docName)
                        .set({
                      'type': 'textpost',
                      'docName': docName,
                      'whethercommunitypost': whethercommunitypost,
                      'communityName':
                          (whethercommunitypost == false) ? '' : communityName,
                      'communitypic':
                          (whethercommunitypost == false) ? '' : communityPic,
                      'topic': textposttitlecontroller.text,
                      'description':
                          (briefdescription == '' || briefdescription == null)
                              ? textpostdescriptioncontroller.text
                              : briefdescription!,
                      'image': tempImageUrl,
                      'link': value,
                      'time': time,
                      'blockedby': blockedby,
                    }).then((value) async => {
                              await contentcollection
                                  .doc(docName)
                                  .get()
                                  .then((value) => {
                                        if (value.exists)
                                          {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TextContentPage(
                                                  docName: docName,
                                                  whetherjustcreated: true,
                                                  showcomments: false,
                                                ),
                                                fullscreenDialog: true,
                                              ),
                                            )
                                          }
                                        else
                                          {
                                            //error message
                                          }
                                      }),
                            }),
                  }),
            });
      });
    }
  }

  editToStorage() async {
    briefdescription = customfeatureddescriptioncontroller?.text;
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('text_posts')
        .child(docName)
        .child('/$docName.txt');

    if (whetherfeaturedimagechanged == true &&
        whetherfeaturedimageselected == true) {
      final _storage = FirebaseStorage.instance;
      await _storage
          .ref()
          .child('text_posts')
          .child(docName)
          .child(generatedocName())
          .putFile(
            imageFilePath,
            SettableMetadata(
              customMetadata: null,
            ),
          )
          .then(
            (p0) => {
              p0.ref
                  .getDownloadURL()
                  .then(
                    (value) => {
                      tempImageUrl = value,
                    },
                  )
                  .then((_) async => {
                        await ref
                            .putString(
                          textpostdescriptioncontroller.text,
                          metadata: SettableMetadata(
                            contentType: 'text/markdown',
                            customMetadata: null,
                          ),
                        )
                            .whenComplete(() async {
                          await ref.getDownloadURL().then((value) async => {
                                await contentcollection.doc(docName).update({
                                  'topic': textposttitlecontroller.text,
                                  'topicinlist': stringtoList(
                                      textposttitlecontroller.text),
                                  'description': (briefdescription == '' ||
                                          briefdescription == null)
                                      ? textpostdescriptioncontroller.text
                                      : briefdescription!,
                                  'descriptioninlist': (briefdescription ==
                                              '' ||
                                          briefdescription == null)
                                      ? stringtoList(
                                          textpostdescriptioncontroller.text)
                                      : stringtoList(briefdescription!),
                                  'image': tempImageUrl,
                                }).then((_) async => {
                                      await usercollection
                                          .doc(widget.onlineuser!.uid)
                                          .collection('content')
                                          .doc(docName)
                                          .update({
                                        'topic': textposttitlecontroller.text,
                                        'description': (briefdescription ==
                                                    '' ||
                                                briefdescription == null)
                                            ? textpostdescriptioncontroller.text
                                            : briefdescription!,
                                        'image': tempImageUrl,
                                      }).then((_) async => {
                                                await contentcollection
                                                    .doc(docName)
                                                    .get()
                                                    .then((value) => {
                                                          if (value.exists)
                                                            {
                                                              if (widget
                                                                      .whetherfrompost ==
                                                                  false)
                                                                {
                                                                  setState(() {
                                                                    hidenav =
                                                                        false;
                                                                  }),
                                                                  AppBuilder.of(
                                                                          context)!
                                                                      .rebuild(),
                                                                  Navigator.pop(
                                                                      context,
                                                                      true)
                                                                }
                                                              else
                                                                {
                                                                  Navigator.pop(
                                                                      context,
                                                                      true)
                                                                }
                                                            }
                                                          else
                                                            {
                                                              //error message
                                                            }
                                                        }),
                                              }),
                                    }),
                              });
                        }),
                      }),
            },
          );
    } else {
      await ref
          .putString(
        textpostdescriptioncontroller.text,
        metadata: SettableMetadata(
          contentType: 'text/markdown',
          customMetadata: null,
        ),
      )
          .whenComplete(() async {
        await ref.getDownloadURL().then((value) async => {
              await contentcollection.doc(docName).update({
                'topic': textposttitlecontroller.text,
                'topicinlist': stringtoList(textposttitlecontroller.text),
                'description':
                    (briefdescription == '' || briefdescription == null)
                        ? textpostdescriptioncontroller.text
                        : briefdescription!,
                'descriptioninlist':
                    (briefdescription == '' || briefdescription == null)
                        ? stringtoList(textpostdescriptioncontroller.text)
                        : stringtoList(briefdescription!),
                'image': tempImageUrl,
              }).then((_) async => {
                    await usercollection
                        .doc(widget.onlineuser!.uid)
                        .collection('content')
                        .doc(docName)
                        .update({
                      'topic': textposttitlecontroller.text,
                      'description':
                          (briefdescription == '' || briefdescription == null)
                              ? textpostdescriptioncontroller.text
                              : briefdescription!,
                      'image': tempImageUrl,
                    }).then((_) async => {
                              await contentcollection
                                  .doc(docName)
                                  .get()
                                  .then((value) => {
                                        if (value.exists)
                                          {
                                            if (widget.whetherfrompost == false)
                                              {
                                                setState(() {
                                                  hidenav = false;
                                                }),
                                                AppBuilder.of(context)!
                                                    .rebuild(),
                                                Navigator.pop(context, true)
                                              }
                                            else
                                              {Navigator.pop(context, true)}
                                          }
                                        else
                                          {
                                            //error message
                                          }
                                      }),
                            }),
                  }),
            });
      });
    }
  }

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showPermissionDenied() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text("Permission Error"),
        content: const Text(
            "Turn on Photos access for Challo in Settings to add a new picture."),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Close"),
            textStyle: Theme.of(context).textTheme.button!.copyWith(
                  color: kPrimaryColorTint2,
                  fontSize: 15.0,
                ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  addFeaturedData() {
    showModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalsetState) {
            return Container(
              color: kBackgroundColorDark,
              height: double.infinity,
              width: double.infinity,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  //crossAxisAlignment: WrapCrossAlignment.start,
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
                                onTap: () => Navigator.pop(context),
                                child: const Icon(
                                  Icons.arrow_back,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              const Text("Add Featured Data (optional)"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      thickness: 2,
                      color: kBackgroundColorDark2,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Add/Remove featured image",
                          style:
                              Theme.of(context).textTheme.headline2!.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: kHeadlineColorDark,
                                  ),
                        ),
                      ),
                    ),
                    (whetherfeaturedimageselected == true)
                        ? Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Stack(children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  border:
                                      Border.all(color: Colors.grey.shade500),
                                ),
                                child: Center(
                                  child: (featuredimage == '')
                                      ? Image.file(imageFilePath)
                                      : Image.network(featuredimage),
                                ),
                                height: 200,
                                width: 400,
                              ),
                              Positioned(
                                  right: 0.0,
                                  top: 0.0,
                                  child: InkWell(
                                      onTap: () {
                                        //when user clicks remove button
                                        modalsetState(() {
                                          whetherfeaturedimageselected = false;
                                          whetherfeaturedimagechanged = true;
                                          tempImageUrl = '';
                                          featuredimage = '';
                                          //tempimage = '';
                                          //whetherimagechanged = true;
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.redAccent,
                                        size: 30.0,
                                      )))
                            ]),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: InkWell(
                              onTap: () async {
                                //final _storage = FirebaseStorage.instance;
                                final ImagePicker _picker = ImagePicker();
                                XFile? image;

                                await Permission.photos.request();

                                var galleryPermissionStatus =
                                    await Permission.photos.status;

                                if (galleryPermissionStatus.isGranted) {
                                  image = await _picker.pickImage(
                                      source: ImageSource.gallery,
                                      imageQuality: 50);
                                  imageFilePath = File(image!.path);
                                  modalsetState(() {
                                    whetherfeaturedimageselected = true;
                                    whetherfeaturedimagechanged = true;
                                  });

                                  /*var snapshot = await _storage
                                      .ref()
                                      .child('text_posts')
                                      .child(docName)
                                      .child(generatedocName())
                                      .putFile(file);

                                  snapshot.ref.getDownloadURL().then((value) {
                                    tempImageUrl = value;
                                    
                                  });*/
                                } else {
                                  //permission issues
                                  _showPermissionDenied();
                                }
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  border:
                                      Border.all(color: Colors.grey.shade500),
                                ),
                                child: Center(
                                  child: Text(
                                    "Tap to select from gallery",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle1!
                                        .copyWith(color: kSubTextColor),
                                  ),
                                ),
                                height: 200,
                                width: 400,
                              ),
                            ),
                          ),
                    const Text(
                      "•••",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(
                      thickness: 2,
                      color: kBackgroundColorDark2,
                    ),
                    const SizedBox(
                      height: 10.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Add a short description",
                          style:
                              Theme.of(context).textTheme.headline2!.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: kHeadlineColorDark,
                                  ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        decoration: BoxDecoration(
                            //color: Colors.grey.shade500,
                            border: Border.all(
                                width: 1, color: Colors.grey.shade500),
                            borderRadius: BorderRadius.circular(5.0)),
                        child: TextFormField(
                          controller: customfeatureddescriptioncontroller,
                          maxLines: 5,
                          maxLength: 150,
                          style:
                              Theme.of(context).textTheme.bodyText1!.copyWith(
                                    color: kHeadlineColorDark,
                                  ),
                          decoration: InputDecoration.collapsed(
                            hintStyle:
                                Theme.of(context).textTheme.subtitle1!.copyWith(
                                      color: Colors.grey.shade500,
                                      fontSize: 15.0,
                                    ),
                            hintText:
                                ' Custom description for featured cards...',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }

  /* addFeaturedImage() {
    showModalBottomSheet(
        isDismissible: false,
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalsetState) {
            return Container(
                color: kBackgroundColorDark,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Wrap(
                    //crossAxisAlignment: WrapCrossAlignment.start,
                    children: [
                      Text(
                        "Add/Remove featured image",
                        style: Theme.of(context).textTheme.headline2!.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white),
                      ),
                      (whetherfeaturedimageselected == true)
                          ? Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Stack(children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade500),
                                  ),
                                  child: Center(
                                    child: Image.network(tempImageUrl),
                                  ),
                                  height: 200,
                                  width: 400,
                                ),
                                Positioned(
                                    right: 0.0,
                                    top: 0.0,
                                    child: InkWell(
                                        onTap: () {
                                          modalsetState(() {
                                            whetherfeaturedimageselected =
                                                false;
                                            tempimage = '';
                                            whetherimagechanged = true;
                                          });
                                        },
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.redAccent,
                                          size: 30.0,
                                        )))
                              ]),
                            )
                          : (whetherfeaturedimagesubmitted == true &&
                                  whetherjustpreview == false)
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Stack(children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade500),
                                      ),
                                      child: Center(
                                        child: Image.network(tempImageUrl),
                                      ),
                                      height: 200,
                                      width: 400,
                                    ),
                                    Positioned(
                                        right: 0.0,
                                        top: 0.0,
                                        child: InkWell(
                                            onTap: () {
                                              modalsetState(() {
                                                whetherfeaturedimageselected =
                                                    false;
                                                whetherjustpreview = true;
                                                tempimage = '';
                                                whetherimagechanged = true;
                                              });
                                            },
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.redAccent,
                                              size: 30.0,
                                            )))
                                  ]),
                                )
                              : Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: InkWell(
                                    onTap: () async {
                                      final _storage = FirebaseStorage.instance;
                                      final ImagePicker _picker = ImagePicker();
                                      XFile? image;

                                      await Permission.photos.request();

                                      var galleryPermissionStatus =
                                          await Permission.photos.status;

                                      if (galleryPermissionStatus.isGranted) {
                                        image = await _picker.pickImage(
                                            source: ImageSource.gallery);
                                        var file = File(image!.path);

                                        var snapshot = await _storage
                                            .ref()
                                            .child('text_posts')
                                            .child(docName)
                                            .child(generatedocName())
                                            .putFile(file);

                                        snapshot.ref
                                            .getDownloadURL()
                                            .then((value) {
                                          tempimage = value;
                                          modalsetState(() {
                                            whetherfeaturedimageselected = true;
                                            whetherimagechanged = true;
                                          });
                                        });
                                      } else {
                                        //permission issues

                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade500),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Tap to select from gallery",
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: Colors.grey.shade500),
                                        ),
                                      ),
                                      height: 200,
                                      width: 400,
                                    ),
                                  ),
                                ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                        child: Text(
                          "Add a short description",
                          style: Theme.of(context)
                              .textTheme
                              .headline2!
                              .copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                            //color: Colors.grey.shade500,
                            border: Border.all(
                                width: 2, color: Colors.grey.shade500),
                            borderRadius: BorderRadius.circular(8.0)),
                        child: TextFormField(
                          controller: customfeatureddescriptioncontroller,
                          maxLines: 3,
                          maxLength: 165,
                          style: Theme.of(context)
                              .textTheme
                              .bodyText1!
                              .copyWith(color: Colors.white),
                          decoration: InputDecoration.collapsed(
                            hintStyle:
                                Theme.of(context).textTheme.subtitle1!.copyWith(
                                      color: Colors.grey.shade500,
                                      fontSize: 15.0,
                                    ),
                            hintText:
                                ' Optional custom description for featured cards...',
                          ),
                        ),
                      ),
                      Text(
                        "Note: Click Update after making changes.",
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                              fontSize: 12.0,
                              color: Colors.white70,
                            ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(
                              "Cancel",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryColor,
                                  ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              //update changes in featured image
                              if (whetherimagechanged == true) {
                                if (tempimage == '') {
                                  tempImageUrl = '';
                                  setState(() {
                                    whetherfeaturedimagesubmitted = false;
                                  });
                                } else {
                                  tempImageUrl = tempimage;
                                  setState(() {
                                    whetherfeaturedimagesubmitted = true;
                                  });
                                }
                              }
                              setState(() {
                                briefdescription =
                                    customfeatureddescriptioncontroller?.text;
                              });
                              print("Featured Image is $tempImageUrl");
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              "Update",
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryColorTint2,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ));
          });
        });
  }*/

  showTextSheetWithLimit(
    String typingWhat,
    int minLength,
    int maxLength,
    bool whetherMultiLine,
    TextEditingController _textEditingController,
  ) {
    showModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Container(
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
                            onTap: () => Navigator.pop(context),
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
          );
        }).whenComplete(() {
      setState(() {});
    });
  }

  showMarkdownGuide() {
    showModalBottomSheet(
        context: context,
        builder: (builder) => Container(
              height: (MediaQuery.of(context).size.height) / 1.7,
              width: (MediaQuery.of(context).size.width),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        "Markdown syntax",
                        style: styleTitleSmall(),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "H1 heading syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "# H1 title",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''# H1 title''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "H2 heading syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "## H2 title",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''## H2 title''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "H3 heading syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "# H3 title",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''### H3 title''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Italic emphasis syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "*italic text*",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''*italic text*''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Bold emphasis syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "**bold text**",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''**bold text**''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Blockquote syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "> That's pretty awesome!",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''> That's pretty awesome!''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Link syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "[Challo website](https://challo.tv)",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data:
                                      '''[Challo website](https://challo.tv)''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Image syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "![Cool dog](https://challo.tv/cool_dog.jpg)",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data:
                                      '''![Cool dog](https://challo.tv/wp-content/uploads/2022/04/cool_dog.jpg)''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Table syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '''Label1 | Label2 | Label3
R1C1 | R1C2 | R1C3
*Text1* | **Text2** | `Text3`
''',
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''
                                Label1 | Label2 | Label3
                                --- | --- | ---
                                R1C1 | R1C2 | R1C3
                                *Text1* | **Text2** | `Text3`
                                ''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Close",
                          style:
                              Theme.of(context).textTheme.subtitle1!.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryColorTint2,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }

  showTextSheetWithoutLimit(
      String typingWhat,
      //int minLength,
      //int maxLength,
      bool whetherMultiLine,
      TextEditingController _textEditingController,
      bool whetherShowFormatting) {
    showModalBottomSheet(
        isDismissible: false,
        enableDrag: false,
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Container(
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
                            onTap: () => Navigator.pop(context),
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
                      (whetherShowFormatting == true)
                          ? TextButton(
                              onPressed: () {
                                showMarkdownGuide();
                              },
                              child: const Text(
                                "Formatting",
                                style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Container(),
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
                      /*validator: (text) {
                        if (text == null || text.isEmpty) {
                          return "$typingWhat cannot be empty";
                        } else if (text.length < minLength) {
                          return "$typingWhat can't be less than ${minLength.toString()} chars";
                        } else if (text.length > maxLength) {
                          return "$typingWhat can't be more than ${maxLength.toString()} chars";
                        }
                        return null;
                      },*/
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: _textEditingController,
                      //maxLength: maxLength,
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
          );
        }).whenComplete(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return (allset == false)
        ? WillPopScope(
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
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
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
                    color: Colors.white,
                  ),
                ),
              ),
              //backgroundColor: Colors.black,
              body: const Center(
                  child: CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              )),
            ),
          )
        : (showpublishloading == false)
            ? WillPopScope(
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
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      (widget.whetherediting == false)
                          ? "Text post"
                          : "Edit post",
                    ),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: TextButton(
                          onPressed: () {
                            if (_textPostKey.currentState!.validate()) {
                              setState(() {
                                showpublishloading = true;
                              });
                              if (widget.whetherediting == false) {
                                uploadToStorage();
                              } else {
                                editToStorage();
                              }
                            } else {
                              print('error');
                            }
                          },
                          child: const Text(
                            "Publish",
                            style: TextStyle(
                                color: kPrimaryColorTint2,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                    centerTitle: true,
                    elevation: 0.0,
                  ),
                  body: Form(
                      key: _textPostKey,
                      child: SafeArea(
                        child: Container(
                          child: Column(
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
                                        progressIndicatorBuilder:
                                            (context, url, downloadProgress) =>
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
                                          thumbColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.white70),
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
                                            onChanged: (widget.whetherediting ==
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
                                                      communityPic = placesMap[
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
                                          } else if (text.length > 100) {
                                            return "Title can't be more than 100 chars";
                                          }
                                          return null;
                                        },
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        controller: textposttitlecontroller,
                                        maxLength: 100,
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
                                          /* hintStyle: Theme.of(context)
                                                .textTheme
                                                .labelMedium!
                                                .copyWith(
                                                  fontSize: 17.0,
                                                  letterSpacing: -0.41,
                                                  color: kSubTextColor,
                                                ),*/
                                        ),
                                        onTap: () {
                                          showTextSheetWithLimit(
                                              "Title",
                                              5,
                                              100,
                                              false,
                                              textposttitlecontroller);
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
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: InkWell(
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(5.0),
                                    ),
                                    onTap: () => addFeaturedData(),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.all(
                                          Radius.circular(5.0),
                                        ),
                                        border: Border.all(
                                          width: 2.0,
                                          color: kPrimaryColorTint2,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10.0),
                                        child: Text(
                                          "Add Featured Data (optional)",
                                          style: Theme.of(context)
                                              .textTheme
                                              .button!
                                              .copyWith(
                                                color: kPrimaryColorTint2,
                                                fontWeight: FontWeight.w500,
                                                fontSize: 15.0,
                                                letterSpacing: -0.24,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                thickness: 2,
                                color: kBackgroundColorDark2,
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: InkWell(
                                    onTap: () {
                                      showTextSheetWithoutLimit("Post", true,
                                          textpostdescriptioncontroller, true);
                                    },
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.description),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Flexible(
                                          child: TextFormField(
                                            /*validator: (text) {
                                                if (text == null || text.isEmpty) {
                                                  return "Description cannot be empty";
                                                } else if (text.length < 10) {
                                                  return "Description can't be less than 10 chars";
                                                } else if (text.length > 150) {
                                                  return "Description can't be more than 150 chars";
                                                }
                                                return null;
                                              },*/
                                            autovalidateMode: AutovalidateMode
                                                .onUserInteraction,
                                            controller:
                                                textpostdescriptioncontroller,
                                            //maxLength: 150,
                                            readOnly: true,
                                            maxLines: null,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1!
                                                .copyWith(
                                                  color: kHeadlineColorDark,
                                                ),
                                            decoration:
                                                const InputDecoration.collapsed(
                                              hintText:
                                                  'Start typing your post...',
                                              /*  hintStyle: Theme.of(context)
                                                    .textTheme
                                                    .labelMedium!
                                                    .copyWith(
                                                      fontSize: 17.0,
                                                      letterSpacing: -0.41,
                                                      color: kSubTextColor,
                                                    ),*/
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                thickness: 2,
                                color: kBackgroundColorDark2,
                              ),
                            ],
                          ),
                        ),
                      )),
                ),
              )
            : WillPopScope(
                onWillPop: () async => false,
                child: const Scaffold(
                  resizeToAvoidBottomInset: false,
                  body: Center(
                      child: CupertinoActivityIndicator(
                    color: kDarkPrimaryColor,
                  )),
                ),
              );
  }
}
