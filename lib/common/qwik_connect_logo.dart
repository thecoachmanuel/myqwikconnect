import 'package:flutter/material.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/font_res.dart';

/// Reusable QwikConnect wordmark logo:
/// "Qwik" is an ultra-bold Orange Gradient (#FF6F43 -> #FF4B1F -> #FE1B03)
/// "Connect" is a bold solid Black (#000000)
class QwikConnectLogo extends StatelessWidget {
  final double fontSize;
  final Color connectColor;
  final List<Shadow>? shadows;

  const QwikConnectLogo({
    super.key,
    this.fontSize = 28,
    this.connectColor = ColorRes.black,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFF6F43),
              Color(0xFFFF4B1F),
              Color(0xFFFE1B03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'Qwik',
            style: TextStyle(
              fontFamily: FontRes.bold,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
              color: Colors.white,
              height: 1.0,
              shadows: shadows,
            ),
          ),
        ),
        Text(
          'Connect',
          style: TextStyle(
            fontFamily: FontRes.bold,
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.2,
            color: connectColor,
            height: 1.0,
            shadows: shadows,
          ),
        ),
      ],
    );
  }
}
