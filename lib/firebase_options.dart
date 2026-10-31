import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCbGuyjzXcnntY33RIzfPLfoHkuv8fXy3c',
    appId: '1:670241921181:web:79b518c2d71565f1f85c74',
    messagingSenderId: '670241921181',
    projectId: 'orange-16f8b',
    authDomain: 'orange-16f8b.firebaseapp.com',
    storageBucket: 'orange-16f8b.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDluEyxM0C-wZitShXNG-SbRqqXl9Ct_4U',
    appId: '1:670241921181:android:79b518c2d71565f1f85c74',
    messagingSenderId: '670241921181',
    projectId: 'orange-16f8b',
    storageBucket: 'orange-16f8b.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCbGuyjzXcnntY33RIzfPLfoHkuv8fXy3c',
    appId: '1:670241921181:ios:575c08272e545455f85c74',
    messagingSenderId: '670241921181',
    projectId: 'orange-16f8b',
    storageBucket: 'orange-16f8b.appspot.com',
    iosBundleId: 'com.retrytech.orangeFlutter',
  );
}

