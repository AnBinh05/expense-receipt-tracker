import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/expense.dart';
import 'category_donut_chart.dart';
import 'weekly_bar_chart.dart';

class AnalyticsView extends StatelessWidget {
  final List<Expense> expenses;

  const AnalyticsView({super.key, required this.expenses});

  String _formatVND(double value) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(value).trim();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final avgDaily = expenses.isNotEmpty ? (totalSpent / 7) : 0.0;

    // Tìm danh mục chi tiêu nhiều nhất
    final categoryTotals = <ExpenseCategory, double>{};
    for (final e in expenses) {
      categoryTotals[e.category] = (categoryTotals[e.category] ?? 0.0) + e.amount;
    }

    ExpenseCategory? topCategory;
    double topCategoryAmount = 0.0;
    categoryTotals.forEach((cat, amt) {
      if (amt > topCategoryAmount) {
        topCategoryAmount = amt;
        topCategory = cat;
      }
    });

    if (expenses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 72.0, color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 16.0),
              Text(
                'Chưa có dữ liệu thống kê',
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Hãy quét hoặc thêm hóa đơn đầu tiên để xem biểu đồ chi tiết!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      children: [
        // 1. Thẻ 3 chỉ số KPI chính
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                theme,
                title: 'Tổng chi tiêu',
                value: _formatVND(totalSpent),
                icon: Icons.account_balance_wallet_outlined,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: _buildMetricCard(
                theme,
                title: 'Trung bình/ngày',
                value: _formatVND(avgDaily),
                icon: Icons.trending_up,
                color: Colors.blue.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),
        if (topCategory != null)
          _buildTopCategoryBanner(theme, topCategory!, topCategoryAmount, totalSpent),

        const SizedBox(height: 20.0),

        // 2. Card Biểu đồ cột: Xu hướng 7 ngày
        Card(
          elevation: 1.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bar_chart, color: theme.colorScheme.primary, size: 22.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'Xu Hướng 7 Ngày Qua',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                WeeklyBarChart(expenses: expenses),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // 3. Card Biểu đồ Donut: Phân bổ danh mục
        Card(
          elevation: 1.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.donut_large, color: theme.colorScheme.primary, size: 22.0),
                    const SizedBox(width: 8.0),
                    Text(
                      'Cơ Cấu Chi Tiêu Danh Mục',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                CategoryDonutChart(expenses: expenses),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16.0),

        // 4. Card Danh sách chi tiết danh mục kèm thanh tiến độ %
        Card(
          elevation: 1.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi Tiết Từng Danh Mục',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16.0),
                ...categoryTotals.entries.map((entry) {
                  final cat = entry.key;
                  final amount = entry.value;
                  final ratio = totalSpent > 0 ? (amount / totalSpent) : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(cat.icon, color: cat.color, size: 18.0),
                            const SizedBox(width: 8.0),
                            Text(
                              cat.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const Spacer(),
                            Text(
                              _formatVND(amount),
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              '(${(ratio * 100).toStringAsFixed(0)}%)',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6.0,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(cat.color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),

        const SizedBox(height: 40.0),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20.0),
              const SizedBox(width: 8.0),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCategoryBanner(
    ThemeData theme,
    ExpenseCategory topCat,
    double topAmount,
    double totalSpent,
  ) {
    final percent = totalSpent > 0 ? ((topAmount / totalSpent) * 100).toStringAsFixed(0) : '0';

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: topCat.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: topCat.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: topCat.color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(topCat.icon, color: topCat.color, size: 22.0),
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chi tiêu nhiều nhất vào: ${topCat.displayName}',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'Chiếm $percent% tổng chi tiêu (${_formatVND(topAmount)})',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
