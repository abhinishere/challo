import 'package:challo/pages/rank_page.dart';
import 'package:challo/variables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class EditProfile extends StatefulWidget {
  final String? uid;
  const EditProfile({
    required this.uid,
  });
  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _editProfileKey = GlobalKey<FormState>();
  bool usernamechecking = false;

  TextEditingController fullnamecontroller = TextEditingController();
  TextEditingController usernamecontroller = TextEditingController();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController biocontroller = TextEditingController();
  String errorMessage = "";
  String imageUrl =
      "https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/profilepics%2Fdefault-profile-pic.jpg?alt=media&token=cb615f5f-0f4d-41ea-b267-60912482d645";
  bool whetherchanged = false;
  //bool whetherpicselected = false;
  String? username, name, email, profilepic, bio;
  bool dataisthere = false;
  final usernameregex = RegExp(r'^(?!.*__)(?!.*_$)[A-Za-z]\w*$');

  //variables for profile picture
  XFile? xFileImage;
  File? fileImage;
  bool whetherimagechanged = false;
  bool imageremoved = false;
  bool showloading = false;
  String aigeneratedimage = "";

  @override
  void initState() {
    super.initState();
    getalldata();
  }

  getalldata() async {
    //get user's date for editing
    var userdoc = await usercollection.doc(widget.uid).get();

    username = userdoc['username'];

    name = userdoc['name'];

    email = userdoc['email'];

    profilepic = userdoc['profilepic'];

    bio = userdoc['bio'];

    fullnamecontroller.text = name!;

    usernamecontroller.text = username!;

    emailcontroller.text = email!;

    biocontroller.text = bio!;

    setState(() {
      dataisthere = true;
    });
  }

  Future<bool> _usernameexists(String username) async {
    final String usernameinlowercase = username.toLowerCase();
    final result = await usercollection
        .where('username', isEqualTo: usernameinlowercase)
        .get();

    return result.docs.isEmpty;
  }

  Widget bottomSheet() {
    return Container(
      height: (MediaQuery.of(context).size.height) / 5,
      width: (MediaQuery.of(context).size.width),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(children: [
        const Text("Change Profile Picture",
            style: TextStyle(fontSize: 20, color: Colors.white)),
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
                      removepicture();
                      //whetherpicselected = true;
                      setState(() {
                        errorMessage =
                            "Note: Wait for the new picture to appear above and then click Save to confirm.";
                      });
                      //whetherchanged = true;
                    },
                    //icon: Icon(Icons.cancel_outlined, color: kPrimaryColor),
                    child: const Text("Remove",
                        style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold))),
              ),
              Container(
                color: Colors.grey.shade500,
                width: 0.5,
                height: 22,
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      takephotofromgallery();
                    },
                    //icon: Icon(Icons.image_outlined, color: kPrimaryColor),
                    child: const Text("Pick from gallery",
                        style: TextStyle(
                            color: kPrimaryColor,
                            fontWeight: FontWeight.bold))),
              )
            ],
          ),
        )
      ]),
    );
  }

  removepicture() async {
    setState(() {
      aigeneratedimage = "";
      imageremoved = true;
      whetherimagechanged = true;
    });
  }

  takephotofromgallery() async {
    //final _storage = FirebaseStorage.instance;
    final ImagePicker picker = ImagePicker();

    //changed for dart upgrade
    //PickedFile image;

    await Permission.photos.request();

    var galleryPermissionStatus = await Permission.photos.status;

    if (galleryPermissionStatus.isGranted) {
      //image = await _picker.getImage(source: ImageSource.gallery);
      xFileImage =
          await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
      fileImage = File(xFileImage!.path);
      setState(() {
        aigeneratedimage = "";
        imageremoved = false;
        whetherimagechanged = true;
      });

      //upload to firebase
      /*var snapshot =
          await _storage.ref().child('profilepics/$username').putFile(file);

      snapshot.ref.getDownloadURL().then((value) => setState(() {
            imageUrl = value;
          }));

      setState(() {
        //whetherpicselected = true;
        setState(() {
          errorMessage =
              "Note: Wait for the new picture to appear above and then click Save to confirm.";
        });
        //whetherchanged = true;
      });*/
    } else {
      //enable permissions message
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

  updateProfile() async {
    whetherchanged = true;
    setState(() {
      showloading = true;
    });
    try {
      await usercollection.doc(widget.uid).update({
        'name':
            (fullnamecontroller.text.isEmpty) ? '' : fullnamecontroller.text,
        'username': usernamecontroller.text,
        'bio': biocontroller.text,
      });

      if (whetherimagechanged == true) {
        if (aigeneratedimage != "") {
          await usercollection.doc(widget.uid).update(
            {
              'profilepic': aigeneratedimage,
            },
          ).then(
            (_) => Navigator.pop(context, whetherchanged),
          );
        } else if (imageremoved == true) {
          imageUrl =
              "https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/profilepics%2Fdefault-profile-pic.jpg?alt=media&token=cb615f5f-0f4d-41ea-b267-60912482d645";
          await usercollection.doc(widget.uid).update(
            {'profilepic': imageUrl},
          ).then(
            (_) => Navigator.pop(context, whetherchanged),
          );
        } else {
          //upload to storage and get url
          Reference ref = FirebaseStorage.instance
              .ref()
              .child('profilepics')
              .child(username!);
          ref
              .putFile(
                fileImage!,
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
                              await usercollection
                                  .doc(widget.uid)
                                  .update({'profilepic': imageUrl}),
                            })
                        .then(
                          (_) => Navigator.pop(context, whetherchanged),
                        )
                  });
        }
      } else {
        if (!mounted) return;
        Navigator.pop(context, whetherchanged);
      }

      /* if (imageUrl != null) {
        print("image url is $imageUrl");
        await usercollection.doc(widget.uid).update({'profilepic': imageUrl});
      }*/

    } on FirebaseAuthException catch (e) {
      errorMessage = e.message.toString();
      print(e);
    }
  }

  validatorCheck(String? text) async {
    setState(() {
      usernamechecking = true;
    });
    if (text != null) {
      final validexists = await _usernameexists(text);
      if (!validexists) {
        setState(() {
          errorMessage = "This username is already taken.";
        });
      } else if (!usernameregex.hasMatch(text)) {
        setState(() {
          errorMessage = "Invalid username: Follow the rules below.";
        });
      } else {
        setState(() {
          errorMessage = "";
        });
      }
    }
    setState(() {
      usernamechecking = false;
    });
  }

  showPictureOptions() {
    showCupertinoModalPopup(
        context: context,
        builder: (BuildContext context) => CupertinoActionSheet(
              title: Text("Edit Profile Picture",
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
                    takephotofromgallery();
                  },
                  child: Text(
                    'Upload a Picture',
                    style: Theme.of(context).textTheme.button!.copyWith(
                          fontSize: 20.0,
                          color: kPrimaryColorTint2,
                          fontStyle: FontStyle.normal,
                        ),
                  ),
                ),
                CupertinoActionSheetAction(
                  //isDefaultAction: true,
                  onPressed: () async {
                    Navigator.pop(context);
                    setState(() {
                      showloading = true;
                    });
                    final String aiImageAPIBaseUrl =
                        roboAvatarAPIURL; // base URL of API for sweet AI bot images
                    final uploadresponse = await http.get(Uri.parse(
                        '$aiImageAPIBaseUrl/{username}?username=$username'));
                    if (uploadresponse.statusCode == 200) {
                      print("success uploading");
                      setState(() {
                        whetherimagechanged = true;
                        aigeneratedimage =
                            "$roboImagesBucketBaseUrl/$username.png"; // link of newly generated AI image
                      });
                    } else {
                      print("error uploading");
                      setState(() {
                        whetherimagechanged = false;
                        aigeneratedimage = "";
                      });
                    }
                    setState(() {
                      showloading = false;
                    });
                  },
                  child: Text(
                    'Generate AI Avatar',
                    style: Theme.of(context).textTheme.button!.copyWith(
                          fontSize: 20.0,
                          color: kPrimaryColorTint2,
                          fontStyle: FontStyle.normal,
                        ),
                  ),
                ),
                CupertinoActionSheetAction(
                  isDestructiveAction: true,
                  onPressed: () {
                    Navigator.pop(context);
                    removepicture();
                  },
                  child: Text(
                    'Remove Current Picture',
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
            ));
  }

  @override
  Widget build(BuildContext context) {
    return (dataisthere == false || showloading == true)
        ? Scaffold(
            appBar: AppBar(
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back),
              ),
              title: const Text(
                "Edit Profile",
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
              elevation: 1,
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
            appBar: AppBar(
              title: const Text(
                "Edit Profile",
                style: TextStyle(color: Colors.white),
              ),
              centerTitle: true,
              //iconTheme: IconThemeData(color: Colors.white),
              elevation: 1,
              leading: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: const Icon(
                  Icons.arrow_back,
                ),
                /* child: Center(
              child: Image.asset('assets/icons/arrow_back_circle_ios.png',
                  width: 30.0, height: 30.0),
            ),*/
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextButton(
                      onPressed: () async {
                        if (_editProfileKey.currentState!.validate()) {
                          if (usernamecontroller.text == username) {
                            updateProfile();

                            //whetherchanged = true;

                            /*if (errorMessage != null) {
                              setState(() {
                                print(errorMessage);
                              });
                            }*/
                          } else {
                            final validexists =
                                await _usernameexists(usernamecontroller.text);
                            if (!validexists) {
                              setState(() {
                                errorMessage =
                                    "The username is already taken. :(";
                                print(errorMessage);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("Error: $errorMessage")));
                              });
                            } else if (!usernameregex
                                .hasMatch(usernamecontroller.text)) {
                              setState(() {
                                errorMessage =
                                    "Invalid username: Please follow the rules when setting a new username.";
                                print(errorMessage);
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("Error: $errorMessage")));
                              });
                            } else {
                              updateProfile();

                              if (errorMessage != "" ||
                                  errorMessage.isNotEmpty) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text("Error: $errorMessage")));
                              }
                            }
                          }
                        }
                      },
                      child: Text(
                        "Update",
                        style: Theme.of(context).textTheme.button!.copyWith(
                              color: kPrimaryColorTint2,
                              fontWeight: FontWeight.w700,
                            ),
                      )),
                )
              ],
            ),
            body: Form(
              key: _editProfileKey,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.only(left: 16, top: 25, right: 16),
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    width: 4,
                                    color: Theme.of(context)
                                        .scaffoldBackgroundColor),
                                boxShadow: [
                                  BoxShadow(
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      color: Colors.black.withOpacity(0.1),
                                      offset: const Offset(0, 10))
                                ],
                                shape: BoxShape.circle,
                                image: DecorationImage(
                                    fit: BoxFit.cover,
                                    image: (whetherimagechanged == false)
                                        ? NetworkImage(profilepic!)
                                        : (aigeneratedimage != "")
                                            ? NetworkImage(aigeneratedimage)
                                            : (imageremoved == false)
                                                ? FileImage(fileImage!)
                                                : const AssetImage(
                                                        "assets/images/default-profile-pic.png")
                                                    as ImageProvider),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: InkWell(
                                onTap: () => showPictureOptions(),
                                child: Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      width: 4,
                                      color: Theme.of(context)
                                          .scaffoldBackgroundColor,
                                    ),
                                    color: kPrimaryColor,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Text(
                              "USERNAME",
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium!
                                  .copyWith(
                                    color: kHeadlineColorDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                  ),
                            ),
                            const SizedBox(
                              width: 10.0,
                            ),
                            (usernamechecking == false)
                                ? Container()
                                : const CupertinoActivityIndicator(
                                    radius: 7.0,
                                    color: kPrimaryColor,
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      TextFormField(
                        cursorColor: kHeadlineColorDark,
                        maxLength: 15,
                        validator: (text) {
                          if (text == null || text.isEmpty) {
                            return 'Username cannot be empty';
                          }
                          if (text.length < 3) {
                            return 'Username must be at least 3 characters';
                          }
                          if (text.length > 15) {
                            return 'Username must be less than 15 characters';
                          }
                          if (errorMessage.isNotEmpty && errorMessage != "") {
                            return errorMessage;
                          }
                          return null;
                        },
                        //onEditingComplete: () => validatorCheck(),
                        onChanged: (text) {
                          if (text != username) {
                            validatorCheck(text);
                          }
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: usernamecontroller,
                        style:
                            Theme.of(context).textTheme.displayMedium!.copyWith(
                                  fontSize: 16,
                                  color: kHeadlineColorDark,
                                  fontWeight: FontWeight.bold,
                                ),
                        decoration: InputDecoration(
                          hintText: 'Username',
                          hintStyle:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontSize: 15,
                                    color: kIconSecondaryColorDark,
                                    //fontWeight: FontWeight.bold,
                                  ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          fillColor: kBackgroundColorDark2,
                          filled: true,
                        ),
                      ),
                      Text(
                        "Usernames are 3-15 characters long and contain only lowercase letters (a-z), numbers (0-9), and underscores (_). Consecutive or trailing underscores are not allowed.",
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                              color: kIconSecondaryColorDark,
                              fontSize: 14.0,
                            ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "NAME (OPTIONAL)",
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: kHeadlineColorDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                  ),
                        ),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      TextFormField(
                        maxLength: 40,
                        cursorColor: kHeadlineColorDark,
                        validator: (text) {
                          if (text!.length > 40) {
                            return 'Name cannot be more than 40 characters.';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: fullnamecontroller,
                        style:
                            Theme.of(context).textTheme.displayMedium!.copyWith(
                                  fontSize: 16,
                                  color: kHeadlineColorDark,
                                  fontWeight: FontWeight.bold,
                                ),
                        decoration: InputDecoration(
                          hintText: 'Name',
                          hintStyle:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontSize: 15,
                                    color: kIconSecondaryColorDark,
                                    //fontWeight: FontWeight.bold,
                                  ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          fillColor: kBackgroundColorDark2,
                          filled: true,
                        ),
                      ),
                      const SizedBox(
                        height: 10.0,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "BIO",
                          style:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    color: kHeadlineColorDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15.0,
                                  ),
                        ),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      TextFormField(
                        maxLength: 50,
                        cursorColor: kHeadlineColorDark,
                        validator: (text) {
                          if (text!.length > 50) {
                            return 'Bio cannot be more than 50 characters.';
                          }
                          return null;
                        },
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: biocontroller,
                        style:
                            Theme.of(context).textTheme.displayMedium!.copyWith(
                                  fontSize: 16,
                                  color: kHeadlineColorDark,
                                  fontWeight: FontWeight.bold,
                                ),
                        decoration: InputDecoration(
                          hintText: 'Bio',
                          hintStyle:
                              Theme.of(context).textTheme.labelMedium!.copyWith(
                                    fontSize: 15,
                                    color: kIconSecondaryColorDark,
                                    //fontWeight: FontWeight.bold,
                                  ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          fillColor: kBackgroundColorDark2,
                          filled: true,
                        ),
                      ),
                      TextButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const RankPage()));
                          },
                          child: const Text("RankPage"))
                    ],
                  ),
                ),
              ),
            ),
          );
  }
}
