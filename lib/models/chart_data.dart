import 'package:intl/intl.dart';

// 차트 시간 단위 열거형
enum ChartTimeFrame {
  min1('1분', '1', 'T'),
  min3('3분', '3', 'T'),
  min5('5분', '5', 'T'),
  min10('10분', '10', 'T'),
  min30('30분', '30', 'T'),
  hour1('1시간', '60', 'T'),
  daily('일', 'D', 'D'),
  weekly('주', 'W', 'W'),
  monthly('월', 'M', 'M');

  const ChartTimeFrame(this.displayName, this.apiCode, this.periodType);
  final String displayName;
  final String apiCode;
  final String periodType; // T: 분/시간, D: 일, W: 주, M: 월
}

// 캔들 데이터 모델
class CandleData {
  final DateTime dateTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final int volume;
  final double? ma5;     // 5일 이동평균선
  final double? ma20;    // 20일 이동평균선
  final double? ma60;    // 60일 이동평균선
  final double? ma120;   // 120일 이동평균선

  CandleData({
    required this.dateTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    this.ma5,
    this.ma20,
    this.ma60,
    this.ma120,
  });

  // 분봉 데이터용 팩토리
  factory CandleData.fromMinuteJson(Map<String, dynamic> json) {
    return CandleData(
      dateTime: _parseDateTime(json['stck_cntg_hour'], json['stck_bsop_date']),
      open: double.tryParse(json['stck_oprc'].toString()) ?? 0.0,
      high: double.tryParse(json['stck_hgpr'].toString()) ?? 0.0,
      low: double.tryParse(json['stck_lwpr'].toString()) ?? 0.0,
      close: double.tryParse(json['stck_prpr'].toString()) ?? 0.0,
      volume: int.tryParse(json['cntg_vol'].toString()) ?? 0,
    );
  }

  // 일봉 데이터용 팩토리
  factory CandleData.fromDailyJson(Map<String, dynamic> json) {
    return CandleData(
      dateTime: DateTime.parse(json['stck_bsop_date']),
      open: double.tryParse(json['stck_oprc'].toString()) ?? 0.0,
      high: double.tryParse(json['stck_hgpr'].toString()) ?? 0.0,
      low: double.tryParse(json['stck_lwpr'].toString()) ?? 0.0,
      close: double.tryParse(json['stck_clpr'].toString()) ?? 0.0,
      volume: int.tryParse(json['acml_vol'].toString()) ?? 0,
    );
  }

  // 주봉/월봉 데이터용 팩토리
  factory CandleData.fromPeriodJson(Map<String, dynamic> json) {
    return CandleData(
      dateTime: DateTime.parse(json['stck_bsop_date']),
      open: double.tryParse(json['stck_oprc'].toString()) ?? 0.0,
      high: double.tryParse(json['stck_hgpr'].toString()) ?? 0.0,
      low: double.tryParse(json['stck_lwpr'].toString()) ?? 0.0,
      close: double.tryParse(json['stck_clpr'].toString()) ?? 0.0,
      volume: int.tryParse(json['acml_vol'].toString()) ?? 0,
    );
  }

  // 날짜/시간 파싱 헬퍼
  static DateTime _parseDateTime(String time, String date) {
    try {
      final dateStr = date.replaceAll('/', '');
      final timeStr = time.padLeft(6, '0');
      final fullDateTimeStr = '$dateStr${timeStr}';
      return DateFormat('yyyyMMddHHmmss').parse(fullDateTimeStr);
    } catch (e) {
      return DateTime.parse(date);
    }
  }

  // 이동평균선이 추가된 새 인스턴스 생성
  CandleData copyWith({
    double? ma5,
    double? ma20,
    double? ma60,
    double? ma120,
  }) {
    return CandleData(
      dateTime: dateTime,
      open: open,
      high: high,
      low: low,
      close: close,
      volume: volume,
      ma5: ma5 ?? this.ma5,
      ma20: ma20 ?? this.ma20,
      ma60: ma60 ?? this.ma60,
      ma120: ma120 ?? this.ma120,
    );
  }

  @override
  String toString() {
    return 'CandleData(dateTime: $dateTime, open: $open, high: $high, low: $low, close: $close, volume: $volume)';
  }
}

// 차트 설정 클래스
class ChartSettings {
  final ChartTimeFrame timeFrame;
  final bool showMA5;
  final bool showMA20;
  final bool showMA60;
  final bool showMA120;
  final bool showVolume;
  final double zoomLevel;
  final double panOffset;

  const ChartSettings({
    this.timeFrame = ChartTimeFrame.daily,
    this.showMA5 = true,
    this.showMA20 = true,
    this.showMA60 = true,
    this.showMA120 = true,
    this.showVolume = true,
    this.zoomLevel = 1.0,
    this.panOffset = 0.0,
  });

  ChartSettings copyWith({
    ChartTimeFrame? timeFrame,
    bool? showMA5,
    bool? showMA20,
    bool? showMA60,
    bool? showMA120,
    bool? showVolume,
    double? zoomLevel,
    double? panOffset,
  }) {
    return ChartSettings(
      timeFrame: timeFrame ?? this.timeFrame,
      showMA5: showMA5 ?? this.showMA5,
      showMA20: showMA20 ?? this.showMA20,
      showMA60: showMA60 ?? this.showMA60,
      showMA120: showMA120 ?? this.showMA120,
      showVolume: showVolume ?? this.showVolume,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      panOffset: panOffset ?? this.panOffset,
    );
  }
}