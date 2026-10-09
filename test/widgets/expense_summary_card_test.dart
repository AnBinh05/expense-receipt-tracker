import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_receipt_tracker/domain/models/expense.dart';
import 'package:expense_receipt_tracker/ui/features/expenses/views/expense_summary_card.dart';

void main() {
  group('ExpenseSummaryCard Widget Tests', () {
    testWidgets('1. Hiển thị đúng merchant, ngày tháng và số tiền định dạng VND',
        (WidgetTester tester) async {
      final testDate = DateTime.now();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSummaryCard(
              merchant: 'Co.opmart Cống Quỳnh',
              amount: 150000,
              date: testDate,
              category: ExpenseCategory.food,
              onTap: () {},
            ),
          ),
        ),
      );

      // Kiểm tra tên cửa hàng và ngày tháng
      expect(find.text('Co.opmart Cống Quỳnh'), findsOneWidget);
      expect(find.textContaining('Hôm nay'), findsOneWidget);

      // Kiểm tra định dạng tiền tệ VND (###.### đ)
      expect(find.textContaining('150.000'), findsOneWidget);
      expect(find.textContaining('đ'), findsOneWidget);

      // Kiểm tra icon category bên trong container tròn
      expect(find.byIcon(ExpenseCategory.food.icon), findsOneWidget);
    });

    testWidgets('2. Kích hoạt ink ripple InkWell onTap callback khi chạm',
        (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSummaryCard(
              merchant: 'Highlands Coffee',
              amount: 45000,
              date: DateTime.now(),
              category: ExpenseCategory.food,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Chạm vào InkWell
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('3. Kiểm tra bố cục không bị tràn (overflow) khi merchant rất dài',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ExpenseSummaryCard(
              merchant: 'Cửa hàng tiện lợi 24h FamilyMart Chi Nhánh Đường Cách Mạng Tháng 8 Quận 3',
              amount: 2500000,
              date: DateTime.now(),
              category: ExpenseCategory.gear,
              onTap: () {},
            ),
          ),
        ),
      );

      // Không phát sinh ngoại lệ RenderFlex overflow
      expect(tester.takeException(), isNull);
    });
  });
}
