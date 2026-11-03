import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/payment_auto_processing_dialog.dart';
import 'package:orange_ui/model/get_diamond_pack.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:stacked/stacked.dart';
import 'package:url_launcher/url_launcher.dart';

class BottomDiamondShopModel extends BaseViewModel {
  bool isLoading = false;
  RxList<CoinPlan> coinPlans = <CoinPlan>[].obs;
  RxList<Package> offerings = <Package>[].obs;

  void init() {
    fetchDiamondPackage();
  }

  void fetchDiamondPackage() {
    isLoading = true;
    notifyListeners();
    ApiProvider().getDiamondPack().then((value) async {
      coinPlans.clear();
      final currency = SessionManager.instance.getSettings()?.appdata?.currency ?? '₦';
      final currencySymbol = (currency.trim().isNotEmpty && currency.trim() != '\$')
          ? currency.trim()
          : '₦';

      for (DiamondPack data in value.data ?? []) {
        final price = data.price != null && data.price! > 0
            ? data.price!
            : ((data.amount ?? 100) * 15);
        final formattedPrice = price.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

        coinPlans.add(CoinPlan(
          data.amount ?? 0,
          data.id ?? -1,
          data.androidProductId ?? 'coin_${data.amount}',
          '$currencySymbol$formattedPrice',
          amountPrice: price.toDouble(),
        ));
      }
      isLoading = false;
      notifyListeners();
    });
  }

  void makePurchase(CoinPlan coinPlan) async {
    CommonUI.lottieLoader();
    final myUser = SessionManager.instance.getUser();

    try {
      final paystackInit = await ApiProvider().initializePaystack(
        email: (myUser?.identity?.contains('@') == true)
            ? myUser!.identity!
            : 'user_${myUser?.id ?? 0}@orangeapp.com',
        amount: coinPlan.amountPrice > 0 ? coinPlan.amountPrice : 1500,
        diamonds: coinPlan.coin,
        planId: coinPlan.coinPackageId.toString(),
        type: 'diamond',
      );

      Get.back(); // close loader

      final authUrl = paystackInit['authorization_url']?.toString();
      final reference = paystackInit['reference']?.toString();

      if (paystackInit['status'] == false || authUrl == null || authUrl.isEmpty) {
        final errorMsg = paystackInit['message']?.toString() ??
            'Could not initialize Paystack payment. Please check your Paystack API keys.';
        CommonUI.snackBar(message: errorMsg);
        return;
      }

      final uri = Uri.tryParse(authUrl);

      // Sandbox reference — automatically verify and credit immediately (no manual button needed)
      if (reference != null && reference.startsWith('ORANGE_SANDBOX_')) {
        CommonUI.lottieLoader();
        final verifyRes = await ApiProvider().verifyPaystack(
          reference: reference,
          diamonds: coinPlan.coin,
          type: 'diamond',
        );
        Get.back(); // close loader
        if (verifyRes.status == true) {
          CommonUI.snackBar(
              message: '💎 ${coinPlan.coin} diamonds added to your wallet!');
          final currentUser = SessionManager.instance.getUser();
          if (currentUser != null) {
            currentUser.wallet = (currentUser.wallet ?? 0) + coinPlan.coin;
            SessionManager.instance.setUser(currentUser);
          }
          ApiProvider().fetchMyUserProfile();
          Get.back(result: coinPlan.coin);
        } else {
          CommonUI.snackBar(
              message: verifyRes.message ?? 'Demo payment failed.');
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
          type: 'diamond',
          diamonds: coinPlan.coin,
          heading: 'Adding Diamonds...',
          description:
              'Please complete your payment of ${coinPlan.priceString} in the Paystack window.\n\nYour diamonds will be added to your wallet automatically once approved — no need to confirm manually.',
          onSuccess: (verifyRes) {
            CommonUI.snackBar(
                message: '💎 ${coinPlan.coin} diamonds added to your wallet!');
            final currentUser = SessionManager.instance.getUser();
            if (currentUser != null) {
              currentUser.wallet = (currentUser.wallet ?? 0) + coinPlan.coin;
              SessionManager.instance.setUser(currentUser);
            }
            ApiProvider().fetchMyUserProfile();
            Get.back(result: coinPlan.coin);
          },
        ),
        barrierDismissible: false,
      );
    } catch (e) {
      Get.back();
      CommonUI.snackBar(message: 'Payment initialization failed. Please try again.');
    }
  }
}

class CoinPlan {
  int coin;
  int coinPackageId;
  String id;
  String priceString;
  double amountPrice;

  CoinPlan(this.coin, this.coinPackageId, this.id, this.priceString, {this.amountPrice = 0});
}
