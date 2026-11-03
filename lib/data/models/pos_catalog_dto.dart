import 'package:equatable/equatable.dart';
import 'package:pos_apps_umkm/core/constants/app_constants.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';

/// Data Transfer Object untuk item katalog POS dari backend Kato POS (`/api/v1/pos/catalog`).
class PosCatalogItemDto extends Equatable {
  final int id;
  final String sku;
  final String name;
  final String description;
  final int basePrice;
  final int categoryId;
  final String categoryName;
  final int stock;
  final String? imageUrl;
  final bool trackStock;
  final String status;
  final int outletId;

  const PosCatalogItemDto({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.categoryId,
    required this.categoryName,
    required this.stock,
    this.imageUrl,
    this.trackStock = true,
    this.status = 'ACTIVE',
    this.outletId = 1,
  });

  /// Normalizes image URL from backend (handles localhost/127.0.0.1 MinIO host and relative paths).
  static String? normalizeImageUrl(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Fix MinIO localhost or 127.0.0.1 mapping for physical device compatibility
    if (trimmed.contains('localhost:') || trimmed.contains('127.0.0.1:')) {
      final backendUri = Uri.tryParse(AppConstants.baseUrl);
      if (backendUri != null) {
        return trimmed
            .replaceAll('localhost:', '${backendUri.host}:')
            .replaceAll('127.0.0.1:', '${backendUri.host}:');
      }
    }

    // Fix relative path if server returned /uploads/... or /katopos/...
    if (trimmed.startsWith('/')) {
      final base = AppConstants.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
      return '$base$trimmed';
    }

    return trimmed;
  }

  factory PosCatalogItemDto.fromJson(Map<String, dynamic> json) {
    return PosCatalogItemDto(
      id: json['id'] as int? ?? 0,
      sku: (json['sku'] as String?) ??
          (json['code'] as String?) ??
          (json['product_code'] as String?) ??
          '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      basePrice: (json['price'] as num?)?.toInt() ??
          (json['base_price'] as num?)?.toInt() ??
          (json['selling_price'] as num?)?.toInt() ??
          0,
      categoryId: json['category_id'] as int? ??
          (json['category'] is Map
              ? (json['category']['id'] as int? ?? 0)
              : 0),
      categoryName: json['category_name'] as String? ??
          (json['category'] is Map
              ? (json['category']['name'] as String? ?? '')
              : ''),
      stock: (json['qty_on_hand'] as num?)?.toInt() ??
          (json['stock'] as num?)?.toInt() ??
          (json['total_stock'] as num?)?.toInt() ??
          (json['quantity'] as num?)?.toInt() ??
          0,
      imageUrl: normalizeImageUrl(
        (json['image_url'] as String?) ??
            (json['imageUrl'] as String?) ??
            (json['image'] as String?) ??
            (json['photo_url'] as String?) ??
            (json['file_url'] as String?) ??
            (json['thumbnail_url'] as String?),
      ),
      trackStock: json['track_stock'] as bool? ?? true,
      status: json['status'] as String? ?? 'ACTIVE',
      outletId: (json['outlet_id'] as num?)?.toInt() ?? 1,
    );
  }

  PosProduct toEntity() {
    return PosProduct(
      id: id,
      sku: sku,
      name: name,
      basePrice: basePrice,
      categoryId: categoryId,
      categoryName: categoryName.isEmpty ? 'Umum' : categoryName,
      stock: stock,
      description: description,
      packagingInfo: categoryName,
      imageUrl: (imageUrl != null && imageUrl!.trim().isNotEmpty)
          ? imageUrl!.trim()
          : '',
      outletId: outletId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sku,
        name,
        basePrice,
        categoryId,
        categoryName,
        stock,
        imageUrl,
        trackStock,
        status,
        outletId,
      ];
}

/// Data Transfer Object untuk kategori produk (`/api/v1/categories`).
class CategoryDto extends Equatable {
  final int id;
  final String name;
  final String description;
  final String status;

  const CategoryDto({
    required this.id,
    required this.name,
    this.description = '',
    this.status = 'ACTIVE',
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  ProductCategory toEntity() {
    return ProductCategory(
      id: id,
      name: name,
    );
  }

  @override
  List<Object?> get props => [id, name, description, status];
}
