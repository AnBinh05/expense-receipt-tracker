import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../data/repositories/expense_repository.dart';
import '../../../../data/services/ocr_service.dart';
import '../../../../domain/models/expense.dart';
import '../../../../domain/services/receipt_regex_parser.dart';

enum ScanStatus { idle, capturing, recognizing, parsed, saving, success, error }

class ScanViewModel extends ChangeNotifier {
  final OcrService _ocrService;
  final IExpenseRepository _repository;
  final ImagePicker _picker;

  ScanViewModel({
    OcrService? ocrService,
    IExpenseRepository? repository,
    ImagePicker? picker,
  })  : _ocrService = ocrService ?? OcrService(),
        _repository = repository ?? ExpenseRepository(),
        _picker = picker ?? ImagePicker();

  ScanStatus _status = ScanStatus.idle;
  String? _errorMessage;
  String? _imagePath;
  String? _rawOcrText;

  String _merchant = '';
  double _amount = 0.0;
  DateTime _date = DateTime.now();
  ExpenseCategory _category = ExpenseCategory.food;

  ScanStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get imagePath => _imagePath;
  String? get rawOcrText => _rawOcrText;

  String get merchant => _merchant;
  double get amount => _amount;
  DateTime get date => _date;
  ExpenseCategory get category => _category;

  void updateMerchant(String value) {
    _merchant = value;
    notifyListeners();
  }

  void updateAmount(double value) {
    _amount = value;
    notifyListeners();
  }

  void updateDate(DateTime value) {
    _date = value;
    notifyListeners();
  }

  void updateCategory(ExpenseCategory value) {
    _category = value;
    notifyListeners();
  }

  /// Chụp ảnh từ camera hoặc chọn từ thư viện
  Future<void> pickAndProcessReceipt(ImageSource source) async {
    _errorMessage = null;
    _status = ScanStatus.capturing;
    notifyListeners();

    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (photo == null) {
        _status = ScanStatus.idle;
        notifyListeners();
        return;
      }

      _imagePath = photo.path;
      _status = ScanStatus.recognizing;
      notifyListeners();

      // Bước 2 trong Pipeline: ML Kit Text Recognition
      final text = await _ocrService.recognizeTextFromImagePath(_imagePath!);
      _rawOcrText = text;

      // Bước 3 trong Pipeline: Dart Regex Parser Engine
      final parsed = ReceiptRegexParser.parse(text);
      _merchant = parsed.merchant;
      _amount = parsed.amount;
      _date = parsed.date;
      _category = parsed.category;

      _status = ScanStatus.parsed;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi xử lý hóa đơn: $e';
      _status = ScanStatus.error;
      notifyListeners();
    }
  }

  /// Trình giả lập quét hóa đơn thông minh cho Web và kiểm thử tự động
  Future<void> processDemoReceipt([String sample = 'coopmart']) async {
    _errorMessage = null;
    _status = ScanStatus.recognizing;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));

    final text = sample == 'highlands'
        ? '''HIGHLANDS COFFEE NGUYEN TRAI
HD: 009281
Time: 09/10/2026 09:30
1x Phin Sua Da (L)     39.000
1x Tra Sen Vang (M)    55.000
-----------------------------
Tong tien:             94.000
Chuyen khoan VNPay:    94.000'''
        : '''SIEU THI CO.OPMART CONG QUYNH
189C Cong Quynh, P. Nguyen Cu Trinh, Q.1, TP.HCM
Ngay: 09/10/2026  14:35:20
Thu ngan: Nguyen Van A
---------------------------------
1. Sua tuoi Vinamilk 1L    32.000
2. Banh mi sandwich        25.000
3. Dau an Simply 1L        65.000
---------------------------------
Tong cong:                122.000 d
Thanh toan:               122.000 d
Tien mat:                 150.000 d
Cam on quy khach & Hen gap lai!''';

    _rawOcrText = text;
    final parsed = ReceiptRegexParser.parse(text);
    _merchant = parsed.merchant;
    _amount = parsed.amount;
    _date = parsed.date;
    _category = parsed.category;

    _status = ScanStatus.parsed;
    notifyListeners();
  }

  /// Bước 4 trong Pipeline: Lưu vào CSDL SQLite địa phương
  Future<Expense?> saveExpense() async {
    if (_merchant.trim().isEmpty) {
      _errorMessage = 'Vui lòng nhập tên cửa hàng';
      notifyListeners();
      return null;
    }

    _status = ScanStatus.saving;
    notifyListeners();

    try {
      String? cachedPath = _imagePath;
      if (!kIsWeb && _imagePath != null && File(_imagePath!).existsSync()) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final receiptsDir = Directory(p.join(appDir.path, 'receipts'));
          if (!await receiptsDir.exists()) {
            await receiptsDir.create(recursive: true);
          }
          final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(_imagePath!)}';
          final savedImage = await File(_imagePath!).copy(p.join(receiptsDir.path, fileName));
          cachedPath = savedImage.path;
        } catch (e) {
          debugPrint('Lỗi cache receipt thumbnail: $e');
        }
      }

      final expense = Expense(
        merchant: _merchant.trim(),
        amount: _amount,
        date: _date,
        category: _category,
        rawOcrText: _rawOcrText,
        imagePath: cachedPath,
      );

      final id = await _repository.addExpense(expense);
      _status = ScanStatus.success;
      notifyListeners();
      return expense.copyWith(id: id);
    } catch (e) {
      _errorMessage = 'Không thể lưu vào CSDL: $e';
      _status = ScanStatus.error;
      notifyListeners();
      return null;
    }
  }

  void reset() {
    _status = ScanStatus.idle;
    _errorMessage = null;
    _imagePath = null;
    _rawOcrText = null;
    _merchant = '';
    _amount = 0.0;
    _date = DateTime.now();
    _category = ExpenseCategory.food;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
