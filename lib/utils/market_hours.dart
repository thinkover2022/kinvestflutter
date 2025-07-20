class MarketHours {
  // 한국 주식시장 운영시간 체크 (정규장: 09:00-15:30)
  static bool isMarketOpen() {
    final now = DateTime.now();

    // 주말 체크 (토요일 = 6, 일요일 = 7)
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return false;
    }

    // 장 시간: 평일 09:00 ~ 15:30
    final marketOpen = DateTime(now.year, now.month, now.day, 9, 0);
    final marketClose = DateTime(now.year, now.month, now.day, 15, 30);

    return now.isAfter(marketOpen) && now.isBefore(marketClose);
  }

  // KIS API 실시간 데이터 제공 시간 체크 (08:30-18:00)
  static bool isRealtimeDataAvailable() {
    final now = DateTime.now();

    // 주말 체크 (토요일 = 6, 일요일 = 7)
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return false;
    }

    // 실시간 데이터 제공 시간: 평일 08:30 ~ 18:00
    final dataStart = DateTime(now.year, now.month, now.day, 8, 30);
    final dataEnd = DateTime(now.year, now.month, now.day, 18, 0);

    return now.isAfter(dataStart) && now.isBefore(dataEnd);
  }

  // 다음 장 개장 시간 계산
  static DateTime getNextMarketOpen() {
    final now = DateTime.now();
    var nextOpen = DateTime(now.year, now.month, now.day, 9, 0);

    // 오늘 장이 이미 시작되었거나 끝났다면 다음 날로
    if (now.hour >= 9) {
      nextOpen = nextOpen.add(const Duration(days: 1));
    }

    // 주말이면 월요일로 이동
    while (nextOpen.weekday == DateTime.saturday ||
        nextOpen.weekday == DateTime.sunday) {
      nextOpen = nextOpen.add(const Duration(days: 1));
    }

    return nextOpen;
  }

  // 장 마감까지 남은 시간
  static Duration? timeUntilMarketClose() {
    if (!isMarketOpen()) return null;

    final now = DateTime.now();
    final marketClose = DateTime(now.year, now.month, now.day, 15, 30);

    return marketClose.difference(now);
  }

  // 장 상태 텍스트
  static String getMarketStatusText() {
    final now = DateTime.now();

    if (isMarketOpen()) {
      final remaining = timeUntilMarketClose();
      if (remaining != null) {
        final hours = remaining.inHours;
        final minutes = remaining.inMinutes % 60;
        return '장 운영중 ($hours시간 $minutes분 남음)';
      }
      return '장 운영중';
    } else if (isRealtimeDataAvailable()) {
      // 08:30-09:00 (장전) 또는 15:30-18:00 (장후)
      if (now.hour < 9) {
        return '장전시간외거래 (전일종가 기준)';
      } else {
        return '장후시간외거래 (당일종가 기준)';
      }
    } else {
      // 18:00-08:30 (실시간 데이터 없음)
      final nextOpen = getNextMarketOpen();
      final diff = nextOpen.difference(now);

      if (diff.inDays > 0) {
        return '장 마감 (${diff.inDays}일 후 개장)';
      } else {
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        return '장 마감 ($hours시간 $minutes분 후 개장)';
      }
    }
  }
}
