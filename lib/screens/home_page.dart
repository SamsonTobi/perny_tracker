// lib/screens/home_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:perny_expense_tracker/utils/logger.dart';
import '../providers/expense_provider.dart';
import '../models/expense_model.dart';
import '../services/expense_bottom_sheet_service.dart';
import '../utils/category_icons.dart';
import '../utils/constants.dart';
import '../services/overlay_service.dart';
import '../services/notification_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _refreshExpenses() async {
    final provider = Provider.of<ExpenseProvider>(context, listen: false);
    await provider.refreshExpenses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<ExpenseProvider>(
          builder: (context, expenseProvider, child) {
            AppLogger.debug(
                "HomePage rebuilding with ${expenseProvider.expenses.length} expenses");

            if (expenseProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final groupedExpenses = expenseProvider.groupedExpenses;
            final totalsByGroup = expenseProvider.totalsByGroup;
            final totalThisWeek = expenseProvider.totalThisWeek;

            // Format the total with commas
            final formattedTotal =
                NumberFormat('#,##0.00').format(totalThisWeek);

            return Column(
              children: [
                // Weekly summary
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                  child: InkWell(
                    onTap: () {
                      expenseProvider.clearAllExpenses();
                    },
                    child: Column(
                      children: [
                        const Text(
                          'Spent this week',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary2,
                            letterSpacing: -.8,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: '₦', // Use system font
                                style: TextStyle(
                                    fontSize: 48, color: AppColors.textPrimary),
                              ),
                              TextSpan(
                                text: formattedTotal, // Use Manrope with commas
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -2,
                                  fontSize: 48,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expenses list
                Expanded(
                  child: groupedExpenses.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => _refreshExpenses(),
                          child: ListView(
                            children: [
                              ...groupedExpenses.entries.map((entry) {
                                return _buildExpenseGroup(
                                  context,
                                  entry.key,
                                  entry.value,
                                  totalsByGroup[entry.key] ?? 0,
                                );
                              }).toList(),
                              // Add some padding at the bottom for the FAB
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: Container(
        width: 130,
        height: 50,
        margin: const EdgeInsets.only(bottom: 14),
        child: FloatingActionButton(
          onPressed: () =>
              ExpenseBottomSheetService.showAddExpenseFlow(context),
          elevation: 0,
          backgroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No expenses yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final isGranted = await NotificationService.requestPermission();
              if (!isGranted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Permission not granted')),
                  );
                }
              }
            },
            child: const Text('Check Notification Permission'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () async {
              final isGranted = await OverlayService.requestPermission();
              if (isGranted) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Overlay permission granted')),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Overlay permission not granted')),
                  );
                }
              }
            },
            child: const Text('Request Overlay Permission'),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseGroup(
    BuildContext context,
    String groupTitle,
    List<ExpenseModel> expenses,
    double totalAmount,
  ) {
    // Format the group total with commas
    final formattedGroupTotal = NumberFormat('#,##0.00').format(totalAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group header with dropdown and total
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0),
            color: const Color(0xFFF5F5F5),
          ),
          child: Row(
            children: [
              Text(
                groupTitle,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: -.8,
                  fontSize: 18,
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
              ),
              const Spacer(),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '₦', // Use system font
                      style: TextStyle(
                          fontSize: 18, color: AppColors.textSecondary2),
                    ),
                    TextSpan(
                      text: formattedGroupTotal, // Use Manrope with commas
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary2,
                        letterSpacing: -.8,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Expenses list
        ...expenses.map((expense) => _buildExpenseItem(expense)),
      ],
    );
  }

  Widget _buildExpenseItem(ExpenseModel expense) {
    final timeFormat = DateFormat('h:mm a');

    // Format the expense amount with commas
    final formattedAmount = NumberFormat('#,##0').format(expense.amount);
    final bool isUncategorized =
        expense.category == ExpenseCategory.uncategorized;

    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: SizedBox(
            width: 30,
            height: 40,
            child: Center(
              child: CategoryIcons.getIconWidget(expense.category),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: isUncategorized
                      ? () => ExpenseBottomSheetService
                          .showCategorySelectionForExpense(context, expense)
                      : null,
                  child: Row(
                    children: [
                      Text(
                        _getCategoryName(expense.category),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: -.6,
                          fontSize: 18,
                        ),
                      ),
                      if (expense.category == ExpenseCategory.uncategorized)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.textSecondary2,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: '₦', // Use system font
                      style:
                          TextStyle(fontSize: 18, color: AppColors.textPrimary),
                    ),
                    TextSpan(
                      text: formattedAmount, // Use Manrope with commas
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -.8,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${timeFormat.format(expense.timestamp)} · ${expense.bankName}',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary2,
                letterSpacing: -.4,
                fontSize: 14,
              ),
            ),
          ),
          onTap: () {
            // Show expense details or edit
          },
        ),
        const Divider(
          height: 1.5,
          indent: 14,
          endIndent: 14,
          color: AppColors.border,
        ),
      ],
    );
  }

  String _getCategoryName(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.uncategorized:
        return 'Uncategorized';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.airtime:
        return 'Airtime';
      case ExpenseCategory.data:
        return 'Data';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.personal:
        return 'Personal';
      case ExpenseCategory.work:
        return 'Work';
      default:
        return category.toString().split('.').last;
    }
  }
}
