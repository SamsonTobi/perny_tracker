import 'package:flutter/material.dart';
import '../models/expense_model.dart';
import '../screens/add_expense_bottom_sheet.dart';
import '../services/overlay_service.dart';
import '../utils/logger.dart';

class OverlayScreen extends StatefulWidget {
  const OverlayScreen({Key? key}) : super(key: key);

  @override
  State<OverlayScreen> createState() => _OverlayScreenState();
}

class _OverlayScreenState extends State<OverlayScreen> {
  ExpenseModel? _currentExpense;

  @override
  void initState() {
    super.initState();
    _listenForExpenses();
  }

  void _listenForExpenses() {
    OverlayService.expenseStream.listen((expense) {
      setState(() {
        _currentExpense = expense;
      });
      AppLogger.log(
          "Overlay received expense: ${expense.amount} from ${expense.bankName}");
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentExpense == null) {
      return const Material(
        color: Colors.transparent,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          // Close overlay when tapping outside the content
          OverlayService.closeOverlay();
        },
        child: Container(
          color: Colors.black54,
          child: Center(
            child: GestureDetector(
              onTap: () {
                // Prevent closing when tapping on the content
              },
              child: CategorySelectionBottomSheet(
                amount: _currentExpense!.amount,
                bankName: _currentExpense!.bankName,
                description: _currentExpense!.description ?? '',
                timestamp: _currentExpense!.timestamp,
                existingExpense: _currentExpense,
                onCategorySelected: () {
                  // Close the overlay when a category is selected
                  OverlayService.closeOverlay();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
