import 'package:flutter/material.dart';
import '../../../../domain/models/expense.dart';
import 'expense_summary_card.dart';

/// Xem trước widget ExpenseSummaryCard ở trạng thái bình thường
Widget previewExpenseSummaryCardStandard() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
    home: Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: ExpenseSummaryCard(
          merchant: 'Siêu thị Co.opmart Cống Quỳnh',
          amount: 250000,
          date: DateTime.now(),
          category: ExpenseCategory.food,
          onTap: () {},
        ),
      ),
    ),
  );
}

/// Xem trước widget ExpenseSummaryCard với tên cửa hàng rất dài (chống tràn layout)
Widget previewExpenseSummaryCardLongText() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepOrange),
    home: Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: ExpenseSummaryCard(
          merchant: 'Nhà Hàng Buffet Lẩu Nướng Hàn Quốc BBQ K-Pub Chi Nhánh Nguyễn Thị Minh Khai',
          amount: 1450000,
          date: DateTime.now().subtract(const Duration(days: 2)),
          category: ExpenseCategory.food,
          onTap: () {},
        ),
      ),
    ),
  );
}
