import 'dart:io';

import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';
import 'package:untitled2/core/services/feedback/app_feedback_message.dart';
import 'package:untitled2/core/services/feedback/user_feedback_service.dart';

@lazySingleton
class PermissionUxService {
  PermissionUxService(this._feedbackService);

  final UserFeedbackService _feedbackService;

  Future<bool> ensureGalleryPermission(BuildContext context) async {
    final permission = Platform.isIOS ? Permission.photos : Permission.storage;
    return _ensurePermission(
      context,
      permission: permission,
      rationaleTitle: context.tr.permissionPhotosTitle,
      rationaleDescription: context.tr.permissionPhotosDescription,
    );
  }

  Future<bool> ensureCameraPermission(BuildContext context) async {
    return _ensurePermission(
      context,
      permission: Permission.camera,
      rationaleTitle: context.tr.permissionCameraTitle,
      rationaleDescription: context.tr.permissionCameraDescription,
    );
  }

  Future<bool> _ensurePermission(
    BuildContext context, {
    required Permission permission,
    required String rationaleTitle,
    required String rationaleDescription,
  }) async {
    final currentStatus = await permission.status;
    if (currentStatus.isGranted || currentStatus.isLimited) {
      return true;
    }

    if (context.mounted) {
      final approved = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text(rationaleTitle),
                content: Text(rationaleDescription),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(context.tr.commonCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(context.tr.commonContinue),
                  ),
                ],
              );
            },
          ) ??
          false;
      if (!approved) {
        return false;
      }
    }

    final result = await permission.request();
    if (result.isGranted || result.isLimited) {
      return true;
    }
    if (result.isPermanentlyDenied && context.mounted) {
      _feedbackService.showWarning(AppMessageKey.permissionPermanentlyDenied);
      final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: Text(context.tr.permissionPermanentlyDeniedTitle),
                content: Text(context.tr.permissionPermanentlyDeniedDescription),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: Text(context.tr.commonCancel),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: Text(context.tr.commonOpenSettings),
                  ),
                ],
              );
            },
          ) ??
          false;
      if (shouldOpenSettings) {
        await openAppSettings();
      }
      return false;
    }
    _feedbackService.showWarning(AppMessageKey.permissionDenied);
    return false;
  }
}
