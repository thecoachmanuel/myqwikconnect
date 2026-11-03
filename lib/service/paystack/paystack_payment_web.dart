// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

Future<Map<String, dynamic>> launchPaystackInlinePlatform({
  required String publicKey,
  required String email,
  required int amountKobo,
  required String reference,
  String? accessCode,
}) {
  final completer = Completer<Map<String, dynamic>>();

  StreamSubscription? sub;
  sub = html.window.on['orange_paystack_response'].listen((event) {
    if (event is html.CustomEvent && event.detail != null) {
      sub?.cancel();
      try {
        final rawDetail = event.detail;
        Map<String, dynamic> data;
        if (rawDetail is String) {
          data = jsonDecode(rawDetail);
        } else if (rawDetail is Map) {
          data = Map<String, dynamic>.from(rawDetail);
        } else {
          data = {'status': 'cancelled'};
        }
        completer.complete(data);
      } catch (e) {
        completer.complete({'status': 'cancelled', 'error': e.toString()});
      }
    }
  });

  try {
    final payload = jsonEncode({
      'key': publicKey,
      'email': email,
      'amount': amountKobo,
      'ref': reference,
      'access_code': accessCode ?? '',
      'currency': 'NGN',
    });
    html.window.dispatchEvent(
      html.CustomEvent('orange_open_paystack', detail: payload),
    );
  } catch (e) {
    sub.cancel();
    completer.complete({'status': 'error', 'message': e.toString()});
  }

  return completer.future;
}
