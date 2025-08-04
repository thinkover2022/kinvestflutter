import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/stock_data_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/add_stock_dialog.dart';
import '../widgets/kospi_stock_list_dialog.dart';
import '../data/kospi_stocks.dart';

class DomesticStocksScreen extends ConsumerStatefulWidget {
  const DomesticStocksScreen({super.key});

  @override
  ConsumerState<DomesticStocksScreen> createState() => _DomesticStocksScreenState();
}

class _DomesticStocksScreenState extends ConsumerState<DomesticStocksScreen> 
    with TickerProviderStateMixin {
  // 기본 종목 제거 - 사용자 관심종목으로 대체
  String? _selectedStockCode;
  String? _selectedStockName;
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    // 로그인 후 사용자 관심종목들을 자동으로 구독
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeUserWatchlistStocks();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _subscribeUserWatchlistStocks() async {
    print('_subscribeUserWatchlistStocks 호출됨');
    final stockData = ref.read(stockDataProvider);
    final authNotifier = ref.read(authProvider.notifier);
    final userWatchlist = authNotifier.getUserWatchlist();
    
    print('사용자 관심종목: $userWatchlist');
    print('현재 구독된 종목 수: ${stockData.subscribedDomesticStocks.length}');
    print('WebSocket 연결 상태: ${stockData.isConnected}');
    
    if (userWatchlist.isNotEmpty) {
      print('구독할 사용자 관심종목들: $userWatchlist');
      
      // 사용자 관심종목들 자동 구독
      for (final stockCode in userWatchlist) {
        try {
          print('종목 구독 시도: $stockCode');
          
          await ref.read(stockDataProvider.notifier)
              .subscribeDomesticStock(stockCode);
              
          print('종목 구독 성공: $stockCode');
        } catch (e) {
          print('종목 구독 실패: $stockCode - $e');
        }
      }
      
      // 구독 후 상태 확인
      final updatedData = ref.read(stockDataProvider);
      print('구독된 종목들: ${updatedData.subscribedDomesticStocks.toList()}');
      print('연결 상태: ${updatedData.isConnected}');
    } else {
      print('사용자 관심종목이 없습니다. 종목을 추가해주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockData = ref.watch(stockDataProvider);
    final domesticQuotes = stockData.domesticQuotes;
    final domesticExecutions = stockData.domesticExecutions;
    final subscribedStocks = stockData.subscribedDomesticStocks;

    return Scaffold(
      body: subscribedStocks.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_chart, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('구독중인 종목이 없습니다'),
                  const Text('+ 버튼을 눌러 종목을 추가해보세요'),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showStockListDialog(),
                        icon: const Icon(Icons.list),
                        label: const Text('종목 리스트에서 선택'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddStockDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('종목코드 직접 입력'),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : _selectedStockCode == null
              ? Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '국내주식 시세',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          Text(
                            '구독중: ${subscribedStocks.length}종목',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: subscribedStocks.length,
                        itemBuilder: (context, index) {
                          final stockCode = subscribedStocks.elementAt(index);
                          final quote = domesticQuotes[stockCode];
                          final execution = domesticExecutions[stockCode];
                          
                          // 종목 이름 찾기 (한국 주식 데이터에서 우선 검색)
                          final koreanStock = KoreanStockData.stocks.firstWhere(
                            (stock) => stock.code == stockCode,
                            orElse: () => KoreanStock(code: stockCode, name: stockCode, sector: '', marketCap: '', market: ''),
                          );
                          
                          // 종목 이름은 한국 주식 데이터를 사용하고, 없으면 종목코드 사용
                          final stockName = koreanStock.name != stockCode ? koreanStock.name : stockCode;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedStockCode = stockCode;
                                _selectedStockName = stockName;
                              });
                            },
                            child: DomesticStockQuoteCard(
                              stockCode: stockCode,
                              stockName: stockName,
                              quote: quote,
                              execution: execution,
                              onRemove: () async {
                                // 실시간 구독 해제
                                await ref
                                    .read(stockDataProvider.notifier)
                                    .unsubscribeDomesticStock(stockCode);
                                
                                // 사용자 관심종목에서도 제거
                                await ref
                                    .read(authProvider.notifier)
                                    .removeStockFromWatchlist(stockCode);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : _buildDetailView(),
      floatingActionButton: _selectedStockCode != null ? null : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // KOSPI 종목 리스트에서 선택
          FloatingActionButton(
            heroTag: "kospi_list",
            onPressed: () async {
              final stockCode = await showDialog<String>(
                context: context,
                builder: (context) => const KoreanStockListDialog(),
              );

              if (stockCode != null && stockCode.isNotEmpty) {
                try {
                  // 실시간 구독 추가
                  await ref
                      .read(stockDataProvider.notifier)
                      .subscribeDomesticStock(stockCode);
                  
                  // 사용자 관심종목에 추가
                  await ref
                      .read(authProvider.notifier)
                      .addStockToWatchlist(stockCode);

                  if (context.mounted) {
                    // 종목 이름 찾기
                    final stock = KoreanStockData.stocks.firstWhere(
                      (s) => s.code == stockCode,
                      orElse: () => KoreanStock(code: stockCode, name: stockCode, sector: '', marketCap: '', market: ''),
                    );
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${stock.name}($stockCode) 종목이 추가되었습니다')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('종목 추가 실패: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Icon(Icons.list),
          ),
          const SizedBox(height: 16),
          
          // 직접 종목코드 입력
          FloatingActionButton(
            heroTag: "direct_input",
            onPressed: () async {
              final stockCode = await showDialog<String>(
                context: context,
                builder: (context) => const AddStockDialog(
                  title: '국내주식 추가',
                  hintText: '종목코드 입력 (예: 005930)',
                ),
              );

              if (stockCode != null && stockCode.isNotEmpty) {
                try {
                  // 실시간 구독 추가
                  await ref
                      .read(stockDataProvider.notifier)
                      .subscribeDomesticStock(stockCode);
                  
                  // 사용자 관심종목에 추가
                  await ref
                      .read(authProvider.notifier)
                      .addStockToWatchlist(stockCode);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('$stockCode 종목이 추가되었습니다')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('종목 추가 실패: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  // 상세 뷰 빌더
  Widget _buildDetailView() {
    final stockData = ref.watch(stockDataProvider);
    final quote = stockData.domesticQuotes[_selectedStockCode];
    final execution = stockData.domesticExecutions[_selectedStockCode];

    return Column(
      children: [
        // 상단 헤더 (뒤로가기 + 종목명)
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedStockCode = null;
                    _selectedStockName = null;
                  });
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedStockName ?? '',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _selectedStockCode ?? '',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // 현재가 정보 영역 (상단 고정)
        if (execution != null)
          _buildPriceInfoHeader(execution, quote),
        
        // 탭 영역
        Expanded(
          child: Column(
            children: [
              // 탭바
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.blue,
                  tabs: const [
                    Tab(text: '시세'),
                    Tab(text: '차트'),
                    Tab(text: '투자자별매매동향'),
                    Tab(text: '뉴스/공시'),
                    Tab(text: '종목분석'),
                    Tab(text: '종목토론'),
                    Tab(text: '공매도현황'),
                  ],
                ),
              ),
              
              // 탭 내용
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQuoteTab(), // 시세
                    _buildChartTab(), // 차트
                    _buildEmptyTab('투자자별매매동향'), // 투자자별매매동향
                    _buildEmptyTab('뉴스/공시'), // 뉴스/공시
                    _buildEmptyTab('종목분석'), // 종목분석
                    _buildEmptyTab('종목토론'), // 종목토론
                    _buildEmptyTab('공매도현황'), // 공매도현황
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 다이얼로그 메서드들
  Future<void> _showStockListDialog() async {
    final stockCode = await showDialog<String>(
      context: context,
      builder: (context) => const KoreanStockListDialog(),
    );
    if (stockCode != null && stockCode.isNotEmpty) {
      await _addStock(stockCode);
    }
  }

  Future<void> _showAddStockDialog() async {
    final stockCode = await showDialog<String>(
      context: context,
      builder: (context) => const AddStockDialog(
        title: '국내주식 추가',
        hintText: '종목코드 입력 (예: 005930)',
      ),
    );
    if (stockCode != null && stockCode.isNotEmpty) {
      await _addStock(stockCode);
    }
  }

  Future<void> _addStock(String stockCode) async {
    try {
      await ref.read(stockDataProvider.notifier).subscribeDomesticStock(stockCode);
      await ref.read(authProvider.notifier).addStockToWatchlist(stockCode);

      if (context.mounted) {
        final stock = KoreanStockData.stocks.firstWhere(
          (s) => s.code == stockCode,
          orElse: () => KoreanStock(code: stockCode, name: stockCode, sector: '', marketCap: '', market: ''),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${stock.name}($stockCode) 종목이 추가되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('종목 추가 실패: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 이미지와 같은 상세 화면 구현
  Widget _buildPriceInfoHeader(dynamic execution, dynamic quote) {
    final formatter = NumberFormat('#,###');
    final changeColor = _getPriceColor(execution.changeSign);
    final changePrefix = execution.dailyChange >= 0 ? '+' : '';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 현재가 행
          Row(
            children: [
              Text(
                formatter.format(execution.currentPrice.toInt()),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '전일 ${formatter.format((execution.currentPrice - execution.dailyChange).toInt())}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '고가 ${formatter.format(execution.highPrice.toInt())} (상한가 ${formatter.format(_calculateUpperLimit(execution.currentPrice - execution.dailyChange))})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '거래량 ${_formatVolume(execution.totalVolume)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // 변동 정보 행
          Row(
            children: [
              Text(
                '전일대비 ${changePrefix}${execution.dailyChange.toInt()} ${changePrefix}${execution.changeRate.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: changeColor,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '시가 ${formatter.format(execution.openPrice.toInt())} 저가 ${formatter.format(execution.lowPrice.toInt())} (하한가 ${formatter.format(_calculateLowerLimit(execution.currentPrice - execution.dailyChange))})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    '거래대금 ${_formatAmount(execution.totalAmount)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 차트 탭
  Widget _buildChartTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '차트 기능',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'fl_chart 라이브러리로 구현 예정',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // 시세 탭 (메인 구현)
  Widget _buildQuoteTab() {
    final stockData = ref.watch(stockDataProvider);
    final quote = stockData.domesticQuotes[_selectedStockCode];
    final execution = stockData.domesticExecutions[_selectedStockCode];
    
    if (execution == null) {
      return const Center(child: Text('데이터를 불러오는 중...'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 좌측: 종목 기본 정보
            Expanded(
              flex: 1,
              child: _buildStockBasicInfo(execution),
            ),
            const SizedBox(width: 16),
            // 우측: 호가 정보
            Expanded(
              flex: 1,
              child: quote != null ? _buildQuoteInfo(quote, execution) : const Center(child: Text('호가 데이터 로딩 중...')),
            ),
          ],
        ),
      ),
    );
  }

  // 빈 탭 위젯
  Widget _buildEmptyTab(String tabName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '$tabName 탭',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '준비 중입니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // 계산 도우미 함수들
  int _calculateUpperLimit(double previousClose) {
    return (previousClose * 1.3).round(); // 상한가 +30%
  }

  int _calculateLowerLimit(double previousClose) {
    return (previousClose * 0.7).round(); // 하한가 -30%
  }

  String _formatVolume(int volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}백만';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(0)}천';
    }
    return NumberFormat('#,###').format(volume);
  }

  String _formatAmount(int amount) {
    if (amount >= 100000000) {
      return '${(amount / 100000000).toStringAsFixed(1)}억';
    } else if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만';
    }
    return NumberFormat('#,###').format(amount);
  }

  Color _getPriceColor(String changeSign) {
    switch (changeSign) {
      case '1': // 상한
      case '2': // 상승
        return Colors.red;
      case '4': // 하한  
      case '5': // 하락
        return Colors.blue;
      case '3': // 보합
      default:
        return Colors.black;
    }
  }

  // 좌측 종목 기본 정보 (이미지와 같은 형태)
  Widget _buildStockBasicInfo(dynamic execution) {
    final formatter = NumberFormat('#,###');
    final previousClose = execution.currentPrice - execution.dailyChange;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Text('주요시세', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('20분지연', style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
              ],
            ),
          ),
          
          // 정보 리스트
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                _buildInfoRow('현재가', formatter.format(execution.currentPrice.toInt()), Colors.black, isMain: true),
                _buildInfoRow('전일대비', '${execution.dailyChange >= 0 ? '+' : ''}${formatter.format(execution.dailyChange.toInt())}', _getPriceColor(execution.changeSign)),
                _buildInfoRow('등락률(%)', '${execution.dailyChange >= 0 ? '+' : ''}${execution.changeRate.toStringAsFixed(2)}%', _getPriceColor(execution.changeSign)),
                
                const Divider(height: 16),
                _buildInfoRow('거래량', _formatVolume(execution.totalVolume), Colors.black),
                _buildInfoRow('거래대금(백만)', '${(execution.totalAmount / 1000000).toStringAsFixed(0)}', Colors.black),
                
                const Divider(height: 16),
                _buildInfoRow('액면가', '5,000원', Colors.grey.shade600), // 고정값
                _buildInfoRow('시가', formatter.format(execution.openPrice.toInt()), Colors.orange.shade600),
                _buildInfoRow('고가', formatter.format(execution.highPrice.toInt()), Colors.red.shade600),
                _buildInfoRow('저가', formatter.format(execution.lowPrice.toInt()), Colors.blue.shade600),
                
                const Divider(height: 16),
                _buildInfoRow('상한가', formatter.format(_calculateUpperLimit(previousClose)), Colors.red),
                _buildInfoRow('하한가', formatter.format(_calculateLowerLimit(previousClose)), Colors.blue),
                
                const Divider(height: 16),
                _buildInfoRow('전일상한', formatter.format(_calculateUpperLimit(previousClose)), Colors.grey.shade600),
                _buildInfoRow('전일하한', formatter.format(_calculateLowerLimit(previousClose)), Colors.grey.shade600),
                
                const Divider(height: 16),
                _buildInfoRow('PER', '7.24', Colors.grey.shade600), // 이미지의 값
                _buildInfoRow('EPS', '35,682', Colors.grey.shade600), // 이미지의 값
                _buildInfoRow('52주 최고', '306,500', Colors.grey.shade600), // 이미지의 값
                _buildInfoRow('52주 최저', '144,700', Colors.grey.shade600), // 이미지의 값
                
                const Divider(height: 16),
                _buildInfoRow('시가총액', '1,881,886억원', Colors.grey.shade600), // 이미지의 값
                _buildInfoRow('상장주식수', '728,002,365', Colors.grey.shade600), // 이미지의 값
                _buildInfoRow('외국인현재', '400,963천주', Colors.grey.shade600), // 이미지의 값
                _buildInfoRow('자본금', '3,657,652백만', Colors.grey.shade600), // 이미지의 값
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor, {bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isMain ? 13 : 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isMain ? 15 : 13,
              color: valueColor,
              fontWeight: isMain ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 우측 호가 정보 (이미지와 같은 형태)
  Widget _buildQuoteInfo(dynamic quote, dynamic execution) {
    final formatter = NumberFormat('#,###');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Text('호가 (20분 지연)', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('5단계', style: TextStyle(fontSize: 10, color: Colors.blue)),
                const SizedBox(width: 4),
                Text('10단계', style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          
          // 호가 테이블 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              border: Border(bottom: BorderSide(color: Color(0xFFDDDDDD), width: 1)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('매도잔량', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('매도호가', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('매수호가', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 3, child: Text('매수잔량', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          
          // 호가 데이터 (5단계만 표시)
          Column(
            children: [
              for (int i = 0; i < 5; i++)
                Container(
                  decoration: BoxDecoration(
                    color: i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFA),
                    border: const Border(bottom: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        // 매도잔량
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
                            ),
                            child: Text(
                              formatter.format(quote.sellQuantities[i]),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                        // 매도호가
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
                            ),
                            child: Text(
                              formatter.format(quote.sellPrices[i].toInt()),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // 매수호가
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            decoration: const BoxDecoration(
                              border: Border(right: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
                            ),
                            child: Text(
                              formatter.format(quote.buyPrices[i].toInt()),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // 매수잔량
                        Expanded(
                          flex: 3,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                            child: Text(
                              formatter.format(quote.buyQuantities[i]),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          
          // 하단 합계
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F8F8),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(8),
                bottomRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text(
                  '잔량합계',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  '${formatter.format(quote.sellQuantities.take(5).fold(0, (sum, qty) => sum + qty))}',
                  style: const TextStyle(fontSize: 10, color: Colors.blue),
                ),
                Container(width: 1, height: 10, color: Colors.grey.shade300),
                Text(
                  '${formatter.format(quote.buyQuantities.take(5).fold(0, (sum, qty) => sum + qty))}',
                  style: const TextStyle(fontSize: 10, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DomesticStockQuoteCard extends StatelessWidget {
  final String stockCode;
  final String stockName;
  final dynamic quote;
  final dynamic execution;
  final VoidCallback onRemove;

  const DomesticStockQuoteCard({
    super.key,
    required this.stockCode,
    required this.stockName,
    this.quote,
    this.execution,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stockName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  stockCode,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Spacer(),
            if (execution != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(execution.currentPrice),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getPriceColor(execution.changeSign),
                    ),
                  ),
                  Text(
                    '${_getChangePrefix(execution.changeSign)}${formatter.format(execution.dailyChange)}',
                    style: TextStyle(
                      color: _getPriceColor(execution.changeSign),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '데이터 수신 중...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                ],
              ),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
        children: [
          if (quote != null) _buildQuoteInfo(),
          if (execution != null) _buildExecutionInfo(),
        ],
      ),
    );
  }

  Widget _buildQuoteInfo() {
    final formatter = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('호가 정보', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    const Text('매도호가', style: TextStyle(color: Colors.blue)),
                    for (int i = 0; i < 5; i++)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatter.format(quote.sellPrices[i])),
                          Text(formatter.format(quote.sellQuantities[i])),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    const Text('매수호가', style: TextStyle(color: Colors.red)),
                    for (int i = 0; i < 5; i++)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(formatter.format(quote.buyPrices[i])),
                          Text(formatter.format(quote.buyQuantities[i])),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExecutionInfo() {
    final formatter = NumberFormat('#,###');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('체결 정보', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('시가: ${formatter.format(execution.openPrice)}'),
                  Text('고가: ${formatter.format(execution.highPrice)}'),
                  Text('저가: ${formatter.format(execution.lowPrice)}'),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('거래량: ${formatter.format(execution.totalVolume)}'),
                  Text('거래대금: ${formatter.format(execution.totalAmount)}'),
                  Text('체결시간: ${execution.executionTime}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriceColor(String changeSign) {
    switch (changeSign) {
      case '1':
      case '2':
        return Colors.red;
      case '4':
      case '5':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  String _getChangePrefix(String changeSign) {
    switch (changeSign) {
      case '1':
      case '2':
        return '+';
      case '4':
      case '5':
        return '-';
      default:
        return '';
    }
  }
}
