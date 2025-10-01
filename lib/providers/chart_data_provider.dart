import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chart_data.dart';
import '../services/chart_service.dart';
import '../providers/auth_provider.dart';

// Chart Service Provider
final chartServiceProvider = Provider<ChartService?>((ref) {
  final authService = ref.watch(authServiceProvider);
  if (authService == null) return null;
  return ChartService(authService);
});

// Chart Data State
class ChartDataState {
  final Map<String, List<CandleData>> chartData;
  final bool isLoading;
  final String? error;
  final ChartSettings settings;

  const ChartDataState({
    this.chartData = const {},
    this.isLoading = false,
    this.error,
    this.settings = const ChartSettings(),
  });

  ChartDataState copyWith({
    Map<String, List<CandleData>>? chartData,
    bool? isLoading,
    String? error,
    ChartSettings? settings,
  }) {
    return ChartDataState(
      chartData: chartData ?? this.chartData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      settings: settings ?? this.settings,
    );
  }
}

// Chart Data Notifier
class ChartDataNotifier extends StateNotifier<ChartDataState> {
  final ChartService? _chartService;

  ChartDataNotifier(this._chartService) : super(const ChartDataState());

  // 차트 데이터 로드
  Future<void> loadChartData(String stockCode, ChartTimeFrame timeFrame) async {
    if (_chartService == null) {
      state = state.copyWith(error: '인증 서비스가 초기화되지 않았습니다');
      return;
    }

    final cacheKey = '${stockCode}_${timeFrame.displayName}';
    
    // 이미 같은 데이터가 있으면 건너뛰기
    if (state.chartData.containsKey(cacheKey) && !state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final data = await _chartService.getChartData(stockCode, timeFrame);
      
      final updatedData = Map<String, List<CandleData>>.from(state.chartData);
      updatedData[cacheKey] = data;
      
      state = state.copyWith(
        chartData: updatedData,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // 차트 설정 업데이트
  void updateSettings(ChartSettings newSettings) {
    state = state.copyWith(settings: newSettings);
  }

  // 에러 클리어
  void clearError() {
    state = state.copyWith(error: null);
  }

  // 특정 종목의 차트 데이터 가져오기
  List<CandleData> getChartData(String stockCode, ChartTimeFrame timeFrame) {
    final cacheKey = '${stockCode}_${timeFrame.displayName}';
    return state.chartData[cacheKey] ?? [];
  }
}

// Chart Data Provider
final chartDataProvider = StateNotifierProvider<ChartDataNotifier, ChartDataState>((ref) {
  final chartService = ref.watch(chartServiceProvider);
  return ChartDataNotifier(chartService);
});