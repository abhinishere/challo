import 'package:challo/variables.dart';
import 'package:flutter/material.dart';

class ButtonSimple extends StatelessWidget {
  final Color? color; //OK
  final Color? textColor; //OK
  final String text; //OK
  final Function onPress; //OK
  final double? size; //OK
  final double? height; //OK
  final bool isPrefix; //OK
  final bool isSuffix; //OK
  final IconData? icon; //OK
  final Color? iconColor; //OK
  final double? textSize; //OK

  const ButtonSimple({
    this.color,
    this.textColor,
    required this.text,
    this.size,
    this.height,
    required this.onPress,
    this.isPrefix = false,
    this.isSuffix = false,
    this.textSize,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onPress();
      },
      child: Container(
        width: (size != null) ? size : MediaQuery.of(context).size.width,
        height: (height != null) ? height : 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            isPrefix
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      icon,
                      color: iconColor,
                    ),
                  )
                : const SizedBox(),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.button!.copyWith(
                  color: (textColor != null) ? textColor : kBackgroundColorDark,
                  fontSize: (textSize != null) ? textSize : 18,
                  fontWeight: FontWeight.w800),
            ),
            isSuffix
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      icon,
                      color: iconColor,
                    ),
                  )
                : const SizedBox()
          ],
        ),
        decoration: ShapeDecoration(
          color: (color == null) ? kHeadlineColorDark : color,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(5.0)),
          ),
        ),
      ),
    );
  }
}
