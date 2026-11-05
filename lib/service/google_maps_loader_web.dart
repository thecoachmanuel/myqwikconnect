import 'dart:js_interop';

/// The Maps JavaScript API must be present in the page before any map is built.
/// It is injected here with the key the admin configured in the backend settings
/// (see `window.orangeLoadGoogleMaps` in `web/index.html`).
@JS('orangeLoadGoogleMaps')
external JSPromise<JSBoolean> _orangeLoadGoogleMaps(JSString apiKey);

const bool googleMapsScriptRequired = true;

/// Loads the Maps JavaScript API using [apiKey].
///
/// When [apiKey] is null or empty the API is loaded without a key, which makes
/// Google render its "For development purposes only" map instead of a keyed one.
Future<void> ensureGoogleMapsLoaded(String? apiKey) async {
  try {
    await _orangeLoadGoogleMaps((apiKey ?? '').trim().toJS).toDart;
  } catch (_) {
    // Nothing to do: the map screen will stay on its loading state rather than
    // taking the whole screen down with it.
  }
}
