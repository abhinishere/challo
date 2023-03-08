import 'package:flutter/material.dart';

class MinimalTextField extends StatelessWidget {
  final String label;
  final IconData? iconData;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final int? mincharlength;
  final int? maxcharlength;
  final int? maxlength;
  final int? maxlines;

  const MinimalTextField({
    required this.label,
    this.iconData,
    this.controller,
    this.focusNode,
    this.mincharlength,
    this.maxcharlength,
    this.maxlength,
    this.maxlines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      //margin: const EdgeInsets.only(bottom: 24),
      child: TextFormField(
        focusNode: focusNode,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        maxLines: maxlines,
        maxLength: maxlength,
        cursorColor: Colors.white,
        validator: (text) {
          if (text == null || text.isEmpty) {
            return '$label cannot be empty';
          }
          if (text.length < mincharlength!) {
            return '$label must be at least $mincharlength characters long';
          }
          if (text.length > maxcharlength!) {
            return '$label must be less than $maxcharlength characters long';
          }
          return null;
        },
        controller: controller,
        style: const TextStyle(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.bold,
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey.shade500,
              width: 2,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey.shade500,
              width: 2,
            ),
          ),
          border: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.grey.shade500,
              width: 2,
            ),
          ),
          suffixIcon: iconData != null
              ? Icon(
                  iconData,
                  color: Colors.grey.shade500,
                )
              : null,
        ),
      ),
    );
  }
}
