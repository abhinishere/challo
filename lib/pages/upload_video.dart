import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:challo/helpers/firebase_api.dart';
import 'package:challo/models/user_info_model.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/nonlive_video_player.dart';
import 'package:challo/variables.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'dart:math';

//PostVideo

class UploadVideoPage extends StatefulWidget {
  final UserInfoModel? onlineuser;
  final bool whethercommunitypost;
  final String? communityName;
  final String? communitypic;
  final bool whetherediting;
  final bool? whetherfrompost;
  final String? docName;

  const UploadVideoPage({
    required this.onlineuser,
    required this.whethercommunitypost,
    this.communityName,
    this.communitypic,
    required this.whetherediting,
    this.whetherfrompost,
    this.docName,
  });

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  bool dataisthere = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _videoPostKey = GlobalKey<FormState>();
  File? videofile;
  bool whethervideoselected = false;
  VideoPlayerController? controller;
  bool _isPlaying = false;
  Duration? duration;
  Duration? position;
  var _progress = 0.0;
  bool showvideoloading = false;
  bool showloading = false;
  late String docName;
  String? videoUrl;
  String? thumbnailUrl;
  final String placeholderUrl =
      "https://firebasestorage.googleapis.com/v0/b/social-media-890bb.appspot.com/o/nonlive_videos%2Fplaceholders%2Fjust_black.jpg?alt=media&token=57df421a-a155-4e61-b3ac-c647f0564b8b";
  String? descriptionUrl;
  File? thumbnailFile;
  int thumbnailHeight = 565;
  int thumbnailWidth = 753;
  double thumbnailAspectRatio = 753 / 565;
  bool whetherThumbnailAdded = false;

  List<String> blockedby = [];
  bool portraitonly = false;

  Map<String, String> placesMap = {};
  List<String> placesList = [];
  String selectedPlace = 'profile';
  bool whethercommunitypost = false;
  String communityName = '';
  String communityPic = '';

  @override
  void dispose() {
    super.dispose();
    if (whethervideoselected == true) {
      controller!.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    getdata();
  }

  getdata() async {
    placesMap['profile'] = widget.onlineuser!.pic!;
    whethercommunitypost = widget.whethercommunitypost;
    if (whethercommunitypost == true) {
      communityName = widget.communityName!;
      communityPic = widget.communitypic!;
      placesMap["c/$communityName"] = communityPic;
      setState(() {
        selectedPlace = "c/$communityName";
      });
    }

    //get communities that user follow
    await communitycollection
        .where('status', isEqualTo: 'published')
        .get()
        .then((value) => {
              for (var element in value.docs)
                {
                  placesMap['c/${element.id}'] = element['mainimage'],
                }
            });

    placesList = placesMap.keys.toList();
    if (widget.whetherediting == false) {
      docName = generatedocName();
      setState(() {
        dataisthere = true;
      });
    } else {
      docName = widget.docName!;

      var videodocs = await contentcollection.doc(docName).get();
      thumbnailUrl = videodocs['thumbnail'];
      videoUrl = videodocs['link'];
      _titleController.text = videodocs['topic'];

      Reference ref = FirebaseStorage.instance
          .ref()
          .child('nonlive_videos')
          .child(docName)
          .child('${docName}_long_description');

      await ref.getData().then((value) => {
            _descriptionController.text = utf8.decode(value!.toList()),
          });
      setState(() {
        dataisthere = true;
      });
    }
  }

  pickVideofromGallery() async {
    final ImagePicker _imagePicker = ImagePicker();
    await Permission.photos.request();
    var galleryPermissionStatus = await Permission.photos.status;
    if (galleryPermissionStatus.isGranted) {
      XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        videofile = File(video.path);
        await VideoCompress.getFileThumbnail(videofile!.path,
                quality: 50, // default(100)
                position: -1 // default(-1)
                )
            .then((file) => {
                  thumbnailFile = file,
                })
            .then((_) async => {
                  if (thumbnailFile != null)
                    {
                      await VideoCompress.getMediaInfo(videofile!.path)
                          .then((value) => {
                                thumbnailHeight = value.height!,
                                thumbnailWidth = value.width!,
                                thumbnailAspectRatio =
                                    value.width! / value.height!,
                                if (thumbnailAspectRatio > 0.8)
                                  {
                                    portraitonly = false,
                                  }
                                else
                                  {
                                    portraitonly = true,
                                  },
                                whetherThumbnailAdded = true,
                              })
                    }
                  else
                    {
                      //if no thumbnail use placeholder
                      thumbnailHeight = 565,
                      thumbnailWidth = 753,
                      thumbnailAspectRatio = 753 / 565,
                      portraitonly = false,
                      whetherThumbnailAdded = false,
                    }
                });

        // portraitonly = (info.width! > info.height!) ? false : true;
        //print("portraitonly is $portraitonly");

        setState(() {
          showvideoloading = true;
        });
        controller = VideoPlayerController.file(videofile!)
          ..initialize().then((value) => {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (controller?.value != null) {
                    controller!
                      ..addListener(() => _onControllerUpdate())
                      ..setLooping(true).then((value) => {
                            setState(() {
                              showvideoloading = false;
                              controller!.pause();
                              whethervideoselected = true;
                            })
                          });
                  }
                })
              });
      } else {
        //no video selected
      }
    } else {
      //permission error
      _showPermissionDenied();
    }
  }

  void _showPermissionDenied() {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text("Permission Error"),
        content: const Text(
            "Turn on Photos access for Challo in Settings to add a new picture."),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text("Close"),
            textStyle: Theme.of(context).textTheme.button!.copyWith(
                  color: kPrimaryColorTint2,
                  fontSize: 15.0,
                ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _onControllerUpdate() async {
    if (controller?.value == null) {
      if (!controller!.value.isInitialized) {
        print("controller not initialized");
      }
    } else {
      var _duration = controller!.value.duration;
      duration = _duration;

      var _position = await controller!.position;
      position = _position;

      final playing = controller!.value.isPlaying;
      if (playing) {
        setState(() {
          _progress = position!.inMilliseconds.ceilToDouble() /
              duration!.inMilliseconds.ceilToDouble();
        });
      }
      setState(() {
        _isPlaying = playing;
      });
    }
  }

  Future openBrowserURL({required String url}) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  showMarkdownGuide() {
    showModalBottomSheet(
        context: context,
        builder: (builder) => Container(
              height: (MediaQuery.of(context).size.height) / 1.7,
              width: (MediaQuery.of(context).size.width),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        "Markdown syntax",
                        style: styleTitleSmall(),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "H1 heading syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "# H1 title",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''# H1 title''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "H2 heading syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "## H2 title",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''## H2 title''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "H3 heading syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "# H3 title",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''### H3 title''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Italic emphasis syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "*italic text*",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''*italic text*''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Bold emphasis syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "**bold text**",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''**bold text**''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Blockquote syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "> That's pretty awesome!",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''> That's pretty awesome!''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Link syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "[Challo website](https://challo.tv)",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data:
                                      '''[Challo website](https://challo.tv)''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Image syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  "![Cool dog](https://challo.tv/cool_dog.jpg)",
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data:
                                      '''![Cool dog](https://challo.tv/wp-content/uploads/2022/04/cool_dog.jpg)''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                                Text(
                                  "Table syntax:",
                                  style: styleSubTitleSmall(
                                    color: Colors.white70,
                                  ),
                                ),
                                Text(
                                  '''Label1 | Label2 | Label3
R1C1 | R1C2 | R1C3
*Text1* | **Text2** | `Text3`
''',
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1!
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.0,
                                        wordSpacing: 2.0,
                                      ),
                                ),
                                Text(
                                  "Output:",
                                  style: Theme.of(context)
                                      .textTheme
                                      .caption!
                                      .copyWith(
                                        color: Colors.white70,
                                        fontSize: 12.0,
                                      ),
                                ),
                                MarkdownBody(
                                  data: '''
                                Label1 | Label2 | Label3
                                --- | --- | ---
                                R1C1 | R1C2 | R1C3
                                *Text1* | **Text2** | `Text3`
                                ''',
                                  styleSheet: styleSheetforMarkdown(context),
                                  onTapLink: (text, url, title) async {
                                    openBrowserURL(url: url!);
                                  },
                                ),
                                const SizedBox(
                                  height: 5.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          "Close",
                          style:
                              Theme.of(context).textTheme.subtitle1!.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: kPrimaryColorTint2,
                                  ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ));
  }

  showTextSheet(
      String typingWhat,
      int minLength,
      int maxLength,
      bool whetherMultiLine,
      TextEditingController _textEditingController,
      bool whetherShowFormatting) {
    showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          return Container(
            color: kBackgroundColorDark,
            height: double.infinity,
            width: double.infinity,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      top: 50.0, left: 10, right: 10, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(
                              Icons.arrow_back,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text("Add $typingWhat"),
                        ],
                      ),
                      (whetherShowFormatting == true)
                          ? TextButton(
                              onPressed: () {
                                showMarkdownGuide();
                              },
                              child: const Text(
                                "Formatting",
                                style: TextStyle(
                                  color: Colors.blueGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
                const Divider(
                  thickness: 2,
                  color: kBackgroundColorDark2,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: TextFormField(
                      validator: (text) {
                        if (text == null || text.isEmpty) {
                          return "$typingWhat cannot be empty";
                        } else if (text.length < minLength) {
                          return "$typingWhat can't be less than ${minLength.toString()} chars";
                        } else if (text.length > maxLength) {
                          return "$typingWhat can't be more than ${maxLength.toString()} chars";
                        }
                        return null;
                      },
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      controller: _textEditingController,
                      maxLength: maxLength,
                      keyboardType: (whetherMultiLine == true)
                          ? TextInputType.multiline
                          : TextInputType.text,
                      maxLines: null,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1!
                          .copyWith(color: Colors.white),
                      decoration: InputDecoration.collapsed(
                        hintText: 'Start Typing $typingWhat...',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }).whenComplete(() {
      setState(() {});
    });
  }

  Widget buildVideo() {
    return Container(
      alignment: Alignment.center,
      child: buildVideoPlayer(),
    );
  }

  Widget buildVideoPlayer() => buildFullScreen(
        child: AspectRatio(
            aspectRatio: controller!.value.aspectRatio,
            child: VideoPlayer(controller!)),
      );

  Widget buildFullScreen({required Widget child}) {
    final size = controller!.value.size;
    final width = size.width;
    final height = size.height;
    return FittedBox(
        fit: BoxFit.cover,
        //alignment: Alignment.topCenter,
        child: SizedBox(width: width, height: height, child: child));
  }

  String convertTwo(int value) {
    return value < 10 ? "0$value" : "$value";
  }

  Widget _vidControls() {
    final _duration = duration!.inSeconds;
    final _head = position!.inSeconds;
    final _remained = max(0, _duration - _head);
    final mins = convertTwo(_remained ~/ 60.0); //~ for taking integer part
    final secs = convertTwo(_remained % 60);
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        height: 35,
        //color: Colors.blueAccent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ButtonTheme(
              padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 8.0), //adds padding inside the button
              materialTapTargetSize: MaterialTapTargetSize
                  .shrinkWrap, //limits the touch area to the button area
              minWidth: 0, //wraps child's width
              height: 0, //wraps child's height

              child: TextButton(
                onPressed: () async {
                  if (_isPlaying == true) {
                    setState(() {
                      _isPlaying = false;
                    });

                    controller!.pause();
                  } else {
                    setState(() {
                      _isPlaying = true;
                    });

                    controller!.play();
                  }
                },
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 25,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Container(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.red[700],
                    inactiveTrackColor: Colors.red[100],
                    trackShape: const RoundedRectSliderTrackShape(),
                    trackHeight: 3.0,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                    thumbColor: Colors.redAccent,
                    overlayColor: Colors.red.withAlpha(32),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 28.0),
                    tickMarkShape: const RoundSliderTickMarkShape(),
                    activeTickMarkColor: Colors.red[700],
                    inactiveTickMarkColor: Colors.red[100],
                    valueIndicatorShape:
                        const PaddleSliderValueIndicatorShape(),
                    valueIndicatorColor: Colors.redAccent,
                    valueIndicatorTextStyle:
                        const TextStyle(color: Colors.white),
                  ),
                  child: Slider(
                    value: max(0, min(_progress * 100, 100)),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    label: position!.toString().split(".")[0],
                    onChanged: (value) {
                      setState(() {
                        _progress = value * 0.01;
                      });
                    },
                    onChangeStart: (value) {
                      controller!.pause();
                    },
                    onChangeEnd: (value) {
                      final duration = controller!.value.duration;

                      var newValue = max(0, min(value, 99)) * 0.01;
                      var millis = (duration.inMilliseconds * newValue).toInt();
                      controller!.seekTo(Duration(milliseconds: millis));
                      controller!.play();
                    },
                  ),
                ),
              ),
            ),
            Text(
              "$mins:$secs",
              style: Theme.of(context).textTheme.subtitle1!.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  shadows: <Shadow>[
                    const Shadow(
                      offset: Offset(0.0, 1.0),
                      blurRadius: 4.0,
                      color: Color.fromARGB(150, 0, 0, 0),
                    )
                  ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget videoPreviewWidget() {
    return Container(
      height: 200,
      child: Stack(
        children: [
          buildVideo(),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: _vidControls(),
            ),
          ),
          Positioned(
            left: 10.0,
            top: 0.0,
            child: TextButton(
              child: Icon(
                (controller!.value.volume > 0)
                    ? Icons.volume_up
                    : Icons.volume_off,
                color: Colors.white,
                size: 25,
              ),
              onPressed: () {
                setState(() {
                  if (controller!.value.volume > 0) {
                    controller!.setVolume(0);
                  } else {
                    controller!.setVolume(1.0);
                  }
                });
              },
            ),
          ),
          Positioned(
            right: 10.0,
            top: 0.0,
            child: TextButton(
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 25,
              ),
              onPressed: () {
                whetherThumbnailAdded = false;
                /*
                bool _isPlaying = false;
  Duration? _duration;
  Duration? _position;
  var _progress = 0.0;
                */
                setState(() {
                  whethervideoselected = false;
                });
                _isPlaying = false;
                _progress = 0.0;
                controller!.dispose();
              },
            ),
          ),
        ],
      ),
    );
  }

  final _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final _rnd = Random();

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  String generatedocName() {
    String newdocName = (widget.onlineuser!.username! + getRandomString(5));
    return newdocName;
  }

  RegExp exp = RegExp(r'[\s,;/.!:?({\[&)\]}]+');
  List<String> stringtoList(String videoinfostring) {
    final List<String> infoinlist0 = videoinfostring.split(exp);
    final List<String> infoinlist =
        infoinlist0.map((email) => email.toLowerCase()).toList();
    infoinlist.removeWhere((value) => value == "");
    return (infoinlist);
  }

  uploadthisVideo() async {
    setState(() {
      showloading = true;
    });
    if (videofile == null) {
      //no file selected error
    } else {
      UploadTask? videoUploadTask;

      final String fileName = videofile!.path.split('/').last;
      final String videodestination = 'nonlive_videos/$docName/$fileName';

      videoUploadTask = FirebaseApi.uploadFile(videodestination, videofile!);

      if (videoUploadTask == null) return;
      await videoUploadTask.then((p0) => {
            p0.ref
                .getDownloadURL()
                .then((value) => {
                      videoUrl = value,
                      print("VideoUrl is $videoUrl"),
                    })
                .then((value) async => {
                      if (whetherThumbnailAdded == false)
                        {
                          print("There is NO thumbnail at all"),
                          await FirebaseStorage.instance
                              .ref()
                              .child('nonlive_videos')
                              .child(docName)
                              .child('${docName}_long_description')
                              .putString(
                                _descriptionController.text,
                                metadata: SettableMetadata(
                                  contentType: 'text/markdown',
                                  customMetadata: null,
                                ),
                              )
                              .then((p1) => p1.ref
                                  .getDownloadURL()
                                  .then((descurl) async => {
                                        descriptionUrl = descurl,
                                        await contentcollection
                                            .doc(docName)
                                            .set({
                                          'type': 'videopost',
                                          'status': 'published',
                                          'docName': docName,
                                          'whethercommunitypost':
                                              whethercommunitypost,
                                          'communityName':
                                              (whethercommunitypost == false)
                                                  ? ''
                                                  : communityName,
                                          'communitypic':
                                              (whethercommunitypost == false)
                                                  ? ''
                                                  : communityPic,
                                          'topic': _titleController.text,
                                          'topicinlist': stringtoList(
                                              _titleController.text),
                                          'descriptionUrl': descriptionUrl,
                                          'description':
                                              _descriptionController.text,
                                          'time': DateTime.now(),
                                          'likes': [],
                                          'dislikes': [],
                                          'commentcount': 0,
                                          'totalviews': [],
                                          'link': videoUrl,
                                          'portraitonly': portraitonly,
                                          'thumbnail': placeholderUrl,
                                          'thumbnailHeight': thumbnailHeight,
                                          'thumbnailWidth': thumbnailWidth,
                                          'thumbnailAspectRatio':
                                              thumbnailAspectRatio,
                                          'opuid': widget.onlineuser!.uid,
                                          'opusername':
                                              widget.onlineuser!.username,
                                          'oppic': widget.onlineuser!.pic,
                                          'blockedby': blockedby,
                                          'topfeaturedpriority': 0,
                                          'trendingpriority': 0,
                                          'communitypostpriority': 0,
                                        }).then((value) async => {
                                                  await usercollection
                                                      .doc(widget
                                                          .onlineuser!.uid)
                                                      .collection('content')
                                                      .doc(docName)
                                                      .set({
                                                    'type': 'videopost',
                                                    'docName': docName,
                                                    'whethercommunitypost':
                                                        whethercommunitypost,
                                                    'communityName':
                                                        (whethercommunitypost ==
                                                                false)
                                                            ? ''
                                                            : communityName,
                                                    'communitypic':
                                                        (whethercommunitypost ==
                                                                false)
                                                            ? ''
                                                            : communityPic,
                                                    'topic':
                                                        _titleController.text,
                                                    'descriptionUrl':
                                                        descriptionUrl,
                                                    'description':
                                                        _descriptionController
                                                            .text,
                                                    'link': videoUrl,
                                                    'portraitonly':
                                                        portraitonly,
                                                    'thumbnail': placeholderUrl,
                                                    'thumbnailHeight':
                                                        thumbnailHeight,
                                                    'thumbnailWidth':
                                                        thumbnailWidth,
                                                    'thumbnailAspectRatio':
                                                        thumbnailAspectRatio,
                                                    'time': DateTime.now(),
                                                    'blockedby': blockedby,
                                                  }).then((_) => {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    ((context) =>
                                                                        NonliveVideoPlayer(
                                                                          docName:
                                                                              docName,
                                                                          whetherjustcreated:
                                                                              true,
                                                                          showcomments:
                                                                              false,
                                                                        )),
                                                                fullscreenDialog:
                                                                    true,
                                                              ),
                                                            )
                                                          })
                                                })
                                      }))
                        }
                      else
                        {
                          uploadthisThumbnail(fileName),
                        }
                    })
          });
    }
  }

  Future uploadthisThumbnail(String fileName) async {
    final String thumbnaildestination =
        'nonlive_videos/$docName/${fileName}_thumbnail';
    final UploadTask? thumbnailUploadTask =
        FirebaseApi.uploadFile(thumbnaildestination, thumbnailFile!);
    if (thumbnailUploadTask == null) return;
    await thumbnailUploadTask.then((p1) => {
          p1.ref
              .getDownloadURL()
              .then((value) => {
                    thumbnailUrl = value,
                  })
              .then((value) async => {
                    if (thumbnailUrl == null)
                      {
                        print("Thumbnail uploaded, but no thumbnail"),
                        await FirebaseStorage.instance
                            .ref()
                            .child('nonlive_videos')
                            .child(docName)
                            .child('${docName}_long_description')
                            .putString(
                              _descriptionController.text,
                              metadata: SettableMetadata(
                                contentType: 'text/markdown',
                                customMetadata: null,
                              ),
                            )
                            .then((p1) => p1.ref
                                .getDownloadURL()
                                .then((descurl) async => {
                                      descriptionUrl = descurl,
                                      await contentcollection.doc(docName).set({
                                        'type': 'videopost',
                                        'status': 'published',
                                        'docName': docName,
                                        'whethercommunitypost':
                                            whethercommunitypost,
                                        'communityName':
                                            (whethercommunitypost == false)
                                                ? ''
                                                : communityName,
                                        'communitypic':
                                            (whethercommunitypost == false)
                                                ? ''
                                                : communityPic,
                                        'topic': _titleController.text,
                                        'topicinlist':
                                            stringtoList(_titleController.text),
                                        'descriptionUrl': descriptionUrl,
                                        'description':
                                            _descriptionController.text,
                                        'time': DateTime.now(),
                                        'likes': [],
                                        'dislikes': [],
                                        'commentcount': 0,
                                        'totalviews': [],
                                        'link': videoUrl,
                                        'portraitonly': portraitonly,
                                        'thumbnail': placeholderUrl,
                                        'thumbnailHeight': thumbnailHeight,
                                        'thumbnailWidth': thumbnailWidth,
                                        'thumbnailAspectRatio':
                                            thumbnailAspectRatio,
                                        'opuid': widget.onlineuser!.uid,
                                        'opusername':
                                            widget.onlineuser!.username,
                                        'oppic': widget.onlineuser!.pic,
                                        'blockedby': blockedby,
                                        'topfeaturedpriority': 0,
                                        'trendingpriority': 0,
                                        'communitypostpriority': 0,
                                      }).then((value) async => {
                                            await usercollection
                                                .doc(widget.onlineuser!.uid)
                                                .collection('content')
                                                .doc(docName)
                                                .set({
                                              'type': 'videopost',
                                              'docName': docName,
                                              'whethercommunitypost':
                                                  whethercommunitypost,
                                              'communityName':
                                                  (whethercommunitypost ==
                                                          false)
                                                      ? ''
                                                      : communityName,
                                              'communitypic':
                                                  (whethercommunitypost ==
                                                          false)
                                                      ? ''
                                                      : communityPic,
                                              'topic': _titleController.text,
                                              'descriptionUrl': descriptionUrl,
                                              'description':
                                                  _descriptionController.text,
                                              'link': videoUrl,
                                              'portraitonly': portraitonly,
                                              'thumbnail': placeholderUrl,
                                              'thumbnailHeight':
                                                  thumbnailHeight,
                                              'thumbnailWidth': thumbnailWidth,
                                              'thumbnailAspectRatio':
                                                  thumbnailAspectRatio,
                                              'time': DateTime.now(),
                                              'blockedby': blockedby,
                                            }).then((_) => {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: ((context) =>
                                                              NonliveVideoPlayer(
                                                                  docName:
                                                                      docName,
                                                                  whetherjustcreated:
                                                                      true,
                                                                  showcomments:
                                                                      false)),
                                                          fullscreenDialog:
                                                              true,
                                                        ),
                                                      )
                                                    })
                                          })
                                    }))
                      }
                    else
                      {
                        print("There is thumbnail"),
                        await FirebaseStorage.instance
                            .ref()
                            .child('nonlive_videos')
                            .child(docName)
                            .child('${docName}_long_description')
                            .putString(
                              _descriptionController.text,
                              metadata: SettableMetadata(
                                contentType: 'text/markdown',
                                customMetadata: null,
                              ),
                            )
                            .then((p1) => p1.ref
                                .getDownloadURL()
                                .then((descurl) async => {
                                      descriptionUrl = descurl,
                                      await contentcollection.doc(docName).set({
                                        'type': 'videopost',
                                        'status': 'published',
                                        'docName': docName,
                                        'whethercommunitypost':
                                            whethercommunitypost,
                                        'communityName':
                                            (whethercommunitypost == false)
                                                ? ''
                                                : communityName,
                                        'communitypic':
                                            (whethercommunitypost == false)
                                                ? ''
                                                : communityPic,
                                        'topic': _titleController.text,
                                        'topicinlist':
                                            stringtoList(_titleController.text),
                                        'descriptionUrl': descriptionUrl,
                                        'description':
                                            _descriptionController.text,
                                        'time': DateTime.now(),
                                        'likes': [],
                                        'dislikes': [],
                                        'commentcount': 0,
                                        'totalviews': [],
                                        'link': videoUrl,
                                        'portraitonly': portraitonly,
                                        'thumbnail': thumbnailUrl,
                                        'thumbnailHeight': thumbnailHeight,
                                        'thumbnailWidth': thumbnailWidth,
                                        'thumbnailAspectRatio':
                                            thumbnailAspectRatio,
                                        'opuid': widget.onlineuser!.uid,
                                        'opusername':
                                            widget.onlineuser!.username,
                                        'oppic': widget.onlineuser!.pic,
                                        'blockedby': blockedby,
                                        'topfeaturedpriority': 0,
                                        'trendingpriority': 0,
                                        'communitypostpriority': 0,
                                      }).then((value) async => {
                                            await usercollection
                                                .doc(widget.onlineuser!.uid)
                                                .collection('content')
                                                .doc(docName)
                                                .set({
                                              'type': 'videopost',
                                              'docName': docName,
                                              'whethercommunitypost':
                                                  whethercommunitypost,
                                              'communityName':
                                                  (whethercommunitypost ==
                                                          false)
                                                      ? ''
                                                      : communityName,
                                              'communitypic':
                                                  (whethercommunitypost ==
                                                          false)
                                                      ? ''
                                                      : communityPic,
                                              'topic': _titleController.text,
                                              'descriptionUrl': descriptionUrl,
                                              'description':
                                                  _descriptionController.text,
                                              'link': videoUrl,
                                              'portraitonly': portraitonly,
                                              'thumbnail': thumbnailUrl,
                                              'thumbnailHeight':
                                                  thumbnailHeight,
                                              'thumbnailWidth': thumbnailWidth,
                                              'thumbnailAspectRatio':
                                                  thumbnailAspectRatio,
                                              'time': DateTime.now(),
                                              'blockedby': blockedby,
                                            }).then((_) => {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: ((context) =>
                                                              NonliveVideoPlayer(
                                                                  docName:
                                                                      docName,
                                                                  whetherjustcreated:
                                                                      true,
                                                                  showcomments:
                                                                      false)),
                                                          fullscreenDialog:
                                                              true,
                                                        ),
                                                      ),
                                                    })
                                          })
                                    }))
                      }
                  })
        });
  }

  makeEdits() async {
    setState(() {
      showloading = true;
    });
    await FirebaseStorage.instance
        .ref()
        .child('nonlive_videos')
        .child(docName)
        .child('${docName}_long_description')
        .putString(
          _descriptionController.text,
          metadata: SettableMetadata(
            contentType: 'text/markdown',
            customMetadata: null,
          ),
        )
        .then((_) async => {
              await contentcollection.doc(docName).update({
                'topic': _titleController.text,
              })
            })
        .then((_) => {
              if (widget.whetherfrompost == false)
                {
                  setState(() {
                    hidenav = false;
                  }),
                  AppBuilder.of(context)!.rebuild(),
                  Navigator.pop(context, true)
                }
              else
                {Navigator.pop(context, true)}
            });
  }

  @override
  Widget build(BuildContext context) {
    return (dataisthere == false)
        ? WillPopScope(
            onWillPop: () {
              if (widget.whetherediting == false) {
                setState(() {
                  hidenav = false;
                });
                AppBuilder.of(context)!.rebuild();
                Navigator.pop(context);
              } else {
                if (widget.whetherfrompost == false) {
                  setState(() {
                    hidenav = false;
                  });
                  AppBuilder.of(context)!.rebuild();
                  Navigator.pop(context);
                } else {
                  Navigator.pop(context);
                }
              }

              return Future.value(false);
            },
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              appBar: AppBar(
                leading: GestureDetector(
                  onTap: () {
                    if (widget.whetherediting == false) {
                      setState(() {
                        hidenav = false;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.pop(context);
                    } else {
                      if (widget.whetherfrompost == false) {
                        setState(() {
                          hidenav = false;
                        });
                        AppBuilder.of(context)!.rebuild();
                        Navigator.pop(context);
                      } else {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white70,
                  ),
                ),
              ),
              //backgroundColor: Colors.black,
              body: const Center(
                  child: CupertinoActivityIndicator(
                color: kDarkPrimaryColor,
              )),
            ),
          )
        : (showloading == false)
            ? WillPopScope(
                onWillPop: () {
                  if (widget.whetherediting == false) {
                    setState(() {
                      hidenav = false;
                    });
                    AppBuilder.of(context)!.rebuild();
                    Navigator.pop(context);
                  } else {
                    if (widget.whetherfrompost == false) {
                      setState(() {
                        hidenav = false;
                      });
                      AppBuilder.of(context)!.rebuild();
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);
                    }
                  }
                  return Future.value(false);
                },
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text("Video post"),
                    centerTitle: true,
                    leading: GestureDetector(
                        onTap: () {
                          if (widget.whetherediting == false) {
                            setState(() {
                              hidenav = false;
                            });
                            AppBuilder.of(context)!.rebuild();
                            Navigator.pop(context);
                          } else {
                            if (widget.whetherfrompost == false) {
                              setState(() {
                                hidenav = false;
                              });
                              AppBuilder.of(context)!.rebuild();
                              Navigator.pop(context);
                            } else {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: const Icon(Icons.arrow_back)),
                    actions: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: TextButton(
                          onPressed: () async {
                            if (_videoPostKey.currentState!.validate()) {
                              if (widget.whetherediting == false) {
                                if (whethervideoselected == false) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Umm... you have not picked a video.",
                                        style: TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  //go ahead and upload the video

                                  uploadthisVideo();
                                }
                              } else {
                                //editing title,description
                                makeEdits();
                              }
                            }
                          },
                          child: const Text(
                            "Publish",
                            style: TextStyle(
                                color: kPrimaryColorTint2,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    ],
                  ),
                  body: Form(
                    key: _videoPostKey,
                    child: SafeArea(
                      child: Scrollbar(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              (showvideoloading == true)
                                  ? Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Container(
                                        height: 200,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: Colors.grey.shade500),
                                        ),
                                        child: const Center(
                                          child: CupertinoActivityIndicator(
                                            color: kDarkPrimaryColor,
                                          ),
                                        ),
                                      ),
                                    )
                                  : (widget.whetherediting == false)
                                      ? (whethervideoselected == false)
                                          ? Padding(
                                              padding:
                                                  const EdgeInsets.all(10.0),
                                              child: InkWell(
                                                onTap: () =>
                                                    pickVideofromGallery(),
                                                child: Container(
                                                  height: 200,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    border: Border.all(
                                                        color: Colors
                                                            .grey.shade500),
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "Pick a video from gallery",
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .subtitle1!
                                                          .copyWith(
                                                            color: Colors
                                                                .grey.shade500,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : videoPreviewWidget()
                                      : Padding(
                                          padding: const EdgeInsets.all(10.0),
                                          child: InkWell(
                                            onTap: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Umm... you can't change the video.",
                                                    style: TextStyle(
                                                      color: Colors.red,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 200,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                    color:
                                                        Colors.grey.shade500),
                                              ),
                                              child: Center(
                                                child: Image.network(
                                                    thumbnailUrl!),
                                              ),
                                            ),
                                          ),
                                        ),
                              const Text(
                                "•••",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Divider(
                                thickness: 2,
                                color: kBackgroundColorDark2,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 10.0, right: 10.0),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    prefixIconConstraints:
                                        const BoxConstraints(),
                                    prefixIcon: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 10.0),
                                      child: CachedNetworkImage(
                                        imageUrl: placesMap[selectedPlace]!,
                                        progressIndicatorBuilder:
                                            (context, url, downloadProgress) =>
                                                Container(
                                          decoration: new BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: new Border.all(
                                              color: Colors.grey.shade600,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: const CircleAvatar(
                                            child: CupertinoActivityIndicator(
                                              color: kPrimaryColorTint2,
                                            ),
                                            radius: 13.0,
                                            backgroundColor:
                                                kBackgroundColorDark2,
                                          ),
                                        ),
                                        imageBuilder:
                                            (context, imageProvider) =>
                                                Container(
                                          decoration: new BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: new Border.all(
                                              color: Colors.grey.shade600,
                                              width: 1.0,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            backgroundImage: imageProvider,
                                            radius: 13.0,
                                            backgroundColor:
                                                kBackgroundColorDark2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    labelText: "Post on...",
                                    labelStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: kSubTextColor,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: Theme(
                                      data: ThemeData(
                                        brightness: Brightness.dark,
                                        splashColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        scrollbarTheme: ScrollbarThemeData(
                                          thumbColor:
                                              MaterialStateProperty.all<Color>(
                                                  Colors.white70),
                                        ),
                                      ),
                                      child: Container(
                                        height: 35,
                                        child: DropdownButton(
                                            isDense: true,
                                            focusColor: Colors.transparent,
                                            menuMaxHeight:
                                                MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    2,
                                            icon: (widget.whetherediting ==
                                                    false)
                                                ? const Icon(
                                                    CupertinoIcons
                                                        .arrowtriangle_down_circle_fill,
                                                    //size: 25,
                                                    color: kPrimaryColorTint2,
                                                  )
                                                : Container(),
                                            dropdownColor:
                                                kBackgroundColorDark2,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1!
                                                .copyWith(
                                                  color: kHeadlineColorDark,
                                                ),
                                            items: placesList
                                                .map((e) => DropdownMenuItem(
                                                      child: Text(e),
                                                      value: e,
                                                    ))
                                                .toList(),
                                            value: selectedPlace,
                                            onChanged: (widget.whetherediting ==
                                                    true)
                                                ? null
                                                : (val) {
                                                    setState(() {
                                                      selectedPlace =
                                                          val as String;
                                                    });
                                                    if (selectedPlace ==
                                                        'profile') {
                                                      whethercommunitypost =
                                                          false;
                                                      communityName = '';
                                                      communityPic = '';
                                                    } else {
                                                      whethercommunitypost =
                                                          true;
                                                      communityName =
                                                          selectedPlace
                                                              .replaceFirst(
                                                                  "c/",
                                                                  ""); //remove c/
                                                      communityPic = placesMap[
                                                          selectedPlace]!;
                                                    }
                                                  }),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const Divider(
                                thickness: 2.0,
                                color: kBackgroundColorDark2,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.title),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Flexible(
                                      child: TextFormField(
                                        validator: (text) {
                                          if (text == null || text.isEmpty) {
                                            return "Title cannot be empty";
                                          } else if (text.length < 5) {
                                            return "Title can't be less than 5 chars";
                                          } else if (text.length > 70) {
                                            return "Title can't be more than 70 chars";
                                          }
                                          return null;
                                        },
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        controller: _titleController,
                                        maxLength: 70,
                                        readOnly: true,
                                        maxLines: 2,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1!
                                            .copyWith(
                                              color: kHeadlineColorDark,
                                            ),
                                        decoration:
                                            const InputDecoration.collapsed(
                                          hintText: 'Add a title...',
                                        ),
                                        onTap: () {
                                          showTextSheet("Title", 5, 70, false,
                                              _titleController, false);
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const Divider(
                                thickness: 2,
                                color: kBackgroundColorDark2,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.description),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Flexible(
                                      child: TextFormField(
                                        validator: (text) {
                                          if (text == null || text.isEmpty) {
                                            return "Description cannot be empty";
                                          } else if (text.length < 10) {
                                            return "Description can't be less than 10 chars";
                                          } else if (text.length > 1250) {
                                            return "Description can't be more than 1250 chars";
                                          }
                                          return null;
                                        },
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        controller: _descriptionController,
                                        readOnly: true,
                                        maxLines: 2,
                                        maxLength: 1250,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyText1!
                                            .copyWith(
                                              color: kHeadlineColorDark,
                                            ),
                                        decoration:
                                            const InputDecoration.collapsed(
                                          hintText: 'Add a description...',
                                        ),
                                        onTap: () {
                                          showTextSheet(
                                              "Description",
                                              10,
                                              1250,
                                              true,
                                              _descriptionController,
                                              true);
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              ),
                              const Divider(
                                thickness: 2,
                                color: kBackgroundColorDark2,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : WillPopScope(
                onWillPop: () async => false,
                child: Scaffold(
                    resizeToAvoidBottomInset: false,
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const CupertinoActivityIndicator(
                            color: kDarkPrimaryColor,
                          ),
                          const SizedBox(height: 10),
                          (widget.whetherediting == false)
                              ? const Text("Uploading video...")
                              : const Text("Updating video..."),
                        ],
                      ),
                    )),
              );
  }
}
