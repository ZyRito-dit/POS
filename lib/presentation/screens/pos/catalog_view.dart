import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/core/theme/app_theme.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/data/dummy/pos_dummy_data.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/widgets/app_text_field.dart';
import 'package:pos_apps_umkm/presentation/widgets/pos_dialogs.dart';
import 'package:pos_apps_umkm/presentation/widgets/primary_button.dart';

class CatalogView extends ConsumerWidget {
  const CatalogView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.colors;
    final products = ref.watch(posProductsProvider);
    final totalStock = products.fold<int>(0, (sum, p) => sum + p.stock);
    final lowStockCount = products.where((p) => p.isLowStock).length;
    final outOfStockCount = products.where((p) => p.isOutOfStock).length;
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? AppTheme.space16 : AppTheme.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTheme.space16,
            runSpacing: AppTheme.space12,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Katalog Produk dan Monitoring Stok',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppTheme.space4),
                    Text(
                      'Kelola master data produk, harga dasar, dan ketersediaan stok etalase kasir.',
                      style: TextStyle(
                        color: palette.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateProductSheet(context),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Tambah Produk'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space20),

          // Summary Metric Cards (Bento Grid)
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 840
                  ? 4
                  : (constraints.maxWidth >= 340 ? 2 : 1);
              const spacing = AppTheme.space12;
              final itemWidth =
                  (constraints.maxWidth - (spacing * (cols - 1))) / cols;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _InventoryStatCard(
                      label: 'Total Produk (SKU)',
                      value: '${products.length}',
                      subtitle: 'Terdaftar di katalog',
                      color: palette.accent,
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _InventoryStatCard(
                      label: 'Total Unit Stok',
                      value: '$totalStock',
                      subtitle: 'Unit siap jual',
                      color: palette.success,
                      icon: Icons.check_circle_outline_rounded,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _InventoryStatCard(
                      label: 'Stok Menipis',
                      value: '$lowStockCount',
                      subtitle: 'Sisa <= 5 unit',
                      color: palette.warning,
                      icon: Icons.warning_amber_rounded,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _InventoryStatCard(
                      label: 'Stok Habis',
                      value: '$outOfStockCount',
                      subtitle: 'Perlu restock segera',
                      color: palette.error,
                      icon: Icons.error_outline_rounded,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppTheme.space20),

          // Product Inventory List
          Container(
            decoration: BoxDecoration(
              color: palette.surface1,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
              border: Border.all(color: palette.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: palette.border),
              itemBuilder: (context, index) {
                final product = products[index];
                return _InventoryProductRow(product: product);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateProductSheet(BuildContext context) {
    final palette = context.colors;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
      ),
      builder: (_) => const _CreateProductSheet(),
    );
  }
}

class _InventoryStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;

  const _InventoryStatCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppTheme.space16),
      decoration: BoxDecoration(
        color: palette.surface1,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space8),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: AppTheme.space12),
          Text(
            value,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: AppTheme.space4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryProductRow extends ConsumerWidget {
  final PosProduct product;

  const _InventoryProductRow({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.colors;

    return InkWell(
      onTap: () => openProductDetailPage(context: context, product: product),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.space16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 540;

            final productInfo = Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ProductNetworkImage(
                  product: product,
                  width: 56,
                  height: 56,
                  borderRadius: AppTheme.radiusMd,
                ),
                const SizedBox(width: AppTheme.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppTheme.space8,
                        runSpacing: AppTheme.space4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              color: palette.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: palette.surface2,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: palette.border),
                            ),
                            child: Text(
                              product.sku,
                              style: TextStyle(
                                color: palette.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.space4),
                      Text(
                        '${product.categoryName} • ${AppFormatters.formatRupiah(product.basePrice)}',
                        style: TextStyle(
                          color: palette.textSecondary,
                          fontSize: 12,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final actionsRow = Wrap(
              spacing: AppTheme.space8,
              runSpacing: AppTheme.space8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment:
                  isNarrow ? WrapAlignment.spaceBetween : WrapAlignment.end,
              children: [
                // Stock status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.space12,
                    vertical: AppTheme.space8,
                  ),
                  decoration: BoxDecoration(
                    color: product.isOutOfStock
                        ? palette.errorSoft
                        : (product.isLowStock
                            ? palette.warningSoft
                            : palette.surface2),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: Text(
                    product.isOutOfStock
                        ? 'Habis (0)'
                        : 'Stok: ${product.stock}',
                    style: TextStyle(
                      color: product.isOutOfStock
                          ? palette.error
                          : (product.isLowStock
                              ? palette.warning
                              : palette.textPrimary),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Detail Page Button
                    OutlinedButton.icon(
                      onPressed: () => openProductDetailPage(
                        context: context,
                        product: product,
                      ),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space12,
                        ),
                        foregroundColor: palette.textPrimary,
                        side: BorderSide(color: palette.borderStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 15),
                      label: const Text(
                        'Detail',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space8),

                    // Quick Restock Button
                    OutlinedButton(
                      onPressed: () {
                        ref
                            .read(posProductsProvider.notifier)
                            .updateStock(product.id, 10);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Restock +10 unit untuk ${product.name} berhasil.',
                              style: TextStyle(color: palette.textPrimary),
                            ),
                            backgroundColor: palette.surface1,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.space12,
                        ),
                        foregroundColor: palette.accent,
                        side: BorderSide(
                          color: palette.accent.withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                        ),
                      ),
                      child: const Text(
                        '+10 Stok',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  productInfo,
                  const SizedBox(height: AppTheme.space12),
                  actionsRow,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: productInfo),
                const SizedBox(width: AppTheme.space16),
                actionsRow,
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Bottom Sheet for Creating New Product (Modeled on POST /api/v1/products).
class _CreateProductSheet extends ConsumerStatefulWidget {
  const _CreateProductSheet();

  @override
  ConsumerState<_CreateProductSheet> createState() =>
      _CreateProductSheetState();
}

class _CreateProductSheetState extends ConsumerState<_CreateProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _skuCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '20');
  final _packagingCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  int _selectedCategoryId = 3;

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _packagingCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final palette = context.colors;

    final price = int.tryParse(
          _priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
        ) ??
        5000;
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 10;

    ref.read(posProductsProvider.notifier).addProduct(
          sku: _skuCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          basePrice: price,
          categoryId: _selectedCategoryId,
          stock: stock,
          packagingInfo: _packagingCtrl.text.trim(),
          description:
              'Produk ${_nameCtrl.text.trim()} terdaftar melalui katalog POS.',
          imageUrl: _imageUrlCtrl.text.trim(),
        );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Produk "${_nameCtrl.text.trim()}" berhasil ditambahkan ke katalog.',
          style: TextStyle(color: palette.textPrimary),
        ),
        backgroundColor: palette.surface1,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final selectableCategories =
        PosDummyData.categories.where((c) => c.id != 0).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.space24,
        right: AppTheme.space24,
        top: AppTheme.space24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.space32,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: palette.borderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.space20),
              Text(
                'Tambah Produk Baru',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppTheme.space4),
              Text(
                'Tambahkan entitas produk baru untuk ditampilkan pada katalog Kasir POS.',
                style: TextStyle(color: palette.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: AppTheme.space20),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _skuCtrl,
                      label: 'Kode SKU',
                      hint: 'Misal: CHT-002',
                      prefixIconData: Icons.qr_code_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'SKU wajib diisi'
                          : null,
                    ),
                  ),
                  const SizedBox(width: AppTheme.space12),
                  Expanded(
                    child: AppTextField(
                      controller: _stockCtrl,
                      label: 'Stok Awal',
                      hint: '20',
                      prefixIconData: Icons.layers_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Wajib diisi'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.space12),
              AppTextField(
                controller: _nameCtrl,
                label: 'Nama Produk',
                hint: 'Misal: Chitato Sapi Panggang',
                prefixIconData: Icons.shopping_bag_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama produk wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppTheme.space12),
              AppTextField(
                controller: _priceCtrl,
                label: 'Harga Dasar (Rp)',
                hint: 'Misal: 12000',
                prefixIconData: Icons.payments_outlined,
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Harga wajib diisi'
                    : null,
              ),
              const SizedBox(height: AppTheme.space12),
              Text(
                'Kategori Produk',
                style: TextStyle(
                  color: palette.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppTheme.space8),
              DropdownButtonFormField<int>(
                initialValue: _selectedCategoryId,
                dropdownColor: palette.surface1,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 14,
                ),
                items: [
                  for (final cat in selectableCategories)
                    DropdownMenuItem(
                      value: cat.id,
                      child: Text(cat.name),
                    ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategoryId = val);
                  }
                },
              ),
              const SizedBox(height: AppTheme.space12),
              AppTextField(
                controller: _imageUrlCtrl,
                label: 'URL Gambar Produk (Online)',
                hint: 'Opsional (https://...)',
                prefixIconData: Icons.image_outlined,
              ),
              const SizedBox(height: AppTheme.space12),
              AppTextField(
                controller: _packagingCtrl,
                label: 'Informasi Kemasan',
                hint: 'Misal: Chitato | Kemasan | 68 gram',
                prefixIconData: Icons.info_outline_rounded,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppTheme.space24),
              PrimaryButton(
                label: 'Simpan Produk ke Katalog',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
