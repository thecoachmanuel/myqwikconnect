import 'dart:async';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:orange_ui/utils/style_res.dart';

class PaymentAutoProcessingDialog extends StatefulWidget {
  final String reference;
  final String type;
  final int diamonds;
  final int months;
  final String? heading;
  final String? description;
  final Function(UserModel userModel) onSuccess;
  final VoidCallback? onCancel;

  const PaymentAutoProcessingDialog({
    super.key,
    required this.reference,
    required this.type,
    this.diamonds = 0,
    this.months = 1,
    this.heading,
    this.description,
    required this.onSuccess,
    this.onCancel,
  });

  @override
  State<PaymentAutoProcessingDialog> createState() =>
      _PaymentAutoProcessingDialogState();
}

class _PaymentAutoProcessingDialogState
    extends State<PaymentAutoProcessingDialog> with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _isChecking = false;
  int _attemptCount = 0;
  static const int _maxAttempts = 80; // 80 * 3s = 4 minutes
  String _statusMessage = 'Waiting for payment confirmation...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initial verification after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _checkPayment();
    });
    // Recurring verification every 3 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted) {
        _checkPayment();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When user returns from browser to app, immediately check payment
    if (state == AppLifecycleState.resumed && mounted) {
      _checkPayment();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPayment() async {
    if (_isChecking || !mounted) return;
    _isChecking = true;
    _attemptCount++;

    if (_attemptCount > _maxAttempts) {
      _pollTimer?.cancel();
      if (mounted) {
        setState(() {
          _statusMessage = 'Verification timed out.';
        });
      }
      _isChecking = false;
      return;
    }

    try {
      final verifyRes = await ApiProvider().verifyPaystack(
        reference: widget.reference,
        diamonds: widget.diamonds,
        months: widget.months,
        type: widget.type,
      );

      if (!mounted) return;

      if (verifyRes.status == true) {
        _pollTimer?.cancel();
        // Close the dialog and trigger the success callback
        Navigator.of(context, rootNavigator: true).pop(true);
        widget.onSuccess(verifyRes);
        return;
      }

      // If already credited, also treat as success
      final msg = (verifyRes.message ?? '').toLowerCase();
      if (msg.contains('already been credited')) {
        _pollTimer?.cancel();
        Navigator.of(context, rootNavigator: true).pop(true);
        widget.onSuccess(verifyRes);
        return;
      }
    } catch (_) {
      // Ignore network blips during polling
    } finally {
      if (mounted) {
        _isChecking = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: SmoothRectangleBorder(
        borderRadius:
            SmoothBorderRadius(cornerRadius: 22, cornerSmoothing: 1),
      ),
      backgroundColor: ColorRes.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius:
                SmoothBorderRadius(cornerRadius: 22, cornerSmoothing: 1),
          ),
          color: ColorRes.white,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top circular gradient icon with spinner
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: StyleRes.linearGradient,
                    boxShadow: [
                      BoxShadow(
                        color: ColorRes.themeColor.withValues(alpha: 0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.credit_card_rounded,
                      color: ColorRes.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 82,
                  height: 82,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(ColorRes.themeColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Heading
            Text(
              widget.heading ?? 'Processing Payment...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: FontRes.bold,
                fontSize: 19,
                color: ColorRes.davyGrey,
              ),
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              widget.description ??
                  'Please complete your payment in the browser window.\n\nYour transaction will be verified automatically — no need to confirm manually.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: ColorRes.dimGrey3,
                fontFamily: FontRes.regular,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),

            // Live status badge
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ColorRes.grey10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ColorRes.themeColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusMessage,
                    style: const TextStyle(
                      fontFamily: FontRes.medium,
                      fontSize: 12,
                      color: ColorRes.davyGrey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Cancel button
            InkWell(
              onTap: () {
                _pollTimer?.cancel();
                Navigator.of(context, rootNavigator: true).pop();
                widget.onCancel?.call();
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 42,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorRes.grey5),
                ),
                child: Text(
                  S.current.cancel,
                  style: const TextStyle(
                    fontFamily: FontRes.semiBold,
                    fontSize: 14,
                    color: ColorRes.davyGrey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
