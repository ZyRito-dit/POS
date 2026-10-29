import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pos_apps_umkm/core/router/app_router.dart';
import 'package:pos_apps_umkm/core/theme/app_theme.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/widgets/pos_dialogs.dart';

/// Full-page Product Detail Screen (Bab 1.2 & 2.1 Buku Panduan Pengguna Nexsell).
/// Replaces popup modal with a dedicated responsive page for Mobile (HP) and Tablet.
class ProductDetailScreen extends ConsumerStatefulWidget {
  final int productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;
  bool _initialized = false;

  void _initQtyIfNeeded(PosProduct product) {
    if (_initialized) return;
    _initialized = true;
    final existing = ref
        .read(cartProvider)
        .where((i) => i.product.id == product.id)
        .firstOrNull;
    _qty = existing?.qty ?? (product.stock > 0 ? 1 : 0);
  }

  void _decrement() {
    if (_qty > 1) {
      setState(() => _qty--);
    }
  }

  void _increment(int maxStock) {
    if (_qty < maxStock) {
      setState(() => _qty++);
    }
  }

  void _addToCart(PosProduct product) {
    ref.read(cartProvider.notifier).setExactQuantity(product, _qty);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _buyNow(PosProduct product) {
    ref.read(cartProvider.notifier).setExactQuantity(product, _qty);
    context.pushReplacement(AppRoutes.payment);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final products = ref.watch(posProductsProvider);
    final product = products
        .where((p) => p.id == widget.productId)
        .firstOrNull;

    if (product == null) {
      return Scaffold(
        backgroundColor: c.canvas,
        appBar: AppBar(
          title: const Text('Detail Produk'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 48, color: c.textMuted),
              const SizedBox(height: AppTheme.space12),
              Text(
                'Produk tidak ditemukan',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppTheme.space16),
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      );
    }

    _initQtyIfNeeded(product);
    final isWide = MediaQuery.sizeOf(context).width >= 768;
    final cartCount = ref.watch(cartTotalItemsProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        backgroundColor: c.surface1,
        leading: IconButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
          icon: Icon(Icons.arrow_back_rounded, color: c.textPrimary),
          tooltip: 'Kembali ke Katalog',
        ),
        title: Text(
          'Detail Produk',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Theme switcher button
          IconButton(
            onPressed: () {
              final current = ref.read(themeModeProvider);
              ref.read(themeModeProvider.notifier).state =
                  current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
            },
            tooltip: context.isDarkMode ? 'Mode Putih' : 'Mode Gelap',
            icon: Icon(
              context.isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              color: c.textSecondary,
            ),
          ),
          if (cartCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppTheme.space12),
              child: IconButton(
                onPressed: () => context.push(AppRoutes.payment),
                tooltip: 'Lanjut ke Pembayaran',
                icon: Badge(
                  label: Text('$cartCount'),
                  backgroundColor: c.accent,
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: c.border),
        ),
      ),
      body: SafeArea(
        child: isWide
            ? Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.space24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.space24),
                      decoration: BoxDecoration(
                        color: c.surface1,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXl),
                        border: Border.all(color: c.border),
                        boxShadow: [
                          if (!context.isDarkMode)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Column: Large Product Image
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AspectRatio(
                                  aspectRatio: 1.05,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: c.surface2,
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusLg,
                                      ),
                                      border: Border.all(color: c.border),
                                    ),
                                    child: ProductNetworkImage(
                                      product: product,
                                      borderRadius: AppTheme.radiusLg,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppTheme.space16),
                                Wrap(
                                  spacing: AppTheme.space8,
                                  runSpacing: AppTheme.space8,
                                  children: [
                                    _MetaPill(
                                      icon: Icons.qr_code_rounded,
                                      label: 'SKU: ${product.sku}',
                                    ),
                                    _MetaPill(
                                      icon: Icons.category_outlined,
                                      label: product.categoryName,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppTheme.space32),

                          // Right Column: Product Info & Purchase Controls
                          Expanded(
                            flex: 6,
                            child: _ProductInfoSection(
                              product: product,
                              qty: _qty,
                              onDecrement: _decrement,
                              onIncrement: () => _increment(product.stock),
                              onAddToCart: () => _addToCart(product),
                              onBuyNow: () => _buyNow(product),
                              showInlineButtons: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.space16),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.space16),
                        decoration: BoxDecoration(
                          color: c.surface1,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg),
                          border: Border.all(color: c.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Component 1: Gambar Produk
                            SizedBox(
                              height: 220,
                              child: ProductNetworkImage(
                                product: product,
                                width: double.infinity,
                                height: 220,
                                borderRadius: AppTheme.radiusMd,
                              ),
                            ),
                            const SizedBox(height: AppTheme.space16),
                            Wrap(
                              spacing: AppTheme.space8,
                              runSpacing: AppTheme.space8,
                              children: [
                                _MetaPill(
                                  icon: Icons.qr_code_rounded,
                                  label: 'SKU: ${product.sku}',
                                ),
                                _MetaPill(
                                  icon: Icons.category_outlined,
                                  label: product.categoryName,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.space16),
                            _ProductInfoSection(
                              product: product,
                              qty: _qty,
                              onDecrement: _decrement,
                              onIncrement: () => _increment(product.stock),
                              onAddToCart: () => _addToCart(product),
                              onBuyNow: () => _buyNow(product),
                              showInlineButtons: false,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Sticky Mobile Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space16,
                      vertical: AppTheme.space12,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface1,
                      border: Border(top: BorderSide(color: c.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: product.isOutOfStock
                                ? null
                                : () => _addToCart(product),
                            icon: const Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 18,
                            ),
                            label: const Text('Tambah ke Keranjang'),
                          ),
                        ),
                        const SizedBox(width: AppTheme.space12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: product.isOutOfStock
                                ? null
                                : () => _buyNow(product),
                            child: const Text('Beli Sekarang'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInfoSection extends StatelessWidget {
  final PosProduct product;
  final int qty;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onAddToCart;
  final VoidCallback onBuyNow;
  final bool showInlineButtons;

  const _ProductInfoSection({
    required this.product,
    required this.qty,
    required this.onDecrement,
    required this.onIncrement,
    required this.onAddToCart,
    required this.onBuyNow,
    required this.showInlineButtons,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Component 2, 3, 4: Nama Produk, Harga Produk, Sisa Stok
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: AppTheme.space12,
          runSpacing: AppTheme.space8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTheme.space4),
                Text(
                  AppFormatters.formatRupiah(product.basePrice),
                  style: TextStyle(
                    color: c.accent,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.space12,
                vertical: AppTheme.space8,
              ),
              decoration: BoxDecoration(
                color: product.isOutOfStock
                    ? c.errorSoft
                    : (product.isLowStock ? c.warningSoft : c.accentSoft),
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: Text(
                product.isOutOfStock
                    ? 'Stok Habis (0)'
                    : 'Sisa stok: ${product.stock}',
                style: TextStyle(
                  color: product.isOutOfStock
                      ? c.error
                      : (product.isLowStock ? c.warning : c.accent),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space16),

        // Component 5: Deskripsi Produk & Spesifikasi Kemasan (Gambar 1.2 Buku Panduan)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space16,
            vertical: AppTheme.space12,
          ),
          decoration: BoxDecoration(
            color: c.accentSoft,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: c.accent.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            product.packagingInfo,
            style: TextStyle(
              color: c.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: AppTheme.space12),
        Text(
          product.description,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: AppTheme.space20),
        Divider(height: 1, color: c.border),
        const SizedBox(height: AppTheme.space20),

        // Component 6, 7, 8: Jumlah Pembelian, Tombol (-), Tombol (+)
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppTheme.space16,
          runSpacing: AppTheme.space12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jumlah',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Maksimal pembelian ${product.stock} item',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: c.surface2,
                borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                border: Border.all(color: c.borderStrong),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _CircleStepButton(
                    icon: Icons.remove_rounded,
                    onPressed: qty > 1 ? onDecrement : null,
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 52),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.space12,
                    ),
                    child: Text(
                      '$qty',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  _CircleStepButton(
                    icon: Icons.add_rounded,
                    onPressed: qty < product.stock ? onIncrement : null,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.space20),

        // Subtotal Preview Card
        Container(
          padding: const EdgeInsets.all(AppTheme.space16),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(color: c.border),
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space4,
            children: [
              Text(
                'Total Harga ($qty item)',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                AppFormatters.formatRupiah(product.basePrice * qty),
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),

        if (showInlineButtons) ...[
          const SizedBox(height: AppTheme.space24),
          // Component 9: Tombol Ke Keranjang & Beli Sekarang
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: product.isOutOfStock ? null : onAddToCart,
                    icon: const Icon(
                      Icons.add_shopping_cart_rounded,
                      size: 19,
                    ),
                    label: const Text('Tambah ke Keranjang'),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: product.isOutOfStock ? null : onBuyNow,
                    child: const Text('Beli Sekarang'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CircleStepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _CircleStepButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onPressed != null;

    return Material(
      color: enabled ? c.accent : c.surfaceHover,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            icon,
            size: 20,
            color: enabled ? Colors.white : c.textMuted,
          ),
        ),
      ),
    );
  }
}
