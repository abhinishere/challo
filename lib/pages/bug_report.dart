import 'package:auto_size_text/auto_size_text.dart';
import 'package:challo/variables.dart';
import 'package:challo/widgets/button_simple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class BugReport extends StatefulWidget {
  @override
  State<BugReport> createState() => _BugReportState();
}

class _BugReportState extends State<BugReport> {
  @override
  void initState() {
    super.initState();
    getuserdata();
  }

  getuserdata() async {
    onlineuid = FirebaseAuth.instance.currentUser!.uid;
    setState(() {
      dataisthere = true;
    });
  }

  String? onlineuid;
  bool dataisthere = false;
  final _reportKey = GlobalKey<FormState>();
  TextEditingController problemdescriptioncontroller = TextEditingController();
  String selectedProblem = 'Report a Bug';
  String? errorMessage;
  List problemList = [
    'Report a Bug',
    'Request a Feature',
  ];
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generateRandomDocName(String username) {
    String newDocName = (username + getRandomString(5));
    return newDocName;
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
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back),
        ),
        title: const Text(
          "Report a Problem",
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
              key: _reportKey,
              child: SafeArea(
                child: Container(
                    child: ListView(
                  children: [
                    Divider(
                      thickness: 1,
                      color: Colors.grey.shade800,
                    ),
                    showAlert(errorMessage),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          prefixIconConstraints: BoxConstraints(),
                          prefixIcon: Padding(
                              padding: EdgeInsets.only(right: 10.0),
                              child: Icon(Icons.question_mark)),
                          labelText: "Select a reason...",
                          labelStyle: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: kSubTextColor,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: Theme(
                            data: ThemeData(
                              brightness: Brightness.dark,
                              splashColor: Colors.transparent,
                              highlightColor: Colors.transparent,
                              scrollbarTheme: ScrollbarThemeData(
                                thumbColor: MaterialStateProperty.all<Color>(
                                    Colors.white70),
                              ),
                            ),
                            child: Container(
                              height: 35,
                              child: DropdownButton(
                                  isDense: true,
                                  focusColor: Colors.transparent,
                                  menuMaxHeight:
                                      MediaQuery.of(context).size.height / 2,
                                  icon: const Icon(
                                    CupertinoIcons
                                        .arrowtriangle_down_circle_fill,
                                    //size: 25,
                                    color: kPrimaryColorTint2,
                                  ),
                                  dropdownColor: kBackgroundColorDark2,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText1!
                                      .copyWith(
                                        color: kHeadlineColorDark,
                                      ),
                                  items: problemList
                                      .map((e) => DropdownMenuItem(
                                            child: Text(e),
                                            value: e,
                                          ))
                                      .toList(),
                                  value: selectedProblem,
                                  onChanged: (val) {
                                    setState(() {
                                      selectedProblem = val as String;
                                    });
                                  }),
                            ),
                          ),
                        ),
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
                                } else if (text.length < 10) {
                                  return "Description can't be less than 10 chars";
                                } else if (text.length > 250) {
                                  return "Description can't be more than 250 chars";
                                }
                                return null;
                              },
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              controller: problemdescriptioncontroller,
                              maxLength: 250,
                              readOnly: true,
                              maxLines: 2,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyText1!
                                  .copyWith(
                                    color: kHeadlineColorDark,
                                  ),
                              decoration: const InputDecoration.collapsed(
                                hintText: 'Describe the issue...',
                              ),
                              onTap: () {
                                showTextSheet("Issue Description", 10, 250,
                                    false, problemdescriptioncontroller);
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                    /* Padding(
                      padding: const EdgeInsets.all(10),
                      child: CustomFieldSignUp(
                          maxlines: null,
                          mincharlength: 20,
                          maxcharlength: 250,
                          maxlength: 250,
                          controller: problemdescriptioncontroller,
                          label: "Describe the issue",
                          iconData: Icons.description_outlined),
                    ),*/
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
                          text: "Send the Report",
                          onPress: () async {
                            if (_reportKey.currentState!.validate()) {
                              await bugreportcollection
                                  .doc(generateRandomDocName(onlineuid!))
                                  .set({
                                'uid': onlineuid,
                                'type': selectedProblem,
                                'description':
                                    problemdescriptioncontroller.text,
                              }).then((_) => {
                                        setState(() {
                                          _reportKey.currentState!.reset();
                                          problemdescriptioncontroller.text =
                                              "";
                                        })
                                      });

                              setState(() {
                                errorMessage =
                                    "Report sent! We will look into the issue and fix it ASAP.";
                              });
                            }
                          }),
                    ),
                  ],
                )),
              )),
    );
  }
}
