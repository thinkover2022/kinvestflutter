import '../widgets/login_settings_dialog.dart';

class UserProfile {
  final String email;
  final String appKey;
  final String appSecret;
  final bool isRealAccount;
  final DataSourceType dataSource;
  final DateTime createdAt;
  final DateTime lastLoginAt;

  UserProfile({
    required this.email,
    required this.appKey,
    required this.appSecret,
    required this.isRealAccount,
    required this.dataSource,
    required this.createdAt,
    required this.lastLoginAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      email: json['email'] as String,
      appKey: json['appKey'] as String,
      appSecret: json['appSecret'] as String,
      isRealAccount: json['isRealAccount'] as bool,
      dataSource: DataSourceType.values.firstWhere(
        (e) => e.name == (json['dataSource'] as String? ?? 'https'),
        orElse: () => DataSourceType.https,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: DateTime.parse(json['lastLoginAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'appKey': appKey,
      'appSecret': appSecret,
      'isRealAccount': isRealAccount,
      'dataSource': dataSource.name,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? email,
    String? appKey,
    String? appSecret,
    bool? isRealAccount,
    DataSourceType? dataSource,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserProfile(
      email: email ?? this.email,
      appKey: appKey ?? this.appKey,
      appSecret: appSecret ?? this.appSecret,
      isRealAccount: isRealAccount ?? this.isRealAccount,
      dataSource: dataSource ?? this.dataSource,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  String get maskedAppKey {
    if (appKey.length <= 8) {
      return appKey.replaceRange(4, appKey.length, '*' * (appKey.length - 4));
    }
    return '${appKey.substring(0, 4)}${'*' * (appKey.length - 8)}${appKey.substring(appKey.length - 4)}';
  }

  String get maskedAppSecret {
    if (appSecret.length <= 8) {
      return appSecret.replaceRange(4, appSecret.length, '*' * (appSecret.length - 4));
    }
    return '${appSecret.substring(0, 4)}${'*' * (appSecret.length - 8)}${appSecret.substring(appSecret.length - 4)}';
  }

  String get displayName => email;
  String get accountType => isRealAccount ? '실전계좌' : '모의계좌';
  String get dataSourceDisplayName => dataSource.displayName;
}