import 'package:challo/pages/community_page.dart';
import 'package:challo/pages/profilepage.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FollowersPage extends StatefulWidget {
  final String uid;
  final String username;
  final int initialIndex;
  const FollowersPage({
    required this.uid,
    required this.username,
    required this.initialIndex,
  });

  @override
  State<FollowersPage> createState() => _FollowersPageState();
}

class _FollowersPageState extends State<FollowersPage> {
  final GlobalKey<ScaffoldState> _followersKey = GlobalKey();

  //bool dataisthere = false;

  Widget followersStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: usercollection
          .doc(widget.uid)
          .collection('followers')
          .orderBy('followedOn', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting followed profiles data");
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

  Widget followingStream() {
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

  communitiesStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: usercollection
          .doc(widget.uid)
          .collection('communities')
          .orderBy('joinedSince', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting communities data");
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

            return InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CommunityPage(
                        whetherjustcreated: false,
                        communityname: community['name'])),
              ),
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
                        backgroundImage: NetworkImage(community['mainimage']),
                      ),
                    ),
                  ),
                  title: Text(
                    "c/${community['name']}",
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          fontSize: 15,
                          //fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  subtitle: Text(
                    "${community['description']}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
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
    return DefaultTabController(
      initialIndex: widget.initialIndex,
      length: 3,
      child: Scaffold(
        key: _followersKey,
        appBar: AppBar(
          bottom: TabBar(
              isScrollable: true,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: Theme.of(context).textTheme.labelMedium!.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 15.0,
                    color: kHeadlineColorDark,
                    letterSpacing: -0.24,
                  ),
              indicatorColor: kHeadlineColorDark,
              tabs: const [
                Tab(
                  text: "Followers",
                ),
                Tab(
                  text: "Following",
                ),
                Tab(
                  text: "Communities",
                ),
              ]),
          title: Text("u/${widget.username}"),
          leading: GestureDetector(
            child: const Icon(Icons.arrow_back),
            onTap: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: TabBarView(
            children: [
              followersStream(),
              followingStream(),
              communitiesStream(),
            ],
          ),
        ),
      ),
    );
  }
}
