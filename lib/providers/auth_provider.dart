import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/kis_auth_service.dart';
import '../services/kis_websocket_service.dart';
import '../services/storage_service.dart';
import '../models/user_profile.dart';
import '../widgets/login_settings_dialog.dart';
import '../utils/market_hours.dart';

class AuthState {
  final bool isLoggedIn;
  final UserProfile? currentUser;
  final String? error;
  final bool isLoading;
  final DataSourceType dataSource;

  const AuthState({
    this.isLoggedIn = false,
    this.currentUser,
    this.error,
    this.isLoading = false,
    this.dataSource = DataSourceType.https,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    UserProfile? currentUser,
    String? error,
    bool? isLoading,
    DataSourceType? dataSource,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentUser: currentUser ?? this.currentUser,
      error: error,
      isLoading: isLoading ?? this.isLoading,
      dataSource: dataSource ?? this.dataSource,
    );
  }

  // 하위 호환성을 위한 getter들
  String? get appKey => currentUser?.appKey;
  String? get appSecret => currentUser?.appSecret;
  bool get isRealAccount => currentUser?.isRealAccount ?? false;
  String? get email => currentUser?.email;
}

class AuthNotifier extends StateNotifier<AuthState> {
  KisAuthService? _authService;
  KisWebSocketService? _webSocketService;
  final StorageService _storageService = StorageService.instance;

  AuthNotifier() : super(const AuthState()) {
    _tryAutoLogin();
  }

  KisAuthService? get authService => _authService;
  KisWebSocketService? get webSocketService => _webSocketService;

  Future<void> _tryAutoLogin() async {
    try {
      final lastUser = await _storageService.getLastLoginUser();
      if (lastUser != null) {
        // 현재 시간에 맞는 최적 데이터 소스로 업데이트
        final optimalDataSource = MarketHours.getOptimalDataSource();
        final updatedUser = lastUser.copyWith(dataSource: optimalDataSource);
        await _performLoginWithUser(updatedUser, saveCredentials: false, dataSource: optimalDataSource);
      }
    } catch (e) {
      // 자동 로그인 실패 시 저장된 정보 삭제
      await _storageService.clearCredentials();
    }
  }

  Future<void> loginWithEmail(String email) async {
    final userProfile = await _storageService.getUserProfile(email);
    if (userProfile != null) {
      // 현재 시간에 맞는 최적 데이터 소스로 업데이트
      final optimalDataSource = MarketHours.getOptimalDataSource();
      final updatedProfile = userProfile.copyWith(dataSource: optimalDataSource);
      await _performLoginWithUser(updatedProfile, saveCredentials: false, dataSource: optimalDataSource);
    } else {
      throw Exception('사용자 정보를 찾을 수 없습니다');
    }
  }

  Future<void> loginWithCredentials({
    required String email,
    required String appKey,
    required String appSecret,
    required bool isRealAccount,
  }) async {
    // 시장 시간에 따라 자동으로 데이터 소스 선택
    final dataSource = MarketHours.getOptimalDataSource();
    
    final userProfile = UserProfile(
      email: email,
      appKey: appKey,
      appSecret: appSecret,
      isRealAccount: isRealAccount,
      dataSource: dataSource,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await _performLoginWithUser(userProfile, saveCredentials: true, dataSource: dataSource);
  }

  Future<void> _performLoginWithUser(UserProfile user, {bool saveCredentials = true, DataSourceType dataSource = DataSourceType.https}) async {
    state = state.copyWith(isLoading: true, error: null, dataSource: dataSource);

    try {
      // 1. KIS 인증 서비스 초기화
      _authService = KisAuthService(
        appKey: user.appKey,
        appSecret: user.appSecret,
        isRealAccount: user.isRealAccount,
      );

      await _authService!.initialize();

      // 2. 데이터 소스에 따른 연결 설정
      if (dataSource == DataSourceType.websocket) {
        // WebSocket 연결 시도 - 로그인 완료 조건
        _webSocketService = KisWebSocketService(_authService!);
        await _webSocketService!.connect();
        print('WebSocket 연결 완료');
      } else {
        // HTTPS 방식의 경우 WebSocket 연결 불필요
        print('HTTPS 방식 선택 - WebSocket 연결 생략');
      }

      // 3. 인증 성공 후 사용자 정보 저장
      if (saveCredentials) {
        await _storageService.saveUserProfile(user);
      } else {
        await _storageService.updateUserLastLogin(user.email);
      }

      // 4. 로그인 완료 상태로 변경
      state = state.copyWith(
        isLoggedIn: true,
        currentUser: user,
        isLoading: false,
        error: null,
        dataSource: dataSource,
      );
    } catch (e) {
      // 실패 시 정리
      await _webSocketService?.disconnect();
      _authService?.clearAuthentication();
      _authService = null;
      _webSocketService = null;
      
      state = state.copyWith(
        isLoggedIn: false,
        isLoading: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> logout({bool clearStoredCredentials = true}) async {
    // WebSocket 연결 해제
    await _webSocketService?.disconnect();
    _webSocketService = null;
    
    // 인증 정보 정리
    _authService?.clearAuthentication();
    _authService = null;
    
    if (clearStoredCredentials && state.currentUser != null) {
      await _storageService.deleteUserProfile(state.currentUser!.email);
    } else {
      await _storageService.clearLastLoginEmail();
    }
    
    state = const AuthState();
  }

  Future<bool> hasStoredCredentials() async {
    return await _storageService.hasStoredUsers();
  }

  Future<List<UserProfile>> getStoredUsers() async {
    return await _storageService.getAllUserProfiles();
  }

  Future<List<String>> getStoredUserEmails() async {
    return await _storageService.getUserEmails();
  }

  Future<void> deleteUser(String email) async {
    await _storageService.deleteUserProfile(email);
    
    // 현재 로그인된 사용자가 삭제된 경우 로그아웃
    if (state.currentUser?.email == email) {
      state = const AuthState();
    }
  }

  Future<void> clearAllStoredData() async {
    await _storageService.clearAllData();
    state = const AuthState();
  }
  
  // Public getters는 이미 위에 정의됨
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoggedIn;
});

final authServiceProvider = Provider<KisAuthService?>((ref) {
  return ref.watch(authProvider.notifier).authService;
});