import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/model/get_diamond_pack.dart';
import 'package:orange_ui/service/paystack/paystack_payment_service.dart';
import 'package:orange_ui/service/session_manager.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:stacked/stacked.dart';

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
    final myUser = SessionManager.instance.getUser();
    final email = (myUser?.identity?.contains('@') == true)
        ? myUser!.identity!
        : 'user_${myUser?.id ?? 0}@orangeapp.com';

    await PaystackPaymentService.instance.processPayment(
      context: null,
      email: email,
      amount: coinPlan.amountPrice > 0 ? coinPlan.amountPrice : 1500,
      diamonds: coinPlan.coin,
      planId: coinPlan.coinPackageId.toString(),
      type: 'diamond',
      heading: 'Adding Diamonds...',
      description:
          'Please complete your payment of ${coinPlan.priceString} in the Paystack window.\n\nYour diamonds will be added to your wallet automatically once approved — no need to confirm manually.',
      onSuccess: (verifyRes) {
        CommonUI.snackBar(
            message: '💎 ${coinPlan.coin} diamonds added to your wallet!');
        Get.back(result: coinPlan.coin);
      },
      onCancel: () {
        // User cancelled cleanly, stays on same screen
      },
    );
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
