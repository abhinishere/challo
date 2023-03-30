import 'dart:io';
import 'dart:math';

import 'package:challo/helpers/link_preview.dart';
import 'package:challo/models/link_model.dart';
import 'package:challo/models/lits_model.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/button_simple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

class LitsUpdate extends StatefulWidget {
  final String docName;
  final UserInfoModel onlineuser;
  final bool whetherEditing;
  final LitsModel? lit;
  //final bool whetherFromEventDetail; //from an individual update page
  const LitsUpdate({
    required this.docName,
    required this.onlineuser,
    required this.whetherEditing,
    this.lit,
    //required this.whetherFromEventDetail,
  });

  @override
  State<LitsUpdate> createState() => _LitsUpdateState();
}

class _LitsUpdateState extends State<LitsUpdate> {
  @override
  void initState() {
    super.initState();
    getEditData();
  }

  String generateImageFileName(String updateDocName) {
    String newDocName = (updateDocName + getRandomString(5));
    return newDocName;
  }

  bool dataisthere = false;

  getEditData() async {
    if (widget.whetherEditing == false) {
      updateDocName = generateUpdatedocName();
      setState(() {
        dataisthere = true;
      });
    } else {
      updateDocName = widget.lit!.updateDocName;
      titleController.text = widget.lit?.title ?? '';
      descriptionController.text = widget.lit?.description ?? '';
      sourceController.text = widget.lit?.link ?? '';
      oldImages = widget.lit?.images ?? [];

      for (String i in oldImages) {
        print("url is $i");
      }
      setState(() {
        dataisthere = true;
      });
    }
  }

  bool uploadingToServer = false;
  //bool dataisthere = false;

  bool popAnyChanges = false;

  final _addUpdateKey = GlobalKey<FormState>();

  late String updateDocName;

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController sourceController = TextEditingController();

  List oldImages = [];
  List newImages = [];

  void _explainLitsUpdate() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text("Lits event"),
        content: const Text(
          "Use this form to add a brief timely post on your Lits timeline so that the readers can catch up on what's happening.",
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

  showTextSheetWithLimit(
    String typingWhat,
    int minLength,
    int maxLength,
    bool whetherMultiLine,
    TextEditingController _textEditingController,
    bool whetherOptional,
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
                        if (whetherOptional == true) {
                          if (text == null || text.isEmpty) {
                            return null;
                          } else if (text.length < minLength) {
                            return "$typingWhat can't be less than ${minLength.toString()} chars";
                          } else if (text.length > maxLength) {
                            return "$typingWhat can't be more than ${maxLength.toString()} chars";
                          }
                        } else {
                          if (text == null || text.isEmpty) {
                            return "$typingWhat cannot be empty";
                          } else if (text.length < minLength) {
                            return "$typingWhat can't be less than ${minLength.toString()} chars";
                          } else if (text.length > maxLength) {
                            return "$typingWhat can't be more than ${maxLength.toString()} chars";
                          }
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

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateUpdatedocName() {
    final String time = DateTime.now().toString();
    final String newDocName =
        widget.docName + getRandomString(5) + time.substring(0, 10);
    return newDocName;
  }

  editLitsUpdateToServer() async {
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    final DateTime time = dateFormat.parse("2022-10-31 09:50:25");
    popAnyChanges = true;
    List _imageUrls = oldImages;
    setState(() {
      uploadingToServer = true;
    });
    //int count = 0;
    final String litsUpdateTitle = titleController.text;
    final String litsUpdateDescription = descriptionController.text;
    final String eventLink = sourceController.text;
    LinkModel? linkModel;
    if (widget.lit?.updateDocName != null) {
      if (sourceController.text.isNotEmpty) {
        //a link is inclued; fetch domainName and other info

        extractDataFromLink(eventLink).then((value) async => {
              linkModel = value,
              if (newImages.isNotEmpty)
                {
                  //upload to storage
                  uploadFiles(newImages).then((value) async => {
                        _imageUrls.addAll(value),
                        await litsdb
                            .child(widget.docName)
                            .child(updateDocName)
                            .update({
                          'title': litsUpdateTitle,
                          'description': litsUpdateDescription,
                          'link': eventLink,
                          'domainName': linkModel!.domain,
                          'linkTitle': linkModel!.title,
                          'linkImage': linkModel!.image,
                          'linkDescription': linkModel!.description,
                          'images': _imageUrls,
                        }).then((_) => {
                                  Navigator.pop(context, popAnyChanges),
                                })
                      })
                }
              else
                {
                  //if no images
                  await litsdb
                      .child(widget.docName)
                      .child(updateDocName)
                      .update({
                    'title': litsUpdateTitle,
                    'description': litsUpdateDescription,
                    'link': eventLink,
                    'domainName': linkModel!.domain,
                    'linkTitle': linkModel!.title,
                    'linkImage': linkModel!.image,
                    'linkDescription': linkModel!.description,
                    'images': _imageUrls,
                  }).then((_) => {
                            Navigator.pop(context, popAnyChanges),
                          })
                }
            });
      } else {
        if (newImages.isNotEmpty) {
          //upload to storage
          uploadFiles(newImages).then((value) async => {
                _imageUrls.addAll(value),
                await litsdb.child(widget.docName).child(updateDocName).update({
                  'title': litsUpdateTitle,
                  'description': litsUpdateDescription,
                  'link': '',
                  'domainName': '',
                  'linkTitle': '',
                  'linkImage': '',
                  'linkDescription': '',
                  'images': _imageUrls,
                  'time': time.millisecondsSinceEpoch,
                }).then((_) => {
                      Navigator.pop(context, popAnyChanges),
                    })
              });
        } else {
          //if no images
          await litsdb.child(widget.docName).child(updateDocName).update({
            'title': litsUpdateTitle,
            'description': litsUpdateDescription,
            'link': '',
            'domainName': '',
            'linkTitle': '',
            'linkImage': '',
            'linkDescription': '',
            'images': _imageUrls,
            'time': time.millisecondsSinceEpoch,
          }).then((_) => {
                Navigator.pop(context, popAnyChanges),
              });
        }
      }
    }
  }

  _validateUrl(String url) {
    if (url.startsWith('http://') == true ||
        url.startsWith('https://') == true) {
      return url;
    } else {
      return 'http://$url';
    }
  }

  Future<LinkModel> extractDataFromLink(String url) async {
    const String placeholderImage =
        'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/assets%2Fimages%2Fimage_404_error?alt=media&token=e30dedd9-66dc-402d-af15-38fbb6724eb3';
    dynamic data;
    Uri? uri;
    await FetchPreview().fetch(url).then((res) {
      data = res;
    });
    uri = Uri.parse(_validateUrl(url));

    /*.then((_) => {
          print("Inside linkdatacollected true if statement"),
          linkTitle = data['title'] ?? 'No title',
          linkImage = (data['image'] == '')
              ? placeholderImage
              : data['image'] ?? placeholderImage,
          linkDescription = data['description'] ?? 'nothing...',
          uri = Uri.parse(_validateUrl(url)),
          domainName =
              (uri?.host == '') ? 'domainError' : uri?.host ?? 'domainError',
          print('domainname is $domainName'),
        });*/

    return LinkModel(
        title: data['title'] ?? 'Error',
        description: data['description'] ?? 'error...',
        image: (data['image'] == '')
            ? placeholderImage
            : data['image'] ?? placeholderImage,
        domain: (uri.host == '') ? 'domainError' : uri.host);
  }

  addLitsUpdateToServer() async {
    setState(() {
      uploadingToServer = true;
    });
    //int count = 0;

    final String litsUpdateTitle = titleController.text;
    final String litsUpdateDescription = descriptionController.text;
    final String eventLink = sourceController.text;
    //final time = DateTime.now();
    DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm:ss");
    final DateTime time = dateFormat.parse("2022-10-31 11:43:36");
    final timestamp = time.millisecondsSinceEpoch;
    List<String> _imageUrls = [];
    LinkModel? linkModel;

    if (sourceController.text.isNotEmpty) {
      //a link is inclued; fetch domainName and other info
      extractDataFromLink(eventLink).then((value) async => {
            linkModel = value,
            if (imagefiles.isNotEmpty)
              {
                //upload to storage
                uploadFiles(imagefiles).then((value) async => {
                      _imageUrls = value,
                      await litsdb
                          .child(widget.docName)
                          .child(updateDocName)
                          .set({
                        'updateDocName': updateDocName,
                        'title': litsUpdateTitle,
                        'description': litsUpdateDescription,
                        'link': eventLink,
                        'domainName': linkModel!.domain,
                        'linkTitle': linkModel!.title,
                        'linkImage': linkModel!.image,
                        'linkDescription': linkModel!.description,
                        'images': _imageUrls,
                        'time': timestamp,
                        'status': 'published',
                      }).then((_) async => {
                                await litscollection
                                    .doc(widget.docName)
                                    .update({
                                  'litscount': FieldValue.increment(1),
                                }).then((_) => {
                                          Navigator.pop(context),
                                        })
                              })
                    })
              }
            else
              {
                //if no images
                await litsdb.child(widget.docName).child(updateDocName).set({
                  'updateDocName': updateDocName,
                  'title': litsUpdateTitle,
                  'description': litsUpdateDescription,
                  'link': eventLink,
                  'domainName': linkModel!.domain,
                  'linkTitle': linkModel!.title,
                  'linkImage': linkModel!.image,
                  'linkDescription': linkModel!.description,
                  'images': _imageUrls,
                  'time': timestamp,
                  'status': 'published',
                }).then((_) async => {
                      await litscollection.doc(widget.docName).update({
                        'litscount': FieldValue.increment(1),
                      }).then((_) => {
                            Navigator.pop(context),
                          })
                    })
              }
          });
    } else {
      if (imagefiles.isNotEmpty) {
        //upload to storage
        uploadFiles(imagefiles).then((value) async => {
              _imageUrls = value,
              await litsdb.child(widget.docName).child(updateDocName).set({
                'updateDocName': updateDocName,
                'title': litsUpdateTitle,
                'description': litsUpdateDescription,
                'link': '',
                'domainName': '',
                'linkTitle': '',
                'linkImage': '',
                'linkDescription': '',
                'images': _imageUrls,
                'time': timestamp,
                'status': 'published',
              }).then((_) async => {
                    await litscollection.doc(widget.docName).update({
                      'litscount': FieldValue.increment(1),
                    }).then((_) => {
                          Navigator.pop(context),
                        })
                  })
            });
      } else {
        //if no images
        await litsdb.child(widget.docName).child(updateDocName).set({
          'updateDocName': updateDocName,
          'title': litsUpdateTitle,
          'description': litsUpdateDescription,
          'link': '',
          'domainName': '',
          'linkTitle': '',
          'linkImage': '',
          'linkDescription': '',
          'images': _imageUrls,
          'time': timestamp,
          'status': 'published',
        }).then((_) async => {
              await litscollection.doc(widget.docName).update({
                'litscount': FieldValue.increment(1),
              }).then((_) => {
                    Navigator.pop(context),
                  })
            });
      }
    }

    /*await litsdb.child(widget.docName).child(updateDocName).set({
      'updateDocName': updateDocName,
      'title': litsUpdateTitle,
      'description': litsUpdateDescription,
      'link': (sourceController.text.isEmpty) ? '' : sourceController.text,
      //'domainName':
      //'images':
      'time': timestamp,
      'status': 'published',
    }).then((_) async => {
          await litscollection.doc(widget.docName).update({
            'litscount': FieldValue.increment(1),
          }).then((_) => {
                Navigator.pop(context),
              })
        });*/
  }

  List imagefiles = [];
  XFile? image;
  List<String> imageUrls = [];

  pickImagefromGallery() async {
    final ImagePicker _imagePicker = ImagePicker();

    await Permission.photos.request();

    var galleryPermissionStatus = await Permission.photos.status;

    if (galleryPermissionStatus.isGranted) {
      image = await _imagePicker.pickImage(
          source: ImageSource.gallery, imageQuality: 50);

      if (widget.whetherEditing == false) {
        setState(() {
          imagefiles.add(File(image!.path));
        });
      } else {
        setState(() {
          newImages.add(File(image!.path));
        });
      }
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
    return (widget.whetherEditing == false)
        ? Container(
            child: Row(
              children: [
                for (var eachimage in imagefiles)
                  Flexible(
                    child: Stack(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          child: Image.file(
                            eachimage,
                            fit: BoxFit.fill,
                          ),
                        ),
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
          )
        : Container(
            child: Row(
              children: [
                Row(
                  children: [
                    for (var eachimage in oldImages)
                      Stack(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            child: Image.network(
                              eachimage,
                              fit: BoxFit.fill,
                            ),
                          ),
                          Positioned(
                            right: 0.0,
                            top: 0.0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  oldImages.remove(eachimage);
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
                  ],
                ),
                Row(
                  children: [
                    for (var eachimage in newImages)
                      Stack(
                        children: [
                          Container(
                            height: 50,
                            width: 50,
                            child: Image.file(
                              eachimage,
                              fit: BoxFit.fill,
                            ),
                          ),
                          Positioned(
                            right: 0.0,
                            top: 0.0,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  newImages.remove(eachimage);
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
                  ],
                ),
              ],
            ),
          );
  }

  //handling image uploads
  Future<List<String>> uploadFiles(List _images) async {
    var imageUrls =
        await Future.wait(_images.map((_image) => uploadFile(_image)));
    print(imageUrls);
    return imageUrls;
  }

  Future<String> uploadFile(File _image) async {
    final String _randomFileName = generateImageFileName(updateDocName);
    Reference storageReference = FirebaseStorage.instance
        .ref()
        .child('lits_data')
        .child(widget.docName)
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        Navigator.pop(context);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: (widget.whetherEditing == false)
              ? const Text("Add Lits Event")
              : const Text("Edit Lits Event"),
          centerTitle: true,
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
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
                onTap: () => _explainLitsUpdate(),
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
                key: _addUpdateKey,
                child: SafeArea(
                  child: Container(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                                      } else if (text.length > 70) {
                                        return "Title can't be more than 70 chars";
                                      }
                                      return null;
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    controller: titleController,
                                    maxLength: 70,
                                    readOnly: true,
                                    maxLines: 2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText1!
                                        .copyWith(color: Colors.white),
                                    decoration: const InputDecoration.collapsed(
                                        hintText: 'Add a title...',
                                        hintStyle: TextStyle(
                                          color: kSubTextColor,
                                        )),
                                    onTap: () {
                                      showTextSheetWithLimit("Title", 5, 70,
                                          false, titleController, false);
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
                                const Icon(
                                  Icons.short_text,
                                ),
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
                                      } else if (text.length > 300) {
                                        return "Description can't be more than 300 chars";
                                      }
                                      return null;
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    controller: descriptionController,
                                    maxLength: 300,
                                    readOnly: true,
                                    maxLines: 2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText1!
                                        .copyWith(color: Colors.white),
                                    decoration: const InputDecoration.collapsed(
                                        hintText: 'Add a description...',
                                        hintStyle: TextStyle(
                                          color: kSubTextColor,
                                        )),
                                    onTap: () {
                                      showTextSheetWithLimit(
                                          "Description",
                                          5,
                                          300,
                                          true,
                                          descriptionController,
                                          false);
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
                                const Icon(
                                  Icons.link,
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Flexible(
                                  child: TextFormField(
                                    validator: (text) {
                                      if (text!.isNotEmpty) {
                                        if (text.length < 3) {
                                          return "Link can't be less than 3 chars";
                                        } else if (text.length > 2048) {
                                          return "Link can't be more than 2048 chars";
                                        }
                                      } //optional field
                                      return null;
                                    },
                                    autovalidateMode:
                                        AutovalidateMode.onUserInteraction,
                                    controller: sourceController,
                                    maxLength: 2048,
                                    readOnly: true,
                                    maxLines: 2,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyText1!
                                        .copyWith(color: Colors.white),
                                    decoration: const InputDecoration.collapsed(
                                        hintText:
                                            'Add an optional source link...',
                                        hintStyle: TextStyle(
                                          color: kSubTextColor,
                                        )),
                                    onTap: () {
                                      showTextSheetWithLimit("Source Link", 3,
                                          2048, false, sourceController, true);
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
                          const Padding(
                            padding: EdgeInsets.only(left: 10.0),
                            child: Text(
                              "Add optional images",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: kSubTextColor,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 5.0,
                          ),
                          Row(
                            children: [
                              const SizedBox(
                                width: 10.0,
                              ),
                              (widget.whetherEditing == false)
                                  ? (imagefiles.isEmpty ||
                                          imagefiles.length < 4)
                                      ? InkWell(
                                          onTap: () {
                                            pickImagefromGallery();
                                          },
                                          child: Container(
                                            height: 50,
                                            width: 50,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade500),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.add,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container()
                                  : ((oldImages.length + newImages.length) < 4)
                                      ? InkWell(
                                          onTap: () {
                                            pickImagefromGallery();
                                          },
                                          child: Container(
                                            height: 50,
                                            width: 50,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.grey.shade500),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.add,
                                              ),
                                            ),
                                          ),
                                        )
                                      : Container(),
                              (imagefiles.isEmpty &&
                                      widget.whetherEditing == false)
                                  ? Container()
                                  : Expanded(child: _multipleImagesWidget()),
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ButtonSimple(
                                color: kPrimaryColor,
                                textColor: kHeadlineColorDark,
                                text: (widget.whetherEditing == false)
                                    ? "Add event"
                                    : "Update event",
                                onPress: () async {
                                  if (_addUpdateKey.currentState!.validate()) {
                                    if (widget.whetherEditing == false) {
                                      addLitsUpdateToServer();
                                    } else {
                                      editLitsUpdateToServer();
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
