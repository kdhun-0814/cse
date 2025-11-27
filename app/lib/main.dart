// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'signup_screen.dart';
import 'main_screen.dart';
import 'home_tab.dart';
import 'community_tab.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MY CSE',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // 텍스트 필드 기본 커서 색상 설정
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: Color(0xFF3B82F6),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = '로그인 정보를 확인해주세요.';
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
      // Center 위젯으로 전체 내용을 수직/수평 중앙 정렬
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // 수직 중앙 정렬 핵심
            crossAxisAlignment: CrossAxisAlignment.center, // 수평 중앙 정렬
            children: [
              // 1. 로고 아이콘 (파란색 학사모)
              const Icon(
                Icons.school_rounded, // 둥근 학사모 아이콘
                size: 80,
                color: Color(0xFF2196F3), // 사진 속 파란색
              ),
              const SizedBox(height: 16),

              // 2. 메인 타이틀 (MY CSE)
              const Text(
                'MY CSE',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900, // 아주 굵게
                  color: Colors.black,
                  letterSpacing: 1.0, // 자간 살짝 넓힘
                ),
              ),
              const SizedBox(height: 8),

              // 3. 서브 타이틀 (학교 계정으로...)
              const Text(
                '학교 계정으로 로그인해주세요.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF9E9E9E), // 연한 회색
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 50), // 로고와 입력창 사이 넉넉한 여백

              // 4. 학번/아이디 입력창
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  hintText: '학번 / 아이디',
                  hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 12),

              // 5. 비밀번호 입력창
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  hintText: '비밀번호',
                  hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(height: 24),

              // 6. 로그인 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3), // 아이콘과 동일한 파란색
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          '로그인',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // 7. 하단 링크 (가운데 정렬)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTextLink('아이디 찾기', () {}),
                  _buildDivider(),
                  _buildTextLink('비밀번호 찾기', () {}),
                  _buildDivider(),
                  _buildTextLink('회원가입', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupScreen()),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextLink(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF757575), // 중간 회색
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 12,
      width: 1,
      color: const Color(0xFFE0E0E0), // 아주 연한 회색 구분선
    );
  }
}