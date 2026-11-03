import 'package:flutter/material.dart';
import 'package:orange_ui/common/button/round_icon_button.dart';
import 'package:orange_ui/common/qwik_connect_logo.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

class DashboardTopBar extends StatelessWidget {
  final VoidCallback onNotificationTap;
  final VoidCallback? onTitleTap;
  final VoidCallback onSearchTap;
  final VoidCallback onLivesBtnClick;
  final int? isDating;
  final int unreadCount;

  const DashboardTopBar({
    super.key,
    required this.onNotificationTap,
    this.onTitleTap,
    required this.onSearchTap,
    required this.onLivesBtnClick,
    required this.isDating,
    this.unreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
      child: Row(
        children: [
          InkWell(
            onTap: onTitleTap,
            child: const QwikConnectLogo(fontSize: 28, isWhite: false),
          ),
          const Spacer(),
          Row(
            spacing: 5,
            children: [
              InkWell(
                onTap: onLivesBtnClick,
                child: Container(
                  height: 37,
                  decoration: BoxDecoration(
                      color: ColorRes.themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30)),
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      Image.asset(
                        AssetRes.sun,
                        height: 20,
                        width: 20,
                        color: ColorRes.themeColor,
                      ),
                      const SizedBox(width: 5),
                      Text(S.of(context).lives,
                          style: const TextStyle(
                              fontFamily: FontRes.regular,
                              fontSize: 12,
                              color: ColorRes.themeColor))
                    ],
                  ),
                ),
              ),
              Stack(
                clipBehavior: Clip.none,
                children: [
                  RoundIconButton(
                      onTap: onNotificationTap, icon: AssetRes.bell, padding: 8),
                  if (unreadCount > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: ColorRes.themeColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 15,
                          minHeight: 15,
                        ),
                        child: Center(
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: ColorRes.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              RoundIconButton(
                  onTap: onSearchTap, icon: AssetRes.search, padding: 8),
            ],
          )
        ],
      ),
    );
  }
}
