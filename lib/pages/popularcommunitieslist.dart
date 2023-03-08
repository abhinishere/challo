import 'package:challo/pages/community_page.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PopularCommunitiesList extends StatefulWidget {
  @override
  State<PopularCommunitiesList> createState() => _PopularCommunitiesListState();
}

class _PopularCommunitiesListState extends State<PopularCommunitiesList> {
  late String onlineuid, onlineusername, onlinepic;
  bool dataisthere = false;

  getuserdata() async {
    onlineuid = FirebaseAuth.instance.currentUser!.uid;
    var userdocs = await usercollection.doc(onlineuid).get();
    onlineusername = userdocs['username'];
    onlinepic = userdocs['profilepic'];
    setState(() {
      dataisthere = true;
    });
  }

  @override
  void initState() {
    super.initState();
    getuserdata();
  }

  Widget topCommunities() {
    return StreamBuilder<QuerySnapshot>(
      stream: communitycollection
          .where('toppriority', isGreaterThan: 50)
          .orderBy('toppriority', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting community data");
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
            var community = snapshot.data.docs[index];
            if (community['status'] == 'published') {
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CommunityPage(
                            whetherjustcreated: false,
                            communityname: community['name'],
                          )),
                ),
                child: Card(
                  color: Theme.of(context).primaryIconTheme.color,
                  child: Container(
                    //height: 100,
                    //width: 150,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 10.0),
                          child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  color: Colors.grey,
                                  child: Image.network(
                                    community['backgroundimage'],
                                    fit: BoxFit.fitWidth,
                                    height: 100,
                                    width: MediaQuery.of(context).size.width,
                                  ),
                                ),
                                Positioned(
                                  top: 85,
                                  left: 10.0,
                                  child: CircleAvatar(
                                    radius: 15,
                                    backgroundColor: Colors.grey.shade800,
                                    backgroundImage: NetworkImage(
                                      community['mainimage'],
                                    ),
                                  ),
                                ),
                              ]),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 10.0, right: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("c/${community['name']}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2!
                                      .copyWith(
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      )),
                              TextButton(
                                onPressed: () async {
                                  if (community['memberuids']
                                      .contains(onlineuid)) {
                                    communitycollection
                                        .doc(community['name'])
                                        .update({
                                      'memberuids':
                                          FieldValue.arrayRemove([onlineuid])
                                    });
                                    var usercommunitydocs = await usercollection
                                        .doc(onlineuid)
                                        .collection('communities')
                                        .doc(community['name'])
                                        .get();
                                    if (usercommunitydocs.exists) {
                                      usercollection
                                          .doc(onlineuid)
                                          .collection('communities')
                                          .doc(community['name'])
                                          .delete();
                                    }
                                  } else {
                                    communitycollection
                                        .doc(community['name'])
                                        .update({
                                      'memberuids':
                                          FieldValue.arrayUnion([onlineuid])
                                    });
                                    var usercommunitydocs = await usercollection
                                        .doc(onlineuid)
                                        .collection('communities')
                                        .doc(community['name'])
                                        .get();
                                    if (!usercommunitydocs.exists) {
                                      usercollection
                                          .doc(onlineuid)
                                          .collection('communities')
                                          .doc(community['name'])
                                          .set({});
                                    }
                                  }
                                },
                                child: Text(
                                    (community['memberuids']
                                            .contains(onlineuid))
                                        ? "Leave"
                                        : "Join",
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.bold,
                                          color: kPrimaryColor,
                                        )),
                              )
                            ],
                          ),
                        ),
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 10.0, right: 10.0),
                          child: Text(
                            (community['memberuids'].length == 1)
                                ? "${community['memberuids'].length} member"
                                : "${community['memberuids'].length} members",
                            style:
                                Theme.of(context).textTheme.subtitle2!.copyWith(
                                      fontSize: 10,
                                      //fontWeight: FontWeight.bold,
                                      //fontWeight: FontWeight.w900,
                                      color: kBodyTextColorDark,
                                    ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 10.0, right: 10.0, bottom: 10.0),
                          child: Text(
                            "${community['description']}",
                            maxLines: 1,
                            style:
                                Theme.of(context).textTheme.subtitle2!.copyWith(
                                      fontSize: 10,
                                      //fontWeight: FontWeight.bold,
                                      //fontWeight: FontWeight.w900,
                                      color: Colors.white70,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              return Container();
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: (dataisthere == false)
            ? const Center(
                child: CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              ))
            : Container(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Top Communities",
                        style: Theme.of(context).textTheme.headline2!.copyWith(
                              color: Colors.white,
                              fontSize: 25.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                      ),
                      Divider(
                        thickness: 1,
                        color: Colors.grey.shade800,
                      ),
                      Expanded(child: topCommunities()),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
