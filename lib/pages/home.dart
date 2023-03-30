import 'package:challo/pages/alerts.dart';
import 'package:challo/pages/appbuilder.dart';
import 'package:challo/pages/feed.dart';
import 'package:challo/pages/chats.dart';
import 'package:challo/variables.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:challo/widgets/tab_item.dart';
import 'package:challo/widgets/bottomnavigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:challo/pages/profilepage.dart';
import 'package:challo/pages/selectformat.dart';

class HomePage extends StatefulWidget {
  final String useruid;
  const HomePage({
    required this.useruid,
  });
  @override
  State<StatefulWidget> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // this is static property so other widget throughout the app
  // can access it simply by AppState.currentTab
  static int currentTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  // list tabs here
  final List<TabItem> tabs = [
    TabItem(
      tabName: "Feed",
      icon: const Icon(
        Icons.home,
        size: 30,
      ),
      page: FeedPage(),
    ),
    TabItem(
      tabName: "Chats",
      icon: const Icon(
        CupertinoIcons.chat_bubble_fill,
        size: 30,
      ),
      page: ChatPage(),
    ),
    TabItem(
      tabName: "Create",
      /*icon: Container(
        width: 45,
        height: 27,
        child: Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 10),
              width: 38,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(19, 136, 8, 1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 10),
              width: 38,
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 153, 51, 1),
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            Center(
              child: Container(
                height: double.infinity,
                width: 38,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.add,
                  size: 20,
                ),
              ),
            )
          ],
        ),
      ),*/
      icon: const Icon(
        Icons.add,
        size: 30,
      ),
      page: SelectFormat(),
    ),
    TabItem(
      tabName: "Alerts",
      icon: const Icon(
        Icons.notifications,
        size: 30,
      ),
      page: AlertsPage(),
    ),
    TabItem(
      tabName: "Profile",
      icon: const Icon(
        Icons.person,
        size: 30,
      ),
      page: ProfilePage(
        uid: FirebaseAuth.instance.currentUser!.uid,
        whetherShowArrow: false,
      ),
    ),
  ];

  HomePageState() {
    // indexing is necessary for proper funcationality
    // of determining which tab is active
    tabs.asMap().forEach((index, details) {
      details.setIndex(index);
    });
  }

  // sets current tab index
  // and update state
  void _selectTab(int index) {
    selectedTabIndex = index;
    if (index == currentTab) {
      // pop to first route
      // if the user taps on the active tab
      tabs[index].key.currentState!.popUntil((route) => route.isFirst);
    } else {
      FocusManager.instance.primaryFocus
          ?.unfocus(); //added on 10 April; to hide keyboard on tab switching
      // update the state
      // in order to repaint
      setState(() => currentTab = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope handle android back btn
    return WillPopScope(onWillPop: () async {
      final isFirstRouteInCurrentTab =
          !await tabs[currentTab].key.currentState!.maybePop();
      if (isFirstRouteInCurrentTab) {
        // if not on the 'main' tab
        if (currentTab != 0) {
          // select 'main' tab
          _selectTab(0);
          // back button handled by app
          return false;
        }
      }
      // let system handle back button if we're on the first route
      return isFirstRouteInCurrentTab;
    },
        // this is the base scaffold
        // don't put appbar in here otherwise you might end up
        // with multiple appbars on one screen
        // eventually breaking the app
        child: AppBuilder(builder: (context) {
      return Scaffold(
        // indexed stack shows only one child
        body: IndexedStack(
          index: currentTab,
          children: tabs.map((e) => e.page).toList(),
        ),
        // Bottom navigation
        bottomNavigationBar: BottomNavigation(
          onSelectTab: _selectTab,
          tabs: tabs,
          currentTab: currentTab,
        ),
      );
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      print("page resumed : ${widget.useruid}");
    } else {
      print("page closed : ${widget.useruid}");
    }
  }
}
