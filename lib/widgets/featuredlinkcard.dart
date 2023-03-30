import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/variables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tago;

class FeaturedLinkCard extends StatelessWidget {
  final bool? whethercommunitypost;
  final String? onlineuid,
      opuid,
      opusername,
      oppic,
      image,
      topic,
      domainname,
      communityname,
      communitypic;
  final dynamic timeofposting;
  final Function launchBrowser;
  final Function onReport;
  final Function onDelete;
  final Function onEdit;
  final Function userInfoClicked;

  const FeaturedLinkCard({
    required this.whethercommunitypost,
    this.communityname,
    this.communitypic,
    required this.onlineuid,
    required this.opuid,
    required this.opusername,
    required this.oppic,
    required this.image,
    required this.topic,
    required this.timeofposting,
    required this.domainname,
    required this.launchBrowser,
    required this.onReport,
    required this.onDelete,
    required this.onEdit,
    required this.userInfoClicked,
  });

  stripWWW() {
    String trimmedDomain = '';
    if (domainname != null) {
      if (domainname!.startsWith('www.')) {
        trimmedDomain = domainname!.replaceFirst("www.", "");
      } else if (domainname!.startsWith('https://www.')) {
        trimmedDomain = domainname!.replaceFirst("https://www.", "");
      } else if (domainname!.startsWith('http://www.')) {
        trimmedDomain = domainname!.replaceFirst("http://www.", "");
      } else if (domainname!.startsWith('https://')) {
        trimmedDomain = domainname!.replaceFirst("https://", "");
      } else if (domainname!.startsWith('http://')) {
        trimmedDomain = domainname!.replaceFirst("http://", "");
      } else {
        trimmedDomain = domainname!;
      }
    }
    return trimmedDomain;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 5.0, top: 5.0, right: 5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: userInfoClicked as void Function()?,
                  child: Row(
                    children: [
                      Container(
                        decoration: new BoxDecoration(
                          shape: BoxShape.circle,
                          border: new Border.all(
                            color: kIconSecondaryColorDark,
                            width: 2.0,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: kIconSecondaryColorDark,
                          radius: 13.0,
                          backgroundImage: const AssetImage(
                              'assets/images/default-profile-pic.png'),
                          child: CircleAvatar(
                            radius: 13.0,
                            backgroundColor: Colors.transparent,
                            backgroundImage: (whethercommunitypost == true)
                                ? NetworkImage(communitypic!)
                                : NetworkImage(oppic!),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 5.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            (whethercommunitypost == true)
                                ? Text('c/$communityname',
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                          fontSize: 15.0,
                                          color: kHeadlineColorDark,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.24,
                                        ))
                                : Text(opusername!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .subtitle2!
                                        .copyWith(
                                          fontSize: 15.0,
                                          color: kHeadlineColorDark,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: -0.24,
                                        )),
                            (whethercommunitypost == true)
                                ? Text(
                                    "$opusername • ${tago.format(
                                      timeofposting.toDate(),
                                      locale: 'en_short',
                                    )} •",
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption!
                                        .copyWith(
                                          fontSize: 13.0,
                                          color: kSubTextColor,
                                          letterSpacing: -0.08,
                                        ),
                                  )
                                : Text(
                                    "• ${tago.format(
                                      timeofposting.toDate(),
                                      locale: 'en_short',
                                    )} •",
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption!
                                        .copyWith(
                                          fontSize: 13.0,
                                          color: kSubTextColor,
                                          letterSpacing: -0.08,
                                        ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                (onlineuid == opuid)
                    ? InkWell(
                        onTap: onDelete as void Function()?,
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            color: kIconSecondaryColorDark,
                          ),
                        ),
                      )
                    : InkWell(
                        onTap: onReport as void Function()?,
                        child: const Padding(
                          padding: EdgeInsets.all(5.0),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            color: kIconSecondaryColorDark,
                          ),
                        ),
                      )
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Text(
                  topic!,
                  style: styleTitleSmall(),
                ),
              )),
              Padding(
                padding: const EdgeInsets.only(right: 5.0),
                child: InkWell(
                    onTap: launchBrowser as void Function()?,
                    child: CachedNetworkImage(
                      imageUrl: image!,
                      progressIndicatorBuilder:
                          (context, url, downloadProgress) =>
                              const CupertinoActivityIndicator(
                        color: kBackgroundColorDark2,
                      ),
                      imageBuilder: (context, imageProvider) => Container(
                        height: 50,
                        width: 100,
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            stripWWW(),
                            style:
                                Theme.of(context).textTheme.caption!.copyWith(
                                      fontSize: 13.0,
                                      color: kHeadlineColorDark,
                                      backgroundColor:
                                          kBackgroundColorDark2, //only for dark mode
                                      letterSpacing: -0.08,
                                    ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )

                    /*Container(
                    height: 50,
                    width: 100,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                      image: NetworkImage(image!),
                      fit: BoxFit.cover,
                    )),
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        domainname!,
                        style: Theme.of(context).textTheme.caption!.copyWith(
                              fontSize: 13.0,
                              color: kHeadlineColorDark,
                              backgroundColor:
                                  kBackgroundColorDark2, //only for dark mode
                              letterSpacing: -0.08,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),*/
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
