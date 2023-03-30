import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/models/lits_model.dart';
import 'package:challo/pages/preview_image_plain.dart';
import 'package:challo/variables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class EventWidget extends StatelessWidget {
  final LitsModel lit;
  final bool whetherOP;
  final Function editEvent;

  const EventWidget({
    required this.lit,
    required this.whetherOP,
    required this.editEvent,
  });

  String dateTimeConvert(DateTime timestamp) {
    final dynamic currentTime = DateTime.now();
    String displayTime = '';
    int yearDiff = currentTime.year - timestamp.year;
    int monthDiff = currentTime.month - timestamp.month;
    int dayDiff = currentTime.difference(timestamp).inDays;
    int hourDiff = currentTime.difference(timestamp).inHours;

    if (yearDiff > 1) {
      displayTime = DateFormat('yyyy-MM-dd h:mm a').format(timestamp);
    } else if (monthDiff > 1) {
      displayTime = DateFormat('MMM dd h:mm a').format(timestamp);
    } else if (dayDiff > 7) {
      displayTime = DateFormat('MMM dd h:mm a').format(timestamp);
    } else if (dayDiff > 1) {
      displayTime = DateFormat('EEE h:mm a').format(timestamp);
    } else if (hourDiff > 24) {
      displayTime = DateFormat('EEE h:mm a').format(timestamp);
    } else {
      displayTime = DateFormat('h:mm a').format(timestamp);
    }

    return displayTime;
  }

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        bottom: 10.0,
        right: 10.0,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 15,
                width: 15,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: kIconSecondaryColorDark,
                ),
              ),
              const SizedBox(
                width: 10.0,
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        lit.title,
                        style: styleTitleSmall(),
                      ),
                    ),
                    (whetherOP == false)
                        ? Container()
                        : Padding(
                            padding:
                                const EdgeInsets.only(right: 10.0, left: 5.0),
                            child: InkWell(
                                onTap: editEvent as void Function()?,
                                child: const Icon(CupertinoIcons.ellipsis)),
                          )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 10.0,
          ),
          IntrinsicHeight(
            child: Row(
              children: [
                const VerticalDivider(
                  thickness: 3.0,
                ),
                const SizedBox(
                  width: 10.0,
                ),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateTimeConvert(lit.timestamp),
                          style: const TextStyle(
                            fontSize: 12.0,
                          ),
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          lit.description,
                          style: styleSubTitleSmall(
                            color: kParaColorDarkTint,
                          ),
                        ),
                        (lit.images.isEmpty)
                            ? Container()
                            : Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: (lit.images.length == 1)
                                    ? InkWell(
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      PreviewImagePlain(
                                                        imageUrl: lit.images[0],
                                                      )));
                                        },
                                        child: CachedNetworkImage(
                                          imageUrl: lit.images[0],
                                          progressIndicatorBuilder: (context,
                                                  url, downloadProgress) =>
                                              Container(
                                            height: 200,
                                            width: double.infinity,
                                            child: const Center(
                                              child: CupertinoActivityIndicator(
                                                color: kPrimaryColorTint2,
                                              ),
                                            ),
                                          ),
                                          imageBuilder:
                                              (context, imageProvider) =>
                                                  Container(
                                            height: 200,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: imageProvider,
                                                fit: BoxFit.cover,
                                              ),
                                              borderRadius:
                                                  const BorderRadius.all(
                                                Radius.circular(10.0),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : (lit.images.length == 2)
                                        ? Container(
                                            height: 200,
                                            width: double.infinity,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Expanded(
                                                  child: InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  PreviewImagePlain(
                                                                    imageUrl:
                                                                        lit.images[
                                                                            0],
                                                                  )));
                                                    },
                                                    child: CachedNetworkImage(
                                                      imageUrl: lit.images[0],
                                                      progressIndicatorBuilder:
                                                          (context, url,
                                                                  downloadProgress) =>
                                                              Container(
                                                        child: const Center(
                                                          child:
                                                              CupertinoActivityIndicator(
                                                            color:
                                                                kPrimaryColorTint2,
                                                          ),
                                                        ),
                                                      ),
                                                      imageBuilder: (context,
                                                              imageProvider) =>
                                                          Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          image:
                                                              DecorationImage(
                                                            image:
                                                                imageProvider,
                                                            fit: BoxFit.cover,
                                                          ),
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                            topLeft:
                                                                Radius.circular(
                                                                    10.0),
                                                            bottomLeft:
                                                                Radius.circular(
                                                                    10.0),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: 5.0,
                                                ),
                                                Expanded(
                                                  child: InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () {
                                                      Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                              builder: (context) =>
                                                                  PreviewImagePlain(
                                                                    imageUrl:
                                                                        lit.images[
                                                                            1],
                                                                  )));
                                                    },
                                                    child: CachedNetworkImage(
                                                      imageUrl: lit.images[1],
                                                      progressIndicatorBuilder:
                                                          (context, url,
                                                                  downloadProgress) =>
                                                              Container(
                                                        child: const Center(
                                                          child:
                                                              CupertinoActivityIndicator(
                                                            color:
                                                                kPrimaryColorTint2,
                                                          ),
                                                        ),
                                                      ),
                                                      imageBuilder: (context,
                                                              imageProvider) =>
                                                          Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          image:
                                                              DecorationImage(
                                                            image:
                                                                imageProvider,
                                                            fit: BoxFit.cover,
                                                          ),
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                            topRight:
                                                                Radius.circular(
                                                                    10.0),
                                                            bottomRight:
                                                                Radius.circular(
                                                                    10.0),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                        : (lit.images.length == 3)
                                            ? Container(
                                                height: 200,
                                                width: double.infinity,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: InkWell(
                                                        splashColor:
                                                            Colors.transparent,
                                                        highlightColor:
                                                            Colors.transparent,
                                                        onTap: () {
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          PreviewImagePlain(
                                                                            imageUrl:
                                                                                lit.images[0],
                                                                          )));
                                                        },
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl:
                                                              lit.images[0],
                                                          progressIndicatorBuilder:
                                                              (context, url,
                                                                      downloadProgress) =>
                                                                  Container(
                                                            child: const Center(
                                                              child:
                                                                  CupertinoActivityIndicator(
                                                                color:
                                                                    kPrimaryColorTint2,
                                                              ),
                                                            ),
                                                          ),
                                                          imageBuilder: (context,
                                                                  imageProvider) =>
                                                              Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              image:
                                                                  DecorationImage(
                                                                image:
                                                                    imageProvider,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                              borderRadius:
                                                                  const BorderRadius
                                                                      .only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                        10.0),
                                                                bottomLeft: Radius
                                                                    .circular(
                                                                        10.0),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 5.0,
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          children: [
                                                            Expanded(
                                                              child: InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) => PreviewImagePlain(
                                                                                imageUrl: lit.images[1],
                                                                              )));
                                                                },
                                                                child:
                                                                    CachedNetworkImage(
                                                                  imageUrl: lit
                                                                      .images[1],
                                                                  progressIndicatorBuilder: (context,
                                                                          url,
                                                                          downloadProgress) =>
                                                                      Container(
                                                                    child:
                                                                        const Center(
                                                                      child:
                                                                          CupertinoActivityIndicator(
                                                                        color:
                                                                            kPrimaryColorTint2,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  imageBuilder:
                                                                      (context,
                                                                              imageProvider) =>
                                                                          Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      image:
                                                                          DecorationImage(
                                                                        image:
                                                                            imageProvider,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        topRight:
                                                                            Radius.circular(10.0),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 5.0,
                                                            ),
                                                            Expanded(
                                                              child: InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) => PreviewImagePlain(
                                                                                imageUrl: lit.images[2],
                                                                              )));
                                                                },
                                                                child:
                                                                    CachedNetworkImage(
                                                                  imageUrl: lit
                                                                      .images[2],
                                                                  progressIndicatorBuilder: (context,
                                                                          url,
                                                                          downloadProgress) =>
                                                                      Container(
                                                                    child:
                                                                        const Center(
                                                                      child:
                                                                          CupertinoActivityIndicator(
                                                                        color:
                                                                            kPrimaryColorTint2,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  imageBuilder:
                                                                      (context,
                                                                              imageProvider) =>
                                                                          Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      image:
                                                                          DecorationImage(
                                                                        image:
                                                                            imageProvider,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        bottomRight:
                                                                            Radius.circular(10.0),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : Container(
                                                height: 200,
                                                width: double.infinity,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Container(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          children: [
                                                            Expanded(
                                                              child: InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) => PreviewImagePlain(
                                                                                imageUrl: lit.images[0],
                                                                              )));
                                                                },
                                                                child:
                                                                    CachedNetworkImage(
                                                                  imageUrl: lit
                                                                      .images[0],
                                                                  progressIndicatorBuilder: (context,
                                                                          url,
                                                                          downloadProgress) =>
                                                                      Container(
                                                                    child:
                                                                        const Center(
                                                                      child:
                                                                          CupertinoActivityIndicator(
                                                                        color:
                                                                            kPrimaryColorTint2,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  imageBuilder:
                                                                      (context,
                                                                              imageProvider) =>
                                                                          Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      image:
                                                                          DecorationImage(
                                                                        image:
                                                                            imageProvider,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        topLeft:
                                                                            Radius.circular(10.0),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 5.0,
                                                            ),
                                                            Expanded(
                                                              child: InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) => PreviewImagePlain(
                                                                                imageUrl: lit.images[2],
                                                                              )));
                                                                },
                                                                child:
                                                                    CachedNetworkImage(
                                                                  imageUrl: lit
                                                                      .images[2],
                                                                  progressIndicatorBuilder: (context,
                                                                          url,
                                                                          downloadProgress) =>
                                                                      Container(
                                                                    child:
                                                                        const Center(
                                                                      child:
                                                                          CupertinoActivityIndicator(
                                                                        color:
                                                                            kPrimaryColorTint2,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  imageBuilder:
                                                                      (context,
                                                                              imageProvider) =>
                                                                          Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      image:
                                                                          DecorationImage(
                                                                        image:
                                                                            imageProvider,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        bottomLeft:
                                                                            Radius.circular(10.0),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      width: 5.0,
                                                    ),
                                                    Expanded(
                                                      child: Container(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .stretch,
                                                          children: [
                                                            Expanded(
                                                              child: InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) => PreviewImagePlain(
                                                                                imageUrl: lit.images[1],
                                                                              )));
                                                                },
                                                                child:
                                                                    CachedNetworkImage(
                                                                  imageUrl: lit
                                                                      .images[1],
                                                                  progressIndicatorBuilder: (context,
                                                                          url,
                                                                          downloadProgress) =>
                                                                      Container(
                                                                    child:
                                                                        const Center(
                                                                      child:
                                                                          CupertinoActivityIndicator(
                                                                        color:
                                                                            kPrimaryColorTint2,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  imageBuilder:
                                                                      (context,
                                                                              imageProvider) =>
                                                                          Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      image:
                                                                          DecorationImage(
                                                                        image:
                                                                            imageProvider,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        topRight:
                                                                            Radius.circular(10.0),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 5.0,
                                                            ),
                                                            Expanded(
                                                              child: InkWell(
                                                                splashColor: Colors
                                                                    .transparent,
                                                                highlightColor:
                                                                    Colors
                                                                        .transparent,
                                                                onTap: () {
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                          builder: (context) => PreviewImagePlain(
                                                                                imageUrl: lit.images[3],
                                                                              )));
                                                                },
                                                                child:
                                                                    CachedNetworkImage(
                                                                  imageUrl: lit
                                                                      .images[3],
                                                                  progressIndicatorBuilder: (context,
                                                                          url,
                                                                          downloadProgress) =>
                                                                      Container(
                                                                    child:
                                                                        const Center(
                                                                      child:
                                                                          CupertinoActivityIndicator(
                                                                        color:
                                                                            kPrimaryColorTint2,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  imageBuilder:
                                                                      (context,
                                                                              imageProvider) =>
                                                                          Container(
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      image:
                                                                          DecorationImage(
                                                                        image:
                                                                            imageProvider,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                      borderRadius:
                                                                          const BorderRadius
                                                                              .only(
                                                                        bottomRight:
                                                                            Radius.circular(10.0),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )),
                        (lit.domainName == '')
                            ? Container()
                            : InkWell(
                                splashColor: Colors.transparent,
                                highlightColor: Colors.transparent,
                                onTap: () async {
                                  if (lit.link != '') {
                                    openBrowserURL(
                                      url: lit.link,
                                    );
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(top: 10.0),
                                  width: double.infinity,
                                  decoration: const BoxDecoration(
                                    color: kBackgroundColorDark2,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(5.0)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 10.0,
                                      top: 5.0,
                                      bottom: 5.0,
                                      right: 10.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            lit.domainName,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            style: styleTitleSmall(
                                                color: kPrimaryColorTint2),
                                          ),
                                        ),
                                        const Icon(
                                          Icons.open_in_browser,
                                          size: 20.0,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              )
                      ]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
