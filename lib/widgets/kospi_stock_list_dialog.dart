import 'package:flutter/material.dart';
import '../data/kospi_stocks.dart';

class KoreanStockListDialog extends StatefulWidget {
  const KoreanStockListDialog({super.key});

  @override
  State<KoreanStockListDialog> createState() => _KoreanStockListDialogState();
}

class _KoreanStockListDialogState extends State<KoreanStockListDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<KoreanStock> _filteredStocks = KoreanStockData.stocks;
  String _selectedSector = '전체';
  String _selectedMarketCap = '전체';
  String _selectedMarket = '전체';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterStocks();
  }

  void _filterStocks() {
    setState(() {
      List<KoreanStock> stocks = KoreanStockData.stocks;

      // 시장 필터링
      if (_selectedMarket != '전체') {
        stocks =
            stocks.where((stock) => stock.market == _selectedMarket).toList();
      }

      // 섹터 필터링
      if (_selectedSector != '전체') {
        stocks =
            stocks.where((stock) => stock.sector == _selectedSector).toList();
      }

      // 시가총액 필터링
      if (_selectedMarketCap != '전체') {
        stocks = stocks
            .where((stock) => stock.marketCap == _selectedMarketCap)
            .toList();
      }

      // 검색어 필터링
      final query = _searchController.text.toLowerCase();
      if (query.isNotEmpty) {
        stocks = stocks.where((stock) {
          return stock.name.toLowerCase().contains(query) ||
              stock.code.contains(query) ||
              stock.sector.toLowerCase().contains(query);
        }).toList();
      }

      _filteredStocks = stocks;
    });
  }

  @override
  Widget build(BuildContext context) {
    final markets = ['전체', ...KoreanStockData.getAllMarkets()];
    final sectors = ['전체', ...KoreanStockData.getAllSectors()];
    final marketCaps = ['전체', '대형주', '중형주', '소형주'];

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              children: [
                const Text(
                  '국내주식 종목 선택',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 검색창
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: '종목명 또는 종목코드 검색',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // 필터 옵션
            Row(
              children: [
                // 시장 필터
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMarket,
                    decoration: const InputDecoration(
                      labelText: '시장',
                      border: OutlineInputBorder(),
                    ),
                    items: markets.map((market) {
                      return DropdownMenuItem(
                        value: market,
                        child: Text(market),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMarket = value!;
                        // 시장 변경 시 섹터 필터 초기화
                        _selectedSector = '전체';
                      });
                      _filterStocks();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // 섹터 필터
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSector,
                    decoration: const InputDecoration(
                      labelText: '섹터',
                      border: OutlineInputBorder(),
                    ),
                    items: sectors.map((sector) {
                      return DropdownMenuItem(
                        value: sector,
                        child: Text(sector),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSector = value!;
                      });
                      _filterStocks();
                    },
                  ),
                ),
                const SizedBox(width: 12),

                // 시가총액 필터
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedMarketCap,
                    decoration: const InputDecoration(
                      labelText: '시가총액',
                      border: OutlineInputBorder(),
                    ),
                    items: marketCaps.map((cap) {
                      return DropdownMenuItem(
                        value: cap,
                        child: Text(cap),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMarketCap = value!;
                      });
                      _filterStocks();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 결과 개수
            Text(
              '검색 결과: ${_filteredStocks.length}개',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),

            // 종목 리스트
            Expanded(
              child: ListView.builder(
                itemCount: _filteredStocks.length,
                itemBuilder: (context, index) {
                  final stock = _filteredStocks[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    child: ListTile(
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _getMarketColor(stock.market),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              stock.market,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              stock.marketCap[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        stock.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '종목코드: ${stock.code}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            '섹터: ${stock.sector}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Chip(
                            label: Text(
                              stock.market,
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: _getMarketColor(stock.market)
                                .withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stock.marketCap,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.of(context).pop(stock.code);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMarketColor(String market) {
    switch (market) {
      case 'KOSPI':
        return Colors.blue;
      case 'KOSDAQ':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getMarketCapColor(String marketCap) {
    switch (marketCap) {
      case '대형주':
        return Colors.blue;
      case '중형주':
        return Colors.green;
      case '소형주':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
