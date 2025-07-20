import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../widgets/login_settings_dialog.dart';

class StorageService {
  static const String _keyUserProfiles = 'user_profiles';
  static const String _keyLastLoginEmail = 'last_login_email';
  static const String _keyEncryptionKey = 'encryption_key';

  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // 간단한 XOR 암호화
  String _encrypt(String text, String key) {
    final textBytes = utf8.encode(text);
    final keyBytes = utf8.encode(key);
    final encrypted = <int>[];

    for (int i = 0; i < textBytes.length; i++) {
      encrypted.add(textBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return base64.encode(encrypted);
  }

  String _decrypt(String encryptedText, String key) {
    final encryptedBytes = base64.decode(encryptedText);
    final keyBytes = utf8.encode(key);
    final decrypted = <int>[];

    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    }

    return utf8.decode(decrypted);
  }

  String _generateEncryptionKey() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
          32, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  String _getOrCreateEncryptionKey() {
    String? key = _prefs?.getString(_keyEncryptionKey);
    if (key == null) {
      key = _generateEncryptionKey();
      _prefs?.setString(_keyEncryptionKey, key);
    }
    return key;
  }

  // 사용자 프로필 관련 메서드들
  Future<List<UserProfile>> getAllUserProfiles() async {
    await init();

    final encryptedData = _prefs?.getString(_keyUserProfiles);
    if (encryptedData == null) return [];

    try {
      final encryptionKey = _getOrCreateEncryptionKey();
      final decryptedData = _decrypt(encryptedData, encryptionKey);
      final jsonList = json.decode(decryptedData) as List;

      return jsonList.map((json) => UserProfile.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveAllUserProfiles(List<UserProfile> profiles) async {
    await init();

    final encryptionKey = _getOrCreateEncryptionKey();
    final jsonList = profiles.map((profile) => profile.toJson()).toList();
    final jsonData = json.encode(jsonList);
    final encryptedData = _encrypt(jsonData, encryptionKey);

    await _prefs?.setString(_keyUserProfiles, encryptedData);
  }

  Future<UserProfile?> getUserProfile(String email) async {
    final profiles = await getAllUserProfiles();
    return profiles.cast<UserProfile?>().firstWhere(
          (profile) => profile?.email.toLowerCase() == email.toLowerCase(),
          orElse: () => null,
        );
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final profiles = await getAllUserProfiles();

    // 기존 사용자 찾기
    final existingIndex = profiles.indexWhere(
      (p) => p.email.toLowerCase() == profile.email.toLowerCase(),
    );

    if (existingIndex >= 0) {
      // 기존 사용자 업데이트
      profiles[existingIndex] = profile.copyWith(lastLoginAt: DateTime.now());
    } else {
      // 새 사용자 추가
      profiles.add(profile.copyWith(
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      ));
    }

    await _saveAllUserProfiles(profiles);
    await setLastLoginEmail(profile.email);
  }

  Future<void> updateUserLastLogin(String email) async {
    final profile = await getUserProfile(email);
    if (profile != null) {
      await saveUserProfile(profile.copyWith(lastLoginAt: DateTime.now()));
    }
  }

  Future<void> deleteUserProfile(String email) async {
    final profiles = await getAllUserProfiles();
    profiles.removeWhere(
      (profile) => profile.email.toLowerCase() == email.toLowerCase(),
    );
    await _saveAllUserProfiles(profiles);

    // 마지막 로그인 이메일이 삭제된 사용자와 같다면 초기화
    final lastLoginEmail = await getLastLoginEmail();
    if (lastLoginEmail?.toLowerCase() == email.toLowerCase()) {
      await clearLastLoginEmail();
    }
  }

  Future<List<String>> getUserEmails() async {
    final profiles = await getAllUserProfiles();
    return profiles.map((profile) => profile.email).toList();
  }

  // 마지막 로그인 이메일 관련
  Future<void> setLastLoginEmail(String email) async {
    await init();
    await _prefs?.setString(_keyLastLoginEmail, email);
  }

  Future<String?> getLastLoginEmail() async {
    await init();
    return _prefs?.getString(_keyLastLoginEmail);
  }

  Future<void> clearLastLoginEmail() async {
    await init();
    await _prefs?.remove(_keyLastLoginEmail);
  }

  // 자동 로그인 관련
  Future<UserProfile?> getLastLoginUser() async {
    final lastEmail = await getLastLoginEmail();
    if (lastEmail == null) return null;
    return await getUserProfile(lastEmail);
  }

  Future<bool> hasStoredUsers() async {
    final profiles = await getAllUserProfiles();
    return profiles.isNotEmpty;
  }

  // 레거시 호환성을 위한 메서드들
  Future<Map<String, dynamic>?> loadCredentials() async {
    final lastUser = await getLastLoginUser();
    if (lastUser == null) return null;

    return {
      'appKey': lastUser.appKey,
      'appSecret': lastUser.appSecret,
      'isRealAccount': lastUser.isRealAccount,
      'email': lastUser.email,
    };
  }

  Future<void> saveCredentials({
    required String appKey,
    required String appSecret,
    required bool isRealAccount,
    required String email,
    bool autoLogin = true,
  }) async {
    final profile = UserProfile(
      email: email,
      appKey: appKey,
      appSecret: appSecret,
      isRealAccount: isRealAccount,
      dataSource: DataSourceType.https, // 기본값으로 HTTPS 사용
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await saveUserProfile(profile);
  }

  Future<bool> hasStoredCredentials() async {
    return await hasStoredUsers();
  }

  Future<void> clearCredentials() async {
    await clearLastLoginEmail();
  }

  Future<void> clearAllData() async {
    await init();
    await _prefs?.clear();
  }
}
