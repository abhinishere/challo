import 'package:challo/models/user_info_model.dart';

class VideoInfoModel {
  final String? subject, description, category, formattype, videourl;
  final int? guestsno, liveviews, totalviews, likes, dislikes;
  final UserInfoModel? user0, user1, user2;
  dynamic time;

  VideoInfoModel({
    this.subject,
    this.description,
    this.category,
    this.formattype,
    this.videourl,
    this.guestsno,
    this.liveviews,
    this.totalviews,
    this.likes,
    this.dislikes,
    this.user0,
    this.user1,
    this.user2,
    this.time,
  });
}
