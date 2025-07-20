import 'package:flutter/material.dart';

enum DataSourceType {
  websocket,
  https,
}

extension DataSourceTypeExtension on DataSourceType {
  String get displayName {
    switch (this) {
      case DataSourceType.websocket:
        return 'WebSocket (실시간)';
      case DataSourceType.https:
        return 'HTTPS (주기적 조회)';
    }
  }
  
  String get description {
    switch (this) {
      case DataSourceType.websocket:
        return '실시간 스트리밍 데이터\n장시간 중 즉시 업데이트';
      case DataSourceType.https:
        return 'REST API 주기적 조회\n장시간 외에도 데이터 확인 가능';
    }
  }
}

class LoginSettingsDialog extends StatefulWidget {
  final String? initialEmail;
  final String? initialAppKey;
  final String? initialAppSecret;
  final bool initialIsRealAccount;
  final DataSourceType initialDataSource;

  const LoginSettingsDialog({
    super.key,
    this.initialEmail,
    this.initialAppKey,
    this.initialAppSecret,
    this.initialIsRealAccount = true,
    this.initialDataSource = DataSourceType.https,
  });

  @override
  State<LoginSettingsDialog> createState() => _LoginSettingsDialogState();
}

class _LoginSettingsDialogState extends State<LoginSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _appKeyController = TextEditingController();
  final _appSecretController = TextEditingController();
  
  bool _isRealAccount = true;
  DataSourceType _dataSource = DataSourceType.https;
  bool _obscureAppKey = true;
  bool _obscureAppSecret = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = widget.initialEmail ?? '';
    _appKeyController.text = widget.initialAppKey ?? '';
    _appSecretController.text = widget.initialAppSecret ?? '';
    _isRealAccount = widget.initialIsRealAccount;
    _dataSource = widget.initialDataSource;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _appKeyController.dispose();
    _appSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  children: [
                    const Icon(Icons.login, size: 32),
                    const SizedBox(width: 12),
                    const Text(
                      '로그인 설정',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 이메일 입력
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: 'user@example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요';
                    }
                    if (!value.contains('@')) {
                      return '올바른 이메일 형식이 아닙니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // App Key 입력
                TextFormField(
                  controller: _appKeyController,
                  decoration: InputDecoration(
                    labelText: 'App Key',
                    hintText: '한국투자증권에서 발급받은 App Key',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.key),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureAppKey ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureAppKey = !_obscureAppKey;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureAppKey,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'App Key를 입력해주세요';
                    }
                    if (value.length < 30) {
                      return 'App Key가 너무 짧습니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // App Secret 입력
                TextFormField(
                  controller: _appSecretController,
                  decoration: InputDecoration(
                    labelText: 'App Secret',
                    hintText: '한국투자증권에서 발급받은 App Secret',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureAppSecret ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureAppSecret = !_obscureAppSecret;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureAppSecret,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'App Secret을 입력해주세요';
                    }
                    if (value.length < 100) {
                      return 'App Secret이 너무 짧습니다';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // 계정 타입 선택
                const Text(
                  '계정 타입',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<bool>(
                        title: const Text('모의투자'),
                        subtitle: const Text('가상 투자 환경'),
                        value: false,
                        groupValue: _isRealAccount,
                        onChanged: (value) {
                          setState(() {
                            _isRealAccount = value!;
                          });
                        },
                      ),
                      RadioListTile<bool>(
                        title: const Text('실전투자'),
                        subtitle: const Text('실제 투자 환경'),
                        value: true,
                        groupValue: _isRealAccount,
                        onChanged: (value) {
                          setState(() {
                            _isRealAccount = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 데이터 소스 선택
                const Text(
                  '데이터 소스',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: DataSourceType.values.map((type) {
                      return RadioListTile<DataSourceType>(
                        title: Text(type.displayName),
                        subtitle: Text(
                          type.description,
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: type,
                        groupValue: _dataSource,
                        onChanged: (value) {
                          setState(() {
                            _dataSource = value!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),

                // 안내 메시지
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Text(
                            '데이터 소스 선택 안내',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• WebSocket: 실시간 스트리밍, 장시간 중 즉시 업데이트\n'
                        '• HTTPS: 주기적 조회, 장시간 외에도 데이터 확인 가능\n'
                        '• 실시간성이 중요하면 WebSocket 선택\n'
                        '• 안정성이 중요하면 HTTPS 선택',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          Navigator.of(context).pop({
                            'email': _emailController.text,
                            'appKey': _appKeyController.text,
                            'appSecret': _appSecretController.text,
                            'isRealAccount': _isRealAccount,
                            'dataSource': _dataSource,
                          });
                        }
                      },
                      child: const Text('로그인'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}