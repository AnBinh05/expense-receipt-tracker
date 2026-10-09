import 'package:flutter_test/flutter_test.dart';
import 'package:expense_receipt_tracker/domain/models/expense.dart';
import 'package:expense_receipt_tracker/domain/services/receipt_regex_parser.dart';

void main() {
  group('ReceiptRegexParser Unit Tests', () {
    test('1. Bóc tách hóa đơn siêu thị Co.opmart thành công', () {
      const sampleOcr = '''
SIEU THI CO.OPMART CONG QUYNH
189C Cong Quynh, Q.1
Ngay: 08/10/2026
1. Banh mi sandwich   25.000
2. Sua Vinamilk       32.000
-----------------------------
Tong cong:           122.000 d
Thanh toan tien mat: 122.000
Cam on quy khach!
''';

      final result = ReceiptRegexParser.parse(sampleOcr);

      expect(result.merchant, contains('CO.OPMART'));
      expect(result.amount, equals(122000.0));
      expect(result.date.day, equals(8));
      expect(result.date.month, equals(10));
      expect(result.date.year, equals(2026));
      expect(result.category, equals(ExpenseCategory.food));
    });

    test('2. Bóc tách hóa đơn Highlands Coffee thành công', () {
      const sampleOcr = '''
HIGHLANDS COFFEE NGUYEN TRAI
HD: 009281
Time: 15/09/2026 09:30
1x Phin Sua Da (L)     39.000
1x Tra Sen Vang (M)    55.000
-----------------------------
Tong tien:             94.000
Chuyen khoan VNPay:    94.000
''';

      final result = ReceiptRegexParser.parse(sampleOcr);

      expect(result.merchant, contains('HIGHLANDS COFFEE'));
      expect(result.amount, equals(94000.0));
      expect(result.date.day, equals(15));
      expect(result.date.month, equals(9));
      expect(result.date.year, equals(2026));
      expect(result.category, equals(ExpenseCategory.food));
    });

    test('3. Bóc tách chuyến đi Grab Car (Di chuyển)', () {
      const sampleOcr = '''
GRAB VIETNAM RECEIPT
Chuyen di GrabCar
Ngay: 01/10/2026
Cuoc phi:              68.000 d
Total Due:             68.000 d
''';

      final result = ReceiptRegexParser.parse(sampleOcr);

      expect(result.merchant, contains('GRAB VIETNAM'));
      expect(result.amount, equals(68000.0));
      expect(result.category, equals(ExpenseCategory.travel));
    });

    test('4. Xử lý an toàn khi văn bản rỗng hoặc không có số tiền', () {
      const emptyOcr = 'To giay trang khong ro chu';
      final result = ReceiptRegexParser.parse(emptyOcr);

      expect(result.amount, equals(0.0));
      expect(result.merchant, isNotEmpty);
    });
  });
}
