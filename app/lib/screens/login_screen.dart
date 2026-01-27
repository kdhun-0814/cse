import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import '../utils/toast_utils.dart';
import '../widgets/common/custom_dialog.dart';
import '../widgets/common/bounceable.dart';
import '../widgets/common/jelly_button.dart';
import 'signup_screen.dart';
import 'approval_waiting_screen.dart';
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
  bool _isObscure = true; // 비밀번호 숨김 여부

  Future<void> _login() async {
    // 1. 입력값이 비어있는지 확인
    if (_studentIdCtrl.text.isEmpty || _pwCtrl.text.isEmpty) {
      ToastUtils.show(context, "학번과 비밀번호를 모두 입력해주세요.", isError: true);
      return;
    }

    // 2. 학번 자릿수(10자리) 검사
    // 학번 길이 체크 9자리 또는 10자리
    if (_studentIdCtrl.text.length != 9 && _studentIdCtrl.text.length != 10) {
      ToastUtils.show(context, "학번을 정확히 입력해주세요.", isError: true);
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

      // 5. 관리자 승인 여부 확인
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .get();

      String status = 'pending';
      if (userDoc.exists && userDoc.data() != null) {
        status =
            (userDoc.data() as Map<String, dynamic>)['status'] ?? 'pending';
      }

      // 관리자 계정 예외 처리 (0000...)
      if (status != 'approved' && email != "0000000000@gnu.ac.kr") {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const ApprovalWaitingScreen(),
            ),
            (route) => false,
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
              style: TextStyle(fontSize: 15, color: Colors.grey),
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
              obscureText: _isObscure,
              decoration: InputDecoration(
                labelText: "비밀번호",
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(color: Color(0xFF3182F6)),
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFB0B8C1),
                ),
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: JellyButton(
                    isActive: !_isObscure,
                    activeIcon: Icons.visibility_outlined,
                    inactiveIcon: Icons.visibility_off_outlined,
                    activeColor: const Color(0xFF3182F6),
                    inactiveColor: const Color(0xFFB0B8C1),
                    size: 24,
                    onTap: () {
                      setState(() {
                        _isObscure = !_isObscure;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 로그인 버튼
            // 로그인 버튼
            Bounceable(
              onTap: _isLoading ? null : _login,
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
                        "로그인",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),

            // 회원가입 버튼
            Bounceable(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SignupScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: "계정이 없으신가요? ",
                    style: TextStyle(color: Color(0xFF8B95A1), fontSize: 13),
                    children: [
                      TextSpan(
                        text: "회원가입",
                        style: TextStyle(
                          color: Color(0xFF3182F6),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
