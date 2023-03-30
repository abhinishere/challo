import 'package:challo/models/content_info_model.dart';
import 'package:challo/pages/podcast_screen3.dart';
import 'package:challo/pages/podcast_screen5.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:challo/models/user_info_model.dart';

class PodcastScreen2 extends StatefulWidget {
  final UserInfoModel? onlineuser;
  final ContentInfoModel? contentinfo;
  final int? guestsno;
  const PodcastScreen2(
      {required this.onlineuser,
      required this.contentinfo,
      required this.guestsno});
  @override
  State<PodcastScreen2> createState() => _PodcastScreen2State();
}

class _PodcastScreen2State extends State<PodcastScreen2> {
  TextEditingController opponentcontroller = TextEditingController();

  UserInfoModel? guest1;
  Future<QuerySnapshot>? searchresult;
  searchuser(String typeduser) {
    var users = usercollection
        .where('username', isGreaterThanOrEqualTo: typeduser)
        .where('username', isLessThan: "${typeduser}z")
        .where('username', isNotEqualTo: widget.onlineuser!.username)
        .get();

    setState(() {
      searchresult = users;
    });
  }

  clearSearch() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => opponentcontroller.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Select guest #1"),
        backgroundColor: Colors.transparent,
        elevation: 0.0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Container(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: TextFormField(
                    cursorColor: Colors.white,
                    controller: opponentcontroller,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search username...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          width: 0,
                          style: BorderStyle.none,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade800,
                      contentPadding: const EdgeInsets.only(left: 16),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(right: 16.0, left: 16.0),
                        child: Icon(
                          Icons.search,
                          color: Colors.grey.shade600,
                          size: 24,
                        ),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 16.0, left: 16.0),
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
                          searchuser(input);
                        });
                      }
                    },
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: (searchresult == null)
                      ? const Center(
                          child: Icon(
                          Icons.person_search,
                          size: 200,
                        ))
                      : FutureBuilder(
                          future: searchresult,
                          builder:
                              (BuildContext context, AsyncSnapshot snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CupertinoActivityIndicator(
                                color: kDarkPrimaryColor,
                              ));
                            }
                            if (snapshot.data.docs.length == 0) {
                              return const Center(
                                child: Text('No users found. :(',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                    )),
                              );
                            }
                            return ListView.builder(
                                itemCount: snapshot.data.docs.length,
                                itemBuilder: (BuildContext context, int index) {
                                  var user = snapshot.data.docs[index];

                                  return InkWell(
                                    onTap: () {
                                      String? guest1uid = user['uid'];
                                      String? guest1username = user['username'];
                                      String? guest1name = user['name'];
                                      String? guest1email = user['email'];
                                      String? guest1pic = user['profilepic'];
                                      bool? guest1profileverified =
                                          user['profileverified'];
                                      guest1 = UserInfoModel(
                                        uid: guest1uid,
                                        username: guest1username,
                                        name: guest1name,
                                        email: guest1email,
                                        pic: guest1pic,
                                        profileverified: guest1profileverified,
                                      );
                                      (widget.guestsno == 1)
                                          ? Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      PodcastScreen5(
                                                        onlineuser:
                                                            widget.onlineuser,
                                                        guest1: guest1,
                                                        contentinfo:
                                                            widget.contentinfo,
                                                        guestsno:
                                                            widget.guestsno,
                                                      )))
                                          : Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      PodcastScreen3(
                                                        onlineuser:
                                                            widget.onlineuser,
                                                        guest1: guest1,
                                                        contentinfo:
                                                            widget.contentinfo,
                                                        guestsno:
                                                            widget.guestsno,
                                                      )));
                                    },
                                    child: ListTile(
                                      leading: const Icon(Icons.search,
                                          color: Colors.white),
                                      trailing: CircleAvatar(
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
                                });
                          }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
