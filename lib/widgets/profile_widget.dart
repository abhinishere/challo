import 'package:challo/widgets/verifiedtick.dart';
import 'package:flutter/material.dart';

class ProfileWidget extends StatelessWidget {
  final String? imageUrl;
  final String? username;
  final bool variation;
  final bool? profileverified;
  final bool showverifiedtick;
  final Function? onPress;

  const ProfileWidget(
      {required this.imageUrl,
      required this.username,
      required this.variation,
      required this.profileverified,
      required this.showverifiedtick,
      this.onPress});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onPress!();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade600,
                width: 4.0,
              ),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.grey.shade600,
              radius: 30,
              backgroundImage:
                  const AssetImage('assets/images/default-profile-pic.png'),
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.transparent,
                backgroundImage: NetworkImage(imageUrl!),
              ),
            ),
          ),
          const SizedBox(
            height: 12,
          ),
          (profileverified == true && showverifiedtick == true)
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      username!,
                      style: Theme.of(context).textTheme.subtitle1!.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 3.0),
                      child: VerifiedTick(iconSize: 14),
                    ),
                  ],
                )
              : Text(
                  username!,
                  style: Theme.of(context).textTheme.subtitle1!.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                )
        ],
      ),
    );
  }
}
