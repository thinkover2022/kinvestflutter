import 'lib/utils/market_hours.dart';
import 'lib/widgets/login_settings_dialog.dart';

void main() {
  print('=== MarketHours 동작 테스트 ===\n');
  
  // 다양한 시간대 테스트
  final testTimes = [
    DateTime(2024, 1, 15, 8, 0),   // 월요일 08:00 (장마감)
    DateTime(2024, 1, 15, 8, 45),  // 월요일 08:45 (장전 시간외)
    DateTime(2024, 1, 15, 9, 0),   // 월요일 09:00 (장 개장)
    DateTime(2024, 1, 15, 12, 0),  // 월요일 12:00 (장중)
    DateTime(2024, 1, 15, 15, 0),  // 월요일 15:00 (장중)
    DateTime(2024, 1, 15, 15, 30), // 월요일 15:30 (장 마감)
    DateTime(2024, 1, 15, 16, 0),  // 월요일 16:00 (장후 시간외)
    DateTime(2024, 1, 15, 18, 0),  // 월요일 18:00 (장마감)
    DateTime(2024, 1, 15, 20, 0),  // 월요일 20:00 (장마감)
    DateTime(2024, 1, 13, 12, 0),  // 토요일 12:00 (주말)
    DateTime(2024, 1, 14, 12, 0),  // 일요일 12:00 (주말)
  ];
  
  for (final testTime in testTimes) {
    // 임시로 현재 시간을 변경하는 것처럼 시뮬레이션
    final weekdayName = ['', '월', '화', '수', '목', '금', '토', '일'][testTime.weekday];
    final timeStr = '${testTime.hour.toString().padLeft(2, '0')}:${testTime.minute.toString().padLeft(2, '0')}';
    
    print('📅 시간: $weekdayName요일 $timeStr');
    
    // MarketHours 상태 확인 (실제 현재 시간 사용)
    final isMarketOpen = _isMarketOpenAt(testTime);
    final isRealtimeAvailable = _isRealtimeDataAvailableAt(testTime);
    final optimalDataSource = _getOptimalDataSourceAt(testTime);
    
    print('  • 장 운영: ${isMarketOpen ? "열림" : "닫힘"}');
    print('  • 실시간 데이터: ${isRealtimeAvailable ? "사용가능" : "불가능"}');
    print('  • 최적 데이터소스: ${optimalDataSource.name}');
    print('  • UI 표시: ${optimalDataSource.getContextualDisplayNameAt(testTime)}');
    print('');
  }
}

// 테스트용 MarketHours 메서드들 (특정 시간 기준)
bool _isMarketOpenAt(DateTime time) {
  if (time.weekday == DateTime.saturday || time.weekday == DateTime.sunday) {
    return false;
  }
  
  final marketOpen = DateTime(time.year, time.month, time.day, 9, 0);
  final marketClose = DateTime(time.year, time.month, time.day, 15, 30);
  
  return time.isAfter(marketOpen) && time.isBefore(marketClose);
}

bool _isRealtimeDataAvailableAt(DateTime time) {
  if (time.weekday == DateTime.saturday || time.weekday == DateTime.sunday) {
    return false;
  }
  
  final dataStart = DateTime(time.year, time.month, time.day, 8, 30);
  final dataEnd = DateTime(time.year, time.month, time.day, 18, 0);
  
  return time.isAfter(dataStart) && time.isBefore(dataEnd);
}

DataSourceType _getOptimalDataSourceAt(DateTime time) {
  if (_isMarketOpenAt(time)) {
    return DataSourceType.websocket;
  } else {
    return DataSourceType.https;
  }
}

// 테스트용 확장 메서드
extension DataSourceTypeTestExtension on DataSourceType {
  String getContextualDisplayNameAt(DateTime time) {
    switch (this) {
      case DataSourceType.websocket:
        return 'WebSocket (장중 실시간)';
        
      case DataSourceType.https:
        if (time.weekday == DateTime.saturday || time.weekday == DateTime.sunday) {
          return 'HTTPS (주말)';
        }
        
        if (time.hour < 9 || (time.hour == 8 && time.minute >= 30)) {
          if (time.hour == 8 && time.minute >= 30) {
            return 'HTTPS (장전 시간외)';
          }
          return 'HTTPS (장마감)';
        } else if (time.hour > 15 || (time.hour == 15 && time.minute >= 30)) {
          if (time.hour < 18) {
            return 'HTTPS (장후 시간외)';
          } else {
            return 'HTTPS (장마감)';
          }
        } else {
          return 'HTTPS (주기적 조회)';
        }
    }
  }
}