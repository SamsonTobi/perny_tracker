// lib/services/expense_bottom_sheet_service.dart
import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../screens/add_expense_bottom_sheet.dart';
import 'overlay_service.dart';

// class CategorySelectionService {
//   // Show add expense modal (full flow)
//   static void showAddExpenseModal(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) =>
//           const ExpenseBottomSheetService.showAddExpenseFlow(context),
//     );
//   }
//
//   // Show only category selection modal (for updating uncategorized expenses)
//   static void showCategorySelectionForExpense(
//     BuildContext context,
//     ExpenseModel expense,
//   ) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => CategorySelectionModal(
//         amount: expense.amount,
//         bankName: expense.bankName,
//         description: expense.description ?? '',
//         existingExpense: expense,
//       ),
//     );
//   }
//
//   // This method can be called from your notification service or other background processes
//   // to show the category selection modal over other apps
//   static Future<void> showCategorySelectionOverlay(
//     BuildContext context,
//     ExpenseModel expense,
//   ) async {
//     // This is a placeholder for the future overlay implementation
//     // You'll need to use a platform-specific plugin or service for this
//     // For now, we'll just use the normal modal if the app is in the foreground
//     showCategorySelectionForExpense(context, expense);
//   }
// }

class ExpenseBottomSheetService {
  /// Shows the full expense addition flow (amount input + category selection)
  static Future<void> showAddExpenseFlow(BuildContext context) {
    return AddExpenseBottomSheet.show(context);
  }

  /// Shows only the category selection for an uncategorized expense
  static Future<void> showCategorySelectionForExpense(
      BuildContext context, ExpenseModel expense) {
    return AddExpenseBottomSheet.show(
      context,
      existingExpense: expense,
      showCategorySelectionOnly: true,
    );
  }

  /// This method can be called from your notification service
  /// to show the category selection over other apps in the future
  static Future<void> showCategorySelectionOverApps(
      ExpenseModel expense) async {
    try {
      final bool hasPermission = await OverlayService.hasPermission();

      if (!hasPermission) {
        debugPrint('Overlay permission not granted. Cannot show overlay.');
        return;
      }
      // Use the overlay service to show the category selection
      final bool shown =
          await OverlayService.showCategorySelectionOverlay(expense);

      if (!shown) {
        debugPrint('Failed to show overlay for expense: ${expense.id}');
      }
    } catch (e) {
      debugPrint('Error showing category selection overlay: $e');
    }
  }
}
