import 'package:challo/pages/profilepage.dart';
import 'package:challo/variables.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CommunityMods extends StatefulWidget {
  final String communityName;

  const CommunityMods({
    required this.communityName,
  });
  @override
  State<CommunityMods> createState() => _CommunityModsState();
}

class _CommunityModsState extends State<CommunityMods> {
  bool dataisthere = false;
  Future<QuerySnapshot>? modsnapshot;
  @override
  void initState() {
    super.initState();
    getmodsdata();
  }

  getmodsdata() async {
    modsnapshot =
        communitycollection.doc(widget.communityName).collection('mods').get();
    setState(() {
      dataisthere = true;
    });
  }

  fetchmodstream() {
    return FutureBuilder<QuerySnapshot>(
        future: modsnapshot,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              ),
            );
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
              var mod = snapshot.data.docs[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: ((context) => ProfilePage(
                                uid: mod['uid'],
                                whetherShowArrow: true,
                              ))));
                },
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
                        radius: 20,
                        backgroundImage: const AssetImage(
                            'assets/images/default-profile-pic.png'),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.transparent,
                          backgroundImage: NetworkImage(mod['profilepic']),
                        ),
                      ),
                    ),
                    title: Text(
                      "${mod['username']}",
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            fontSize: 15,
                            //fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                  ),
                ),
              );
            },
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Moderators"),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back,
          ),
        ),
      ),
      body: SafeArea(
        child: (dataisthere == false)
            ? const Center(
                child: CupertinoActivityIndicator(
                  color: kDarkPrimaryColor,
                ),
              )
            : Container(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: fetchmodstream(),
                ),
              ),
      ),
    );
  }
}
