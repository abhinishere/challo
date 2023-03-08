import 'package:challo/pages/community_page.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FeaturedCommunities extends StatefulWidget {
  final String uid;
  const FeaturedCommunities({
    required this.uid,
  });

  @override
  State<FeaturedCommunities> createState() => _FeaturedCommunitiesState();
}

class _FeaturedCommunitiesState extends State<FeaturedCommunities> {
  communitiesStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: communitycollection
          .where('featuredpriority', isGreaterThan: 50)
          .orderBy('featuredpriority', descending: true)
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
            bool whetherjoined = (community['memberuids']).contains(widget.uid);
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
                  trailing: IconButton(
                    onPressed: () async {
                      if (community['memberuids'].contains(widget.uid)) {
                        print("User already present; now removing...");
                        //remove the user from community
                        await communitycollection
                            .doc(community['name'])
                            .update({
                          'memberuids': FieldValue.arrayRemove([widget.uid]),
                        });
                        var usercommunitydocs = await usercollection
                            .doc(widget.uid)
                            .collection('communities')
                            .doc(community['name'])
                            .get();
                        if (usercommunitydocs.exists) {
                          usercollection
                              .doc(widget.uid)
                              .collection('communities')
                              .doc(community['name'])
                              .delete();
                        }
                      } else {
                        var time = DateTime.now();
                        //add user to community
                        communitycollection.doc(community['name']).update({
                          'memberuids': FieldValue.arrayUnion([widget.uid])
                        });
                        var usercommunitydocs = await usercollection
                            .doc(widget.uid)
                            .collection('communities')
                            .doc(community['name'])
                            .get();
                        if (!usercommunitydocs.exists) {
                          usercollection
                              .doc(widget.uid)
                              .collection('communities')
                              .doc(community['name'])
                              .set({
                            'name': community['name'],
                            'mainimage': community['mainimage'],
                            'backgroundimage': community['backgroundimage'],
                            'joinedSince': time,
                            'description': community['description'],
                          });
                        }
                      }
                    },
                    icon: (whetherjoined == false)
                        ? const Icon(
                            CupertinoIcons.add_circled_solid,
                            color: kIconSecondaryColorDark,
                          )
                        : Stack(children: [
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                margin: const EdgeInsets.all(3.0),
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.check_mark_circled_solid,
                              color: kPrimaryColor,
                            ),
                          ]),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Featured Communities"),
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back),
          onTap: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: communitiesStream(),
      ),
    );
  }
}
