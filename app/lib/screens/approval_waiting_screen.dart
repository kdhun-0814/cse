import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'welcome_screen.dart';
import '../auth_gate.dart';
import '../widgets/common/bounceable.dart';
import '../widgets/common/animated_hourglass.dart'; // import 추가
import '../utils/toast_utils.dart'; // ToastUtils import
import '../widgets/common/custom_loading_indicator.dart'; // Loading Indicator import

class ApprovalWaitingScreen extends StatefulWidget {
  const ApprovalWaitingScreen({super.key});

  @override
  State<ApprovalWaitingScreen> createState() => _ApprovalWaitingScreenState();
}

class _ApprovalWaitingScreenState extends State<ApprovalWaitingScreen> {
  bool _isLoading = false;

  // 새로고침 (승인 여부 확인)
  Future<void> _checkApprovalStatus() async {
    setState(() => _isLoading = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        // 유저 정보가 없으면 로그아웃 처리
        _logout();
        return;
      }

      // DB 정보 다시 불러오기
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        if (mounted) {
          ToastUtils.show(context, "유저 정보를 찾을 수 없습니다.", isError: true);
        }
        _logout();
        return;
      }

      String status =
          (userDoc.data() as Map<String, dynamic>)['status'] ?? 'pending';

      if (status == 'approved') {
        if (mounted) {
          ToastUtils.show(context, "가입이 승인되었습니다!");
          // 승인 완료 시 AuthGate로 이동하여 메인 화면 진입
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const AuthGate()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ToastUtils.show(context, "아직 승인 대기 중입니다.");
        }
      }
    } catch (e) {
      if (mounted) ToastUtils.show(context, "오류가 발생했습니다: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // 아이콘 또는 이미지
              Container(
                width: 120, // 크기 약간 키움
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F6),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AnimatedHourglass(
                    size: 60,
                    color: Color(0xFF3182F6),
                    duration: Duration(seconds: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "가입 승인을 기다리고 있어요",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF191F28),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "관리자가 확인 후 승인하면\n정상적으로 서비스를 이용할 수 있어요.\n(최대 1~3일 소요)",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7684),
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),

              // 새로고침 버튼 (파란색)
              Bounceable(
                onTap: _isLoading ? null : _checkApprovalStatus,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3182F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "새로고침",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // 로그아웃 버튼 (회색)
              Bounceable(
                onTap: () => _logout(),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "로그아웃",
                    style: TextStyle(
                      color: Color(0xFF4E5968),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
