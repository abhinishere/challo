import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BlockedCommunities extends StatefulWidget {
  final String? profileuid;
  const BlockedCommunities({
    required this.profileuid,
  });
  @override
  State<BlockedCommunities> createState() => _BlockedCommunitiesState();
}

class _BlockedCommunitiesState extends State<BlockedCommunities> {
  unblockCommunity(String? communityName) async {
    List<String> blockedcommunities = [];
    var profiledoc = await usercollection.doc(widget.profileuid).get();
    blockedcommunities = List.from(profiledoc['blockedcommunities']);
    if (blockedcommunities.contains(communityName)) {
      await usercollection.doc(widget.profileuid).update({
        'blockedcommunities': FieldValue.arrayRemove([communityName]),
      });
    }
    var blockeddoc = await usercollection
        .doc(widget.profileuid)
        .collection('blockedcommunitieslist')
        .doc(communityName)
        .get();

    if (!blockeddoc.exists) {
      //do nothing if doc doesn't exist for some reason
    } else {
      usercollection
          .doc(widget.profileuid)
          .collection('blockedcommunitieslist')
          .doc(communityName)
          .delete();
    }
    await communitycollection.doc(communityName).update({
      'blockedby': FieldValue.arrayRemove([widget.profileuid]),
    });
  }

  Widget blockedCommunitiesStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: usercollection
          .doc(widget.profileuid)
          .collection('blockedcommunitieslist')
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting blocked communities data");
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

            return Card(
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
                      backgroundImage: NetworkImage(community['communitypic']),
                    ),
                  ),
                ),
                title: Text(
                  "${community['communityName']}",
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        fontSize: 15,
                        //fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                subtitle: Text(
                  "${community['description']}",
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        fontSize: 12,
                        //fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                ),
                trailing: TextButton(
                  onPressed: () {
                    print("unblocking ${community['communityName']}");
                    unblockCommunity(community['communityName']);
                  },
                  child: Text(
                    "Unblock",
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColorTint2,
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
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(Icons.arrow_back),
        ),
        title: const Text("Blocked Communities"),
      ),
      body: SafeArea(
        child: Container(
          child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: blockedCommunitiesStream()),
        ),
      ),
    );
  }
}
