// lib/services/expense_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:perny_expense_tracker/utils/logger.dart';
import '../models/expense_model.dart';

class ExpenseStorage {
  static const String _storageKey = 'stored_expenses';

  // Save an expense to storage
  static Future<List<ExpenseModel>> saveExpense(ExpenseModel expense) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing expenses
      List<ExpenseModel> expenses = await getExpenses();

      // Add new expense
      expenses.add(expense);

      // Limit storage to prevent excessive memory usage
      if (expenses.length > 500) {
        // Keep only the 500 most recent expenses
        expenses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        expenses = expenses.take(500).toList();
      }

      // Convert to JSON and save
      final List<String> jsonList =
          expenses.map((expense) => jsonEncode(expense.toMap())).toList();

      await prefs.setStringList(_storageKey, jsonList);
      return expenses;
    } catch (e) {
      AppLogger.error('Error saving expense: $e');
      return [];
    }
  }

  // Get all stored expenses
  static Future<List<ExpenseModel>> getExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList(_storageKey);

      if (jsonList == null || jsonList.isEmpty) {
        return [];
      }

      return jsonList
          .map((json) => ExpenseModel.fromMap(jsonDecode(json)))
          .toList();
    } catch (e) {
      AppLogger.error('Error retrieving expenses: $e');
      return [];
    }
  }

  // Update an existing expense
  static Future<void> updateExpense(ExpenseModel updatedExpense) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<ExpenseModel> expenses = await getExpenses();

      // Find and replace the expense with matching ID
      final index = expenses.indexWhere((e) => e.id == updatedExpense.id);
      if (index != -1) {
        expenses[index] = updatedExpense;

        // Convert to JSON and save
        final List<String> jsonList =
            expenses.map((expense) => jsonEncode(expense.toMap())).toList();

        await prefs.setStringList(_storageKey, jsonList);
      }
    } catch (e) {
      AppLogger.error('Error updating expense: $e');
    }
  }

  // Delete an expense by ID
  static Future<void> deleteExpense(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<ExpenseModel> expenses = await getExpenses();

      // Remove the expense with matching ID
      expenses.removeWhere((e) => e.id == id);

      // Convert to JSON and save
      final List<String> jsonList =
          expenses.map((expense) => jsonEncode(expense.toMap())).toList();

      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      AppLogger.error('Error deleting expense: $e');
    }
  }

  // Clear all expenses
  static Future<void> clearExpenses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      AppLogger.error('Error clearing expenses: $e');
    }
  }
}
