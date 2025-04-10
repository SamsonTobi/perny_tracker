// lib/models/expense_model.dart
import 'package:flutter/foundation.dart';

enum ExpenseCategory {
  uncategorized,
  transport,
  airtime,
  data,
  utilities,
  personal,
  work,
  food,
  shopping,
  entertainment,
  health,
  education,
  other
}

class ExpenseModel {
  final String id;
  final String bankName;
  final double amount;
  final DateTime timestamp;
  final ExpenseCategory category;
  final String? description;

  ExpenseModel({
    required this.id,
    required this.bankName,
    required this.amount,
    required this.timestamp,
    this.category = ExpenseCategory.uncategorized,
    this.description,
  });

  // Factory constructor to create an expense from a notification
  factory ExpenseModel.fromNotification({
    required String? packageName,
    required String? content,
    required DateTime timestamp,
    required String? amountString,
  }) {
    // Generate a unique ID based on timestamp
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Convert bank package name to bank name
    String bankName = 'Unknown Bank';
    if (packageName != null) {
      switch (packageName) {
        case 'com.kudabank.app':
          bankName = 'Kuda Bank';
          break;
        case 'team.opay.pay':
          bankName = 'OPay';
          break;
        case 'com.moniepoint.personal':
          bankName = 'Moniepoint';
          break;
      }
    }

    // Convert amount string to double
    double amount = 0.0;
    if (amountString != null) {
      // Remove currency symbols, commas, and convert to double
      final cleanedAmount = amountString.replaceAll(RegExp(r'[₦$,]'), '');
      try {
        amount = double.parse(cleanedAmount);
      } catch (e) {
        debugPrint('Error parsing amount: $e');
      }
    }

    return ExpenseModel(
      id: id,
      bankName: bankName,
      amount: amount,
      timestamp: timestamp,
      category: ExpenseCategory.uncategorized,
      description: content,
    );
  }

  // Convert to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bankName': bankName,
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
      'category': category.index,
      'description': description,
    };
  }

  // Create from a map (for storage retrieval)
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'],
      bankName: map['bankName'],
      amount: map['amount'],
      timestamp: DateTime.parse(map['timestamp']),
      category: ExpenseCategory.values[map['category']],
      description: map['description'],
    );
  }

  // Create a copy of this expense with some fields replaced
  ExpenseModel copyWith({
    String? id,
    String? bankName,
    double? amount,
    DateTime? timestamp,
    ExpenseCategory? category,
    String? description,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }
}
