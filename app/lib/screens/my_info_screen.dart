import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyInfoScreen extends StatefulWidget {
  const MyInfoScreen({super.key});

  @override
  State<MyInfoScreen> createState() => _MyInfoScreenState();
}

class _MyInfoScreenState extends State<MyInfoScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _user = _auth.currentUser;
    if (_user != null) {
      try {
        DocumentSnapshot doc = await _db
            .collection('users')
            .doc(_user!.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data() as Map<String, dynamic>;
          });
        }
      } catch (e) {
        debugPrint("Error loading user data: $e");
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _sendPasswordResetEmail() async {
    if (_user?.email == null) return;

    try {
      await _auth.sendPasswordResetEmail(email: _user!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_user!.email}로 비밀번호 재설정 메일을 보냈습니다.'),
            backgroundColor: const Color(0xFF3182F6),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메일 발송에 실패했습니다. 잠시 후 다시 시도해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF2F4F6),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 데이터 파싱
    String name = "이름 없음";
    String studentId = "학번 정보 없음";
    String email = _user?.email ?? "이메일 없음";
    String role = "USER";

    if (_userData != null) {
      name =
          "${_userData!['last_name'] ?? ''}${_userData!['first_name'] ?? ''}";
      studentId = "${_userData!['student_id'] ?? '정보 없음'}";
      role = _userData!['role'] ?? 'USER';
    }

    bool isAdmin = role == 'ADMIN';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      appBar: AppBar(
        title: const Text(
          "내 정보",
          style: TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF4E5968),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. 프로필 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFFE5E8EB),
                        width: 1,
                      ),
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundColor: Color(0xFFF2F4F6),
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Color(0xFFB0B8C1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191F28),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF8B95A1),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 뱃지 표시 (관리자 여부)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isAdmin
                          ? const Color(0xFFE8F3FF)
                          : const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isAdmin ? "관리자 (ADMIN)" : "학생 (USER)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isAdmin
                            ? const Color(0xFF3182F6)
                            : const Color(0xFF4E5968),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 2. 상세 정보 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "기본 정보",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191F28),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow("학번", studentId),
                  const Divider(height: 32, color: Color(0xFFF2F4F6)),
                  _buildInfoRow("이메일", email),
                  const Divider(height: 32, color: Color(0xFFF2F4F6)),
                  _buildInfoRow("계정 권한", role),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. 계정 설정 섹션
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "계정 설정",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF191F28),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 비밀번호 재설정 버튼
                  InkWell(
                    onTap: _sendPasswordResetEmail,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF2F4F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lock_reset_rounded,
                              color: Color(0xFF4E5968),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "비밀번호 재설정",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF333D4B),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "이메일로 재설정 링크를 발송합니다",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8B95A1),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Color(0xFFB0B8C1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 추후 위젯 추가 영역 예시
            // Text("위젯 추가 예정 영역", style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF8B95A1),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333D4B),
          ),
        ),
      ],
    );
  }
}
