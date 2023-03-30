import 'dart:io';
import 'package:challo/pages/navigation.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/button_simple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DeleteAccount extends StatefulWidget {
  const DeleteAccount({Key? key}) : super(key: key);

  @override
  State<DeleteAccount> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends State<DeleteAccount> {
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
  final _accountDeleteKey = GlobalKey<FormState>();
  String errorMessage = "";
  TextEditingController pwdcontroller = TextEditingController();
  bool _obscureText = true;
  bool dataisthere = false;
  bool internetOK = false;
  bool _toggle() {
    setState(() {
      _obscureText = !_obscureText;
    });
    return _obscureText;
  }

  bool deletionInProgress = false;

  Future<void> _validatePwd(String pwd) async {
    var authCredentials =
        EmailAuthProvider.credential(email: email, password: pwd);
    try {
      await firebaseUser
          .reauthenticateWithCredential(authCredentials)
          .then((_) => {
                deleteAccountConfirmation(),
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

  deleteAccountConfirmation() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text("Sure you want to proceed to delete account permanently?",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kSubTextColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                )),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            //isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(context);
              deleteAccountConfirmationAgain();
            },
            child: Text(
              'Yes',
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
            "Cancel",
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
      ),
    );
  }

  deleteAccount() async {
    setState(() {
      deletionInProgress = true;
    });
    await usercollection.doc(uid).update({
      'accountStatus': 'deleted',
    }).then((_) async => {
          await accountDeletionCollection
              .doc(uid)
              .set({
                'uid': uid,
                'reason': 'other',
                'time': DateTime.now(),
              })
              .then((_) => {
                    firebaseUser.delete(),
                  })
              .then((_) => {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => NavigationPage(),
                      ),
                      (Route<dynamic> route) => false,
                    )
                  }),
        });
  }

  deleteAccountConfirmationAgain() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
            "Please confirm again you want to delete this account. This step is to avoid accidental deletions.",
            style: Theme.of(context).textTheme.titleSmall!.copyWith(
                  color: kSubTextColor,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w700,
                )),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            //isDefaultAction: true,
            onPressed: () async {
              Navigator.pop(context);
              deleteAccount();
            },
            child: Text(
              'Yes, Delete My Account',
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
            "Cancel",
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Delete Account"),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back),
        ),
      ),
      body: (dataisthere == false)
          ? const Center(
              child: CupertinoActivityIndicator(color: kDarkPrimaryColor))
          : (deletionInProgress == true)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: const [
                      CupertinoActivityIndicator(color: kDarkPrimaryColor),
                      SizedBox(
                        height: 20.0,
                      ),
                      Text("Deleting account...")
                    ],
                  ),
                )
              : Form(
                  key: _accountDeleteKey,
                  child: SafeArea(
                    child: Container(
                      padding:
                          const EdgeInsets.only(left: 16, top: 25, right: 16),
                      child: ListView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        children: [
                          Text(
                            "Type in password to delete this account.",
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: kHeadlineColorDark,
                                  fontSize: 15.0,
                                  letterSpacing: -0.24,
                                  fontWeight: FontWeight.w500,
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
                            obscureText: _obscureText,
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
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            controller: pwdcontroller,
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
                                splashColor: Colors.transparent,
                                hoverColor: Colors.transparent,
                                highlightColor: Colors.transparent,
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
                            "We're sorry to hear you'd like to delete your account. After deletion, you will permanently lose access to your profile and posts you've created with this account.",
                            style:
                                Theme.of(context).textTheme.subtitle1!.copyWith(
                                      color: kIconSecondaryColorDark,
                                      fontSize: 14.0,
                                    ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          ButtonSimple(
                              color: kWarningColorDark,
                              textColor: kHeadlineColorDark,
                              text: "Delete account",
                              onPress: () {
                                checkInternet().then((_) => {
                                      if (internetOK == true)
                                        {
                                          if (_accountDeleteKey.currentState!
                                              .validate())
                                            {_validatePwd(pwdcontroller.text)}
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
