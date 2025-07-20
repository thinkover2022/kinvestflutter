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
  DataSourceType _dataSource = DataSourceType.websocket;

  StreamSubscription<DomesticStockQuote>? _domesticQuoteSubscription;
  StreamSubscription<OverseasStockQuote>? _overseasQuoteSubscription;
  StreamSubscription<DomesticStockExecution>? _domesticExecutionSubscription;
  StreamSubscription<OverseasStockExecution>? _overseasExecutionSubscription;
  StreamSubscription<DomesticOrderNotification>? _domesticOrderSubscription;
  StreamSubscription<OverseasOrderNotification>? _overseasOrderSubscription;

  StockDataNotifier() : super(const StockDataState()) {
    _initializeMarketStatus();
    _loadPersistedData();
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
    
    try {
      // 즉시 한 번 조회
      final execution = await _quoteService!.getDomesticStockPrice(stockCode);
      final newExecutions = Map<String, DomesticStockExecution>.from(state.domesticExecutions);
      newExecutions[stockCode] = execution;
      state = state.copyWith(domesticExecutions: newExecutions);
      
      print('HTTPS 현재가 조회 성공: $stockCode - ${execution.currentPrice}');
    } catch (e) {
      print('HTTPS 현재가 조회 실패: $stockCode - $e');
      // 실패해도 구독 목록에는 추가 (폴링에서 다시 시도)
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
    } catch (e) {
      print('HTTPS 폴링 업데이트 실패: $e');
    }
  }

  Future<void> disconnect() async {
    _httpsPollingTimer?.cancel();
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
