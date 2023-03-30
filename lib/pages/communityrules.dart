import 'dart:convert';
import 'package:challo/variables.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';

class CommunityRules extends StatefulWidget {
  final String communityName;
  final String rulesurl;
  const CommunityRules({
    required this.communityName,
    required this.rulesurl,
  });
  @override
  State<CommunityRules> createState() => _CommunityRulesState();
}

class _CommunityRulesState extends State<CommunityRules> {
  late String rulesText;
  bool dataisthere = false;

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  void initState() {
    super.initState();
    getrulesdata();
  }

  getrulesdata() async {
    Reference ref = FirebaseStorage.instance
        .ref()
        .child('communities')
        .child(widget.communityName)
        .child('${widget.communityName}_rules');
    await ref.getData().then((value) {
      rulesText = utf8.decode(value!.toList());
    });
    print("Got rulesText");
    setState(() {
      dataisthere = true;
    });
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
                        "c/${widget.communityName} rules",
                        style: Theme.of(context).textTheme.headline1!.copyWith(
                              fontSize: 25.0,
                            ),
                      ),
                      Divider(
                        thickness: 1,
                        color: Colors.grey.shade800,
                      ),
                      MarkdownBody(
                        data: rulesText,
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
