import 'package:challo/variables.dart';
import 'package:flutter/material.dart';

class ContentFormatCard extends StatelessWidget {
  final Function onPress;
  final IconData icon;
  final String title, subtitle;
  final bool whetherupcoming;
  const ContentFormatCard({
    required this.onPress,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.whetherupcoming,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onPress();
      },
      child: Card(
        color: kBackgroundColorDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            5.0,
          ),
        ),
        elevation: 4.0,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 0.0, 10.0, 0.0),
          child: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 0.0, right: 10.0),
                child: Icon(
                  icon,
                  color: kIconSecondaryColorDark,
                ),
              ),
              const SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 10.0),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          color: kHeadlineColorDark,
                        ),
                  ),
                  const SizedBox(
                    height: 2.0,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.subtitle1!.copyWith(
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          color: kParaColorDark,
                        ),
                  ),
                  const SizedBox(height: 5),
                ],
              ),
              const SizedBox(width: 5),
            ],
          ),
        ),
      ),
    );
  }
}
