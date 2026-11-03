import 'dart:developer';

import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/model/get_package.dart';
import 'package:orange_ui/service/paystack/paystack_payment_service.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/service/subscription/subscription_manager.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

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

    final double priceAmount = package != null && package.storeProduct.price > 0
        ? package.storeProduct.price
        : (double.tryParse(selectedAdminPackage.value?.price ?? '') ?? 5000.0);
    final int monthsCount = selectedAdminPackage.value?.months ?? (package != null ? 1 : 1);
    final String planIdentifier = package?.identifier ?? selectedAdminPackage.value?.playid ?? 'pkg_1m';
    final email = (myUser?.identity?.contains('@') == true)
        ? myUser!.identity!
        : 'user_${myUser?.id ?? 0}@orangeapp.com';

    await PaystackPaymentService.instance.processPayment(
      context: null,
      email: email,
      amount: priceAmount,
      diamonds: 0,
      months: monthsCount,
      planId: planIdentifier,
      type: 'subscription',
      heading: 'Activating VIP...',
      description:
          'Please complete your payment in the Paystack window.\n\nYour VIP subscription will be activated automatically once payment is approved — no need to confirm manually.',
      onSuccess: (verifyRes) {
        purchaseCallBack?.call();
        CommonUI.snackBar(
            message: '👑 VIP Subscription activated successfully!');
        Get.back(result: true);
      },
      onCancel: () {
        // User closed/cancelled payment cleanly, stays on sheet
      },
    );
  }
}
