import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orange_ui/service/session_manager.dart';

class PresenceService with WidgetsBindingObserver {
  static final PresenceService instance = PresenceService._();
  PresenceService._();

  Timer? _heartbeatTimer;
  bool _initialized = false;

  void init() {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    setOnline(true);

    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      setOnline(true);
    });
  }

  void setOnline(bool isOnline) {
    try {
      final uid = SessionManager.instance.getUserID();
      if (uid <= 0) return;

      FirebaseFirestore.instance.collection('user_presence').doc('$uid').set({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      setOnline(false);
    }
  }

  static String formatLastSeen(num? lastSeenMs) {
    if (lastSeenMs == null || lastSeenMs <= 0) return 'Offline';

    final now = DateTime.now();
    final seen = DateTime.fromMillisecondsSinceEpoch(lastSeenMs.toInt());
    final difference = now.difference(seen);

    if (difference.inSeconds < 60) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24 && now.day == seen.day) {
      return 'Last seen today at ${DateFormat('h:mm a').format(seen)}';
    } else if (difference.inHours < 48 &&
        now.subtract(const Duration(days: 1)).day == seen.day) {
      return 'Last seen yesterday at ${DateFormat('h:mm a').format(seen)}';
    } else {
      return 'Last seen ${DateFormat('d MMM, h:mm a').format(seen)}';
    }
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}

