import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stock_data_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_button.dart';
import '../widgets/login_settings_dialog.dart';
import '../services/kis_quote_service.dart';
import 'domestic_stocks_screen.dart';
import 'overseas_stocks_screen.dart';
import 'orders_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  bool _isInitialized = false;

  final List<Widget> _screens = [
    const DomesticStocksScreen(),
    const OverseasStocksScreen(),
    const OrdersScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 로그인 상태에 따라 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndInitialize();
    });
  }

  void _checkAuthAndInitialize() {
    final isLoggedIn = ref.read(isLoggedInProvider);
    if (isLoggedIn && !_isInitialized) {
      _initializeConnection();
    }
  }

  Future<void> _initializeConnection() async {
    final authState = ref.read(authProvider);
    if (!authState.isLoggedIn) {
      setState(() {
        _isInitialized = false;
      });
      return;
    }

    // AuthProvider에서 데이터 소스에 따른 서비스 설정
    final authNotifier = ref.read(authProvider.notifier);
    final dataSource = authState.dataSource;
    
    if (dataSource == DataSourceType.websocket) {
      final webSocketService = authNotifier.webSocketService;
      if (webSocketService != null) {
        ref.read(stockDataProvider.notifier).setServices(
          webSocketService: webSocketService,
          dataSource: dataSource,
        );
        print('WebSocket 서비스 설정 완료');
      }
    } else {
      // HTTPS 방식
      final authService = authNotifier.authService;
      if (authService != null) {
        final quoteService = KisQuoteService(authService);
        ref.read(stockDataProvider.notifier).setServices(
          quoteService: quoteService,
          dataSource: dataSource,
        );
        print('HTTPS 서비스 설정 완료');
      }
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final isConnected = ref.watch(connectionStatusProvider);
    final connectionError = ref.watch(connectionErrorProvider);
    final stockData = ref.watch(stockDataProvider);

    // 로그인 상태 변화 감지
    ref.listen<bool>(isLoggedInProvider, (previous, next) {
      if (next && !_isInitialized) {
        _initializeConnection();
      } else if (!next) {
        setState(() {
          _isInitialized = false;
        });
        ref.read(stockDataProvider.notifier).disconnect();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('KInvest Flutter'),
            if (isLoggedIn)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stockData.marketStatusText,
                    style: TextStyle(
                      fontSize: 12,
                      color: stockData.isMarketOpen ? Colors.green : Colors.orange,
                    ),
                  ),
                  Text(
                    ref.watch(authProvider).dataSource.getContextualDisplayName(),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: Icon(
                isConnected ? Icons.wifi : Icons.wifi_off,
                color: isConnected ? Colors.green : Colors.red,
              ),
              tooltip: isConnected ? '연결됨' : '연결 끊김',
              onPressed: () {
                if (isConnected) {
                  ref.read(stockDataProvider.notifier).disconnect();
                } else {
                  _initializeConnection();
                }
              },
            ),
          const LoginButton(),
        ],
      ),
      body: !isLoggedIn
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.login, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('로그인이 필요합니다'),
                  const SizedBox(height: 8),
                  const Text('우측 상단의 로그인 버튼을 눌러주세요'),
                  const SizedBox(height: 16),
                  FutureBuilder<bool>(
                    future: ref.read(authProvider.notifier).hasStoredCredentials(),
                    builder: (context, snapshot) {
                      final hasStored = snapshot.data ?? false;
                      if (!hasStored) return const SizedBox.shrink();
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade700),
                            const SizedBox(height: 8),
                            Text(
                              '저장된 로그인 정보가 있습니다',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '앱을 다시 시작하면 자동으로 로그인됩니다',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            )
          : !_isInitialized
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('연결 중...'),
                    ],
                  ),
                )
              : connectionError != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('연결 오류: $connectionError'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _initializeConnection,
                            child: const Text('다시 연결'),
                          ),
                        ],
                      ),
                    )
                  : _screens[_selectedIndex],
      bottomNavigationBar: isLoggedIn
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: '국내주식',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.public),
                  label: '해외주식',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.receipt_long),
                  label: '주문내역',
                ),
              ],
            )
          : null,
    );
  }
}