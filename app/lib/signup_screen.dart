// lib/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_screen.dart'; // 메인 화면 import

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _studentIdController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    // 1. 빈 칸 확인
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _studentIdController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 정보를 입력해주세요.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. [중요] 학번 중복 체크 (Firestore 조회)
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('student_id', isEqualTo: _studentIdController.text.trim())
          .get();

      if (result.docs.isNotEmpty) {
        throw FirebaseAuthException(
            code: 'duplicate-student-id', message: '이미 가입된 학번입니다.');
      }

      // 3. 계정 생성
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 4. DB 저장
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'student_id': _studentIdController.text.trim(),
        'role': 'student',
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
      });

      // 5. 성공 시 바로 메인 화면으로 이동 (뒤로가기 방지)
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = '회원가입 실패';
      if (e.code == 'duplicate-student-id') {
        message = '이미 가입된 학번입니다. 관리자에게 문의하세요.';
      } else if (e.code == 'email-already-in-use') {
        message = '이미 사용 중인 이메일입니다.';
      } else if (e.code == 'weak-password') {
        message = '비밀번호는 6자리 이상이어야 합니다.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('회원가입', style: TextStyle(color: Colors.black)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '학과 생활의 시작,\n정보를 입력해주세요.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // 이름 입력
            _buildCustomTextField(
              controller: _nameController,
              hintText: '이름 (실명)',
            ),
            const SizedBox(height: 12),
            // 학번 입력 (요청하신 예시 적용)
            _buildCustomTextField(
              controller: _studentIdController,
              hintText: '학번 (예: 2022010803)',
              isNumber: true,
            ),
            const SizedBox(height: 12),
            // 이메일 입력
            _buildCustomTextField(
              controller: _emailController,
              hintText: '이메일',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            // 비밀번호 입력
            _buildCustomTextField(
              controller: _passwordController,
              hintText: '비밀번호 (6자리 이상)',
              isPassword: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6), // 파란색
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('가입 완료',
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // UI 통일성을 위한 위젯 함수
  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool isNumber = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isNumber ? TextInputType.number : (keyboardType ?? TextInputType.text),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF5F5F5), // 연한 회색 배경
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF999999)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none, // 테두리 없음
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }
}