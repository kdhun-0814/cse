import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'scrap_screen.dart';
import 'group/group_root_screen.dart'; // ★ import 변경

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  // 탭 이동 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 화면 리스트
    final List<Widget> screens = [
      const HomeScreen(),
      const ScrapScreen(),
      
      // ★ 모집 탭: GroupRootScreen 연결
      // onGoHome 콜백: 홈 탭(0번)으로 이동시켜줌
      GroupRootScreen(onGoHome: () => _onItemTapped(0)), 
      
      const CalendarScreen(),
      const Scaffold(body: Center(child: Text("3D맵 화면 준비중"))),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      
      // ★ 2번 탭(모집)일 때는 글로벌 하단바를 숨깁니다 (GroupRootScreen의 하단바를 쓰기 위해)
      bottomNavigationBar: _selectedIndex == 2 
          ? null 
          : BottomNavigationBar(
              backgroundColor: Colors.white,
              selectedItemColor: const Color(0xFF3182F6),
              unselectedItemColor: const Color(0xFFB0B8C1),
              showUnselectedLabels: true,
              type: BottomNavigationBarType.fixed,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              elevation: 0,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: '홈'),
                BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), label: '스크랩'),
                BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: '모집'), 
                BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: '일정'),
                BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: '3D맵'),
              ],
            ),
    );
  }
}