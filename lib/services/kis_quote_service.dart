import 'dart:convert';
import 'package:http/http.dart' as http;
import 'kis_auth_service.dart';
import '../models/stock_execution.dart';
import '../models/stock_quote.dart';

class KisQuoteService {
  final KisAuthService _authService;

  KisQuoteService(this._authService);

  String get _baseUrl => _authService.baseUrl;

  /// 국내주식 현재가 시세 조회 (FHKST01010100)
  Future<DomesticStockExecution> getDomesticStockPrice(String stockCode) async {
    if (!_authService.isAuthenticated) {
      throw Exception('인증이 필요합니다');
    }

    final url = Uri.parse('$_baseUrl/uapi/domestic-stock/v1/quotations/inquire-price');
    // REST API 호출 시에는 Access Token 사용
    final accessToken = await _authService.getAccessToken();
    
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'authorization': 'Bearer $accessToken',
      'appkey': _authService.appKey,
      'appsecret': _authService.appSecret,
      'tr_id': 'FHKST01010100',
      'custtype': 'P',
      'hashkey': '', // 해시키는 일반적으로 빈 문자열
    };

    final queryParams = {
      'FID_COND_MRKT_DIV_CODE': 'J', // J: KRX
      'FID_INPUT_ISCD': stockCode,
    };

    final uriWithParams = url.replace(queryParameters: queryParams);

    try {
      print('HTTPS 현재가 조회 요청: $stockCode');
      print('요청 URL: $uriWithParams');
      print('요청 헤더: $headers');
      print('인증 상태: ${_authService.isAuthenticated}');
      print('승인키: ${_authService.approvalKey?.substring(0, 20)}...');
      
      final response = await http.get(uriWithParams, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['rt_cd'] == '0') {
          final output = responseData['output'];
          print('HTTPS 현재가 조회 성공: $stockCode - ${output['stck_prpr']}');
          
          // API 응답을 DomesticStockExecution 모델로 변환
          return _convertToDomesticStockExecution(stockCode, output);
        } else {
          // 토큰 관련 오류 체크
          if (responseData['msg_cd'] == 'EGW00121' || responseData['msg1']?.contains('token') == true) {
            print('토큰 오류 감지, 토큰 갱신 후 재시도: ${responseData['msg1']}');
            // 토큰 초기화하여 다음 호출 시 새로 발급받도록 함
            _authService.clearAuthentication();
            await _authService.initialize();
            throw Exception('토큰 만료 - 재시도 필요: ${responseData['msg1']}');
          }
          throw Exception('API 오류: ${responseData['msg1']}');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // 인증 오류 시 토큰 갱신
        print('인증 오류 감지, 토큰 갱신 중...');
        _authService.clearAuthentication();
        await _authService.initialize();
        throw Exception('인증 오류 - 토큰 갱신 필요');
      } else {
        print('HTTP 오류 응답 바디: ${response.body}');
        throw Exception('HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('HTTPS 현재가 조회 실패: $stockCode - $e');
      throw Exception('현재가 조회 실패: $e');
    }
  }

  /// 여러 종목의 현재가를 한 번에 조회
  Future<List<DomesticStockExecution>> getMultipleDomesticStockPrices(List<String> stockCodes) async {
    final List<DomesticStockExecution> results = [];
    
    for (String stockCode in stockCodes) {
      try {
        final execution = await getDomesticStockPrice(stockCode);
        results.add(execution);
        
        // API 호출 간격 (초당 20건 제한)
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        print('종목 $stockCode 조회 실패: $e');
        // 실패한 종목은 건너뛰고 계속 진행
      }
    }
    
    return results;
  }

  /// 국내주식 호가 조회 (FHKST01010200)
  Future<DomesticStockQuote> getDomesticStockOrderbook(String stockCode) async {
    if (!_authService.isAuthenticated) {
      throw Exception('인증이 필요합니다');
    }

    final url = Uri.parse('$_baseUrl/uapi/domestic-stock/v1/quotations/inquire-asking-price-exp-ccn');
    // REST API 호출 시에는 Access Token 사용
    final accessToken = await _authService.getAccessToken();
    
    final headers = {
      'Content-Type': 'application/json; charset=utf-8',
      'authorization': 'Bearer $accessToken',
      'appkey': _authService.appKey,
      'appsecret': _authService.appSecret,
      'tr_id': 'FHKST01010200',
      'custtype': 'P',
    };

    final queryParams = {
      'FID_COND_MRKT_DIV_CODE': 'J',
      'FID_INPUT_ISCD': stockCode,
    };

    final uriWithParams = url.replace(queryParameters: queryParams);

    try {
      print('HTTPS 호가 조회 요청: $stockCode');
      final response = await http.get(uriWithParams, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['rt_cd'] == '0') {
          final output = responseData['output'];
          print('HTTPS 호가 조회 성공: $stockCode');
          
          return _convertToDomesticStockQuote(stockCode, output);
        } else {
          // 토큰 관련 오류 체크
          if (responseData['msg_cd'] == 'EGW00121' || responseData['msg1']?.contains('token') == true) {
            print('토큰 오류 감지, 토큰 갱신 후 재시도: ${responseData['msg1']}');
            _authService.clearAuthentication();
            await _authService.initialize();
            throw Exception('토큰 만료 - 재시도 필요: ${responseData['msg1']}');
          }
          throw Exception('API 오류: ${responseData['msg1']}');
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // 인증 오류 시 토큰 갱신
        print('인증 오류 감지, 토큰 갱신 중...');
        _authService.clearAuthentication();
        await _authService.initialize();
        throw Exception('인증 오류 - 토큰 갱신 필요');
      } else {
        print('HTTP 오류 응답 바디: ${response.body}');
        throw Exception('HTTP 오류: ${response.statusCode}');
      }
    } catch (e) {
      print('HTTPS 호가 조회 실패: $stockCode - $e');
      throw Exception('호가 조회 실패: $e');
    }
  }

  /// API 응답을 DomesticStockExecution 모델로 변환
  DomesticStockExecution _convertToDomesticStockExecution(String stockCode, Map<String, dynamic> output) {
    try {
      final currentPrice = double.parse(output['stck_prpr'] ?? '0'); // 현재가
      final openPrice = double.parse(output['stck_oprc'] ?? '0'); // 시가
      final highPrice = double.parse(output['stck_hgpr'] ?? '0'); // 고가
      final lowPrice = double.parse(output['stck_lwpr'] ?? '0'); // 저가
      final prevClosePrice = double.parse(output['stck_sdpr'] ?? '0'); // 전일종가
      
      // 전일 대비 변화량 및 비율
      final dailyChange = double.parse(output['prdy_vrss'] ?? '0'); // 전일대비
      final changeRate = double.parse(output['prdy_ctrt'] ?? '0'); // 전일대비율
      final changeSign = output['prdy_vrss_sign'] ?? '3'; // 등락구분
      
      return DomesticStockExecution(
        stockCode: stockCode,
        executionTime: DateTime.now().toString().substring(11, 19).replaceAll(':', ''), // HHMMSS
        currentPrice: currentPrice,
        changeSign: changeSign,
        dailyChange: dailyChange.abs(),
        changeRate: changeRate,
        weightedAvgPrice: double.parse(output['wghn_avrg_stck_prc'] ?? currentPrice.toString()),
        openPrice: openPrice,
        highPrice: highPrice,
        lowPrice: lowPrice,
        sellPrice1: currentPrice + 500, // 호가 정보가 없으므로 임시값
        buyPrice1: currentPrice - 500, // 호가 정보가 없으므로 임시값
        executionVolume: 0, // 현재가 API에는 체결량 정보 없음
        totalVolume: int.parse(output['acml_vol'] ?? '0'), // 누적거래량
        totalAmount: double.parse(output['acml_tr_pbmn'] ?? '0').toInt(), // 누적거래대금
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('데이터 변환 실패: $e');
      throw Exception('데이터 변환 실패: $e');
    }
  }

  /// API 응답을 DomesticStockQuote 모델로 변환
  DomesticStockQuote _convertToDomesticStockQuote(String stockCode, Map<String, dynamic> output) {
    try {
      // 매도호가 (1~10호가)
      final sellPrices = <double>[];
      final sellQuantities = <int>[];
      
      // 매수호가 (1~10호가)
      final buyPrices = <double>[];
      final buyQuantities = <int>[];
      
      for (int i = 1; i <= 10; i++) {
        // 매도호가/물량
        sellPrices.add(double.parse(output['askp$i'] ?? '0'));
        sellQuantities.add(int.parse(output['askp_rsqn$i'] ?? '0'));
        
        // 매수호가/물량
        buyPrices.add(double.parse(output['bidp$i'] ?? '0'));
        buyQuantities.add(int.parse(output['bidp_rsqn$i'] ?? '0'));
      }
      
      return DomesticStockQuote(
        stockCode: stockCode,
        businessTime: DateTime.now().toString().substring(11, 19), // HH:MM:SS 형태
        timeCode: DateTime.now().toString().substring(11, 19), // HH:MM:SS 형태
        sellPrices: sellPrices,
        sellQuantities: sellQuantities,
        buyPrices: buyPrices,
        buyQuantities: buyQuantities,
        totalSellQuantity: sellQuantities.fold(0, (sum, qty) => sum + qty),
        totalBuyQuantity: buyQuantities.fold(0, (sum, qty) => sum + qty),
        expectedPrice: buyPrices.isNotEmpty ? buyPrices.first : 0.0,
        expectedQuantity: buyQuantities.isNotEmpty ? buyQuantities.first : 0,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      print('호가 데이터 변환 실패: $e');
      throw Exception('호가 데이터 변환 실패: $e');
    }
  }
}