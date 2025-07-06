import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

import '../models/stock_quote.dart';
import '../models/stock_execution.dart';
import '../models/order_notification.dart';
import 'kis_auth_service.dart';
import 'encryption_service.dart';

enum KisWebSocketRequestType {
  domesticQuote('H0STASP0'),
  domesticExecution('H0STCNT0'),
  domesticOrderNotification('H0STCNI0'),
  overseasQuote('HDFSASP0'),
  overseasQuoteAsia('HDFSASP1'),
  overseasExecution('HDFSCNT0'),
  overseasOrderNotification('H0GSCNI0');

  const KisWebSocketRequestType(this.code);
  final String code;
}

class KisWebSocketService {
  static const String _realWsUrl = 'ws://ops.koreainvestment.com:21000';
  static const String _mockWsUrl = 'ws://ops.koreainvestment.com:31000';

  final KisAuthService _authService;
  WebSocketChannel? _channel;
  StreamController<DomesticStockQuote>? _domesticQuoteController;
  StreamController<OverseasStockQuote>? _overseasQuoteController;
  StreamController<DomesticStockExecution>? _domesticExecutionController;
  StreamController<OverseasStockExecution>? _overseasExecutionController;
  StreamController<DomesticOrderNotification>? _domesticOrderController;
  StreamController<OverseasOrderNotification>? _overseasOrderController;

  String? _aesKey;
  String? _aesIv;
  bool _isConnected = false;

  KisWebSocketService(this._authService);

  String get _wsUrl => _authService.isRealAccount ? _realWsUrl : _mockWsUrl;

  Stream<DomesticStockQuote> get domesticQuoteStream {
    _domesticQuoteController ??= StreamController<DomesticStockQuote>.broadcast();
    return _domesticQuoteController!.stream;
  }

  Stream<OverseasStockQuote> get overseasQuoteStream {
    _overseasQuoteController ??= StreamController<OverseasStockQuote>.broadcast();
    return _overseasQuoteController!.stream;
  }

  Stream<DomesticStockExecution> get domesticExecutionStream {
    _domesticExecutionController ??= StreamController<DomesticStockExecution>.broadcast();
    return _domesticExecutionController!.stream;
  }

  Stream<OverseasStockExecution> get overseasExecutionStream {
    _overseasExecutionController ??= StreamController<OverseasStockExecution>.broadcast();
    return _overseasExecutionController!.stream;
  }

  Stream<DomesticOrderNotification> get domesticOrderStream {
    _domesticOrderController ??= StreamController<DomesticOrderNotification>.broadcast();
    return _domesticOrderController!.stream;
  }

  Stream<OverseasOrderNotification> get overseasOrderStream {
    _overseasOrderController ??= StreamController<OverseasOrderNotification>.broadcast();
    return _overseasOrderController!.stream;
  }

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_isConnected) return;

    try {
      // AuthProvider에서 이미 initialize()를 호출했으므로 여기서는 체크만
      if (!_authService.isAuthenticated) {
        throw Exception('AuthService not initialized. Call authService.initialize() first.');
      }

      _channel = WebSocketChannel.connect(Uri.parse(_wsUrl));
      _isConnected = true;

      _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnected,
        onError: _onError,
      );

      print('WebSocket connected to $_wsUrl');
    } catch (e) {
      _isConnected = false;
      throw Exception('Failed to connect WebSocket: $e');
    }
  }

  Future<void> disconnect() async {
    if (!_isConnected) return;

    await _channel?.sink.close(status.goingAway);
    _isConnected = false;
    _aesKey = null;
    _aesIv = null;
    print('WebSocket disconnected');
  }

  Future<void> subscribeDomesticQuote(String stockCode) async {
    await _subscribe(KisWebSocketRequestType.domesticQuote, stockCode);
  }

  Future<void> subscribeDomesticExecution(String stockCode) async {
    await _subscribe(KisWebSocketRequestType.domesticExecution, stockCode);
  }

  Future<void> subscribeDomesticOrderNotification(String htsId) async {
    await _subscribe(KisWebSocketRequestType.domesticOrderNotification, htsId);
  }

  Future<void> subscribeOverseasQuote(String stockCode) async {
    await _subscribe(KisWebSocketRequestType.overseasQuote, stockCode);
  }

  Future<void> subscribeOverseasQuoteAsia(String stockCode) async {
    await _subscribe(KisWebSocketRequestType.overseasQuoteAsia, stockCode);
  }

  Future<void> subscribeOverseasExecution(String stockCode) async {
    await _subscribe(KisWebSocketRequestType.overseasExecution, stockCode);
  }

  Future<void> subscribeOverseasOrderNotification(String htsId) async {
    await _subscribe(KisWebSocketRequestType.overseasOrderNotification, htsId);
  }

  Future<void> unsubscribeDomesticQuote(String stockCode) async {
    await _unsubscribe(KisWebSocketRequestType.domesticQuote, stockCode);
  }

  Future<void> unsubscribeDomesticExecution(String stockCode) async {
    await _unsubscribe(KisWebSocketRequestType.domesticExecution, stockCode);
  }

  Future<void> _subscribe(KisWebSocketRequestType type, String key) async {
    if (!_isConnected) throw Exception('WebSocket not connected');

    final message = _createSubscriptionMessage(type, key, '1');
    _channel!.sink.add(message);
    await Future.delayed(const Duration(milliseconds: 500));
    print('Subscribed to ${type.code} for $key');
  }

  Future<void> _unsubscribe(KisWebSocketRequestType type, String key) async {
    if (!_isConnected) throw Exception('WebSocket not connected');

    final message = _createSubscriptionMessage(type, key, '2');
    _channel!.sink.add(message);
    await Future.delayed(const Duration(milliseconds: 500));
    print('Unsubscribed from ${type.code} for $key');
  }

  String _createSubscriptionMessage(KisWebSocketRequestType type, String key, String trType) {
    return json.encode({
      'header': {
        'approval_key': _authService.approvalKey,
        'custtype': 'P',
        'tr_type': trType,
        'content-type': 'utf-8',
      },
      'body': {
        'input': {
          'tr_id': type.code,
          'tr_key': key,
        },
      },
    });
  }

  void _onMessage(dynamic message) {
    try {
      final data = message.toString();

      if (data.startsWith('0') || data.startsWith('1')) {
        _handleRealtimeData(data);
      } else {
        _handleResponseMessage(data);
      }
    } catch (e) {
      print('Error processing message: $e');
    }
  }

  void _handleRealtimeData(String data) {
    final parts = data.split('|');
    if (parts.length < 4) return;

    final flag = parts[0];
    final trId = parts[1];
    final dataCount = parts.length > 2 ? int.tryParse(parts[2]) ?? 1 : 1;
    final payload = parts[3];

    try {
      if (flag == '0') {
        switch (trId) {
          case 'H0STASP0':
            final quote = DomesticStockQuote.fromWebSocketData(payload);
            _domesticQuoteController?.add(quote);
            break;
          case 'H0STCNT0':
            final execution = DomesticStockExecution.fromWebSocketData(payload);
            _domesticExecutionController?.add(execution);
            break;
          case 'HDFSASP0':
          case 'HDFSASP1':
            final quote = OverseasStockQuote.fromWebSocketData(payload);
            _overseasQuoteController?.add(quote);
            break;
          case 'HDFSCNT0':
            final execution = OverseasStockExecution.fromWebSocketData(payload);
            _overseasExecutionController?.add(execution);
            break;
        }
      } else if (flag == '1') {
        if (_aesKey != null && _aesIv != null) {
          final decryptedData = EncryptionService.aesDecrypt(_aesKey!, _aesIv!, payload);
          
          switch (trId) {
            case 'H0STCNI0':
            case 'H0STCNI9':
              final notification = DomesticOrderNotification.fromDecryptedData(decryptedData);
              _domesticOrderController?.add(notification);
              break;
            case 'H0GSCNI0':
            case 'H0GSCNI9':
              final notification = OverseasOrderNotification.fromDecryptedData(decryptedData);
              _overseasOrderController?.add(notification);
              break;
          }
        }
      }
    } catch (e) {
      print('Error parsing realtime data: $e');
    }
  }

  void _handleResponseMessage(String data) {
    try {
      final jsonData = json.decode(data);
      final trId = jsonData['header']['tr_id'];

      if (trId == 'PINGPONG') {
        _channel!.sink.add(data);
        print('PINGPONG received and sent back');
        return;
      }

      final rtCd = jsonData['body']['rt_cd'];
      final msg = jsonData['body']['msg1'];

      if (rtCd == '0') {
        print('Success: $msg');
        
        if (trId == 'H0STCNI0' || trId == 'H0STCNI9' || trId == 'H0GSCNI0' || trId == 'H0GSCNI9') {
          _aesKey = jsonData['body']['output']['key'];
          _aesIv = jsonData['body']['output']['iv'];
          print('AES keys received for $trId');
        }
      } else {
        print('Error: $msg');
      }
    } catch (e) {
      print('Error parsing response message: $e');
    }
  }

  void _onDisconnected() {
    _isConnected = false;
    _aesKey = null;
    _aesIv = null;
    print('WebSocket disconnected');
  }

  void _onError(error) {
    print('WebSocket error: $error');
    _isConnected = false;
  }

  void dispose() {
    disconnect();
    _domesticQuoteController?.close();
    _overseasQuoteController?.close();
    _domesticExecutionController?.close();
    _overseasExecutionController?.close();
    _domesticOrderController?.close();
    _overseasOrderController?.close();
  }
}