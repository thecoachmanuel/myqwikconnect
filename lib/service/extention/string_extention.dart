import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orange_ui/common/dominant_color.dart';
import 'package:orange_ui/utils/color_res.dart';
import 'package:orange_ui/utils/const_res.dart';

extension StringExtention on String {
  String addBaseURL() {
    if (isEmpty) return '';
    if (startsWith('blob:') || startsWith('data:')) {
      return this;
    }
    String fullUrl;
    if (startsWith('http://') || startsWith('https://')) {
      fullUrl = this;
    } else if (startsWith('/public/storage/')) {
      fullUrl = '${ConstRes.base}${substring(1)}';
    } else if (startsWith('public/storage/')) {
      fullUrl = '${ConstRes.base}$this';
    } else if (startsWith('/storage/')) {
      fullUrl = '${ConstRes.base}public$this';
    } else if (startsWith('storage/')) {
      fullUrl = '${ConstRes.base}public/$this';
    } else if (startsWith('/')) {
      fullUrl = '${ConstRes.aImageBaseUrl}${substring(1)}';
    } else {
      fullUrl = (ConstRes.aImageBaseUrl) + this;
    }

    if (fullUrl.contains('uploads/user') || fullUrl.contains('uploads/story')) {
      if (!fullUrl.contains('?v=')) {
        fullUrl += (fullUrl.contains('?') ? '&' : '?') + 'v=4';
      }
    }
    return fullUrl;
  }

  String get removeEmojis {
    final emojiRegex = RegExp(
        r'[\u{1F600}-\u{1F64F}' // Emoticons
        r'\u{1F300}-\u{1F5FF}' // Symbols & Pictographs
        r'\u{1F680}-\u{1F6FF}' // Transport & Map Symbols
        r'\u{2600}-\u{26FF}' // Misc symbols
        r'\u{2700}-\u{27BF}' // Dingbats
        r'\u{FE00}-\u{FE0F}' // Variation Selectors
        r'\u{1F900}-\u{1F9FF}' // Supplemental Symbols and Pictographs
        r'\u{1F1E6}-\u{1F1FF}' // Flags
        r'\u{1F700}-\u{1F77F}]', // Alchemical symbols
        unicode: true);

    return replaceAll(emojiRegex, '');
  }

  int get dateTimeToAge {
    DateTime birthDate = DateTime.parse(this);
    final today = DateTime.now();
    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  Future<LinearGradient> get getGradientFromImage async {
    List<Color> colors = [];
    try {
      Uint8List imageBytes;
      if (kIsWeb) {
        imageBytes = await XFile(this).readAsBytes();
      } else {
        imageBytes = await File(this).readAsBytes();
      }
      DominantColors extractor =
          DominantColors(bytes: imageBytes, dominantColorsCount: 5);
      colors = extractor.extractDominantColors();
    } catch (_) {
      colors.clear();
    }

    if (colors.length < 2) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [ColorRes.lightOrange, ColorRes.themeColor],
      );
    }

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.1, 1],
      colors: [colors.first, colors.last],
    );
  }
}
