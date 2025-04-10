// lib/providers/expense_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/expense_model.dart';
import '../repositories/expense_repository.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseRepository _repository = ExpenseRepository();
  late StreamSubscription<List<ExpenseModel>> _subscription;

  List<ExpenseModel> _expenses = [];
  Map<String, List<ExpenseModel>> _groupedExpenses = {};
  Map<String, double> _totalsByGroup = {};
  double _totalThisWeek = 0;
  bool _isLoading = true;

  ExpenseProvider() {
    _initializeSubscription();
  }

  void _initializeSubscription() {
    _subscription = _repository.expensesStream.listen((expenses) {
      debugPrint("ExpenseProvider received ${expenses.length} expenses");
      _expenses = expenses;
      _groupExpenses();
      _calculateTotals();
      _isLoading = false;
      notifyListeners();
    });
  }

  // Getters
  List<ExpenseModel> get expenses => _expenses;
  Map<String, List<ExpenseModel>> get groupedExpenses => _groupedExpenses;
  Map<String, double> get totalsByGroup => _totalsByGroup;
  double get totalThisWeek => _totalThisWeek;
  bool get isLoading => _isLoading;

  // Group expenses by date
  void _groupExpenses() {
    _groupedExpenses = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    for (final expense in _expenses) {
      final expenseDate = DateTime(
        expense.timestamp.year,
        expense.timestamp.month,
        expense.timestamp.day,
      );

      String groupKey;

      if (expenseDate == today) {
        groupKey = 'Today';
      } else if (expenseDate == yesterday) {
        groupKey = 'Yesterday';
      } else if (expenseDate.isAfter(startOfWeek) ||
          expenseDate == startOfWeek) {
        groupKey = 'This Week';
      } else {
        groupKey = 'Earlier';
      }

      if (!_groupedExpenses.containsKey(groupKey)) {
        _groupedExpenses[groupKey] = [];
      }

      _groupedExpenses[groupKey]!.add(expense);
    }

    // Sort expenses within each group by timestamp (newest first)
    _groupedExpenses.forEach((key, expenses) {
      expenses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  // Calculate totals for each group and week
  void _calculateTotals() {
    _totalsByGroup = {};

    _groupedExpenses.forEach((key, expenses) {
      final total = expenses.fold(0.0, (sum, expense) => sum + expense.amount);
      _totalsByGroup[key] = total;
    });

    // Calculate total for this week
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    _totalThisWeek = _expenses
        .where((expense) =>
            expense.timestamp
                .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            expense.timestamp.isBefore(endOfWeek.add(const Duration(days: 1))))
        .fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Methods
  Future<void> addExpense(ExpenseModel expense) async {
    await _repository.addExpense(expense);
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _repository.updateExpense(expense);
  }

  Future<void> deleteExpense(String id) async {
    await _repository.deleteExpense(id);
  }

  Future<void> clearAllExpenses() async {
    await _repository.clearAllExpenses();
  }

  Future<void> refreshExpenses() async {
    _isLoading = true;
    notifyListeners();
    await _repository.refreshExpenses();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
