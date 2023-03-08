import 'dart:io';

import 'package:challo/variables.dart';
import 'package:challo/widgets/button_simple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PasswordChange extends StatefulWidget {
  const PasswordChange({Key? key}) : super(key: key);

  @override
  State<PasswordChange> createState() => _PasswordChangeState();
}

class _PasswordChangeState extends State<PasswordChange> {
  @override
  void initState() {
    super.initState();
    getUserData();
  }

  getUserData() async {
    firebaseAuth = FirebaseAuth.instance;
    firebaseUser = firebaseAuth!.currentUser!;
    uid = firebaseUser.uid;
    email = firebaseUser.email!;
    setState(() {
      dataisthere = true;
    });
  }

  late FirebaseAuth? firebaseAuth;
  late User firebaseUser;
  late String uid;
  late String email;
  final _passwordChangeKey = GlobalKey<FormState>();
  String errorMessage = "";
  TextEditingController oldpwdcontroller = TextEditingController();
  TextEditingController newpwdcontroller = TextEditingController();

  bool _obscureOldPwd = true;
  bool _obscureNewPwd = true;
  bool dataisthere = false;
  bool internetOK = false;

  bool _toggle(bool _obscureText) {
    setState(() {
      _obscureText = !_obscureText;
    });
    return _obscureText;
  }

  Future<void> _validatePwd(String oldpwd) async {
    final String newpwd = newpwdcontroller.text;
    var authCredentials =
        EmailAuthProvider.credential(email: email, password: oldpwd);
    try {
      await firebaseUser
          .reauthenticateWithCredential(authCredentials)
          .then((_) async => {
                firebaseUser.updatePassword(newpwd).then((_) => {
                      setState(() {
                        _passwordChangeKey.currentState!.reset();
                        oldpwdcontroller.text = "";
                        newpwdcontroller.text = "";
                      }),
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Your password has been changed.",
                          ),
                        ),
                      ),
                    })
              }); // proceed with password change

    } on FirebaseAuthException catch (e) {
      // handle if reauthenticatation was not successful
      errorMessage = e.message.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Error: $errorMessage",
          ),
        ),
      );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Password"),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: (dataisthere == false)
          ? const Center(
              child: CupertinoActivityIndicator(color: kDarkPrimaryColor))
          : Form(
              key: _passwordChangeKey,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.only(left: 16, top: 25, right: 16),
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Text(
                              "OLD PASSWORD",
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
                            /*(usernamechecking == false)
                          ? Container()
                          : const CupertinoActivityIndicator(
                              radius: 7.0,
                              color: kPrimaryColor,
                            ),*/
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      TextFormField(
                        obscureText: _obscureOldPwd,
                        cursorColor: kHeadlineColorDark,
                        //maxLength: 15,
                        validator: (text) {
                          if (text == null || text.isEmpty) {
                            return 'Password cannot be empty';
                          }
                          /* if (text.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    if (text.length > 128) {
                      return 'Password must be less than 128 characters long';
                    }
                  if (errorMessage.isNotEmpty && errorMessage != "") {
                      return errorMessage;
                    }*/
                          return null;
                        },
                        //onEditingComplete: () => validatorCheck(),
                        /*onChanged: (text) {
                    if (text != username) {
                      validatorCheck(text);
                    }
                  },*/
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: oldpwdcontroller,
                        style:
                            Theme.of(context).textTheme.displayMedium!.copyWith(
                                  fontSize: 16,
                                  color: kHeadlineColorDark,
                                  fontWeight: FontWeight.bold,
                                ),
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            splashColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            icon: (_obscureOldPwd == true)
                                ? const Icon(
                                    Icons.visibility_off_outlined,
                                    color: kIconSecondaryColorDark,
                                  )
                                : const Icon(
                                    Icons.visibility_outlined,
                                    color: kIconSecondaryColorDark,
                                  ),
                            onPressed: () {
                              _obscureOldPwd = _toggle(_obscureOldPwd);
                            },
                          ),
                          hintText: 'Old Password',
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
                        height: 20.0,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Text(
                              "NEW PASSWORD",
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
                            /*(usernamechecking == false)
                          ? Container()
                          : const CupertinoActivityIndicator(
                              radius: 7.0,
                              color: kPrimaryColor,
                            ),*/
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 5.0,
                      ),
                      TextFormField(
                        obscureText: _obscureNewPwd,
                        cursorColor: kHeadlineColorDark,
                        //maxLength: 15,
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
                        //onEditingComplete: () => validatorCheck(),
                        /*onChanged: (text) {
                    if (text != username) {
                      validatorCheck(text);
                    }
                  },*/
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        controller: newpwdcontroller,
                        style:
                            Theme.of(context).textTheme.displayMedium!.copyWith(
                                  fontSize: 16,
                                  color: kHeadlineColorDark,
                                  fontWeight: FontWeight.bold,
                                ),
                        decoration: InputDecoration(
                          suffixIcon: IconButton(
                            splashColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            icon: (_obscureNewPwd == true)
                                ? const Icon(
                                    Icons.visibility_off_outlined,
                                    color: kIconSecondaryColorDark,
                                  )
                                : const Icon(
                                    Icons.visibility_outlined,
                                    color: kIconSecondaryColorDark,
                                  ),
                            onPressed: () {
                              _obscureNewPwd = _toggle(_obscureNewPwd);
                            },
                          ),
                          hintText: 'New Password',
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
                        height: 20,
                      ),
                      ButtonSimple(
                          color: kPrimaryColor,
                          textColor: kHeadlineColorDark,
                          text: "Change password",
                          onPress: () {
                            checkInternet().then((_) => {
                                  if (internetOK == true)
                                    {
                                      if (_passwordChangeKey.currentState!
                                          .validate())
                                        {_validatePwd(oldpwdcontroller.text)}
                                    }
                                  else
                                    {
                                      _showNoInternet(),
                                    }
                                });
                          })
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
