import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/const_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:stacked/stacked.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

class WebViewScreenViewModel extends BaseViewModel {
  WebViewControllerPlus controller = WebViewControllerPlus();
  bool showNativeReader = true;
  bool isLoading = false;
  String contentText = '';
  String title = '';

  void init(String url, String appBarTitle) {
    title = appBarTitle;
    final isTermsOrPrivacy = url.toLowerCase().contains('term') ||
        url.toLowerCase().contains('privac') ||
        url.toLowerCase().contains('policy');

    // On web, or for Terms/Privacy documents, prefer the instant native reader
    if (kIsWeb || isTermsOrPrivacy) {
      showNativeReader = true;
      _loadContent(url);
    } else {
      showNativeReader = false;
      try {
        controller = WebViewControllerPlus()
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (url) async {},
            ),
          )
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..loadRequest(Uri.parse(ConstRes.base + url));
      } catch (_) {
        showNativeReader = true;
        _loadContent(url);
      }
    }
    notifyListeners();
  }

  void _loadContent(String url) {
    final settings = SessionManager.instance.getSettings();
    final isTerms = url.toLowerCase().contains('term');

    String? found = isTerms
        ? settings?.appdata?.termsofuse
        : settings?.appdata?.privacypolicy;

    if (found != null && found.trim().isNotEmpty) {
      contentText = found;
      notifyListeners();
      return;
    }

    // Background fetch if not available in cache
    isLoading = true;
    notifyListeners();
    ApiProvider().getSettingData().then((val) {
      isLoading = false;
      if (val.status == true && val.data != null) {
        SessionManager.instance.setSettings(val.data);
        contentText = isTerms
            ? (val.data?.appdata?.termsofuse ?? '')
            : (val.data?.appdata?.privacypolicy ?? '');
      }
      if (contentText.isEmpty) {
        contentText = isTerms ? _defaultTerms : _defaultPrivacy;
      }
      notifyListeners();
    }).catchError((_) {
      isLoading = false;
      contentText = isTerms ? _defaultTerms : _defaultPrivacy;
      notifyListeners();
    });
  }

  Widget buildNativeReaderContent(BuildContext context) {
    if (isLoading && contentText.isEmpty) {
      return Center(
        child: CommonUI.lottieWidget(),
      );
    }

    final raw = contentText.isNotEmpty
        ? contentText
        : (title.toLowerCase().contains('privac')
            ? _defaultPrivacy
            : _defaultTerms);

    final cleanSections = _parseHtmlIntoSections(raw);

    return Container(
      color: ColorRes.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: cleanSections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final sec = cleanSections[index];
          if (sec.type == _SectionType.heading) {
            return Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Text(
                sec.text,
                style: const TextStyle(
                  fontFamily: FontRes.bold,
                  fontSize: 18,
                  color: ColorRes.davyGrey,
                  height: 1.4,
                ),
              ),
            );
          } else if (sec.type == _SectionType.bullet) {
            return Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 7, right: 10),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: ColorRes.themeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      sec.text,
                      style: const TextStyle(
                        fontFamily: FontRes.regular,
                        fontSize: 14,
                        color: ColorRes.dimGrey3,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Text(
              sec.text,
              style: const TextStyle(
                fontFamily: FontRes.regular,
                fontSize: 14,
                color: ColorRes.dimGrey3,
                height: 1.6,
              ),
            );
          }
        },
      ),
    );
  }

  List<_ParsedSection> _parseHtmlIntoSections(String html) {
    final List<_ParsedSection> list = [];
    final text = html
        .replaceAll(RegExp(r'<\/?div[^>]*>'), '\n')
        .replaceAll(RegExp(r'<\/?span[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    final lines = text.split('\n');
    for (var line in lines) {
      String trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('<h3>') || trimmed.startsWith('<h2>') || trimmed.startsWith('<h1>')) {
        final content = trimmed.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (content.isNotEmpty) {
          list.add(_ParsedSection(_SectionType.heading, content));
        }
      } else if (trimmed.startsWith('<li>') || trimmed.contains('<li>')) {
        final items = trimmed.split('<li>');
        for (var it in items) {
          final c = it.replaceAll(RegExp(r'<[^>]*>'), '').trim();
          if (c.isNotEmpty) {
            list.add(_ParsedSection(_SectionType.bullet, c));
          }
        }
      } else {
        final content = trimmed.replaceAll(RegExp(r'<[^>]*>'), '').trim();
        if (content.isNotEmpty) {
          list.add(_ParsedSection(_SectionType.paragraph, content));
        }
      }
    }
    return list;
  }

  static const String _defaultTerms = '''
<h3>1. Acceptance of Terms</h3>
<p>By creating an account, downloading, or using the Orange Dating & Live Stream platform, you agree to be bound by these Terms of Service. If you disagree with any terms, please discontinue use.</p>
<h3>2. Eligibility & Age Verification</h3>
<p>You must be at least 18 years of age to access or use this service. Registration by minors is strictly prohibited.</p>
<h3>3. Community Guidelines & Safety</h3>
<p>Respect others. Harassment, abuse, hate speech, inappropriate or non-consensual content, and fraudulent impersonation are strictly banned and will result in immediate account termination.</p>
<h3>4. Virtual Diamonds & Payments</h3>
<p>Virtual diamonds may be purchased via Paystack. Diamonds enable in-app gifting, direct messaging, and premium discovery. Diamond redemptions are subject to minimum earning thresholds.</p>
<h3>5. Live Streaming & Content Rules</h3>
<p>Broadcasters must follow all community safety guidelines. Live broadcasts violating safety policies are terminated in real time.</p>
''';

  static const String _defaultPrivacy = '''
<h3>1. Introduction</h3>
<p>Your privacy is important to us. Orange Dating & Live Stream values and protects the personal data you share with us.</p>
<h3>2. Information We Collect</h3>
<p>We collect account details (name, email, age, gender), location coordinates (for proximity matching with your permission), and profile photos.</p>
<h3>3. Privacy Controls</h3>
<p>You have full control over your privacy settings, including Show Me on Map and Go Anonymous mode at any time.</p>
<h3>4. Data Security</h3>
<p>We apply high industry encryption and security measures to protect your communications and personal data.</p>
<h3>5. Contact Us</h3>
<p>If you have any questions or data requests, please contact our support team in the app.</p>
''';
}

enum _SectionType { heading, paragraph, bullet }

class _ParsedSection {
  final _SectionType type;
  final String text;
  _ParsedSection(this.type, this.text);
}
