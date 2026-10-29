import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_apps_umkm/core/constants/app_constants.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/core/errors/error_mapper.dart';
import 'package:pos_apps_umkm/core/network/dio_provider.dart';
import 'package:pos_apps_umkm/data/models/checkout_dto.dart';
import 'package:pos_apps_umkm/data/models/pos_catalog_dto.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';
import 'package:pos_apps_umkm/domain/repositories/pos_repository.dart';

/// Implementasi konkret [PosRepository] yang berkomunikasi langsung dengan
/// API backend Kato POS (`/api/v1/pos/catalog`, `/api/v1/products`, dan `/api/v1/categories`).
class PosRepositoryImpl implements PosRepository {
  final Dio _dio;

  const PosRepositoryImpl(this._dio);

  @override
  Future<(List<PosProduct>?, AppFailure?)> getCatalog({
    int? categoryId,
    String? search,
    int? outletId,
    int page = 1,
    int perPage = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (categoryId != null && categoryId > 0) {
      queryParams['category_id'] = categoryId;
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (outletId != null && outletId > 0) {
      queryParams['outlet_id'] = outletId;
    }

    try {
      // 1. Coba endpoint utama POS Catalog
      Response response;
      try {
        response = await _dio.get(
          AppConstants.posCatalogEndpoint,
          queryParameters: queryParams,
        );
      } on DioException catch (e) {
        // Jika endpoint pos/catalog 404, fallback ke endpoint /products
        if (e.response?.statusCode == 404) {
          response = await _dio.get(
            AppConstants.productsEndpoint,
            queryParameters: queryParams,
          );
        } else {
          rethrow;
        }
      }

      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['data'] is List) {
        final list = (raw['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => PosCatalogItemDto.fromJson(item).toEntity())
            .toList();
        return (list, null);
      }

      return (const <PosProduct>[], null);
    } on DioException catch (e) {
      return (null, mapDioExceptionToFailure(e));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<ProductCategory>?, AppFailure?)> getCategories({
    int? outletId,
  }) async {
    final queryParams = <String, dynamic>{
      'per_page': 50,
    };
    if (outletId != null && outletId > 0) {
      queryParams['outlet_id'] = outletId;
    }

    try {
      final response = await _dio.get(
        AppConstants.categoriesEndpoint,
        queryParameters: queryParams,
      );

      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['data'] is List) {
        final list = (raw['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => CategoryDto.fromJson(item).toEntity())
            .toList();
        return (list, null);
      }

      return (const <ProductCategory>[], null);
    } on DioException catch (e) {
      return (null, mapDioExceptionToFailure(e));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(CheckoutResult?, AppFailure?)> checkout({
    required int outletId,
    required String paymentMethod,
    int? cashReceived,
    required List<CartItem> items,
    String receiptFormat = 'A',
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ??
        'chk_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

    final dto = CheckoutRequestDto(
      outletId: outletId,
      paymentMethod: paymentMethod,
      cashReceived: cashReceived,
      receiptFormat: receiptFormat,
      items: items
          .map((item) => CheckoutItemRequestDto(
                productId: item.product.id,
                quantity: item.qty,
              ))
          .toList(),
    );

    try {
      final response = await _dio.post(
        AppConstants.posCheckoutEndpoint,
        data: dto.toJson(),
        options: Options(
          headers: {'Idempotency-Key': key},
        ),
      );

      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
        final resultDto = CheckoutResponseDto.fromJson(
          raw['data'] as Map<String, dynamic>,
        );
        return (resultDto.toEntity(), null);
      }

      return (
        null,
        const UnknownFailure('Format data checkout tidak valid dari server')
      );
    } on DioException catch (e) {
      return (null, mapDioExceptionToFailure(e));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(QrisPaymentInfo?, AppFailure?)> initiateQris({
    required int saleId,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ??
        'qris_${saleId}_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';

    try {
      final response = await _dio.post(
        AppConstants.initiateQrisEndpoint(saleId),
        data: {'idempotency_key': key},
        options: Options(
          headers: {'Idempotency-Key': key},
        ),
      );

      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
        final qrisDto = InitiateQrisResponseDto.fromJson(
          raw['data'] as Map<String, dynamic>,
        );
        return (qrisDto.toEntity(), null);
      }

      return (
        null,
        const UnknownFailure('Gagal menghasilkan payload QRIS dari server')
      );
    } on DioException catch (e) {
      return (null, mapDioExceptionToFailure(e));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(QrisPaymentInfo?, AppFailure?)> checkPaymentStatus({
    required int paymentId,
  }) async {
    try {
      final response = await _dio.get(
        AppConstants.paymentStatusEndpoint(paymentId),
      );

      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
        final qrisDto = InitiateQrisResponseDto.fromJson(
          raw['data'] as Map<String, dynamic>,
        );
        return (qrisDto.toEntity(), null);
      }

      return (
        null,
        const UnknownFailure('Status pembayaran tidak ditemukan')
      );
    } on DioException catch (e) {
      return (null, mapDioExceptionToFailure(e));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, String?, AppFailure?)> verifyPayment({
    required int paymentId,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.verifyPaymentEndpoint(paymentId),
      );

      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['data'] is Map<String, dynamic>) {
        final data = raw['data'] as Map<String, dynamic>;
        final status = (data['status'] as String? ?? '').toUpperCase();
        final message =
            data['message'] as String? ?? 'Verifikasi status berhasil';
        return (status == 'PAID', message, null);
      }

      return (
        false,
        null,
        const UnknownFailure('Format respon verifikasi tidak dikenali')
      );
    } on DioException catch (e) {
      return (false, null, mapDioExceptionToFailure(e));
    } catch (e) {
      return (false, null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, String?, AppFailure?)> simulateQrisPayment({
    required int paymentId,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.simulatePayEndpoint(paymentId),
      );

      final raw = response.data;
      final message = raw is Map<String, dynamic>
          ? (raw['message'] as String? ?? 'Simulasi pembayaran berhasil')
          : 'Simulasi pembayaran berhasil';
      return (true, message, null);
    } on DioException catch (e) {
      return (false, null, mapDioExceptionToFailure(e));
    } catch (e) {
      return (false, null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<SaleRecord>?, AppFailure?)> getSales({
    int? outletId,
    String? startDate,
    String? endDate,
    String? status,
    int page = 1,
    int perPage = 50,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'per_page': perPage,
    };
    if (outletId != null && outletId > 0) {
      queryParams['outlet_id'] = outletId;
    }
    if (startDate != null && startDate.isNotEmpty) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      queryParams['end_date'] = endDate;
    }
    if (status != null &&
        status.isNotEmpty &&
        status.toUpperCase() != 'SEMUA' &&
        status.toUpperCase() != 'SEMUA STATUS') {
      queryParams['status'] = status.toUpperCase();
    }

    try {
      final response = await _dio.get(
        AppConstants.salesEndpoint,
        queryParameters: queryParams,
      );

      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['data'] is List) {
        final list = (raw['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) {
          final dto = CheckoutResponseDto.fromJson(item);
          final pm = dto.paymentMethod.toUpperCase().contains('QRIS')
              ? PaymentMethod.qris
              : PaymentMethod.cash;
          return SaleRecord(
            id: dto.saleId,
            invoiceNumber: dto.transactionNo,
            terminalCode: dto.outletName,
            cashierName: dto.cashierName,
            createdAt: dto.createdAt,
            paymentMethod: pm,
            status: (dto.status.toUpperCase() == 'COMPLETED' ||
                    dto.paymentStatus.toUpperCase() == 'PAID')
                ? TransactionStatus.completed
                : (dto.status.toUpperCase() == 'CANCELLED'
                    ? TransactionStatus.cancelled
                    : TransactionStatus.pending),
            items: dto.items.map((e) => e.toEntity()).toList(),
            totalAmount: dto.totalAmount,
            amountPaid: dto.paidAmount,
            changeAmount: dto.changeAmount,
          );
        }).toList();
        return (list, null);
      }

      return (const <SaleRecord>[], null);
    } on DioException catch (e) {
      return (null, mapDioExceptionToFailure(e));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}

/// Provider lazy singleton untuk [PosRepository].
final posRepositoryProvider = Provider<PosRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return PosRepositoryImpl(dio);
});
