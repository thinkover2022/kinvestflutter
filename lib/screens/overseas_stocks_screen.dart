import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/stock_data_provider.dart';

class OverseasStocksScreen extends ConsumerWidget {
  const OverseasStocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockData = ref.watch(stockDataProvider);
    final overseasQuotes = stockData.overseasQuotes;
    final overseasExecutions = stockData.overseasExecutions;
    final subscribedStocks = stockData.subscribedOverseasStocks;

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '해외주식 시세',
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
                        Icon(Icons.public, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('구독중인 해외주식이 없습니다'),
                        Text('+ 버튼을 눌러 종목을 추가해보세요'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: subscribedStocks.length,
                    itemBuilder: (context, index) {
                      final stockCode = subscribedStocks.elementAt(index);
                      final quote = overseasQuotes[stockCode];
                      final execution = overseasExecutions[stockCode];

                      return OverseasStockQuoteCard(
                        stockCode: stockCode,
                        quote: quote,
                        execution: execution,
                        onRemove: () async {
                          // 해외주식 구독 해제는 현재 구현되지 않음
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('해외주식 구독 해제 기능은 준비 중입니다'),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => const AddOverseasStockDialog(),
          );

          if (result != null) {
            final stockCode = result['stockCode'] as String;
            final isAsia = result['isAsia'] as bool;

            try {
              await ref
                  .read(stockDataProvider.notifier)
                  .subscribeOverseasStock(stockCode, isAsia: isAsia);

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

class AddOverseasStockDialog extends StatefulWidget {
  const AddOverseasStockDialog({super.key});

  @override
  State<AddOverseasStockDialog> createState() => _AddOverseasStockDialogState();
}

class _AddOverseasStockDialogState extends State<AddOverseasStockDialog> {
  final _controller = TextEditingController();
  bool _isAsia = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('해외주식 추가'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: '종목코드 입력 (예: DNASAAPL, DHKS00003)',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _isAsia,
                onChanged: (value) {
                  setState(() {
                    _isAsia = value ?? false;
                  });
                },
              ),
              const Text('아시아 시장 (일본, 홍콩, 중국 등)'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.isNotEmpty) {
              Navigator.of(context).pop({
                'stockCode': _controller.text.trim(),
                'isAsia': _isAsia,
              });
            }
          },
          child: const Text('추가'),
        ),
      ],
    );
  }
}

class OverseasStockQuoteCard extends StatelessWidget {
  final String stockCode;
  final dynamic quote;
  final dynamic execution;
  final VoidCallback onRemove;

  const OverseasStockQuoteCard({
    super.key,
    required this.stockCode,
    this.quote,
    this.execution,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###.##');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ExpansionTile(
        title: Row(
          children: [
            Text(
              stockCode,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            if (execution != null) ...[
              Text(
                formatter.format(execution.currentPrice),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _getPriceColor(execution.changeSign),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_getChangePrefix(execution.changeSign)}${formatter.format(execution.dailyChange)}',
                style: TextStyle(
                  color: _getPriceColor(execution.changeSign),
                ),
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
    final formatter = NumberFormat('#,###.##');

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('호가 정보', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text('매수호가', style: TextStyle(color: Colors.red)),
                  Text(formatter.format(quote.buyPrice)),
                  Text('수량: ${formatter.format(quote.buyQuantity)}'),
                ],
              ),
              Column(
                children: [
                  const Text('매도호가', style: TextStyle(color: Colors.blue)),
                  Text(formatter.format(quote.sellPrice)),
                  Text('수량: ${formatter.format(quote.sellQuantity)}'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('현지시간: ${quote.localDate} ${quote.localTime}'),
          Text('한국시간: ${quote.koreaDate} ${quote.koreaTime}'),
        ],
      ),
    );
  }

  Widget _buildExecutionInfo() {
    final formatter = NumberFormat('#,###.##');

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
                  Text('등락률: ${execution.changeRate.toStringAsFixed(2)}%'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('현지시간: ${execution.localDate} ${execution.localTime}'),
          Text('한국시간: ${execution.koreaDate} ${execution.koreaTime}'),
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
