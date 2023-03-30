import 'package:challo/models/content_info_model.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/podcast_screen5.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PodcastScreen3 extends StatefulWidget {
  final UserInfoModel? onlineuser;
  final UserInfoModel? guest1;
  final ContentInfoModel? contentinfo;
  final int? guestsno;
  const PodcastScreen3({
    required this.onlineuser,
    required this.guest1,
    required this.contentinfo,
    required this.guestsno,
  });
  @override
  State<PodcastScreen3> createState() => _PodcastScreen3State();
}

class _PodcastScreen3State extends State<PodcastScreen3> {
  TextEditingController opponentcontroller = TextEditingController();
  Future<QuerySnapshot>? searchresult;
  UserInfoModel? guest2;
  searchuser(String typeduser) {
    //isNotEqualTo is not working as intended; for instance isNotEqualTo: username1 removes username2 as well
    var users = usercollection
        .where('username', isGreaterThanOrEqualTo: typeduser)
        .where('username', isLessThan: "${typeduser}z")
        .where('username', isNotEqualTo: widget.onlineuser!.username)
        //.where('username', isNotEqualTo: widget.guest1.username)
        .get();

    setState(() {
      searchresult = users;
    });
  }

  clearSearch() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => opponentcontroller.clear());
  }

  void _alreadyInvitedAlert() {
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
          content: new Text(
              "This user has already been included. Please select a different guest.",
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                    color: Colors.white70,
                    fontSize: 14.0,
                  )),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new TextButton(
              ////highlightColor: Colors.white,
              child: const Text("Okay", style: TextStyle(color: kPrimaryColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Select guest #2"),
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
                                      if (user['uid'] == widget.guest1!.uid) {
                                        _alreadyInvitedAlert();
                                      } else {
                                        String? guest2uid = user['uid'];
                                        String? guest2username =
                                            user['username'];
                                        String? guest2name = user['name'];
                                        String? guest2email = user['email'];
                                        String? guest2pic = user['profilepic'];
                                        bool? guest2profileverified =
                                            user['profileverified'];
                                        guest2 = UserInfoModel(
                                            uid: guest2uid,
                                            username: guest2username,
                                            name: guest2name,
                                            email: guest2email,
                                            pic: guest2pic,
                                            profileverified:
                                                guest2profileverified);
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    PodcastScreen5(
                                                      onlineuser:
                                                          widget.onlineuser,
                                                      guest1: widget.guest1,
                                                      guest2: guest2,
                                                      contentinfo:
                                                          widget.contentinfo,
                                                      guestsno: widget.guestsno,
                                                    )));
                                      }
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
