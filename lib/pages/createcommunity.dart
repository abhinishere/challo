import 'dart:convert';
import 'dart:io';

import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/community_page.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class CreateCommunity extends StatefulWidget {
  final bool whetherediting;
  final UserInfoModel? onlineuser;
  final String? docName;
  const CreateCommunity({
    required this.whetherediting,
    required this.onlineuser,
    this.docName, //community name required for editing
  });

  @override
  State<CreateCommunity> createState() => _CreateCommunityState();
}

class _CreateCommunityState extends State<CreateCommunity> {
  @override
  void initState() {
    super.initState();
    getalldata();
  }

  getalldata() async {
    if (widget.whetherediting == true) {
      communityName = widget.docName;
      _nameController.text = communityName!;
      DocumentSnapshot communitydocs =
          await communitycollection.doc(communityName!).get();
      mainimgurl = communitydocs['mainimage'];
      backgroundimgurl = communitydocs['backgroundimage'];
      showmainimagepreview = true;
      showbackgroundimagepreview = true;
      _briefDescriptionController.text = communitydocs['description'];
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('communities')
          .child(communityName!);
      await ref
          .child('${communityName}_long_description')
          .getData()
          .then((value) {
        _longDescriptionController.text = utf8.decode(value!.toList());
      });
      await ref.child('${communityName}_rules').getData().then((value) {
        _rulesController.text = utf8.decode(value!.toList());
      });

      setState(() {
        dataisthere = true;
      });
    } else {
      setState(() {
        dataisthere = true;
      });
    }
  }

  bool dataisthere = false;
  bool showloading = false;
  final _createCommunityKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _briefDescriptionController =
      TextEditingController();
  final TextEditingController _longDescriptionController =
      TextEditingController();
  final TextEditingController _rulesController = TextEditingController();
  bool whetherbackimageselected = false;
  bool whethermainimageselected = false;
  XFile? xFileBackImage;
  File? fileBackImage;
  XFile? xFileMainImage;
  File? fileMainImage;
  String errorMessage = '';
  final communityNameRegex = RegExp(r'^[a-zA-Z]+$');
  String backgroundimgurl =
      'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/assets%2Fimages%2Fdark_background_image_1280_720_px?alt=media&token=2fe7fbf8-1399-48b9-9ecf-f43bd3fb93e7';
  String mainimgurl =
      'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/assets%2Fimages%2Fdark_background_image_500px?alt=media&token=dcf5c782-a5e9-419a-a2ee-d4acb1356a4e';
  String rulesurl = '';
  String longdescurl = '';

  //for editing
  String? communityName;
  bool showmainimagepreview = false;
  bool showbackgroundimagepreview = false;

  pickBackImagefromGallery() async {
    final ImagePicker _imagePicker = ImagePicker();

    await Permission.photos.request();

    var galleryPermissionStatus = await Permission.photos.status;

    if (galleryPermissionStatus.isGranted) {
      xFileBackImage = await _imagePicker.pickImage(
          source: ImageSource.gallery, imageQuality: 50);

      setState(() {
        fileBackImage = File(xFileBackImage!.path);
      });

      setState(() {
        whetherbackimageselected = true;
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

  pickMainImagefromGallery() async {
    final ImagePicker _imagePicker = ImagePicker();

    await Permission.photos.request();

    var galleryPermissionStatus = await Permission.photos.status;

    if (galleryPermissionStatus.isGranted) {
      xFileMainImage = await _imagePicker.pickImage(
          source: ImageSource.gallery, imageQuality: 50);

      setState(() {
        fileMainImage = File(xFileMainImage!.path);
      });

      setState(() {
        whethermainimageselected = true;
      });
    } else {
      //permission error
      _showPermissionDenied();
    }
  }

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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

  showTextSheet(
      String typingWhat,
      int minLength,
      int maxLength,
      bool whetherMultiLine,
      TextEditingController typingController,
      bool whetherShowFormatting) {
    showModalBottomSheet(
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
                      controller: typingController,
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

  Future<bool> _communityNameExists(String communityName) async {
    final String communityNameinLowercase = communityName.toLowerCase();
    final result = await communitycollection
        .where('nameinlowercase', isEqualTo: communityNameinLowercase)
        .get();
    return result.docs.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return (showloading == false)
        ? WillPopScope(
            onWillPop: () {
              setState(() {
                hidenav = false;
              });
              AppBuilder.of(context)!.rebuild();
              Navigator.pop(context);
              return Future.value(false);
            },
            child: Scaffold(
              appBar: AppBar(
                title: (widget.whetherediting == false)
                    ? const Text("New community")
                    : const Text("Edit community"),
                centerTitle: true,
                leading: GestureDetector(
                  onTap: () {
                    setState(() {
                      hidenav = false;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.pop(context);
                  },
                  child: const Icon(Icons.arrow_back),
                ),
                actions: (dataisthere == true)
                    ? [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: TextButton(
                            onPressed: () async {
                              final newCommunityName = _nameController.text;
                              if (_createCommunityKey.currentState!
                                  .validate()) {
                                final validExists = await _communityNameExists(
                                    newCommunityName);
                                if (!validExists &&
                                    widget.whetherediting == false) {
                                  errorMessage =
                                      "This community name is already taken.";
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        errorMessage,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 15.0,
                                          //fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  setState(() {
                                    showloading = true;
                                  });
                                  print(
                                      "No error, continue with the creation of community");
                                  List<String> blockedby = [];
                                  List<String> memberuids = [
                                    widget.onlineuser!.uid!,
                                  ];
                                  List<String> moduids = [
                                    widget.onlineuser!.uid!,
                                  ];

                                  Reference ref = FirebaseStorage.instance
                                      .ref()
                                      .child('communities')
                                      .child(newCommunityName);

                                  if (whetherbackimageselected == true &&
                                      whethermainimageselected == true) {
                                    ref
                                        .child('${newCommunityName}_background')
                                        .putFile(
                                          fileBackImage!,
                                          SettableMetadata(
                                            customMetadata: null,
                                          ),
                                        )
                                        .then((p0) => {
                                              p0.ref
                                                  .getDownloadURL()
                                                  .then((backurl) => {
                                                        backgroundimgurl =
                                                            backurl,
                                                        print(
                                                            "BackImage url is $backgroundimgurl"),
                                                      })
                                                  .then((value) => {
                                                        ref
                                                            .child(
                                                                '${newCommunityName}_main')
                                                            .putFile(
                                                              fileMainImage!,
                                                              SettableMetadata(
                                                                customMetadata:
                                                                    null,
                                                              ),
                                                            )
                                                            .then(
                                                              (p1) => p1.ref
                                                                  .getDownloadURL()
                                                                  .then(
                                                                      (mainurl) =>
                                                                          {
                                                                            mainimgurl =
                                                                                mainurl,
                                                                            print("MainImage url is $mainimgurl"),
                                                                          })
                                                                  .then(
                                                                      (value) =>
                                                                          {
                                                                            ref.child('${newCommunityName}_long_description').putString(_longDescriptionController.text, metadata: SettableMetadata(contentType: 'text/markdown')).then(
                                                                                  (p2) => p2.ref
                                                                                      .getDownloadURL()
                                                                                      .then((desclink) => {
                                                                                            longdescurl = desclink,
                                                                                            print("description url is $longdescurl")
                                                                                          })
                                                                                      .then((value) => {
                                                                                            ref
                                                                                                .child('${newCommunityName}_rules')
                                                                                                .putString(
                                                                                                  _rulesController.text,
                                                                                                  metadata: SettableMetadata(
                                                                                                    contentType: 'text/markdown',
                                                                                                    customMetadata: null,
                                                                                                  ),
                                                                                                )
                                                                                                .then(
                                                                                                  (p3) => p3.ref
                                                                                                      .getDownloadURL()
                                                                                                      .then((ruleslink) => {
                                                                                                            rulesurl = ruleslink,
                                                                                                            print("ruless url is $rulesurl"),
                                                                                                          })
                                                                                                      .then((value) async => {
                                                                                                            await communitycollection.doc(newCommunityName).set({
                                                                                                              'status': 'published',
                                                                                                              'name': newCommunityName,
                                                                                                              'nameinlowercase': newCommunityName.toLowerCase(),
                                                                                                              'description': _briefDescriptionController.text,
                                                                                                              'backgroundimage': backgroundimgurl,
                                                                                                              'mainimage': mainimgurl,
                                                                                                              'longdescription': longdescurl,
                                                                                                              'rules': rulesurl,
                                                                                                              'time': DateTime.now(),
                                                                                                              'memberuids': memberuids,
                                                                                                              'moduids': moduids,
                                                                                                              'createdby': widget.onlineuser!.uid!,
                                                                                                              'blockedby': blockedby,
                                                                                                              'communityrules': '', //for old time's sake; no longer needed though
                                                                                                              'featuredpriority': 0,
                                                                                                              'whetherpopular': true, //for old time's sake; no longer needed though
                                                                                                              'prioritypoints': 0, //for old time's sake; no longer needed though
                                                                                                              'toppriority': 0,
                                                                                                            }).then((value) async => {
                                                                                                                  await communitycollection.doc(newCommunityName).collection('mods').doc(widget.onlineuser!.uid).set({
                                                                                                                    'uid': widget.onlineuser!.uid,
                                                                                                                    'username': widget.onlineuser!.username,
                                                                                                                    'profilepic': widget.onlineuser!.pic,
                                                                                                                  }).then((value) => {
                                                                                                                        setState(() {
                                                                                                                          hidenav = false;
                                                                                                                        }),
                                                                                                                        AppBuilder.of(context)!.rebuild(),
                                                                                                                        Navigator.push(
                                                                                                                          context,
                                                                                                                          MaterialPageRoute(
                                                                                                                            builder: ((context) => CommunityPage(
                                                                                                                                  whetherjustcreated: true,
                                                                                                                                  communityname: newCommunityName,
                                                                                                                                )),
                                                                                                                            fullscreenDialog: true,
                                                                                                                          ),
                                                                                                                        )
                                                                                                                      })
                                                                                                                })
                                                                                                          }),
                                                                                                )
                                                                                          }),
                                                                                )
                                                                          }),
                                                            )
                                                      })
                                            });
                                  } else if (whetherbackimageselected ==
                                          false &&
                                      whethermainimageselected == true) {
                                    ref
                                        .child('${newCommunityName}_main')
                                        .putFile(
                                          fileMainImage!,
                                          SettableMetadata(
                                            customMetadata: null,
                                          ),
                                        )
                                        .then((p0) => {
                                              p0.ref
                                                  .getDownloadURL()
                                                  .then((mainurl) => {
                                                        mainimgurl = mainurl,
                                                        print(
                                                            "MainImage url is $mainimgurl"),
                                                      })
                                                  .then((value) => {
                                                        ref
                                                            .child(
                                                                '${newCommunityName}_long_description')
                                                            .putString(
                                                              _longDescriptionController
                                                                  .text,
                                                              metadata:
                                                                  SettableMetadata(
                                                                contentType:
                                                                    'text/markdown',
                                                                customMetadata:
                                                                    null,
                                                              ),
                                                            )
                                                            .then((p1) => {
                                                                  p1.ref
                                                                      .getDownloadURL()
                                                                      .then(
                                                                          (desclink) =>
                                                                              {
                                                                                longdescurl = desclink,
                                                                                print("Desc url is $longdescurl"),
                                                                              })
                                                                      .then(
                                                                          (value) =>
                                                                              {
                                                                                ref
                                                                                    .child('${newCommunityName}_rules')
                                                                                    .putString(
                                                                                      _rulesController.text,
                                                                                      metadata: SettableMetadata(
                                                                                        contentType: 'text/markdown',
                                                                                        customMetadata: null,
                                                                                      ),
                                                                                    )
                                                                                    .then((p2) => {
                                                                                          p2.ref
                                                                                              .getDownloadURL()
                                                                                              .then((ruleslink) => {
                                                                                                    rulesurl = ruleslink,
                                                                                                    print("Rules url is $rulesurl"),
                                                                                                  })
                                                                                              .then((value) async => {
                                                                                                    await communitycollection.doc(newCommunityName).set({
                                                                                                      'status': 'published',
                                                                                                      'name': newCommunityName,
                                                                                                      'nameinlowercase': newCommunityName.toLowerCase(),
                                                                                                      'description': _briefDescriptionController.text,
                                                                                                      'backgroundimage': backgroundimgurl,
                                                                                                      'mainimage': mainimgurl,
                                                                                                      'longdescription': longdescurl,
                                                                                                      'rules': rulesurl,
                                                                                                      'time': DateTime.now(),
                                                                                                      'memberuids': memberuids,
                                                                                                      'moduids': moduids,
                                                                                                      'createdby': widget.onlineuser!.uid!,
                                                                                                      'blockedby': blockedby,
                                                                                                      'communityrules': '', //for old time's sake; no longer needed though
                                                                                                      'featuredpriority': 0,
                                                                                                      'whetherpopular': true, //for old time's sake; no longer needed though
                                                                                                      'prioritypoints': 0, //for old time's sake; no longer needed though
                                                                                                      'toppriority': 0,
                                                                                                    }).then((value) => {
                                                                                                          setState(() {
                                                                                                            hidenav = false;
                                                                                                          }),
                                                                                                          AppBuilder.of(context)!.rebuild(),
                                                                                                          Navigator.push(
                                                                                                            context,
                                                                                                            MaterialPageRoute(
                                                                                                              builder: ((context) => CommunityPage(
                                                                                                                    whetherjustcreated: true,
                                                                                                                    communityname: newCommunityName,
                                                                                                                  )),
                                                                                                              fullscreenDialog: true,
                                                                                                            ),
                                                                                                          )
                                                                                                        })
                                                                                                  })
                                                                                        })
                                                                              })
                                                                })
                                                      })
                                            });
                                  } else if (whetherbackimageselected == true &&
                                      whethermainimageselected == false) {
                                    ref
                                        .child('${newCommunityName}_background')
                                        .putFile(
                                          fileBackImage!,
                                          SettableMetadata(
                                            customMetadata: null,
                                          ),
                                        )
                                        .then((p0) => {
                                              p0.ref
                                                  .getDownloadURL()
                                                  .then((backurl) => {
                                                        backgroundimgurl =
                                                            backurl,
                                                        print(
                                                            "BackgroundImage url is $backgroundimgurl"),
                                                      })
                                                  .then((value) => {
                                                        ref
                                                            .child(
                                                                '${newCommunityName}_long_description')
                                                            .putString(
                                                              _longDescriptionController
                                                                  .text,
                                                              metadata:
                                                                  SettableMetadata(
                                                                contentType:
                                                                    'text/markdown',
                                                                customMetadata:
                                                                    null,
                                                              ),
                                                            )
                                                            .then((p1) => {
                                                                  p1.ref
                                                                      .getDownloadURL()
                                                                      .then(
                                                                          (desclink) =>
                                                                              {
                                                                                longdescurl = desclink,
                                                                                print("Desc url is $longdescurl"),
                                                                              })
                                                                      .then(
                                                                          (value) =>
                                                                              {
                                                                                ref
                                                                                    .child('${newCommunityName}_rules')
                                                                                    .putString(
                                                                                      _rulesController.text,
                                                                                      metadata: SettableMetadata(
                                                                                        contentType: 'text/markdown',
                                                                                        customMetadata: null,
                                                                                      ),
                                                                                    )
                                                                                    .then((p2) => {
                                                                                          p2.ref
                                                                                              .getDownloadURL()
                                                                                              .then((ruleslink) => {
                                                                                                    rulesurl = ruleslink,
                                                                                                    print("Rules url is $rulesurl"),
                                                                                                  })
                                                                                              .then((value) async => {
                                                                                                    await communitycollection.doc(newCommunityName).set({
                                                                                                      'status': 'published',
                                                                                                      'name': newCommunityName,
                                                                                                      'nameinlowercase': newCommunityName.toLowerCase(),
                                                                                                      'description': _briefDescriptionController.text,
                                                                                                      'backgroundimage': backgroundimgurl,
                                                                                                      'mainimage': mainimgurl,
                                                                                                      'longdescription': longdescurl,
                                                                                                      'rules': rulesurl,
                                                                                                      'time': DateTime.now(),
                                                                                                      'memberuids': memberuids,
                                                                                                      'moduids': moduids,
                                                                                                      'createdby': widget.onlineuser!.uid!,
                                                                                                      'blockedby': blockedby,
                                                                                                      'communityrules': '', //for old time's sake; no longer needed though
                                                                                                      'featuredpriority': 0,
                                                                                                      'whetherpopular': true, //for old time's sake; no longer needed though
                                                                                                      'prioritypoints': 0, //for old time's sake; no longer needed though
                                                                                                      'toppriority': 0,
                                                                                                    }).then((value) => {
                                                                                                          setState(() {
                                                                                                            hidenav = false;
                                                                                                          }),
                                                                                                          AppBuilder.of(context)!.rebuild(),
                                                                                                          Navigator.push(
                                                                                                            context,
                                                                                                            MaterialPageRoute(
                                                                                                              builder: ((context) => CommunityPage(
                                                                                                                    whetherjustcreated: true,
                                                                                                                    communityname: newCommunityName,
                                                                                                                  )),
                                                                                                              fullscreenDialog: true,
                                                                                                            ),
                                                                                                          )
                                                                                                        })
                                                                                                  })
                                                                                        })
                                                                              })
                                                                })
                                                      })
                                            });
                                  } else if (whetherbackimageselected ==
                                          false &&
                                      whethermainimageselected == false) {
                                    ref
                                        .child(
                                            '${newCommunityName}_long_description')
                                        .putString(
                                          _longDescriptionController.text,
                                          metadata: SettableMetadata(
                                            contentType: 'text/markdown',
                                            customMetadata: null,
                                          ),
                                        )
                                        .then((p0) => {
                                              p0.ref
                                                  .getDownloadURL()
                                                  .then((desclink) => {
                                                        longdescurl = desclink,
                                                        print(
                                                            "Description url is $longdescurl"),
                                                      })
                                                  .then((value) => {
                                                        ref
                                                            .child(
                                                                '${newCommunityName}_rules')
                                                            .putString(
                                                              _rulesController
                                                                  .text,
                                                              metadata:
                                                                  SettableMetadata(
                                                                contentType:
                                                                    'text/markdown',
                                                                customMetadata:
                                                                    null,
                                                              ),
                                                            )
                                                            .then((p1) => {
                                                                  p1.ref
                                                                      .getDownloadURL()
                                                                      .then(
                                                                          (ruleslink) =>
                                                                              {
                                                                                rulesurl = ruleslink,
                                                                                print("Rules url is $rulesurl"),
                                                                              })
                                                                      .then(
                                                                          (value) async =>
                                                                              {
                                                                                await communitycollection.doc(newCommunityName).set({
                                                                                  'status': 'published',
                                                                                  'name': newCommunityName,
                                                                                  'nameinlowercase': newCommunityName.toLowerCase(),
                                                                                  'description': _briefDescriptionController.text,
                                                                                  'backgroundimage': backgroundimgurl,
                                                                                  'mainimage': mainimgurl,
                                                                                  'longdescription': longdescurl,
                                                                                  'rules': rulesurl,
                                                                                  'time': DateTime.now(),
                                                                                  'memberuids': memberuids,
                                                                                  'moduids': moduids,
                                                                                  'createdby': widget.onlineuser!.uid!,
                                                                                  'blockedby': blockedby,
                                                                                  'communityrules': '', //for old time's sake; no longer needed though
                                                                                  'featuredpriority': 0,
                                                                                  'whetherpopular': true, //for old time's sake; no longer needed though
                                                                                  'prioritypoints': 0, //for old time's sake; no longer needed though
                                                                                  'toppriority': 0,
                                                                                }).then((value) => {
                                                                                      setState(() {
                                                                                        hidenav = false;
                                                                                      }),
                                                                                      AppBuilder.of(context)!.rebuild(),
                                                                                      Navigator.push(
                                                                                        context,
                                                                                        MaterialPageRoute(
                                                                                          builder: ((context) => CommunityPage(
                                                                                                whetherjustcreated: true,
                                                                                                communityname: newCommunityName,
                                                                                              )),
                                                                                          fullscreenDialog: true,
                                                                                        ),
                                                                                      )
                                                                                    })
                                                                              })
                                                                })
                                                      })
                                            });
                                  }
                                }
                              }
                            },
                            child: Text(
                              "Publish",
                              style:
                                  Theme.of(context).textTheme.button!.copyWith(
                                        color: kPrimaryColorTint2,
                                        fontWeight: FontWeight.bold,
                                      ),
                            ),
                          ),
                        )
                      ]
                    : null,
              ),
              body: (dataisthere == true)
                  ? NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (overScroll) {
                        overScroll.disallowIndicator();
                        return true;
                      },
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Form(
                          key: _createCommunityKey,
                          child: SafeArea(
                            child: Scrollbar(
                              //isAlwaysShown: true,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    (whetherbackimageselected == false)
                                        ? (showbackgroundimagepreview == false)
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: InkWell(
                                                  onTap: () {
                                                    pickBackImagefromGallery();
                                                  },
                                                  child: Container(
                                                    height: 200,
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      border: Border.all(
                                                          color: Colors
                                                              .grey.shade500),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        "Add the background image",
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .subtitle1!
                                                            .copyWith(
                                                              color: Colors.grey
                                                                  .shade500,
                                                            ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : Padding(
                                                padding:
                                                    const EdgeInsets.all(10.0),
                                                child: Stack(
                                                  children: [
                                                    Container(
                                                      height: 200,
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors
                                                                .grey.shade500),
                                                      ),
                                                      child: Center(
                                                        child: Image.network(
                                                            backgroundimgurl),
                                                      ),
                                                    ),
                                                    Positioned(
                                                      right: 0.0,
                                                      top: 0.0,
                                                      child: InkWell(
                                                        onTap: () {
                                                          setState(() {
                                                            whetherbackimageselected =
                                                                false;
                                                            showbackgroundimagepreview =
                                                                false;
                                                            backgroundimgurl =
                                                                'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/assets%2Fimages%2Fdark_background_image_1280_720_px?alt=media&token=2fe7fbf8-1399-48b9-9ecf-f43bd3fb93e7';
                                                          });
                                                        },
                                                        child: const Icon(
                                                          Icons.close,
                                                          color:
                                                              Colors.redAccent,
                                                          size: 30.0,
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              )
                                        : Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Stack(
                                              children: [
                                                Container(
                                                  height: 200,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade500),
                                                  ),
                                                  child: Center(
                                                    child: Image.file(
                                                        fileBackImage!),
                                                  ),
                                                ),
                                                Positioned(
                                                  right: 0.0,
                                                  top: 0.0,
                                                  child: InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        whetherbackimageselected =
                                                            false;
                                                      });
                                                    },
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.redAccent,
                                                      size: 30.0,
                                                    ),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                    Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Row(
                                        children: [
                                          (whethermainimageselected == false)
                                              ? (showmainimagepreview == false)
                                                  ? InkWell(
                                                      onTap: () {
                                                        pickMainImagefromGallery();
                                                      },
                                                      child: Container(
                                                        height: 60,
                                                        width: 60,
                                                        decoration:
                                                            BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          border: Border.all(
                                                            color: Colors
                                                                .grey.shade500,
                                                          ),
                                                        ),
                                                        child: Icon(
                                                          Icons
                                                              .photo_camera_outlined,
                                                          color: Colors
                                                              .grey.shade500,
                                                        ),
                                                      ),
                                                    )
                                                  : Container(
                                                      height: 60,
                                                      width: 60,
                                                      child: Stack(
                                                        children: [
                                                          Positioned.fill(
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                image:
                                                                    DecorationImage(
                                                                  image: NetworkImage(
                                                                      mainimgurl),
                                                                  fit: BoxFit
                                                                      .cover,
                                                                ),
                                                                shape: BoxShape
                                                                    .circle,
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            right: 0.0,
                                                            top: 5.0,
                                                            child: InkWell(
                                                              onTap: () {
                                                                setState(() {
                                                                  whethermainimageselected =
                                                                      false;
                                                                  showmainimagepreview =
                                                                      false;
                                                                  mainimgurl =
                                                                      'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/assets%2Fimages%2Fdark_background_image_500px?alt=media&token=dcf5c782-a5e9-419a-a2ee-d4acb1356a4e';
                                                                });
                                                              },
                                                              child: const Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .redAccent,
                                                                size: 30.0,
                                                              ),
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    )
                                              : Container(
                                                  height: 60,
                                                  width: 60,
                                                  child: Stack(
                                                    children: [
                                                      Positioned.fill(
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            image:
                                                                DecorationImage(
                                                              image: FileImage(
                                                                  fileMainImage!),
                                                              fit: BoxFit.cover,
                                                            ),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        right: 0.0,
                                                        top: 5.0,
                                                        child: InkWell(
                                                          onTap: () {
                                                            setState(() {
                                                              whethermainimageselected =
                                                                  false;
                                                            });
                                                          },
                                                          child: const Icon(
                                                            Icons.close,
                                                            color: Colors
                                                                .redAccent,
                                                            size: 30.0,
                                                          ),
                                                        ),
                                                      )
                                                    ],
                                                  ),
                                                ),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Flexible(
                                            child: Container(
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  bottom: BorderSide(
                                                    width: 2.0,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ),
                                              child: TextFormField(
                                                onTap: () => (widget
                                                            .whetherediting ==
                                                        true)
                                                    ? ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Community names can't be changed.",
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                              fontSize: 15.0,
                                                              //fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      )
                                                    : null,
                                                readOnly:
                                                    (widget.whetherediting ==
                                                            false)
                                                        ? false
                                                        : true,
                                                validator: (text) {
                                                  if (text == null ||
                                                      text.isEmpty) {
                                                    return "Community name cannot be empty";
                                                  } else if (text.length < 3) {
                                                    return "Name cannot be less than 3 chars";
                                                  } else if (text.length > 20) {
                                                    return "Name cannot be more than 20 chars";
                                                  } else if (!communityNameRegex
                                                      .hasMatch(text)) {
                                                    return "Invalid community name";
                                                  }
                                                  return null;
                                                },
                                                autovalidateMode:
                                                    AutovalidateMode
                                                        .onUserInteraction,
                                                controller: _nameController,
                                                maxLength: 20,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodyText1!
                                                    .copyWith(
                                                        color: Colors.white),
                                                decoration:
                                                    const InputDecoration
                                                        .collapsed(
                                                  hintText: 'Community name...',
                                                ),
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.only(
                                          left: 5.0, right: 5.0),
                                      child: Text(
                                          "Note: Community Names can be within 3-20 characters long and contain only letters and no special characters.",
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                              fontStyle: FontStyle.italic)),
                                    ),
                                    const Divider(
                                      thickness: 2,
                                      color: kBackgroundColorDark2,
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
                                                if (text == null ||
                                                    text.isEmpty) {
                                                  return "Brief description cannot be empty";
                                                } else if (text.length < 10) {
                                                  return "Brief description can't be less than 10 chars";
                                                } else if (text.length > 70) {
                                                  return "Brief description can't be more than 70 chars";
                                                }
                                                return null;
                                              },
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                              controller:
                                                  _briefDescriptionController,
                                              maxLength: 70,
                                              readOnly: true,
                                              maxLines: 2,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1!
                                                  .copyWith(
                                                      color: Colors.white),
                                              decoration: const InputDecoration
                                                  .collapsed(
                                                hintText:
                                                    'Add brief description...',
                                              ),
                                              onTap: () {
                                                showTextSheet(
                                                    "Brief Description",
                                                    10,
                                                    70,
                                                    false,
                                                    _briefDescriptionController,
                                                    false);
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
                                          const Icon(Icons.description),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Flexible(
                                            child: TextFormField(
                                              validator: (text) {
                                                if (text == null ||
                                                    text.isEmpty) {
                                                  return "Description cannot be empty";
                                                } else if (text.length < 10) {
                                                  return "Description can't be less than 10 chars";
                                                } else if (text.length > 1250) {
                                                  return "Description can't be more than 1250 chars";
                                                }
                                                return null;
                                              },
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                              controller:
                                                  _longDescriptionController,
                                              readOnly: true,
                                              maxLines: 2,
                                              maxLength: 1250,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1!
                                                  .copyWith(
                                                      color: Colors.white),
                                              decoration: const InputDecoration
                                                  .collapsed(
                                                hintText:
                                                    'Add complete description...',
                                              ),
                                              onTap: () {
                                                showTextSheet(
                                                    "Long Description",
                                                    10,
                                                    1250,
                                                    true,
                                                    _longDescriptionController,
                                                    true);
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
                                          const Icon(Icons.rule),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          Flexible(
                                            child: TextFormField(
                                              validator: (text) {
                                                if (text == null ||
                                                    text.isEmpty) {
                                                  return "Rules cannot be empty";
                                                } else if (text.length < 10) {
                                                  return "Rules can't be less than 10 chars";
                                                } else if (text.length > 1250) {
                                                  return "Rules can't be more than 1250 chars";
                                                }
                                                return null;
                                              },
                                              autovalidateMode: AutovalidateMode
                                                  .onUserInteraction,
                                              controller: _rulesController,
                                              readOnly: true,
                                              maxLines: 2,
                                              maxLength: 1250,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyText1!
                                                  .copyWith(
                                                      color: Colors.white),
                                              decoration: const InputDecoration
                                                  .collapsed(
                                                hintText:
                                                    'Add community rules...',
                                              ),
                                              onTap: () {
                                                showTextSheet(
                                                    "Rules",
                                                    10,
                                                    1250,
                                                    true,
                                                    _rulesController,
                                                    true);
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
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  : const Center(
                      child: CupertinoActivityIndicator(
                        color: kDarkPrimaryColor,
                      ),
                    ),
            ),
          )
        : WillPopScope(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const CupertinoActivityIndicator(
                  color: kDarkPrimaryColor,
                ),
                const SizedBox(
                  height: 10.0,
                ),
                (widget.whetherediting == false)
                    ? const Text("Creating community...")
                    : const Text("Updating community..."),
              ],
            ),
            onWillPop: () async => false,
          );
  }
}
