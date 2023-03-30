import 'dart:io';

import 'package:challo/pages/username_register.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/button_simple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class SignUp extends StatefulWidget {
  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final _signupKey = GlobalKey<FormState>();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  bool _obscureText = true;
  String? errorMessage;
  bool internetOK = false;

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateRandomUsername(String dateString) {
    String newUsername = "user$dateString${getRandomString(4)}";
    return newUsername;
  }

  /*Widget showAlert(String? errorMessage) {
    if (errorMessage != null) {
      return Container(
        color: kPrimaryColor,
        width: double.infinity,
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.error_outline),
            ),
            Expanded(
                child: AutoSizeText(
              errorMessage,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
            )),
          ],
        ),
      );
    } else {
      return const SizedBox(height: 0.0);
    }
  }*/

  registeruser() async {
    List<String> blockedusers = [];
    List<String> blockedcommunities = [];

    List<String> hiddenusers = [];
    DateFormat dateFormat = DateFormat("yyMMdd");
    String dateString = dateFormat.format(DateTime.now());
    String newUsername = generateRandomUsername(dateString);
    String trimmedEmail = emailcontroller.text.trim();
    String? uid;
    try {
      final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
      await _firebaseAuth
          .createUserWithEmailAndPassword(
              email: trimmedEmail, password: passwordcontroller.text)
          .then((signeduser) {
        uid = signeduser.user!.uid;
        usercollection.doc(signeduser.user!.uid).set({
          'username': newUsername,
          'email': trimmedEmail,
          'name': '',
          'uid': signeduser.user!.uid,
          'profilepic':
              'https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/profilepics%2Fdefault-profile-pic.jpg?alt=media&token=cb615f5f-0f4d-41ea-b267-60912482d645',
          'accountStatus': 'active',
          'pendingvideo': false,
          'bio': '',
          'isLive': false,
          'emailverified': false,
          'profileverified': false,
          'docName': '',
          'blockedusers': blockedusers,
          'blockedcommunities': blockedcommunities,
          'hiddenusers': hiddenusers,
          'closedugc': false,
          'popularpriority': 0,
          'inAppReviewDisplayed': true,
        });
      }).then(
        (value) => {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => UsernameRegister(
                uid: uid!,
                username: newUsername,
              ),
            ),
            (Route<dynamic> route) => false,
          )
        },
      );
      /*Navigator.popUntil(
          context, ModalRoute.withName(Navigator.defaultRouteName));*/
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message.toString();
        //print(errorMessage);
        //return (errorMessage);
      });
    }
  }

  clearControllers() {
    emailcontroller.clear();
    passwordcontroller.clear();
  }

  bool _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
    return _obscureText;
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
                key: _signupKey,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              top: 16.0,
                              bottom: 0.6,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Icon(
                                Icons.arrow_back,
                                color: kIconSecondaryColorDark,
                              ),
                            ),
                          ),
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
                          "Create account",
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
                          "Thanks for giving us a shot.",
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
                          child: Text(
                            "EMAIL",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
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
                          cursorColor: kHeadlineColorDark,
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Email cannot be empty';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: emailcontroller,
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium!
                              .copyWith(
                                fontSize: 16,
                                color: kHeadlineColorDark,
                                fontWeight: FontWeight.bold,
                              ),
                          decoration: InputDecoration(
                            hintText: 'Email',
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
                          height: 20.0,
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "PASSWORD",
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
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
                          cursorColor: kHeadlineColorDark,
                          obscureText: _obscureText,
                          validator: (text) {
                            if (text == null || text.isEmpty) {
                              return 'Password cannot be empty';
                            }
                            if (text.length < 6) {
                              return 'Password must be at least 6 characters long';
                            }
                            if (text.length > 128) {
                              return 'Password must be less than 128 characters long';
                            }
                            return null;
                          },
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          controller: passwordcontroller,
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium!
                              .copyWith(
                                fontSize: 16,
                                color: kHeadlineColorDark,
                                fontWeight: FontWeight.bold,
                              ),
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              icon: (_obscureText == true)
                                  ? const Icon(
                                      Icons.visibility_off_outlined,
                                      color: kIconSecondaryColorDark,
                                    )
                                  : const Icon(
                                      Icons.visibility_outlined,
                                      color: kIconSecondaryColorDark,
                                    ),
                              onPressed: () {
                                _obscureText = _toggle();
                              },
                            ),
                            hintText: 'Password',
                            hintStyle: Theme.of(context)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  fontSize: 15,
                                  color: kIconSecondaryColorDark,
                                  //fontWeight: FontWeight.bold,
                                ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5.0),
                              borderSide: BorderSide.none,
                            ),
                            fillColor: kBackgroundColorDark2,
                            filled: true,
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 20,
                        ),
                        Text.rich(
                          TextSpan(
                              text: "By signing up, you agree to our ",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12.0,
                              ),
                              children: <TextSpan>[
                                TextSpan(
                                    text: "Terms & Conditions",
                                    style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: Colors.blueGrey,
                                      fontSize: 12.0,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (context) {
                                            return AlertDialog(
                                              contentPadding:
                                                  const EdgeInsets.only(
                                                      left: 10, right: 10),
                                              title: Column(children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    //print("closing...");
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Align(
                                                    alignment:
                                                        Alignment.topRight,
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 25.0,
                                                      color: kPrimaryColorTint2,
                                                    ),
                                                  ),
                                                ),
                                                const Center(
                                                  child: Text(
                                                    "Terms & Conditions",
                                                    style: TextStyle(
                                                        fontSize: 15.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white),
                                                  ),
                                                ),
                                              ]),
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(20.0),
                                                ),
                                              ),
                                              content: Container(
                                                height: (MediaQuery.of(context)
                                                        .size
                                                        .height) /
                                                    1.2,
                                                width: (MediaQuery.of(context)
                                                        .size
                                                        .width) /
                                                    1.2,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      child: Expanded(
                                                        child:
                                                            SingleChildScrollView(
                                                                child: Text(
                                                          termsconditions,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12.0,
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                        )),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }),
                                TextSpan(
                                  text: ", ",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12.0,
                                  ),
                                ),
                                TextSpan(
                                    text: "Privacy Policy",
                                    style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: Colors.blueGrey,
                                      fontSize: 12.0,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (context) {
                                            return AlertDialog(
                                              contentPadding:
                                                  const EdgeInsets.only(
                                                      left: 10, right: 10),
                                              title: Column(children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    //print("closing...");
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Align(
                                                    alignment:
                                                        Alignment.topRight,
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 25.0,
                                                      color: kPrimaryColorTint2,
                                                    ),
                                                  ),
                                                ),
                                                const Center(
                                                  child: Text(
                                                    "Privacy Policy",
                                                    style: TextStyle(
                                                      fontSize: 15.0,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(20.0),
                                                ),
                                              ),
                                              content: Container(
                                                height: (MediaQuery.of(context)
                                                        .size
                                                        .height) /
                                                    1.2,
                                                width: (MediaQuery.of(context)
                                                        .size
                                                        .width) /
                                                    1.2,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      child: Expanded(
                                                        child:
                                                            SingleChildScrollView(
                                                                child: Text(
                                                          privacypolicy,
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      12.0,
                                                                  color: Colors
                                                                      .white70),
                                                        )),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }),
                                TextSpan(
                                  text: " and ",
                                  style: TextStyle(
                                    fontSize: 12.0,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                TextSpan(
                                    text: "User Generated Content (UGC) Policy",
                                    style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                      color: Colors.blueGrey,
                                      fontSize: 12.0,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: true,
                                          builder: (context) {
                                            return AlertDialog(
                                              contentPadding:
                                                  const EdgeInsets.only(
                                                      left: 10, right: 10),
                                              title: Column(children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    //print("closing...");
                                                    Navigator.of(context).pop();
                                                  },
                                                  child: const Align(
                                                    alignment:
                                                        Alignment.topRight,
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 25.0,
                                                      color: kPrimaryColorTint2,
                                                    ),
                                                  ),
                                                ),
                                                const Center(
                                                  child: Text(
                                                    "UGC Policy",
                                                    style: TextStyle(
                                                      fontSize: 15.0,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ]),
                                              shape:
                                                  const RoundedRectangleBorder(
                                                borderRadius: BorderRadius.all(
                                                  Radius.circular(20.0),
                                                ),
                                              ),
                                              content: Container(
                                                height: (MediaQuery.of(context)
                                                        .size
                                                        .height) /
                                                    1.2,
                                                width: (MediaQuery.of(context)
                                                        .size
                                                        .width) /
                                                    1.2,
                                                child: Column(
                                                  children: [
                                                    Container(
                                                      child: Expanded(
                                                        child:
                                                            SingleChildScrollView(
                                                                child: Text(
                                                          ugcRules,
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12.0,
                                                            color:
                                                                Colors.white70,
                                                          ),
                                                        )),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }),
                              ]),
                        ),
                        const SizedBox(
                          height: 16.0,
                        ),
                        ButtonSimple(
                          color: kPrimaryColor,
                          textColor: kHeadlineColorDark,
                          text: "Sign up",
                          onPress: () async {
                            checkInternet().then(
                              (_) => {
                                if (internetOK == true)
                                  {
                                    if (_signupKey.currentState!.validate())
                                      {
                                        registeruser(),
                                        if (errorMessage != null)
                                          {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                              "Error: $errorMessage",
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .displaySmall!
                                                  .copyWith(
                                                    color: Colors.redAccent,
                                                    fontSize: 16.0,
                                                  ),
                                            ))),
                                          }
                                      }
                                  }
                                else
                                  {
                                    _showNoInternet(),
                                  }
                              },
                            );
                          },
                        )
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
