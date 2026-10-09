import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_receipt_tracker/domain/models/expense.dart';
import 'package:expense_receipt_tracker/ui/features/analytics/views/category_donut_chart.dart';
import 'package:expense_receipt_tracker/ui/features/analytics/views/weekly_bar_chart.dart';

void main() {
  final sampleExpenses = [
    Expense(
      id: 1,
      merchant: 'Co.opmart',
      amount: 150000,
      date: DateTime.now(),
      category: ExpenseCategory.food,
    ),
    Expense(
      id: 2,
      merchant: 'Fahasa',
      amount: 80000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: ExpenseCategory.study,
    ),
    Expense(
      id: 3,
      merchant: 'Grab',
      amount: 50000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: ExpenseCategory.travel,
    ),
  ];

  group('CategoryDonutChart Widget Tests', () {
    testWidgets('1. Render donut chart with data and animated canvas without errors',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryDonutChart(expenses: sampleExpenses),
          ),
        ),
      );

      // Cho animation chạy hoàn tất
      await tester.pumpAndSettle();

      // Kiểm tra có CustomPaint vẽ canvas
      expect(find.byType(CustomPaint), findsWidgets);
      // Kiểm tra tổng tiền hiển thị ở giữa donut chart
      expect(find.text('Tổng ngân quỹ'), findsOneWidget);
      // Kiểm tra nhãn danh mục thức ăn và học tập
      expect(find.text(ExpenseCategory.food.displayName), findsOneWidget);
      expect(find.text(ExpenseCategory.study.displayName), findsOneWidget);
    });

    testWidgets('2. Render trạng thái rỗng khi không có chi tiêu',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryDonutChart(expenses: []),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('Chưa có dữ liệu'), findsOneWidget);
    });
  });

  group('WeeklyBarChart Widget Tests', () {
    testWidgets('1. Render weekly bar chart and interactive bar tap tooltip',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 250,
              child: WeeklyBarChart(expenses: sampleExpenses),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Kiểm tra CustomPaint có mặt
      expect(find.byType(CustomPaint), findsWidgets);

      // Chạm vào thanh bar để kích hoạt tooltip
      await tester.tap(find.byType(CustomPaint).last);
      await tester.pumpAndSettle();

      // Kiểm tra icon lịch trong tooltip xuất hiện
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });
  });
}
