import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'multi_user_login_dialog.dart';

class LoginButton extends ConsumerWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoggedIn) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.account_circle, color: Colors.green),
        onSelected: (value) {
          if (value == 'logout') {
            _showLogoutDialog(context, ref);
          } else if (value == 'info') {
            _showAccountInfo(context, authState);
          } else if (value == 'switch') {
            _showLoginDialog(context);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'info',
            child: Row(
              children: [
                const Icon(Icons.info),
                const SizedBox(width: 8),
                Text('계정 정보'),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'switch',
            child: Row(
              children: [
                const Icon(Icons.switch_account),
                const SizedBox(width: 8),
                Text('계정 전환'),
              ],
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'logout',
            child: Row(
              children: [
                const Icon(Icons.logout, color: Colors.red),
                const SizedBox(width: 8),
                Text('로그아웃', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      );
    }

    return IconButton(
      icon: const Icon(Icons.login),
      onPressed: () => _showLoginDialog(context),
    );
  }

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MultiUserLoginDialog(),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('정말 로그아웃하시겠습니까?'),
            const SizedBox(height: 16),
            FutureBuilder<bool>(
              future: ref.read(authProvider.notifier).hasStoredCredentials(),
              builder: (context, snapshot) {
                final hasStored = snapshot.data ?? false;
                if (!hasStored) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info,
                              color: Colors.blue.shade700, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '로그아웃 옵션',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '로그아웃만: 세션만 종료, 사용자 정보 유지\n'
                        '계정 삭제: 현재 사용자 정보 완전 삭제',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FutureBuilder<bool>(
            future: ref.read(authProvider.notifier).hasStoredCredentials(),
            builder: (context, snapshot) {
              final hasStored = snapshot.data ?? false;
              if (!hasStored) {
                return ElevatedButton(
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('로그아웃되었습니다'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child:
                      const Text('로그아웃', style: TextStyle(color: Colors.white)),
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      ref
                          .read(authProvider.notifier)
                          .logout(clearStoredCredentials: false);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('로그아웃되었습니다 (사용자 정보 유지)'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    child: const Text('로그아웃만'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(authProvider.notifier)
                          .logout(clearStoredCredentials: true);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('계정이 삭제되었습니다'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('계정 삭제',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAccountInfo(BuildContext context, AuthState authState) {
    final user = authState.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('이메일', user.email),
            const SizedBox(height: 8),
            _buildInfoRow('App Key', user.maskedAppKey),
            const SizedBox(height: 8),
            _buildInfoRow('App Secret', user.maskedAppSecret),
            const SizedBox(height: 8),
            _buildInfoRow('계좌 유형', user.accountType),
            const SizedBox(height: 8),
            _buildInfoRow('데이터 소스', user.dataSourceDisplayName),
            const SizedBox(height: 8),
            _buildInfoRow('가입일', _formatDate(user.createdAt)),
            const SizedBox(height: 8),
            _buildInfoRow('마지막 로그인', _formatDate(user.lastLoginAt)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
