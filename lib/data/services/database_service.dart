import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../domain/models/expense.dart';
import '../models/expense_record.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Database? _database;
  final List<Expense> _webInMemoryDb = [
    Expense(
      id: 1,
      merchant: 'Siêu thị Co.opmart Cống Quỳnh',
      amount: 340000,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      category: ExpenseCategory.food,
      note: 'Mua thực phẩm liên hoan nhóm',
    ),
    Expense(
      id: 2,
      merchant: 'Tiệm In Ấn & Photo Sinh Viên',
      amount: 85000,
      date: DateTime.now().subtract(const Duration(hours: 4)),
      category: ExpenseCategory.study,
      note: 'In tài liệu thảo luận CLB',
    ),
    Expense(
      id: 3,
      merchant: 'Nhà Sách Fahasa Nguyễn Huệ',
      amount: 215000,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: ExpenseCategory.study,
      note: 'Mua sổ tay và bút dạ quang',
    ),
    Expense(
      id: 4,
      merchant: 'GrabCar Di chuyển Sân Bay',
      amount: 150000,
      date: DateTime.now().subtract(const Duration(days: 2)),
      category: ExpenseCategory.travel,
      note: 'Đón diễn giả sự kiện',
    ),
    Expense(
      id: 5,
      merchant: 'Cửa hàng Thiết Bị Âm Thanh & Dây Cáp',
      amount: 450000,
      date: DateTime.now().subtract(const Duration(days: 3)),
      category: ExpenseCategory.gear,
      note: 'Mua cáp HDMI và micro CLB',
    ),
    Expense(
      id: 6,
      merchant: 'Rạp Chiếu Phim CGV Vincom',
      amount: 280000,
      date: DateTime.now().subtract(const Duration(days: 4)),
      category: ExpenseCategory.entertainment,
      note: 'Team building ban truyền thông',
    ),
    Expense(
      id: 7,
      merchant: 'Highlands Coffee Nguyễn Trãi',
      amount: 95000,
      date: DateTime.now().subtract(const Duration(days: 5)),
      category: ExpenseCategory.food,
      note: 'Họp ban chủ nhiệm',
    ),
    Expense(
      id: 8,
      merchant: 'Đổ xăng Petrolimex Số 15',
      amount: 110000,
      date: DateTime.now().subtract(const Duration(days: 6)),
      category: ExpenseCategory.travel,
      note: 'Tiền xăng khảo sát địa điểm',
    ),
  ];

  Future<Database?> get database async {
    if (kIsWeb) return null;
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'expenses_tracker.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE ${ExpenseRecord.tableName} (
            ${ExpenseRecord.columnId} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${ExpenseRecord.columnMerchant} TEXT NOT NULL,
            ${ExpenseRecord.columnAmount} REAL NOT NULL,
            ${ExpenseRecord.columnDate} TEXT NOT NULL,
            ${ExpenseRecord.columnCategory} TEXT NOT NULL,
            ${ExpenseRecord.columnRawOcrText} TEXT,
            ${ExpenseRecord.columnImagePath} TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertExpense(Expense expense) async {
    if (kIsWeb) {
      final newId = (_webInMemoryDb.isEmpty ? 0 : _webInMemoryDb.map((e) => e.id ?? 0).reduce((a, b) => a > b ? a : b)) + 1;
      _webInMemoryDb.insert(0, expense.copyWith(id: newId));
      return newId;
    }
    final db = (await database)!;
    return await db.insert(
      ExpenseRecord.tableName,
      ExpenseRecord.toMap(expense),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Expense>> getAllExpenses() async {
    if (kIsWeb) {
      return List.from(_webInMemoryDb);
    }
    final db = (await database)!;
    final List<Map<String, dynamic>> maps = await db.query(
      ExpenseRecord.tableName,
      orderBy: '${ExpenseRecord.columnDate} DESC',
    );
    return maps.map((map) => ExpenseRecord.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    if (kIsWeb) {
      final index = _webInMemoryDb.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _webInMemoryDb[index] = expense;
        return 1;
      }
      return 0;
    }
    final db = (await database)!;
    return await db.update(
      ExpenseRecord.tableName,
      ExpenseRecord.toMap(expense),
      where: '${ExpenseRecord.columnId} = ?',
      whereArgs: [expense.id],
    );
  }

  Future<int> deleteExpense(int id) async {
    if (kIsWeb) {
      _webInMemoryDb.removeWhere((e) => e.id == id);
      return 1;
    }
    final db = (await database)!;
    return await db.delete(
      ExpenseRecord.tableName,
      where: '${ExpenseRecord.columnId} = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
