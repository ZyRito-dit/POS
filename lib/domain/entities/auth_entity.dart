import 'package:equatable/equatable.dart';

/// Domain entity representing an authenticated user's token pair.
/// Pure Dart - no JSON/serialization annotations here.
class AuthToken extends Equatable {
  final String accessToken;
  final String tokenType;
  final String? refreshToken;
  final int? expiresIn;
  final UserProfile? user;

  const AuthToken({
    required this.accessToken,
    required this.tokenType,
    this.refreshToken,
    this.expiresIn,
    this.user,
  });

  String get authorizationHeader => '${_capitalize(tokenType)} $accessToken';

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  @override
  List<Object?> get props => [
        accessToken,
        tokenType,
        refreshToken,
        expiresIn,
        user,
      ];
}

/// Domain entity representing an authenticated user's profile.
class UserProfile extends Equatable {
  final int id;
  final String username;
  final String? email;
  final String? fullName;
  final bool isActive;
  final String? role;
  final int? tenantId;
  final int? outletId;

  const UserProfile({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    required this.isActive,
    this.role,
    this.tenantId,
    this.outletId,
  });

  String get displayName => fullName?.isNotEmpty == true ? fullName! : username;

  UserProfile copyWith({
    int? id,
    String? username,
    String? email,
    String? fullName,
    bool? isActive,
    String? role,
    int? tenantId,
    int? outletId,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      isActive: isActive ?? this.isActive,
      role: role ?? this.role,
      tenantId: tenantId ?? this.tenantId,
      outletId: outletId ?? this.outletId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        fullName,
        isActive,
        role,
        tenantId,
        outletId,
      ];
}

/// Domain entity representing a business branch or physical outlet.
/// Matches KatoPOS API `domain.Outlet`.
class Outlet extends Equatable {
  final int id;
  final int tenantId;
  final String code;
  final String name;
  final String? address;
  final String? phone;
  final String? timezone;
  final String? status;
  final String? logoUrl;
  final int totalCashiers;

  const Outlet({
    required this.id,
    required this.tenantId,
    required this.code,
    required this.name,
    this.address,
    this.phone,
    this.timezone,
    this.status = 'ACTIVE',
    this.logoUrl,
    this.totalCashiers = 0,
  });

  bool get isActive => status?.toUpperCase() == 'ACTIVE';

  Outlet copyWith({
    int? id,
    int? tenantId,
    String? code,
    String? name,
    String? address,
    String? phone,
    String? timezone,
    String? status,
    String? logoUrl,
    int? totalCashiers,
  }) {
    return Outlet(
      id: id ?? this.id,
      tenantId: tenantId ?? this.tenantId,
      code: code ?? this.code,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      timezone: timezone ?? this.timezone,
      status: status ?? this.status,
      logoUrl: logoUrl ?? this.logoUrl,
      totalCashiers: totalCashiers ?? this.totalCashiers,
    );
  }

  @override
  List<Object?> get props => [
        id,
        tenantId,
        code,
        name,
        address,
        phone,
        timezone,
        status,
        logoUrl,
        totalCashiers,
      ];
}
