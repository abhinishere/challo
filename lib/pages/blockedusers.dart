import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BlockedUsers extends StatefulWidget {
  final String? profileuid;
  const BlockedUsers({
    required this.profileuid,
  });
  @override
  State<BlockedUsers> createState() => _BlockedUsersState();
}

class _BlockedUsersState extends State<BlockedUsers> {
  unblockUser(String? unblockuid) async {
    List<String> blockedusers = [];
    var profiledoc = await usercollection.doc(widget.profileuid).get();
    blockedusers = List.from(profiledoc['blockedusers']);
    if (blockedusers.contains(unblockuid)) {
      await usercollection.doc(widget.profileuid).update({
        'blockedusers': FieldValue.arrayRemove([unblockuid]),
      });
      var blockeddoc = await usercollection
          .doc(widget.profileuid)
          .collection('blockeduserslist')
          .doc(unblockuid)
          .get();

      if (!blockeddoc.exists) {
        //do nothing if doc doesn't exist for some reason
      } else {
        usercollection
            .doc(widget.profileuid)
            .collection('blockeduserslist')
            .doc(unblockuid)
            .delete();
      }
      await usercollection.doc(unblockuid).update({
        'hiddenusers': FieldValue.arrayRemove([widget.profileuid]),
      });
    }
  }

  Widget blockedAccountsStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: usercollection
          .doc(widget.profileuid)
          .collection('blockeduserslist')
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          print("getting blocked profiles data");
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
                      backgroundImage: NetworkImage(profile['blockeduserpic']),
                    ),
                  ),
                ),
                title: Text(
                  (profile['blockedname'] == "" ||
                          profile['blockedname'] == null)
                      ? "${profile['blockedusername']}"
                      : "${profile['blockedname']}",
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        fontSize: 15,
                        //fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                ),
                subtitle: (profile['blockedname'] == "" ||
                        profile['blockedname'] == null)
                    ? Container()
                    : Text(
                        "${profile['blockedusername']}",
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                              fontSize: 12,
                              //fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                      ),
                trailing: TextButton(
                  onPressed: () {
                    print("unblocking ${profile['blockedusername']}");
                    unblockUser(profile['blockeduid']);
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
        title: const Text("Blocked Users"),
      ),
      body: SafeArea(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: blockedAccountsStream(),
          ),
        ),
      ),
    );
  }
}
