import 'package:flutter/material.dart';

class FormatCard extends StatelessWidget {
  final String? imageUrl;
  final String? item;
  final Function? onPress;
  const FormatCard({this.imageUrl, this.item, this.onPress});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onPress!();
      },
      child: SizedBox(
        height: 172,
        width: 150,
        child: Card(
          color: Colors.grey.shade500,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Image.asset(imageUrl!),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Text(
                    item!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
