import 'package:challo/variables.dart';
import 'package:flutter/material.dart';

class DividerHorizontal extends StatelessWidget {
  final double? thickness;
  final Color? color;
  const DividerHorizontal(
      {this.thickness = 2.0, this.color = kBackgroundColorDark2});

  @override
  Widget build(BuildContext context) {
    return Divider(
      thickness: thickness,
      color: color,
    );
  }
}
