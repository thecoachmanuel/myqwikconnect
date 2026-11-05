/// On Android and iOS the Google Maps key is read by the native SDK from the
/// app manifest at build time, so nothing is loaded at runtime.
const bool googleMapsScriptRequired = false;

Future<void> ensureGoogleMapsLoaded(String? apiKey) async {}
