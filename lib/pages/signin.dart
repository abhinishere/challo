import 'dart:io';

import 'package:challo/pages/forgotpassword.dart';
import 'package:challo/pages/navigation.dart';
import 'package:challo/widgets/button_simple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:challo/variables.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class SignIn extends StatefulWidget {
  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _signinKey = GlobalKey<FormState>();
  TextEditingController emailcontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  String? errorMessage;
  bool _obscureText = true;
  bool internetOK = false;

  /*Widget showAlert(String? errorMessage) {
    if (errorMessage != null) {
      return Container(
        color: kLightPink,
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

  userAuth(String email, String password) async {
    try {
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      await firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password)
          .then((_) => {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => NavigationPage(),
                  ),
                  (Route<dynamic> route) => false,
                )
              });
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
        //resizeToAvoidBottomInset: false,
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
              //physics: const ClampingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Form(
                key: _signinKey,
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
                          "Login to Challo",
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
                          "Welcome back!",
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
                        TextButton(
                          child: Text(
                            "Forgot password?",
                            style: Theme.of(context).textTheme.button!.copyWith(
                                  color: kPrimaryColorTint2,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15.0,
                                ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ForgotPassword()),
                            );
                          },
                        ),
                        const SizedBox(
                          height: 16.0,
                        ),
                        ButtonSimple(
                          color: kPrimaryColor,
                          textColor: kHeadlineColorDark,
                          text: "Sign in",
                          onPress: () {
                            String trimmedEmail = emailcontroller.text.trim();
                            checkInternet().then((_) => {
                                  if (internetOK == true)
                                    {
                                      if (_signinKey.currentState!.validate())
                                        {
                                          userAuth(trimmedEmail,
                                              passwordcontroller.text),
                                          if (errorMessage != null)
                                            {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                "Error: $errorMessage",
                                              ))),
                                            }
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
