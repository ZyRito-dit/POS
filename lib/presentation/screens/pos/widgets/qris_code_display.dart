import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pos_apps_umkm/presentation/widgets/pos_dialogs.dart';

/// Painter untuk menggambar 4 sudut bingkai scanner (corner brackets) tebal dan membulat
/// sesuai persis dengan referensi desain QRIS Kato POS.
class QrCornerFramePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  const QrCornerFramePainter({
    this.color = const Color(0xFF1E293B),
    this.strokeWidth = 5.5,
    this.cornerLength = 34.0,
    this.cornerRadius = 14.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;
    final r = cornerRadius;
    final l = cornerLength;

    // 1. Sudut Kiri Atas (Top-Left)
    final tlPath = Path()
      ..moveTo(0, l)
      ..lineTo(0, r)
      ..arcToPoint(Offset(r, 0), radius: Radius.circular(r))
      ..lineTo(l, 0);
    canvas.drawPath(tlPath, paint);

    // 2. Sudut Kanan Atas (Top-Right)
    final trPath = Path()
      ..moveTo(w - l, 0)
      ..lineTo(w - r, 0)
      ..arcToPoint(Offset(w, r), radius: Radius.circular(r))
      ..lineTo(w, l);
    canvas.drawPath(trPath, paint);

    // 3. Sudut Kiri Bawah (Bottom-Left)
    final blPath = Path()
      ..moveTo(0, h - l)
      ..lineTo(0, h - r)
      ..arcToPoint(Offset(r, h), radius: Radius.circular(r))
      ..lineTo(l, h);
    canvas.drawPath(blPath, paint);

    // 4. Sudut Kanan Bawah (Bottom-Right)
    final brPath = Path()
      ..moveTo(w - l, h)
      ..lineTo(w - r, h)
      ..arcToPoint(Offset(w, h - r), radius: Radius.circular(r))
      ..lineTo(w, h - l);
    canvas.drawPath(brPath, paint);
  }

  @override
  bool shouldRepaint(covariant QrCornerFramePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.cornerLength != cornerLength ||
      oldDelegate.cornerRadius != cornerRadius;
}

/// Widget Tampilan QR Code dengan bingkai scanner sudut responsif
class QrisCodeDisplay extends StatelessWidget {
  final String? qrData;
  final bool isLoading;
  final double size;
  final VoidCallback? onTap;

  const QrisCodeDisplay({
    super.key,
    required this.qrData,
    this.isLoading = false,
    this.size = 200.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: const QrCornerFramePainter(),
        child: Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(22.0),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF5247A1),
                  ),
                )
              : (qrData != null && qrData!.isNotEmpty)
                  ? QrImageView(
                      data: qrData!,
                      version: QrVersions.auto,
                      size: size - 44,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF1E293B),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF1E293B),
                      ),
                    )
                  : CustomPaint(
                      size: Size(size - 44, size - 44),
                      painter: const SimulatedQrPainter(seed: 42),
                    ),
        ),
      ),
    );
  }
}
