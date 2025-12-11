import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 자동 생성된 파일
import 'package:intl/date_symbol_data_local.dart';
import 'auth_gate.dart'; // 생성할 파일

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  // ★ Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MY_CSE',
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFF2F4F6),
        primaryColor: const Color(0xFF3182F6),
        useMaterial3: true,
      ),
      home: const AuthGate(), // 로그인 세션
    );
  }
}
