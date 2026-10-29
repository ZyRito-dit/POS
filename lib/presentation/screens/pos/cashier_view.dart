import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/core/theme/app_theme.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/data/dummy/pos_dummy_data.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/widgets/pos_dialogs.dart';

class CashierView extends ConsumerStatefulWidget {
  const CashierView({super.key});

  @override
  ConsumerState<CashierView> createState() => _CashierViewState();
}

class _CashierViewState extends ConsumerState<CashierView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _CatalogSection(searchController: _searchCtrl),
              ),
              Container(width: 1, color: c.border),
              const SizedBox(
                width: 360,
                child: _CartPanel(),
              ),
            ],
          );
        }

        return Column(
          children: [
            Expanded(
              child: _CatalogSection(searchController: _searchCtrl),
            ),
            const _MobileCartBar(),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Left/Main Pane: Katalog Produk (Bab 1.1 Halaman Produk)
// ---------------------------------------------------------------------------

class _CatalogSection extends ConsumerWidget {
  final TextEditingController searchController;

  const _CatalogSection({required this.searchController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final selectedCatId = ref.watch(selectedCategoryIdProvider);
    final products = ref.watch(filteredProductsProvider);
    final cartItems = ref.watch(cartProvider);

    // Pre-index cart quantities by product ID for O(1) lookup
    final qtyMap = <int, int>{
      for (final item in cartItems) item.product.id: item.qty,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 500;
        final pad = isCompact ? AppTheme.space12 : AppTheme.space20;

        return Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar
              TextField(
                controller: searchController,
                onChanged: (val) =>
                    ref.read(catalogSearchQueryProvider.notifier).state = val,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari nama produk atau SKU (mis. KPL-001)...',
                  fillColor: c.surface1,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: c.textMuted,
                    size: 20,
                  ),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            ref
                                .read(catalogSearchQueryProvider.notifier)
                                .state = '';
                          },
                          icon: Icon(
                            Icons.clear_rounded,
                            color: c.textMuted,
                            size: 18,
                          ),
                          tooltip: 'Hapus pencarian',
                        )
                      : null,
                ),
              ),
              const SizedBox(height: AppTheme.space12),

              // Category Filter Pills
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: PosDummyData.categories.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppTheme.space8),
                  itemBuilder: (context, index) {
                    final cat = PosDummyData.categories[index];
                    final isSelected = selectedCatId == cat.id;

                    return Material(
                      color: isSelected ? c.accent : c.surface1,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      child: InkWell(
                        onTap: () => ref
                            .read(selectedCategoryIdProvider.notifier)
                            .state = cat.id,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.space16,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                            border: Border.all(
                              color: isSelected ? c.accent : c.border,
                            ),
                          ),
                          child: Text(
                            cat.name,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : c.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppTheme.space12),

              // Products Grid (Bab 1.1 Daftar Produk)
              Expanded(
                child: products.isEmpty
                    ? const _EmptyCatalogState()
                    : GridView.builder(
                        gridDelegate: isCompact
                            ? const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisExtent: 254,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              )
                            : const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 235,
                                mainAxisExtent: 266,
                                crossAxisSpacing: AppTheme.space12,
                                mainAxisSpacing: AppTheme.space12,
                              ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final inCartQty = qtyMap[product.id] ?? 0;
                          return _ProductCatalogCard(
                            product: product,
                            inCartQty: inCartQty,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProductCatalogCard extends ConsumerWidget {
  final PosProduct product;
  final int inCartQty;

  const _ProductCatalogCard({
    required this.product,
    required this.inCartQty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final isOut = product.isOutOfStock;

    return Material(
      color: c.surface1,
      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      child: InkWell(
        onTap: () => openProductDetailPage(
          context: context,
          product: product,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(
              color: inCartQty > 0 ? c.accent : c.border,
              width: inCartQty > 0 ? 1.5 : 1,
            ),
            boxShadow: [
              if (!context.isDarkMode)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Component 2: Gambar Produk (Flexible height prevents any vertical overflow)
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductNetworkImage(
                      product: product,
                      borderRadius: AppTheme.radiusSm,
                    ),
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          product.sku,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isOut
                              ? c.error
                              : (product.isLowStock
                                  ? c.warning
                                  : Colors.black.withValues(alpha: 0.65)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isOut ? 'Habis' : 'Stok: ${product.stock}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Component 3: Nama Produk
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isOut ? c.textMuted : c.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                product.categoryName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),

              // Component 4: Harga Produk
              Text(
                AppFormatters.formatRupiah(product.basePrice),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isOut ? c.textMuted : c.accent,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),

              // Component 5: Tombol Beli (Navigates to Detail Page) & Quick Add
              if (inCartQty == 0)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton(
                          onPressed: isOut
                              ? null
                              : () => openProductDetailPage(
                                    context: context,
                                    product: product,
                                  ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusSm),
                            ),
                          ),
                          child: Text(
                            isOut ? 'Habis' : 'Beli',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isOut) ...[
                      const SizedBox(width: 6),
                      Material(
                        color: c.accentSoft,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        child: InkWell(
                          onTap: () => ref
                              .read(cartProvider.notifier)
                              .addOrUpdate(product, delta: 1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          child: SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(
                              Icons.add_shopping_cart_rounded,
                              size: 16,
                              color: c.accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                )
              else
                Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.accentSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 36,
                        ),
                        onPressed: () => ref
                            .read(cartProvider.notifier)
                            .addOrUpdate(product, delta: -1),
                        icon: Icon(
                          Icons.remove_rounded,
                          size: 16,
                          color: c.accent,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '$inCartQty',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 36,
                        ),
                        onPressed: inCartQty < product.stock
                            ? () => ref
                                .read(cartProvider.notifier)
                                .addOrUpdate(product, delta: 1)
                            : null,
                        icon: Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: inCartQty < product.stock
                              ? c.accent
                              : c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyCatalogState extends StatelessWidget {
  const _EmptyCatalogState();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 48,
            color: c.textMuted,
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            'Produk tidak ditemukan',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            'Coba gunakan kata kunci pencarian atau kategori lain.',
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Right Pane / Bottom Sheet: Keranjang Kasir (Order Summary)
// ---------------------------------------------------------------------------

class _CartPanel extends ConsumerWidget {
  final bool isModalSheet;

  const _CartPanel({this.isModalSheet = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final cartItems = ref.watch(cartProvider);
    final totalAmount = ref.watch(cartTotalAmountProvider);
    final totalItems = ref.watch(cartTotalItemsProvider);
    final selectedMethod = ref.watch(selectedPaymentMethodProvider);

    return Container(
      color: c.surface1,
      padding: const EdgeInsets.all(AppTheme.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cart Header
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.space8,
            runSpacing: AppTheme.space8,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    color: c.accent,
                    size: 20,
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Text(
                    'Pesanan Kasir',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: c.accentSoft,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: Text(
                      '$totalItems',
                      style: TextStyle(
                        color: c.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              if (cartItems.isNotEmpty)
                InkWell(
                  onTap: () => ref.read(cartProvider.notifier).clear(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.delete_outline_rounded,
                          size: 15,
                          color: c.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reset',
                          style: TextStyle(
                            color: c.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Divider(height: 1, color: c.border),
          const SizedBox(height: AppTheme.space12),

          // Cart Items List
          Expanded(
            child: cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_shopping_cart_rounded,
                          size: 44,
                          color: c.textMuted,
                        ),
                        const SizedBox(height: AppTheme.space12),
                        Text(
                          'Keranjang kasir masih kosong',
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppTheme.space4),
                        Text(
                          'Pilih produk di katalog untuk memulai transaksi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: cartItems.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppTheme.space8),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return _CartItemTile(item: item);
                    },
                  ),
          ),

          const SizedBox(height: AppTheme.space12),
          Divider(height: 1, color: c.border),
          const SizedBox(height: AppTheme.space12),

          // Payment Method Selection
          Text(
            'Metode Pembayaran',
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppTheme.space8),
          Row(
            children: [
              for (final method in PaymentMethod.values)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: method != PaymentMethod.values.last
                          ? AppTheme.space8
                          : 0,
                    ),
                    child: InkWell(
                      onTap: () => ref
                          .read(selectedPaymentMethodProvider.notifier)
                          .state = method,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selectedMethod == method
                              ? c.accentSoft
                              : c.surface2,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                            color: selectedMethod == method
                                ? c.accent
                                : c.border,
                          ),
                        ),
                        child: Text(
                          method.code,
                          style: TextStyle(
                            color: selectedMethod == method
                                ? c.accent
                                : c.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.space16),

          // Summary Totals
          Container(
            padding: const EdgeInsets.all(AppTheme.space16),
            decoration: BoxDecoration(
              color: c.surface2,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total Item',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '$totalItems item',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Total Tagihan',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          AppFormatters.formatRupiah(totalAmount),
                          style: TextStyle(
                            color: c.accent,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space16),

          // Checkout CTA -> Navigates to full-page PaymentScreen
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: cartItems.isEmpty
                  ? null
                  : () {
                      if (isModalSheet && Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      openPosPaymentPage(context: context, ref: ref);
                    },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: Text(
                selectedMethod == PaymentMethod.qris
                    ? 'Bayar via QRIS'
                    : 'Proses Pembayaran (${selectedMethod.code})',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemTile extends ConsumerWidget {
  final CartItem item;

  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.surface2,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          ProductNetworkImage(
            product: item.product,
            width: 44,
            height: 44,
            borderRadius: AppTheme.radiusSm,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppFormatters.formatRupiah(item.product.basePrice)} • Sisa: ${item.product.stock}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.formatRupiah(item.subtotal),
                  style: TextStyle(
                    color: c.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _MiniQtyBtn(
                icon: Icons.remove_rounded,
                onTap: () => ref
                    .read(cartProvider.notifier)
                    .addOrUpdate(item.product, delta: -1),
              ),
              SizedBox(
                width: 28,
                child: Text(
                  '${item.qty}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              _MiniQtyBtn(
                icon: Icons.add_rounded,
                onTap: item.qty < item.product.stock
                    ? () => ref
                        .read(cartProvider.notifier)
                        .addOrUpdate(item.product, delta: 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniQtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniQtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final enabled = onTap != null;

    return Material(
      color: enabled ? c.surfaceHover : c.surface1,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            icon,
            size: 16,
            color: enabled ? c.textPrimary : c.textMuted,
          ),
        ),
      ),
    );
  }
}

class _MobileCartBar extends ConsumerWidget {
  const _MobileCartBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final totalItems = ref.watch(cartTotalItemsProvider);
    final totalAmount = ref.watch(cartTotalAmountProvider);

    if (totalItems == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space16,
        vertical: AppTheme.space12,
      ),
      decoration: BoxDecoration(
        color: c.surface1,
        border: Border(top: BorderSide(color: c.borderStrong)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: c.surface1,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(AppTheme.radiusXl),
                    ),
                  ),
                  builder: (_) => const SizedBox(
                    height: 520,
                    child: _CartPanel(isModalSheet: true),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$totalItems item dipilih (Ketuk rincian)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppFormatters.formatRupiah(totalAmount),
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppTheme.space12),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () =>
                  openPosPaymentPage(context: context, ref: ref),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Bayar'),
            ),
          ),
        ],
      ),
    );
  }
}
