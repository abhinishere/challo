import 'package:challo/models/content_info_model.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/debate_screen3.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DebateScreen2 extends StatefulWidget {
  final UserInfoModel? onlineuser;
  final ContentInfoModel? contentinfo;

  const DebateScreen2({
    required this.onlineuser,
    required this.contentinfo,
  });
  @override
  State<DebateScreen2> createState() => _DebateScreen2State();
}

class _DebateScreen2State extends State<DebateScreen2> {
  TextEditingController opponentcontroller = TextEditingController();
  UserInfoModel? opponentuser;
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
        title: const Text(
          "Select opponent",
          style: TextStyle(color: Colors.white),
        ),
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
                      : FutureBuilder<QuerySnapshot>(
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
                                      String? opponentuid = user['uid'];
                                      String? opponentusername =
                                          user['username'];
                                      String? opponentname = user['name'];
                                      String? opponentemail = user['email'];
                                      String? opponentpic = user['profilepic'];
                                      String opponentstand = (widget.onlineuser!
                                                  .selectedRadioStand ==
                                              "For the motion")
                                          ? "Against the motion"
                                          : "For the motion";
                                      bool? opponentprofileverified =
                                          user['profileverified'];
                                      opponentuser = UserInfoModel(
                                        uid: opponentuid,
                                        username: opponentusername,
                                        name: opponentname,
                                        email: opponentemail,
                                        pic: opponentpic,
                                        selectedRadioStand: opponentstand,
                                        profileverified:
                                            opponentprofileverified,
                                      );

                                      Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  DebateScreen3(
                                                    onlineuser:
                                                        widget.onlineuser,
                                                    opponentuser: opponentuser,
                                                    contentinfo:
                                                        widget.contentinfo,
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
