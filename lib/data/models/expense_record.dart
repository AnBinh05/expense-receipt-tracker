import '../../domain/models/expense.dart';

class ExpenseRecord {
  static const String tableName = 'expenses';
  static const String columnId = 'id';
  static const String columnMerchant = 'merchant';
  static const String columnAmount = 'amount';
  static const String columnDate = 'date';
  static const String columnCategory = 'category';
  static const String columnRawOcrText = 'raw_ocr_text';
  static const String columnImagePath = 'image_path';

  static Map<String, dynamic> toMap(Expense expense) {
    return {
      if (expense.id != null) columnId: expense.id,
      columnMerchant: expense.merchant,
      columnAmount: expense.amount,
      columnDate: expense.date.toIso8601String(),
      columnCategory: expense.category.name,
      columnRawOcrText: expense.rawOcrText,
      columnImagePath: expense.imagePath,
    };
  }

  static Expense fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map[columnId] as int?,
      merchant: map[columnMerchant] as String? ?? 'Chưa rõ',
      amount: (map[columnAmount] as num?)?.toDouble() ?? 0.0,
      date: map[columnDate] != null
          ? DateTime.tryParse(map[columnDate] as String) ?? DateTime.now()
          : DateTime.now(),
      category: ExpenseCategory.fromString(map[columnCategory] as String?),
      rawOcrText: map[columnRawOcrText] as String?,
      imagePath: map[columnImagePath] as String?,
    );
  }
}
