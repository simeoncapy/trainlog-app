import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';

class AndroidUpdateService {
  static Future<void> checkForUpdate(BuildContext context) async {
    // in_app_update is backed by the Play Store and only has an Android
    // implementation; on other platforms the call throws MissingPluginException.
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final AppUpdateInfo updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        // Option A: Flexible update
        await InAppUpdate.startFlexibleUpdate();
        await InAppUpdate.completeFlexibleUpdate();

        // Option B: Immediate update
        // await InAppUpdate.performImmediateUpdate();
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }
}