import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orange_ui/firebase_options.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/screen/countries/select_country_controller.dart';
import 'package:orange_ui/screen/languages_screen/languages_screen_view_model.dart';
import 'package:orange_ui/screen/restart_app/restart_app.dart';
import 'package:orange_ui/screen/splash_screen/splash_screen.dart';
import 'package:orange_ui/service/ads_service.dart';
import 'package:orange_ui/service/firebase_notification_manager.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/service/subscription/subscription_manager.dart';
import 'package:orange_ui/utils/app_platform.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  FirebaseNotificationManager.shared.showNotification(message);
}

Future<void> main() async {
  // 1. MUST BE FIRST: Initialize Flutter binding before any platform calls
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Safe mobile platform styling
  if (!kIsWeb) {
    try {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: ColorRes.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ));
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      HttpOverrides.global = MyHttpOverrides();
    } catch (e) {
      debugPrint('Mobile platform styling error: $e');
    }
  }

  // 3. Safe Firebase initialization
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  // 4. Safe persistent storage initialization
  try {
    await GetStorage.init('Orange');
  } catch (e) {
    debugPrint('GetStorage initialization error: $e');
  }

  // 5. Safe language setup
  try {
    LanguagesScreenViewModel.selectedLanguage =
        SessionManager.instance.getString(key: SessionKeys.languageCode) ??
            AppPlatform.languageCode;
  } catch (e) {
    LanguagesScreenViewModel.selectedLanguage = 'en';
  }

  // 6. Background messaging handler (mobile only)
  if (!kIsWeb) {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Firebase messaging error: $e');
    }
  }

  // 7. Error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.library == 'image resource service' && details.exception.toString().contains('404')) {
      return;
    }
    FlutterError.presentError(details);
  };

  // 8. Safe subscription manager init
  try {
    SubscriptionManager.shared.initPlatformState();
  } catch (e) {
    debugPrint('SubscriptionManager init error: $e');
  }

  // 9. Always launch the application
  runApp(const RestartWidget(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    consentForm();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      onInit: () {
        Get.put(SelectCountryController());
      },
      builder: (context, child) => ScrollConfiguration(behavior: MyBehavior(), child: child!),
      supportedLocales: S.delegate.supportedLocales,
      locale: Locale(
        S.delegate.isSupported(Locale(LanguagesScreenViewModel.selectedLanguage))
            ? LanguagesScreenViewModel.selectedLanguage
            : 'en',
      ),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          fontFamily: FontRes.regular,
          primaryColor: ColorRes.themeColor,
          splashColor: ColorRes.transparent,
          highlightColor: ColorRes.transparent,
          textSelectionTheme: const TextSelectionThemeData(cursorColor: ColorRes.davyGrey),
          useMaterial3: false),
      home: const SplashScreen(),
    );
  }

  void consentForm() async {
    if (!kIsWeb) {
      AdsService.requestConsentInfoUpdate();
    }
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
