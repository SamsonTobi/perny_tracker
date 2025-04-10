// lib/utils/category_icons.dart
import 'package:flutter/material.dart';
import '../models/expense_model.dart';

class CategoryIcons {
  static const Map<ExpenseCategory, String> emojis = {
    ExpenseCategory.uncategorized: '😶',
    ExpenseCategory.transport: '🚌',
    ExpenseCategory.airtime: '📱',
    ExpenseCategory.data: '📊',
    ExpenseCategory.utilities: '🛒',
    ExpenseCategory.personal: '😀',
    ExpenseCategory.work: '🔧',
    ExpenseCategory.food: '🍔',
    ExpenseCategory.shopping: '🛍️',
    ExpenseCategory.entertainment: '🎬',
    ExpenseCategory.health: '💊',
    ExpenseCategory.education: '📚',
    ExpenseCategory.other: '📦',
  };

  static Widget getIconWidget(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.uncategorized:
        return const Text('❓', style: TextStyle(fontSize: 32));
      case ExpenseCategory.transport:
        return const Text('🚌', style: TextStyle(fontSize: 32));
      case ExpenseCategory.airtime:
        return const Text('📱', style: TextStyle(fontSize: 32));
      case ExpenseCategory.data:
        return const Text('📊', style: TextStyle(fontSize: 32));
      case ExpenseCategory.utilities:
        return const Text('🛒', style: TextStyle(fontSize: 32));
      case ExpenseCategory.personal:
        return const Text('😎', style: TextStyle(fontSize: 32));
      case ExpenseCategory.work:
        return const Text('⚒', style: TextStyle(fontSize: 32));
      case ExpenseCategory.education:
        return const Text('📚', style: TextStyle(fontSize: 32));
      case ExpenseCategory.health:
        return const Text('💊', style: TextStyle(fontSize: 32));
      case ExpenseCategory.food:
        return const Text('🍔', style: TextStyle(fontSize: 32));
      case ExpenseCategory.entertainment:
        return const Text('🎬', style: TextStyle(fontSize: 32));
      case ExpenseCategory.shopping:
        return const Text('🛍️', style: TextStyle(fontSize: 32));
      default:
        return const Text('📦', style: TextStyle(fontSize: 32));
    }
  }
}
