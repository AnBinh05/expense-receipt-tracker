import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/expense.dart';
import '../view_models/scan_view_model.dart';

class ScanReceiptScreen extends StatefulWidget {
  final ScanViewModel? viewModel;
  const ScanReceiptScreen({super.key, this.viewModel});

  @override
  State<ScanReceiptScreen> createState() => _ScanReceiptScreenState();
}

class _ScanReceiptScreenState extends State<ScanReceiptScreen> with SingleTickerProviderStateMixin {
  late final TextEditingController _merchantController;
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  late final AnimationController _scanLaserController;
  late final Animation<double> _laserAnimation;

  bool _isFlashOn = false;
  Offset? _focusTapPosition;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController();
    _amountController = TextEditingController();
    _noteController = TextEditingController();

    _scanLaserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnimation = CurvedAnimation(
      parent: _scanLaserController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _scanLaserController.dispose();
    super.dispose();
  }

  void _syncControllers(ScanViewModel vm) {
    if (_merchantController.text != vm.merchant) {
      _merchantController.text = vm.merchant;
    }
    final formattedAmount = vm.amount > 0 ? vm.amount.toStringAsFixed(0) : '';
    if (_amountController.text != formattedAmount) {
      _amountController.text = formattedAmount;
    }
  }

  void _triggerFocusTap(Offset localPos) {
    setState(() {
      _focusTapPosition = localPos;
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _focusTapPosition = null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => widget.viewModel ?? ScanViewModel(),
      child: Consumer<ScanViewModel>(
        builder: (context, vm, _) {
          _syncControllers(vm);
          final theme = Theme.of(context);

          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              title: const Text(
                'Quét Biên Lai & Hóa Đơn',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              actions: [
                // 1. Flash Toggle Button
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? Colors.amber : Colors.white70,
                  ),
                  tooltip: _isFlashOn ? 'Tắt đèn Flash' : 'Bật đèn Flash',
                  onPressed: () {
                    setState(() {
                      _isFlashOn = !_isFlashOn;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_isFlashOn ? 'Đã bật đèn Flash' : 'Đã tắt đèn Flash'),
                        duration: const Duration(milliseconds: 700),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                // Viewfinder / Chụp ảnh
                Column(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildCameraViewfinder(context, vm, theme),
                    ),
                    Expanded(
                      flex: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 16.0,
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: _buildReviewPanel(context, vm, theme),
                      ),
                    ),
                  ],
                ),

                // Hiệu ứng vòng tròn lấy nét (Focus Tap Indicator)
                if (_focusTapPosition != null)
                  Positioned(
                    left: _focusTapPosition!.dx - 32.0,
                    top: _focusTapPosition!.dy - 32.0,
                    child: IgnorePointer(
                      child: Container(
                        width: 64.0,
                        height: 64.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber, width: 2.0),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Khung ngắm máy ảnh kèm Crop Overlay và hiệu ứng Laser quét
  Widget _buildCameraViewfinder(BuildContext context, ScanViewModel vm, ThemeData theme) {
    return GestureDetector(
      onTapUp: (details) => _triggerFocusTap(details.localPosition),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Nền hiển thị ảnh đã chụp hoặc giả lập camera
          if (vm.imagePath != null && !kIsWeb && File(vm.imagePath!).existsSync())
            Positioned.fill(
              child: Image.file(
                File(vm.imagePath!),
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              color: const Color(0xFF121212),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.document_scanner,
                      size: 64.0,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      'Căn chỉnh hóa đơn vào khung quét',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Lớp tối mờ xung quanh khung crop
          Positioned.fill(
            child: CustomPaint(
              painter: _ViewfinderOverlayPainter(),
            ),
          ),

          // Khung crop chữ nhật với 4 góc định vị
          Center(
            child: Container(
              width: 280.0,
              height: 220.0,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.0),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Stack(
                children: [
                  // 4 góc định vị màu Neon Teal
                  ..._buildCornerBrackets(),

                  // Tia laser quét lên xuống khi đang nhận dạng hoặc ở chế độ ngắm
                  AnimatedBuilder(
                    animation: _laserAnimation,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserAnimation.value * 210.0,
                        left: 8.0,
                        right: 8.0,
                        child: Container(
                          height: 2.5,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.transparent, Colors.tealAccent, Colors.transparent],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.tealAccent.withValues(alpha: 0.8),
                                blurRadius: 8.0,
                                spreadRadius: 1.0,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Nút điều khiển chụp ở phía dưới khung ngắm
          Positioned(
            bottom: 10.0,
            left: 12.0,
            right: 12.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                        backgroundColor: Colors.black45,
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      ),
                      icon: const Icon(Icons.photo_library_outlined, size: 18.0),
                      label: const Text('Thư viện'),
                      onPressed: () => vm.pickAndProcessReceipt(ImageSource.gallery),
                    ),
                    const SizedBox(width: 12.0),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
                      ),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Chụp biên lai', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => vm.pickAndProcessReceipt(ImageSource.camera),
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.tealAccent,
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                  ),
                  icon: const Icon(Icons.auto_fix_high, size: 16.0),
                  label: const Text(
                    'Quét hóa đơn mẫu (Demo)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => vm.processDemoReceipt(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCornerBrackets() {
    const size = 20.0;
    const thickness = 3.5;
    const color = Colors.tealAccent;

    return [
      // Top Left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
      // Top Right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
      // Bottom Left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
      // Bottom Right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: size,
          height: thickness,
          color: color,
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: size,
          color: color,
        ),
      ),
    ];
  }

  /// Bảng xác nhận và chỉnh sửa thông tin (Interactive Review Screen)
  Widget _buildReviewPanel(BuildContext context, ScanViewModel vm, ThemeData theme) {
    if (vm.status == ScanStatus.recognizing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14.0),
            Text(
              'On-Device ML Kit OCR (<100ms) đang quét...',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Xác nhận thông tin hóa đơn',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Text(
                'Offline OCR',
                style: TextStyle(color: Colors.green, fontSize: 11.0, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12.0),

        // Tên đơn vị / Cửa hàng
        TextField(
          controller: _merchantController,
          decoration: const InputDecoration(
            labelText: 'Tên cửa hàng / Đơn vị',
            prefixIcon: Icon(Icons.storefront_rounded),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          ),
          onChanged: (val) => vm.updateMerchant(val),
        ),
        const SizedBox(height: 10.0),

        Row(
          children: [
            // Số tiền
            Expanded(
              flex: 5,
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Số tiền',
                  suffixText: 'đ',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val) ?? 0.0;
                  vm.updateAmount(parsed);
                },
              ),
            ),
            const SizedBox(width: 10.0),

            // Chọn danh mục
            Expanded(
              flex: 5,
              child: DropdownButtonFormField<ExpenseCategory>(
                isExpanded: true,
                initialValue: vm.category,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
                ),
                items: ExpenseCategory.values.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cat.icon, color: cat.color, size: 16.0),
                        const SizedBox(width: 6.0),
                        Flexible(
                          child: Text(
                            cat.displayName,
                            style: const TextStyle(fontSize: 13.0),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (cat) {
                  if (cat != null) vm.updateCategory(cat);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10.0),

        // Ngày giao dịch
        Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8.0),
            ),
            leading: const Icon(Icons.calendar_today, size: 18.0),
            title: Text(
              'Ngày: ${DateFormat('dd/MM/yyyy').format(vm.date)}',
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.edit_calendar, size: 18.0),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: vm.date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) vm.updateDate(picked);
            },
          ),
        ),
        const SizedBox(height: 14.0),

        // Nút Lưu vào SQLite
        FilledButton.icon(
          icon: const Icon(Icons.save_rounded),
          label: const Text('Lưu vào CSDL Thủ Quỹ CLB', style: TextStyle(fontWeight: FontWeight.bold)),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
          onPressed: () async {
            final saved = await vm.saveExpense();
            if (saved != null && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã lưu giao dịch vào CSDL SQLite thành công!')),
              );
              Navigator.pop(context, saved);
            }
          },
        ),
      ],
    );
  }
}

class _ViewfinderOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const cutoutWidth = 280.0;
    const cutoutHeight = 220.0;
    final cutoutLeft = (size.width - cutoutWidth) / 2;
    final cutoutTop = (size.height - cutoutHeight) / 2;

    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha: 0.65);

    // Vẽ vùng tối có khoét lỗ hình chữ nhật ở giữa
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(cutoutLeft, cutoutTop, cutoutWidth, cutoutHeight),
        const Radius.circular(16.0),
      ))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
