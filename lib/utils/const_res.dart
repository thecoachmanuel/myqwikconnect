class ConstRes {
  ///------------------------ Backend urls and key ------------------------///

  static const String base = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://myqwikconnectadmin.vercel.app/',
  ); // Base url (can be overridden at build time via --dart-define=BACKEND_URL=...)
  static const String aBaseUrl = '${base}api/';
  static const String aImageBaseUrl = '${base}public/storage/';
  static const String apiKey = '123';

  ///------------------------ Agora app Id ------------------------///
  static const String agoraAppId = "b07fffcaca5c4c67a4f00bd2924d7c52"; // Agora app id
  static const String customerId = ""; // Agora customer id
  static const String customerSecret = ""; // Agora customer secret

  ///------------------------ RevenueCate ------------------------///
  static const String revenueCatAndroidApiKey = ""; // RevenueCat android api key
  static const String revenueCatAppleApiKey = ""; // RevenueCat apple api key
}
