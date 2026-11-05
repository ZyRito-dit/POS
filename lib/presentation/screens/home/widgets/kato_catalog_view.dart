import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';
import 'package:pos_apps_umkm/presentation/widgets/pos_dialogs.dart';

/// Tampilan Katalog Produk Kato POS yang terhubung langsung dengan backend API
/// (`/api/v1/pos/catalog` atau `/api/v1/products`).
/// Menghilangkan seluruh data dummy dan menampilkan data real-time, loading, dan empty state.
class KatoCatalogView extends ConsumerStatefulWidget {
  final ValueChanged<PosProduct>? onProductTap;
  final bool isMobile;

  const KatoCatalogView({
    super.key,
    this.onProductTap,
    this.isMobile = false,
  });

  @override
  ConsumerState<KatoCatalogView> createState() => _KatoCatalogViewState();
}

class _KatoCatalogViewState extends ConsumerState<KatoCatalogView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategoryId = ref.watch(selectedCategoryIdProvider);
    final filteredProducts = ref.watch(filteredProductsProvider);
    final cartItems = ref.watch(cartProvider);
    final isLoading = ref.watch(isCatalogLoadingProvider);
    final catalogError = ref.watch(catalogErrorProvider);

    final categoriesAsync = ref.watch(categoriesProvider);
    final categories = categoriesAsync.valueOrNull ??
        const [ProductCategory(id: 0, name: 'Semua')];

    // Hitung jumlah tiap produk dalam cart untuk menampilkan badge kuantitas & active border
    final cartQtyByProductId = <int, int>{};
    for (final item in cartItems) {
      cartQtyByProductId[item.product.id] = item.qty;
    }

    final isMobile = widget.isMobile;

    return Container(
      color: const Color(0xFFFBFBFD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -----------------------------------------------------------------
          // 1. Search Bar & Filter Kategori Dropdown
          // -----------------------------------------------------------------
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: 14,
            ),
            child: Row(
              children: [
                // Input Pencarian Nama Produk atau SKU
                Expanded(
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(catalogSearchQueryProvider.notifier).state = val;
                        setState(() {});
                      },
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari nama produk atau SKU',
                        hintStyle: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF94A3B8),
                          size: 20,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 16),
                                color: const Color(0xFF94A3B8),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(catalogSearchQueryProvider.notifier)
                                      .state = '';
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Tombol Filter Kategori (Dropdown Menu)
                _buildCategoryFilterDropdown(categories, selectedCategoryId),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // 2. Grid Produk (4 kolom di tablet, 2 kolom di mobile)
          // -----------------------------------------------------------------
          Expanded(
            child: isLoading && filteredProducts.isEmpty
                ? const Center(
                    child: SingleChildScrollView(
                      physics: BouncingScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF5247A1),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Memuat katalog produk...',
                            style: TextStyle(
                              fontFamily: 'Open Sans',
                              fontSize: 13,
                              color: Color(0xFF808080),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredProducts.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F0FA),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  _searchController.text.trim().isNotEmpty
                                      ? Icons.search_off_rounded
                                      : Icons.inventory_2_outlined,
                                  size: 28,
                                  color: const Color(0xFF5247A1),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchController.text.trim().isNotEmpty
                                    ? 'Produk Tidak Ditemukan'
                                    : 'Belum Ada Produk di Etalase',
                                style: const TextStyle(
                                  fontFamily: 'Open Sans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchController.text.trim().isNotEmpty
                                    ? 'Tidak ada produk yang cocok dengan "${_searchController.text.trim()}". Periksa ejaan atau reset kata kunci.'
                                    : (catalogError ??
                                        'Katalog kosong. Produk akan muncul saat terhubung dengan server Kato POS.'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Open Sans',
                                  fontSize: 13,
                                  color: Color(0xFF808080),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_searchController.text.trim().isNotEmpty)
                                OutlinedButton.icon(
                                  onPressed: () {
                                    _searchController.clear();
                                    ref
                                        .read(catalogSearchQueryProvider.notifier)
                                        .state = '';
                                    setState(() {});
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF5247A1),
                                    side: const BorderSide(
                                      color: Color(0xFF5247A1),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                  ),
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  label: const Text(
                                    'Reset Pencarian',
                                    style: TextStyle(
                                      fontFamily: 'Open Sans',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ref
                                        .read(posProductsProvider.notifier)
                                        .fetchCatalog(
                                          categoryId: selectedCategoryId,
                                          search: _searchController.text,
                                          outletId: ref.read(selectedOutletProvider)?.id ??
                                              ref.read(currentUserProvider)?.outletId ??
                                              1,
                                        );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF5247A1),
                                    side: const BorderSide(
                                      color: Color(0xFF5247A1),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                      vertical: 10,
                                    ),
                                  ),
                                  icon:
                                      const Icon(Icons.refresh_rounded, size: 18),
                                  label: const Text(
                                    'Muat Ulang',
                                    style: TextStyle(
                                      fontFamily: 'Open Sans',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: const Color(0xFF5247A1),
                        onRefresh: () async {
                          await ref
                              .read(posProductsProvider.notifier)
                              .fetchCatalog(
                                categoryId: selectedCategoryId,
                                search: _searchController.text,
                                outletId: ref.read(selectedOutletProvider)?.id ??
                                    ref.read(currentUserProvider)?.outletId ??
                                    1,
                              );
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            // Responsif adaptif kolom berdasarkan lebar aktual yang tersedia:
                            // Mobile portrait / ruang sempit (< 480px): 2 kolom
                            // Mode landscape / tablet / desktop (>= 480px): 4 kolom sesuai desain Kato POS
                            final int crossAxisCount;
                            final double childAspectRatio;

                            if (availableWidth < 480) {
                              crossAxisCount = 2;
                              childAspectRatio = 0.68;
                            } else {
                              crossAxisCount = 4;
                              childAspectRatio = 0.65;
                            }

                            final horizontalPadding = availableWidth < 600
                                ? 16.0
                                : (isMobile ? 16.0 : 24.0);

                            return GridView.builder(
                              padding: EdgeInsets.only(
                                left: horizontalPadding,
                                right: horizontalPadding,
                                top: 4,
                                bottom: 24,
                              ),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: childAspectRatio,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                final cartQty = cartQtyByProductId[product.id] ?? 0;
                                final remainingStock =
                                    (product.stock - cartQty).clamp(0, 9999);
                                final isSelected = cartQty > 0;

                                return _buildProductCard(
                                  context: context,
                                  product: product,
                                  remainingStock: remainingStock,
                                  isSelected: isSelected,
                                  onTap: () {
                                    if (remainingStock <= 0) {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Stok ${product.name} telah habis di keranjang',
                                            style: const TextStyle(
                                                fontFamily: 'Open Sans'),
                                          ),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }

                                    ref
                                        .read(cartProvider.notifier)
                                        .addOrUpdate(product, delta: 1);
                                    widget.onProductTap?.call(product);
                                  },
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required PosProduct product,
    required int remainingStock,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final hasImage = product.imageUrl.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5247A1)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x145247A1),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ]
              : const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kotak Gambar Produk (Expanded responsif agar tinggi gambar dan card 100% sejajar tanpa overflow)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFBFBFD),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: hasImage
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const ProductNoImagePlaceholder(iconSize: 32),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF5247A1),
                              ),
                            ),
                          );
                        },
                      )
                    : const ProductNoImagePlaceholder(iconSize: 34),
              ),
            ),

            const SizedBox(height: 8),

            // Baris Nama Produk & Badge Stok (Sejajar dengan teks nama produk baris pertama)
            SizedBox(
              height: 34,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: Color(0xFF1E293B),
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 18,
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 18,
                      maxHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5.5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: remainingStock > 0
                          ? const Color(0xFF5247A1)
                          : const Color(0xFF94A3B8),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$remainingStock',
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Badge Kategori (Tinggi Seragam 20px)
            SizedBox(
              height: 20,
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F0FA),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        product.categoryName.isNotEmpty
                            ? product.categoryName
                            : 'Produk',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: Color(0xFF5247A1),
                        ),
                      ),
                    ),
                  ),
                  // Kode produk dinonaktifkan dari tampilan card produk
                  // if (product.sku.isNotEmpty) ...[
                  //   const SizedBox(width: 4),
                  //   Flexible(
                  //     child: Text(
                  //       'Kode: ${product.sku}',
                  //       maxLines: 1,
                  //       overflow: TextOverflow.ellipsis,
                  //       style: const TextStyle(
                  //         fontFamily: 'Open Sans',
                  //         fontWeight: FontWeight.w400,
                  //         fontSize: 9.5,
                  //         color: Color(0xFF94A3B8),
                  //       ),
                  //     ),
                  //   ),
                  // ],
                ],
              ),
            ),

            const SizedBox(height: 5),

            // Harga Produk (#5247A1)
            Text(
              AppFormatters.formatRupiah(product.basePrice),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: Color(0xFF5247A1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilterDropdown(
    List<ProductCategory> categories,
    int selectedCategoryId,
  ) {
    final selectedCategory = categories.firstWhere(
      (c) => c.id == selectedCategoryId,
      orElse: () => const ProductCategory(id: 0, name: 'Semua'),
    );

    final label = selectedCategory.id == 0
        ? 'Filter Kategori'
        : selectedCategory.name;

    return PopupMenuButton<int>(
      tooltip: 'Filter Kategori',
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      elevation: 4,
      onSelected: (catId) {
        ref.read(selectedCategoryIdProvider.notifier).state = catId;
      },
      itemBuilder: (context) => [
        for (final cat in categories)
          PopupMenuItem<int>(
            value: cat.id,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 13,
                      fontWeight: cat.id == selectedCategoryId
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: cat.id == selectedCategoryId
                          ? const Color(0xFF5247A1)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (cat.id == selectedCategoryId)
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Color(0xFF5247A1),
                  ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: widget.isMobile ? 100 : 160,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Icon(
              Icons.tune_rounded,
              size: 18,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }
}
