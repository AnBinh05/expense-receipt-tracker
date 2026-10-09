import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../../../domain/models/expense.dart';

class WeeklyBarChart extends StatefulWidget {
  final List<Expense> expenses;

  const WeeklyBarChart({super.key, required this.expenses});

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _animation;
  int? _selectedBarIndex;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant WeeklyBarChart oldWidget) {
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

  List<_DayBarData> get _weeklyData {
    final now = DateTime.now();
    final list = <_DayBarData>[];

    for (int i = 6; i >= 0; i--) {
      final targetDate = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final dayExpenses = widget.expenses.where((e) {
        return e.date.year == targetDate.year &&
            e.date.month == targetDate.month &&
            e.date.day == targetDate.day;
      });

      final total = dayExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final label = _getWeekdayLabel(targetDate.weekday);

      list.add(_DayBarData(
        date: targetDate,
        label: label,
        amount: total,
      ));
    }
    return list;
  }

  String _getWeekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'T2';
      case DateTime.tuesday:
        return 'T3';
      case DateTime.wednesday:
        return 'T4';
      case DateTime.thursday:
        return 'T5';
      case DateTime.friday:
        return 'T6';
      case DateTime.saturday:
        return 'T7';
      case DateTime.sunday:
        return 'CN';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _weeklyData;
    final maxAmount = data.map((d) => d.amount).fold(1.0, (prev, val) => val > prev ? val : prev);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tooltip hiển thị số tiền khi bấm vào cột
        if (_selectedBarIndex != null && _selectedBarIndex! < data.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today, size: 14.0, color: theme.colorScheme.primary),
                  const SizedBox(width: 6.0),
                  Text(
                    '${DateFormat('dd/MM/yyyy').format(data[_selectedBarIndex!].date)}: ${_formatVND(data[_selectedBarIndex!].amount)}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Biểu đồ cột vẽ bằng CustomPainter trực tiếp
        SizedBox(
          height: 180.0,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return GestureDetector(
                onTapUp: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox != null) {
                    final width = renderBox.size.width;
                    final slotWidth = width / data.length;
                    final index = (details.localPosition.dx / slotWidth).floor().clamp(0, data.length - 1);
                    setState(() {
                      _selectedBarIndex = _selectedBarIndex == index ? null : index;
                    });
                  }
                },
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _AnimatedBarChartPainter(
                    data: data,
                    maxAmount: maxAmount,
                    progress: _animation.value,
                    selectedIndex: _selectedBarIndex,
                    primaryColor: theme.colorScheme.primary,
                    tertiaryColor: theme.colorScheme.tertiary,
                    surfaceColor: theme.colorScheme.surfaceContainerHighest,
                    textColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayBarData {
  final DateTime date;
  final String label;
  final double amount;

  _DayBarData({required this.date, required this.label, required this.amount});
}

class _AnimatedBarChartPainter extends CustomPainter {
  final List<_DayBarData> data;
  final double maxAmount;
  final double progress;
  final int? selectedIndex;
  final Color primaryColor;
  final Color tertiaryColor;
  final Color surfaceColor;
  final Color textColor;

  _AnimatedBarChartPainter({
    required this.data,
    required this.maxAmount,
    required this.progress,
    required this.selectedIndex,
    required this.primaryColor,
    required this.tertiaryColor,
    required this.surfaceColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    const bottomPadding = 28.0;
    final chartHeight = size.height - bottomPadding;
    final slotWidth = size.width / data.length;
    final barWidth = (slotWidth * 0.48).clamp(16.0, 36.0);

    // Đường cơ sở đáy (Baseline)
    final baselinePaint = Paint()
      ..color = surfaceColor
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, chartHeight),
      Offset(size.width, chartHeight),
      baselinePaint,
    );

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final isSelected = selectedIndex == i;
      final isToday = i == data.length - 1;

      final ratio = maxAmount > 0 ? (item.amount / maxAmount) : 0.0;
      final currentHeight = (ratio * chartHeight * progress).clamp(4.0, chartHeight);

      final centerX = (i * slotWidth) + (slotWidth / 2);
      final left = centerX - (barWidth / 2);
      final top = chartHeight - currentHeight;

      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, currentHeight),
        const Radius.circular(8.0),
      );

      final barPaint = Paint()
        ..style = PaintingStyle.fill;

      if (isSelected) {
        barPaint.shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [primaryColor, tertiaryColor],
        ).createShader(Rect.fromLTWH(left, top, barWidth, currentHeight));
      } else if (isToday) {
        barPaint.shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [primaryColor, primaryColor.withValues(alpha: 0.7)],
        ).createShader(Rect.fromLTWH(left, top, barWidth, currentHeight));
      } else if (item.amount > 0) {
        barPaint.color = primaryColor.withValues(alpha: 0.35);
      } else {
        barPaint.color = surfaceColor;
      }

      canvas.drawRRect(barRect, barPaint);

      // Nhãn thứ trong tuần
      textPainter.text = TextSpan(
        text: item.label,
        style: TextStyle(
          color: (isToday || isSelected) ? primaryColor : textColor,
          fontSize: 12.0,
          fontWeight: (isToday || isSelected) ? FontWeight.bold : FontWeight.w500,
        ),
      );
      textPainter.layout(minWidth: slotWidth, maxWidth: slotWidth);
      textPainter.paint(
        canvas,
        Offset(centerX - (slotWidth / 2), chartHeight + 8.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedBarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.maxAmount != maxAmount;
  }
}
