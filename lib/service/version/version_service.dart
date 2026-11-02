import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orange_ui/common/common_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'version_stub.dart' if (dart.library.html) 'version_web.dart';

class VersionService with WidgetsBindingObserver {
  static final VersionService instance = VersionService._();
  VersionService._();

  String? _currentBuildNumber;
  Timer? _periodicTimer;
  bool _isChecking = false;

  void init() {
    if (!kIsWeb) return;

    WidgetsBinding.instance.addObserver(this);

    PackageInfo.fromPlatform().then((info) {
      _currentBuildNumber = info.buildNumber;
      _checkForUpdate();
    }).catchError((_) {
      _currentBuildNumber = '8';
      _checkForUpdate();
    });

    // Check periodically every 3 minutes
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      _checkForUpdate();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    if (!kIsWeb || _isChecking) return;
    _isChecking = true;

    try {
      final uri = Uri.parse('version.json?t=${DateTime.now().millisecondsSinceEpoch}');
      final response = await http.get(uri, headers: {
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      }).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final remoteBuild = data['build_number']?.toString() ?? data['version']?.toString();

        if (remoteBuild != null &&
            _currentBuildNumber != null &&
            remoteBuild.isNotEmpty &&
            remoteBuild != _currentBuildNumber) {
          int? remoteInt = int.tryParse(remoteBuild);
          int? currentInt = int.tryParse(_currentBuildNumber!);

          if ((remoteInt != null && currentInt != null && remoteInt > currentInt) ||
              remoteBuild != _currentBuildNumber) {
            _periodicTimer?.cancel();
            CommonUI.snackBar(message: 'New update detected. Refreshing app...');
            await Future.delayed(const Duration(milliseconds: 800));
            reloadAppPlatform();
            return;
          }
        }
      }
    } catch (_) {
      // Ignored if offline
    } finally {
      _isChecking = false;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
  }
}

