import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/core/utils/formatters.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/presentation/providers/auth_provider.dart';
import 'package:pos_apps_umkm/presentation/providers/pos_provider.dart';

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
          // 1. Search Bar & Barcode Scanner Button
          // -----------------------------------------------------------------
          Padding(
            padding: EdgeInsets.only(
              left: isMobile ? 16 : 24,
              right: isMobile ? 16 : 24,
              top: 16,
              bottom: 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE8E8EC),
                        width: 1,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(catalogSearchQueryProvider.notifier).state = val;
                      },
                      style: const TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 14,
                        color: Color(0xFF1E1E1E),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Cari produk makanan...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 14,
                          color: Color(0xFFA0A0A5),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFFA0A0A5),
                          size: 22,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                color: const Color(0xFFA0A0A5),
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
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Tombol Barcode Scanner Ungu (#5247A1)
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Pemindai barcode aktif...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5247A1),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x265247A1),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // -----------------------------------------------------------------
          // 2. Kategori Horizontal Chips (Dinamis dari API /api/v1/categories)
          // -----------------------------------------------------------------
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
              ),
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategoryId == category.id;

                return GestureDetector(
                  onTap: () {
                    ref.read(selectedCategoryIdProvider.notifier).state =
                        category.id;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF5247A1)
                          : const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF5247A1)
                            : const Color(0xFFE8E8EC),
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? const [
                              BoxShadow(
                                color: Color(0x205247A1),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontFamily: 'Open Sans',
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 13,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // -----------------------------------------------------------------
          // 3. Grid Produk (3 kolom di tablet, 2 kolom di mobile)
          // -----------------------------------------------------------------
          Expanded(
            child: isLoading && filteredProducts.isEmpty
                ? const Center(
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
                  )
                : filteredProducts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F0FA),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 32,
                                  color: Color(0xFF5247A1),
                                ),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Belum Ada Produk di Etalase',
                                style: TextStyle(
                                  fontFamily: 'Open Sans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E1E1E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                catalogError ??
                                    'Katalog kosong. Produk akan muncul saat terhubung dengan server Kato POS.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontFamily: 'Open Sans',
                                  fontSize: 13,
                                  color: Color(0xFF808080),
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  ref
                                      .read(posProductsProvider.notifier)
                                      .fetchCatalog(
                                        categoryId: selectedCategoryId,
                                        search: _searchController.text,
                                        outletId: ref.read(currentUserProvider)?.outletId ?? 1,
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
                                outletId: ref.read(currentUserProvider)?.outletId ?? 1,
                              );
                        },
                        child: GridView.builder(
                          padding: EdgeInsets.only(
                            left: isMobile ? 16 : 24,
                            right: isMobile ? 16 : 24,
                            top: 4,
                            bottom: 24,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: isMobile ? 2 : 3,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: isMobile ? 0.72 : 0.78,
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5247A1)
                : const Color(0xFFEFEFF2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x185247A1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gambar Makanan dalam Piring Putih Elegan
            Expanded(
              flex: 12,
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Lingkaran Piring Putih di belakang sajian
                    Center(
                      child: Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Gambar Produk Asli atau Placeholder Ikon Sesuai Kategori
                    if (hasImage)
                      Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Center(
                          child: Icon(
                            _getProductPlaceholderIcon(product),
                            size: 44,
                            color: const Color(0xFF5247A1)
                                .withValues(alpha: 0.45),
                          ),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Center(
                            child: Icon(
                              _getProductPlaceholderIcon(product),
                              size: 36,
                              color: const Color(0xFF5247A1)
                                  .withValues(alpha: 0.2),
                            ),
                          );
                        },
                      )
                    else
                      Center(
                        child: Icon(
                          _getProductPlaceholderIcon(product),
                          size: 46,
                          color: const Color(0xFF5247A1)
                              .withValues(alpha: 0.45),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Info Produk: Nama & Badge Stok Sisa, Kode SKU, Harga
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Baris 1: Nama Produk & Badge Jumlah Stok Saat Ini (Berkurang saat dipilih)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF1E1E1E),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: remainingStock > 0
                              ? const Color(0xFF5247A1)
                              : const Color(0xFF9E9E9E),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$remainingStock',
                          style: const TextStyle(
                            fontFamily: 'Open Sans',
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kode: ${product.sku.isNotEmpty ? product.sku : 'P00${product.id}'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                      color: Color(0xFF8C8C8C),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppFormatters.formatRupiah(product.basePrice),
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF5247A1),
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

  IconData _getProductPlaceholderIcon(PosProduct product) {
    final lower = '${product.name} ${product.categoryName}'.toLowerCase();
    if (lower.contains('kopi') ||
        lower.contains('coffee') ||
        lower.contains('espresso')) {
      return Icons.coffee_rounded;
    }
    if (lower.contains('matcha') ||
        lower.contains('latte') ||
        lower.contains('tea') ||
        lower.contains('drink') ||
        lower.contains('beverage') ||
        lower.contains('non-coffee')) {
      return Icons.local_cafe_outlined;
    }
    if (lower.contains('cake') ||
        lower.contains('pastry') ||
        lower.contains('dessert') ||
        lower.contains('bakery') ||
        lower.contains('slice')) {
      return Icons.cake_outlined;
    }
    return Icons.restaurant_rounded;
  }
}
