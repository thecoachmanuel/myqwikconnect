import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/payment_auto_processing_dialog.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/service/subscription/subscription_manager.dart';
import 'package:url_launcher/url_launcher.dart';

import 'paystack_payment_stub.dart'
    if (dart.library.html) 'paystack_payment_web.dart';

class PaystackPaymentService {
  static final PaystackPaymentService instance = PaystackPaymentService._();
  PaystackPaymentService._();

  Future<void> processPayment({
    required BuildContext? context,
    required String email,
    required double amount,
    int diamonds = 0,
    int months = 1,
    required String planId,
    required String type, // 'diamond' or 'subscription'
    String? heading,
    String? description,
    required Function(UserModel userModel) onSuccess,
    VoidCallback? onCancel,
  }) async {
    CommonUI.lottieLoader();
    final myUser = SessionManager.instance.getUser();

    // Ensure a valid, RFC-compliant email address for Paystack
    String resolvedEmail = email.trim().toLowerCase();
    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+(\.[\w\-]+)+$');
    if (resolvedEmail.isEmpty || !emailRegex.hasMatch(resolvedEmail)) {
      final identity = (myUser?.identity ?? '').trim().toLowerCase();
      if (identity.isNotEmpty && emailRegex.hasMatch(identity)) {
        resolvedEmail = identity;
      } else {
        final uid = (myUser?.id ?? 0) > 0 ? myUser!.id : DateTime.now().millisecondsSinceEpoch;
        resolvedEmail = 'user_$uid@gmail.com';
      }
    }

    try {
      final paystackInit = await ApiProvider().initializePaystack(
        email: resolvedEmail,
        amount: amount > 0 ? amount : 1500,
        diamonds: diamonds,
        planId: planId,
        type: type,
        months: months,
      );

      Get.back(); // close initial loader

      final authUrl = paystackInit['authorization_url']?.toString();
      final reference = paystackInit['reference']?.toString();
      final accessCode = paystackInit['access_code']?.toString();
      final publicKey = paystackInit['public_key']?.toString();
      final returnedEmail = (paystackInit['email']?.toString() ?? resolvedEmail).trim().toLowerCase();

      if (paystackInit['status'] == false || authUrl == null || authUrl.isEmpty) {
        final errorMsg = paystackInit['message']?.toString() ??
            'Could not initialize Paystack payment. Please verify your Paystack API keys.';
        CommonUI.snackBar(message: errorMsg);
        return;
      }

      // 1. Web Flow: Use Paystack Inline Popup directly in-app
      if (kIsWeb && publicKey != null && publicKey.trim().isNotEmpty) {
        final amountKobo = (amount * 100).round();
        final webResult = await launchPaystackInlinePlatform(
          publicKey: publicKey.trim(),
          email: returnedEmail,
          amountKobo: amountKobo,
          reference: reference ?? '',
          accessCode: accessCode,
        );

        final resultStatus = webResult['status']?.toString();

        if (resultStatus == 'cancelled') {
          // User clicked X/cancel on the Paystack popup
          onCancel?.call();
          return;
        }

        if (resultStatus == 'success') {
          // User completed payment on Paystack popup
          CommonUI.lottieLoader();
          final verifiedRef = webResult['reference']?.toString() ?? reference ?? '';
          final verifyRes = await ApiProvider().verifyPaystack(
            reference: verifiedRef,
            diamonds: diamonds,
            months: months,
            type: type,
          );
          Get.back(); // close verifying loader

          if (verifyRes.status == true ||
              (verifyRes.message ?? '').toLowerCase().contains('already been credited')) {
            _applySuccessfulPayment(type: type, diamonds: diamonds, months: months, verifyRes: verifyRes);
            onSuccess(verifyRes);
          } else {
            CommonUI.snackBar(message: verifyRes.message ?? 'Payment verification failed.');
          }
          return;
        }

        // If inline returned error or not supported, fall through to URL launch
      }

      // 2. Mobile Flow (or Web fallback): In-App Browser View
      final uri = Uri.tryParse(authUrl);
      if (uri != null && await canLaunchUrl(uri)) {
        if (kIsWeb) {
          await launchUrl(uri, webOnlyWindowName: '_blank');
        } else {
          // Keep user in-app with Chrome Custom Tabs / SFSafariViewController
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
        }
      }

      // Background auto-poller dialog
      Get.dialog(
        PaymentAutoProcessingDialog(
          reference: reference ?? '',
          type: type,
          diamonds: diamonds,
          months: months,
          heading: heading,
          description: description,
          onSuccess: (verifyRes) {
            _applySuccessfulPayment(type: type, diamonds: diamonds, months: months, verifyRes: verifyRes);
            onSuccess(verifyRes);
          },
          onCancel: onCancel,
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      Get.back();
      CommonUI.snackBar(message: 'Payment initialization error. Please try again.');
    }
  }

  static void _applySuccessfulPayment({
    required String type,
    required int diamonds,
    required int months,
    required UserModel verifyRes,
  }) {
    final currentUser = SessionManager.instance.getUser();
    if (currentUser != null) {
      if (type == 'diamond') {
        currentUser.wallet = (currentUser.wallet ?? 0) + diamonds;
        SessionManager.instance.setUser(currentUser);
        SessionManager.instance.walletRx.value = currentUser.wallet ?? 0;
      } else if (type == 'subscription') {
        currentUser.isVerified = 3;
        currentUser.isPro = 1;
        if (verifyRes.data != null) {
          currentUser.proExpireDate =
              verifyRes.data?.proExpireDate ?? verifyRes.data?.toString();
        }
        SessionManager.instance.setUser(currentUser);
        isSubscribe.value = true;
        ApiProvider().updateProfile(isVerified: 3);
        SessionManager.instance.updateFirebase();
      }
      // Refresh profile in background
      ApiProvider().fetchMyUserProfile();
    }
  }
}

