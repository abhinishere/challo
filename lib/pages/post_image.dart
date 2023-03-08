import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/image_page_2.dart';
import 'package:challo/variables.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class PostImage extends StatefulWidget {
  final UserInfoModel? onlineuser;
  final bool whethercommunitypost;
  final String? communityName;
  final String? communitypic;
  final bool whetherediting;
  final bool? whetherfrompost;
  final String? docName;

  const PostImage({
    required this.onlineuser,
    required this.whethercommunitypost,
    this.communityName,
    this.communitypic,
    required this.whetherediting,
    this.whetherfrompost,
    this.docName,
  });

  @override
  State<PostImage> createState() => _PostImageState();
}

class _PostImageState extends State<PostImage> {
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
      docName = widget.docName!;
      //initial data for making edits
      var imagedocs = await contentcollection.doc(docName).get();
      final String topicText = imagedocs['topic'];
      imageUrls = List.from(imagedocs['imageslist']);
      imageposttitlecontroller.text = topicText;
      setState(() {
        allset = true;
      });
    }
  }

  final _imagePostKey = GlobalKey<FormState>();

  TextEditingController imageposttitlecontroller = TextEditingController();
  //TextEditingController imagepostdesccontroller = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();
  final FocusNode descFocusNode = FocusNode();
  List imagefiles = [];
  List<String> imageUrls = [];
  bool whetherimageselected = false;
  bool allset = false;
  RegExp exp = RegExp(r'[\s,;/.!:?({\[&)\]}]+');
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();
  XFile? image;

  Map<String, String> placesMap = {};
  List<String> placesList = [];
  String selectedPlace = 'profile';
  bool whethercommunitypost = false;
  String communityName = '';
  String communityPic = '';

  late String docName;

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generatedocName() {
    String newdocName = (widget.onlineuser!.username! + getRandomString(5));
    return newdocName;
  }

  String generateImageFileName(String docName) {
    String newDocName = (docName + getRandomString(5));
    return newDocName;
  }

  bool showpublishloading = false;

  pickImagefromGallery() async {
    final ImagePicker _imagePicker = ImagePicker();

    await Permission.photos.request();

    var galleryPermissionStatus = await Permission.photos.status;

    if (galleryPermissionStatus.isGranted) {
      image = await _imagePicker.pickImage(
          source: ImageSource.gallery, imageQuality: 50);

      setState(() {
        imagefiles.add(File(image!.path));
      });

      setState(() {
        whetherimageselected = true;
      });
    } else {
      //permission error
      _showPermissionDenied();
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

  Widget _multipleImagesWidget() {
    return (widget.whetherediting == false)
        ? Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              child: Row(
                children: [
                  for (var eachimage in imagefiles)
                    Flexible(
                      child: Stack(
                        children: [
                          Container(height: 50, child: Image.file(eachimage)),
                          Positioned(
                            right: 0.0,
                            top: 0.0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  imagefiles.remove(eachimage);
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              child: Row(
                children: [
                  for (var eachimage in imageUrls)
                    Flexible(
                      child: Container(
                          height: 50, child: Image.network(eachimage)),
                    ),
                ],
              ),
            ),
          );
  }

  List<String> stringtoList(String videoinfostring) {
    final List<String> infoinlist0 = videoinfostring.split(exp);
    final List<String> infoinlist =
        infoinlist0.map((email) => email.toLowerCase()).toList();
    infoinlist.removeWhere((value) => value == "");
    return (infoinlist);
  }

  editpublish() async {
    setState(() {
      showpublishloading = true;
    });
    await contentcollection.doc(docName).get().then((value) async => {
          if (value.exists)
            {
              await contentcollection.doc(docName).update({
                'topic': imageposttitlecontroller.text,
                'topicinlist': stringtoList(imageposttitlecontroller.text),
              }).then((value) async => {
                    await usercollection
                        .doc(widget.onlineuser!.uid)
                        .collection('content')
                        .doc(docName)
                        .update({
                      'topic': imageposttitlecontroller.text,
                    }).then((value) async => {
                              if (whethercommunitypost == true)
                                {
                                  await communitycollection
                                      .doc(communityName)
                                      .collection('content')
                                      .doc(docName)
                                      .update({
                                    'topic': imageposttitlecontroller.text,
                                  }).then((value) => {
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
                                          })
                                }
                              else
                                {
                                  if (widget.whetherfrompost == false)
                                    {
                                      setState(() {
                                        hidenav = false;
                                      }),
                                      AppBuilder.of(context)!.rebuild(),
                                      Navigator.pop(context, true)
                                    }
                                  else
                                    {Navigator.pop(context, true)}
                                }
                            }),
                  }),
            }
          else
            {
              //error message
            }
        });
  }

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

  //handling image uploads
  Future<List<String>> uploadFiles(List _images) async {
    var imageUrls =
        await Future.wait(_images.map((_image) => uploadFile(_image)));
    print(imageUrls);
    return imageUrls;
  }

  Future<String> uploadFile(File _image) async {
    final String _randomFileName = generateImageFileName(docName);
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('image_posts')
        .child(docName)
        .child('/$_randomFileName');
    UploadTask uploadTask = storageReference.putFile(
      _image,
      SettableMetadata(
        customMetadata: null,
      ),
    );
    await uploadTask;

    return await storageReference.getDownloadURL();
  }

  uploadaction() async {
    setState(() {
      showpublishloading = true;
    });
    //final List? imagefiles = widget.imagefiles;
    final String title = imageposttitlecontroller.text;
    const String description = '';
    List<String>? _imageUrls;
    final time = DateTime.now();
    List<String> blockedby = [];

    uploadFiles(imagefiles).then((value) async => {
          _imageUrls = value,
          await contentcollection.doc(docName).set({
            'type': 'imagepost',
            'status': 'published',
            'docName': docName,
            'whethercommunitypost': whethercommunitypost,
            'communityName':
                (whethercommunitypost == false) ? '' : communityName,
            'communitypic': (whethercommunitypost == false) ? '' : communityPic,
            'topic': title,
            'topicinlist': stringtoList(title),
            'description': description,
            'descriptioninlist': stringtoList(description),
            'imageslist': value,
            'likes': [],
            'dislikes': [],
            'commentcount': 0,
            'totalviews': [],
            'links': value,
            'opuid': widget.onlineuser!.uid,
            'opusername': widget.onlineuser!.username,
            'oppic': widget.onlineuser!.pic,
            'time': time,
            'blockedby': blockedby,
            'topfeaturedpriority': 0,
            'trendingpriority': 0,
            'communitypostpriority': 0,
          }).then((value) async => {
                await usercollection
                    .doc(widget.onlineuser!.uid)
                    .collection('content')
                    .doc(docName)
                    .set({
                  'type': 'imagepost',
                  'docName': docName,
                  'whethercommunitypost': whethercommunitypost,
                  'communityName':
                      (whethercommunitypost == false) ? '' : communityName,
                  'communitypic':
                      (whethercommunitypost == false) ? '' : communityPic,
                  'topic': title,
                  'description': description,
                  'imageslist': _imageUrls,
                  'links': _imageUrls,
                  'time': time,
                  'blockedby': blockedby,
                }).then((value) async => {
                          if (whethercommunitypost == true)
                            {
                              await communitycollection
                                  .doc(communityName)
                                  .collection('content')
                                  .doc(docName)
                                  .set({
                                'type': 'imagepost',
                                'docName': docName,
                                'whethercommunitypost': whethercommunitypost,
                                'communityName': (whethercommunitypost == false)
                                    ? ''
                                    : communityName,
                                'communitypic': (whethercommunitypost == false)
                                    ? ''
                                    : communityPic,
                                'topic': title,
                                'description': description,
                                'imageslist': _imageUrls,
                                'links': _imageUrls,
                                'opuid': widget.onlineuser!.uid,
                                'oppic': widget.onlineuser!.pic,
                                'opusername': widget.onlineuser!.username,
                                'time': time,
                                'blockedby': blockedby,
                                'trendingpriority': 0,
                                'topfeaturedpriority': 0,
                                'communitypostpriority': 0,
                              }).then((value) => {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ImagePage2(
                                                        whetherjustcreated:
                                                            true,
                                                        docName: docName,
                                                        showcomments: false)))
                                      })
                            }
                          else
                            {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ImagePage2(
                                          whetherjustcreated: true,
                                          docName: docName,
                                          showcomments: false)))
                            }
                        })
              }),
        });
  }

  //end of image uploads

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
                    color: Colors.white70,
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
        : WillPopScope(
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
                  ),
                ),
                title: Text(
                  (widget.whetherediting == false) ? "Image post" : "Edit post",
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: (showpublishloading == false)
                        ? TextButton(
                            onPressed: () {
                              if (_imagePostKey.currentState!.validate()) {
                                if (widget.whetherediting == false) {
                                  if (imagefiles.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Umm... you have not picked any image.",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    );
                                  } else {
                                    uploadaction();
                                  }
                                } else {
                                  //publish for edits
                                  editpublish();
                                }
                              } else {
                                //error
                              }
                            },
                            child: const Text(
                              "Publish",
                              style: TextStyle(
                                  color: kPrimaryColorTint2,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        : const CupertinoActivityIndicator(
                            color: kDarkPrimaryColor,
                          ),
                  )
                ],
                centerTitle: true,
                elevation: 0.0,
              ),
              body: (showpublishloading == false)
                  ? Form(
                      key: _imagePostKey,
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
                                          } else if (text.length > 70) {
                                            return "Title can't be more than 70 chars";
                                          }
                                          return null;
                                        },
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        controller: imageposttitlecontroller,
                                        maxLength: 70,
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
                                          showTextSheetWithLimit("Title", 5, 70,
                                              false, imageposttitlecontroller);
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
                              /* MinimalTextField(
                              focusNode: titleFocusNode,
                              label: "Title",
                              maxlines: 1,
                              mincharlength: 5,
                              maxcharlength: 70,
                              maxlength: 70,
                              controller: imageposttitlecontroller,
                            ),*/
                              /*MinimalTextField(
                                focusNode: descFocusNode,
                                label: "Description (optional)",
                                maxlines: null,
                                mincharlength: 0,
                                maxcharlength: 165,
                                maxlength: 165,
                                controller: imagepostdesccontroller,
                              ),*/
                              const SizedBox(
                                height: 16,
                              ),
                              (imagefiles.isEmpty &&
                                      widget.whetherediting == false)
                                  ? Container()
                                  : _multipleImagesWidget(),
                              (imagefiles.length < 5 &&
                                      widget.whetherediting == false)
                                  ? Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10.0,
                                            right: 10.0,
                                            bottom: 10.0),
                                        child: InkWell(
                                          onTap: () {
                                            pickImagefromGallery();
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade500),
                                            ),
                                            child: Center(
                                              child: Text(
                                                (imagefiles.isEmpty)
                                                    ? "Tap to select image from gallery"
                                                    : "Add another image from gallery",
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .subtitle1!
                                                    .copyWith(
                                                        color: Colors
                                                            .grey.shade500),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Text(
                                      (widget.whetherediting == false)
                                          ? "You've reached the max limit for uploading images."
                                          : "Making changes to image(s) are not allowed during edits.",
                                      style: Theme.of(context)
                                          .textTheme
                                          .subtitle1!
                                          .copyWith(
                                            fontSize: 12.0,
                                            color: Colors.white70,
                                          ),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(
                            color: kDarkPrimaryColor,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            (widget.whetherediting == false)
                                ? "Uploading image(s)..."
                                : "Updating post...",
                          ),
                        ],
                      ),
                    ),
            ),
          );
  }
}
