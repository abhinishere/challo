import 'package:flutter/material.dart';

class RoundedLabel extends StatelessWidget {
  final bool small;
  final Color bordercolor;
  final Color textcolor;
  final String text;
  final Function? onPress;

  const RoundedLabel(
      {required this.small,
      required this.bordercolor,
      required this.textcolor,
      required this.text,
      this.onPress});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onPress != null) {
          onPress!();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: small ? 10 : 16, vertical: small ? 4 : 8),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(
            Radius.circular(10),
          ),
          border: Border.all(
            width: 2,
            color: bordercolor,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textcolor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
