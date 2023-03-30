import 'package:challo/helpers/theme.dart';
import 'package:challo/pages/selectformat.dart';
import 'package:challo/variables.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:challo/pages/navigation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: kBackgroundColorDark2,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Challo',
        home: NavigationPage(),
        theme: themeData(context),
        darkTheme: darkThemeData(context),
        themeMode: ThemeMode.dark,
        routes: {
          'SelectFormat': (context) => SelectFormat(),
          'navigation': (context) => NavigationPage(),
        },
      ),
    );
  }
}
