class DomesticOrderNotification {
  final String customerId;
  final String accountNumber;
  final String orderNumber;
  final String originalOrderNumber;
  final String sellBuyType;
  final String correctionType;
  final String orderType;
  final String orderCondition;
  final String stockCode;
  final int executionQuantity;
  final double executionPrice;
  final String executionTime;
  final String rejectFlag;
  final String executionFlag;
  final String acceptFlag;
  final String branchNumber;
  final int orderQuantity;
  final String accountName;
  final String stockName;
  final DateTime timestamp;

  DomesticOrderNotification({
    required this.customerId,
    required this.accountNumber,
    required this.orderNumber,
    required this.originalOrderNumber,
    required this.sellBuyType,
    required this.correctionType,
    required this.orderType,
    required this.orderCondition,
    required this.stockCode,
    required this.executionQuantity,
    required this.executionPrice,
    required this.executionTime,
    required this.rejectFlag,
    required this.executionFlag,
    required this.acceptFlag,
    required this.branchNumber,
    required this.orderQuantity,
    required this.accountName,
    required this.stockName,
    required this.timestamp,
  });

  factory DomesticOrderNotification.fromJson(Map<String, dynamic> json) {
    return DomesticOrderNotification(
      customerId: json['customerId'] as String,
      accountNumber: json['accountNumber'] as String,
      orderNumber: json['orderNumber'] as String,
      originalOrderNumber: json['originalOrderNumber'] as String,
      sellBuyType: json['sellBuyType'] as String,
      correctionType: json['correctionType'] as String,
      orderType: json['orderType'] as String,
      orderCondition: json['orderCondition'] as String,
      stockCode: json['stockCode'] as String,
      executionQuantity: json['executionQuantity'] as int,
      executionPrice: json['executionPrice'] as double,
      executionTime: json['executionTime'] as String,
      rejectFlag: json['rejectFlag'] as String,
      executionFlag: json['executionFlag'] as String,
      acceptFlag: json['acceptFlag'] as String,
      branchNumber: json['branchNumber'] as String,
      orderQuantity: json['orderQuantity'] as int,
      accountName: json['accountName'] as String,
      stockName: json['stockName'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'accountNumber': accountNumber,
      'orderNumber': orderNumber,
      'originalOrderNumber': originalOrderNumber,
      'sellBuyType': sellBuyType,
      'correctionType': correctionType,
      'orderType': orderType,
      'orderCondition': orderCondition,
      'stockCode': stockCode,
      'executionQuantity': executionQuantity,
      'executionPrice': executionPrice,
      'executionTime': executionTime,
      'rejectFlag': rejectFlag,
      'executionFlag': executionFlag,
      'acceptFlag': acceptFlag,
      'branchNumber': branchNumber,
      'orderQuantity': orderQuantity,
      'accountName': accountName,
      'stockName': stockName,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory DomesticOrderNotification.fromDecryptedData(String data) {
    final parts = data.split('^');
    
    return DomesticOrderNotification(
      customerId: parts[0],
      accountNumber: parts[1],
      orderNumber: parts[2],
      originalOrderNumber: parts[3],
      sellBuyType: parts[4],
      correctionType: parts[5],
      orderType: parts[6],
      orderCondition: parts[7],
      stockCode: parts[8],
      executionQuantity: int.tryParse(parts[9]) ?? 0,
      executionPrice: double.tryParse(parts[10]) ?? 0.0,
      executionTime: parts[11],
      rejectFlag: parts[12],
      executionFlag: parts[13],
      acceptFlag: parts[14],
      branchNumber: parts[15],
      orderQuantity: int.tryParse(parts[16]) ?? 0,
      accountName: parts[17],
      stockName: parts[18],
      timestamp: DateTime.now(),
    );
  }

  bool get isExecuted => executionFlag == '2';
  bool get isRejected => rejectFlag == '1';
  bool get isBuyOrder => sellBuyType == '02';
  bool get isSellOrder => sellBuyType == '01';
}

class OverseasOrderNotification {
  final String customerId;
  final String accountNumber;
  final String orderNumber;
  final String originalOrderNumber;
  final String sellBuyType;
  final String correctionType;
  final String orderType2;
  final String stockCode;
  final int executionQuantity;
  final double executionPrice;
  final String executionTime;
  final String rejectFlag;
  final String executionFlag;
  final String acceptFlag;
  final String branchNumber;
  final int orderQuantity;
  final String accountName;
  final String stockName;
  final String overseasStockType;
  final DateTime timestamp;

  OverseasOrderNotification({
    required this.customerId,
    required this.accountNumber,
    required this.orderNumber,
    required this.originalOrderNumber,
    required this.sellBuyType,
    required this.correctionType,
    required this.orderType2,
    required this.stockCode,
    required this.executionQuantity,
    required this.executionPrice,
    required this.executionTime,
    required this.rejectFlag,
    required this.executionFlag,
    required this.acceptFlag,
    required this.branchNumber,
    required this.orderQuantity,
    required this.accountName,
    required this.stockName,
    required this.overseasStockType,
    required this.timestamp,
  });

  factory OverseasOrderNotification.fromJson(Map<String, dynamic> json) {
    return OverseasOrderNotification(
      customerId: json['customerId'] as String,
      accountNumber: json['accountNumber'] as String,
      orderNumber: json['orderNumber'] as String,
      originalOrderNumber: json['originalOrderNumber'] as String,
      sellBuyType: json['sellBuyType'] as String,
      correctionType: json['correctionType'] as String,
      orderType2: json['orderType2'] as String,
      stockCode: json['stockCode'] as String,
      executionQuantity: json['executionQuantity'] as int,
      executionPrice: json['executionPrice'] as double,
      executionTime: json['executionTime'] as String,
      rejectFlag: json['rejectFlag'] as String,
      executionFlag: json['executionFlag'] as String,
      acceptFlag: json['acceptFlag'] as String,
      branchNumber: json['branchNumber'] as String,
      orderQuantity: json['orderQuantity'] as int,
      accountName: json['accountName'] as String,
      stockName: json['stockName'] as String,
      overseasStockType: json['overseasStockType'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'accountNumber': accountNumber,
      'orderNumber': orderNumber,
      'originalOrderNumber': originalOrderNumber,
      'sellBuyType': sellBuyType,
      'correctionType': correctionType,
      'orderType2': orderType2,
      'stockCode': stockCode,
      'executionQuantity': executionQuantity,
      'executionPrice': executionPrice,
      'executionTime': executionTime,
      'rejectFlag': rejectFlag,
      'executionFlag': executionFlag,
      'acceptFlag': acceptFlag,
      'branchNumber': branchNumber,
      'orderQuantity': orderQuantity,
      'accountName': accountName,
      'stockName': stockName,
      'overseasStockType': overseasStockType,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory OverseasOrderNotification.fromDecryptedData(String data) {
    final parts = data.split('^');
    
    return OverseasOrderNotification(
      customerId: parts[0],
      accountNumber: parts[1],
      orderNumber: parts[2],
      originalOrderNumber: parts[3],
      sellBuyType: parts[4],
      correctionType: parts[5],
      orderType2: parts[6],
      stockCode: parts[7],
      executionQuantity: int.tryParse(parts[8]) ?? 0,
      executionPrice: double.tryParse(parts[9]) ?? 0.0,
      executionTime: parts[10],
      rejectFlag: parts[11],
      executionFlag: parts[12],
      acceptFlag: parts[13],
      branchNumber: parts[14],
      orderQuantity: int.tryParse(parts[15]) ?? 0,
      accountName: parts[16],
      stockName: parts[17],
      overseasStockType: parts[18],
      timestamp: DateTime.now(),
    );
  }

  bool get isExecuted => executionFlag == '2';
  bool get isRejected => rejectFlag == '1';
  bool get isBuyOrder => sellBuyType == '02';
  bool get isSellOrder => sellBuyType == '01';
}