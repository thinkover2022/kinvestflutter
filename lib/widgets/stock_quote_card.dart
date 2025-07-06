import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StockQuoteCard extends StatelessWidget {
  final String stockCode;
  final String? stockName;
  final Widget child;

  const StockQuoteCard({
    super.key,
    required this.stockCode,
    this.stockName,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  stockCode,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (stockName != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    stockName!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class QuoteInfoWidget extends StatelessWidget {
  final List<double> sellPrices;
  final List<double> buyPrices;
  final List<int> sellQuantities;
  final List<int> buyQuantities;
  final int maxLevels;

  const QuoteInfoWidget({
    super.key,
    required this.sellPrices,
    required this.buyPrices,
    required this.sellQuantities,
    required this.buyQuantities,
    this.maxLevels = 5,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text(
                    '매도호가',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Center(
                  child: Text(
                    '매수호가',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (int i = 0; i < maxLevels && i < sellPrices.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatter.format(sellPrices[i]),
                        style: const TextStyle(color: Colors.blue),
                      ),
                      Text(
                        formatter.format(sellQuantities[i]),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatter.format(buyPrices[i]),
                        style: const TextStyle(color: Colors.red),
                      ),
                      Text(
                        formatter.format(buyQuantities[i]),
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class ExecutionInfoWidget extends StatelessWidget {
  final double currentPrice;
  final String changeSign;
  final double dailyChange;
  final double changeRate;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final int totalVolume;
  final String executionTime;

  const ExecutionInfoWidget({
    super.key,
    required this.currentPrice,
    required this.changeSign,
    required this.dailyChange,
    required this.changeRate,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.totalVolume,
    required this.executionTime,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    final priceColor = _getPriceColor(changeSign);
    final changePrefix = _getChangePrefix(changeSign);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatter.format(currentPrice),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: priceColor,
                  ),
                ),
                Text(
                  '$changePrefix${formatter.format(dailyChange)} (${changeRate.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: priceColor,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('거래량: ${formatter.format(totalVolume)}'),
                Text('체결시간: $executionTime'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPriceInfo('시가', openPrice),
            _buildPriceInfo('고가', highPrice),
            _buildPriceInfo('저가', lowPrice),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceInfo(String label, double price) {
    final formatter = NumberFormat('#,###');
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          formatter.format(price),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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
