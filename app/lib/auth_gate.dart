import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/main_nav_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/fcm_service.dart';
import 'widgets/common/custom_loading_indicator.dart';
import 'widgets/common/bounceable.dart';
import 'screens/approval_waiting_screen.dart';

class AuthGate extends StatefulWidget {
  final Map<String, dynamic>? initialUserData; // 로그인 직후 넘겨받은 데이터 (최적화용)

  const AuthGate({super.key, this.initialUserData});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _fcmInitialized = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. 로그인 상태 확인 로그
        if (!snapshot.hasData) {
          print("🔍 AuthGate: 로그아웃 상태임 -> WelcomeScreen 이동");
          _fcmInitialized = false; // Reset FCM state
          return const WelcomeScreen();
        }

        print("🔍 AuthGate: 로그인 됨 (UID: ${snapshot.data!.uid}) -> DB 조회 시작");

        // 2. 유저 정보 실시간 감지 (Future -> Stream 변경)
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            // 2. 로딩 상태 확인 로그
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              // ★ 최적화: 초기 데이터가 있으면 로딩 없이 즉시 렌더링
              if (widget.initialUserData != null) {
                print("⚡ AuthGate: 초기 데이터 사용하여 즉시 렌더링");
                return _buildContent(widget.initialUserData!);
              }

              print("⏳ AuthGate: DB 데이터 가져오는 중...");
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(child: CustomLoadingIndicator()),
              );
            }

            // 3. 에러 또는 데이터 없음 (회원가입 진행 중일 수 있음)
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              print("⏳ AuthGate: 유저 정보 없음 (가입 진행 중 예상) -> 대기 화면 표시");
              // 회원가입 직후 Firestore 생성 전 단계일 수 있으므로 로그아웃 시키지 않음
              return Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CustomLoadingIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "가입 처리 중입니다...",
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Bounceable(
                        onTap: () => FirebaseAuth.instance.signOut(),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "로그아웃",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            return _buildContent(userData);
          },
        );
      },
    );
  }

  Widget _buildContent(Map<String, dynamic> userData) {
    final String status = userData['status'] ?? 'pending';
    print("✅ AuthGate: 유저 정보 확인됨 (상태: $status)");

    // 4. 승인 여부 분기
    if (status == 'approved') {
      print("🚀 AuthGate: 승인 완료 -> 메인 화면 이동");

      // FCM 초기화 (한 번만)
      if (!_fcmInitialized) {
        _fcmInitialized = true;
        FCMService()
            .initialize()
            .then((_) {
              print("✅ FCM 초기화 완료");
            })
            .catchError((e) {
              print("❌ FCM 초기화 실패: $e");
            });
      }

      return const MainNavScreen();
    }

    print("⛔ AuthGate: 승인 대기 중 -> 차단 화면 표시");
    return const ApprovalWaitingScreen();
  }
}
