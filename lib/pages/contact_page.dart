import 'package:auto_size_text/auto_size_text.dart';
import 'package:challo/widgets/button_simple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:challo/variables.dart';

class ContactPage extends StatefulWidget {
  @override
  State<ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<ContactPage> {
  String? onlineuid;
  bool dataisthere = false;
  final _contactKey = GlobalKey<FormState>();
  String? errorMessage;
  TextEditingController contactsubjectcontroller = TextEditingController();
  TextEditingController contactdescriptioncontroller = TextEditingController();

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateRandomDocName(String username) {
    String newDocName = (username + getRandomString(5));
    return newDocName;
  }

  getuserdata() async {
    onlineuid = FirebaseAuth.instance.currentUser!.uid;
    setState(() {
      dataisthere = true;
    });
  }

  @override
  void initState() {
    super.initState();
    getuserdata();
  }

  Widget showAlert(String? errorMessage) {
    if (errorMessage != null) {
      return Container(
        decoration: BoxDecoration(
            color: kPrimaryColor,
            border: Border.all(),
            borderRadius: const BorderRadius.all(Radius.circular(20))),
        width: double.infinity,
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(
                Icons.error_outline,
              ),
            ),
            Expanded(
                child: AutoSizeText(
              errorMessage,
              maxLines: 3,
              style: const TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontSize: 11.0),
            )),
          ],
        ),
      );
    } else {
      return const SizedBox(height: 0.0);
    }
  }

  showTextSheet(
    String typingWhat,
    int minLength,
    int maxLength,
    bool whetherMultiLine,
    TextEditingController _textEditingController,
  ) {
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
    return Scaffold(
      appBar: AppBar(
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back),
          onTap: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Contact",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: (dataisthere == false)
          ? const Center(
              child: CupertinoActivityIndicator(
              color: kDarkPrimaryColor,
            ))
          : Form(
              key: _contactKey,
              child: SafeArea(
                child: Container(
                    child: ListView(
                  children: [
                    showAlert(errorMessage),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, right: 8.0, top: 8.0),
                      child: Text(
                        "You can either use the contact form below (reply via notifications) or email your queries to contact@challo.tv.",
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                              color: kHeadlineColorDark,
                              fontSize: 15,
                              //fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Divider(
                      thickness: 1,
                      color: Colors.grey.shade800,
                    ),
                    /*
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: CustomFieldSignUp(
                          maxlines: null,
                          mincharlength: 10,
                          maxcharlength: 50,
                          maxlength: 50,
                          controller: contactsubjectcontroller,
                          label: "Subject...",
                          iconData: Icons.description_outlined),
                    ),*/
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
                                  return "Subject cannot be empty";
                                } else if (text.length < 5) {
                                  return "Subject can't be less than 5 chars";
                                } else if (text.length > 70) {
                                  return "Subject can't be more than 70 chars";
                                }
                                return null;
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              controller: contactsubjectcontroller,
                              maxLength: 70,
                              readOnly: true,
                              maxLines: 2,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1!
                                  .copyWith(color: Colors.white),
                              decoration: const InputDecoration.collapsed(
                                hintText: 'Add a Subject...',
                              ),
                              onTap: () {
                                showTextSheet("Subject", 5, 70, false,
                                    contactsubjectcontroller);
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
                    /*Padding(
                      padding:
                          const EdgeInsets.only(left: 20, right: 20, top: 20),
                      child: CustomFieldSignUp(
                          maxlines: null,
                          mincharlength: 20,
                          maxcharlength: 250,
                          maxlength: 250,
                          controller: contactdescriptioncontroller,
                          label: "Message...",
                          iconData: Icons.description_outlined),
                    ),*/
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
                                  return "Message body cannot be empty";
                                } else if (text.length < 10) {
                                  return "Message body can't be less than 10 chars";
                                } else if (text.length > 250) {
                                  return "Message body can't be more than 250 chars";
                                }
                                return null;
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              controller: contactdescriptioncontroller,
                              maxLength: 250,
                              readOnly: true,
                              maxLines: 2,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1!
                                  .copyWith(color: Colors.white),
                              decoration: const InputDecoration.collapsed(
                                hintText: 'Add the Message',
                              ),
                              onTap: () {
                                showTextSheet("Message Body", 10, 250, false,
                                    contactdescriptioncontroller);
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
                    const SizedBox(
                      height: 10.0,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ButtonSimple(
                          color: kPrimaryColor,
                          textColor: kHeadlineColorDark,
                          text: "Send Message",
                          onPress: () async {
                            if (_contactKey.currentState!.validate()) {
                              await directcontactcollection
                                  .doc(generateRandomDocName(onlineuid!))
                                  .set({
                                'time': DateTime.now(),
                                'uid': onlineuid,
                                'type': 'directcontact',
                                'subject': contactsubjectcontroller.text,
                                'description':
                                    contactdescriptioncontroller.text,
                              }).then((_) => {
                                        _contactKey.currentState!.reset(),
                                        contactsubjectcontroller.text = "",
                                        contactdescriptioncontroller.text = "",
                                      });

                              setState(() {
                                errorMessage =
                                    "Your message has been sent! You'll be replied ASAP via notifications.";
                              });
                            }
                          }),
                    ),
                    /*RoundedButton(
                      text: "Send message",
                      color: kPrimaryColor,
                      onPress: () async {
                        if (_contactKey.currentState!.validate()) {
                          await directcontactcollection
                              .doc(generateRandomDocName(onlineuid!))
                              .set({
                            'time': DateTime.now(),
                            'uid': onlineuid,
                            'type': 'directcontact',
                            'subject': contactsubjectcontroller.text,
                            'description': contactdescriptioncontroller.text,
                          });
                          _contactKey.currentState!.reset();
                          setState(() {
                            errorMessage =
                                "Your message has been sent! You'll be replied ASAP via notifications.";
                          });
                        }
                      },
                    ),*/
                  ],
                )),
              )),
    );
  }
}
