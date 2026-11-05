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
  // Constructed lazily: `webview_flutter` has no web implementation, so
  // building this eagerly would throw on Flutter Web and blank the screen.
  WebViewControllerPlus? controller;
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
<p>Welcome to QwikConnect — a modern dating, chat and social discovery platform built to help authentic people meet, connect and build real relationships.</p>
<p>QwikConnect brings together smart proximity discovery, verified profiles, real-time messaging, stories and high-definition live streaming in one fast, friendly experience.</p>
<h3>Our Mission</h3>
<p>To connect authentic people through real conversations, verified identities and shared interests — in a safe, respectful and exciting space where lasting relationships can grow.</p>
<h3>Our Vision</h3>
<p>To become Africa's most trusted dating and social community, where everyone can express themselves freely and connect with confidence, without fake profiles or harassment.</p>
<h3>What You Can Do on QwikConnect</h3>
<p>• Smart Proximity Discovery: find and match with verified profiles near you using distance filters and an interactive map.</p>
<p>• Verified Profiles: face and photo verification keep the community genuine and free from impersonation.</p>
<p>• Real-Time Chat & Calls: send messages, share photos and enjoy high-quality audio and video conversations.</p>
<p>• Interactive Live Streaming: go live, watch talented creators and support them with virtual gifts.</p>
<p>• Stories & Posts: share moments and stay close to the people who matter.</p>
<p>• Privacy First: stay in control with "Show Me on Map", "Go Anonymous" mode and granular privacy controls.</p>
<p>• Secure Virtual Economy: buy diamond packs and manage your wallet securely through Paystack.</p>
<h3>Our Community Values</h3>
<p>• Respect: kindness and consent always come first.</p>
<p>• Authenticity: real people, real profiles, real conversations.</p>
<p>• Safety: active moderation, reporting tools and verification to protect everyone.</p>
<p>• Inclusion: a welcoming space for all adults, whatever their background.</p>
<h3>Contact Us</h3>
<p>Have questions, partnership enquiries or need help? Our support team is always happy to hear from you at support@qwikconnect.ng.</p>
''';

  static const String _defaultTerms = '''
<h3>1. Acceptance of Terms</h3>
<p>By creating an account, downloading or using the QwikConnect platform, you agree to be bound by these Terms of Service. If you disagree with any part of them, please discontinue use.</p>
<h3>2. Eligibility & Age Requirement</h3>
<p>You must be at least 18 years of age to create an account and use QwikConnect. Registration by minors is strictly prohibited.</p>
<h3>3. Account Security & Verification</h3>
<p>You are responsible for keeping your login details confidential. Submitting fraudulent documents or impersonating others will result in permanent account termination.</p>
<h3>4. Community Guidelines</h3>
<p>Respect others. Harassment, bullying, hate speech, non-consensual or explicit content, spam and fraudulent impersonation are strictly banned and will result in immediate account termination.</p>
<h3>5. Live Streaming & Social Features</h3>
<p>Broadcasters must follow all community safety guidelines. Live broadcasts violating safety policies are ended in real time and the account may be suspended.</p>
<h3>6. Diamonds, Virtual Gifts & Payments</h3>
<p>Virtual diamonds may be purchased via Paystack and can be used for in-app gifting, direct messaging and premium discovery. All purchases are final and non-refundable. Payouts require completed verification and minimum thresholds.</p>
<h3>7. Location Features & Privacy Controls</h3>
<p>QwikConnect offers proximity-based matching and map discovery. You stay in control with "Show Me on Map" and "Go Anonymous" mode at any time.</p>
<h3>8. Termination</h3>
<p>We may suspend or delete your account at any time for any breach of these Terms. You may delete your account from the Settings menu.</p>
<h3>9. Contact Us</h3>
<p>For questions about these Terms, reach us in the in-app support centre or email support@qwikconnect.ng.</p>
''';

  static const String _defaultPrivacy = '''
<h3>1. Introduction</h3>
<p>Your privacy matters to us. This Privacy Policy explains how QwikConnect collects, uses, stores and shares your personal information.</p>
<h3>2. Information We Collect</h3>
<p>Account details (name, username, email, phone, date of birth, gender, preferences, bio and photos), location data (with your consent, for nearby matches and map features), messages and media you share, verification documents, and device/usage information.</p>
<h3>3. How We Use Your Information</h3>
<p>To provide and improve matching and live streaming, deliver messaging and calls, enable proximity discovery, verify authenticity, detect fraud and process virtual diamond transactions and payouts.</p>
<h3>4. Privacy Controls & Ephemeral Media</h3>
<p>Toggle "Show Me on Map" or enable "Go Anonymous" at any time. Stories expire and are removed from storage after 24 hours.</p>
<h3>5. Information Sharing & Third Parties</h3>
<p>We do not sell your personal data. We share it only with trusted providers needed to run the App (such as Google Firebase, Agora and Paystack), or where required by law.</p>
<h3>6. Data Retention & Security</h3>
<p>We apply strong technical and organisational measures to protect your data. Inactive accounts and expired media are removed periodically.</p>
<h3>7. Your Rights</h3>
<p>Depending on your jurisdiction you may access, correct, download or delete your personal data — in the App settings or by contacting our Data Protection Officer.</p>
<h3>8. Children's Privacy</h3>
<p>Our services are strictly for people aged 18 and older. We do not knowingly collect data from minors.</p>
<h3>9. Contact Us</h3>
<p>For privacy questions or data requests, contact our privacy team at privacy@qwikconnect.ng.</p>
''';
}

enum _SectionType { heading, paragraph, bullet }

class _ParsedSection {
  final _SectionType type;
  final String text;
  _ParsedSection(this.type, this.text);
}
