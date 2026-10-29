import 'package:equatable/equatable.dart';

/// Domain entity representing an authenticated user's token pair.
/// Pure Dart — no JSON/serialization annotations here.
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
