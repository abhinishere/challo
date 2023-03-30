import 'package:challo/variables.dart';
import 'package:flutter/material.dart';

class TextOnlyButton extends StatelessWidget {
  final String mainText;
  final Function onPress;
  final bool? whetherborderbottom;
  const TextOnlyButton({
    required this.mainText,
    required this.onPress,
    this.whetherborderbottom = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: const BorderSide(width: 2.0, color: kBackgroundColorDark2),
          bottom: BorderSide(
            width: (whetherborderbottom == true) ? 2.0 : 0.0,
            color: kBackgroundColorDark2,
          ),
        ),
      ),
      child: InkWell(
        onTap: onPress as void Function()?,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 15.0,
            bottom: 15.0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                mainText,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      fontSize: 17.0,
                      letterSpacing: -0.41,
                      color: kHeadlineColorDark,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: kIconSecondaryColorDark,
              )
            ],
          ),
        ),
      ),
    );
  }
}
