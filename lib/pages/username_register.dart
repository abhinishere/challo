import 'dart:io';

import 'package:challo/pages/navigation.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/button_simple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UsernameRegister extends StatefulWidget {
  final String username;
  final String uid;
  const UsernameRegister({
    required this.username,
    required this.uid,
  });

  @override
  State<UsernameRegister> createState() => _UsernameRegisterState();
}

class _UsernameRegisterState extends State<UsernameRegister> {
  /* @override
  void initState() {
    super.initState();
  }

  getusernamedata() async {
    setState(() {
      dataisthere = true;
    });
  }*/

  final _usernameregisterKey = GlobalKey<FormState>();
  TextEditingController usernamecontroller = TextEditingController();
  TextEditingController namecontroller = TextEditingController();
  String? errorMessage;

  bool dataisthere = false;
  bool usernamechecking = false;
  final usernameregex = RegExp(r'^(?!.*__)(?!.*_$)[A-Za-z]\w*$');
  bool internetOK = false;

  //RegExp(r'^(?=.{3,20}$)(?![_.])(?!.*[_.]{2})[a-z0-9._]+(?<![_.])$');

  Future<bool> _usernameexists(String username) async {
    final String usernameinlowercase = username.toLowerCase();
    final result = await usercollection
        .where('username', isEqualTo: usernameinlowercase)
        .get();

    return result.docs.isEmpty;
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

  updateUsername() async {
    final validexists = await _usernameexists(usernamecontroller.text);
    if (!validexists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "This username is already taken.",
            style: Theme.of(context).textTheme.displaySmall!.copyWith(
                  color: kWarningColorDark,
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
    } else {
      //update
      await usercollection.doc(widget.uid).update({
        'username': usernamecontroller.text,
      }).then((value) => {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => NavigationPage(),
              ),
              (Route<dynamic> route) => false,
            )
          });
    }
  }

  Future checkInternet() async {
    try {
      final result = await InternetAddress.lookup('duckduckgo.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('connected');
        internetOK = true;
      }
    } on SocketException catch (_) {
      print('not connected');
      internetOK = false;
    }
  }

  void _showNoInternet() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text("Connection Failed"),
        content: const Text(
            "Unable to connect to Internet. Please check your connection and try again."),
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

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: kBackgroundColorDark,
      ),
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: AppBar(
            backgroundColor: kBackgroundColorDark,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: kBackgroundColorDark,
              statusBarBrightness: Brightness.dark,
            ),
          ),
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: NotificationListener<OverscrollIndicatorNotification>(
            onNotification: (overScroll) {
              overScroll.disallowIndicator();
              return true;
            },
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _usernameregisterKey,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 20,
                        ),
                        SizedBox(
                          height: 90,
                          child: Image.asset(
                            "assets/icons/welcome_screen_logo_transparent.png",
                            //color: kPrimaryColor,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "Set username",
                          style:
                              Theme.of(context).textTheme.titleLarge!.copyWith(
                                    color: const Color(0xFFfffffe),
                                    fontSize: 27,
                                    fontWeight: FontWeight.w700,
                                    //wordSpacing: 0.5,
                                  ),
                        ),
                        const SizedBox(
                          height: 5.0,
                        ),
                        Text(
                          "Your username is how others find you on Challo, and so maybe go for something catchy.",
                          style: Theme.of(context).textTheme.caption!.copyWith(
                                color: const Color(0xFF94a1b2),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 20,
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
                            if (errorMessage != null && errorMessage != "") {
                              return errorMessage;
                            }
                            return null;
                          },
                          //onEditingComplete: () => validatorCheck(),
                          onChanged: (text) => validatorCheck(text),
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: usernamecontroller,
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium!
                              .copyWith(
                                fontSize: 16,
                                color: kHeadlineColorDark,
                                fontWeight: FontWeight.bold,
                              ),
                          decoration: InputDecoration(
                            hintText: 'Username',
                            hintStyle: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
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
                        Text(
                          "Usernames are 3-15 characters long and contain only lowercase letters (a-z), numbers (0-9), and underscores (_). Consecutive or trailing underscores are not allowed.",
                          style:
                              Theme.of(context).textTheme.subtitle1!.copyWith(
                                    color: kIconSecondaryColorDark,
                                    fontSize: 14.0,
                                  ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 20,
                        ),
                        ButtonSimple(
                          color: kPrimaryColor,
                          textColor: kHeadlineColorDark,
                          text: "Continue",
                          onPress: () {
                            checkInternet().then((_) => {
                                  if (internetOK == true)
                                    {
                                      if (_usernameregisterKey.currentState!
                                          .validate())
                                        {
                                          updateUsername(),
                                        }
                                    }
                                  else
                                    {
                                      _showNoInternet(),
                                    }
                                });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
