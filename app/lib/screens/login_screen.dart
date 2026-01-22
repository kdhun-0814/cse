import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import '../auth_gate.dart'; // AuthGate 임포트 추가
import 'package:google_fonts/google_fonts.dart';
import '../widgets/common/custom_loading_indicator.dart';
import '../widgets/common/custom_dialog.dart';
import '../utils/toast_utils.dart';
import '../widgets/common/bounceable.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _studentIdCtrl = TextEditingController(); // 학번 입력
  final _pwCtrl = TextEditingController(); // 비번 입력
  bool _isLoading = false;

  Future<void> _login() async {
    // 1. 입력값이 비어있는지 확인
    if (_studentIdCtrl.text.isEmpty || _pwCtrl.text.isEmpty) {
      ToastUtils.show(context, "학번과 비밀번호를 모두 입력해주세요.", isError: true);
      return;
    }

    // 2. 학번 자릿수(9~10자리) 검사
    int idLength = _studentIdCtrl.text.length;
    if (idLength < 9 || idLength > 10) {
      ToastUtils.show(context, "학번은 9자리 또는 10자리여야 합니다.", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 3. 학번 뒤에 학교 도메인 붙이기
      String email = "${_studentIdCtrl.text.trim()}@gnu.ac.kr";

      // 4. 로그인 시도
      UserCredential userCred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email,
            password: _pwCtrl.text.trim(),
          );

      // 5. 로그인 성공 시 화면 이동 로직 (이메일 인증 확인 제거됨)
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      // 에러 로그 출력
      print("Login Error Code: ${e.code}");

      String message = "로그인 실패";

      // 최신 Firebase 보안 정책 반영 (invalid-credential)
      if (e.code == 'invalid-credential' ||
          e.code == 'user-not-found' ||
          e.code == 'wrong-password') {
        message = "가입되지 않은 학번이거나 비밀번호가 틀렸습니다.";
      } else if (e.code == 'invalid-email') {
        message = "올바르지 않은 이메일 형식입니다.";
      } else if (e.code == 'too-many-requests') {
        message = "접속 시도가 너무 많습니다. 잠시 후 시도해주세요.";
      } else if (e.code == 'user-disabled') {
        message = "비활성화된 계정입니다. 관리자에게 문의하세요.";
      }

      ToastUtils.show(context, message, isError: true);
    } catch (e) {
      ToastUtils.show(context, "오류가 발생했습니다: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // 상단 앱바 (뒤로가기 버튼)
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF191F28),
          ),
          onPressed: () {
            Navigator.pop(context); // 웰컴 화면으로 돌아가기
          },
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "MY_CSE",

              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF3182F6),
                letterSpacing: 1.2,
                height: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              "경상국립대학교 IT 공과대학 컴퓨터공학부",
              style: TextStyle(fontSize: 13, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // 학번 입력 필드 (10자리 제한)
            TextField(
              controller: _studentIdCtrl,
              keyboardType: TextInputType.number,
              maxLength: 10, // UI 입력 제한
              decoration: const InputDecoration(
                labelText: "학번",

                counterText: "", // 글자수 카운터 숨김
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF3182F6)),
                ),
                prefixIcon: Icon(
                  Icons.school_outlined,
                  color: Color(0xFFB0B8C1),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 비밀번호 입력
            TextField(
              controller: _pwCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "비밀번호",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF3182F6)),
                ),
                prefixIcon: Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFB0B8C1),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 로그인 버튼
            Bounceable(
              onTap: _isLoading ? null : _login,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3182F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: _isLoading
                    ? const CustomLoadingIndicator(
                        color: Colors.white,
                        size: 20,
                      )
                    : const Text(
                        "로그인",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // 회원가입 버튼
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              ),
              child: const Text(
                "계정이 없으신가요? 회원가입",
                style: TextStyle(color: Color(0xFF8B95A1)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
