class DomesticStockQuote {
  final String stockCode;
  final String businessTime;
  final String timeCode;
  final List<double> sellPrices;
  final List<double> buyPrices;
  final List<int> sellQuantities;
  final List<int> buyQuantities;
  final int totalSellQuantity;
  final int totalBuyQuantity;
  final double expectedPrice;
  final int expectedQuantity;
  final DateTime timestamp;

  DomesticStockQuote({
    required this.stockCode,
    required this.businessTime,
    required this.timeCode,
    required this.sellPrices,
    required this.buyPrices,
    required this.sellQuantities,
    required this.buyQuantities,
    required this.totalSellQuantity,
    required this.totalBuyQuantity,
    required this.expectedPrice,
    required this.expectedQuantity,
    required this.timestamp,
  });

  factory DomesticStockQuote.fromJson(Map<String, dynamic> json) {
    return DomesticStockQuote(
      stockCode: json['stockCode'] as String,
      businessTime: json['businessTime'] as String,
      timeCode: json['timeCode'] as String,
      sellPrices: List<double>.from(json['sellPrices']),
      buyPrices: List<double>.from(json['buyPrices']),
      sellQuantities: List<int>.from(json['sellQuantities']),
      buyQuantities: List<int>.from(json['buyQuantities']),
      totalSellQuantity: json['totalSellQuantity'] as int,
      totalBuyQuantity: json['totalBuyQuantity'] as int,
      expectedPrice: json['expectedPrice'] as double,
      expectedQuantity: json['expectedQuantity'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockCode': stockCode,
      'businessTime': businessTime,
      'timeCode': timeCode,
      'sellPrices': sellPrices,
      'buyPrices': buyPrices,
      'sellQuantities': sellQuantities,
      'buyQuantities': buyQuantities,
      'totalSellQuantity': totalSellQuantity,
      'totalBuyQuantity': totalBuyQuantity,
      'expectedPrice': expectedPrice,
      'expectedQuantity': expectedQuantity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DomesticStockQuote.fromWebSocketData(String data) {
    final parts = data.split('^');
    
    return DomesticStockQuote(
      stockCode: parts[0],
      businessTime: parts[1],
      timeCode: parts[2],
      sellPrices: List.generate(10, (i) => double.tryParse(parts[3 + i]) ?? 0.0),
      buyPrices: List.generate(10, (i) => double.tryParse(parts[13 + i]) ?? 0.0),
      sellQuantities: List.generate(10, (i) => int.tryParse(parts[23 + i]) ?? 0),
      buyQuantities: List.generate(10, (i) => int.tryParse(parts[33 + i]) ?? 0),
      totalSellQuantity: int.tryParse(parts[43]) ?? 0,
      totalBuyQuantity: int.tryParse(parts[44]) ?? 0,
      expectedPrice: double.tryParse(parts[47]) ?? 0.0,
      expectedQuantity: int.tryParse(parts[48]) ?? 0,
      timestamp: DateTime.now(),
    );
  }
}

class OverseasStockQuote {
  final String realtimeCode;
  final String stockCode;
  final String decimalPlaces;
  final String localDate;
  final String localTime;
  final String koreaDate;
  final String koreaTime;
  final int totalBuyQuantity;
  final int totalSellQuantity;
  final double buyPrice;
  final double sellPrice;
  final int buyQuantity;
  final int sellQuantity;
  final DateTime timestamp;

  OverseasStockQuote({
    required this.realtimeCode,
    required this.stockCode,
    required this.decimalPlaces,
    required this.localDate,
    required this.localTime,
    required this.koreaDate,
    required this.koreaTime,
    required this.totalBuyQuantity,
    required this.totalSellQuantity,
    required this.buyPrice,
    required this.sellPrice,
    required this.buyQuantity,
    required this.sellQuantity,
    required this.timestamp,
  });

  factory OverseasStockQuote.fromJson(Map<String, dynamic> json) {
    return OverseasStockQuote(
      realtimeCode: json['realtimeCode'] as String,
      stockCode: json['stockCode'] as String,
      decimalPlaces: json['decimalPlaces'] as String,
      localDate: json['localDate'] as String,
      localTime: json['localTime'] as String,
      koreaDate: json['koreaDate'] as String,
      koreaTime: json['koreaTime'] as String,
      totalBuyQuantity: json['totalBuyQuantity'] as int,
      totalSellQuantity: json['totalSellQuantity'] as int,
      buyPrice: json['buyPrice'] as double,
      sellPrice: json['sellPrice'] as double,
      buyQuantity: json['buyQuantity'] as int,
      sellQuantity: json['sellQuantity'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'realtimeCode': realtimeCode,
      'stockCode': stockCode,
      'decimalPlaces': decimalPlaces,
      'localDate': localDate,
      'localTime': localTime,
      'koreaDate': koreaDate,
      'koreaTime': koreaTime,
      'totalBuyQuantity': totalBuyQuantity,
      'totalSellQuantity': totalSellQuantity,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'buyQuantity': buyQuantity,
      'sellQuantity': sellQuantity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory OverseasStockQuote.fromWebSocketData(String data) {
    final parts = data.split('^');
    
    return OverseasStockQuote(
      realtimeCode: parts[0],
      stockCode: parts[1],
      decimalPlaces: parts[2],
      localDate: parts[3],
      localTime: parts[4],
      koreaDate: parts[5],
      koreaTime: parts[6],
      totalBuyQuantity: int.tryParse(parts[7]) ?? 0,
      totalSellQuantity: int.tryParse(parts[8]) ?? 0,
      buyPrice: double.tryParse(parts[11]) ?? 0.0,
      sellPrice: double.tryParse(parts[12]) ?? 0.0,
      buyQuantity: int.tryParse(parts[13]) ?? 0,
      sellQuantity: int.tryParse(parts[14]) ?? 0,
      timestamp: DateTime.now(),
    );
  }
}