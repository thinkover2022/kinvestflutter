class DomesticStockExecution {
  final String stockCode;
  final String executionTime;
  final double currentPrice;
  final String changeSign;
  final double dailyChange;
  final double changeRate;
  final double weightedAvgPrice;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double sellPrice1;
  final double buyPrice1;
  final int executionVolume;
  final int totalVolume;
  final int totalAmount;
  final DateTime timestamp;

  DomesticStockExecution({
    required this.stockCode,
    required this.executionTime,
    required this.currentPrice,
    required this.changeSign,
    required this.dailyChange,
    required this.changeRate,
    required this.weightedAvgPrice,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.sellPrice1,
    required this.buyPrice1,
    required this.executionVolume,
    required this.totalVolume,
    required this.totalAmount,
    required this.timestamp,
  });

  factory DomesticStockExecution.fromJson(Map<String, dynamic> json) {
    return DomesticStockExecution(
      stockCode: json['stockCode'] as String,
      executionTime: json['executionTime'] as String,
      currentPrice: json['currentPrice'] as double,
      changeSign: json['changeSign'] as String,
      dailyChange: json['dailyChange'] as double,
      changeRate: json['changeRate'] as double,
      weightedAvgPrice: json['weightedAvgPrice'] as double,
      openPrice: json['openPrice'] as double,
      highPrice: json['highPrice'] as double,
      lowPrice: json['lowPrice'] as double,
      sellPrice1: json['sellPrice1'] as double,
      buyPrice1: json['buyPrice1'] as double,
      executionVolume: json['executionVolume'] as int,
      totalVolume: json['totalVolume'] as int,
      totalAmount: json['totalAmount'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stockCode': stockCode,
      'executionTime': executionTime,
      'currentPrice': currentPrice,
      'changeSign': changeSign,
      'dailyChange': dailyChange,
      'changeRate': changeRate,
      'weightedAvgPrice': weightedAvgPrice,
      'openPrice': openPrice,
      'highPrice': highPrice,
      'lowPrice': lowPrice,
      'sellPrice1': sellPrice1,
      'buyPrice1': buyPrice1,
      'executionVolume': executionVolume,
      'totalVolume': totalVolume,
      'totalAmount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DomesticStockExecution.fromWebSocketData(String data) {
    final parts = data.split('^');
    
    return DomesticStockExecution(
      stockCode: parts[0],
      executionTime: parts[1],
      currentPrice: double.tryParse(parts[2]) ?? 0.0,
      changeSign: parts[3],
      dailyChange: double.tryParse(parts[4]) ?? 0.0,
      changeRate: double.tryParse(parts[5]) ?? 0.0,
      weightedAvgPrice: double.tryParse(parts[6]) ?? 0.0,
      openPrice: double.tryParse(parts[7]) ?? 0.0,
      highPrice: double.tryParse(parts[8]) ?? 0.0,
      lowPrice: double.tryParse(parts[9]) ?? 0.0,
      sellPrice1: double.tryParse(parts[10]) ?? 0.0,
      buyPrice1: double.tryParse(parts[11]) ?? 0.0,
      executionVolume: int.tryParse(parts[12]) ?? 0,
      totalVolume: int.tryParse(parts[13]) ?? 0,
      totalAmount: int.tryParse(parts[14]) ?? 0,
      timestamp: DateTime.now(),
    );
  }
}

class OverseasStockExecution {
  final String realtimeCode;
  final String stockCode;
  final String decimalPlaces;
  final String localBusinessDate;
  final String localDate;
  final String localTime;
  final String koreaDate;
  final String koreaTime;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double currentPrice;
  final String changeSign;
  final double dailyChange;
  final double changeRate;
  final double sellPrice;
  final double buyPrice;
  final int sellQuantity;
  final int buyQuantity;
  final int executionVolume;
  final int totalVolume;
  final int totalAmount;
  final DateTime timestamp;

  OverseasStockExecution({
    required this.realtimeCode,
    required this.stockCode,
    required this.decimalPlaces,
    required this.localBusinessDate,
    required this.localDate,
    required this.localTime,
    required this.koreaDate,
    required this.koreaTime,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.currentPrice,
    required this.changeSign,
    required this.dailyChange,
    required this.changeRate,
    required this.sellPrice,
    required this.buyPrice,
    required this.sellQuantity,
    required this.buyQuantity,
    required this.executionVolume,
    required this.totalVolume,
    required this.totalAmount,
    required this.timestamp,
  });

  factory OverseasStockExecution.fromJson(Map<String, dynamic> json) {
    return OverseasStockExecution(
      realtimeCode: json['realtimeCode'] as String,
      stockCode: json['stockCode'] as String,
      decimalPlaces: json['decimalPlaces'] as String,
      localBusinessDate: json['localBusinessDate'] as String,
      localDate: json['localDate'] as String,
      localTime: json['localTime'] as String,
      koreaDate: json['koreaDate'] as String,
      koreaTime: json['koreaTime'] as String,
      openPrice: json['openPrice'] as double,
      highPrice: json['highPrice'] as double,
      lowPrice: json['lowPrice'] as double,
      currentPrice: json['currentPrice'] as double,
      changeSign: json['changeSign'] as String,
      dailyChange: json['dailyChange'] as double,
      changeRate: json['changeRate'] as double,
      sellPrice: json['sellPrice'] as double,
      buyPrice: json['buyPrice'] as double,
      sellQuantity: json['sellQuantity'] as int,
      buyQuantity: json['buyQuantity'] as int,
      executionVolume: json['executionVolume'] as int,
      totalVolume: json['totalVolume'] as int,
      totalAmount: json['totalAmount'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'realtimeCode': realtimeCode,
      'stockCode': stockCode,
      'decimalPlaces': decimalPlaces,
      'localBusinessDate': localBusinessDate,
      'localDate': localDate,
      'localTime': localTime,
      'koreaDate': koreaDate,
      'koreaTime': koreaTime,
      'openPrice': openPrice,
      'highPrice': highPrice,
      'lowPrice': lowPrice,
      'currentPrice': currentPrice,
      'changeSign': changeSign,
      'dailyChange': dailyChange,
      'changeRate': changeRate,
      'sellPrice': sellPrice,
      'buyPrice': buyPrice,
      'sellQuantity': sellQuantity,
      'buyQuantity': buyQuantity,
      'executionVolume': executionVolume,
      'totalVolume': totalVolume,
      'totalAmount': totalAmount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory OverseasStockExecution.fromWebSocketData(String data) {
    final parts = data.split('^');
    
    return OverseasStockExecution(
      realtimeCode: parts[0],
      stockCode: parts[1],
      decimalPlaces: parts[2],
      localBusinessDate: parts[3],
      localDate: parts[4],
      localTime: parts[5],
      koreaDate: parts[6],
      koreaTime: parts[7],
      openPrice: double.tryParse(parts[8]) ?? 0.0,
      highPrice: double.tryParse(parts[9]) ?? 0.0,
      lowPrice: double.tryParse(parts[10]) ?? 0.0,
      currentPrice: double.tryParse(parts[11]) ?? 0.0,
      changeSign: parts[12],
      dailyChange: double.tryParse(parts[13]) ?? 0.0,
      changeRate: double.tryParse(parts[14]) ?? 0.0,
      sellPrice: double.tryParse(parts[15]) ?? 0.0,
      buyPrice: double.tryParse(parts[16]) ?? 0.0,
      sellQuantity: int.tryParse(parts[17]) ?? 0,
      buyQuantity: int.tryParse(parts[18]) ?? 0,
      executionVolume: int.tryParse(parts[19]) ?? 0,
      totalVolume: int.tryParse(parts[20]) ?? 0,
      totalAmount: int.tryParse(parts[21]) ?? 0,
      timestamp: DateTime.now(),
    );
  }
}