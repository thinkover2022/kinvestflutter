import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class KisAuthService {
  static const String _realUrl = 'https://openapi.koreainvestment.com:9443';
  static const String _mockUrl = 'https://openapivts.koreainvestment.com:29443';

  final String appKey;
  final String appSecret;
  final bool isRealAccount;

  String? _approvalKey;
  String? _accessToken;
  DateTime? _tokenExpiry;

  KisAuthService({
    required this.appKey,
    required this.appSecret,
    this.isRealAccount = false,
  });

  String get baseUrl => isRealAccount ? _realUrl : _mockUrl;
  String? get approvalKey => _approvalKey;
  String? get accessToken => _accessToken;

  Future<String> getApprovalKey() async {
    if (_approvalKey != null) {
      return _approvalKey!;
    }

    final url = Uri.parse('$baseUrl/oauth2/Approval');
    final headers = {'Content-Type': 'application/json;charset=utf-8'};
    final body = json.encode({
      'grant_type': 'client_credentials',
      'appkey': appKey,
      'secretkey': appSecret,
    });

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _approvalKey = responseData['approval_key'];
        return _approvalKey!;
      } else {
        throw Exception('Failed to get approval key: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting approval key: $e');
    }
  }

  Future<String> getAccessToken() async {
    // 먼저 저장된 토큰이 있는지 확인
    await _loadStoredToken();
    
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      print('기존 Access Token 재사용: 만료시간 ${_tokenExpiry!}');
      return _accessToken!;
    }

    print('새로운 Access Token 발급 요청 (기존 토큰 만료 또는 없음)');
    final url = Uri.parse('$baseUrl/oauth2/tokenP');
    final headers = {'Content-Type': 'application/json'};
    final body = json.encode({
      'grant_type': 'client_credentials',
      'appkey': appKey,
      'appsecret': appSecret,
    });

    try {
      await Future.delayed(const Duration(milliseconds: 50));
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _accessToken = responseData['access_token'];

        final expiresIn = responseData['expires_in'] as int? ?? 7200;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 300));

        // 토큰을 영구 저장
        await _saveToken();
        
        print('새 Access Token 발급 완료: 만료시간 ${_tokenExpiry!}');
        return _accessToken!;
      } else {
        throw Exception('Failed to get access token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting access token: $e');
    }
  }

  Future<void> _loadStoredToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString('access_token_${appKey}');
      final storedExpiry = prefs.getString('token_expiry_${appKey}');
      
      if (storedToken != null && storedExpiry != null) {
        _accessToken = storedToken;
        _tokenExpiry = DateTime.parse(storedExpiry);
        print('저장된 Access Token 로드됨: 만료시간 ${_tokenExpiry!}');
      }
    } catch (e) {
      print('저장된 토큰 로드 실패: $e');
    }
  }

  Future<void> _saveToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null && _tokenExpiry != null) {
        await prefs.setString('access_token_${appKey}', _accessToken!);
        await prefs.setString('token_expiry_${appKey}', _tokenExpiry!.toIso8601String());
        print('Access Token 저장 완료');
      }
    } catch (e) {
      print('토큰 저장 실패: $e');
    }
  }

  Future<void> initialize() async {
    await getApprovalKey();
  }

  bool get isAuthenticated => _approvalKey != null;

  Future<void> clearAuthentication() async {
    _approvalKey = null;
    _accessToken = null;
    _tokenExpiry = null;
    
    // 저장된 토큰도 삭제
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token_${appKey}');
      await prefs.remove('token_expiry_${appKey}');
      print('저장된 Access Token 삭제 완료');
    } catch (e) {
      print('저장된 토큰 삭제 실패: $e');
    }
  }

  // 토큰 상태 확인용 메서드
  Future<Map<String, dynamic>> getTokenStatus() async {
    await _loadStoredToken();
    
    return {
      'hasToken': _accessToken != null,
      'isValid': _accessToken != null && 
                 _tokenExpiry != null && 
                 DateTime.now().isBefore(_tokenExpiry!),
      'expiryTime': _tokenExpiry?.toIso8601String(),
      'remainingTime': _tokenExpiry != null 
          ? _tokenExpiry!.difference(DateTime.now()).inMinutes
          : 0,
    };
  }
}
