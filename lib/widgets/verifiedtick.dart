import 'package:challo/variables.dart';
import 'package:flutter/material.dart';

class VerifiedTick extends StatelessWidget {
  final double iconSize;
  const VerifiedTick({required this.iconSize});
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      color: kTertiaryColor,
      size: iconSize,
    );
  }
}
