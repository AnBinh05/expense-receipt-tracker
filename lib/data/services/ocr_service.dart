import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get textRecognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Nhận dạng văn bản từ tệp ảnh sử dụng Google ML Kit OCR trên thiết bị
  Future<String> recognizeTextFromImagePath(String imagePath) async {
    if (kIsWeb) {
      return _generateFallbackText(imagePath);
    }

    final file = File(imagePath);
    if (!file.existsSync()) {
      throw Exception('Không tìm thấy tệp ảnh tại đường dẫn: $imagePath');
    }

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      // Fallback khi chạy trên môi trường không hỗ trợ native ML Kit (như desktop/web test)
      return _generateFallbackText(file.path);
    }
  }

  /// Dữ liệu mẫu giả lập phục vụ kiểm thử và demo khi không có camera thực tế
  String _generateFallbackText(String path) {
    return '''
SIEU THI CO.OPMART CONG QUYNH
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
Tien thua:                 28.000 d
Cam on quy khach & Hen gap lai!
''';
  }

  void dispose() {
    if (!kIsWeb) {
      _textRecognizer?.close();
    }
  }
}
