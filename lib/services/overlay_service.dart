import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../models/expense_model.dart';
import '../utils/logger.dart';

class OverlayService {
  static bool _isInitialized = false;
  static final StreamController<ExpenseModel> _expenseStreamController =
      StreamController<ExpenseModel>.broadcast();

  // Stream to communicate with the overlay
  static Stream<ExpenseModel> get expenseStream =>
      _expenseStreamController.stream;

  // Initialize the overlay service
  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final bool hasPermission =
          await FlutterOverlayWindow.isPermissionGranted();

      if (hasPermission) {
        _isInitialized = true;
        AppLogger.log("Overlay permission is granted");
        return true;
      } else {
        AppLogger.log("Overlay permission not granted");
        return false;
      }
    } catch (e) {
      AppLogger.error("Error initializing overlay service: $e");
      return false;
    }
  }

  // Request overlay permission
  static Future<bool> requestPermission() async {
    try {
      final bool hasPermission =
          await FlutterOverlayWindow.isPermissionGranted();

      if (hasPermission) {
        _isInitialized = true;
        return true;
      }

      final bool? permissionGranted =
          await FlutterOverlayWindow.requestPermission();
      _isInitialized = permissionGranted!;
      return permissionGranted;
    } catch (e) {
      AppLogger.error("Error requesting overlay permission: $e");
      return false;
    }
  }

  // Check if overlay permission is granted
  static Future<bool> hasPermission() async {
    try {
      return await FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      AppLogger.error("Error checking overlay permission: $e");
      return false;
    }
  }

  // Show the overlay for category selection
  static Future<bool> showCategorySelectionOverlay(ExpenseModel expense) async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          AppLogger.error("Failed to initialize overlay service");
          return false;
        }
      }

      // Check if overlay is already showing
      final bool isActive = await FlutterOverlayWindow.isActive();

      if (isActive) {
        // If already showing, just update the expense data
        _expenseStreamController.add(expense);
        return true;
      }

      // Open the overlay window
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        height: 450,
        width: WindowSize.matchParent,
        alignment: OverlayAlignment.center,
        flag: OverlayFlag.defaultFlag,
        visibility: NotificationVisibility.visibilityPublic,
      );

      // Send the expense data to the overlay
      _expenseStreamController.add(expense);
      return true;
    } catch (e) {
      AppLogger.error("Error showing category selection overlay: $e");
      return false;
    }
  }

  // Close the overlay
  static Future<bool> closeOverlay() async {
    try {
      await FlutterOverlayWindow.closeOverlay();
      return true;
    } catch (e) {
      AppLogger.error("Error closing overlay: $e");
      return false;
    }
  }

  // Dispose resources
  static void dispose() {
    _expenseStreamController.close();
  }
}
