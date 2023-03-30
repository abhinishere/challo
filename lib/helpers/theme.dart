import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:challo/variables.dart';

// Our light/Primary Theme
ThemeData themeData(BuildContext context) {
  return ThemeData(
    appBarTheme: AppBarTheme(
      titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: kHeadlineColorDark,
            fontSize: 15.0,
            fontWeight: FontWeight.w700,
          ),
      color: kBackgroundColorDark2,
      elevation: 0,
      iconTheme: const IconThemeData(
        color: kIconSecondaryColorDark,
        size: 25.0,
      ),
    ),
    primaryColor: kPrimaryColor,
    //accentColor: kAccentLightColor,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      secondary: kSecondaryLightColor,
      // on light theme surface = Colors.white by default
    ),
    backgroundColor: Colors.white,
    iconTheme: const IconThemeData(color: kBodyTextColorLight),
    //accentIconTheme: IconThemeData(color: kAccentIconLightColor),
    primaryIconTheme: const IconThemeData(color: kPrimaryIconLightColor),
    textTheme: GoogleFonts.latoTextTheme().copyWith(
      bodyText1: const TextStyle(color: kBodyTextColorLight),
      bodyText2: const TextStyle(color: kBodyTextColorLight),
      headline4: const TextStyle(color: kTitleTextLightColor, fontSize: 32),
      headline1: const TextStyle(color: kTitleTextLightColor, fontSize: 80),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    /*pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoWillPopScopePageTransionsBuilder()
    }),*/
  );
}

// Dark Theme
ThemeData darkThemeData(BuildContext context) {
  return ThemeData.dark().copyWith(
    brightness: Brightness.dark,
    primaryColor: kPrimaryColor,
    //accentColor: kAccentDarkColor,
    //scaffoldBackgroundColor: const Color(0xFF0D0C0E), //old
    scaffoldBackgroundColor: kBackgroundColorDark,
    cardColor: kBackgroundColorDark2,
    appBarTheme: AppBarTheme(
      systemOverlayStyle: const SystemUiOverlayStyle(
        // Status bar color
        //systemNavigationBarColor: kBackgroundColorDark2,
        //systemNavigationBarDividerColor: kBackgroundColorDark2,
        //systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: kBackgroundColorDark2,
        statusBarBrightness: Brightness.dark,

        /* // Status bar brightness (optional)
        statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
        statusBarBrightness: Brightness.light, // For iOS (dark icons)
      */
      ),
      centerTitle: true,
      titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
            color: kHeadlineColorDark,
            fontSize: 17.0,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
      color: kBackgroundColorDark2,
      elevation: 0,
      iconTheme: const IconThemeData(
        color: kIconSecondaryColorDark,
        size: 25.0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
      overlayColor: MaterialStateProperty.all(kOverlayColorDark2),
    )),
    colorScheme: const ColorScheme.light(
      primary: kPrimaryColor,
      secondary: kSecondaryDarkColor,
      surface: kSurfaceDarkColor,
    ),
    iconTheme: const IconThemeData(color: kBodyTextColorDark),
    //accentIconTheme: IconThemeData(color: kAccentIconDarkColor),
    primaryIconTheme: const IconThemeData(color: kPrimaryIconDarkColor),
    textTheme: GoogleFonts.latoTextTheme().copyWith(
      bodyText1: const TextStyle(color: kBodyTextColorDark),
      bodyText2: const TextStyle(color: kBodyTextColorDark),
      headline4: const TextStyle(color: kTitleTextDarkColor, fontSize: 32),
      headline1: const TextStyle(color: kTitleTextDarkColor, fontSize: 80),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Colors.white,
      selectionHandleColor: Color(0xFF4267B2),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFFfffffe),
      contentTextStyle: Theme.of(context).textTheme.displaySmall!.copyWith(
            color: kBackgroundColorDark,
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
          ),
    ),

    /*pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoWillPopScopePageTransionsBuilder()
    }),*/
  );
}
