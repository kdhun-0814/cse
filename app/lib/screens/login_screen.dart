import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import '../auth_gate.dart'; // AuthGate 임포트 추가
import 'package:google_fonts/google_fonts.dart';

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("학번과 비밀번호를 모두 입력해주세요.")));
      return;
    }

    // 2. 학번 자릿수(10자리) 검사
    if (_studentIdCtrl.text.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("학번은 10자리여야 합니다. 올바르게 입력해주세요.")),
      );
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

      // 5. 이메일 인증 여부 확인
      // (단, 관리자 계정 0000000000@gnu.ac.kr은 인증 없이 통과)
      if (!userCred.user!.emailVerified && email != "0000000000@gnu.ac.kr") {
        await FirebaseAuth.instance.signOut(); // 즉시 로그아웃

        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                "이메일 미인증",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: const Text(
                "학교 메일 인증이 완료되지 않았습니다.\n메일함(스팸함 포함)을 확인해주세요.",
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    try {
                      await userCred.user!.sendEmailVerification();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("인증 메일을 다시 보냈습니다.")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("잠시 후 다시 시도해주세요.")),
                      );
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text(
                    "메일 재전송",
                    style: TextStyle(color: Color(0xFF3182F6)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    "확인",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3182F6),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      // 로그인 성공 시 화면 이동 로직
      // "모든 화면 기록을 지우고 AuthGate(앱의 첫 관문)로 새로 이동하라"
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthGate()),
          (route) => false, // 이전의 모든 화면 기록 삭제 (뒤로가기 불가)
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: $e")));
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
                fontSize: 25,
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
                suffixText: "@gnu.ac.kr",
                suffixStyle: TextStyle(color: Color(0xFF8B95A1)),
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
            ElevatedButton(
              onPressed: _isLoading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3182F6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
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
                      "로그인",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
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
