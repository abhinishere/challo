import 'dart:convert';

import 'package:challo/variables.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityAbout extends StatefulWidget {
  final String communityName;
  final String longdescriptionurl;
  const CommunityAbout({
    required this.communityName,
    required this.longdescriptionurl,
  });
  @override
  State<CommunityAbout> createState() => _CommunityAboutState();
}

class _CommunityAboutState extends State<CommunityAbout> {
  bool dataisthere = false;
  late String aboutText;

  @override
  void initState() {
    super.initState();
    getaboutdata();
  }

  getaboutdata() async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('communities')
        .child(widget.communityName)
        .child('${widget.communityName}_long_description');
    await ref.getData().then((value) {
      aboutText = utf8.decode(value!.toList());
    });
    print("Got aboutText");
    setState(() {
      dataisthere = true;
    });
  }

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
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
      ),
      body: SafeArea(
        child: (dataisthere == false)
            ? const Center(
                child: CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              ))
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "c/${widget.communityName} about",
                        style: Theme.of(context).textTheme.headline1!.copyWith(
                              fontSize: 25.0,
                            ),
                      ),
                      Divider(
                        thickness: 1,
                        color: Colors.grey.shade800,
                      ),
                      MarkdownBody(
                        data: aboutText,
                        styleSheet: styleSheetforMarkdown(context),
                        onTapLink: (text, url, title) async {
                          openBrowserURL(url: url!);
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
