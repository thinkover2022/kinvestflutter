import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';

class MultiUserLoginDialog extends ConsumerStatefulWidget {
  const MultiUserLoginDialog({super.key});

  @override
  ConsumerState<MultiUserLoginDialog> createState() =>
      _MultiUserLoginDialogState();
}

class _MultiUserLoginDialogState extends ConsumerState<MultiUserLoginDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _appKeyController = TextEditingController();
  final _appSecretController = TextEditingController();
  bool _isRealAccount = false;
  bool _obscureSecret = true;

  List<UserProfile> _storedUsers = [];
  UserProfile? _selectedUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStoredUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _appKeyController.dispose();
    _appSecretController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredUsers() async {
    final users = await ref.read(authProvider.notifier).getStoredUsers();
    setState(() {
      _storedUsers = users;
      if (users.isNotEmpty) {
        _selectedUser = users.first;
        _tabController.index = 0; // 저장된 사용자 탭으로 이동
      } else {
        _tabController.index = 1; // 새 사용자 탭으로 이동
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'KIS API 로그인',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people),
                      const SizedBox(width: 8),
                      Text('저장된 사용자 (${_storedUsers.length})'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.person_add),
                      SizedBox(width: 8),
                      Text('새 사용자'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStoredUsersTab(authState),
                  _buildNewUserTab(authState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoredUsersTab(AuthState authState) {
    if (_storedUsers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('저장된 사용자가 없습니다'),
            Text('새 사용자 탭에서 계정을 추가해주세요'),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _storedUsers.length,
            itemBuilder: (context, index) {
              final user = _storedUsers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        user.isRealAccount ? Colors.red : Colors.blue,
                    child: Text(
                      user.email.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(user.email),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.accountType),
                      Text(
                        '마지막 로그인: ${_formatDateTime(user.lastLoginAt)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteUserDialog(user),
                      ),
                    ],
                  ),
                  selected: _selectedUser?.email == user.email,
                  onTap: () {
                    setState(() {
                      _selectedUser = user;
                    });
                  },
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _selectedUser == null || authState.isLoading
                ? null
                : () => _loginWithStoredUser(),
            child: authState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('${_selectedUser?.email ?? "선택된 사용자"}로 로그인'),
          ),
        ),
        if (authState.error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '로그인 실패: ${authState.error}',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNewUserTab(AuthState authState) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '이메일을 입력해주세요';
                      }
                      if (!value.contains('@')) {
                        return '올바른 이메일 형식을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _appKeyController,
                    decoration: const InputDecoration(
                      labelText: 'App Key',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.key),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'App Key를 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _appSecretController,
                    decoration: InputDecoration(
                      labelText: 'App Secret',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureSecret
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureSecret = !_obscureSecret;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureSecret,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'App Secret을 입력해주세요';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('실전투자계좌'),
                    subtitle:
                        Text(_isRealAccount ? '실전투자계좌로 연결' : '모의투자계좌로 연결'),
                    value: _isRealAccount,
                    onChanged: (value) {
                      setState(() {
                        _isRealAccount = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : _loginWithNewCredentials,
              child: authState.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('새 계정으로 로그인'),
            ),
          ),
          if (authState.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '로그인 실패: ${authState.error}',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loginWithStoredUser() async {
    if (_selectedUser == null) return;

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userEmail = _selectedUser!.email;

    try {
      await ref.read(authProvider.notifier).loginWithEmail(userEmail);
      if (mounted) {
        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('$userEmail로 로그인되었습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 에러는 AuthNotifier에서 처리됨
    }
  }

  Future<void> _loginWithNewCredentials() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final email = _emailController.text.trim();
    final accountType = _isRealAccount ? "실전" : "모의";

    try {
      await ref.read(authProvider.notifier).loginWithCredentials(
            email: email,
            appKey: _appKeyController.text.trim(),
            appSecret: _appSecretController.text.trim(),
            isRealAccount: _isRealAccount,
          );

      if (mounted) {
        navigator.pop(true);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('$email로 로그인되었습니다 ($accountType투자계좌)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 에러는 AuthNotifier에서 처리됨
    }
  }

  void _showDeleteUserDialog(UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('사용자 삭제'),
        content: Text('${user.email} 사용자를 삭제하시겠습니까?\n저장된 모든 정보가 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final userEmail = user.email;

              await ref.read(authProvider.notifier).deleteUser(userEmail);
              if (mounted) {
                navigator.pop();
                await _loadStoredUsers();
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('$userEmail 사용자가 삭제되었습니다'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
