import 'package:challo/variables.dart';
import 'package:flutter/material.dart';

class ButtonWithShadow extends StatelessWidget {
  final Color borderColor;
  final Color shadowColor;
  final Color color;
  final Color? textColor;
  final String text;
  final Function onPress;
  final double? size;
  final double? height;

  const ButtonWithShadow(
      {required this.borderColor,
      required this.shadowColor,
      required this.color,
      this.textColor,
      required this.text,
      this.size,
      this.height,
      required this.onPress});

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
        decoration: ShapeDecoration(
            shadows: [
              BoxShadow(
                color: shadowColor,
                offset: const Offset(
                  0.0, // Move to right 10  horizontally
                  4.0, // Move to bottom 5 Vertically
                ),
              )
            ],
            color: color,
            shape: RoundedRectangleBorder(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                side: BorderSide(color: borderColor, width: 2))),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.button!.copyWith(
                  color: (textColor != null) ? textColor : kBlackContrast,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ),
    );
  }
}
