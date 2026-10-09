import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../domain/models/expense.dart';

class CategoryDonutChart extends StatefulWidget {
  final List<Expense> expenses;

  const CategoryDonutChart({super.key, required this.expenses});

  @override
  State<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends State<CategoryDonutChart> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _animation;
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant CategoryDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expenses != widget.expenses) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _formatVND(double value) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(value).trim();
  }

  Map<ExpenseCategory, double> get _categoryTotals {
    final map = <ExpenseCategory, double>{};
    for (final e in widget.expenses) {
      map[e.category] = (map[e.category] ?? 0.0) + e.amount;
    }
    return map;
  }

  double get _totalAmount {
    return _categoryTotals.values.fold(0.0, (sum, val) => sum + val);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = _categoryTotals;
    final total = _totalAmount;

    if (total == 0 || totals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Chưa có dữ liệu để vẽ biểu đồ canvas',
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Biểu đồ CustomPainter vẽ trực tiếp lên canvas có animation mượt mà
        SizedBox(
          height: 230.0,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(220.0, 220.0),
                    painter: _AnimatedDonutChartPainter(
                      categoryTotals: totals,
                      totalAmount: total,
                      animationProgress: _animation.value,
                      selectedCategory: _selectedCategory,
                    ),
                  ),
                  // Thông tin chi tiết ở tâm Donut
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCategory != null
                            ? _selectedCategory!.displayName
                            : 'Tổng ngân quỹ',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        _formatVND(_selectedCategory != null
                            ? (totals[_selectedCategory] ?? 0.0)
                            : total),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: _selectedCategory != null
                              ? _selectedCategory!.color
                              : theme.colorScheme.primary,
                        ),
                      ),
                      if (_selectedCategory != null)
                        Text(
                          '${((totals[_selectedCategory]! / total) * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _selectedCategory!.color,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        Text(
                          '${totals.length} danh mục',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 18.0),

        // Danh sách chip danh mục tương tác (Interactive Legend)
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          children: totals.entries.map((entry) {
            final cat = entry.key;
            final amount = entry.value;
            final percent = (amount / total) * 100;
            final isSelected = _selectedCategory == cat;

            return InkWell(
              borderRadius: BorderRadius.circular(16.0),
              onTap: () {
                setState(() {
                  _selectedCategory = isSelected ? null : cat;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: isSelected ? cat.color.withValues(alpha: 0.18) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: isSelected
                        ? cat.color
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 14.0, color: cat.color),
                    const SizedBox(width: 6.0),
                    Text(
                      cat.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '${percent.toStringAsFixed(0)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _AnimatedDonutChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> categoryTotals;
  final double totalAmount;
  final double animationProgress;
  final ExpenseCategory? selectedCategory;

  _AnimatedDonutChartPainter({
    required this.categoryTotals,
    required this.totalAmount,
    required this.animationProgress,
    this.selectedCategory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const defaultStroke = 26.0;

    var currentAngle = -math.pi / 2;

    for (final entry in categoryTotals.entries) {
      final category = entry.key;
      final fullSweepAngle = (entry.value / totalAmount) * (2 * math.pi);
      // Sweep angle theo tiến độ animation
      final animatedSweepAngle = fullSweepAngle * animationProgress;

      final isSelected = selectedCategory == category;
      final strokeWidth = isSelected ? defaultStroke + 8.0 : defaultStroke;

      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      if (isSelected) {
        paint.maskFilter = const MaskFilter.blur(BlurStyle.solid, 4.0);
      }

      final arcRect = Rect.fromCircle(
        center: center,
        radius: radius - (defaultStroke / 2) - (isSelected ? 2.0 : 0.0),
      );

      // Khoảng cách thẩm mỹ giữa các cung tròn
      final gap = animatedSweepAngle > 0.1 ? 0.05 : 0.0;
      canvas.drawArc(
        arcRect,
        currentAngle + gap,
        math.max(animatedSweepAngle - gap * 2, 0.01),
        false,
        paint,
      );

      currentAngle += animatedSweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedDonutChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedCategory != selectedCategory ||
        oldDelegate.totalAmount != totalAmount;
  }
}
