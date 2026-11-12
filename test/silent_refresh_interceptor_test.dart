import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_apps_umkm/core/constants/app_constants.dart';
import 'package:pos_apps_umkm/core/network/dio_provider.dart';

class _MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) handler;

  const _MockAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthTokenInterceptor - Silent 401 Auto-Refresh & Retry Tests', () {
    setUp(() {
      FlutterSecureStorage.setMockInitialValues({
        AppConstants.tokenKey: 'expired_access_token',
        AppConstants.refreshTokenKey: 'valid_refresh_token',
      });
    });

    test(
        '401 Unauthorized on protected endpoint automatically triggers /auth/refresh and retries successfully',
        () async {
      const storage = FlutterSecureStorage();
      int catalogRequestCount = 0;
      int refreshRequestCount = 0;
      String? lastCatalogAuthHeader;

      final mainDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
      final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

      mainDio.httpClientAdapter = _MockAdapter((options) async {
        if (options.path.contains('/pos/catalog')) {
          catalogRequestCount++;
          lastCatalogAuthHeader = options.headers['Authorization'] as String?;

          if (catalogRequestCount == 1) {
            // First attempt: Token is expired (401)
            return ResponseBody.fromString(
              jsonEncode({'message': 'Token expired'}),
              401,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          } else {
            // Second attempt after refresh: 200 OK
            return ResponseBody.fromString(
              jsonEncode({'data': []}),
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
        }
        return ResponseBody.fromString('Not Found', 404);
      });

      refreshDio.httpClientAdapter = _MockAdapter((options) async {
        if (options.path.contains(AppConstants.refreshTokenEndpoint)) {
          refreshRequestCount++;
          return ResponseBody.fromString(
            jsonEncode({
              'meta': {'code': 200, 'status': 'success'},
              'data': {
                'access_token': 'renewed_access_token_123',
                'token_type': 'Bearer',
                'refresh_token': 'renewed_refresh_token_456',
              },
            }),
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        return ResponseBody.fromString('Not Found', 404);
      });

      final interceptor = AuthTokenInterceptor(
        dio: mainDio,
        storage: storage,
        refreshDio: refreshDio,
      );
      mainDio.interceptors.add(interceptor);

      // Perform a catalog request that initially gets a 401
      final response = await mainDio.get('/pos/catalog');

      // Assertions
      expect(response.statusCode, 200);
      expect(catalogRequestCount, 2,
          reason: 'Initial request + 1 transparent retry');
      expect(refreshRequestCount, 1,
          reason: 'Silent refresh was called exactly once');
      expect(lastCatalogAuthHeader, 'Bearer renewed_access_token_123');

      // Secure storage should have the new tokens persisted
      final storedAccessToken = await storage.read(key: AppConstants.tokenKey);
      final storedRefreshToken =
          await storage.read(key: AppConstants.refreshTokenKey);
      expect(storedAccessToken, 'renewed_access_token_123');
      expect(storedRefreshToken, 'renewed_refresh_token_456');
    });

    test('401 on /auth/login does NOT trigger silent refresh loop', () async {
      const storage = FlutterSecureStorage();
      int refreshRequestCount = 0;

      final mainDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
      final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

      mainDio.httpClientAdapter = _MockAdapter((options) async {
        return ResponseBody.fromString(
          jsonEncode({'message': 'Invalid credentials'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      refreshDio.httpClientAdapter = _MockAdapter((options) async {
        refreshRequestCount++;
        return ResponseBody.fromString('{}', 200);
      });

      final interceptor = AuthTokenInterceptor(
        dio: mainDio,
        storage: storage,
        refreshDio: refreshDio,
      );
      mainDio.interceptors.add(interceptor);

      await expectLater(
        mainDio.post(AppConstants.loginEndpoint),
        throwsA(isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        )),
      );

      expect(refreshRequestCount, 0,
          reason: 'Login 401 should never trigger refresh token');
    });

    test('Already retried request does NOT trigger another refresh loop',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        AppConstants.tokenKey: 'stale_token_test3',
        AppConstants.refreshTokenKey: 'valid_refresh_token_test3',
      });
      const storage = FlutterSecureStorage();
      int refreshRequestCount = 0;
      int catalogRequestCount = 0;

      final mainDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
      final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

      mainDio.httpClientAdapter = _MockAdapter((options) async {
        catalogRequestCount++;
        return ResponseBody.fromString(
          jsonEncode({'message': 'Still Unauthorized'}),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      refreshDio.httpClientAdapter = _MockAdapter((options) async {
        refreshRequestCount++;
        return ResponseBody.fromString(
          jsonEncode({
            'data': {
              'access_token': 'new_token_test3',
              'token_type': 'Bearer',
            },
          }),
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final interceptor = AuthTokenInterceptor(
        dio: mainDio,
        storage: storage,
        refreshDio: refreshDio,
      );
      mainDio.interceptors.add(interceptor);

      await expectLater(
        mainDio.get('/pos/catalog'),
        throwsA(isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        )),
      );

      // Refresh was called once, retry was attempted once, then stopped cleanly without infinite loop
      expect(refreshRequestCount, 1);
      expect(catalogRequestCount, 2, reason: 'Initial request + 1 retry');
    });

    test(
        '401 with missing tenant_id claim does NOT trigger silent refresh loop',
        () async {
      FlutterSecureStorage.setMockInitialValues({
        AppConstants.tokenKey: 'valid_token_missing_claim',
        AppConstants.refreshTokenKey: 'valid_refresh_token',
      });
      const storage = FlutterSecureStorage();
      int refreshRequestCount = 0;
      int notificationsRequestCount = 0;

      final mainDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));
      final refreshDio = Dio(BaseOptions(baseUrl: AppConstants.apiBaseUrl));

      mainDio.httpClientAdapter = _MockAdapter((options) async {
        notificationsRequestCount++;
        return ResponseBody.fromString(
          jsonEncode({
            'success': false,
            'message': 'Tenant ID diperlukan dari token otentikasi',
            'error': {'code': 'UNAUTHORIZED'},
          }),
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      refreshDio.httpClientAdapter = _MockAdapter((options) async {
        refreshRequestCount++;
        return ResponseBody.fromString('{}', 200);
      });

      final interceptor = AuthTokenInterceptor(
        dio: mainDio,
        storage: storage,
        refreshDio: refreshDio,
      );
      mainDio.interceptors.add(interceptor);

      await expectLater(
        mainDio.get(AppConstants.notificationsEndpoint),
        throwsA(isA<DioException>().having(
          (e) => e.response?.statusCode,
          'statusCode',
          401,
        )),
      );

      // Invariant: Missing claims on the server cannot be solved by token renewal.
      // Zero token refresh calls should be initiated.
      expect(refreshRequestCount, 0,
          reason: 'Missing tenant claim must not trigger refresh loop');
      expect(notificationsRequestCount, 1,
          reason: 'Request should fail immediately without retry');
    });
  });
}
