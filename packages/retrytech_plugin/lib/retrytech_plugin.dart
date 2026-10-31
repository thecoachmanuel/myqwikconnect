import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RetrytechPlugin {
  static var shared = RetrytechPlugin();
  final methodChannel = const MethodChannel('retrytech_plugin');
  final cameraChannel = const MethodChannel('retrytech_camera');

  Future<bool?> shareToInstagram(String command) {
    if (kIsWeb) return Future.value(false);
    return methodChannel.invokeMethod("shareToInstagram", command);
  }

  Future<bool?> applyFilterAndAudioToVideo({
    required String inputPath,
    required String outputPath,
    bool shouldBothMusics = false,
    String? audioPath,
    List<double> filterValues = const [],
    double? audioStartTimeInMS,
  }) {
    if (kIsWeb) return Future.value(false);
    return methodChannel.invokeMethod("applyFilterAndAudioToVideo", {
      'input_path': inputPath,
      'audio_path': audioPath,
      'filter_values': filterValues,
      'output_path': outputPath,
      'should_add_both_musics': shouldBothMusics,
      'audio_start_time_in_ms': audioStartTimeInMS,
    });
  }

  Future<bool?> extractAudio({
    required String inputPath,
    required String outputPath,
  }) {
    if (kIsWeb) return Future.value(false);
    return methodChannel.invokeMethod("extractAudio", {
      'input_path': inputPath,
      'output_path': outputPath,
    });
  }

  Future<bool?> addWaterMarkInVideo({
    required String inputPath,
    required String thumbnailPath,
    required String username,
    required String outputPath,
  }) {
    if (kIsWeb) return Future.value(false);
    return methodChannel.invokeMethod("addWaterMarkInVideo", {
      'input_path': inputPath,
      'thumbnail_path': thumbnailPath,
      'username': username,
      'output_path': outputPath,
    });
  }

  Future<bool?> applyFilterToImage({
    required String inputPath,
    required List<double> filterValues,
    required String outputPath,
  }) {
    if (kIsWeb) return Future.value(false);
    return methodChannel.invokeMethod("applyFilterToImage", {
      'input_path': inputPath,
      'filter_values': filterValues,
      'output_path': outputPath
    });
  }

  Future<bool?> createVideoFromImage({
    required String inputPath,
    required String outputPath,
    String? audioPath,
    List<double> filterValues = const [],
    double? audioStartTimeInMS,
    double videoTotalDurationInSec = 5.0,
  }) {
    if (kIsWeb) return Future.value(false);
    return methodChannel.invokeMethod("createVideoFromImage", {
      'input_path': inputPath,
      'audio_path': audioPath,
      'filter_values': filterValues,
      'output_path': outputPath,
      'audio_start_time_in_ms': audioStartTimeInMS,
      'video_total_duration_in_sec': videoTotalDurationInSec,
    });
  }

  Future<bool?> hasAudio({required String inputPath }) {
    if (kIsWeb) return Future.value(false);
    return methodChannel.invokeMethod('hasAudio', {'input_path': inputPath});
  }
}

extension RetrytechCameraPlugin on RetrytechPlugin {
  Widget get cameraView {
    if (kIsWeb) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const Icon(Icons.camera_alt, color: Colors.white54, size: 48),
      );
    }
    return Platform.isAndroid
        ? const AndroidView(
      viewType: 'retrytech_camera_view',
      layoutDirection: TextDirection.ltr,
      creationParams: {},
      creationParamsCodec: StandardMessageCodec(),
    )
        : const UiKitView(
      viewType: 'retrytech_camera_view',
      layoutDirection: TextDirection.ltr,
      creationParams: {},
      creationParamsCodec: StandardMessageCodec(),
    );
  }

  Future<void> initCamera() async {
    if (kIsWeb) return;
    await cameraChannel.invokeMethod('init');
  }

  Future<void> get startRecording async {
    if (kIsWeb) return;
    await cameraChannel.invokeMethod('start');
  }

  Future<void> get pauseRecording async {
    if (kIsWeb) return;
    await cameraChannel.invokeMethod('pause');
  }

  Future<void> get resumeRecording async {
    if (kIsWeb) return;
    await cameraChannel.invokeMethod('resume');
  }

  Future<String?> get stopRecording async {
    if (kIsWeb) return null;
    return await cameraChannel.invokeMethod('stop');
  }

  Future<bool> get disposeCamera async {
    if (kIsWeb) return true;
    return (await cameraChannel.invokeMethod('dispose')) ?? true;
  }

  Future<void> get toggleCamera async {
    if (kIsWeb) return;
    await cameraChannel.invokeMethod('toggle');
  }

  Future<void> get flashOnOff async {
    if (kIsWeb) return;
    await cameraChannel.invokeMethod('flash');
  }

  Future<String?> captureImage() async {
    if (kIsWeb) return null;
    return await cameraChannel.invokeMethod('capture_image');
  }
}