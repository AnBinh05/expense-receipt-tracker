import '../models/expense.dart';

class ParsedReceiptResult {
  final String merchant;
  final double amount;
  final DateTime date;
  final ExpenseCategory category;
  final String rawText;

  const ParsedReceiptResult({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    required this.rawText,
  });

  Expense toExpense({String? imagePath, String? note}) {
    return Expense(
      merchant: merchant,
      amount: amount,
      date: date,
      category: category,
      rawOcrText: rawText,
      imagePath: imagePath,
      note: note,
    );
  }
}

class ReceiptRegexParser {
  /// Hàm chính phân tích toàn bộ văn bản OCR với heuristic logic
  static ParsedReceiptResult parse(String ocrText) {
    final merchant = extractMerchant(ocrText);
    final amount = extractTotal(ocrText) ?? 0.0;
    final date = extractDate(ocrText) ?? DateTime.now();
    final category = inferCategory(merchant, ocrText);

    return ParsedReceiptResult(
      merchant: merchant,
      amount: amount,
      date: date,
      category: category,
      rawText: ocrText,
    );
  }

  /// Trích xuất tổng tiền từ văn bản (Hỗ trợ 150,000 VND, 150.000 đ, 150000...)
  static double? extractTotal(String text) {
    final lines = text.split('\n');

    // 1. Từ khóa ưu tiên của hóa đơn Việt Nam & quốc tế
    final totalKeywords = [
      RegExp(r'(?:t[ổo]ng\s*c[ộo]ng|t[ổo]ng\s*ti[ềe]n|t[ổo]ng\s*tt|thanh\s*to[áa]n|th[àa]nh\s*ti[ềe]n)', caseSensitive: false),
      RegExp(r'(?:total\s*due|grand\s*total|total\s*amount|total|amount|vnd|vnđ)', caseSensitive: false),
    ];

    // Mẫu regex số tiền (hỗ trợ dấu chấm, phẩy, kèm đ, VND, vnđ)
    final moneyPattern = RegExp(r'(\d{1,3}(?:[.,]\d{3})+(?:[.,]\d{2})?|\d{4,})\s*(?:đ|d|vnd|vnđ)?', caseSensitive: false);

    for (final line in lines) {
      for (final keyword in totalKeywords) {
        if (keyword.hasMatch(line)) {
          final matches = moneyPattern.allMatches(line);
          if (matches.isNotEmpty) {
            final rawNum = matches.last.group(1)!;
            final clean = _normalizeNumber(rawNum);
            final val = double.tryParse(clean);
            if (val != null && val > 0) return val;
          }
        }
      }
    }

    // 2. Fallback heuristic: Quét toàn bộ dòng và lấy số tiền lớn nhất hợp lý
    double maxAmount = 0.0;
    for (final line in lines) {
      // Tránh các dòng chứa mã số thuế, số điện thoại, ngày giờ
      if (RegExp(r'(mst|tel|phone|ng[àa]y|date|h[đd]|s[ốo]\s*h[đd])', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      final matches = moneyPattern.allMatches(line);
      for (final match in matches) {
        final val = double.tryParse(_normalizeNumber(match.group(1)!));
        if (val != null && val > maxAmount && val < 500000000) {
          maxAmount = val;
        }
      }
    }

    return maxAmount > 0 ? maxAmount : null;
  }

  /// Trích xuất ngày tháng giao dịch (DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD)
  static DateTime? extractDate(String text) {
    final datePatterns = [
      RegExp(r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\b'),
      RegExp(r'\b(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})\b'),
      RegExp(r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{2})\b'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (match.group(1)!.length == 4) {
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            if (_isValidDate(year, month, day)) return DateTime(year, month, day);
          } else {
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            var year = int.parse(match.group(3)!);
            if (year < 100) year += 2000;
            if (_isValidDate(year, month, day)) return DateTime(year, month, day);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// Trích xuất tên cửa hàng / đơn vị phát hành
  static String extractMerchant(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length > 2)
        .toList();

    if (lines.isEmpty) return 'Biên lai học sinh / CLB';

    final ignoreKeywords = RegExp(
      r'^(phiếu\s*thanh\s*toán|hóa\s*đơn|receipt|invoice|bill|đơn\s*hàng|phiếu\s*tính\s*tiền|welcome|cộng\s*hòa)',
      caseSensitive: false,
    );

    for (int i = 0; i < lines.length && i < 4; i++) {
      final line = lines[i];
      if (!ignoreKeywords.hasMatch(line) && !RegExp(r'^\d+$').hasMatch(line)) {
        return _cleanMerchantName(line);
      }
    }

    return _cleanMerchantName(lines.first);
  }

  /// Heuristic phân loại danh mục: Food, Study, Travel, Gear, Entertainment
  static ExpenseCategory inferCategory(String merchant, String fullText) {
    final combined = '$merchant $fullText'.toLowerCase();

    // 1. Học tập (Study): sách, in ấn, photo, tài liệu, giáo trình, văn phòng phẩm, fahasa, tiki
    if (RegExp(r'(photo|in\s*ấn|tài\s*liệu|giáo\s*trình|sách|vở|bút|fahasa|nhà\s*sách|văn\s*phòng\s*phẩm|study|học\s*phí|khóa\s*học|tiki)').hasMatch(combined)) {
      return ExpenseCategory.study;
    }

    // 2. Thiết bị / Đồ dùng CLB (Gear): linh kiện, dây cáp, loa, mic, phích cắm, công cụ, dụng cụ
    if (RegExp(r'(thiết\s*bị|dụng\s*cụ|linh\s*kiện|gear|cable|cáp|loa|mic|pin|bóng\s*đèn|dây\s*điện|ổ\s*cắm|vật\s*tư|phần\s*cứng)').hasMatch(combined)) {
      return ExpenseCategory.gear;
    }

    // 3. Đi lại (Travel): xe bus, vé xe, gửi xe, xăng, grab, be, taxi, petrolimex
    if (RegExp(r'(xe\s*buýt|bus|vé\s*xe|gửi\s*xe|giữ\s*xe|grab|be|gojek|taxi|xăng|petro|pv\s*oil|transit|travel)').hasMatch(combined)) {
      return ExpenseCategory.travel;
    }

    // 4. Ăn uống (Food): canteen, cơm, phở, bún, bánh mì, trà sữa, cafe, highlands, siêu thị mua thực phẩm
    if (RegExp(r'(canteen|cơm|phở|bún|bánh|trà\s*sữa|cà\s*phê|cafe|coffee|coopmart|co\.opmart|vinmart|winmart|siêu\s*thị|food|quán|nhà\s*hàng|highlands|circle\s*k|7-eleven|family\s*mart)').hasMatch(combined)) {
      return ExpenseCategory.food;
    }

    // 5. Giải trí / Hoạt động CLB (Entertainment): xem phim, cgv, liên hoan, karaoke, sự kiện, team building
    if (RegExp(r'(cgv|lotte\s*cinema|rạp|xem\s*phim|liên\s*hoan|karaoke|bida|sự\s*kiện|event|team\s*building|party|tiệc)').hasMatch(combined)) {
      return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.food;
  }

  static String _normalizeNumber(String raw) {
    if (RegExp(r'^\d{1,3}([.,]\d{3})+$').hasMatch(raw)) {
      return raw.replaceAll('.', '').replaceAll(',', '');
    }
    if (raw.contains('.') && raw.contains(',')) {
      return raw.replaceAll('.', '').replaceAll(',', '.');
    }
    return raw.replaceAll(',', '');
  }

  static bool _isValidDate(int year, int month, int day) {
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (year < 2000 || year > 2100) return false;
    return true;
  }

  static String _cleanMerchantName(String raw) {
    return raw.replaceAll(RegExp(r'^[-#*_=]+\s*'), '').trim();
  }
}
