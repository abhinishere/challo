import 'package:challo/helpers/dynamic_link_service.dart';
import 'package:challo/models/link_to.dart';
import 'package:share/share.dart';

class ShareService {
  static Future<void> shareContent(String docName, String type, String topic,
      String description, String? image) async {
    String? generatedLink;
    await DynamicLinkService.createDynamicLink(
      true,
      LinkTo(
        docName: docName,
        type: type,
        topic: topic,
        description: description,
        image: image,
      ),
    ).then((linkForSharing) => {
          generatedLink = linkForSharing,
          print(generatedLink),
          if (generatedLink != null)
            {
              Share.share("$topic; View on Challo app - $generatedLink"),
            }
          else
            {
              //error sharing
            }
        });
  }
}
