import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:expense_receipt_tracker/data/repositories/expense_repository.dart';
import 'package:expense_receipt_tracker/domain/models/expense.dart';
import 'package:expense_receipt_tracker/ui/features/expenses/view_models/expense_view_model.dart';
import 'package:expense_receipt_tracker/ui/features/expenses/views/expense_list_screen.dart';
import 'package:expense_receipt_tracker/ui/features/scan/view_models/scan_view_model.dart';
import 'package:expense_receipt_tracker/ui/features/scan/views/scan_receipt_screen.dart';

class InMemoryExpenseRepository implements IExpenseRepository {
  final List<Expense> _list = [
    Expense(
      id: 1,
      merchant: 'Tiệm Bánh Mì Sài Gòn',
      amount: 35000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: ExpenseCategory.food,
      note: 'Ăn sáng trước khi đi làm',
    ),
    Expense(
      id: 2,
      merchant: 'GrabCar Di chuyển',
      amount: 75000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: ExpenseCategory.travel,
      note: 'Đi họp nhóm CLB',
    ),
  ];

  @override
  Future<List<Expense>> getAllExpenses() async => List.from(_list);

  @override
  Future<int> addExpense(Expense expense) async {
    final nextId = _list.length + 1;
    final saved = expense.copyWith(id: nextId);
    _list.insert(0, saved);
    return nextId;
  }

  @override
  Future<int> updateExpense(Expense expense) async => 1;

  @override
  Future<int> deleteExpense(int id) async {
    _list.removeWhere((e) => e.id == id);
    return 1;
  }
}

void main() {
  group('E2E Flow Test: Quét Hóa Đơn & Thống Kê Biểu Đồ', () {
    testWidgets('Kiểm thử toàn bộ luồng Quét hóa đơn OCR -> Trích xuất Regex -> Lưu CSDL -> Cập nhật Biểu đồ',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeRepo = InMemoryExpenseRepository();
      final expenseVm = ExpenseViewModel(repository: fakeRepo);
      final scanVm = ScanViewModel(repository: fakeRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ExpenseViewModel>.value(value: expenseVm),
          ],
          child: MaterialApp(
            home: const ExpenseListScreen(),
          ),
        ),
      );

      // Chờ nạp dữ liệu ban đầu
      await tester.pumpAndSettle();

      // 1. Kiểm tra màn hình chính hiển thị danh sách ban đầu
      expect(find.text('Expense Tracker'), findsOneWidget);
      expect(find.text('Tiệm Bánh Mì Sài Gòn'), findsOneWidget);
      expect(find.text('GrabCar Di chuyển'), findsOneWidget);
      expect(find.text('2 hóa đơn'), findsOneWidget);

      // 2. Mở màn hình Quét Hóa Đơn
      final nav = tester.state<NavigatorState>(find.byType(Navigator));
      nav.push(MaterialPageRoute(
        builder: (_) => ScanReceiptScreen(viewModel: scanVm),
      ));
      // Dùng pump với khoảng thời gian vì ScanReceiptScreen có laser animation lặp vô tận
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Kiểm tra các thành phần của giao diện máy ảnh
      expect(find.text('Quét Biên Lai & Hóa Đơn'), findsOneWidget);
      expect(find.text('Căn chỉnh hóa đơn vào khung quét'), findsOneWidget);
      expect(find.text('Thư viện'), findsOneWidget);
      expect(find.text('Chụp biên lai'), findsWidgets);
      expect(find.text('Quét hóa đơn mẫu (Demo)'), findsOneWidget);

      // 3. Test nút bật/tắt đèn Flash
      await tester.tap(find.byTooltip('Bật đèn Flash'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Đã bật đèn Flash'), findsWidgets);

      // 4. Kích hoạt quét nhận dạng OCR bằng nút "Quét hóa đơn mẫu (Demo)"
      await tester.tap(find.text('Quét hóa đơn mẫu (Demo)'));
      await tester.pump();
      // Chờ quá trình nhận diện và bóc tách regex hoàn tất
      await tester.pump(const Duration(milliseconds: 800));

      // 5. Kiểm tra thông tin đã được trích xuất tự động qua Regex
      expect(find.textContaining('SIEU THI CO.OPMART CONG QUYNH'), findsOneWidget);
      expect(find.text('122000'), findsOneWidget);
      expect(find.text('Offline OCR'), findsOneWidget);

      // 6. Cuộn và bấm nút "Lưu vào CSDL Thủ Quỹ CLB"
      final saveBtn = find.text('Lưu vào CSDL Thủ Quỹ CLB');
      await tester.ensureVisible(saveBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(saveBtn);

      // Bơm khung hình để đóng màn hình quét
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // 7. Cập nhật lại view model danh sách chi tiêu sau khi lưu
      await expenseVm.loadExpenses();
      await tester.pumpAndSettle();

      // Kiểm tra hóa đơn mới đã xuất hiện trong danh sách chính
      expect(find.text('SIEU THI CO.OPMART CONG QUYNH'), findsOneWidget);
      expect(find.textContaining('122.000'), findsOneWidget);
      expect(find.text('3 hóa đơn'), findsOneWidget);

      // 8. Chạm vào hóa đơn mới để kiểm tra BottomSheet chi tiết & văn bản OCR
      await tester.tap(find.text('SIEU THI CO.OPMART CONG QUYNH'));
      await tester.pumpAndSettle();

      expect(find.text('Văn bản OCR trích xuất được:'), findsOneWidget);
      expect(find.textContaining('Sua tuoi Vinamilk'), findsOneWidget);

      // Đóng BottomSheet
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // 9. Chuyển sang Tab "Thống Kê Biểu Đồ"
      await tester.tap(find.text('Thống Kê Biểu Đồ'));
      await tester.pumpAndSettle();

      // Kiểm tra Biểu đồ CustomPainter vẽ lên canvas
      expect(find.byType(CustomPaint), findsWidgets);
      // Kiểm tra tổng ngân quỹ được cộng dồn (35.000 + 75.000 + 122.000 = 232.000 đ)
      expect(find.textContaining('232.000'), findsWidgets);
      expect(find.text('Tổng ngân quỹ'), findsOneWidget);
    });
  });
}
