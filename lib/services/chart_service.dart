import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chart_data.dart';
import 'kis_auth_service.dart';

class ChartService {
  final KisAuthService _authService;
  
  ChartService(this._authService);

  // 분봉 데이터 조회 (1분, 3분, 5분, 10분, 30분, 1시간)
  Future<List<CandleData>> getMinuteCandles(
    String stockCode,
    ChartTimeFrame timeFrame,
  ) async {
    if (timeFrame.periodType != 'T') {
      throw ArgumentError('Invalid timeframe for minute data: ${timeFrame.displayName}');
    }

    final baseUrl = _authService.baseUrl;
    final accessToken = await _authService.getAccessToken();
    
    final url = Uri.parse('$baseUrl/uapi/domestic-stock/v1/quotations/inquire-time-itemchartprice');
    
    final response = await http.get(
      url.replace(queryParameters: {
        'FID_ETC_CLS_CODE': '',
        'FID_COND_MRKT_DIV_CODE': 'J',
        'FID_INPUT_ISCD': stockCode,
        'FID_INPUT_HOUR_1': timeFrame.apiCode, // 분 단위
        'FID_PW_DATA_INCU_YN': 'Y',
      }),
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $accessToken',
        'appkey': _authService.appKey,
        'appsecret': _authService.appSecret,
        'tr_id': 'FHKST03010200', // 분봉 조회 TR_ID
        'custtype': 'P',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final output2 = data['output2'] as List?;
      
      if (output2 == null || output2.isEmpty) {
        return [];
      }
      
      List<CandleData> candles = output2.map((item) => 
        CandleData.fromMinuteJson(item)
      ).toList();
      
      // 최신순으로 정렬 (오래된 것부터)
      candles.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      
      // 이동평균선 계산
      _calculateMovingAverages(candles);
      
      return candles;
    } else {
      throw Exception('Failed to fetch minute chart data: ${response.statusCode}');
    }
  }

  // 일봉 데이터 조회
  Future<List<CandleData>> getDailyCandles(
    String stockCode,
    {String period = '1'} // 1:1년, 2:3개월, 3:1개월
  ) async {
    final baseUrl = _authService.baseUrl;
    final accessToken = await _authService.getAccessToken();
    
    final url = Uri.parse('$baseUrl/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice');
    
    final response = await http.get(
      url.replace(queryParameters: {
        'FID_COND_MRKT_DIV_CODE': 'J',
        'FID_INPUT_ISCD': stockCode,
        'FID_INPUT_DATE_1': '', // 시작일 (빈값이면 최근)
        'FID_INPUT_DATE_2': '', // 종료일 (빈값이면 오늘)
        'FID_PERIOD_DIV_CODE': period,
        'FID_ORG_ADJ_PRC': '1', // 수정주가 반영
      }),
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $accessToken',
        'appkey': _authService.appKey,
        'appsecret': _authService.appSecret,
        'tr_id': 'FHKST03010100', // 일봉 조회 TR_ID
        'custtype': 'P',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final output2 = data['output2'] as List?;
      
      if (output2 == null || output2.isEmpty) {
        return [];
      }
      
      List<CandleData> candles = output2.map((item) => 
        CandleData.fromDailyJson(item)
      ).toList();
      
      // 최신순으로 정렬 (오래된 것부터)
      candles.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      
      // 이동평균선 계산
      _calculateMovingAverages(candles);
      
      return candles;
    } else {
      throw Exception('Failed to fetch daily chart data: ${response.statusCode}');
    }
  }

  // 주봉/월봉 데이터 조회
  Future<List<CandleData>> getPeriodCandles(
    String stockCode,
    ChartTimeFrame timeFrame,
  ) async {
    if (timeFrame.periodType != 'W' && timeFrame.periodType != 'M') {
      throw ArgumentError('Invalid timeframe for period data: ${timeFrame.displayName}');
    }

    final baseUrl = _authService.baseUrl;
    final accessToken = await _authService.getAccessToken();
    
    final url = Uri.parse('$baseUrl/uapi/domestic-stock/v1/quotations/inquire-daily-itemchartprice');
    
    final response = await http.get(
      url.replace(queryParameters: {
        'FID_COND_MRKT_DIV_CODE': 'J',
        'FID_INPUT_ISCD': stockCode,
        'FID_INPUT_DATE_1': '',
        'FID_INPUT_DATE_2': '',
        'FID_PERIOD_DIV_CODE': timeFrame.periodType == 'W' ? 'W' : 'M',
        'FID_ORG_ADJ_PRC': '1',
      }),
      headers: {
        'Content-Type': 'application/json',
        'authorization': 'Bearer $accessToken',
        'appkey': _authService.appKey,
        'appsecret': _authService.appSecret,
        'tr_id': 'FHKST03010100',
        'custtype': 'P',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final output2 = data['output2'] as List?;
      
      if (output2 == null || output2.isEmpty) {
        return [];
      }
      
      List<CandleData> candles = output2.map((item) => 
        CandleData.fromPeriodJson(item)
      ).toList();
      
      // 최신순으로 정렬 (오래된 것부터)
      candles.sort((a, b) => a.dateTime.compareTo(b.dateTime));
      
      // 이동평균선 계산
      _calculateMovingAverages(candles);
      
      return candles;
    } else {
      throw Exception('Failed to fetch period chart data: ${response.statusCode}');
    }
  }

  // 통합 차트 데이터 조회 메서드
  Future<List<CandleData>> getChartData(
    String stockCode,
    ChartTimeFrame timeFrame,
  ) async {
    switch (timeFrame.periodType) {
      case 'T': // 분/시간봉
        return await getMinuteCandles(stockCode, timeFrame);
      case 'D': // 일봉
        return await getDailyCandles(stockCode);
      case 'W':
      case 'M': // 주봉/월봉
        return await getPeriodCandles(stockCode, timeFrame);
      default:
        throw ArgumentError('Unsupported timeframe: ${timeFrame.displayName}');
    }
  }

  // 이동평균선 계산
  void _calculateMovingAverages(List<CandleData> candles) {
    for (int i = 0; i < candles.length; i++) {
      CandleData current = candles[i];
      
      // 5일 이동평균
      if (i >= 4) {
        double sum5 = 0;
        for (int j = i - 4; j <= i; j++) {
          sum5 += candles[j].close;
        }
        current = current.copyWith(ma5: sum5 / 5);
      }
      
      // 20일 이동평균
      if (i >= 19) {
        double sum20 = 0;
        for (int j = i - 19; j <= i; j++) {
          sum20 += candles[j].close;
        }
        current = current.copyWith(ma20: sum20 / 20);
      }
      
      // 60일 이동평균
      if (i >= 59) {
        double sum60 = 0;
        for (int j = i - 59; j <= i; j++) {
          sum60 += candles[j].close;
        }
        current = current.copyWith(ma60: sum60 / 60);
      }
      
      // 120일 이동평균
      if (i >= 119) {
        double sum120 = 0;
        for (int j = i - 119; j <= i; j++) {
          sum120 += candles[j].close;
        }
        current = current.copyWith(ma120: sum120 / 120);
      }
      
      candles[i] = current;
    }
  }
}