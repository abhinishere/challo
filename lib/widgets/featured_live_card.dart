import 'package:challo/variables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as tago;

class FeaturedLiveCard extends StatelessWidget {
  final bool? whethercommunitypost;
  final String? communityname, communitypic;
  final String? opuid, onlineuid;
  final String? opusername, oppic;
  final String? type;
  final String? status;
  final String? topic;
  final List participatedpics;
  final List participatedusernames;
  final dynamic timeofposting;
  final Function userInfoClicked;
  final Function onReport;
  final Function onDelete;

  const FeaturedLiveCard({
    required this.whethercommunitypost,
    required this.communityname,
    required this.communitypic,
    required this.opuid,
    required this.type,
    required this.status,
    required this.topic,
    required this.participatedpics,
    required this.participatedusernames,
    required this.onlineuid,
    required this.opusername,
    required this.oppic,
    required this.userInfoClicked,
    required this.timeofposting,
    required this.onReport,
    required this.onDelete,
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
            padding: const EdgeInsets.only(
              left: 5.0,
              top: 5.0,
              right: 5.0,
            ),
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
                                : Text(
                                    (status == 'published')
                                        ? '$opusername  was  live.'
                                        : '$opusername  is  live.',
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
                                    "$opusername • $type • ${tago.format(
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
                                          fontWeight: FontWeight.w400,
                                        ),
                                  )
                                : Text(
                                    "$type • ${tago.format(
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
                                          fontWeight: FontWeight.w400,
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
          Padding(
            padding: const EdgeInsets.only(
              top: 5.0,
              left: 5.0,
              right: 5.0,
            ),
            child: Row(
              //crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                (participatedpics.length == 1)
                    ? Container(
                        decoration: new BoxDecoration(
                          shape: BoxShape.circle,
                          border: new Border.all(
                            color: kIconSecondaryColorDark,
                            width: 2.0,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: kIconSecondaryColorDark,
                          radius: 30,
                          backgroundImage: const AssetImage(
                              'assets/images/default-profile-pic.png'),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.transparent,
                            backgroundImage: NetworkImage(participatedpics[0]),
                          ),
                        ),
                      )
                    : (participatedpics.length == 2)
                        ? Container(
                            height: 60.0,
                            width: 60.0,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: 20.0,
                                  top: 15.0,
                                  child: Container(
                                    decoration: new BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: new Border.all(
                                        color: kIconSecondaryColorDark,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: kIconSecondaryColorDark,
                                      radius: 19,
                                      backgroundImage: const AssetImage(
                                          'assets/images/default-profile-pic.png'),
                                      child: CircleAvatar(
                                        radius: 19,
                                        backgroundColor: Colors.transparent,
                                        backgroundImage:
                                            NetworkImage(participatedpics[1]),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: new BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: new Border.all(
                                      color: kIconSecondaryColorDark,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    backgroundColor: kIconSecondaryColorDark,
                                    radius: 19,
                                    backgroundImage: const AssetImage(
                                        'assets/images/default-profile-pic.png'),
                                    child: CircleAvatar(
                                      radius: 19,
                                      backgroundColor: Colors.transparent,
                                      backgroundImage:
                                          NetworkImage(participatedpics[0]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            height: 60.0,
                            width: 60.0,
                            child: Stack(
                              children: [
                                Positioned(
                                  //bottom
                                  left: 15.0,
                                  top: 22.0,
                                  child: Container(
                                    decoration: new BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: new Border.all(
                                        color: kIconSecondaryColorDark,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: kIconSecondaryColorDark,
                                      radius: 16,
                                      backgroundImage: const AssetImage(
                                          'assets/images/default-profile-pic.png'),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.transparent,
                                        backgroundImage:
                                            NetworkImage(participatedpics[2]),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  //pic at top right
                                  left: 25.0,
                                  child: Container(
                                    decoration: new BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: new Border.all(
                                        color: kIconSecondaryColorDark,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: kIconSecondaryColorDark,
                                      radius: 16,
                                      backgroundImage: const AssetImage(
                                          'assets/images/default-profile-pic.png'),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.transparent,
                                        backgroundImage:
                                            NetworkImage(participatedpics[1]),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 25,
                                  child: Container(
                                    decoration: new BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: new Border.all(
                                        color: kIconSecondaryColorDark,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: CircleAvatar(
                                      backgroundColor: kIconSecondaryColorDark,
                                      radius: 16,
                                      backgroundImage: const AssetImage(
                                          'assets/images/default-profile-pic.png'),
                                      child: CircleAvatar(
                                        radius: 16,
                                        backgroundColor: Colors.transparent,
                                        backgroundImage:
                                            NetworkImage(participatedpics[0]),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                const SizedBox(
                  width: 20.0,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic!,
                        style: styleTitleSmall(),
                      ),
                      for (String username in participatedusernames)
                        Text(
                          username,
                          style: Theme.of(context).textTheme.caption!.copyWith(
                              fontSize: 15.0,
                              color: kSubTextColor,
                              letterSpacing: -0.24,
                              fontWeight: FontWeight.w400),
                        )
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
