import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/main_nav_screen.dart';
import 'screens/welcome_screen.dart';
import 'widgets/common/custom_loading_indicator.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. 로그인 상태 확인 로그
        if (!snapshot.hasData) {
          print("🔍 AuthGate: 로그아웃 상태임 -> WelcomeScreen 이동");
          return const WelcomeScreen();
        }

        print("🔍 AuthGate: 로그인 됨 (UID: ${snapshot.data!.uid}) -> DB 조회 시작");

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            // 2. 로딩 상태 확인 로그
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              print("⏳ AuthGate: DB 데이터 가져오는 중...");
              return const Scaffold(
                backgroundColor: Colors.white,
                body: Center(
                  child: CustomLoadingIndicator(),
                ),
              );
            }

            // 3. 에러 또는 데이터 없음
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              print("🚨 AuthGate: DB에 유저 정보 없음! -> 로그아웃 시킴");
              FirebaseAuth.instance.signOut();
              return const WelcomeScreen();
            }

            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final String status = userData['status'] ?? 'pending';
            print("✅ AuthGate: 유저 정보 확인됨 (상태: $status)");

            // 4. 승인 여부 분기
            if (status == 'approved') {
              print("🚀 AuthGate: 승인 완료 -> 메인 화면 이동");
              return const MainNavScreen();
            }

            print("⛔ AuthGate: 승인 대기 중 -> 차단 화면 표시");
            return _buildBlockScreen(context);
          },
        );
      },
    );
  }

  Widget _buildBlockScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.hourglass_top_rounded,
                size: 80,
                color: Color(0xFF3182F6),
              ),
              const SizedBox(height: 24),
              const Text(
                "승인 대기 중",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                "학생회에서 재학증명서 확인 후\n승인 완료 시 이용 가능합니다.\n(최대 3일 소요)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text("로그아웃", style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
