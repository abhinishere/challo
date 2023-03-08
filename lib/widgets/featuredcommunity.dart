import 'package:challo/models/communityinfomodel.dart';
import 'package:challo/variables.dart';
import 'package:flutter/material.dart';

class FeaturedCommunity extends StatelessWidget {
  final CommunityInfoModel community;
  final Function onTapped;
  final double? width;
  final double? backgroundheight,
      foregroundposition,
      foregroundradius,
      postpictextpadding,
      namesize,
      countsize,
      descriptionsize;
  final bool? showmembercount;
  final bool? whetherassetimages;
  final int? descmaxlines;
  const FeaturedCommunity({
    required this.community,
    required this.onTapped,
    this.width,
    this.backgroundheight,
    this.foregroundposition,
    this.foregroundradius,
    this.postpictextpadding,
    this.namesize,
    this.countsize,
    this.descriptionsize,
    this.showmembercount = true,
    this.whetherassetimages = false,
    this.descmaxlines,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTapped as void Function()?,
      child: Card(
        child: Container(
          //height: 100,
          width: (width == null) ? 150 : width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                height: (backgroundheight == null) ? 50 : backgroundheight,
                // ignore: prefer_const_constructors
                margin: EdgeInsets.only(bottom: 15.0),
                child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: Container(
                          color: Colors.grey,
                          child: (whetherassetimages == false)
                              ? Image.network(
                                  community.communityBackgroundPic!,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  community.communityBackgroundPic!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      Positioned(
                        top: (foregroundposition == null)
                            ? 35
                            : foregroundposition,
                        child: CircleAvatar(
                          radius: (foregroundradius == null)
                              ? 15
                              : foregroundradius,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage: (whetherassetimages == false)
                              ? NetworkImage(
                                  community.communityPic!,
                                )
                              : AssetImage(
                                  community.communityPic!,
                                ) as ImageProvider,
                        ),
                      ),
                    ]),
              ),
              Padding(
                padding: EdgeInsets.only(
                    left: 2.0,
                    right: 2.0,
                    top: (postpictextpadding == null)
                        ? 2.0
                        : postpictextpadding!),
                child: Text("c/${community.communityName}",
                    style: Theme.of(context).textTheme.subtitle2!.copyWith(
                          fontSize: (namesize == null) ? 12.0 : namesize,
                          fontWeight: FontWeight.w700,
                          color: kHeadlineColorDark,
                        )),
              ),
              (showmembercount == true)
                  ? Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        (community.communityMemberCount == 1)
                            ? "${community.communityMemberCount} member"
                            : "${community.communityMemberCount} members",
                        style: Theme.of(context).textTheme.subtitle2!.copyWith(
                              fontSize: (countsize == null) ? 10.0 : countsize,
                              //fontWeight: FontWeight.bold,
                              //fontWeight: FontWeight.w900,
                              color: kBodyTextColorDark,
                            ),
                      ),
                    )
                  : Container(),
              Padding(
                padding: const EdgeInsets.all(2.0),
                child: Text(
                  community.communityDescription!,
                  maxLines: (descmaxlines == null) ? 1 : descmaxlines,
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                        fontSize:
                            (descriptionsize == null) ? 10.0 : descriptionsize,
                        //fontWeight: FontWeight.bold,
                        //fontWeight: FontWeight.w900,
                        color: kSubTextColor,
                        fontWeight: FontWeight.bold,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
