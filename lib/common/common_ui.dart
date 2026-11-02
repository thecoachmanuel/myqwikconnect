import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

class CommonUI {
  static Widget profileImagePlaceHolder(
      {String? name,
      double heightWidth = 0,
      double? borderRadius,
      Color? color,
      double? fontSize}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double resolvedWidth = heightWidth > 0 && heightWidth.isFinite
            ? heightWidth
            : (constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : double.infinity);
        double resolvedHeight = heightWidth > 0 && heightWidth.isFinite
            ? heightWidth
            : (constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : double.infinity);

        double baseSize = 50.0;
        if (heightWidth > 0 && heightWidth.isFinite) {
          baseSize = heightWidth;
        } else if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          baseSize = constraints.maxHeight;
        } else if (constraints.maxWidth.isFinite && constraints.maxWidth > 0) {
          baseSize = constraints.maxWidth;
        }

        final double iconSize = (baseSize * 0.5).clamp(16.0, 120.0);

        return Container(
          width: resolvedWidth,
          height: resolvedHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F6),
            borderRadius: BorderRadius.circular(borderRadius ?? 50),
          ),
          alignment: Alignment.center,
          child: Center(
            child: Image.asset(
              AssetRes.icProfileUser,
              width: iconSize,
              height: iconSize,
              fit: BoxFit.contain,
              color: (color ?? ColorRes.dimGrey3).withValues(alpha: 0.65),
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.person_rounded,
                size: iconSize,
                color: (color ?? ColorRes.dimGrey3).withValues(alpha: 0.65),
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget postPlaceHolder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: const BoxDecoration(color: ColorRes.lightGrey),
      alignment: Alignment.center,
      child: Image.asset(
        AssetRes.icPostPlaceholder,
        height: 200 / 3,
        color: ColorRes.grey,
      ),
    );
  }

  static String fullName(String? fullName) {
    return fullName ?? 'Unknown';
  }

  static String userName(String? userName) {
    return '@${userName ?? 'unknown'}';
  }

  static Widget noData({String? title}) {
    return Center(
      child: Text(
        title ?? S.current.noData,
        style: const TextStyle(
            fontFamily: FontRes.semiBold,
            fontSize: 18,
            color: ColorRes.dimGrey3),
      ),
    );
  }

  static Future<void> lottieLoader({bool isBarrierDismissible = true}) {
    return Get.dialog(
        Center(
            child:
                Lottie.asset(AssetRes.loadingLottie, height: 100, width: 100)),
        barrierDismissible: isBarrierDismissible);
  }

  static Widget cupertinoIndicator(
      {Color color = ColorRes.borderColor, double radius = 10.0}) {
    return CupertinoActivityIndicator(color: color, radius: radius);
  }

  static Widget lottieWidget() {
    return Center(
      child: Lottie.asset(
        AssetRes.loadingLottie,
        height: 100,
        width: 100,
      ),
    );
  }

  static void snackBarWidget(String? titleName) {
    ScaffoldMessenger.of(Get.context!)
        .showSnackBar(
          SnackBar(
            content: Text((titleName ?? '').capitalizeFirst ?? '',
                style: const TextStyle(
                    color: ColorRes.white,
                    fontFamily: FontRes.medium,
                    fontSize: 16),
                maxLines: 2),
            backgroundColor: ColorRes.black,
            shape: SmoothRectangleBorder(
                borderRadius:
                    SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 1)),
            elevation: 2,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(milliseconds: 2500),
          ),
        )
        .closed
        .then((value) => ScaffoldMessenger.of(Get.context!).clearSnackBars());
  }

  static void snackBar({String? message}) {
    Get.rawSnackbar(
        messageText: Text(
          message ?? '',
          style: const TextStyle(
            color: ColorRes.white,
            fontFamily: FontRes.medium,
            fontSize: 16,
          ),
        ),
        backgroundColor: ColorRes.black,
        borderRadius: 10,
        margin: const EdgeInsets.all(15));
  }
}
