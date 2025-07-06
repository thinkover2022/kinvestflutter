import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/stock_data_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _htsIdController = TextEditingController();
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _htsIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final domesticOrders = ref.watch(domesticOrdersProvider);
    final overseasOrders = ref.watch(overseasOrdersProvider);

    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '주문 내역',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      '국내: ${domesticOrders.length}, 해외: ${overseasOrders.length}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (!_isSubscribed)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _htsIdController,
                          decoration: const InputDecoration(
                            hintText: 'HTS ID 입력 (주문 알림 수신용)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final htsId = _htsIdController.text.trim();
                          if (htsId.isNotEmpty) {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            
                            try {
                              await ref
                                  .read(stockDataProvider.notifier)
                                  .subscribeOrderNotifications(htsId);
                              if (mounted) {
                                setState(() {
                                  _isSubscribed = true;
                                });
                                scaffoldMessenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('주문 알림 구독이 시작되었습니다'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('구독 실패: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: const Text('구독'),
                      ),
                    ],
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          '주문 알림 구독 중 (HTS ID: ${_htsIdController.text})',
                          style: TextStyle(color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '국내주식'),
              Tab(text: '해외주식'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDomesticOrdersList(domesticOrders),
                _buildOverseasOrdersList(overseasOrders),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDomesticOrdersList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('국내주식 주문 내역이 없습니다'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return DomesticOrderCard(order: order);
      },
    );
  }

  Widget _buildOverseasOrdersList(List<dynamic> orders) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('해외주식 주문 내역이 없습니다'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OverseasOrderCard(order: order);
      },
    );
  }
}

class DomesticOrderCard extends StatelessWidget {
  final dynamic order;

  const DomesticOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.stockCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(order),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('종목명: ${order.stockName}'),
                    Text(
                      '${order.isBuyOrder ? "매수" : "매도"} ${order.orderType}',
                      style: TextStyle(
                        color: order.isBuyOrder ? Colors.red : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (order.isExecuted) ...[
                      Text('체결가: ${formatter.format(order.executionPrice)}'),
                      Text('체결량: ${formatter.format(order.executionQuantity)}'),
                    ] else ...[
                      Text('주문가격: ${formatter.format(order.executionPrice)}'),
                      Text('주문량: ${formatter.format(order.orderQuantity)}'),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('주문번호: ${order.orderNumber}'),
                Text('시간: ${order.executionTime}'),
              ],
            ),
            if (order.accountName.isNotEmpty)
              Text('계좌: ${order.accountName}'),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(dynamic order) {
    if (order.isRejected) return Colors.red;
    if (order.isExecuted) return Colors.green;
    return Colors.orange;
  }

  String _getStatusText(dynamic order) {
    if (order.isRejected) return '거부';
    if (order.isExecuted) return '체결';
    return '접수';
  }
}

class OverseasOrderCard extends StatelessWidget {
  final dynamic order;

  const OverseasOrderCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###.##');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.stockCode,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _getStatusText(order),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('종목명: ${order.stockName}'),
                    Text(
                      '${order.isBuyOrder ? "매수" : "매도"} ${order.orderType2}',
                      style: TextStyle(
                        color: order.isBuyOrder ? Colors.red : Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('시장: ${order.overseasStockType}'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (order.isExecuted) ...[
                      Text('체결가: ${formatter.format(order.executionPrice)}'),
                      Text('체결량: ${formatter.format(order.executionQuantity)}'),
                    ] else ...[
                      Text('주문가격: ${formatter.format(order.executionPrice)}'),
                      Text('주문량: ${formatter.format(order.orderQuantity)}'),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('주문번호: ${order.orderNumber}'),
                Text('시간: ${order.executionTime}'),
              ],
            ),
            if (order.accountName.isNotEmpty)
              Text('계좌: ${order.accountName}'),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(dynamic order) {
    if (order.isRejected) return Colors.red;
    if (order.isExecuted) return Colors.green;
    return Colors.orange;
  }

  String _getStatusText(dynamic order) {
    if (order.isRejected) return '거부';
    if (order.isExecuted) return '체결';
    return '접수';
  }
}