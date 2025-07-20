import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import 'login_settings_dialog.dart';

class MultiUserLoginDialog extends ConsumerStatefulWidget {
  const MultiUserLoginDialog({super.key});

  @override
  ConsumerState<MultiUserLoginDialog> createState() =>
      _MultiUserLoginDialogState();
}

class _MultiUserLoginDialogState extends ConsumerState<MultiUserLoginDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
                        '데이터 소스: ${user.dataSourceDisplayName}',
                        style: const TextStyle(fontSize: 12, color: Colors.blue),
                      ),
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
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  const Icon(Icons.person_add, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    '새 계정으로 로그인',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '아래 버튼을 클릭하여 새 계정 정보를 입력하고\n데이터 소스를 선택하세요',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
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
                          '데이터 소스 선택',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'WebSocket: 실시간 데이터 (빠름)\nHTTPS: 30초마다 업데이트 (안정적)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
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
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const LoginSettingsDialog(),
    );

    if (result != null && mounted) {
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      final email = result['email'] as String;
      final accountType = result['isRealAccount'] as bool ? "실전" : "모의";
      final dataSource = result['dataSource'] as DataSourceType;

      try {
        await ref.read(authProvider.notifier).loginWithCredentials(
              email: email,
              appKey: result['appKey'] as String,
              appSecret: result['appSecret'] as String,
              isRealAccount: result['isRealAccount'] as bool,
              dataSource: dataSource,
            );

        if (mounted) {
          navigator.pop(true);
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('$email로 로그인되었습니다 ($accountType투자계좌, ${dataSource.displayName})'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        // 에러는 AuthNotifier에서 처리됨
      }
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
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('$userEmail 사용자가 삭제되었습니다'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
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
