import 'package:challo/models/content_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/widgets/button_simple.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:challo/variables.dart';
import 'package:challo/pages/podcast_screen2.dart';
import 'package:challo/models/user_info_model.dart';

class PodcastScreen1 extends StatefulWidget {
  final UserInfoModel? onlineuser;
  final bool whetherediting;
  final bool? whetherfrompost;
  final String? docName;
  final List? participateduids;
  const PodcastScreen1({
    required this.onlineuser,
    required this.whetherediting,
    this.whetherfrompost,
    this.docName,
    this.participateduids,
  });
  @override
  State<PodcastScreen1> createState() => _PodcastScreen1State();
}

class _PodcastScreen1State extends State<PodcastScreen1> {
  final _podcastKey = GlobalKey<FormState>();
  int guestsNo = 1;
  TextEditingController podcastsubjectcontroller = TextEditingController();
  TextEditingController podcastdescriptioncontroller = TextEditingController();
  String? selectedCategory;
  ContentInfoModel? contentinfo;
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

  @override
  void initState() {
    super.initState();
    getalldata();
  }

  bool dataisthere = false;

  getalldata() async {
    if (widget.whetherediting == false) {
      setState(() {
        dataisthere = true;
      });
    } else {
      var podcastdocs = await contentcollection.doc(widget.docName).get();
      final String podcastTopic = podcastdocs['topic'];
      final String podcastDescription = podcastdocs['description'];
      for (String uid in widget.participateduids!) {
        print('participateduids are $uid');
      }
      podcastsubjectcontroller.text = podcastTopic;
      podcastdescriptioncontroller.text = podcastDescription;
      setState(() {
        dataisthere = true;
      });
    }
  }

  clearSearch(controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) => controller.clear());
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

  List<String> stringtoList(String videoinfostring) {
    RegExp exp = RegExp(r'[\s,;/.!:?({\[&)\]}]+');
    final List<String> infoinlist0 = videoinfostring.split(exp);
    final List<String> infoinlist =
        infoinlist0.map((email) => email.toLowerCase()).toList();
    infoinlist.removeWhere((value) => value == "");
    return (infoinlist);
  }

  updateAndExit() async {
    await contentcollection.doc(widget.docName).update({
      'topic': podcastsubjectcontroller.text,
      'topicinlist': stringtoList(podcastsubjectcontroller.text),
      'description': podcastdescriptioncontroller.text,
      'descriptioninlist': stringtoList(podcastdescriptioncontroller.text),
    }).then((_) async => {
          for (String uid in widget.participateduids!)
            {
              await usercollection
                  .doc(uid)
                  .collection('content')
                  .doc(widget.docName)
                  .update({
                'topic': podcastsubjectcontroller.text,
                'description': podcastdescriptioncontroller.text,
              }).then((_) async => {
                        await contentcollection
                            .doc(widget.docName)
                            .get()
                            .then((value) => {
                                  if (value.exists)
                                    {
                                      if (widget.whetherfrompost == false)
                                        {
                                          setState(() {
                                            hidenav = false;
                                          }),
                                          AppBuilder.of(context)!.rebuild(),
                                          Navigator.pop(context)
                                        }
                                      else
                                        {
                                          Navigator.pop(context, true),
                                        }
                                    }
                                  else
                                    {
                                      //error message
                                    }
                                }),
                      })
            }
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
                      onPressed: () {
                        if (_podcastKey.currentState!.validate()) {
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
            child: const Icon(Icons.arrow_back),
          ),
          title: const Text("Podcast"),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: (dataisthere == false)
            ? const CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              )
            : Form(
                key: _podcastKey,
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
                                  controller: podcastsubjectcontroller,
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
                                        podcastsubjectcontroller);
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
                                  controller: podcastdescriptioncontroller,
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
                                        podcastdescriptioncontroller);
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
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "No of guests...",
                                          style: TextStyle(
                                            fontSize: 15.0,
                                            color: kSubTextColor,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            InkWell(
                                              customBorder:
                                                  const CircleBorder(),
                                              onTap: () {
                                                if (guestsNo > 1) {
                                                  setState(() {
                                                    guestsNo = guestsNo - 1;
                                                    print(
                                                        'guestsNo is $guestsNo');
                                                  });
                                                }
                                              },
                                              child: Icon(
                                                CupertinoIcons.minus_circle,
                                                color: (guestsNo == 1)
                                                    ? kIconSecondaryColorDark
                                                    : kPrimaryColorTint2,
                                                size: 30,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            Text(
                                              '$guestsNo',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium!
                                                  .copyWith(
                                                    fontSize: 15.0,
                                                    color: kSubTextColor,
                                                  ),
                                            ),
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            InkWell(
                                              customBorder:
                                                  const CircleBorder(),
                                              onTap: () {
                                                if (guestsNo < 2) {
                                                  setState(() {
                                                    guestsNo = guestsNo + 1;
                                                    print(
                                                        'guestsNo is $guestsNo');
                                                  });
                                                }
                                              },
                                              child: Icon(
                                                CupertinoIcons.plus_circle,
                                                color: (guestsNo == 2)
                                                    ? kIconSecondaryColorDark
                                                    : kPrimaryColorTint2,
                                                size: 30,
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    thickness: 1,
                                    color: Colors.grey.shade800,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      left: 10.0,
                                      right: 10.0,
                                      top: 5.0,
                                      bottom: 10.0,
                                    ),
                                    child: DropdownButtonFormField(
                                      decoration: const InputDecoration(
                                          enabledBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                        color: kHeadlineColorDark,
                                        width: 1.0,
                                      ))),
                                      autovalidateMode:
                                          AutovalidateMode.onUserInteraction,
                                      validator: (dynamic value) =>
                                          value == null
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
                                      value: selectedCategory,
                                      onChanged: (dynamic newValue) {
                                        setState(() {
                                          selectedCategory = newValue;
                                        });
                                      },
                                      items: categoryList.map((valueItem) {
                                        return DropdownMenuItem(
                                          value: valueItem,
                                          child: Text(valueItem),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: ButtonSimple(
                                        color: kPrimaryColor,
                                        textColor: kHeadlineColorDark,
                                        text: "Pick Guests",
                                        onPress: () async {
                                          if (_podcastKey.currentState!
                                              .validate()) {
                                            contentinfo = ContentInfoModel(
                                                subject:
                                                    podcastsubjectcontroller
                                                        .text,
                                                description:
                                                    podcastdescriptioncontroller
                                                        .text,
                                                category: selectedCategory);
                                            Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                    settings:
                                                        const RouteSettings(
                                                            name:
                                                                "PodcastPage2"),
                                                    builder: (context) =>
                                                        PodcastScreen2(
                                                          onlineuser:
                                                              widget.onlineuser,
                                                          contentinfo:
                                                              contentinfo,
                                                          guestsno: guestsNo,
                                                        )));
                                          }
                                        }),
                                  ),
                                ],
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
