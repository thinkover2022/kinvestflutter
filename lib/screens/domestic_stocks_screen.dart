import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/stock_data_provider.dart';
import '../widgets/add_stock_dialog.dart';

class DomesticStocksScreen extends ConsumerStatefulWidget {
  const DomesticStocksScreen({super.key});

  @override
  ConsumerState<DomesticStocksScreen> createState() => _DomesticStocksScreenState();
}

class _DomesticStocksScreenState extends ConsumerState<DomesticStocksScreen> {
  // 인기 한국 주식 종목 코드들
  final List<Map<String, String>> _defaultStocks = [
    {'code': '005930', 'name': '삼성전자'},
    {'code': '000660', 'name': 'SK하이닉스'},
    {'code': '035420', 'name': 'NAVER'},
    {'code': '051910', 'name': 'LG화학'},
    {'code': '006400', 'name': '삼성SDI'},
    {'code': '035720', 'name': '카카오'},
    {'code': '028260', 'name': '삼성물산'},
    {'code': '066570', 'name': 'LG전자'},
    {'code': '096770', 'name': 'SK이노베이션'},
    {'code': '207940', 'name': '삼성바이오로직스'},
    {'code': '068270', 'name': 'Celltrion'},
    {'code': '323410', 'name': '카카오뱅크'},
    {'code': '003670', 'name': '포스코홀딩스'},
    {'code': '000270', 'name': '기아'},
    {'code': '105560', 'name': 'KB금융'},
  ];

  @override
  void initState() {
    super.initState();
    // 로그인 후 기본 종목들을 자동으로 구독
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeDefaultStocks();
    });
  }

  Future<void> _subscribeDefaultStocks() async {
    final stockData = ref.read(stockDataProvider);
    if (stockData.subscribedDomesticStocks.isEmpty) {
      // 처음 5개 종목만 자동 구독
      for (int i = 0; i < 5 && i < _defaultStocks.length; i++) {
        try {
          await ref.read(stockDataProvider.notifier)
              .subscribeDomesticStock(_defaultStocks[i]['code']!);
        } catch (e) {
          // 개별 종목 구독 실패는 무시하고 계속 진행
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockData = ref.watch(stockDataProvider);
    final domesticQuotes = stockData.domesticQuotes;
    final domesticExecutions = stockData.domesticExecutions;
    final subscribedStocks = stockData.subscribedDomesticStocks;

    return Scaffold(
      body: Column(
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
            child: subscribedStocks.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_chart, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('구독중인 종목이 없습니다'),
                        Text('+ 버튼을 눌러 종목을 추가해보세요'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: subscribedStocks.length,
                    itemBuilder: (context, index) {
                      final stockCode = subscribedStocks.elementAt(index);
                      final quote = domesticQuotes[stockCode];
                      final execution = domesticExecutions[stockCode];
                      
                      // 종목 이름 찾기
                      final stockInfo = _defaultStocks.firstWhere(
                        (stock) => stock['code'] == stockCode,
                        orElse: () => {'code': stockCode, 'name': stockCode},
                      );

                      return DomesticStockQuoteCard(
                        stockCode: stockCode,
                        stockName: stockInfo['name']!,
                        quote: quote,
                        execution: execution,
                        onRemove: () async {
                          await ref
                              .read(stockDataProvider.notifier)
                              .unsubscribeDomesticStock(stockCode);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
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
              await ref
                  .read(stockDataProvider.notifier)
                  .subscribeDomesticStock(stockCode);

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
