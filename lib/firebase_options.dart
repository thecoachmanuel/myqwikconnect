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
    apiKey: 'AIzaSyDRVmYrXYD9lGjDJmXMZ9criz4uBPO6cDM',
    appId: '1:260849839740:web:ddb869372937477ecca3f9',
    messagingSenderId: '260849839740',
    projectId: 'orange-16f8b-72bea',
    authDomain: 'qwikconnect.com.ng',
    storageBucket: 'orange-16f8b-72bea.firebasestorage.app',
    measurementId: 'G-X4CT0807L2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDluEyxM0C-wZitShXNG-SbRqqXl9Ct_4U',
    appId: '1:260849839740:android:79b518c2d71565f1f85c74',
    messagingSenderId: '260849839740',
    projectId: 'orange-16f8b-72bea',
    storageBucket: 'orange-16f8b-72bea.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCbGuyjzXcnntY33RIzfPLfoHkuv8fXy3c',
    appId: '1:260849839740:ios:575c08272e545455f85c74',
    messagingSenderId: '260849839740',
    projectId: 'orange-16f8b-72bea',
    storageBucket: 'orange-16f8b-72bea.appspot.com',
    iosBundleId: 'com.retrytech.orangeFlutter',
  );
}
