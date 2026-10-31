import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:orange_ui/api_provider/api_provider.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/model/get_diamond_pack.dart';
import 'package:orange_ui/service/subscription/subscription_manager.dart';
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
    List<Package> items = SubscriptionManager.shared.offering;
    offerings.addAll(items);
    ApiProvider().getDiamondPack().then((value) async {
      for (DiamondPack data in value.data ?? []) {
        bool matched = false;
        for (var element in offerings) {
          if ([data.iosProductId, data.androidProductId]
              .contains(element.storeProduct.identifier)) {
            coinPlans.add(CoinPlan(
                data.amount ?? 0,
                data.id ?? -1,
                element.storeProduct.identifier,
                element.storeProduct.priceString));
            matched = true;
          }
        }
        if (!matched) {
          coinPlans.add(CoinPlan(
              data.amount ?? 0,
              data.id ?? -1,
              data.androidProductId ?? 'coin_${data.amount}',
              '\$${((data.amount ?? 100) * 0.01).toStringAsFixed(2)}'));
        }
      }
      isLoading = false;
      notifyListeners();
    });
  }

  void makePurchase(CoinPlan coinPlan) {
    CommonUI.lottieLoader();
    if (kIsWeb || offerings.isEmpty) {
      ApiProvider().addCoinFromWallet(coinPlan.coin).then((value) {
        Get.back();
        if (value.status == true) {
          CommonUI.snackBar(message: 'Added ${coinPlan.coin} coins to wallet!');
          Get.back(result: coinPlan.coin);
        } else {
          CommonUI.snackBar(message: value.message ?? 'Purchase failed');
        }
      }).catchError((e) {
        Get.back();
      });
      return;
    }
    Package? package = offerings.firstWhereOrNull(
        (element) => element.storeProduct.identifier == coinPlan.id);
    if (package != null) {
      SubscriptionManager.shared.makePurchaseCustom(package).then((value) async {
        if (value != null) {
          ApiProvider().addCoinFromWallet(coinPlan.coin).then((value) {
            Get.back();
            if (value.status == true) {
              Get.back(result: coinPlan.coin);
            }
          });
        } else {
          Get.back();
        }
      });
    } else {
      Get.back();
    }
  }
}

class CoinPlan {
  int coin;
  int coinPackageId;
  String id;
  String priceString;

  CoinPlan(this.coin, this.coinPackageId, this.id, this.priceString);
}
