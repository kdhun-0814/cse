import 'package:flutter/material.dart';
import 'group_list_screen.dart';
import 'group_create_screen.dart';

class GroupRootScreen extends StatefulWidget {
  final VoidCallback onGoHome; // 홈으로 가기 콜백

  const GroupRootScreen({super.key, required this.onGoHome});

  @override
  State<GroupRootScreen> createState() => _GroupRootScreenState();
}

class _GroupRootScreenState extends State<GroupRootScreen> {
  // 페이지 컨트롤러 (초기 페이지: 2번 '모임 목록')
  late PageController _pageController;
  int _selectedIndex = 2; 

  // 탭별 상단 타이틀
  final List<String> _titles = [
    "",             // 0: 뒤로가기 (사용 안 함)
    "모임 만들기",   // 1
    "모임 목록",     // 2
    "모임 관리",     // 3
    "찜한 목록",     // 4
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 2);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // 하단 탭 클릭 시 실행
  void _onItemTapped(int index) {
    if (index == 0) {
      widget.onGoHome(); // 0번은 홈으로 이동
    } else {
      setState(() {
        _selectedIndex = index;
      });
      // ★ 핵심: 페이지를 부드럽게 옆으로 넘김 (토스 스타일 슬라이딩)
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic, // 자연스러운 감속 곡선
      );
    }
  }

  // 화면을 손으로 밀었을 때(Swipe) 탭 인덱스 동기화
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),
      
      // 상단 앱바
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F6),
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // 뒤로가기 버튼 숨김 (하단바에 있음)
        
        // 타이틀이 바뀔 때 부드럽게 페이드 효과 적용
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            _titles[_selectedIndex], // 현재 인덱스에 맞는 타이틀 표시
            key: ValueKey<String>(_titles[_selectedIndex]),
            style: const TextStyle(
              color: Color(0xFF191F28),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
      
      // ★ 핵심: PageView를 사용하여 화면이 옆으로 이어지게 구현
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(), // iOS 스타일 탄성 스크롤
        children: [
          // 0번: 더미 화면 (뒤로가기용, 실제로는 안 보임)
          Container(), 
          
          // 1번: 모임 만들기 화면
          const GroupCreateScreen(),
          
          // 2번: 전체 모임 목록
          const GroupListScreen(filterType: 'all'),
          
          // 3번: 내가 만든 모임 관리
          const GroupListScreen(filterType: 'my'),
          
          // 4번: 찜한 목록
          const GroupListScreen(filterType: 'liked'),
        ],
      ),

      // 하단 네비게이션 바
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2), // 위쪽으로 은은한 그림자
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed, // 아이콘 5개 고정
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF3182F6), // 선택된 색 (토스 블루)
          unselectedItemColor: const Color(0xFFB0B8C1), // 선택 안 된 색 (회색)
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.arrow_back_ios_new_rounded), label: '뒤로가기'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline_rounded), label: '모임 만들기'),
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: '모임 목록'),
            BottomNavigationBarItem(icon: Icon(Icons.manage_accounts_rounded), label: '모임 관리'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: '찜한 목록'),
          ],
        ),
      ),
    );
  }
}