import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _studentIdCtrl = TextEditingController(); // 학번
  final _pwCtrl = TextEditingController(); // 비번
  final _lastNameCtrl = TextEditingController(); // 성
  final _firstNameCtrl = TextEditingController(); // 이름

  bool _isLoading = false;

  Future<void> _signUp() async {
    // 1. 기본 입력 확인
    if (_studentIdCtrl.text.isEmpty ||
        _pwCtrl.text.isEmpty ||
        _lastNameCtrl.text.isEmpty ||
        _firstNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("모든 정보를 입력해주세요.")));
      return;
    }

    // 2. 학번 자릿수 검사 (10자리)
    int idLength = _studentIdCtrl.text.length;
    if (idLength != 9 && idLength != 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("정확한 학번을 입력해주세요.")));
      return;
    }

    // 3. 비밀번호 유효성 검사 (영문+숫자 필수, 8자리 이상)
    String password = _pwCtrl.text;
    RegExp passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호는 영문+숫자 포함 8자리 이상이어야 합니다.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 학교 도메인 자동 완성
      String email = "${_studentIdCtrl.text.trim()}@gnu.ac.kr";

      // 이름 합치기
      String lastName = _lastNameCtrl.text.trim();
      String firstName = _firstNameCtrl.text.trim();
      String fullName = "$lastName$firstName";

      // 4. Firebase Auth 계정 생성
      UserCredential userCred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _pwCtrl.text.trim(),
          );

      // 5. 인증 메일 발송
      await userCred.user!.sendEmailVerification();

      // 6. Firestore DB 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCred.user!.uid)
          .set({
            'student_id': _studentIdCtrl.text.trim(),
            'email': email,
            'name': fullName, // 전체 이름
            'last_name': lastName, // 성
            'first_name': firstName, // 이름
            'role': 'USER',
            'status': 'pending',
            'created_at': FieldValue.serverTimestamp(),
            'approved_at': null,
            'expires_at': null,
          });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ), // 팝업도 둥글게
            title: const Text(
              "인증 메일 발송 완료",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "$email 로\n인증 메일을 보냈습니다.\n\n반드시 메일함에서 링크를 클릭하여\n인증을 완료한 후 로그인해주세요.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: const Text(
                  "확인",
                  style: TextStyle(
                    color: Color(0xFF3182F6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      String message = "가입 실패: $e";
      if (e is FirebaseAuthException && e.code == 'email-already-in-use') {
        message = "이미 가입된 학번(이메일)입니다.";
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ★ 통일된 디자인의 AppBar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "회원가입",
          style: TextStyle(
            color: Color(0xFF191F28),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF191F28),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  "학교 이메일(@gnu.ac.kr) 인증을 위해 \n 실제 학번을 입력해주세요.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF8B95A1),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 1. 학번 입력
              const Text(
                "학번",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333D4B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _studentIdCtrl,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: const InputDecoration(
                  hintText: "예: 20xxxxxxxx",
                  hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
                  counterText: "",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ), // 둥근 테두리
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFFE5E8EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide(color: Color(0xFF3182F6)),
                  ),
                  prefixIcon: Icon(
                    Icons.badge_outlined,
                    color: Color(0xFFB0B8C1),
                  ),
                  suffixText: "@gnu.ac.kr",
                  suffixStyle: TextStyle(color: Color(0xFF8B95A1)),
                ),
              ),
              const SizedBox(height: 24),

              // 2. 이름 입력 (Row)
              const Text(
                "이름 (실명)",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333D4B),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: _lastNameCtrl,
                      decoration: const InputDecoration(
                        hintText: "성",
                        hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
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
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _firstNameCtrl,
                      decoration: const InputDecoration(
                        hintText: "이름",
                        hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
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
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 3. 비밀번호 입력
              const Text(
                "비밀번호",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333D4B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pwCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: "영문+숫자 포함 8자리 이상",
                  hintStyle: TextStyle(color: Color(0xFFC5C8CE)),
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

              const SizedBox(height: 40),

              // 4. 가입 버튼
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3182F6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                          "인증 메일 받기",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
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
