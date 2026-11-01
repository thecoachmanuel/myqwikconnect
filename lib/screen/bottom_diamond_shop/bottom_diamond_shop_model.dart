import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/common/confirmation_dialog.dart';
import 'package:orange_ui/model/get_diamond_pack.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:orange_ui/service/subscription/subscription_manager.dart';
import 'package:orange_ui/utils/app_res.dart';
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
    List<Package> items = SubscriptionManager.shared.offering;
    offerings.addAll(items);
    ApiProvider().getDiamondPack().then((value) async {
      final currency = SessionManager.instance.getSettings()?.appdata?.currency ??
          AppRes.defaultCurrencyCode;

      for (DiamondPack data in value.data ?? []) {
        bool matched = false;
        for (var element in offerings) {
          if ([data.iosProductId, data.androidProductId]
              .contains(element.storeProduct.identifier)) {
            coinPlans.add(CoinPlan(
                data.amount ?? 0,
                data.id ?? -1,
                element.storeProduct.identifier,
                element.storeProduct.priceString,
                amountPrice: (data.price ?? 1500).toDouble()));
            matched = true;
          }
        }
        if (!matched) {
          final price = data.price != null && data.price! > 0
              ? data.price!
              : ((data.amount ?? 100) * 15);
          coinPlans.add(CoinPlan(
              data.amount ?? 0,
              data.id ?? -1,
              data.androidProductId ?? 'coin_${data.amount}',
              '$currency$price',
              amountPrice: price.toDouble()));
        }
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

      if (authUrl != null && authUrl.isNotEmpty) {
        final uri = Uri.tryParse(authUrl);
        if (uri != null && await canLaunchUrl(uri)) {
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
              Get.back(result: coinPlan.coin);
            } else {
              CommonUI.snackBar(
                  message: verifyRes.message ?? 'Payment verification failed');
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
