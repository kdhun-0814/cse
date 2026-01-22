import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/common/bounceable.dart';
import '../../utils/toast_utils.dart';
import 'package:intl/intl.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 승인 처리
  Future<void> _approveUser(String uid, String name) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'status': 'approved',
        'approved_at': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ToastUtils.show(context, "$name 님의 가입을 승인했습니다.");
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, "승인 처리 중 오류가 발생했습니다.", isError: true);
      }
    }
  }

  // 거절 처리 (선택 사항: 문서를 삭제하거나 status를 rejected로 변경)
  Future<void> _rejectUser(String uid, String name) async {
    // 확인 다이얼로그
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("가입 거절"),
        content: Text("$name 님의 가입 요청을 거절하시겠습니까?\n거절 시 해당 요청은 삭제됩니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("거절(삭제)", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('users').doc(uid).delete();
        if (mounted) {
          ToastUtils.show(context, "$name 님의 요청을 거절(삭제)했습니다.");
        }
      } catch (e) {
        if (mounted) {
          ToastUtils.show(context, "거절 처리 중 오류가 발생했습니다.", isError: true);
        }
      }
    }
  }

  // 이미지 확대 보기 다이얼로그
  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const CircularProgressIndicator(color: Colors.white);
                  },
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "가입 승인 관리",
          style: TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF191F28)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users')
            .where('status', isEqualTo: 'pending')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print("🚨 AdminApprovalScreen Error: ${snapshot.error}");
            return Center(
              child: Text(
                "오류가 발생했습니다.\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "승인 대기 중인 요청이 없습니다.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final String uid = docs[index].id;
              final String name = data['name'] ?? '이름 없음';
              final String studentId = data['student_id'] ?? '-';
              final String proofUrl = data['proof_url'] ?? '';
              final Timestamp? createdAt = data['created_at'];
              final String dateStr = createdAt != null
                  ? DateFormat('MM/dd HH:mm').format(createdAt.toDate())
                  : '-';

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E8EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 증명서 썸네일
                        GestureDetector(
                          onTap: () {
                            if (proofUrl.isNotEmpty) {
                              _showImageDialog(proofUrl);
                            } else {
                              ToastUtils.show(context, "이미지가 없습니다.", isError: true);
                            }
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: proofUrl.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      proofUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : const Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$name ($studentId)",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF191F28),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "신청일: $dateStr",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF8B95A1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Bounceable(
                            onTap: () => _rejectUser(uid, name),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "거절",
                                style: TextStyle(
                                  color: Color(0xFF4E5968),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Bounceable(
                            onTap: () => _approveUser(uid, name),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3182F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "승인",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
