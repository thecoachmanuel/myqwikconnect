import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/payment_auto_processing_dialog.dart';
import 'package:orange_ui/model/get_package.dart';
import 'package:orange_ui/model/user/registration_user.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/service/subscription/subscription_manager.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionSheetController extends GetxController {
  RxList<Package> packages = <Package>[].obs;
  Rx<Package?> selectedPackage = Rx(null);
  RxList<GetPackageData> adminPackages = <GetPackageData>[].obs;
  Rx<GetPackageData?> selectedAdminPackage = Rx(null);
  Function()? purchaseCallBack;

  @override
  void onInit() {
    super.onInit();
    final user = SessionManager.instance.getUser();
    if (user != null && (user.isPro == 1 || user.isVerified == 3)) {
      // Check if subscription is expired
      bool expired = false;
      if (user.proExpireDate != null && user.proExpireDate!.trim().isNotEmpty) {
        try {
          expired = DateTime.parse(user.proExpireDate!).isBefore(DateTime.now());
        } catch (_) {}
      }
      if (!expired) {
        isSubscribe.value = true;
      }
    }

    packages.value = SubscriptionManager.shared.packages;
    if (packages.isNotEmpty) {
      selectedPackage.value = SubscriptionManager.shared.packages.first;
    }
    fetchAdminPackages();
  }

  void fetchAdminPackages() async {
    try {
      final res = await ApiProvider().getPackage();
      if (res.status == true && res.data != null && res.data!.isNotEmpty) {
        adminPackages.value = res.data!;
        if (selectedAdminPackage.value == null && adminPackages.isNotEmpty) {
          selectedAdminPackage.value = adminPackages.first;
        }
      }
    } catch (e) {
      log('fetchAdminPackages error: $e');
    }
  }

  void onSubscriptionTap(Package package) {
    selectedPackage.value = package;
  }

  void onMakePurchase([Package? package]) async {
    final myUser = SessionManager.instance.getUser();
    CommonUI.lottieLoader();

    final double priceAmount = package != null && package.storeProduct.price > 0
        ? package.storeProduct.price
        : (double.tryParse(selectedAdminPackage.value?.price ?? '') ?? 5000.0);
    final int monthsCount = selectedAdminPackage.value?.months ?? (package != null ? 1 : 1);
    final String planIdentifier = package?.identifier ?? selectedAdminPackage.value?.playid ?? 'pkg_1m';

    // Initiate Paystack payment
    try {
      final paystackInit = await ApiProvider().initializePaystack(
        email: (myUser?.identity?.contains('@') == true)
            ? myUser!.identity!
            : 'user_${myUser?.id ?? 0}@orangeapp.com',
        amount: priceAmount,
        diamonds: 0,
        planId: planIdentifier,
        type: 'subscription',
        months: monthsCount,
      );

      Get.back(); // close loader

      final authUrl = paystackInit['authorization_url']?.toString();
      final reference = paystackInit['reference']?.toString();

      if (paystackInit['status'] == false || authUrl == null || authUrl.isEmpty) {
        final errorMsg = paystackInit['message']?.toString() ??
            'Could not initialize Paystack payment. Please check your Paystack API keys in Admin Settings.';
        CommonUI.snackBar(message: errorMsg);
        return;
      }

      final uri = Uri.tryParse(authUrl);

      // Sandbox reference — automatically verify and activate immediately (no manual button needed)
      if (reference != null && reference.startsWith('ORANGE_SANDBOX_')) {
        CommonUI.lottieLoader();
        final verifyRes = await ApiProvider().verifyPaystack(
          reference: reference,
          type: 'subscription',
          months: monthsCount,
        );
        Get.back(); // close loader
        if (verifyRes.status == true) {
          purchaseCallBack?.call();
          UserData? user = SessionManager.instance.getUser();
          user?.isVerified = 3;
          user?.isPro = 1;
          if (verifyRes.data != null) {
            user?.proExpireDate = verifyRes.data?.proExpireDate ?? verifyRes.data?.toString();
          }
          SessionManager.instance.setUser(user);
          isSubscribe.value = true;
          ApiProvider().updateProfile(isVerified: 3);
          SessionManager.instance.updateFirebase();
          CommonUI.snackBar(
              message: '👑 VIP Subscription activated successfully!');
          Get.back(result: true);
        } else {
          CommonUI.snackBar(
              message: verifyRes.message ?? 'Demo activation failed.');
        }
        return;
      }

      if (uri != null && await canLaunchUrl(uri)) {
        if (kIsWeb) {
          await launchUrl(uri, webOnlyWindowName: '_blank');
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      // Automatic payment verification — polls Paystack in background and auto-completes
      Get.dialog(
        PaymentAutoProcessingDialog(
          reference: reference ?? '',
          type: 'subscription',
          months: monthsCount,
          heading: 'Activating VIP...',
          description:
              'Please complete your payment in the Paystack window.\n\nYour VIP subscription will be activated automatically once payment is approved — no need to confirm manually.',
          onSuccess: (verifyRes) {
            purchaseCallBack?.call();
            UserData? user = SessionManager.instance.getUser();
            user?.isVerified = 3;
            user?.isPro = 1;
            if (verifyRes.data != null) {
              user?.proExpireDate = verifyRes.data?.proExpireDate ?? verifyRes.data?.toString();
            }
            SessionManager.instance.setUser(user);
            isSubscribe.value = true;
            ApiProvider().updateProfile(isVerified: 3);
            SessionManager.instance.updateFirebase();
            CommonUI.snackBar(
                message: '👑 VIP Subscription activated successfully!');
            Get.back(result: true);
          },
        ),
        barrierDismissible: false,
      );
      return;
    } catch (_) {}

    if (!kIsWeb && package != null) {
      bool? status = await SubscriptionManager.shared.makePurchase(package);
      Get.back();
      if (status == true) {
        purchaseCallBack?.call();
        UserData? user = SessionManager.instance.getUser();
        user?.isVerified = 3;
        SessionManager.instance.setUser(user);
        isSubscribe.value = true;
        ApiProvider().updateProfile(isVerified: 3);
        Get.back(result: true);
      }
    } else {
      Get.back();
    }
  }
}
