class KoreanStock {
  final String code;
  final String name;
  final String sector;
  final String marketCap;
  final String market; // 'KOSPI' 또는 'KOSDAQ'

  const KoreanStock({
    required this.code,
    required this.name,
    required this.sector,
    required this.marketCap,
    required this.market,
  });
}

class KoreanStockData {
  static const List<KoreanStock> stocks = [
    // ========== KOSPI 종목 ==========
    // 대형주 (시가총액 상위)
    KoreanStock(code: '005930', name: '삼성전자', sector: '반도체', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '000660', name: 'SK하이닉스', sector: '반도체', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '035420', name: 'NAVER', sector: '인터넷', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '051910', name: 'LG화학', sector: '화학', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '006400', name: '삼성SDI', sector: '배터리', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '035720', name: '카카오', sector: '인터넷', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '028260', name: '삼성물산', sector: '종합상사', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '066570', name: 'LG전자', sector: '가전', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '096770', name: 'SK이노베이션', sector: '정유', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '207940', name: '삼성바이오로직스', sector: '바이오', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '068270', name: 'Celltrion', sector: '바이오', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '323410', name: '카카오뱅크', sector: '은행', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '003670', name: '포스코홀딩스', sector: '철강', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '000270', name: '기아', sector: '자동차', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '105560', name: 'KB금융', sector: '금융', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '055550', name: '신한지주', sector: '금융', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '012330', name: '현대모비스', sector: '자동차부품', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '086790', name: '하나금융지주', sector: '금융', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '003550', name: 'LG', sector: '지주회사', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '017670', name: 'SK텔레콤', sector: '통신', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '373220', name: 'LG에너지솔루션', sector: '배터리', marketCap: '대형주', market: 'KOSPI'),
    KoreanStock(code: '005380', name: '현대차', sector: '자동차', marketCap: '대형주', market: 'KOSPI'),
    
    // 중형주
    KoreanStock(code: '030200', name: 'KT', sector: '통신', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '034730', name: 'SK', sector: '지주회사', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '018260', name: '삼성에스디에스', sector: 'IT서비스', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '000810', name: '삼성화재', sector: '보험', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '015760', name: '한국전력', sector: '전력', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '032830', name: '삼성생명', sector: '보험', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '009540', name: 'HD한국조선해양', sector: '조선', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '010950', name: 'S-Oil', sector: '정유', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '000720', name: '현대건설', sector: '건설', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '047810', name: '한국항공우주', sector: '항공우주', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '004020', name: '현대제철', sector: '철강', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '090430', name: '아모레퍼시픽', sector: '화장품', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '011170', name: '롯데케미칼', sector: '화학', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '139480', name: '이마트', sector: '유통', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '021240', name: '코웨이', sector: '가전', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '000100', name: '유한양행', sector: '제약', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '185750', name: '종근당', sector: '제약', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '097950', name: 'CJ제일제당', sector: '식품', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '271560', name: '오리온', sector: '식품', marketCap: '중형주', market: 'KOSPI'),
    KoreanStock(code: '161390', name: '한국타이어앤테크놀로지', sector: '타이어', marketCap: '중형주', market: 'KOSPI'),
    
    // 소형주
    KoreanStock(code: '042660', name: '한화시스템', sector: '방산', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '000120', name: 'CJ대한통운', sector: '물류', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '010140', name: '삼성중공업', sector: '조선', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '004170', name: '신세계', sector: '유통', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '036570', name: '엔씨소프트', sector: '게임', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '251270', name: '넷마블', sector: '게임', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '112610', name: '씨에스윈드', sector: '풍력', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '329180', name: '티웨이항공', sector: '항공', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '020150', name: '롯데에너지머티리얼즈', sector: '화학', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '078930', name: 'GS', sector: '지주회사', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '035900', name: 'JYP Ent.', sector: '엔터테인먼트', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '041510', name: 'SM', sector: '엔터테인먼트', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '122870', name: '와이지엔터테인먼트', sector: '엔터테인먼트', marketCap: '소형주', market: 'KOSPI'),
    KoreanStock(code: '352820', name: '하이브', sector: '엔터테인먼트', marketCap: '중형주', market: 'KOSPI'),
    
    // ========== KOSDAQ 종목 ==========
    // 대형주 (시가총액 상위)
    KoreanStock(code: '091990', name: '셀트리온헬스케어', sector: '바이오', marketCap: '대형주', market: 'KOSDAQ'),
    KoreanStock(code: '196170', name: '알테오젠', sector: '바이오', marketCap: '대형주', market: 'KOSDAQ'),
    KoreanStock(code: '293490', name: '카카오게임즈', sector: '게임', marketCap: '대형주', market: 'KOSDAQ'),
    KoreanStock(code: '263750', name: '펄어비스', sector: '게임', marketCap: '대형주', market: 'KOSDAQ'),
    KoreanStock(code: '041510', name: 'SM', sector: '엔터테인먼트', marketCap: '대형주', market: 'KOSDAQ'),
    KoreanStock(code: '039030', name: '이오테크닉스', sector: '반도체장비', marketCap: '대형주', market: 'KOSDAQ'),
    KoreanStock(code: '214150', name: '클래시스', sector: '반도체', marketCap: '대형주', market: 'KOSDAQ'),
    KoreanStock(code: '067310', name: '하나마이크론', sector: '반도체', marketCap: '대형주', market: 'KOSDAQ'),
    KoreanStock(code: '035760', name: 'CJ ENM', sector: '미디어', marketCap: '대형주', market: 'KOSDAQ'),
    KoreanStock(code: '277810', name: '레인보우로보틱스', sector: '로봇', marketCap: '대형주', market: 'KOSDAQ'),
    
    // 중형주
    KoreanStock(code: '112040', name: '위메이드', sector: '게임', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '095660', name: '네오위즈', sector: '게임', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '225570', name: '넥슨게임즈', sector: '게임', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '376300', name: '디어유', sector: '화장품', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '348370', name: '엔켐', sector: '화학', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '145020', name: '휴젤', sector: '바이오', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '028300', name: 'HLB', sector: '바이오', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '195940', name: 'HK이노엔', sector: '제약', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '064550', name: '바이오니아', sector: '바이오', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '086900', name: '메디톡스', sector: '바이오', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '347770', name: '핌스', sector: 'IT서비스', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '357120', name: '코람코에너지리츠', sector: '리츠', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '240810', name: '원익IPS', sector: '반도체장비', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '067160', name: '아프리카TV', sector: '미디어', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '053800', name: '안랩', sector: '보안', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '066970', name: '엘앤에프', sector: '배터리소재', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '086520', name: '에코프로', sector: '배터리소재', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '247540', name: '에코프로비엠', sector: '배터리소재', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '121600', name: '나노신소재', sector: '소재', marketCap: '중형주', market: 'KOSDAQ'),
    KoreanStock(code: '234080', name: 'JW홀딩스', sector: '지주회사', marketCap: '중형주', market: 'KOSDAQ'),
    
    // 소형주
    KoreanStock(code: '034230', name: '파라다이스', sector: '레저', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '078340', name: '컴투스', sector: '게임', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '192080', name: '더블유게임즈', sector: '게임', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '192820', name: '코스맥스', sector: '화장품', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '214420', name: '토니모리', sector: '화장품', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '237690', name: '에스티팜', sector: '제약', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '246690', name: '테크노마트', sector: '유통', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '298540', name: '더네이쳐홀딩스', sector: '화장품', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '131970', name: '두산테스나', sector: '측정기', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '060280', name: '큐렉소', sector: '바이오', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '290650', name: '엘앤씨바이오', sector: '바이오', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '123700', name: 'SJM', sector: '반도체', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '178920', name: '피아이첨단소재', sector: '소재', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '058470', name: '리노공업', sector: '화학', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '036540', name: 'SFA반도체', sector: '반도체', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '140910', name: '월드게임즈', sector: '게임', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '095500', name: '미래에셋대우', sector: '증권', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '226320', name: '잇츠한불', sector: '바이오', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '032500', name: '케이엠더블유', sector: '화학', marketCap: '소형주', market: 'KOSDAQ'),
    KoreanStock(code: '263720', name: '디앤씨미디어', sector: '미디어', marketCap: '소형주', market: 'KOSDAQ'),
  ];

  // 검색 기능
  static List<KoreanStock> searchStocks(String query) {
    if (query.isEmpty) return stocks;
    
    final lowerQuery = query.toLowerCase();
    return stocks.where((stock) {
      return stock.name.toLowerCase().contains(lowerQuery) ||
             stock.code.contains(lowerQuery) ||
             stock.sector.toLowerCase().contains(lowerQuery);
    }).toList();
  }
  
  // 섹터별 필터링
  static List<KoreanStock> getStocksBySector(String sector) {
    return stocks.where((stock) => stock.sector == sector).toList();
  }
  
  // 시가총액별 필터링
  static List<KoreanStock> getStocksByMarketCap(String marketCap) {
    return stocks.where((stock) => stock.marketCap == marketCap).toList();
  }
  
  // 시장별 필터링
  static List<KoreanStock> getStocksByMarket(String market) {
    return stocks.where((stock) => stock.market == market).toList();
  }
  
  // 모든 섹터 리스트
  static List<String> getAllSectors() {
    return stocks.map((stock) => stock.sector).toSet().toList()..sort();
  }
  
  // 모든 시장 리스트
  static List<String> getAllMarkets() {
    return stocks.map((stock) => stock.market).toSet().toList()..sort();
  }
}