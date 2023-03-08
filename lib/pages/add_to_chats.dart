import 'dart:math';

import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/chatwith.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AddToChats extends StatefulWidget {
  const AddToChats({Key? key}) : super(key: key);

  @override
  State<AddToChats> createState() => _AddToChatsState();
}

class _AddToChatsState extends State<AddToChats> {
  final GlobalKey<ScaffoldState> _addtoChatsScaffoldKey =
      GlobalKey<ScaffoldState>();
  bool dataisthere = false;
  List<String> blockedusers = [];
  late String onlineuid, onlineusername, onlinepic;
  TextEditingController searchcontroller = TextEditingController();
  bool showloading = false;
  Future<QuerySnapshot>? usersuggestions;
  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();
  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  String generateRandomDocName() {
    final String time = DateTime.now().toString();
    final String newDocName =
        onlineusername + getRandomString(5) + time.substring(0, 10);
    return newDocName;
  }

  givesuggestions(String typedquery) async {
    setState(() {
      showloading = true;
    });
    final String typedqueryinlowercase = typedquery.toLowerCase();
    usersuggestions = usercollection
        .where('username', isGreaterThanOrEqualTo: typedqueryinlowercase)
        .where('username', isLessThan: '${typedqueryinlowercase}z')
        .where('username', isNotEqualTo: onlineusername)
        .get()
        .whenComplete(() => {
              setState(() {
                showloading = false;
              })
            });
  }

  clearSearch() {
    searchcontroller.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        usersuggestions = null;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    getalldata();
  }

  getalldata() async {
    onlineuid = FirebaseAuth.instance.currentUser!.uid;

    var onlineuserdocs = await usercollection.doc(onlineuid).get();

    onlineusername = onlineuserdocs['username'];
    onlinepic = onlineuserdocs['profilepic'];
    blockedusers = List.from(onlineuserdocs['blockedusers']);

    setState(() {
      dataisthere = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _addtoChatsScaffoldKey,
      appBar: AppBar(
        leading: Container(),
        title: const Text("Add to chats"),
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                hidenav = false;
              });
              AppBuilder.of(context)!.rebuild();
              Navigator.pop(context);
            },
            child: const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(Icons.arrow_back),
            ),
          ),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 8.0,
                right: 8.0,
                top: 5.0,
                bottom: 5.0,
              ),
              child: TextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (text) {
                  if (text == null || text.isEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      setState(() {
                        usersuggestions = null;
                      });
                    });

                    return null;
                  }
                  return null;
                },
                autofocus: true,
                cursorColor: kHeadlineColorDark,
                controller: searchcontroller,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  hintText: "Search by username...",
                  hintStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                        fontSize: 14,
                        color: kSubTextColor,
                        fontWeight: FontWeight.normal,
                      ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5),
                    borderSide: const BorderSide(
                      width: 0,
                      style: BorderStyle.none,
                    ),
                  ),
                  filled: true,
                  fillColor: kBackgroundColorDark,
                  contentPadding: const EdgeInsets.only(left: 16),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(
                      left: 5.0,
                      right: 5.0,
                    ),
                    child: Icon(
                      Icons.search,
                      color: Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 5.0, left: 5.0),
                    child: IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey.shade600,
                        size: 24,
                      ),
                      onPressed: () => clearSearch(),
                    ),
                  ),
                ),
                onChanged: (input) {
                  if (input.isNotEmpty) {
                    setState(() {
                      givesuggestions(input);
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: (dataisthere == false)
          ? const Center(
              child: CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              ),
            )
          : (usersuggestions == null)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_search,
                        color: kIconSecondaryColorDark,
                        size: 100,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'Select username from suggestions to start a chat',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium!
                              .copyWith(
                                fontSize: 13.0,
                                //fontStyle: FontStyle.italic,
                                color: kSubTextColor,
                              ),
                        ),
                      )
                    ],
                  ),
                )
              : (showloading == true)
                  ? const Center(
                      child: CupertinoActivityIndicator(
                        color: kDarkPrimaryColor,
                      ),
                    )
                  : FutureBuilder(
                      future: usersuggestions,
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CupertinoActivityIndicator(
                            color: kDarkPrimaryColor,
                          ));
                        }
                        if (snapshot.data.docs.length == 0) {
                          return Center(
                            child: Container(),
                          );
                        }
                        return ListView.builder(
                            scrollDirection: Axis.vertical,
                            shrinkWrap: true,
                            itemCount: snapshot.data.docs.length,
                            itemBuilder: (BuildContext context, int index) {
                              var user = snapshot.data.docs[index];
                              if (!blockedusers.contains(user['uid']) &&
                                  user['accountStatus'] != 'deleted') {
                                return InkWell(
                                  onTap: () async {
                                    var chatalready = await usercollection
                                        .doc(onlineuid)
                                        .collection('chats')
                                        .doc(user['uid'])
                                        .get();

                                    if (chatalready.exists) {
                                      final String chatDocName =
                                          chatalready['chatDocName'];
                                      final String otheruid =
                                          chatalready['uid'];
                                      //go to chats directly
                                      if (!mounted) return;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatWith(
                                            chatDocName: chatDocName,
                                            otheruid: otheruid,
                                            whetherjustcreated: true,
                                            onlineuid: onlineuid,
                                            onlineusername: onlineusername,
                                            onlinepic: onlinepic,
                                          ),
                                          fullscreenDialog: true,
                                        ),
                                      );
                                      print("this chat already exists");
                                    } else {
                                      setState(() {
                                        showloading = true;
                                      });
                                      final time = DateTime.now();

                                      final List<String> users = [
                                        onlineuid,
                                        user['uid'],
                                      ];
                                      final List<String> deletedBy = [];
                                      final Map<String, DateTime> deletedUntil =
                                          {
                                        onlineuid: time,
                                        user['uid']: time,
                                      };
                                      final String chatDocName =
                                          generateRandomDocName();
                                      await chatscollection
                                          .doc(chatDocName)
                                          .set({
                                        'uids': users,
                                        'time': time,
                                        'chatDocName': chatDocName,
                                        'status':
                                            'pending', //pending -> published -> deleted
                                        'deletedBy': deletedBy,
                                        'deletedUntil': deletedUntil,
                                      }).then((_) async => {
                                                await usercollection
                                                    .doc(onlineuid)
                                                    .collection('chats')
                                                    .doc(user['uid'])
                                                    .set({
                                                  'uid': user['uid'],
                                                  'time': time,
                                                  'chatDocName': chatDocName,
                                                  'status': 'pending',
                                                  'lastReadOn': time,
                                                  'lastDeletedOn': time,
                                                  'unreadCount': 0,
                                                  'lastMessagedOn': time,
                                                  'whetherDeleted': false,
                                                }).then((_) async => {
                                                          await usercollection
                                                              .doc(user['uid'])
                                                              .collection(
                                                                  'chats')
                                                              .doc(onlineuid)
                                                              .set({
                                                            'uid': onlineuid,
                                                            'time': time,
                                                            'chatDocName':
                                                                chatDocName,
                                                            'status': 'pending',
                                                            'lastReadOn': time,
                                                            'unreadCount': 0,
                                                            'lastDeletedOn':
                                                                time,
                                                            'lastMessagedOn':
                                                                time,
                                                            'whetherDeleted':
                                                                false,
                                                          }).then((_) => {
                                                                    Navigator
                                                                        .push(
                                                                      _addtoChatsScaffoldKey
                                                                          .currentContext!,
                                                                      MaterialPageRoute(
                                                                        builder: ((context) =>
                                                                            ChatWith(
                                                                              chatDocName: chatDocName,
                                                                              otheruid: user['uid'],
                                                                              whetherjustcreated: true,
                                                                              onlineuid: onlineuid,
                                                                              onlineusername: onlineusername,
                                                                              onlinepic: onlinepic,
                                                                            )),
                                                                      ),
                                                                    ),
                                                                  }),
                                                        }),
                                              });
                                    }
                                  },
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.white,
                                      backgroundImage:
                                          NetworkImage(user['profilepic']),
                                    ),
                                    title: Text(
                                      user['username'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return Container();
                              }
                            });
                      }),
    );
  }
}
