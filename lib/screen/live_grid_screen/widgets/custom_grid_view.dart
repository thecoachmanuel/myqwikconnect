import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:orange_ui/common/custom_image.dart';
import 'package:orange_ui/generated/l10n.dart';
import 'package:orange_ui/model/chat_and_live_stream/live_stream.dart';
import 'package:orange_ui/utils/asset_res.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';
import 'package:orange_ui/utils/style_res.dart';

class CustomGridView extends StatelessWidget {
  final List<LiveStreamUser> userData;
  final Function(LiveStreamUser? data) onImageTap;

  const CustomGridView({
    super.key,
    required this.userData,
    required this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: userData.isEmpty
          ? _noLiveUser()
          : LayoutBuilder(
              builder: (context, constraints) {
                // Responsive column count: mobile=2, tablet=3, desktop=4
                final double maxW = constraints.maxWidth;
                final int crossCount = maxW < 600
                    ? 2
                    : maxW < 900
                        ? 3
                        : 4;
                // Tile height varies by screen width to keep aspect ratio nice
                final double tileHeight = maxW < 600 ? (maxW / 2) * 1.28 : 220;

                return RefreshIndicator(
                  color: ColorRes.themeColor,
                  onRefresh: () async {
                    // Inherited via parent ViewModel listener — just show indicator
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  child: GridView.builder(
                    padding: EdgeInsets.fromLTRB(
                      maxW < 600 ? 12 : 16,
                      4,
                      maxW < 600 ? 12 : 16,
                      24,
                    ),
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossCount,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: tileHeight,
                    ),
                    itemCount: userData.length,
                    itemBuilder: (context, index) {
                      return _gridTile(
                        data: userData[index],
                        index: index,
                        tileHeight: tileHeight,
                      );
                    },
                  ),
                );
              },
            ),
    );
  }

  Widget _gridTile({
    required LiveStreamUser data,
    required int index,
    required double tileHeight,
  }) {
    return GestureDetector(
      onTap: () => onImageTap(data),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background image ──────────────────────────────────────────
            CustomImage(
              image: data.userImage,
              fit: BoxFit.cover,
              fullname: data.fullName,
              radius: 20,
            ),

            // ── Dark gradient overlay at bottom ───────────────────────────
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 1.0],
                    colors: [
                      ColorRes.black.withValues(alpha: 0.0),
                      ColorRes.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),

            // ── LIVE badge (top-left) ─────────────────────────────────────
            Positioned(
              top: 10,
              left: 10,
              child: _LiveBadge(),
            ),

            // ── Viewer count (top-right) ──────────────────────────────────
            Positioned(
              top: 10,
              right: 10,
              child: _ViewerCountBadge(count: data.watchingCount ?? 0),
            ),

            // ── Bottom info area ──────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomInfoArea(data: data, onTap: () => onImageTap(data)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noLiveUser() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gradient circle with live icon
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: StyleRes.linearGradient,
              boxShadow: [
                BoxShadow(
                  color: ColorRes.themeColor.withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Center(
              child: Image.asset(
                AssetRes.sun,
                height: 44,
                width: 44,
                color: ColorRes.white,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            S.current.noUsersAreLive,
            style: const TextStyle(
              fontFamily: FontRes.bold,
              fontSize: 20,
              color: ColorRes.darkGrey,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back soon for live streams!',
            style: TextStyle(
              fontFamily: FontRes.regular,
              fontSize: 14,
              color: ColorRes.darkGrey.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing red LIVE badge
class _LiveBadge extends StatefulWidget {
  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ColorRes.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        const Color(0xFFFF3B30).withValues(alpha: _pulse.value),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'LIVE',
                style: TextStyle(
                  color: ColorRes.white,
                  fontSize: 11,
                  fontFamily: FontRes.extraBold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Viewer count pill (top-right)
class _ViewerCountBadge extends StatelessWidget {
  final int count;
  const _ViewerCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ColorRes.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                AssetRes.eye,
                width: 14,
                height: 12,
                color: ColorRes.white,
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: const TextStyle(
                  color: ColorRes.white,
                  fontSize: 12,
                  fontFamily: FontRes.medium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom frosted info area with name, age, address, and Join button
class _BottomInfoArea extends StatelessWidget {
  final LiveStreamUser data;
  final VoidCallback onTap;
  const _BottomInfoArea({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Name + age + address
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        data.fullName ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ColorRes.white,
                          fontSize: 15,
                          fontFamily: FontRes.bold,
                        ),
                      ),
                    ),
                    if (data.age != null)
                      Text(
                        ' ${data.age}',
                        style: const TextStyle(
                          color: ColorRes.white,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(width: 3),
                    Image.asset(AssetRes.tickMark, height: 14, width: 14),
                  ],
                ),
                if ((data.address ?? '').isNotEmpty)
                  Text(
                    data.address ?? '',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: ColorRes.white.withValues(alpha: 0.8),
                      fontSize: 11,
                      fontFamily: FontRes.regular,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // "Join" CTA pill
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                gradient: StyleRes.linearGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: ColorRes.themeColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Join',
                style: TextStyle(
                  color: ColorRes.white,
                  fontSize: 13,
                  fontFamily: FontRes.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
