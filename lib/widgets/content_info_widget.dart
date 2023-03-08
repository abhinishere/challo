import 'package:flutter/material.dart';
import 'package:challo/widgets/profile_widget.dart';
import 'package:challo/models/content_info_model.dart';
import 'package:challo/models/user_info_model.dart';

class ContentInfoWidget extends StatelessWidget {
  final String? formattype;
  final UserInfoModel? user0;
  final UserInfoModel? user1;
  final ContentInfoModel? contentinfo;
  const ContentInfoWidget(
      {required this.formattype,
      required this.user0,
      this.user1,
      required this.contentinfo});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        child: ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          children: [
            const SizedBox(
              height: 20,
            ),
            (formattype == "Debate")
                ? Padding(
                    padding:
                        const EdgeInsets.only(bottom: 16, right: 16, left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ProfileWidget(
                            showverifiedtick: false,
                            profileverified: user0!.profileverified,
                            imageUrl: user0!.pic,
                            username: user0!.username,
                            variation: true,
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Text("vs.",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child: ProfileWidget(
                            showverifiedtick: false,
                            profileverified: user1!.profileverified,
                            imageUrl: user1!.pic,
                            username: user1!.username,
                            variation: true,
                          ),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding:
                        const EdgeInsets.only(bottom: 16, right: 16, left: 16),
                    child: ProfileWidget(
                      showverifiedtick: false,
                      profileverified: user0!.profileverified,
                      imageUrl: user0!.pic,
                      username: user0!.username,
                      variation: true,
                    ),
                  ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, right: 16, left: 16),
              child: Card(
                color: Colors.grey.shade800,
                child: Container(
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ...ListTile.divideTiles(
                        color: Colors.grey,
                        tiles: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            title: const Text(
                              "Topic:",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(contentinfo!.subject!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                          ListTile(
                            title: const Text("Description:",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18)),
                            subtitle: Text(contentinfo!.description!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                          (formattype == "Debate")
                              ? ListTile(
                                  title: const Text("You're debating...",
                                      style: TextStyle(
                                          color: Colors.white, fontSize: 18)),
                                  subtitle: Text(user0!.selectedRadioStand!,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                )
                              : Container(),
                          ListTile(
                            title: const Text("Category:",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 18)),
                            subtitle: Text(contentinfo!.category!,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
