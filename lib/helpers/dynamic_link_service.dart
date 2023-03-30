import 'package:challo/models/link_to.dart';
import 'package:challo/variables.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';

class DynamicLinkService {
  static Future<String> createDynamicLink(bool short, LinkTo linkTo) async {
    String _linkMessage;

    final dynamicLinkParams = DynamicLinkParameters(
      link: Uri.parse(
          "https://www.challo.tv/linkToV1?type=${linkTo.type}&docName=${linkTo.docName}"),
      uriPrefix: "https://challo.page.link",
      androidParameters: const AndroidParameters(
        packageName: "tv.challo.challo",
        minimumVersion: 27,
      ),
      iosParameters: const IOSParameters(
        bundleId: "tv.challo.challo",
        appStoreId: "123456789",
        minimumVersion: "2.1.1",
      ),
      /*googleAnalyticsParameters: const GoogleAnalyticsParameters(
        source: "twitter",
        medium: "social",
        campaign: "example-promo",
      ),*/
      socialMetaTagParameters: (linkTo.image == null || linkTo.image == '')
          ? SocialMetaTagParameters(
              title: linkTo.topic,
              description: linkTo.description,
            )
          : SocialMetaTagParameters(
              title: linkTo.topic,
              description: linkTo.description,
              imageUrl: Uri.parse(linkTo.image!),
            ),
    );

    Uri url;
    if (short) {
      final shortLink =
          await FirebaseDynamicLinks.instance.buildShortLink(dynamicLinkParams);
      url = shortLink.shortUrl;
    } else {
      url = await FirebaseDynamicLinks.instance.buildLink(dynamicLinkParams);
    }

    _linkMessage = url.toString();
    return _linkMessage;
  }

  static Future<void> initPreDynamicLink() async {
    PendingDynamicLinkData? data;
    Uri? deepLink;
    data = await FirebaseDynamicLinks.instance.getInitialLink();

    if (data != null) {
      deepLink = data.link;
      var isStory = deepLink.pathSegments.contains('linkToV1');
      if (isStory) {
        String docName = deepLink.queryParameters['docName'] ?? '';
        String linkType = deepLink.queryParameters['type'] ?? '';
        if (docName != '' && linkType != '') {
          try {
            preLinkedPage = LinkTo(docName: docName, type: linkType);
            print("Linked page docName is $docName and type is $linkType");

            /*
          await FirebaseFirestore.instance
              .collection('contentcollection')
              .doc(docName)
              .get()
              .then((snapshot) => {
                    if (linkType == 'videopost')
                      {
                        linkTo = LinkTo.fromSnapshot(snapshot, 'thumbnail'),
                      }
                    else
                      {
                        linkTo = LinkTo.fromSnapshot(snapshot, 'image'),
                      },
                    linkedPage = linkTo,
                  });*/
          } catch (e) {
            print("Error is ${e.toString()}");
          }
        }
      } else {
        //error
      }
    } else {
      //no link

    }
  }
}
