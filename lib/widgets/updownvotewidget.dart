import 'package:challo/variables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UpDownVoteWidget extends StatelessWidget {
  //final int upvotes;
  //final int downvotes;
  final int upvoteCount;
  final int downvoteCount;
  final int commentCount;
  final Function? onUpvoted;
  final Function? onDownvoted;
  final Function? onShared;
  final Function? onComment;
  final bool? whetherUpvoted, whetherDownvoted;
  final bool? whetherIconsBig;
  const UpDownVoteWidget({
    //required this.upvotes,
    //required this.downvotes,
    required this.upvoteCount,
    required this.downvoteCount,
    required this.commentCount,
    required this.onUpvoted,
    required this.onDownvoted,
    required this.onShared,
    required this.whetherUpvoted,
    required this.whetherDownvoted,
    required this.onComment,
    this.whetherIconsBig,
  });

  convertToK(int count) {
    String kCount = '';
    if (count > 1000) {
      kCount = '${count / 1000}K';
    } else {
      kCount = '$count';
    }
    return kCount;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Container(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              //mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onUpvoted as void Function()?,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Stack(children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (whetherUpvoted!)
                                ? Colors.white
                                : Colors.transparent,
                          ),
                          margin: const EdgeInsets.all(7.0),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.arrow_up_circle_fill,
                        size: (whetherIconsBig == null ||
                                whetherIconsBig == false)
                            ? 25
                            : 30,
                        color: whetherUpvoted!
                            ? kPrimaryColor
                            : kIconSecondaryColorDark,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  convertToK(upvoteCount),
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: kIconSecondaryColorDark,
                      ),
                ),
              ],
            ),
            Row(
              children: [
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDownvoted as void Function()?,
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Stack(children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (whetherDownvoted!)
                                ? Colors.white
                                : Colors.transparent,
                          ),
                          margin: const EdgeInsets.all(7.0),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.arrow_down_circle_fill,
                        size: (whetherIconsBig == null ||
                                whetherIconsBig == false)
                            ? 25
                            : 30,
                        color: whetherDownvoted!
                            ? kPrimaryColor
                            : kIconSecondaryColorDark,
                      ),
                    ]),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  convertToK(downvoteCount),
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                        fontSize: 12.0,
                        color: kIconSecondaryColorDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            InkWell(
              onTap: onComment as void Function()?,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.message,
                      size:
                          (whetherIconsBig == null || whetherIconsBig == false)
                              ? 20
                              : 25,
                      color: kIconSecondaryColorDark,
                    ),
                    const SizedBox(width: 10.0),
                    Text(
                      convertToK(commentCount),
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            fontSize: 12.0,
                            color: kIconSecondaryColorDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            InkWell(
              onTap: onShared as void Function()?,
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.share_solid,
                      size:
                          (whetherIconsBig == null || whetherIconsBig == false)
                              ? 20
                              : 25,
                      color: kIconSecondaryColorDark,
                    ),
                    /*Image.asset(
                      "assets/icons/share_thick_outlined.png",
                      height: 20,
                      width: 20,
                      color: kSubTextColor,
                    ),*/
                    const SizedBox(width: 5.0),
                    Text(
                      'Share',
                      style: Theme.of(context).textTheme.button!.copyWith(
                            fontSize: 12.0,
                            color: kIconSecondaryColorDark,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
