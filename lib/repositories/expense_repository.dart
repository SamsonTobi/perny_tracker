// lib/repositories/expense_repository.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../models/notification_event_model.dart';
import '../services/expense_bottom_sheet_service.dart';
import '../services/expense_storage.dart';
import '../utils/logger.dart';

class ExpenseRepository {
  // Singleton instance
  static final ExpenseRepository _instance = ExpenseRepository._internal();

  // Stream controller to broadcast expense updates
  final _expensesStreamController =
      StreamController<List<ExpenseModel>>.broadcast();

  // Cached expenses
  List<ExpenseModel> _cachedExpenses = [];

  // Factory constructor
  factory ExpenseRepository() {
    return _instance;
  }

  // Private constructor
  ExpenseRepository._internal() {
    _loadExpenses();

    Timer.periodic(const Duration(seconds: 10), (timer) {
      refreshExpenses();
    });
  }

  // Getter for the stream
  Stream<List<ExpenseModel>> get expensesStream =>
      _expensesStreamController.stream;

  // Getter for cached expenses
  List<ExpenseModel> get expenses => _cachedExpenses;

  // Load all expenses from storage
  Future<void> _loadExpenses() async {
    try {
      _cachedExpenses = await ExpenseStorage.getExpenses();

      // Sort expenses by timestamp (newest first)
      _cachedExpenses.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Always emit an event when expenses are loaded
      _notifyListeners();

      debugPrint("Loaded ${_cachedExpenses.length} expenses from storage");
    } catch (e) {
      AppLogger.error('Error loading expenses in repository: $e');
    }
  }

  // Helper method to notify listeners
  void _notifyListeners() {
    if (!_expensesStreamController.isClosed) {
      _expensesStreamController.add(List<ExpenseModel>.from(_cachedExpenses));
    }
  }

  // Check if an expense with the same details already exists
  bool _isDuplicateExpense(ExpenseModel newExpense) {
    return _cachedExpenses.any((expense) =>
        expense.bankName == newExpense.bankName &&
        expense.amount == newExpense.amount &&
        // Check if timestamps are within 1 minute of each other
        (expense.timestamp.difference(newExpense.timestamp).inMinutes.abs() <
            1));
  }

  // Create an expense from a notification
  Future<bool> createExpenseFromNotification(
      NotificationEventModel notification) async {
    try {
      // Check if notification is from a bank app
      if (isBankNotification(notification) &&
          notification.hasRemoved == false) {
        // Extract amount from notification content
        final amountString = extractAmount(notification.content);

        // Create expense from notification
        final expense = ExpenseModel.fromNotification(
          packageName: notification.packageName,
          content: notification.content,
          timestamp: notification.timestamp,
          amountString: amountString,
        );

        // Check if this expense already exists
        if (_isDuplicateExpense(expense)) {
          AppLogger.log(
              'Duplicate expense detected, skipping: ${expense.bankName} - ${expense.amount}');
          return false;
        }

        // Save expense to storage
        // Save expense to storage and get updated list
        _cachedExpenses = await ExpenseStorage.saveExpense(expense);

        // Add to cached expenses and notify listeners
        _cachedExpenses.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        AppLogger.debug(
            "=== NOTIFICATION EXPENSE CREATED: ${expense.amount} from ${expense.bankName} ===");

        // Show the category selection overlay
        await ExpenseBottomSheetService.showCategorySelectionOverApps(expense);

        _notifyListeners();

        AppLogger.debug(
            "Created new expense: ${expense.bankName} - ${expense.amount}");
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error creating expense from notification: $e');
      return false;
    }
  }

  // Add a new expense
  Future<void> addExpense(ExpenseModel expense) async {
    try {
      // Check if this expense already exists
      if (_isDuplicateExpense(expense)) {
        AppLogger.log(
            'Duplicate expense detected, skipping: ${expense.bankName} - ${expense.amount}');
        return;
      }

      await ExpenseStorage.saveExpense(expense);

      // Add to cached expenses and notify listeners
      _cachedExpenses.add(expense);
      _cachedExpenses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _notifyListeners();

      debugPrint("Added new expense: ${expense.bankName} - ${expense.amount}");
    } catch (e) {
      AppLogger.error('Error adding expense: $e');
    }
  }

  // Update an existing expense
  Future<void> updateExpense(ExpenseModel expense) async {
    try {
      await ExpenseStorage.updateExpense(expense);

      // Update cached expense and notify listeners
      final index = _cachedExpenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _cachedExpenses[index] = expense;
        _notifyListeners();
      }
    } catch (e) {
      AppLogger.error('Error updating expense: $e');
    }
  }

  // Delete an expense
  Future<void> deleteExpense(String id) async {
    try {
      await ExpenseStorage.deleteExpense(id);

      // Remove from cached expenses and notify listeners
      _cachedExpenses.removeWhere((e) => e.id == id);
      _notifyListeners();
    } catch (e) {
      AppLogger.error('Error deleting expense: $e');
    }
  }

  // Refresh expenses from storage
  Future<void> refreshExpenses() async {
    try {
      // Force reload from shared preferences
      _cachedExpenses = await ExpenseStorage.getExpenses();
      _cachedExpenses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _notifyListeners();
      debugPrint("Refreshed expenses, count: ${_cachedExpenses.length}");
    } catch (e) {
      AppLogger.error('Error refreshing expenses: $e');
    }
  }

  List<dynamic> _hasAmount(String? content) {
    if (content == null || content.isEmpty) {
      return [false, null];
    }

    String? foundAmount;

    // Pattern 1: Currency symbols like ₦1,000.00 or $50.45
    final symbolRegex = RegExp(r'[₦$](\d+(?:,\d+)*(?:\.\d+)?)');
    final symbolMatch = symbolRegex.firstMatch(content);

    // Pattern 2: NGN format like NGN300.00 or NGN 300.00
    final ngnRegex =
        RegExp(r'NGN\s*(\d+(?:,\d+)*(?:\.\d+)?)', caseSensitive: false);
    final ngnMatch = ngnRegex.firstMatch(content);

    // Check for symbol match
    if (symbolMatch != null) {
      foundAmount = symbolMatch.group(1);
      return [true, foundAmount];
    }

    // Check for NGN match
    if (ngnMatch != null) {
      // Get the full match and format it properly
      final fullMatch = ngnMatch.group(1);
      if (fullMatch != null) {
        foundAmount = fullMatch;
        return [true, foundAmount];
      }
    }

    // No amount found
    return [false, null];
  }

  // Check if a notification is from a bank app
  bool isBankNotification(NotificationEventModel notification) {
    final String? packageName = notification.packageName?.toLowerCase();
    final String? title = notification.title?.toLowerCase();
    final String? content = notification.content?.toLowerCase();

    // List of bank app package names to filter
    final List<String> bankPackageNames = [
      'com.kudabank.app',
      'team.opay.pay',
      'com.moniepoint.personal'
    ];

    bool isOutgoingTransaction = false;

    // Pattern 1: "You just sent ₦X to Y" (Kuda pattern)
    if (content!.contains('you just sent') && content.contains('to ')) {
      isOutgoingTransaction = true;
    }

    // Pattern 2: "Your account X was debited NGN/₦Y for TRANSFER TO Z" (Moniepoint pattern)
    else if ((content.contains('was debited') ||
            content.contains('debited with')) &&
        (content.contains('transfer to') || content.contains('for transfer'))) {
      isOutgoingTransaction = true;
    }

    // Pattern 3: Any content containing both "debit" and "transfer" variations
    else if ((content.contains('debit') || content.contains('debited')) &&
        content.contains('transfer')) {
      isOutgoingTransaction = true;
    }

    final bool isFromBankPackage = notification.packageName != null &&
        bankPackageNames.contains(notification.packageName);

    // Get the amount check result
    final amountCheck = _hasAmount(content);
    final hasAmount = amountCheck[0];

    return isFromBankPackage && isOutgoingTransaction && hasAmount;
  }

  // Extract transaction amount from notification content
  String? extractAmount(String? content) {
    final amountCheck = _hasAmount(content);
    if (amountCheck[0] == true && amountCheck.length > 1) {
      return amountCheck[1] as String?;
    }
    return null;
  }

  // Clear all expenses
  Future<void> clearAllExpenses() async {
    try {
      await ExpenseStorage.clearExpenses();
      _cachedExpenses = [];
      _notifyListeners();
    } catch (e) {
      AppLogger.error('Error clearing expenses: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _expensesStreamController.close();
  }
}
