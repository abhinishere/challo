import 'package:challo/models/comment_model.dart';
import 'package:challo/variables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CommentBottom extends StatelessWidget {
  final int upvoteCount;
  final int downvoteCount;
  final bool? whetherUpvoted, whetherDownvoted;
  final String onlineuid;
  final CommentModel comment;
  final Function? onUpvoted;
  final Function? onDownvoted;
  final Function? onReply;
  final Function? moreOptionsForOP;
  final Function? moreOptionsForOthers;

  //final bool? whetherUpvoted;
  //final bool? whetherDownvoted;
  const CommentBottom({
    required this.upvoteCount,
    required this.downvoteCount,
    required this.whetherUpvoted,
    required this.whetherDownvoted,
    required this.onlineuid,
    required this.comment,
    required this.onUpvoted,
    required this.onDownvoted,
    required this.onReply,
    required this.moreOptionsForOP,
    required this.moreOptionsForOthers,

    //required this.whetherUpvoted,
    // required this.whetherDownvoted,
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
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          (comment.blockedBy.contains(onlineuid))
              ? Text(
                  "[comment blocked]",
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: kParaColorDarkTint,
                        fontSize: 15.0,
                        letterSpacing: -0.24,
                        fontStyle: FontStyle.italic,
                      ),
                )
              : (comment.status == 'published')
                  ? Text(
                      comment.content,
                      style: styleSubTitleSmall(color: kParaColorDarkTint),
                    )
                  : Text(
                      "[comment deleted]",
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: kParaColorDarkTint,
                            fontSize: 15.0,
                            letterSpacing: -0.24,
                            fontStyle: FontStyle.italic,
                          ),
                    ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              (onReply == null)
                  ? Container()
                  : Padding(
                      padding: const EdgeInsets.only(right: 20.0),
                      child: InkWell(
                        onTap: onReply as void Function()?,
                        child: Text("Reply",
                            style: Theme.of(context).textTheme.button!.copyWith(
                                  fontSize: 15.0,
                                  color: kIconSecondaryColorDark,
                                  fontWeight: FontWeight.w700,
                                )),
                      ),
                    ),
              //const SizedBox(width: 20.0),
              Row(
                //mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onUpvoted as void Function()?,
                    child: /*Image.asset(
                      "assets/icons/arrow-up_rounded_outlined.png",
                      color: kSubTextColor,
                      height: 25,
                      width: 25,
                    )*/

                        Stack(children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (comment.likes.contains(onlineuid))
                                ? Colors.white
                                : Colors.transparent,
                          ),
                          margin: const EdgeInsets.all(7.0),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.arrow_up_circle_fill,
                        size: 25,
                        color: (comment.likes.contains(onlineuid))
                            ? kPrimaryColor
                            : kIconSecondaryColorDark,
                      ),
                    ]),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    convertToK(comment.likes.length),
                    style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                          color: kIconSecondaryColorDark,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: 20.0),
              Row(
                children: [
                  InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onDownvoted as void Function()?,
                    child: Stack(children: [
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (comment.dislikes.contains(onlineuid))
                                ? Colors.white
                                : Colors.transparent,
                          ),
                          margin: const EdgeInsets.all(7.0),
                        ),
                      ),
                      Icon(
                        CupertinoIcons.arrow_down_circle_fill,
                        size: 25,
                        color: (comment.dislikes.contains(onlineuid))
                            ? kPrimaryColor
                            : kIconSecondaryColorDark,
                      ),
                    ]),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    convertToK(comment.dislikes.length),
                    style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          fontSize: 12.0,
                          color: kIconSecondaryColorDark,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: 20.0),
              InkWell(
                onTap: (comment.posterUid == onlineuid)
                    ? moreOptionsForOP as void Function()?
                    : moreOptionsForOthers as void Function()?,
                child: const Icon(
                  CupertinoIcons.ellipsis,
                  color: kIconSecondaryColorDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
