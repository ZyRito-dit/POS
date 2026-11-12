import 'package:equatable/equatable.dart';

enum PaymentMethod {
  cash('CASH', 'Tunai (Kasir)'),
  qris('QRIS', 'QRIS Dinamis');

  final String code;
  final String label;
  const PaymentMethod(this.code, this.label);
}

enum TransactionStatus {
  completed('completed', 'Selesai'),
  pending('pending', 'Menunggu'),
  cancelled('cancelled', 'Dibatalkan');

  final String code;
  final String label;
  const TransactionStatus(this.code, this.label);
}

enum NotificationSeverity {
  info,
  warning,
  error,
  success,
}

class ProductCategory extends Equatable {
  final int id;
  final String name;

  const ProductCategory({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];
}

class PosProduct extends Equatable {
  final int id;
  final String sku;
  final String name;
  final int basePrice;
  final int categoryId;
  final String categoryName;
  final int stock;
  final String description;
  final String packagingInfo;
  final String imageUrl;
  final int outletId;

  const PosProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.basePrice,
    required this.categoryId,
    required this.categoryName,
    required this.stock,
    required this.description,
    required this.packagingInfo,
    required this.imageUrl,
    this.outletId = 1,
  });

  bool get isOutOfStock => stock <= 0;
  bool get isLowStock => stock > 0 && stock <= 5;

  PosProduct copyWith({
    int? id,
    String? sku,
    String? name,
    int? basePrice,
    int? categoryId,
    String? categoryName,
    int? stock,
    String? description,
    String? packagingInfo,
    String? imageUrl,
    int? outletId,
  }) {
    return PosProduct(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      stock: stock ?? this.stock,
      description: description ?? this.description,
      packagingInfo: packagingInfo ?? this.packagingInfo,
      imageUrl: imageUrl ?? this.imageUrl,
      outletId: outletId ?? this.outletId,
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
        description,
        packagingInfo,
        imageUrl,
        outletId,
      ];
}

class CartItem extends Equatable {
  final PosProduct product;
  final int qty;

  const CartItem({
    required this.product,
    required this.qty,
  });

  int get subtotal => product.basePrice * qty;

  CartItem copyWith({
    PosProduct? product,
    int? qty,
  }) {
    return CartItem(
      product: product ?? this.product,
      qty: qty ?? this.qty,
    );
  }

  @override
  List<Object?> get props => [product, qty];
}

class SaleItemRecord extends Equatable {
  final int productId;
  final String sku;
  final String productName;
  final int unitPrice;
  final int qty;

  const SaleItemRecord({
    required this.productId,
    required this.sku,
    required this.productName,
    required this.unitPrice,
    required this.qty,
  });

  int get subtotal => unitPrice * qty;

  @override
  List<Object?> get props => [productId, sku, productName, unitPrice, qty];
}

class SaleRecord extends Equatable {
  final int id;
  final String invoiceNumber;
  final String terminalCode;
  final String cashierName;
  final DateTime createdAt;
  final PaymentMethod paymentMethod;
  final TransactionStatus status;
  final List<SaleItemRecord> items;
  final int totalAmount;
  final int amountPaid;
  final int changeAmount;

  const SaleRecord({
    required this.id,
    required this.invoiceNumber,
    required this.terminalCode,
    required this.cashierName,
    required this.createdAt,
    required this.paymentMethod,
    required this.status,
    required this.items,
    required this.totalAmount,
    required this.amountPaid,
    required this.changeAmount,
  });

  int get totalQty => items.fold(0, (sum, item) => sum + item.qty);

  SaleRecord copyWith({
    TransactionStatus? status,
    int? amountPaid,
    int? changeAmount,
  }) {
    return SaleRecord(
      id: id,
      invoiceNumber: invoiceNumber,
      terminalCode: terminalCode,
      cashierName: cashierName,
      createdAt: createdAt,
      paymentMethod: paymentMethod,
      status: status ?? this.status,
      items: items,
      totalAmount: totalAmount,
      amountPaid: amountPaid ?? this.amountPaid,
      changeAmount: changeAmount ?? this.changeAmount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        terminalCode,
        cashierName,
        createdAt,
        paymentMethod,
        status,
        items,
        totalAmount,
        amountPaid,
        changeAmount,
      ];
}

class SystemNotification extends Equatable {
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final NotificationSeverity severity;
  final String? type;
  final String? referenceType;
  final int? referenceId;
  final DateTime? readAt;

  const SystemNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.severity,
    this.type,
    this.referenceType,
    this.referenceId,
    this.readAt,
  });

  SystemNotification copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return SystemNotification(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      severity: severity,
      type: type,
      referenceType: referenceType,
      referenceId: referenceId,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        message,
        createdAt,
        isRead,
        severity,
        type,
        referenceType,
        referenceId,
        readAt,
      ];
}

class PosTerminalInfo extends Equatable {
  final int id;
  final String machineCode;
  final String name;
  final String locationName;
  final String status;
  final String paymentGateway;
  final String printerStatus;
  final DateTime lastSync;

  const PosTerminalInfo({
    required this.id,
    required this.machineCode,
    required this.name,
    required this.locationName,
    required this.status,
    required this.paymentGateway,
    required this.printerStatus,
    required this.lastSync,
  });

  @override
  List<Object?> get props => [
        id,
        machineCode,
        name,
        locationName,
        status,
        paymentGateway,
        printerStatus,
        lastSync,
      ];
}

/// Hasil eksekusi checkout transaksi kasir dari API backend (`/api/v1/pos/checkout`).
class CheckoutResult extends Equatable {
  final int saleId;
  final String transactionNo;
  final String outletName;
  final String cashierName;
  final List<SaleItemRecord> items;
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

  const CheckoutResult({
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

  SaleRecord toSaleRecord({required PaymentMethod method}) {
    return SaleRecord(
      id: saleId,
      invoiceNumber: transactionNo,
      terminalCode: outletName,
      cashierName: cashierName,
      createdAt: createdAt,
      paymentMethod: method,
      status: paymentStatus.toUpperCase() == 'PAID'
          ? TransactionStatus.completed
          : TransactionStatus.pending,
      items: items,
      totalAmount: totalAmount,
      amountPaid: paidAmount,
      changeAmount: changeAmount,
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

/// Informasi pembayaran QRIS dinamis dari API backend (`/api/v1/sales/{sale_id}/payments/qris`).
class QrisPaymentInfo extends Equatable {
  final int paymentId;
  final int saleId;
  final int amount;
  final String status;
  final String? qrPayload;
  final String? qrUrl;
  final DateTime? expiresAt;
  final String? providerReference;

  const QrisPaymentInfo({
    required this.paymentId,
    required this.saleId,
    required this.amount,
    required this.status,
    this.qrPayload,
    this.qrUrl,
    this.expiresAt,
    this.providerReference,
  });

  bool get isPaid => status.toUpperCase() == 'PAID';
  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isExpired => status.toUpperCase() == 'EXPIRED';

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

/// Entitas status konektivitas terminal POS (`/api/v1/pos/ping`).
class PosConnectivity extends Equatable {
  final String status;
  final bool isOnline;
  final int cashierId;
  final String cashierName;
  final int outletId;
  final String outletName;
  final DateTime serverTime;
  final String friendlyMessage;

  const PosConnectivity({
    required this.status,
    required this.isOnline,
    required this.cashierId,
    required this.cashierName,
    required this.outletId,
    required this.outletName,
    required this.serverTime,
    required this.friendlyMessage,
  });

  factory PosConnectivity.initial() {
    return PosConnectivity(
      status: 'ONLINE',
      isOnline: true,
      cashierId: 0,
      cashierName: '',
      outletId: 0,
      outletName: '',
      serverTime: DateTime.now(),
      friendlyMessage: 'Perangkat kasir terhubung secara online',
    );
  }

  factory PosConnectivity.fromJson(Map<String, dynamic> json) {
    return PosConnectivity(
      status: json['status'] as String? ??
          (json['is_online'] == false ? 'OFFLINE' : 'ONLINE'),
      isOnline: json['is_online'] as bool? ??
          (json['status']?.toString().toUpperCase() == 'ONLINE'),
      cashierId: json['cashier_id'] as int? ?? 0,
      cashierName: json['cashier_name'] as String? ?? '',
      outletId: json['outlet_id'] as int? ?? 0,
      outletName: json['outlet_name'] as String? ?? '',
      serverTime:
          DateTime.tryParse(json['server_time'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      friendlyMessage: json['friendly_message'] as String? ??
          (json['is_online'] == false
              ? 'Perangkat kasir offline'
              : 'Perangkat kasir terhubung secara online'),
    );
  }

  PosConnectivity copyWith({
    String? status,
    bool? isOnline,
    int? cashierId,
    String? cashierName,
    int? outletId,
    String? outletName,
    DateTime? serverTime,
    String? friendlyMessage,
  }) {
    return PosConnectivity(
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      cashierId: cashierId ?? this.cashierId,
      cashierName: cashierName ?? this.cashierName,
      outletId: outletId ?? this.outletId,
      outletName: outletName ?? this.outletName,
      serverTime: serverTime ?? this.serverTime,
      friendlyMessage: friendlyMessage ?? this.friendlyMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        isOnline,
        cashierId,
        cashierName,
        outletId,
        outletName,
        serverTime,
        friendlyMessage,
      ];
}
