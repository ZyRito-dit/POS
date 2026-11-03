import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos_apps_umkm/core/constants/app_constants.dart';
import 'package:pos_apps_umkm/core/errors/app_failure.dart';
import 'package:pos_apps_umkm/core/errors/error_mapper.dart';
import 'package:pos_apps_umkm/core/network/dio_provider.dart';
import 'package:pos_apps_umkm/data/models/auth_dto.dart';
import 'package:pos_apps_umkm/domain/entities/auth_entity.dart';
import 'package:pos_apps_umkm/domain/repositories/auth_repository.dart';

/// Concrete HTTP implementation of [AuthRepository].
/// All Dio, JSON, and storage concerns are confined to this file.
class AuthRepositoryImpl implements AuthRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  const AuthRepositoryImpl(this._dio, this._storage);

  @override
  Future<(AuthToken?, AppFailure?)> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: LoginRequestDto(email: email, password: password).toJson(),
        // Avoid attaching stale tokens during login
        options: Options(headers: {'Authorization': null}),
      );

      final rawData = response.data;
      if (rawData is! Map<String, dynamic>) {
        return (null, const ServerFailure('Format respon dari server tidak valid.'));
      }

      final dto = TokenResponseDto.fromJson(rawData);

      // Persist token to secure storage after successful authentication
      await Future.wait([
        _storage.write(key: AppConstants.tokenKey, value: dto.accessToken),
        _storage.write(key: AppConstants.tokenTypeKey, value: dto.tokenType),
      ]);

      UserProfile? userProfile;
      if (dto.user != null) {
        userProfile = UserProfile(
          id: dto.user!.id,
          username: dto.user!.name,
          email: email,
          fullName: dto.user!.name,
          isActive: true,
          role: dto.user!.role,
          tenantId: dto.user!.tenantId,
          outletId: dto.user!.outletId,
        );
      }

      final token = AuthToken(
        accessToken: dto.accessToken,
        tokenType: dto.tokenType,
        refreshToken: dto.refreshToken,
        expiresIn: dto.expiresIn,
        user: userProfile,
      );
      return (token, null);
    } on DioException catch (e) {
      return (null, mapDioExceptionToFailure(e));
    } catch (_) {
      return (null, const UnknownFailure());
    }
  }

  @override
  Future<(UserProfile?, AppFailure?)> register({
    required String username,
    required String password,
    required String email,
    String? fullName,
  }) async {
    try {
      final response = await _dio.post(
        AppConstants.createUserEndpoint,
        data: UserCreateDto(
          username: username,
          password: password,
          email: email,
          fullName: fullName,
        ).toJson(),
      );

      final dto = UserProfileDto.fromJson(response.data as Map<String, dynamic>);
      final profile = _mapDtoToProfile(dto);
      return (profile, null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        return (
          null,
          const ServerFailure(
            'Endpoint ini memerlukan hak akses admin. Pastikan kamu sudah login sebagai admin.',
          ),
        );
      }
      return (null, mapDioExceptionToFailure(e));
    } catch (_) {
      return (null, const UnknownFailure());
    }
  }

  @override
  Future<(UserProfile?, AppFailure?)> getCurrentUser() async {
    try {
      final response = await _dio.get(AppConstants.meEndpoint);
      final dto = UserProfileDto.fromJson(response.data as Map<String, dynamic>);
      return (_mapDtoToProfile(dto), null);
    } on DioException catch (e) {
      return (null, mapDioExceptionToFailure(e));
    } catch (_) {
      return (null, const UnknownFailure());
    }
  }

  @override
  Future<(List<Outlet>?, AppFailure?)> getAccessibleOutlets() async {
    try {
      final response = await _dio.get(AppConstants.meOutletsEndpoint);
      final raw = response.data;
      if (raw is Map<String, dynamic> && raw['data'] is List) {
        final list = (raw['data'] as List)
            .whereType<Map<String, dynamic>>()
            .map((item) => OutletDto.fromJson(item).toEntity())
            .toList();
        return (list, null);
      }
      return (const <Outlet>[], null);
    } on DioException catch (e) {
      return (null, mapDioExceptionToFailure(e));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<void> logout() async {
    await Future.wait([
      _storage.delete(key: AppConstants.tokenKey),
      _storage.delete(key: AppConstants.tokenTypeKey),
    ]);
  }

  @override
  Future<bool> hasValidSession() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  UserProfile _mapDtoToProfile(UserProfileDto dto) => UserProfile(
        id: dto.id,
        username: dto.username,
        email: dto.email,
        fullName: dto.fullName,
        isActive: dto.isActive,
        role: dto.role,
        tenantId: dto.tenantId,
        outletId: dto.outletId,
      );
}

/// Riverpod provider for [AuthRepository].
/// Presentation layer injects this - never the concrete class directly.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  );
});
