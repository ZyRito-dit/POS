/// Core application constants.
/// Single source of truth for all configuration values.
class AppConstants {
  AppConstants._();

  static const String baseUrl = 'http://157.20.32.181:8006';
  static const String apiVersion = '/api/v1';
  static const String apiBaseUrl = '$baseUrl$apiVersion';

  // Auth endpoints (KatoPOS Backend API)
  static const String loginEndpoint = '/auth/login';
  static const String meEndpoint = '/auth/me';
  static const String meOutletsEndpoint = '/auth/me/outlets';
  static const String createUserEndpoint = '/auth/users';
  static const String outletsEndpoint = '/outlets';

  // POS, Sales & Payment endpoints (KatoPOS Backend API)
  static const String posCatalogEndpoint = '/pos/catalog';
  static const String categoriesEndpoint = '/categories';
  static const String productsEndpoint = '/products';
  static const String posCheckoutEndpoint = '/pos/checkout';
  static const String paymentMethodsEndpoint = '/payment-methods';
  static const String salesEndpoint = '/sales';
  static const String posPingEndpoint = '/pos/ping';

  static String saleDetailEndpoint(int saleId) => '/sales/$saleId';
  static String cancelSaleEndpoint(int saleId) => '/sales/$saleId/cancel';
  static String initiateQrisEndpoint(int saleId) => '/sales/$saleId/payments/qris';
  static String paymentStatusEndpoint(int paymentId) => '/payments/$paymentId';
  static String simulatePayEndpoint(int paymentId) => '/payments/$paymentId/simulate-pay';
  static String verifyPaymentEndpoint(int paymentId) => '/payments/$paymentId/verify';
  static String saleReceiptEndpoint(int saleId) => '/sales/$saleId/receipt';

  // Token & Session storage keys
  static const String tokenKey = 'nexsell_access_token';
  static const String tokenTypeKey = 'nexsell_token_type';
  static const String activeOutletIdKey = 'nexsell_active_outlet_id';
  static const String activeOutletNameKey = 'nexsell_active_outlet_name';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
