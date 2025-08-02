import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/stock_quote.dart';
import '../models/stock_execution.dart';
import '../models/order_notification.dart';
import '../services/kis_websocket_service.dart';
import '../services/kis_quote_service.dart';
import '../utils/market_hours.dart';
import '../widgets/login_settings_dialog.dart';

class StockDataState {
  final Map<String, DomesticStockQuote> domesticQuotes;
  final Map<String, OverseasStockQuote> overseasQuotes;
  final Map<String, DomesticStockExecution> domesticExecutions;
  final Map<String, OverseasStockExecution> overseasExecutions;
  final List<DomesticOrderNotification> domesticOrders;
  final List<OverseasOrderNotification> overseasOrders;
  final Set<String> subscribedDomesticStocks;
  final Set<String> subscribedOverseasStocks;
  final bool isConnected;
  final String? connectionError;
  final bool isMarketOpen;
  final bool isRealtimeDataAvailable;
  final String marketStatusText;

  const StockDataState({
    this.domesticQuotes = const {},
    this.overseasQuotes = const {},
    this.domesticExecutions = const {},
    this.overseasExecutions = const {},
    this.domesticOrders = const [],
    this.overseasOrders = const [],
    this.subscribedDomesticStocks = const {},
    this.subscribedOverseasStocks = const {},
    this.isConnected = false,
    this.connectionError,
    this.isMarketOpen = false,
    this.isRealtimeDataAvailable = false,
    this.marketStatusText = '장 상태 확인 중...',
  });

  StockDataState copyWith({
    Map<String, DomesticStockQuote>? domesticQuotes,
    Map<String, OverseasStockQuote>? overseasQuotes,
    Map<String, DomesticStockExecution>? domesticExecutions,
    Map<String, OverseasStockExecution>? overseasExecutions,
    List<DomesticOrderNotification>? domesticOrders,
    List<OverseasOrderNotification>? overseasOrders,
    Set<String>? subscribedDomesticStocks,
    Set<String>? subscribedOverseasStocks,
    bool? isConnected,
    String? connectionError,
    bool? isMarketOpen,
    bool? isRealtimeDataAvailable,
    String? marketStatusText,
  }) {
    return StockDataState(
      domesticQuotes: domesticQuotes ?? this.domesticQuotes,
      overseasQuotes: overseasQuotes ?? this.overseasQuotes,
      domesticExecutions: domesticExecutions ?? this.domesticExecutions,
      overseasExecutions: overseasExecutions ?? this.overseasExecutions,
      domesticOrders: domesticOrders ?? this.domesticOrders,
      overseasOrders: overseasOrders ?? this.overseasOrders,
      subscribedDomesticStocks:
          subscribedDomesticStocks ?? this.subscribedDomesticStocks,
      subscribedOverseasStocks:
          subscribedOverseasStocks ?? this.subscribedOverseasStocks,
      isConnected: isConnected ?? this.isConnected,
      connectionError: connectionError ?? this.connectionError,
      isMarketOpen: isMarketOpen ?? this.isMarketOpen,
      isRealtimeDataAvailable: isRealtimeDataAvailable ?? this.isRealtimeDataAvailable,
      marketStatusText: marketStatusText ?? this.marketStatusText,
    );
  }
}

class StockDataNotifier extends StateNotifier<StockDataState> {
  KisWebSocketService? _webSocketService;
  KisQuoteService? _quoteService;
  Timer? _httpsPollingTimer;
  Timer? _dataSourceSwitchTimer;
  Timer? _marketCloseTimer; // 장 마감 시점 강제 전환용 타이머
  Timer? _marketOpenTimer; // 장 개장 시점 강제 전환용 타이머
  DataSourceType _dataSource = DataSourceType.websocket;
  
  // WebSocket 건강 상태 모니터링
  DateTime? _lastWebSocketDataReceived;
  int _webSocketHealthCheckFailures = 0;

  StreamSubscription<DomesticStockQuote>? _domesticQuoteSubscription;
  StreamSubscription<OverseasStockQuote>? _overseasQuoteSubscription;
  StreamSubscription<DomesticStockExecution>? _domesticExecutionSubscription;
  StreamSubscription<OverseasStockExecution>? _overseasExecutionSubscription;
  StreamSubscription<DomesticOrderNotification>? _domesticOrderSubscription;
  StreamSubscription<OverseasOrderNotification>? _overseasOrderSubscription;

  StockDataNotifier() : super(const StockDataState()) {
    _initializeMarketStatus();
    _loadPersistedData();
    _scheduleDataSourceSwitch();
    _scheduleMarketCloseSwitch(); // 장 마감 시점 강제 전환 스케줄링
    _scheduleMarketOpenSwitch(); // 장 개장 시점 강제 전환 스케줄링
  }

  // 장 상태 초기화
  void _initializeMarketStatus() {
    final isOpen = MarketHours.isMarketOpen();
    final isRealtimeAvailable = MarketHours.isRealtimeDataAvailable();
    final statusText = MarketHours.getMarketStatusText();
    
    state = state.copyWith(
      isMarketOpen: isOpen,
      isRealtimeDataAvailable: isRealtimeAvailable,
      marketStatusText: statusText,
    );
    
    print('장 상태 초기화: $statusText (실시간 데이터: ${isRealtimeAvailable ? "사용가능" : "불가능"})');
  }

  // 저장된 데이터 로드 (실시간 데이터 제공 안 될 때는 로드하지 않음)
  Future<void> _loadPersistedData() async {
    if (state.isRealtimeDataAvailable) {
      print('실시간 데이터 제공 시간 - 저장된 데이터 로드하지 않음');
      return;
    }
    
    // 18시 이후에는 저장된 데이터도 사용하지 않음
    print('실시간 데이터 미제공 시간 - 저장된 데이터 로드하지 않음');
    return;
  }

  // 데이터 저장 (실시간 데이터를 받을 때만)
  Future<void> _persistData() async {
    if (state.isRealtimeDataAvailable && state.domesticExecutions.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        
        // 체결 데이터를 JSON으로 변환
        final executionsJson = <String, dynamic>{};
        for (var entry in state.domesticExecutions.entries) {
          executionsJson[entry.key] = entry.value.toJson();
        }
        
        final dataToSave = {
          'domesticExecutions': executionsJson,
          'lastUpdated': DateTime.now().toIso8601String(),
        };
        
        await prefs.setString('last_stock_data', json.encode(dataToSave));
        print('주식 데이터 저장 완료: ${state.domesticExecutions.length}개 종목');
      } catch (e) {
        print('데이터 저장 실패: $e');
      }
    }
  }

  // AuthProvider에서 서비스를 설정
  void setServices({
    KisWebSocketService? webSocketService,
    KisQuoteService? quoteService,
    required DataSourceType dataSource,
  }) {
    _dataSource = dataSource;
    _webSocketService = webSocketService;
    _quoteService = quoteService;
    
    if (dataSource == DataSourceType.websocket && webSocketService != null) {
      _setupSubscriptions();
      state = state.copyWith(isConnected: webSocketService.isConnected);
    } else if (dataSource == DataSourceType.https && quoteService != null) {
      state = state.copyWith(isConnected: true);
      _startHttpsPolling();
    }
  }

  DomesticStockQuote? getDomesticQuote(String stockCode) =>
      state.domesticQuotes[stockCode];
  OverseasStockQuote? getOverseasQuote(String stockCode) =>
      state.overseasQuotes[stockCode];
  DomesticStockExecution? getDomesticExecution(String stockCode) =>
      state.domesticExecutions[stockCode];
  OverseasStockExecution? getOverseasExecution(String stockCode) =>
      state.overseasExecutions[stockCode];

  // 중복 초기화 제거 - AuthProvider에서 이미 연결된 WebSocket 사용
  // initialize() 메서드는 더 이상 필요하지 않음

  void _setupSubscriptions() {
    if (_webSocketService == null) return;

    _domesticQuoteSubscription = _webSocketService!.domesticQuoteStream.listen(
      (quote) {
        print('StockDataProvider: 국내 호가 데이터 수신 - ${quote.stockCode}');
        _lastWebSocketDataReceived = DateTime.now(); // WebSocket 데이터 수신 시간 업데이트
        final newQuotes =
            Map<String, DomesticStockQuote>.from(state.domesticQuotes);
        newQuotes[quote.stockCode] = quote;
        state = state.copyWith(domesticQuotes: newQuotes);
        print('StockDataProvider: 상태 업데이트 완료 - 총 ${newQuotes.length}개 종목');
      },
    );

    _overseasQuoteSubscription = _webSocketService!.overseasQuoteStream.listen(
      (quote) {
        final newQuotes =
            Map<String, OverseasStockQuote>.from(state.overseasQuotes);
        newQuotes[quote.stockCode] = quote;
        state = state.copyWith(overseasQuotes: newQuotes);
      },
    );

    _domesticExecutionSubscription =
        _webSocketService!.domesticExecutionStream.listen(
      (execution) {
        print('StockDataProvider: 국내 체결 데이터 수신 - ${execution.stockCode}: ${execution.currentPrice}');
        _lastWebSocketDataReceived = DateTime.now(); // WebSocket 데이터 수신 시간 업데이트
        final newExecutions =
            Map<String, DomesticStockExecution>.from(state.domesticExecutions);
        newExecutions[execution.stockCode] = execution;
        state = state.copyWith(domesticExecutions: newExecutions);
        print('StockDataProvider: 체결 데이터 업데이트 완료 - 총 ${newExecutions.length}개 종목');
        
        // 실시간 데이터를 받을 때마다 저장 (장 운영 중에도)
        _persistData();
      },
    );

    _overseasExecutionSubscription =
        _webSocketService!.overseasExecutionStream.listen(
      (execution) {
        final newExecutions =
            Map<String, OverseasStockExecution>.from(state.overseasExecutions);
        newExecutions[execution.stockCode] = execution;
        state = state.copyWith(overseasExecutions: newExecutions);
      },
    );

    _domesticOrderSubscription = _webSocketService!.domesticOrderStream.listen(
      (order) {
        final newOrders =
            List<DomesticOrderNotification>.from(state.domesticOrders);
        newOrders.insert(0, order);
        if (newOrders.length > 100) {
          newOrders.removeRange(100, newOrders.length);
        }
        state = state.copyWith(domesticOrders: newOrders);
      },
    );

    _overseasOrderSubscription = _webSocketService!.overseasOrderStream.listen(
      (order) {
        final newOrders =
            List<OverseasOrderNotification>.from(state.overseasOrders);
        newOrders.insert(0, order);
        if (newOrders.length > 100) {
          newOrders.removeRange(100, newOrders.length);
        }
        state = state.copyWith(overseasOrders: newOrders);
      },
    );
  }

  Future<void> subscribeDomesticStock(String stockCode) async {
    print('StockDataProvider: 국내 주식 구독 시도 - $stockCode (${_dataSource.displayName})');
    
    if (state.subscribedDomesticStocks.contains(stockCode)) {
      print('이미 구독중인 종목입니다: $stockCode');
      return;
    }

    try {
      if (_dataSource == DataSourceType.websocket) {
        await _subscribeWebSocket(stockCode);
      } else {
        await _subscribeHttps(stockCode);
      }

      final newSubscribed = Set<String>.from(state.subscribedDomesticStocks);
      newSubscribed.add(stockCode);
      state = state.copyWith(subscribedDomesticStocks: newSubscribed);
      
      print('구독 완료: $stockCode (총 ${newSubscribed.length}개 구독중)');
    } catch (e) {
      print('구독 실패: $stockCode - $e');
      throw Exception('Failed to subscribe to domestic stock $stockCode: $e');
    }
  }

  Future<void> _subscribeWebSocket(String stockCode) async {
    if (_webSocketService == null) {
      throw Exception('WebSocket 서비스가 null입니다');
    }
    
    if (!state.isConnected) {
      throw Exception('WebSocket이 연결되지 않았습니다');
    }

    print('WebSocket 호가 데이터 구독 시도: $stockCode');
    await _webSocketService!.subscribeDomesticQuote(stockCode);
    
    print('WebSocket 체결 데이터 구독 시도: $stockCode');
    await _webSocketService!.subscribeDomesticExecution(stockCode);
  }

  Future<void> _subscribeHttps(String stockCode) async {
    if (_quoteService == null) {
      throw Exception('Quote 서비스가 null입니다');
    }

    print('HTTPS 현재가 조회 시도: $stockCode');
    
    // 토큰 오류 시 재시도 로직
    for (int retry = 0; retry < 2; retry++) {
      try {
        // 즉시 한 번 조회
        final execution = await _quoteService!.getDomesticStockPrice(stockCode);
        final newExecutions = Map<String, DomesticStockExecution>.from(state.domesticExecutions);
        newExecutions[stockCode] = execution;
        state = state.copyWith(domesticExecutions: newExecutions);
        
        print('HTTPS 현재가 조회 성공: $stockCode - ${execution.currentPrice}');
        return; // 성공 시 즉시 반환
      } catch (e) {
        if (e.toString().contains('토큰 만료') && retry == 0) {
          print('토큰 만료로 인한 재시도: $stockCode (시도 ${retry + 1}/2)');
          await Future.delayed(const Duration(milliseconds: 500)); // 잠시 대기
          continue; // 재시도
        }
        print('HTTPS 현재가 조회 실패: $stockCode - $e (시도 ${retry + 1}/2)');
        if (retry == 1) {
          // 마지막 시도 실패 시에도 구독 목록에는 추가 (폴링에서 다시 시도)
          break;
        }
      }
    }
  }

  Future<void> subscribeOverseasStock(String stockCode,
      {bool isAsia = false}) async {
    if (_webSocketService == null || !state.isConnected) {
      throw Exception('WebSocket not available or not connected');
    }

    if (state.subscribedOverseasStocks.contains(stockCode)) {
      return;
    }

    try {
      if (isAsia) {
        await _webSocketService!.subscribeOverseasQuoteAsia(stockCode);
      } else {
        await _webSocketService!.subscribeOverseasQuote(stockCode);
      }
      await _webSocketService!.subscribeOverseasExecution(stockCode);

      final newSubscribed = Set<String>.from(state.subscribedOverseasStocks);
      newSubscribed.add(stockCode);
      state = state.copyWith(subscribedOverseasStocks: newSubscribed);
    } catch (e) {
      throw Exception('Failed to subscribe to overseas stock $stockCode: $e');
    }
  }

  Future<void> unsubscribeDomesticStock(String stockCode) async {
    if (!state.subscribedDomesticStocks.contains(stockCode)) {
      return;
    }

    try {
      await _webSocketService!.unsubscribeDomesticQuote(stockCode);
      await _webSocketService!.unsubscribeDomesticExecution(stockCode);

      final newSubscribed = Set<String>.from(state.subscribedDomesticStocks);
      newSubscribed.remove(stockCode);

      final newQuotes =
          Map<String, DomesticStockQuote>.from(state.domesticQuotes);
      newQuotes.remove(stockCode);

      final newExecutions =
          Map<String, DomesticStockExecution>.from(state.domesticExecutions);
      newExecutions.remove(stockCode);

      state = state.copyWith(
        subscribedDomesticStocks: newSubscribed,
        domesticQuotes: newQuotes,
        domesticExecutions: newExecutions,
      );
    } catch (e) {
      throw Exception(
          'Failed to unsubscribe from domestic stock $stockCode: $e');
    }
  }

  Future<void> subscribeOrderNotifications(String htsId) async {
    if (_webSocketService == null || !state.isConnected) {
      throw Exception('WebSocket not available or not connected');
    }

    try {
      await _webSocketService!.subscribeDomesticOrderNotification(htsId);
      await _webSocketService!.subscribeOverseasOrderNotification(htsId);
    } catch (e) {
      throw Exception('Failed to subscribe to order notifications: $e');
    }
  }

  void clearData() {
    state = const StockDataState();
  }


  // HTTPS 폴링 시작
  void _startHttpsPolling() {
    _httpsPollingTimer?.cancel();
    
    // 30초마다 업데이트
    _httpsPollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateHttpsData();
    });
    
    print('HTTPS 폴링 시작 (30초 간격)');
  }
  
  // HTTPS 데이터 업데이트
  Future<void> _updateHttpsData() async {
    if (_quoteService == null || state.subscribedDomesticStocks.isEmpty) {
      return;
    }
    
    // 토큰 오류 시 재시도 로직
    for (int retry = 0; retry < 2; retry++) {
      try {
        print('HTTPS 폴링 업데이트 시작 (${state.subscribedDomesticStocks.length}개 종목)');
        
        final stockCodes = state.subscribedDomesticStocks.toList();
        final executions = await _quoteService!.getMultipleDomesticStockPrices(stockCodes);
        
        final newExecutions = Map<String, DomesticStockExecution>.from(state.domesticExecutions);
        
        for (final execution in executions) {
          newExecutions[execution.stockCode] = execution;
        }
        
        state = state.copyWith(domesticExecutions: newExecutions);
        print('HTTPS 폴링 업데이트 완료: ${executions.length}개 종목');
        
        // 데이터 저장
        _persistData();
        return; // 성공 시 즉시 반환
      } catch (e) {
        if (e.toString().contains('토큰 만료') && retry == 0) {
          print('폴링 중 토큰 만료로 인한 재시도 (시도 ${retry + 1}/2)');
          await Future.delayed(const Duration(milliseconds: 1000)); // 조금 더 긴 대기
          continue; // 재시도
        }
        print('HTTPS 폴링 업데이트 실패: $e (시도 ${retry + 1}/2)');
        if (retry == 1) {
          // 마지막 시도도 실패한 경우 다음 폴링 때까지 대기
          break;
        }
      }
    }
  }

  // 데이터 소스 자동 전환 스케줄링
  void _scheduleDataSourceSwitch() {
    _dataSourceSwitchTimer?.cancel();
    
    // 장 운영 중에는 30초마다, 그 외에는 1분마다 체크
    final checkInterval = MarketHours.isMarketOpen() 
        ? const Duration(seconds: 30) 
        : const Duration(minutes: 1);
    
    _dataSourceSwitchTimer = Timer.periodic(checkInterval, (_) {
      _checkAndSwitchDataSource();
    });
  }
  
  // 시장 상태에 따른 데이터 소스 전환 확인
  void _checkAndSwitchDataSource() {
    final optimalDataSource = MarketHours.getOptimalDataSource();
    final isOpen = MarketHours.isMarketOpen();
    final isRealtimeAvailable = MarketHours.isRealtimeDataAvailable();
    final statusText = MarketHours.getMarketStatusText();
    
    // 시장 상태 업데이트
    state = state.copyWith(
      isMarketOpen: isOpen,
      isRealtimeDataAvailable: isRealtimeAvailable,
      marketStatusText: statusText,
    );
    
    // 강제 전환 조건 체크 (장 마감 시점)
    final now = DateTime.now();
    final isAfterMarketClose = now.hour > 15 || (now.hour == 15 && now.minute >= 30);
    
    // 데이터 소스가 변경되어야 하는 경우 또는 강제 전환이 필요한 경우
    if (_dataSource != optimalDataSource || 
        (_dataSource == DataSourceType.websocket && isAfterMarketClose)) {
      
      final switchReason = _dataSource != optimalDataSource ? '시간대 변경' : '장 마감 강제 전환';
      print('데이터 소스 전환 ($switchReason): ${_dataSource.displayName} → ${optimalDataSource.displayName}');
      _switchDataSource(optimalDataSource);
    }
    
    // WebSocket 연결 상태 모니터링 (장 운영 중에만)
    if (_dataSource == DataSourceType.websocket && isOpen) {
      _monitorWebSocketHealth();
    }
    
    // 타이머 간격 재조정 (시장 상태 변경 시)
    final currentInterval = MarketHours.isMarketOpen() 
        ? const Duration(seconds: 30) 
        : const Duration(minutes: 1);
    
    // 현재 타이머와 다른 간격이 필요한 경우 재시작
    if (_shouldRestartTimer(currentInterval)) {
      _scheduleDataSourceSwitch();
    }
  }
  
  // 데이터 소스 전환 실행
  Future<void> _switchDataSource(DataSourceType newDataSource) async {
    final previousDataSource = _dataSource;
    _dataSource = newDataSource;
    
    try {
      if (newDataSource == DataSourceType.websocket) {
        // HTTP → WebSocket 전환
        _httpsPollingTimer?.cancel();
        
        if (_webSocketService != null) {
          if (!_webSocketService!.isConnected) {
            await _webSocketService!.connect();
          }
          _setupSubscriptions();
          state = state.copyWith(isConnected: _webSocketService!.isConnected);
          
          // 기존 구독 종목들을 WebSocket으로 재구독
          for (final stockCode in state.subscribedDomesticStocks) {
            await _subscribeWebSocket(stockCode);
          }
          
          print('WebSocket 전환 완료 - ${state.subscribedDomesticStocks.length}개 종목 재구독');
        }
      } else {
        // WebSocket → HTTP 전환
        await _webSocketService?.disconnect();
        _clearSubscriptions();
        
        if (_quoteService != null) {
          state = state.copyWith(isConnected: true);
          _startHttpsPolling();
          print('HTTPS 전환 완료 - 폴링 시작');
        }
      }
    } catch (e) {
      print('데이터 소스 전환 실패: $e');
      // 실패 시 이전 데이터 소스로 롤백
      _dataSource = previousDataSource;
    }
  }
  
  // WebSocket 건강 상태 모니터링
  void _monitorWebSocketHealth() {
    if (_webSocketService == null || !_webSocketService!.isConnected) {
      print('WebSocket 연결 상태 불량 - HTTPS로 강제 전환 고려');
      _webSocketHealthCheckFailures++;
      
      // 연속 3회 실패 시 HTTPS로 강제 전환
      if (_webSocketHealthCheckFailures >= 3) {
        print('WebSocket 건강 상태 불량으로 HTTPS 강제 전환');
        _switchDataSource(DataSourceType.https);
        _webSocketHealthCheckFailures = 0;
      }
      return;
    }
    
    // 데이터 수신 시간 체크 (2분 이상 데이터 없음)
    if (_lastWebSocketDataReceived != null) {
      final timeSinceLastData = DateTime.now().difference(_lastWebSocketDataReceived!);
      if (timeSinceLastData.inMinutes >= 2 && state.subscribedDomesticStocks.isNotEmpty) {
        print('WebSocket 데이터 수신 중단 감지: ${timeSinceLastData.inMinutes}분 경과');
        _webSocketHealthCheckFailures++;
        
        if (_webSocketHealthCheckFailures >= 2) {
          print('WebSocket 데이터 중단으로 HTTPS 강제 전환');
          _switchDataSource(DataSourceType.https);
          _webSocketHealthCheckFailures = 0;
        }
      } else {
        _webSocketHealthCheckFailures = 0; // 정상적으로 데이터 수신 중
      }
    }
  }
  
  // 장 마감 시점 강제 전환 스케줄링
  void _scheduleMarketCloseSwitch() {
    _marketCloseTimer?.cancel();
    
    final now = DateTime.now();
    
    // 주말 체크
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return;
    }
    
    // 오늘 15:30 시점 계산
    final marketCloseTime = DateTime(now.year, now.month, now.day, 15, 30);
    
    // 이미 장 마감 시간이 지났다면 다음 평일 15:30으로 설정
    DateTime targetTime = marketCloseTime;
    if (now.isAfter(marketCloseTime)) {
      targetTime = marketCloseTime.add(const Duration(days: 1));
      // 주말 건너뛰기
      while (targetTime.weekday == DateTime.saturday || targetTime.weekday == DateTime.sunday) {
        targetTime = targetTime.add(const Duration(days: 1));
      }
    }
    
    final timeUntilMarketClose = targetTime.difference(now);
    
    print('장 마감 강제 전환 스케줄링: ${targetTime.toString().substring(0, 16)}');
    
    _marketCloseTimer = Timer(timeUntilMarketClose, () {
      if (_dataSource == DataSourceType.websocket) {
        print('장 마감 시점 도달 - WebSocket에서 HTTPS로 강제 전환');
        _switchDataSource(DataSourceType.https);
      }
      // 다음 날 장 마감을 위해 재스케줄링
      _scheduleMarketCloseSwitch();
    });
  }
  
  // 장 개장 시점 강제 전환 스케줄링 (장 운영 시작 시점: 09:00)
  void _scheduleMarketOpenSwitch() {
    _marketOpenTimer?.cancel();
    
    final now = DateTime.now();
    
    // 주말 체크
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      // 주말이면 다음 월요일 09:00으로 설정
      DateTime nextMonday = now.add(Duration(days: DateTime.monday - now.weekday + 7));
      final marketOpenTime = DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 9, 0);
      final timeUntilMarketOpen = marketOpenTime.difference(now);
      
      print('장 개장 강제 전환 스케줄링 (주말): ${marketOpenTime.toString().substring(0, 16)}');
      
      _marketOpenTimer = Timer(timeUntilMarketOpen, () {
        if (_dataSource == DataSourceType.https) {
          print('장 개장 시점 도달 - HTTPS에서 WebSocket으로 강제 전환');
          _switchDataSource(DataSourceType.websocket);
        }
        _scheduleMarketOpenSwitch();
      });
      return;
    }
    
    // 오늘 09:00 시점 계산 (장 운영 시작)
    final marketOpenTime = DateTime(now.year, now.month, now.day, 9, 0);
    
    // 이미 09:00이 지났다면 다음 평일 09:00으로 설정
    DateTime targetTime = marketOpenTime;
    if (now.isAfter(marketOpenTime)) {
      targetTime = marketOpenTime.add(const Duration(days: 1));
      // 주말 건너뛰기
      while (targetTime.weekday == DateTime.saturday || targetTime.weekday == DateTime.sunday) {
        targetTime = targetTime.add(const Duration(days: 1));
      }
    }
    
    final timeUntilMarketOpen = targetTime.difference(now);
    
    print('장 개장 강제 전환 스케줄링: ${targetTime.toString().substring(0, 16)}');
    
    _marketOpenTimer = Timer(timeUntilMarketOpen, () {
      if (_dataSource == DataSourceType.https) {
        print('장 개장 시점 도달 - HTTPS에서 WebSocket으로 강제 전환');
        _switchDataSource(DataSourceType.websocket);
      }
      // 다음 날 장 개장을 위해 재스케줄링
      _scheduleMarketOpenSwitch();
    });
  }
  
  // 타이머 재시작 필요 여부 확인
  bool _shouldRestartTimer(Duration newInterval) {
    // 현재 장 상태와 타이머 간격이 맞지 않는 경우
    final isMarketOpen = MarketHours.isMarketOpen();
    final isCurrentIntervalCorrect = isMarketOpen 
        ? newInterval == const Duration(seconds: 30)
        : newInterval == const Duration(minutes: 1);
    
    return !isCurrentIntervalCorrect;
  }
  
  // 구독 정리
  void _clearSubscriptions() {
    _domesticQuoteSubscription?.cancel();
    _overseasQuoteSubscription?.cancel();
    _domesticExecutionSubscription?.cancel();
    _overseasExecutionSubscription?.cancel();
    _domesticOrderSubscription?.cancel();
    _overseasOrderSubscription?.cancel();
  }

  Future<void> disconnect() async {
    _httpsPollingTimer?.cancel();
    _dataSourceSwitchTimer?.cancel();
    _marketCloseTimer?.cancel();
    _marketOpenTimer?.cancel();
    await _webSocketService?.disconnect();
    state = state.copyWith(
      isConnected: false,
      connectionError: null,
    );
    clearData();
  }

  @override
  void dispose() {
    _httpsPollingTimer?.cancel();
    _dataSourceSwitchTimer?.cancel();
    _marketCloseTimer?.cancel();
    _marketOpenTimer?.cancel();
    _domesticQuoteSubscription?.cancel();
    _overseasQuoteSubscription?.cancel();
    _domesticExecutionSubscription?.cancel();
    _overseasExecutionSubscription?.cancel();
    _domesticOrderSubscription?.cancel();
    _overseasOrderSubscription?.cancel();
    _webSocketService?.dispose();
    super.dispose();
  }
}

// Riverpod Providers
final stockDataProvider =
    StateNotifierProvider<StockDataNotifier, StockDataState>((ref) {
  return StockDataNotifier();
});

// 개별 데이터 접근을 위한 Provider들
final domesticQuotesProvider = Provider<Map<String, DomesticStockQuote>>((ref) {
  return ref.watch(stockDataProvider).domesticQuotes;
});

final overseasQuotesProvider = Provider<Map<String, OverseasStockQuote>>((ref) {
  return ref.watch(stockDataProvider).overseasQuotes;
});

final domesticExecutionsProvider =
    Provider<Map<String, DomesticStockExecution>>((ref) {
  return ref.watch(stockDataProvider).domesticExecutions;
});

final overseasExecutionsProvider =
    Provider<Map<String, OverseasStockExecution>>((ref) {
  return ref.watch(stockDataProvider).overseasExecutions;
});

final domesticOrdersProvider = Provider<List<DomesticOrderNotification>>((ref) {
  return ref.watch(stockDataProvider).domesticOrders;
});

final overseasOrdersProvider = Provider<List<OverseasOrderNotification>>((ref) {
  return ref.watch(stockDataProvider).overseasOrders;
});

final connectionStatusProvider = Provider<bool>((ref) {
  return ref.watch(stockDataProvider).isConnected;
});

final connectionErrorProvider = Provider<String?>((ref) {
  return ref.watch(stockDataProvider).connectionError;
});

// 특정 종목 데이터 접근을 위한 Family Provider들
final domesticQuoteByCodeProvider =
    Provider.family<DomesticStockQuote?, String>((ref, stockCode) {
  return ref.watch(stockDataProvider).domesticQuotes[stockCode];
});

final overseasQuoteByCodeProvider =
    Provider.family<OverseasStockQuote?, String>((ref, stockCode) {
  return ref.watch(stockDataProvider).overseasQuotes[stockCode];
});

final domesticExecutionByCodeProvider =
    Provider.family<DomesticStockExecution?, String>((ref, stockCode) {
  return ref.watch(stockDataProvider).domesticExecutions[stockCode];
});

final overseasExecutionByCodeProvider =
    Provider.family<OverseasStockExecution?, String>((ref, stockCode) {
  return ref.watch(stockDataProvider).overseasExecutions[stockCode];
});
