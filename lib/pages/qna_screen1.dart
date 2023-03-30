import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:challo/models/content_info_model.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/participantpage.dart';
import 'package:challo/widgets/button_simple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:challo/variables.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

class QnAScreen1 extends StatefulWidget {
  final UserInfoModel? onlineuser;
  final bool whetherediting;
  final bool? whetherfrompost;
  final String? docName;
  const QnAScreen1({
    required this.onlineuser,
    required this.whetherediting,
    this.whetherfrompost,
    this.docName,
  });

  @override
  State<QnAScreen1> createState() => _QnAScreen1State();
}

class _QnAScreen1State extends State<QnAScreen1> {
  @override
  void initState() {
    super.initState();
    getalldata();
  }

  getalldata() async {
    if (widget.whetherediting == false) {
      setState(() {
        dataisthere = true;
      });
    } else {
      //what's needed - topic, description
      var qnadocs = await contentcollection.doc(widget.docName).get();
      final String qnatopic = qnadocs['topic'];
      final String qnadescription = qnadocs['description'];

      //setting form field
      qnasubjectcontroller.text = qnatopic;
      qnadescriptioncontroller.text = qnadescription;
      setState(() {
        dataisthere = true;
      });
    }
  }

  bool dataisthere = false;
  final _qnaKey = GlobalKey<FormState>();
  TextEditingController qnasubjectcontroller = TextEditingController();
  TextEditingController qnadescriptioncontroller = TextEditingController();
  String? category, docName, topic, description, camerastatus, micstatus;
  ContentInfoModel? contentinfo;
  //dynamic time;
  List categoryList = [
    'Business',
    'Entertainment',
    'Family',
    'Health',
    'Politics',
    'Religion',
    'Science',
    'Social Issues',
    'Sports',
    'Technology',
    'Other'
  ];
  bool channelcreated = false;
  RegExp exp = RegExp(r'[\s,;/.!:?({\[&)\]}]+');
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generatedocName() {
    String newdocName = (widget.onlineuser!.username! + getRandomString(5));
    return newdocName;
  }

  void _channelError() {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("Error",
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: Colors.white,
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold)),
          content: new Text("Sorry, something went wrong. Please try again.",
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    color: Colors.white70,
                    fontSize: 14.0,
                  )),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new TextButton(
              ////highlightColor: Colors.white,
              child:
                  const Text("Close", style: TextStyle(color: kPrimaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleCamera(Permission permission) async {
    final status = await permission.request();
    if (status == PermissionStatus.granted) {
      setState(() {
        camerastatus = 'granted';
      });
    } else if (status == PermissionStatus.permanentlyDenied) {
      setState(() {
        camerastatus = 'permanentlydenied';
      });
    } else {
      setState(() {
        camerastatus = 'denied';
      });
    }
  }

  Future<void> _handleMic(Permission permission) async {
    final status = await permission.request();
    if (status == PermissionStatus.granted) {
      setState(() {
        micstatus = 'granted';
      });
    } else if (status == PermissionStatus.permanentlyDenied) {
      setState(() {
        micstatus = 'permanentlydenied';
      });
    } else {
      setState(() {
        micstatus = 'denied';
      });
    }
  }

  void _showPermissionDenied(String status) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text("Permission Error"),
        content: Text((status == 'permanentlydenied')
            ? "Allow camera and mic access in Settings to enter a live session."
            : "Allow camera and mic access to enter a live session."),
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

  Future<void> onCreate() async {
    await _handleCamera(Permission.camera);
    await _handleMic(Permission.microphone);
    // push video page with given channel name
    print("no of guests in qna ${contentinfo!.guestsno}");

    if (camerastatus == 'granted' && micstatus == 'granted') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ParticipantPage(
            oppic: widget.onlineuser!.pic!,
            opusername: widget.onlineuser!.username!,
            guestsno: 0,
            whostarted: widget.onlineuser!.uid,
            user0: widget.onlineuser,
            docName: docName,
            formattype: "QnA",
            role: ClientRole.Broadcaster,
            onlineuser: widget.onlineuser,
            contentinfo: contentinfo,
          ),
          fullscreenDialog: true,
        ),
      );
    } else if (camerastatus == 'permanentlydenied' ||
        micstatus == 'permanentlydenied') {
      _showPermissionDenied('permanentlydenied');
    } else {
      _showPermissionDenied('denied');
    }
  }

  gotoLivePage() {
    setState(() {
      hidenav = true;
    });
    //if (!mounted) return;
    AppBuilder.of(context)!.rebuild();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ParticipantPage(
          oppic: widget.onlineuser!.pic!,
          opusername: widget.onlineuser!.username!,
          guestsno: 0,
          whostarted: widget.onlineuser!.uid,
          user0: widget.onlineuser,
          docName: docName,
          formattype: "QnA",
          role: ClientRole.Broadcaster,
          onlineuser: widget.onlineuser,
          contentinfo: contentinfo,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  List<String> stringtoList(String videoinfostring) {
    final List<String> infoinlist0 = videoinfostring.split(exp);
    final List<String> infoinlist =
        infoinlist0.map((email) => email.toLowerCase()).toList();
    infoinlist.removeWhere((value) => value == "");
    return (infoinlist);
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

  updateAndExit() async {
    await contentcollection.doc(widget.docName).update({
      'topic': qnasubjectcontroller.text,
      'topicinlist': stringtoList(qnasubjectcontroller.text),
      'description': qnadescriptioncontroller.text,
      'descriptioninlist': stringtoList(qnadescriptioncontroller.text),
    }).then((_) async => {
          await usercollection
              .doc(widget.onlineuser!.uid)
              .collection('content')
              .doc(widget.docName)
              .update({
            'topic': qnasubjectcontroller.text,
            'description': qnadescriptioncontroller.text,
          }).then((_) => {
                    //exit
                    if (widget.whetherfrompost == false)
                      {
                        setState(() {
                          hidenav = false;
                        }),
                        AppBuilder.of(context)!.rebuild(),
                        Navigator.pop(context),
                      }
                    else
                      {
                        Navigator.pop(context),
                      }
                  }),
        });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (widget.whetherfrompost == false || widget.whetherediting == false) {
          setState(() {
            hidenav = false;
          });
          AppBuilder.of(context)!.rebuild();
          Navigator.pop(context);
        } else {
          Navigator.pop(context);
        }
        return Future.value(false);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          actions: [
            (widget.whetherediting == true && dataisthere == true)
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: TextButton(
                      onPressed: () async {
                        if (_qnaKey.currentState!.validate()) {
                          updateAndExit();
                        }
                      },
                      child: Text(
                        "Update",
                        style: Theme.of(context).textTheme.button!.copyWith(
                              color: kPrimaryColorTint2,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  )
                : Container(),
          ],
          leading: GestureDetector(
            onTap: () {
              if (widget.whetherfrompost == false ||
                  widget.whetherediting == false) {
                setState(() {
                  hidenav = false;
                });
                AppBuilder.of(context)!.rebuild();
                Navigator.pop(context);
              } else {
                Navigator.pop(context);
              }
            },
            child: const Icon(
              Icons.arrow_back,
            ),
          ),
          title: Text((widget.whetherediting == false) ? "Q&A" : "Edit Q&A"),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: (dataisthere == false)
            ? const CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              )
            : Form(
                key: _qnaKey,
                child: SafeArea(
                  child: Container(
                    child: ListView(
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
                                  controller: qnasubjectcontroller,
                                  maxLength: 70,
                                  readOnly: true,
                                  maxLines: 2,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText1!
                                      .copyWith(color: Colors.white),
                                  decoration: const InputDecoration.collapsed(
                                    hintText: 'Add a title...',
                                  ),
                                  onTap: () {
                                    showTextSheet("Title", 5, 70, false,
                                        qnasubjectcontroller);
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
                                    } else if (text.length > 150) {
                                      return "Description can't be more than 150 chars";
                                    }
                                    return null;
                                  },
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  controller: qnadescriptioncontroller,
                                  maxLength: 150,
                                  readOnly: true,
                                  maxLines: 2,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyText1!
                                      .copyWith(color: Colors.white),
                                  decoration: const InputDecoration.collapsed(
                                    hintText: 'Add a description...',
                                  ),
                                  onTap: () {
                                    showTextSheet("Description", 10, 150, false,
                                        qnadescriptioncontroller);
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
                        (widget.whetherediting == false)
                            ? Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: DropdownButtonFormField(
                                  decoration: const InputDecoration(
                                      enabledBorder: UnderlineInputBorder(
                                          borderSide: BorderSide(
                                    color: kHeadlineColorDark,
                                    width: 1.0,
                                  ))),
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  validator: (dynamic value) => value == null
                                      ? 'Please select a category'
                                      : null,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: kHeadlineColorDark,
                                      fontWeight: FontWeight.bold),
                                  icon: const Icon(
                                      Icons.arrow_drop_down_outlined),
                                  dropdownColor: kBackgroundColorDark,
                                  hint: Text(
                                    "Select Category",
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption!
                                        .copyWith(
                                          fontSize: 15.0,
                                          color: kSubTextColor,
                                          letterSpacing: -0.24,
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                  value: category,
                                  onChanged: (dynamic newValue) {
                                    setState(() {
                                      category = newValue;
                                    });
                                  },
                                  items: categoryList.map((valueItem) {
                                    return DropdownMenuItem(
                                      value: valueItem,
                                      child: Text(valueItem),
                                    );
                                  }).toList(),
                                ),
                              )
                            : Container(),
                        const SizedBox(height: 10),
                        (widget.whetherediting == false)
                            ? Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ButtonSimple(
                                    color: kPrimaryColor,
                                    textColor: kHeadlineColorDark,
                                    text: "Go Live",
                                    onPress: () async {
                                      if (_qnaKey.currentState!.validate()) {
                                        List<String> blockedby = [];
                                        topic = qnasubjectcontroller.text;
                                        description =
                                            qnadescriptioncontroller.text;
                                        contentinfo = ContentInfoModel(
                                          subject: topic,
                                          description: description,
                                          category: category,
                                          formattype: 'QnA',
                                          guestsno: 0,
                                        );
                                        docName = generatedocName();
                                        //time = DateTime.now();
                                        await usercollection
                                            .doc(widget.onlineuser!.uid)
                                            .update({
                                          'pendingvideo': true,
                                          'docName': docName,
                                        });
                                        await contentcollection
                                            .doc(docName)
                                            .set({
                                          'type': 'QnA',
                                          'guestsno': 0,
                                          'status': 'started',
                                          'docName': docName,
                                          'whethercommunitypost': false,
                                          'communityName': '',
                                          'communitypic': '',
                                          'topic': topic,
                                          'topicinlist': stringtoList(topic!),
                                          'description': description,
                                          'descriptioninlist':
                                              stringtoList(description!),
                                          'category': category,
                                          //'time': time,
                                          'likes': [],
                                          'dislikes': [],
                                          'commentcount': 0,
                                          'liveviews': [],
                                          'totalviews': [],
                                          'link':
                                              "$mergedBucketBaseUrl/$docName.mp4", // pre-generated AWS link where the video will be stored; for instance https://${bucket-name}.${region}.amazonaws.com/$docName.mp4
                                          'whostarted': widget.onlineuser!.uid,
                                          'opusername':
                                              widget.onlineuser!.username,
                                          'oppic': widget.onlineuser!.pic,
                                          'requesteduids': [],
                                          'accepteduids': [],
                                          'declineduids': [],
                                          'pendinguids': [],
                                          'participateduids': [],
                                          'unexiteduids': [
                                            widget.onlineuser!.uid
                                          ],
                                          'portraitonly': true,
                                          'blockedby': blockedby,
                                          'whetherlive': false,
                                          'topfeaturedpriority': 0,
                                          'trendingpriority': 0,
                                          'communitypostpriority': 0,
                                        });

                                        await contentcollection
                                            .doc(docName)
                                            .get()
                                            .then((value) => {
                                                  if (value.exists)
                                                    {
                                                      setState(() {
                                                        channelcreated = true;
                                                      })
                                                    }
                                                });

                                        if (channelcreated == true) {
                                          await contentcollection
                                              .doc(docName)
                                              .collection('users')
                                              .doc('user 0')
                                              .set({
                                            'uid': widget.onlineuser!.uid,
                                            'username':
                                                widget.onlineuser!.username,
                                            'name': widget.onlineuser!.name,
                                            'email': widget.onlineuser!.email,
                                            'pic': widget.onlineuser!.pic,
                                          });
                                          onCreate();
                                        } else {
                                          _channelError();
                                        }
                                      }
                                    }),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
