import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/const_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:orange_ui/utils/urls.dart';
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
    final isLegalOrAbout = url.toLowerCase().contains('term') ||
        url.toLowerCase().contains('privac') ||
        url.toLowerCase().contains('about') ||
        url.toLowerCase().contains('policy');

    // On web, or for Terms/Privacy/About documents, prefer the instant native reader
    if (kIsWeb || isLegalOrAbout) {
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
    final isAbout = url.toLowerCase().contains('about');

    String? found = isAbout
        ? settings?.appdata?.about
        : (isTerms
            ? settings?.appdata?.termsofuse
            : settings?.appdata?.privacypolicy);

    if (found != null && found.trim().isNotEmpty) {
      contentText = found;
      notifyListeners();
    } else {
      isLoading = true;
      notifyListeners();
    }

    final endpoint = isAbout ? 'viewAbout' : (isTerms ? 'viewTerms' : 'viewPrivacy');
    http.post(
      Uri.parse('${ConstRes.aBaseUrl}$endpoint'),
      headers: {Urls.apiKeyName: ConstRes.apiKey},
    ).then((res) {
      isLoading = false;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final page = data['data'];
        if (page != null) {
          final text = isAbout
              ? page['about']
              : (isTerms
                  ? (page['termsofuse'] ?? page['terms'])
                  : (page['privacy'] ?? page['privacypolicy']));
          if (text != null && text.toString().trim().isNotEmpty) {
            contentText = text.toString();
            final appdata = settings?.appdata;
            if (appdata != null) {
              if (isAbout) {
                appdata.about = text.toString();
              } else if (isTerms) {
                appdata.termsofuse = text.toString();
              } else {
                appdata.privacypolicy = text.toString();
              }
              SessionManager.instance.setSettings(settings);
            }
            notifyListeners();
            return;
          }
        }
      }
      if (contentText.isEmpty) {
        contentText = isAbout ? _defaultAbout : (isTerms ? _defaultTerms : _defaultPrivacy);
        notifyListeners();
      }
    }).catchError((_) {
      isLoading = false;
      if (contentText.isEmpty) {
        contentText = isAbout ? _defaultAbout : (isTerms ? _defaultTerms : _defaultPrivacy);
        notifyListeners();
      }
    });
  }

  Widget buildNativeReaderContent(BuildContext context) {
    if (isLoading && contentText.isEmpty) {
      return Center(
        child: CommonUI.lottieWidget(),
      );
    }

    final isPrivacy = title.toLowerCase().contains('privac');
    final isAbout = title.toLowerCase().contains('about');

    final raw = contentText.isNotEmpty
        ? contentText
        : (isPrivacy
            ? _defaultPrivacy
            : (isAbout ? _defaultAbout : _defaultTerms));

    final cleanSections = _parseHtmlIntoSections(raw);

    return Container(
      color: const Color(0xFFF9FAFB),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        itemCount: cleanSections.length + 1, // +1 for hero card
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          if (index == 0) {
            // Modern QwikConnect Hero Card
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorRes.lightOrange, ColorRes.themeColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: ColorRes.themeColor.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPrivacy
                          ? Icons.security_rounded
                          : (isAbout ? Icons.info_outline_rounded : Icons.gavel_rounded),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.isNotEmpty
                              ? title
                              : (isPrivacy
                                  ? 'Privacy Policy'
                                  : (isAbout ? 'About QwikConnect' : 'Terms of Use')),
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: FontRes.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isPrivacy
                              ? 'How QwikConnect protects and manages your data'
                              : (isAbout
                                  ? 'Connecting authentic people across Nigeria and beyond'
                                  : 'QwikConnect platform rules and user agreements'),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontFamily: FontRes.regular,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          final sec = cleanSections[index - 1];
          if (sec.type == _SectionType.heading) {
            return Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: ColorRes.grey5.withValues(alpha: 0.6)),
              ),
              child: Text(
                sec.text,
                style: const TextStyle(
                  fontFamily: FontRes.bold,
                  fontSize: 16,
                  color: ColorRes.davyGrey,
                  height: 1.3,
                ),
              ),
            );
          } else if (sec.type == _SectionType.bullet) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 10),
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
                        fontFamily: FontRes.medium,
                        fontSize: 14,
                        color: ColorRes.dimGrey3,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                sec.text,
                style: const TextStyle(
                  fontFamily: FontRes.regular,
                  fontSize: 14,
                  color: ColorRes.dimGrey3,
                  height: 1.6,
                ),
              ),
            );
          }
        },
      ),
    );
  }

  List<_ParsedSection> _parseHtmlIntoSections(String html) {
    final List<_ParsedSection> list = [];
    String text = html
        .replaceAll(RegExp(r'<\/?div[^>]*>'), '\n')
        .replaceAll(RegExp(r'<\/?p[^>]*>'), '\n')
        .replaceAll(RegExp(r'<br\s*\/?>'), '\n')
        .replaceAll(RegExp(r'<h[1-6][^>]*>'), '\n### ')
        .replaceAll(RegExp(r'<\/h[1-6]>'), '\n')
        .replaceAll(RegExp(r'<li>'), '\n• ')
        .replaceAll(RegExp(r'<\/li>'), '\n')
        .replaceAll(RegExp(r'<\/?ul[^>]*>'), '\n')
        .replaceAll(RegExp(r'<\/?ol[^>]*>'), '\n')
        .replaceAll(RegExp(r'<\/?span[^>]*>'), '')
        .replaceAll(RegExp(r'<\/?strong[^>]*>'), '')
        .replaceAll(RegExp(r'<\/?b[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");

    final lines = text.split('\n');
    for (var line in lines) {
      String trimmed = line.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('###')) {
        final content = trimmed.replaceAll('###', '').trim();
        if (content.isNotEmpty) {
          list.add(_ParsedSection(_SectionType.heading, content));
        }
      } else if (trimmed.startsWith('•') || trimmed.startsWith('-')) {
        final content = trimmed.replaceFirst(RegExp(r'^[•\-]\s*'), '').trim();
        if (content.isNotEmpty) {
          list.add(_ParsedSection(_SectionType.bullet, content));
        }
      } else {
        list.add(_ParsedSection(_SectionType.paragraph, trimmed));
      }
    }
    return list;
  }

  static const String _defaultAbout = '''
<h3>About QwikConnect</h3>
<p>Welcome to QwikConnect, Nigeria's premier interactive dating and social discovery platform designed to connect authentic individuals through genuine interests, proximity discovery, real-time messaging, and high-definition live streaming.</p>
<h3>Our Mission</h3>
<p>Our mission is to create a vibrant, safe, and empowering space where meaningful relationships flourish. Whether seeking love, friendship, or creative collaboration, QwikConnect makes authentic human connections effortless and fun.</p>
<h3>Core Features</h3>
<p>• Smart Proximity Discovery: Match with interesting verified profiles near you using interactive map filtering.</p>
<p>• Interactive Live Streaming: Stream your passions, join live broadcasts, and support creators with virtual gifts.</p>
<p>• Verified Security: Rigorous face and photo verification ensures you connect with genuine, verified community members.</p>
<p>• Seamless In-App Virtual Economy: Secure diamond packs and wallet management powered by Paystack.</p>
<h3>Contact & Community Support</h3>
<p>Have questions, partnership inquiries, or need assistance? Reach our dedicated support team at support@qwikconnect.ng.</p>
''';

  static const String _defaultTerms = '''
<h3>1. Acceptance of Terms</h3>
<p>By creating an account, downloading, or using the QwikConnect Dating & Live Stream platform, you agree to be bound by these Terms of Service. If you disagree with any terms, please discontinue use.</p>
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
<p>Your privacy is important to us. QwikConnect Dating & Live Stream values and protects the personal data you share with us.</p>
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
