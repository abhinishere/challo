import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/variables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tago;

class FeaturedTextCard extends StatelessWidget {
  final bool whethercommunitypost;
  final String? onlineuid;
  final String? opuid;
  final String? opusername;
  final String? oppic;
  final String? topic;
  final String? description;
  final String? image;
  final String? communityName;
  final String? communitypic;
  final dynamic timeofposting;
  final Function onReport;
  final Function? onDelete;
  final Function? onEdit;
  final Function? onTapImage;
  final Function userInfoClicked;

  const FeaturedTextCard({
    required this.whethercommunitypost,
    required this.onlineuid,
    required this.opuid,
    required this.opusername,
    required this.oppic,
    required this.topic,
    required this.description,
    this.image,
    this.communityName,
    this.communitypic,
    required this.timeofposting,
    required this.onReport,
    required this.onDelete,
    required this.onEdit,
    required this.onTapImage,
    required this.userInfoClicked,
  });

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
                                ? Text('c/$communityName',
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
          (image == '')
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        topic!,
                        style: styleTitleSmall(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: styleSubTitleSmall()),
                    )
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              topic!,
                              style: styleTitleSmall(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Text(description!,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: styleSubTitleSmall()),
                          )
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5.0),
                        child: InkWell(
                          onTap: onTapImage as void Function()?,
                          child: Container(
                            height: 50,
                            width: 100,
                            child: CachedNetworkImage(
                              imageUrl: image!,
                              progressIndicatorBuilder:
                                  (context, url, downloadProgress) =>
                                      const CupertinoActivityIndicator(
                                color: kBackgroundColorDark2,
                              ),
                            ),
                            //Image.network(image!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          /* : Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Text(
                        topic!,
                        style: Theme.of(context).textTheme.subtitle1!.copyWith(
                              fontSize: 15,
                              //fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                    )),
                    Padding(
                      padding: const EdgeInsets.only(right: 5.0),
                      child: InkWell(
                        onTap: null,
                        child: Container(
                          height: 50,
                          width: 100,
                          child: Image.network(image!),
                        ),
                      ),
                    ),
                  ],
                ),*/
        ],
      ),
    );
  }
}
