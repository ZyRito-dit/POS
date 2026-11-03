import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_apps_umkm/core/router/app_router.dart';
import 'package:pos_apps_umkm/core/theme/app_theme.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/screens/pos/widgets/thermal_receipt_preview_dialog.dart';

/// Shared product visual icon helper based on category ID.
IconData getCategoryIcon(int categoryId) {
  switch (categoryId) {
    case 1:
      return Icons.coffee_rounded;
    case 2:
      return Icons.local_cafe_outlined;
    case 3:
      return Icons.fastfood_outlined;
    case 4:
      return Icons.local_drink_outlined;
    default:
      return Icons.inventory_2_outlined;
  }
}

Color getCategoryColor(int categoryId) {
  switch (categoryId) {
    case 1:
      return const Color(0xFFD97706);
    case 2:
      return const Color(0xFF6D28D9);
    case 3:
      return const Color(0xFFDC2626);
    case 4:
      return const Color(0xFF16A34A);
    default:
      return const Color(0xFF6D28D9);
  }
}

/// Standard uniform placeholder when a product has no image or photo available.
class ProductNoImagePlaceholder extends StatelessWidget {
  final double iconSize;

  const ProductNoImagePlaceholder({
    super.key,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_outlined,
        size: iconSize,
        color: const Color(0xFF94A3B8),
      ),
    );
  }
}

/// Reusable online product image widget with loading indicator and standard fallback.
class ProductNetworkImage extends StatelessWidget {
  final PosProduct product;
  final double? width;
  final double? height;
  final double borderRadius;

  const ProductNetworkImage({
    super.key,
    required this.product,
    this.width,
    this.height,
    this.borderRadius = AppTheme.radiusMd,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = getCategoryColor(product.categoryId);
    final isOut = product.isOutOfStock;
    final hasImage = product.imageUrl.trim().isNotEmpty;
    final placeholderIconSize = (height != null && height! < 60) ? 22.0 : 34.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xFFF1F5F9),
        child: ColorFiltered(
          colorFilter: isOut
              ? const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.saturation,
                )
              : const ColorFilter.mode(
                  Colors.transparent,
                  BlendMode.multiply,
                ),
          child: hasImage
              ? Image.network(
                  product.imageUrl,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: catColor,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return ProductNoImagePlaceholder(
                      iconSize: placeholderIconSize,
                    );
                  },
                )
              : ProductNoImagePlaceholder(
                  iconSize: placeholderIconSize,
                ),
        ),
      ),
    );
  }
}

/// Navigates to the full-page Product Detail Screen (Bab 1.2 & 2.1 Buku Panduan).
void openProductDetailPage({
  required BuildContext context,
  required PosProduct product,
}) {
  context.push(AppRoutes.productDetail(product.id));
}

/// Navigates to the full-page Payment Screen (Bab 1.3 & 2.3 Buku Panduan).
void openPosPaymentPage({
  required BuildContext context,
  required WidgetRef ref,
}) {
  final cartItems = ref.read(cartProvider);
  if (cartItems.isEmpty) return;
  final method = ref.read(selectedPaymentMethodProvider);
  if (method == PaymentMethod.cash) {
    context.push(AppRoutes.paymentCash);
  } else {
    context.push(AppRoutes.paymentQris);
  }
}

/// Opens the POS Receipt Dialog for a transaction with the new 58mm thermal design.
Future<void> showSaleReceiptDialog(
  BuildContext context,
  SaleRecord sale, {
  bool showTotals = true,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => ThermalReceiptPreviewDialog(
      sale: sale,
      showTotals: showTotals,
    ),
  );
}

/// Deterministic QR Matrix painter for the QRIS checkout preview.
class SimulatedQrPainter extends CustomPainter {
  final int seed;

  const SimulatedQrPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    const gridCount = 21;
    final cellSize = size.width / gridCount;
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    void drawFinderPattern(int startX, int startY) {
      for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 7; x++) {
          final isBorder = x == 0 || x == 6 || y == 0 || y == 6;
          final isInner = x >= 2 && x <= 4 && y >= 2 && y <= 4;
          if (isBorder || isInner) {
            canvas.drawRect(
              Rect.fromLTWH(
                (startX + x) * cellSize,
                (startY + y) * cellSize,
                cellSize,
                cellSize,
              ),
              paint,
            );
          }
        }
      }
    }

    drawFinderPattern(0, 0);
    drawFinderPattern(gridCount - 7, 0);
    drawFinderPattern(0, gridCount - 7);

    for (var y = 0; y < gridCount; y++) {
      for (var x = 0; x < gridCount; x++) {
        final inTopLeft = x < 8 && y < 8;
        final inTopRight = x >= gridCount - 8 && y < 8;
        final inBottomLeft = x < 8 && y >= gridCount - 8;
        if (inTopLeft || inTopRight || inBottomLeft) continue;

        final hash = ((x * 37) ^ (y * 73) ^ seed) % 11;
        if (hash < 5 || (x == 6 || y == 6) && (x + y).isEven) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * cellSize,
              y * cellSize,
              cellSize * 0.95,
              cellSize * 0.95,
            ),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant SimulatedQrPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
