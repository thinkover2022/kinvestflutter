import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../models/stock_quote.dart';
import '../models/stock_execution.dart';
import '../models/order_notification.dart';
import '../services/kis_auth_service.dart';
import '../services/kis_websocket_service.dart';
import 'auth_provider.dart';

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
      subscribedDomesticStocks: subscribedDomesticStocks ?? this.subscribedDomesticStocks,
      subscribedOverseasStocks: subscribedOverseasStocks ?? this.subscribedOverseasStocks,
      isConnected: isConnected ?? this.isConnected,
      connectionError: connectionError ?? this.connectionError,
    );
  }
}

class StockDataNotifier extends StateNotifier<StockDataState> {
  final KisAuthService _authService;
  final KisWebSocketService _webSocketService;

  StreamSubscription<DomesticStockQuote>? _domesticQuoteSubscription;
  StreamSubscription<OverseasStockQuote>? _overseasQuoteSubscription;
  StreamSubscription<DomesticStockExecution>? _domesticExecutionSubscription;
  StreamSubscription<OverseasStockExecution>? _overseasExecutionSubscription;
  StreamSubscription<DomesticOrderNotification>? _domesticOrderSubscription;
  StreamSubscription<OverseasOrderNotification>? _overseasOrderSubscription;

  StockDataNotifier({
    required String appKey,
    required String appSecret,
    bool isRealAccount = false,
  })  : _authService = KisAuthService(
          appKey: appKey,
          appSecret: appSecret,
          isRealAccount: isRealAccount,
        ),
        _webSocketService = KisWebSocketService(
          KisAuthService(
            appKey: appKey,
            appSecret: appSecret,
            isRealAccount: isRealAccount,
          ),
        ),
        super(const StockDataState());

  bool get isAuthenticated => _authService.isAuthenticated;

  DomesticStockQuote? getDomesticQuote(String stockCode) => state.domesticQuotes[stockCode];
  OverseasStockQuote? getOverseasQuote(String stockCode) => state.overseasQuotes[stockCode];
  DomesticStockExecution? getDomesticExecution(String stockCode) => state.domesticExecutions[stockCode];
  OverseasStockExecution? getOverseasExecution(String stockCode) => state.overseasExecutions[stockCode];

  Future<void> initialize() async {
    try {
      state = state.copyWith(connectionError: null);
      await _authService.initialize();
      await _webSocketService.connect();
      _setupSubscriptions();
      state = state.copyWith(isConnected: true);
    } catch (e) {
      state = state.copyWith(
        connectionError: e.toString(),
        isConnected: false,
      );
      rethrow;
    }
  }

  void _setupSubscriptions() {
    _domesticQuoteSubscription = _webSocketService.domesticQuoteStream.listen(
      (quote) {
        final newQuotes = Map<String, DomesticStockQuote>.from(state.domesticQuotes);
        newQuotes[quote.stockCode] = quote;
        state = state.copyWith(domesticQuotes: newQuotes);
      },
    );

    _overseasQuoteSubscription = _webSocketService.overseasQuoteStream.listen(
      (quote) {
        final newQuotes = Map<String, OverseasStockQuote>.from(state.overseasQuotes);
        newQuotes[quote.stockCode] = quote;
        state = state.copyWith(overseasQuotes: newQuotes);
      },
    );

    _domesticExecutionSubscription = _webSocketService.domesticExecutionStream.listen(
      (execution) {
        final newExecutions = Map<String, DomesticStockExecution>.from(state.domesticExecutions);
        newExecutions[execution.stockCode] = execution;
        state = state.copyWith(domesticExecutions: newExecutions);
      },
    );

    _overseasExecutionSubscription = _webSocketService.overseasExecutionStream.listen(
      (execution) {
        final newExecutions = Map<String, OverseasStockExecution>.from(state.overseasExecutions);
        newExecutions[execution.stockCode] = execution;
        state = state.copyWith(overseasExecutions: newExecutions);
      },
    );

    _domesticOrderSubscription = _webSocketService.domesticOrderStream.listen(
      (order) {
        final newOrders = List<DomesticOrderNotification>.from(state.domesticOrders);
        newOrders.insert(0, order);
        if (newOrders.length > 100) {
          newOrders.removeRange(100, newOrders.length);
        }
        state = state.copyWith(domesticOrders: newOrders);
      },
    );

    _overseasOrderSubscription = _webSocketService.overseasOrderStream.listen(
      (order) {
        final newOrders = List<OverseasOrderNotification>.from(state.overseasOrders);
        newOrders.insert(0, order);
        if (newOrders.length > 100) {
          newOrders.removeRange(100, newOrders.length);
        }
        state = state.copyWith(overseasOrders: newOrders);
      },
    );
  }

  Future<void> subscribeDomesticStock(String stockCode) async {
    if (!state.isConnected) {
      throw Exception('Not connected to WebSocket');
    }

    if (state.subscribedDomesticStocks.contains(stockCode)) {
      return;
    }

    try {
      await _webSocketService.subscribeDomesticQuote(stockCode);
      await _webSocketService.subscribeDomesticExecution(stockCode);
      
      final newSubscribed = Set<String>.from(state.subscribedDomesticStocks);
      newSubscribed.add(stockCode);
      state = state.copyWith(subscribedDomesticStocks: newSubscribed);
    } catch (e) {
      throw Exception('Failed to subscribe to domestic stock $stockCode: $e');
    }
  }

  Future<void> subscribeOverseasStock(String stockCode, {bool isAsia = false}) async {
    if (!state.isConnected) {
      throw Exception('Not connected to WebSocket');
    }

    if (state.subscribedOverseasStocks.contains(stockCode)) {
      return;
    }

    try {
      if (isAsia) {
        await _webSocketService.subscribeOverseasQuoteAsia(stockCode);
      } else {
        await _webSocketService.subscribeOverseasQuote(stockCode);
      }
      await _webSocketService.subscribeOverseasExecution(stockCode);
      
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
      await _webSocketService.unsubscribeDomesticQuote(stockCode);
      await _webSocketService.unsubscribeDomesticExecution(stockCode);
      
      final newSubscribed = Set<String>.from(state.subscribedDomesticStocks);
      newSubscribed.remove(stockCode);
      
      final newQuotes = Map<String, DomesticStockQuote>.from(state.domesticQuotes);
      newQuotes.remove(stockCode);
      
      final newExecutions = Map<String, DomesticStockExecution>.from(state.domesticExecutions);
      newExecutions.remove(stockCode);
      
      state = state.copyWith(
        subscribedDomesticStocks: newSubscribed,
        domesticQuotes: newQuotes,
        domesticExecutions: newExecutions,
      );
    } catch (e) {
      throw Exception('Failed to unsubscribe from domestic stock $stockCode: $e');
    }
  }

  Future<void> subscribeOrderNotifications(String htsId) async {
    if (!state.isConnected) {
      throw Exception('Not connected to WebSocket');
    }

    try {
      await _webSocketService.subscribeDomesticOrderNotification(htsId);
      await _webSocketService.subscribeOverseasOrderNotification(htsId);
    } catch (e) {
      throw Exception('Failed to subscribe to order notifications: $e');
    }
  }

  void clearData() {
    state = const StockDataState();
  }

  Future<void> disconnect() async {
    await _webSocketService.disconnect();
    _authService.clearAuthentication();
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
    _webSocketService.dispose();
    super.dispose();
  }
}

// Riverpod Providers
final stockDataProvider = StateNotifierProvider<StockDataNotifier, StockDataState>((ref) {
  final authService = ref.watch(authServiceProvider);
  
  if (authService == null) {
    return StockDataNotifier(
      appKey: '',
      appSecret: '',
      isRealAccount: false,
    );
  }
  
  return StockDataNotifier(
    appKey: authService.appKey,
    appSecret: authService.appSecret,
    isRealAccount: authService.isRealAccount,
  );
});

// 개별 데이터 접근을 위한 Provider들
final domesticQuotesProvider = Provider<Map<String, DomesticStockQuote>>((ref) {
  return ref.watch(stockDataProvider).domesticQuotes;
});

final overseasQuotesProvider = Provider<Map<String, OverseasStockQuote>>((ref) {
  return ref.watch(stockDataProvider).overseasQuotes;
});

final domesticExecutionsProvider = Provider<Map<String, DomesticStockExecution>>((ref) {
  return ref.watch(stockDataProvider).domesticExecutions;
});

final overseasExecutionsProvider = Provider<Map<String, OverseasStockExecution>>((ref) {
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
final domesticQuoteByCodeProvider = Provider.family<DomesticStockQuote?, String>((ref, stockCode) {
  return ref.watch(stockDataProvider).domesticQuotes[stockCode];
});

final overseasQuoteByCodeProvider = Provider.family<OverseasStockQuote?, String>((ref, stockCode) {
  return ref.watch(stockDataProvider).overseasQuotes[stockCode];
});

final domesticExecutionByCodeProvider = Provider.family<DomesticStockExecution?, String>((ref, stockCode) {
  return ref.watch(stockDataProvider).domesticExecutions[stockCode];
});

final overseasExecutionByCodeProvider = Provider.family<OverseasStockExecution?, String>((ref, stockCode) {
  return ref.watch(stockDataProvider).overseasExecutions[stockCode];
});