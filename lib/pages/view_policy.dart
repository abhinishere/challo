import 'package:challo/variables.dart';
import 'package:flutter/material.dart';

class ViewPolicy extends StatelessWidget {
  final String policyName;
  final String policyText;
  const ViewPolicy({
    required this.policyName,
    required this.policyText,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(policyName),
        centerTitle: true,
        leading: GestureDetector(
          child: const Icon(Icons.arrow_back),
          onTap: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text(
              policyText,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.08,
                    color: kParaColorDark,
                  ),
            )),
      )),
    );
  }
}
