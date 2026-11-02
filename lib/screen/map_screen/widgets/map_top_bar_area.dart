import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:orange_ui/common/button/round_icon_button.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

class MapTopBarArea extends StatelessWidget {
  final List<int> distanceList;
  final int selectedDistance;
  final Function(int value) onDistanceChange;
  final bool isListView;
  final VoidCallback? onToggleView;
  final VoidCallback? onMyLocationTap;

  const MapTopBarArea({
    super.key,
    required this.distanceList,
    required this.selectedDistance,
    required this.onDistanceChange,
    this.isListView = false,
    this.onToggleView,
    this.onMyLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaY: 10, sigmaX: 10),
            child: Container(
              height: 54,
              padding: const EdgeInsets.fromLTRB(11, 8, 8, 8),
              decoration: BoxDecoration(
                color: ColorRes.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const RoundIconButton(),
                  const SizedBox(width: 8),
                  Image.asset(AssetRes.themeLabel, height: 22, width: 68),
                  const SizedBox(width: 4),
                  Text(
                    isListView ? 'Nearby' : S.current.map,
                    style: const TextStyle(
                      color: ColorRes.black,
                      fontFamily: FontRes.bold,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ColorRes.davyGrey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: DropdownButton<int>(
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, size: 18),
                      padding: EdgeInsets.zero,
                      isDense: true,
                      items: distanceList
                          .map<DropdownMenuItem<int>>(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(
                                "$e ${S.current.km}",
                                style: const TextStyle(
                                  color: ColorRes.darkGrey9,
                                  fontFamily: FontRes.semiBold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      value: selectedDistance,
                      onChanged: (int? value) {
                        if (value != null) {
                          onDistanceChange(value);
                        }
                      },
                    ),
                  ),
                  if (onMyLocationTap != null) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(7),
                      onTap: onMyLocationTap,
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: ColorRes.davyGrey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: ColorRes.themeColor,
                        ),
                      ),
                    ),
                  ],
                  if (onToggleView != null) ...[
                    const SizedBox(width: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(7),
                      onTap: onToggleView,
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: ColorRes.themeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Icon(
                          isListView ? Icons.map_rounded : Icons.grid_view_rounded,
                          size: 19,
                          color: ColorRes.themeColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
