import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/expense_model.dart';
import '../providers/expense_provider.dart';
import '../utils/category_icons.dart';
import '../utils/constants.dart';

class AddExpenseBottomSheet extends StatelessWidget {
  final ExpenseModel? existingExpense;
  final bool showCategorySelectionOnly;

  const AddExpenseBottomSheet({
    Key? key,
    this.existingExpense,
    this.showCategorySelectionOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If we're editing an uncategorized expense or explicitly showing only category selection
    if (existingExpense != null &&
        (existingExpense!.category == ExpenseCategory.uncategorized ||
            showCategorySelectionOnly)) {
      return CategorySelectionBottomSheet(
        amount: existingExpense!.amount,
        bankName: existingExpense!.bankName,
        description: existingExpense!.description ?? '',
        timestamp: existingExpense!.timestamp,
        existingExpense: existingExpense,
      );
    }

    // Otherwise show the amount input first
    return AmountInputBottomSheet(existingExpense: existingExpense);
  }

  // Static method to show the bottom sheet - makes it easier to call from anywhere
  static Future<void> show(
    BuildContext context, {
    ExpenseModel? existingExpense,
    bool showCategorySelectionOnly = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddExpenseBottomSheet(
        existingExpense: existingExpense,
        showCategorySelectionOnly: showCategorySelectionOnly,
      ),
    );
  }
}

class AmountInputBottomSheet extends StatefulWidget {
  final ExpenseModel? existingExpense;

  const AmountInputBottomSheet({
    Key? key,
    this.existingExpense,
  }) : super(key: key);

  @override
  State<AmountInputBottomSheet> createState() => _AmountInputBottomSheetState();
}

class _AmountInputBottomSheetState extends State<AmountInputBottomSheet> {
  String _amount = '0';
  String _bankName = 'Added manually';
  String _description = '';

  @override
  void initState() {
    super.initState();
    if (widget.existingExpense != null) {
      _amount = widget.existingExpense!.amount.toString().replaceAll('.00', '');
      _bankName = widget.existingExpense!.bankName;
      _description = widget.existingExpense!.description ?? '';
    }
  }

  void _addDigit(String digit) {
    setState(() {
      if (_amount == '0') {
        _amount = digit;
      } else {
        _amount += digit;
      }
    });
  }

  void _addDecimalPoint() {
    setState(() {
      if (!_amount.contains('.')) {
        _amount += '.';
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_amount.length > 1) {
        _amount = _amount.substring(0, _amount.length - 1);
      } else {
        _amount = '0';
      }
    });
  }

  void _showCategorySelection() {
    // Parse amount and handle potential errors
    double parsedAmount;
    try {
      parsedAmount = double.parse(_amount);
      if (parsedAmount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid amount')),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    // Close current bottom sheet and show category selection
    Navigator.of(context).pop();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategorySelectionBottomSheet(
        amount: parsedAmount,
        bankName: _bankName,
        description: _description,
        timestamp: DateTime.now(),
        existingExpense: widget.existingExpense,
      ),
    );
  }

  String get formattedAmount {
    // Format the amount with commas for thousands
    if (_amount.isEmpty || _amount == '0') return '0';

    List<String> parts = _amount.split('.');
    String integerPart = parts[0];

    // Add commas to the integer part
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formattedInteger =
        integerPart.replaceAllMapped(reg, (Match match) => '${match[1]},');

    // Add back the decimal part if it exists
    if (parts.length > 1) {
      return '$formattedInteger.${parts[1]}';
    }
    return formattedInteger;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 4,
              width: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            // Amount display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '₦', // Use system font
                          style: TextStyle(
                            fontSize: 48,
                            color: formattedAmount == '0'
                                ? const Color(0xFFC5C5C5)
                                : AppColors.textPrimary,
                          ),
                        ),
                        TextSpan(
                          text: formattedAmount, // Use Manrope with commas
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            fontSize: 48,
                            color: formattedAmount == '0'
                                ? const Color(0xFFC5C5C5)
                                : AppColors.textPrimary,
                            letterSpacing: -1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Keypad
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  // Row 1: 1, 2, 3
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('1'),
                      _buildKeypadButton('2'),
                      _buildKeypadButton('3'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 2: 4, 5, 6
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('4'),
                      _buildKeypadButton('5'),
                      _buildKeypadButton('6'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 3: 7, 8, 9
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('7'),
                      _buildKeypadButton('8'),
                      _buildKeypadButton('9'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Row 4: ., 0, backspace
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildKeypadButton('.', onTap: _addDecimalPoint),
                      _buildKeypadButton('0'),
                      _buildKeypadButton(
                        '⌫',
                        onTap: _backspace,
                        child: const Icon(Icons.backspace_outlined,
                            size: 24, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Confirm button
                  _buildConfirmButton(),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String value,
      {VoidCallback? onTap, Widget? child}) {
    return InkWell(
      onTap: onTap ?? () => _addDigit(value),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: child ??
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return InkWell(
      onTap: _showCategorySelection,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 130,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Center(
          child: Icon(
            Icons.check_rounded,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class CategorySelectionBottomSheet extends StatelessWidget {
  final double amount;
  final String bankName;
  final String description;
  final DateTime timestamp;
  final ExpenseModel? existingExpense;
  final VoidCallback? onCategorySelected;

  const CategorySelectionBottomSheet({
    Key? key,
    required this.amount,
    required this.bankName,
    required this.description,
    required this.timestamp,
    this.existingExpense,
    this.onCategorySelected,
  }) : super(key: key);

  String get formattedAmount {
    // Format the amount with commas for thousands
    String amountStr = amount.toStringAsFixed(2);
    List<String> parts = amountStr.split('.');
    String integerPart = parts[0];

    // Add commas to the integer part
    final RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    String formattedInteger =
        integerPart.replaceAllMapped(reg, (Match match) => '${match[1]},');

    // Add back the decimal part
    return '$formattedInteger.${parts[1]}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (existingExpense == null) {
      return 'Today';
    } else if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      final difference = today.difference(dateToCheck).inDays;
      if (difference < 7) {
        return '$difference days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 4,
            width: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFD9D9D9),
              borderRadius: BorderRadius.circular(20.0),
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '₦', // Use system font
                  style: TextStyle(fontSize: 32, color: AppColors.textPrimary),
                ),
                TextSpan(
                  text: formattedAmount, // Use Manrope with commas
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: AppColors.textPrimary,
                    letterSpacing: -1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_formatDate(timestamp)} · $bankName',
            style: const TextStyle(
              fontFamily: 'Manrope',
              color: AppColors.textSecondary2,
              fontWeight: FontWeight.w600,
              letterSpacing: -.4,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                const Divider(
                  thickness: 1,
                  indent: 14,
                  // endIndent: 14,
                  color: AppColors.border,
                ),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text(
                    'Select expense category',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: AppColors.textSecondary2,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -.6,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildCategoryGrid(context, expenseProvider),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(
      BuildContext context, ExpenseProvider expenseProvider) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: ExpenseCategory.values
          .map((category) {
            // Skip Uncategorized in the grid
            if (category == ExpenseCategory.uncategorized) {
              return const SizedBox.shrink();
            }

            return GestureDetector(
              onTap: () async {
                // Create or update expense based on whether we're editing
                if (existingExpense != null) {
                  // Update existing expense with new category
                  final updatedExpense = existingExpense!.copyWith(
                    category: category,
                    description: description.isNotEmpty
                        ? description
                        : existingExpense!.description,
                  );
                  await expenseProvider.updateExpense(updatedExpense);
                } else {
                  // Create new expense
                  final newExpense = ExpenseModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    bankName: bankName,
                    amount: amount,
                    timestamp: timestamp,
                    category: category,
                    description: description.isNotEmpty ? description : null,
                  );
                  await expenseProvider.addExpense(newExpense);
                }

                // Call the callback if provided
                if (onCategorySelected != null) {
                  onCategorySelected!();
                }

                // Close the modal if we're in a modal context
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CategoryIcons.getIconWidget(category),
                    const SizedBox(height: 8),
                    Text(
                      _formatCategoryName(category.toString().split('.').last),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: -.4,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          })
          .where((widget) => widget is! SizedBox)
          .toList(),
    );
  }

  String _formatCategoryName(String name) {
    if (name.isEmpty) return 'No category name!';

    // Handle the first character separately to ensure it's capitalized
    String result = name[0].toUpperCase();

    // Process the rest of the string
    if (name.length > 1) {
      for (int i = 1; i < name.length; i++) {
        final char = name[i];
        if (char == char.toUpperCase() && char != char.toLowerCase()) {
          // It's an uppercase letter, add a space before it
          result += ' ${char}';
        } else {
          result += char;
        }
      }
    }
    return result;
  }
}
