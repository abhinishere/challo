import 'package:challo/pages/profilepage.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FollowingPage extends StatefulWidget {
  final String uid;
  final String username;
  const FollowingPage({
    required this.uid,
    required this.username,
  });

  @override
  State<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> {
  bool dataisthere = false;
  @override
  void initState() {
    super.initState();
    getFollowersData();
  }

  getFollowersData() async {
    setState(() {
      dataisthere = true;
    });
  }

  Widget followersStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: usercollection
          .doc(widget.uid)
          .collection('following')
          .orderBy('followingSince', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting following profiles data");
          return const Center(
              child: CupertinoActivityIndicator(
            color: kDarkPrimaryColor,
          ));
        }
        if (snapshot.data.docs.length == 0) {
          return Center(child: Container());
        }
        return ListView.builder(
          reverse: false,
          physics: const ScrollPhysics(),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: snapshot.data.docs.length,
          itemBuilder: (BuildContext context, int index) {
            var profile = snapshot.data.docs[index];

            return InkWell(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfilePage(
                          whetherShowArrow: true, uid: profile['uid']))),
              child: Card(
                color: kCardBackgroundColor,
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  leading: Container(
                    decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      border: new Border.all(
                        color: Colors.white70,
                        width: 2.0,
                      ),
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.grey.shade500,
                      radius: 30,
                      backgroundImage: const AssetImage(
                          'assets/images/default-profile-pic.png'),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.transparent,
                        backgroundImage: NetworkImage(profile['profilepic']),
                      ),
                    ),
                  ),
                  title: Text(
                    (profile['name'] == "" || profile['name'] == null)
                        ? "${profile['username']}"
                        : "${profile['name']}",
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          fontSize: 15,
                          //fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  subtitle: (profile['name'] == "" || profile['name'] == null)
                      ? Container()
                      : Text(
                          "${profile['username']}",
                          style:
                              Theme.of(context).textTheme.subtitle1!.copyWith(
                                    fontSize: 12,
                                    //fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                        ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("u/${widget.username}/Following"),
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back),
          onTap: () => Navigator.pop(context),
        ),
      ),
      body: (dataisthere == false)
          ? const CupertinoActivityIndicator(
              color: kDarkPrimaryColor,
            )
          : SafeArea(
              child: Container(
                child: Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: followersStream(),
                ),
              ),
            ),
    );
  }
}
