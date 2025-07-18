import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../models/stock_quote.dart';
import '../models/stock_execution.dart';
import '../models/order_notification.dart';
import '../services/kis_websocket_service.dart';

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
    );
  }
}

class StockDataNotifier extends StateNotifier<StockDataState> {
  KisWebSocketService? _webSocketService;

  StreamSubscription<DomesticStockQuote>? _domesticQuoteSubscription;
  StreamSubscription<OverseasStockQuote>? _overseasQuoteSubscription;
  StreamSubscription<DomesticStockExecution>? _domesticExecutionSubscription;
  StreamSubscription<OverseasStockExecution>? _overseasExecutionSubscription;
  StreamSubscription<DomesticOrderNotification>? _domesticOrderSubscription;
  StreamSubscription<OverseasOrderNotification>? _overseasOrderSubscription;

  StockDataNotifier() : super(const StockDataState());

  // AuthProvider에서 WebSocket 서비스를 설정
  void setWebSocketService(KisWebSocketService webSocketService) {
    _webSocketService = webSocketService;
    _setupSubscriptions();
    state = state.copyWith(isConnected: webSocketService.isConnected);
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
    if (_webSocketService == null || !state.isConnected) {
      throw Exception('WebSocket not available or not connected');
    }

    if (state.subscribedDomesticStocks.contains(stockCode)) {
      return;
    }

    try {
      await _webSocketService!.subscribeDomesticQuote(stockCode);
      await _webSocketService!.subscribeDomesticExecution(stockCode);

      final newSubscribed = Set<String>.from(state.subscribedDomesticStocks);
      newSubscribed.add(stockCode);
      state = state.copyWith(subscribedDomesticStocks: newSubscribed);
    } catch (e) {
      throw Exception('Failed to subscribe to domestic stock $stockCode: $e');
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

  // 테스트용 모의 데이터 추가 메서드
  void addMockData() {
    print('StockDataProvider: 모의 데이터 추가 시작');
    
    final mockExecutions = <String, DomesticStockExecution>{};
    final stockCodes = ['005930', '000660', '035420', '051910', '006400'];
    final stockNames = ['삼성전자', 'SK하이닉스', 'NAVER', 'LG화학', '삼성SDI'];
    
    for (int i = 0; i < stockCodes.length; i++) {
      final stockCode = stockCodes[i];
      
      try {
        // 모의 체결 데이터 (실제 DomesticStockExecution 형식)
        final basePrice = 50000 + (i * 10000); // 기본가격
        final changeAmount = (i % 2 == 0) ? 1500 : -800; // 변동금액
        final currentPrice = basePrice + changeAmount;
        
        // DomesticStockExecution 객체 직접 생성
        final execution = DomesticStockExecution(
          stockCode: stockCode,
          executionTime: '151030',
          currentPrice: currentPrice.toDouble(),
          changeSign: changeAmount > 0 ? '2' : '5', // 상승/하락
          dailyChange: changeAmount.abs().toDouble(),
          changeRate: ((changeAmount / basePrice) * 100),
          weightedAvgPrice: currentPrice.toDouble(),
          openPrice: basePrice.toDouble(),
          highPrice: (currentPrice + 500).toDouble(),
          lowPrice: (currentPrice - 1000).toDouble(),
          sellPrice1: (currentPrice + 100).toDouble(),
          buyPrice1: (currentPrice - 100).toDouble(),
          executionVolume: 1000 + (i * 500),
          totalVolume: 1234567 + (i * 100000),
          totalAmount: (currentPrice * (1234567 + (i * 100000))),
          timestamp: DateTime.now(),
        );
        
        mockExecutions[stockCode] = execution;
        print('모의 데이터 생성: $stockCode - 현재가: ${currentPrice.toStringAsFixed(0)}원');
      } catch (e) {
        print('모의 데이터 생성 실패: $stockCode - $e');
      }
    }
    
    // 상태 업데이트
    state = state.copyWith(domesticExecutions: mockExecutions);
    print('StockDataProvider: 모의 데이터 ${mockExecutions.length}개 추가 완료');
  }

  Future<void> disconnect() async {
    await _webSocketService?.disconnect();
    state = state.copyWith(
      isConnected: false,
      connectionError: null,
    );
    clearData();
  }

  @override
  void dispose() {
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
