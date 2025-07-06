import 'dart:convert';
import 'package:http/http.dart' as http;

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
      'secretKey': appSecret,
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
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken!;
    }

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

        return _accessToken!;
      } else {
        throw Exception('Failed to get access token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting access token: $e');
    }
  }

  Future<void> initialize() async {
    await getApprovalKey();
  }

  bool get isAuthenticated => _approvalKey != null;

  void clearAuthentication() {
    _approvalKey = null;
    _accessToken = null;
    _tokenExpiry = null;
  }
}
