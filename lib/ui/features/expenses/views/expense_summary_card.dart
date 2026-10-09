import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/expense.dart';

/// Reusable Widget hiển thị tóm tắt chi phí theo chuẩn Material 3
/// Đáp ứng đầy đủ 4 tiêu chí của bài tập In-Class Lab Exercise và nâng cấp thẩm mỹ cao cấp.
class ExpenseSummaryCard extends StatelessWidget {
  final String merchant;
  final double amount;
  final DateTime date;
  final VoidCallback onTap;
  final ExpenseCategory category;
  final String? imagePath;
  final VoidCallback? onDelete;

  const ExpenseSummaryCard({
    super.key,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.onTap,
    this.category = ExpenseCategory.food,
    this.imagePath,
    this.onDelete,
  });

  /// Factory constructor nhận trực tiếp Domain Model Expense
  factory ExpenseSummaryCard.fromExpense({
    Key? key,
    required Expense expense,
    required VoidCallback onTap,
    VoidCallback? onDelete,
  }) {
    return ExpenseSummaryCard(
      key: key,
      merchant: expense.merchant,
      amount: expense.amount,
      date: expense.date,
      category: expense.category,
      imagePath: expense.imagePath,
      onTap: onTap,
      onDelete: onDelete,
    );
  }

  /// Định dạng số tiền nổi bật theo chuẩn Việt Nam Đồng (VD: 150.000 đ)
  String _formatVND(double value) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(value).trim();
  }

  String _formatDisplayDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(dt.year, dt.month, dt.day);

    if (itemDate == today) {
      return 'Hôm nay, ${DateFormat('HH:mm').format(dt)}';
    } else if (itemDate == today.subtract(const Duration(days: 1))) {
      return 'Hôm qua, ${DateFormat('HH:mm').format(dt)}';
    } else {
      return DateFormat('dd/MM/yyyy').format(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayDate = _formatDisplayDate(date);

    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias, // Ngăn hiệu ứng InkWell tràn ra ngoài góc bo tròn
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // 1. Icon bên trong circular container chỉ định category (có viền sáng nhẹ)
              Container(
                width: 50.0,
                height: 50.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: category.color.withValues(alpha: 0.12),
                  border: Border.all(
                    color: category.color.withValues(alpha: 0.25),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  category.icon,
                  color: category.color,
                  size: 24.0,
                ),
              ),
              const SizedBox(width: 16.0),

              // 2. Tên cửa hàng và ngày tháng xếp dọc với CrossAxisAlignment.start
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      merchant,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5.0),
                    Row(
                      children: [
                        Text(
                          displayDate,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                          decoration: BoxDecoration(
                            color: category.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            category.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: category.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.5,
                            ),
                          ),
                        ),
                        if (imagePath != null && imagePath!.isNotEmpty) ...[
                          const SizedBox(width: 6.0),
                          Icon(
                            Icons.receipt_outlined,
                            size: 14.0,
                            color: theme.colorScheme.primary.withValues(alpha: 0.8),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),

              // 3. Số tiền nổi bật định dạng VND (###.### đ)
              Text(
                _formatVND(amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.primary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
