import 'package:flutter/material.dart';
import 'package:orange_ui/utils/font_res.dart';

/// Reusable QwikConnect wordmark logo.
///
/// [fontSize]   – base size; "Qwik" gets full size, "Connect" same size.
/// [isWhite]    – true  → both words white (for dark/image backgrounds, e.g. Auth screen)
///              – false → "Qwik" orange gradient, "Connect" dark (for light bg, e.g. Navbar)
class QwikConnectLogo extends StatelessWidget {
  final double fontSize;
  final bool isWhite;

  const QwikConnectLogo({
    super.key,
    this.fontSize = 28,
    this.isWhite = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isWhite) {
      // Auth screen: both words plain white, Qwik ultra-bold
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Qwik',
              style: TextStyle(
                fontFamily: FontRes.bold,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: Colors.white,
                height: 1,
              ),
            ),
            TextSpan(
              text: 'Connect',
              style: TextStyle(
                fontFamily: FontRes.bold,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: -1.2,
                color: Colors.white,
                height: 1,
              ),
            ),
          ],
        ),
      );
    }

    // Explore / navbar: "Qwik" in orange gradient, "Connect" dark
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFF6F43), Color(0xFFFF4B1F), Color(0xFFFE1B03)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(
        // only shade the "Qwik" portion (roughly 40% of the total width)
        Rect.fromLTWH(0, 0, bounds.width * 0.44, bounds.height),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Qwik',
              style: TextStyle(
                fontFamily: FontRes.bold,
                fontSize: fontSize,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                color: const Color(0xFFFF6F43), // caught by ShaderMask
                height: 1,
              ),
            ),
            TextSpan(
              text: 'Connect',
              style: TextStyle(
                fontFamily: FontRes.bold,
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: -1.2,
                color: const Color(0xFF2D2D2D), // dark, ShaderMask won't reach
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

