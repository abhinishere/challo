import 'package:challo/variables.dart';
import 'package:challo/widgets/tab_item.dart';
import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final ValueChanged<int>? onSelectTab;
  final List<TabItem>? tabs;
  final int? currentTab;
  const BottomNavigation({
    this.onSelectTab,
    this.tabs,
    this.currentTab,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      height: (hidenav == true) ? 0 : null,
      child: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: kBackgroundColorDark2,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kHeadlineColorDark,
        unselectedItemColor: kIconSecondaryColorDark,
        currentIndex: currentTab!,
        items: tabs!
            .map(
              (e) => _buildItem(
                index: e.getIndex(),
                icon: e.icon,
                tabName: e.tabName,
              ),
            )
            .toList(),
        onTap: (index) => onSelectTab!(
          index,
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildItem(
      {int? index, required Widget icon, String? tabName}) {
    return BottomNavigationBarItem(
      icon: icon,
      label: tabName,
    );
  }
}
