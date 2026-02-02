import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../utils/toast_utils.dart';
import '../../widgets/common/custom_dialog.dart';
import '../../widgets/common/custom_dialog.dart';
import '../../widgets/common/bounceable.dart';
import '../../widgets/common/custom_loading_indicator.dart';

class AdminUserListScreen extends StatefulWidget {
  const AdminUserListScreen({super.key});

  @override
  State<AdminUserListScreen> createState() => _AdminUserListScreenState();
}

class _AdminUserListScreenState extends State<AdminUserListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "승인 대기 회원",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getPendingUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "승인 대기 중인 회원이 없습니다.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final users = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: const Icon(Icons.person, color: Colors.grey),
                ),
                title: Text(
                  "${user['name'] ?? '이름없음'} (${user['student_id'] ?? '-'})",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(user['email'] ?? ''),
                trailing: Bounceable(
                  onTap: () => _approveUser(user),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3182F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "승인",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _approveUser(Map<String, dynamic> user) async {
    if (!mounted) return;

    final shouldApprove = await showDialog<bool>(
      context: context,
      builder: (ctx) => CustomDialog(
        title: "가입 승인",
        contentText: "${user['name']} (${user['student_id']}) 님의\n가입을 승인하시겠습니까?",
        cancelText: "취소",
        confirmText: "승인",
        onCancel: () => Navigator.pop(ctx, false),
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (shouldApprove == true && mounted) {
      await _firestoreService.approveUser(user['uid']);
      if (mounted) {
        ToastUtils.show(context, "승인되었습니다.");
      }
    }
  }
}
