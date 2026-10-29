import 'package:equatable/equatable.dart';
import 'package:pos_apps_umkm/domain/entities/pos_entities.dart';

/// DTO untuk item pesanan checkout kasir (`#/definitions/service.CheckoutItemRequest`).
class CheckoutItemRequestDto {
  final int productId;
  final int quantity;

  const CheckoutItemRequestDto({
    required this.productId,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'quantity': quantity,
      };
}

/// DTO untuk request body checkout kasir (`#/definitions/service.CheckoutRequest`).
class CheckoutRequestDto {
  final int outletId;
  final String paymentMethod; // "CASH" atau "QRIS"
  final int? cashReceived;
  final String receiptFormat; // "A" atau "B"
  final List<CheckoutItemRequestDto> items;

  const CheckoutRequestDto({
    required this.outletId,
    required this.paymentMethod,
    this.cashReceived,
    this.receiptFormat = 'A',
    required this.items,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'outlet_id': outletId,
      'payment_method': paymentMethod,
      'receipt_format': receiptFormat,
      'items': items.map((e) => e.toJson()).toList(),
    };
    if (cashReceived != null && cashReceived! > 0) {
      map['cash_received'] = cashReceived;
    }
    return map;
  }
}

/// DTO untuk response checkout kasir (`#/definitions/service.CheckoutResponse`).
class CheckoutResponseDto extends Equatable {
  final int saleId;
  final String transactionNo;
  final String outletName;
  final String cashierName;
  final List<SaleItemResponseDto> items;
  final int subtotal;
  final int discountAmount;
  final int taxAmount;
  final int totalAmount;
  final int paidAmount;
  final int changeAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final String receiptFormat;
  final DateTime createdAt;

  const CheckoutResponseDto({
    required this.saleId,
    required this.transactionNo,
    required this.outletName,
    required this.cashierName,
    required this.items,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.receiptFormat,
    required this.createdAt,
  });

  factory CheckoutResponseDto.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List? ?? const [];
    return CheckoutResponseDto(
      saleId: json['sale_id'] as int? ?? json['id'] as int? ?? 0,
      transactionNo: (json['transaction_no'] as String?) ??
          (json['invoice_no'] as String?) ??
          'TRX-${DateTime.now().millisecondsSinceEpoch}',
      outletName: json['outlet_name'] as String? ?? 'Outlet Utama',
      cashierName: json['cashier_name'] as String? ?? 'Kasir',
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(SaleItemResponseDto.fromJson)
          .toList(),
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      discountAmount: (json['discount_amount'] as num?)?.toInt() ?? 0,
      taxAmount: (json['tax_amount'] as num?)?.toInt() ?? 0,
      totalAmount: (json['total_amount'] as num?)?.toInt() ?? 0,
      paidAmount: (json['paid_amount'] as num?)?.toInt() ?? 0,
      changeAmount: (json['change_amount'] as num?)?.toInt() ?? 0,
      paymentMethod: json['payment_method'] as String? ?? 'CASH',
      paymentStatus: json['payment_status'] as String? ?? 'PAID',
      status: json['status'] as String? ?? 'COMPLETED',
      receiptFormat: json['receipt_format'] as String? ?? 'A',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  CheckoutResult toEntity() {
    return CheckoutResult(
      saleId: saleId,
      transactionNo: transactionNo,
      outletName: outletName,
      cashierName: cashierName,
      items: items.map((e) => e.toEntity()).toList(),
      subtotal: subtotal,
      discountAmount: discountAmount,
      taxAmount: taxAmount,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      changeAmount: changeAmount,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus,
      status: status,
      receiptFormat: receiptFormat,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        saleId,
        transactionNo,
        outletName,
        cashierName,
        items,
        subtotal,
        discountAmount,
        taxAmount,
        totalAmount,
        paidAmount,
        changeAmount,
        paymentMethod,
        paymentStatus,
        status,
        receiptFormat,
        createdAt,
      ];
}

/// DTO untuk item transaksi penjualan (`#/definitions/service.SaleItemResponse`).
class SaleItemResponseDto extends Equatable {
  final int productId;
  final String productName;
  final String sku;
  final int unitPrice;
  final int quantity;
  final int subtotal;

  const SaleItemResponseDto({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory SaleItemResponseDto.fromJson(Map<String, dynamic> json) {
    return SaleItemResponseDto(
      productId: json['product_id'] as int? ?? 0,
      productName: json['product_name'] as String? ?? 'Produk',
      sku: json['sku'] as String? ?? '',
      unitPrice: (json['unit_price'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
    );
  }

  SaleItemRecord toEntity() {
    return SaleItemRecord(
      productId: productId,
      sku: sku,
      productName: productName,
      unitPrice: unitPrice,
      qty: quantity,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        sku,
        unitPrice,
        quantity,
        subtotal,
      ];
}

/// DTO untuk inisiasi pembayaran QRIS dinamis (`#/definitions/service.InitiateQRISResponse`).
class InitiateQrisResponseDto extends Equatable {
  final int paymentId;
  final int saleId;
  final int amount;
  final String status;
  final String? qrPayload;
  final String? qrUrl;
  final DateTime? expiresAt;
  final String? providerReference;

  const InitiateQrisResponseDto({
    required this.paymentId,
    required this.saleId,
    required this.amount,
    required this.status,
    this.qrPayload,
    this.qrUrl,
    this.expiresAt,
    this.providerReference,
  });

  factory InitiateQrisResponseDto.fromJson(Map<String, dynamic> json) {
    return InitiateQrisResponseDto(
      paymentId: json['payment_id'] as int? ?? json['id'] as int? ?? 0,
      saleId: json['sale_id'] as int? ?? 0,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'PENDING',
      qrPayload: json['qr_payload'] as String?,
      qrUrl: json['qr_url'] as String?,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String)
          : null,
      providerReference: json['provider_reference'] as String?,
    );
  }

  QrisPaymentInfo toEntity() {
    return QrisPaymentInfo(
      paymentId: paymentId,
      saleId: saleId,
      amount: amount,
      status: status,
      qrPayload: qrPayload,
      qrUrl: qrUrl,
      expiresAt: expiresAt,
      providerReference: providerReference,
    );
  }

  @override
  List<Object?> get props => [
        paymentId,
        saleId,
        amount,
        status,
        qrPayload,
        qrUrl,
        expiresAt,
        providerReference,
      ];
}
