import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:orange_ui/common/common_ui.dart';
import 'package:orange_ui/screen/shimmer_screen/shimmer_screen.dart';
import 'package:orange_ui/service/extention/string_extention.dart';

class CustomImage extends StatelessWidget {
  final String? image;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final String? fullname;
  final double? radius;
  final bool showShimmer;

  const CustomImage(
      {super.key,
      required this.image,
      this.height,
      this.width,
      this.fit,
      this.fullname,
      this.radius,
      this.showShimmer = true});

  @override
  Widget build(BuildContext context) {
    final rawUrl = image?.trim() ?? '';
    final validUrl = rawUrl.addBaseURL();
    final effectiveFit = fit ?? BoxFit.cover;

    return LayoutBuilder(
      builder: (context, constraints) {
        final effectiveHeight = height ?? constraints.maxHeight;

        if (validUrl.isEmpty) {
          return CommonUI.profileImagePlaceHolder(
              name: CommonUI.fullName(fullname),
              heightWidth: effectiveHeight,
              borderRadius: radius);
        }

        if (validUrl.startsWith('data:image')) {
          try {
            final base64String = validUrl.split(',').last;
            final bytes = base64Decode(base64String);
            return ClipSmoothRect(
              radius: SmoothBorderRadius(
                  cornerRadius: radius ?? 0, cornerSmoothing: 1),
              child: Image.memory(
                bytes,
                height: height,
                width: width,
                fit: effectiveFit,
                gaplessPlayback: true,
                errorBuilder: (context, error, stackTrace) {
                  return CommonUI.profileImagePlaceHolder(
                      name: CommonUI.fullName(fullname),
                      heightWidth: effectiveHeight,
                      borderRadius: radius);
                },
              ),
            );
          } catch (_) {}
        }

        if (kIsWeb) {
          return ClipSmoothRect(
            radius:
                SmoothBorderRadius(cornerRadius: radius ?? 0, cornerSmoothing: 1),
            child: Image.network(
              validUrl,
              height: height,
              width: width,
              fit: effectiveFit,
              gaplessPlayback: true,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                if (!showShimmer) return const SizedBox();
                return CustomShimmer(width: width, height: height);
              },
              errorBuilder: (context, error, stackTrace) {
                return CommonUI.profileImagePlaceHolder(
                    name: CommonUI.fullName(fullname),
                    heightWidth: effectiveHeight,
                    borderRadius: radius);
              },
            ),
          );
        }

        return ClipSmoothRect(
          radius:
              SmoothBorderRadius(cornerRadius: radius ?? 0, cornerSmoothing: 1),
          child: CachedNetworkImage(
            imageUrl: validUrl,
            height: height,
            width: width,
            fit: effectiveFit,
            fadeInDuration: const Duration(milliseconds: 100),
            fadeOutDuration: const Duration(milliseconds: 100),
            placeholder: (context, url) {
              if (!showShimmer) {
                return const SizedBox();
              }
              return CustomShimmer(width: width, height: height);
            },
            errorWidget: (context, url, error) {
              return CommonUI.profileImagePlaceHolder(
                  name: CommonUI.fullName(fullname),
                  heightWidth: effectiveHeight,
                  borderRadius: radius);
            },
          ),
        );
      },
    );
  }
}
