import 'package:equatable/equatable.dart';
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
      imageUrl: json['image_url'] as String?,
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
      imageUrl: imageUrl ?? '',
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
