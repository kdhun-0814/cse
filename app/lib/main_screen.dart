// lib/main_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart'; // 로그아웃 시 이동용
import 'home_tab.dart';
import 'community_tab.dart';
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0; // 현재 선택된 탭 번호 (0: 홈)

  // 각 탭에 해당하는 화면들 (나중에 하나씩 파일로 분리할 예정)
  final List<Widget> _pages = [
    const HomeTab(),      // 0번
    const Center(child: Text('나의 스크랩 화면')),       // 1번
    const CommunityTab(),   // 2번
    const Center(child: Text('학사 일정/캘린더 화면')),   // 3번
    const Center(child: Text('3D 맵 / 내 정보 화면')),   // 4번 (일단 맵으로 배치)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 앱바 (탭별로 다르게 보여줄 수도 있음)
      appBar: AppBar(
        title: const Text(
          'MY CSE', 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // 임시 로그아웃 버튼 (나중에 마이페이지로 이동)
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            onPressed: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const MyApp()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      
      // 현재 선택된 화면 보여주기
      body: _pages[_selectedIndex],

      // 하단 내비게이션 바
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed, // 탭이 4개 이상일 때 필수!
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF3B82F6), // 선택된 아이콘 색 (파랑)
          unselectedItemColor: Colors.grey, // 안 선택된 아이콘 색
          showUnselectedLabels: true,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_rounded), // 스크랩 아이콘
              label: '스크랩',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded), // 커뮤니티 아이콘
              label: '모임',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month_rounded), // 일정 아이콘
              label: '일정',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded), // 지도 아이콘
              label: '맵',
            ),
          ],
        ),
      ),
    );
  }
}