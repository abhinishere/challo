import 'dart:io';
import 'dart:math';

import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/lits_timeline_2.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/button_simple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class AddLits extends StatefulWidget {
  final UserInfoModel onlineuser;
  final bool whetherEditing;
  final bool whetherFromPost;
  final String? docName;
  const AddLits({
    required this.onlineuser,
    required this.whetherEditing,
    required this.whetherFromPost,
    this.docName,
  });

  @override
  State<AddLits> createState() => _AddLitsState();
}

class _AddLitsState extends State<AddLits> {
  @override
  void initState() {
    super.initState();
    getalldata();
  }

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generatedocName() {
    String newdocName = (widget.onlineuser.username! + getRandomString(5));
    return newdocName;
  }

  bool dataisthere = false;
  bool uploadingToServer = false;
  final _addLitsKey = GlobalKey<FormState>();
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  dynamic imageFilePath;
  bool whetherImageSelected = false;
  String imageUrl = '';
  RegExp allexp = RegExp(r'[\s,;/.!:?({\[&)\]}]+');
  String titleForEditing = '';
  String descriptionForEditing = '';
  String imageForEditing = '';
  bool whetherImageEdited = false;

  bool whetherchanged = false;

  getalldata() async {
    if (widget.whetherEditing == true) {
      whetherImageSelected = true;
      DocumentSnapshot litsdocs =
          await litscollection.doc(widget.docName).get();
      titleForEditing = litsdocs['topic'];
      descriptionForEditing = litsdocs['description'];
      imageForEditing = litsdocs['image'];
      titleController.text = titleForEditing;
      descriptionController.text = descriptionForEditing;

      setState(() {
        dataisthere = true;
      });
    } else {
      setState(() {
        dataisthere = true;
      });
    }
  }

  getImageFromGallery() async {
    final ImagePicker _picker = ImagePicker();
    XFile? image;

    await Permission.photos.request();

    var galleryPermissionStatus = await Permission.photos.status;

    if (galleryPermissionStatus.isGranted) {
      image = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 50);
      imageFilePath = File(image!.path);
      setState(() {
        whetherImageSelected = true;
      });
    } else {
      //permission issues
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

  void _explainLits() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text("Challo Lits (Beta)"),
        content: const Text(
          "Live Interactive Timeline Stories (Lits) organizes progressing news stories, cricket matches and other events as a timeline, and includes live chats. Each Lits post is currently setup to disappear after 24 hours, but this may change in the future.",
          textAlign: TextAlign.left,
        ),
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

  List<String> stringtoList(String videoinfostring) {
    final List<String> infoinlist0 = videoinfostring.split(allexp);
    final List<String> infoinlist =
        infoinlist0.map((email) => email.toLowerCase()).toList();
    infoinlist.removeWhere((value) => value == "");
    return (infoinlist);
  }

  editToServer() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    final DateTime time = dateFormat.parse("2022-10-31 07:30:46");
    whetherchanged = true;
    setState(() {
      uploadingToServer = true;
    });
    if (whetherImageEdited == true) {
      final _storage = FirebaseStorage.instance;
      await _storage
          .ref()
          .child('lits_data')
          .child(widget.docName!)
          .child(generatedocName())
          .putFile(
            imageFilePath,
            SettableMetadata(
              customMetadata: null,
            ),
          )
          .then((p0) => {
                p0.ref
                    .getDownloadURL()
                    .then((value) => {
                          imageUrl = value,
                        })
                    .then((_) => {
                          litscollection.doc(widget.docName).update({
                            'topic': titleController.text,
                            'topicinlist': stringtoList(titleController.text),
                            'description': (descriptionController.text == '')
                                ? ''
                                : descriptionController.text,
                            'descriptioninlist':
                                stringtoList(descriptionController.text),
                            'image': imageUrl,
                          }).then((_) => {
                                usercollection
                                    .doc(widget.onlineuser.uid)
                                    .collection('lits')
                                    .doc(widget.docName)
                                    .update({
                                  'topic': titleController.text,
                                  'description':
                                      (descriptionController.text == '')
                                          ? ''
                                          : descriptionController.text,
                                  'image': imageUrl,
                                }).then((_) => {
                                          Navigator.pop(
                                              context, whetherchanged),
                                        })
                              })
                        })
              });
    } else {
      await litscollection.doc(widget.docName).update({
        'topic': titleController.text,
        'topicinlist': stringtoList(titleController.text),
        'description': (descriptionController.text == '')
            ? ''
            : descriptionController.text,
        'descriptioninlist': stringtoList(descriptionController.text),
        'time': time,
      }).then((_) async => {
            usercollection
                .doc(widget.onlineuser.uid)
                .collection('lits')
                .doc(widget.docName)
                .update({
              'topic': titleController.text,
              'description': (descriptionController.text == '')
                  ? ''
                  : descriptionController.text,
              'time': time,
            }).then((_) => {
                      Navigator.pop(context, whetherchanged),
                    })
          });
    }
  }

  uploadToServer() async {
    setState(() {
      uploadingToServer = true;
    });
    final String docName = generatedocName();
    final time = DateTime.now();
    List<String> blockedby = [];

    if (whetherImageSelected == true) {
      final _storage = FirebaseStorage.instance;
      await _storage
          .ref()
          .child('lits_data')
          .child(docName)
          .child(generatedocName())
          .putFile(
            imageFilePath,
            SettableMetadata(
              customMetadata: null,
            ),
          )
          .then((p0) => {
                p0.ref
                    .getDownloadURL()
                    .then((value) => {
                          imageUrl = value,
                        })
                    .then((_) async => {
                          await litscollection.doc(docName).set({
                            'type': 'litsv1',
                            'status': 'published',
                            'docName': docName,
                            'whethercommunitypost': false,
                            'communityName': '',
                            'communitypic': '',
                            'topic': titleController.text,
                            'topicinlist': stringtoList(titleController.text),
                            'description': (descriptionController.text == '')
                                ? ''
                                : descriptionController.text,
                            'descriptioninlist':
                                stringtoList(descriptionController.text),
                            'image': imageUrl,
                            'likes': [],
                            'dislikes': [],
                            'litscount': 0,
                            'commentcount': 0,
                            'totalviews': [],
                            'opuid': widget.onlineuser.uid,
                            'opusername': widget.onlineuser.username,
                            'oppic': widget.onlineuser.pic,
                            'time': time,
                            'blockedby': blockedby,
                            'topfeaturedpriority': 0,
                            'trendingpriority': 0,
                            'communitypostpriority': 0,
                          }).then((_) async => {
                                await usercollection
                                    .doc(widget.onlineuser.uid)
                                    .collection('lits')
                                    .doc(docName)
                                    .set({
                                  'type': 'litsv1',
                                  'docName': docName,
                                  'status': 'published',
                                  'whethercommunitypost': false,
                                  'communityName': '',
                                  'communitypic': '',
                                  'topic': titleController.text,
                                  'description':
                                      (descriptionController.text == '')
                                          ? ''
                                          : descriptionController.text,
                                  'image': imageUrl,
                                  'time': time,
                                  'blockedby': blockedby,
                                }).then((_) async => {
                                          await litscollection
                                              .doc(docName)
                                              .get()
                                              .then((value) => {
                                                    if (value.exists)
                                                      {
                                                        //push to Timeline
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder: (context) =>
                                                                LitsTimeline2(
                                                              docName: docName,
                                                              whetherJustCreated:
                                                                  true,
                                                            ),
                                                            fullscreenDialog:
                                                                true,
                                                          ),
                                                        ),
                                                      }
                                                    else
                                                      {
                                                        //some error
                                                      }
                                                  })
                                        })
                              })
                        }),
              });
    } else {
      //image error
    }
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
                Divider(
                  thickness: 1,
                  color: Colors.grey.shade800,
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (widget.whetherEditing == false) {
          setState(() {
            hidenav = false;
          });
          AppBuilder.of(context)!.rebuild();
          Navigator.pop(context);
        } else {
          if (widget.whetherFromPost == false) {
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
          title: (widget.whetherEditing == false)
              ? const Text("Add Lits")
              : const Text("Edit Lits"),
          centerTitle: true,
          leading: GestureDetector(
            onTap: () {
              if (widget.whetherEditing == false) {
                setState(() {
                  hidenav = false;
                });
                AppBuilder.of(context)!.rebuild();
                Navigator.pop(context);
              } else {
                if (widget.whetherFromPost == false) {
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
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 15.0),
              child: InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () => _explainLits(),
                child: const Icon(
                  CupertinoIcons.question_circle_fill,
                ),
              ),
            ),
          ],
        ),
        body: (dataisthere == false || uploadingToServer == true)
            ? const Center(
                child: CupertinoActivityIndicator(color: kDarkPrimaryColor))
            : Form(
                key: _addLitsKey,
                child: SafeArea(
                  child: Container(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Divider(
                            thickness: 1,
                            color: Colors.grey.shade800,
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
                                      } else if (text.length > 15) {
                                        return "Title can't be more than 15 chars";
                                      }
                                      return null;
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    controller: titleController,
                                    maxLength: 15,
                                    readOnly: true,
                                    maxLines: 2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText1!
                                        .copyWith(color: Colors.white),
                                    decoration: const InputDecoration.collapsed(
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
                                      showTextSheetWithLimit("Title", 5, 15,
                                          false, titleController);
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                          Divider(
                            thickness: 1,
                            color: Colors.grey.shade800,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Row(
                              children: [
                                const Icon(Icons.short_text),
                                const SizedBox(
                                  width: 10,
                                ),
                                Flexible(
                                  child: TextFormField(
                                    validator: (text) {
                                      if (text == null || text.isEmpty) {
                                        return "Description cannot be empty";
                                      } else if (text.length < 5) {
                                        return "Description can't be less than 5 chars";
                                      } else if (text.length > 150) {
                                        return "Description can't be more than 150 chars";
                                      }
                                      return null;
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    controller: descriptionController,
                                    maxLength: 150,
                                    readOnly: true,
                                    maxLines: 2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText1!
                                        .copyWith(color: Colors.white),
                                    decoration: const InputDecoration.collapsed(
                                      hintText: 'Add description...',
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
                                      showTextSheetWithLimit("Description", 5,
                                          150, false, descriptionController);
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),
                          Divider(
                            thickness: 1,
                            color: Colors.grey.shade800,
                          ),
                          (whetherImageSelected == false)
                              ? Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: InkWell(
                                    onTap: () => getImageFromGallery(),
                                    child: Container(
                                      height: 250,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.grey.shade500),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "Add featured image from gallery",
                                          style: Theme.of(context)
                                              .textTheme
                                              .subtitle1!
                                              .copyWith(
                                                  color: Colors.grey.shade500),
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : (widget.whetherEditing == true)
                                  ? (whetherImageEdited == false)
                                      ? Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Stack(
                                            children: [
                                              Container(
                                                height: 250,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey.shade500),
                                                ),
                                                child: Center(
                                                  child: Image.network(
                                                    imageForEditing,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                  right: 10.0,
                                                  top: 10.0,
                                                  child: InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          whetherImageEdited =
                                                              true;
                                                          whetherImageSelected =
                                                              false;
                                                        });
                                                      },
                                                      child: const Icon(
                                                        Icons.close,
                                                        color: Colors.redAccent,
                                                        size: 30.0,
                                                      )))
                                            ],
                                          ),
                                        )
                                      : Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: Stack(
                                            children: [
                                              Container(
                                                height: 250,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                      color:
                                                          Colors.grey.shade500),
                                                ),
                                                child: Center(
                                                  child:
                                                      Image.file(imageFilePath),
                                                ),
                                              ),
                                              Positioned(
                                                  right: 10.0,
                                                  top: 10.0,
                                                  child: InkWell(
                                                      onTap: () {
                                                        setState(() {
                                                          whetherImageSelected =
                                                              false;
                                                        });
                                                      },
                                                      child: const Icon(
                                                        Icons.close,
                                                        color: Colors.redAccent,
                                                        size: 30.0,
                                                      )))
                                            ],
                                          ),
                                        )
                                  : Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Stack(
                                        children: [
                                          Container(
                                            height: 250,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade500),
                                            ),
                                            child: Center(
                                              child: Image.file(imageFilePath),
                                            ),
                                          ),
                                          Positioned(
                                              right: 10.0,
                                              top: 10.0,
                                              child: InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      whetherImageSelected =
                                                          false;
                                                    });
                                                  },
                                                  child: const Icon(
                                                    Icons.close,
                                                    color: Colors.redAccent,
                                                    size: 30.0,
                                                  )))
                                        ],
                                      ),
                                    ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ButtonSimple(
                                color: kPrimaryColor,
                                textColor: kHeadlineColorDark,
                                text: (widget.whetherEditing == false)
                                    ? "Publish & go to timeline"
                                    : "Update & go to timeline",
                                onPress: () async {
                                  if (_addLitsKey.currentState!.validate()) {
                                    if (whetherImageSelected == false) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Umm... you have not picked any image.",
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      );
                                    } else {
                                      if (widget.whetherEditing == false) {
                                        uploadToServer();
                                      } else {
                                        //edits
                                        editToServer();
                                      }
                                    }
                                  }
                                }),
                          )
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
