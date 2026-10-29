// Data Transfer Objects for the KatoPOS auth API.
// Based on Swagger specification: POST /api/v1/auth/login and user profile endpoints.

class LoginRequestDto {
  final String email;
  final String password;

  const LoginRequestDto({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class LoginUserDataDto {
  final int id;
  final String name;
  final String role;
  final int? tenantId;
  final int? outletId;

  const LoginUserDataDto({
    required this.id,
    required this.name,
    required this.role,
    this.tenantId,
    this.outletId,
  });

  factory LoginUserDataDto.fromJson(Map<String, dynamic> json) =>
      LoginUserDataDto(
        id: (json['id'] as num).toInt(),
        name: (json['name'] as String?) ?? '',
        role: (json['role'] as String?) ?? '',
        tenantId: (json['tenant_id'] as num?)?.toInt(),
        outletId: (json['outlet_id'] as num?)?.toInt(),
      );
}

class TokenResponseDto {
  final String accessToken;
  final String tokenType;
  final String? refreshToken;
  final int? expiresIn;
  final LoginUserDataDto? user;

  const TokenResponseDto({
    required this.accessToken,
    required this.tokenType,
    this.refreshToken,
    this.expiresIn,
    this.user,
  });

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) {
    // Support both wrapped response { success: true, data: { ... } } and direct map
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    return TokenResponseDto(
      accessToken: (data['access_token'] as String?) ?? '',
      tokenType: (data['token_type'] as String?) ?? 'Bearer',
      refreshToken: data['refresh_token'] as String?,
      expiresIn: (data['expires_in'] as num?)?.toInt(),
      user: data['user'] is Map<String, dynamic>
          ? LoginUserDataDto.fromJson(data['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserCreateDto {
  final String username;
  final String password;
  final String email;
  final String? fullName;

  const UserCreateDto({
    required this.username,
    required this.password,
    required this.email,
    this.fullName,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'username': username,
      'password': password,
      'email': email,
    };
    if (fullName != null && fullName!.isNotEmpty) {
      map['full_name'] = fullName;
    }
    return map;
  }
}

class UserProfileDto {
  final int id;
  final String username;
  final String? email;
  final String? fullName;
  final bool isActive;
  final String? role;
  final int? tenantId;
  final int? outletId;

  const UserProfileDto({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    required this.isActive,
    this.role,
    this.tenantId,
    this.outletId,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    return UserProfileDto(
      id: (data['id'] as num).toInt(),
      username: (data['username'] as String?) ??
          (data['name'] as String?) ??
          (data['email'] as String?) ??
          '',
      email: data['email'] as String?,
      fullName: (data['name'] as String?) ?? (data['full_name'] as String?),
      isActive: (data['status'] as String?) == 'ACTIVE' ||
          (data['is_active'] as bool? ?? true),
      role: (data['role'] as String?) ??
          (data['roles'] is List && (data['roles'] as List).isNotEmpty
              ? ((data['roles'] as List).first is Map
                  ? ((data['roles'] as List).first['code'] as String?)
                  : (data['roles'] as List).first.toString())
              : null),
      tenantId: (data['tenant_id'] as num?)?.toInt(),
      outletId: (data['outlet_id'] as num?)?.toInt(),
    );
  }
}
