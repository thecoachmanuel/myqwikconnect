import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/confirmation_dialog.dart';
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

      // Sandbox reference — show instant native confirmation without opening URL
      if (reference != null && reference.startsWith('ORANGE_SANDBOX_')) {
        Get.dialog(
          ConfirmationDialog(
            heading: '🧪 Demo Payment',
            description:
                'Sandbox mode is active. Tap "Complete" to simulate a successful payment of ${coinPlan.priceString} and receive ${coinPlan.coin} diamonds instantly.',
            textButton: 'Complete Demo Purchase',
            onTap: () async {
              Get.back();
              CommonUI.lottieLoader();
              final verifyRes = await ApiProvider().verifyPaystack(
                reference: reference,
                diamonds: coinPlan.coin,
                type: 'diamond',
              );
              Get.back();
              if (verifyRes.status == true) {
                CommonUI.snackBar(
                    message: 'Added ${coinPlan.coin} diamonds to your wallet!');
                ApiProvider().fetchMyUserProfile();
                Get.back(result: coinPlan.coin);
              } else {
                CommonUI.snackBar(
                    message: verifyRes.message ?? 'Demo payment failed.');
              }
            },
          ),
        );
        return;
      }

      if (uri != null && await canLaunchUrl(uri)) {
        if (kIsWeb) {
          await launchUrl(uri, webOnlyWindowName: '_blank');
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }

      // Show payment verification dialog
      Get.dialog(
        ConfirmationDialog(
          heading: 'Confirm Payment',
          description:
              'Complete your payment of ${coinPlan.priceString} on Paystack, then tap Confirm below.',
          textButton: 'Confirm Payment',
          onTap: () async {
            Get.back();
            CommonUI.lottieLoader();
            final verifyRes = await ApiProvider().verifyPaystack(
              reference: reference ?? '',
              diamonds: coinPlan.coin,
              type: 'diamond',
            );
            Get.back();
            if (verifyRes.status == true) {
              CommonUI.snackBar(
                  message: 'Added ${coinPlan.coin} diamonds to your wallet!');
              // Re-fetch user profile from server for accurate wallet
              ApiProvider().fetchMyUserProfile();
              Get.back(result: coinPlan.coin);
            } else {
              CommonUI.snackBar(
                  message: verifyRes.message ?? 'Payment verification failed: payment was not completed on Paystack.');
            }
          },
        ),
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
