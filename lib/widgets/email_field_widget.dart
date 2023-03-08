import 'package:flutter/material.dart';

class EmailFieldWidget extends StatelessWidget {
  final String label;
  final IconData? iconData;
  final TextEditingController? controller;
  final int? mincharlength;
  final int? maxcharlength;
  final int? maxlength;
  final int? maxlines;

  const EmailFieldWidget(
      {required this.label,
      this.iconData,
      this.controller,
      this.mincharlength,
      this.maxcharlength,
      this.maxlength,
      this.maxlines});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: TextFormField(
        autovalidateMode: AutovalidateMode.onUserInteraction,
        maxLines: maxlines,
        maxLength: maxlength,
        cursorColor: Colors.white,
        validator: (text) {
          bool emailValid = RegExp(
                  r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
              .hasMatch(controller!.text);
          if (text == null || text.isEmpty) {
            return '$label cannot be empty';
          }
          if (text.length < mincharlength!) {
            return '$label must be at least $mincharlength characters long';
          }
          if (text.length > maxcharlength!) {
            return '$label must be less than $maxcharlength characters long';
          }
          if (emailValid == false) {
            return 'Enter a valid $label address';
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
              : Container(),
        ),
      ),
    );
  }
}
