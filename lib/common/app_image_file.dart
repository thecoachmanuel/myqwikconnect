import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

Widget appImageFile({
  required String path,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (kIsWeb) {
    return Image.network(
      path,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
    );
  }
  return Image.file(
    File(path),
    width: width,
    height: height,
    fit: fit,
  );
}

