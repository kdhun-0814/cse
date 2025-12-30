import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'calendar_screen.dart';
import 'scrap_screen.dart';
import 'group/group_root_screen.dart';
import '../features/map_3d/screens/map_screen.dart'; // NEW
import '../widgets/animated_bottom_nav_item.dart';
import '../widgets/animated_bottom_nav_item.dart';
import '../widgets/group_bottom_nav_bar.dart';
import '../widgets/main_bottom_nav_bar.dart'; // Import MainBottomNavBar

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // 모집 탭 관리를 위한 변수들
  late PageController _groupPageController;
  int _groupTabIndex = 2; // 모집 탭 내부 인덱스 (초기값: 모집 목록)

  // 네비게이션 바 애니메이션 컨트롤러
  late AnimationController _navAnimationController;
  late Animation<double> _fadeInAnimation;
  late Animation<double> _fadeOutAnimation;

  @override
  void initState() {
    super.initState();
    _groupPageController = PageController(initialPage: 2);

    _navAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300), // 페이드 효과에 맞춰 시간 단축
      value: 1.0, // 초기 상태: 보여짐
    );

    // 페이드 인 (0 -> 1)
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _navAnimationController, curve: Curves.easeIn),
    );

    // 페이드 아웃 (1 -> 0)
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _navAnimationController, curve: Curves.easeOut),
    );

    // 애니메이션 종료 시 화면 갱신 (위젯 트리에서 제거하기 위해)
    _navAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        setState(() {});
      }
    });
  }

  // ... (dispose, onItemTapped omitted for brevity) ...
  // Please ensure the surrounding code matches carefully if you use this tool,
  // but since I am engaging in a multi-hunk edit effectively by replacing the whole init + vars,
  // I should be careful.
  // Wait, I can only do one block.
  // I will split this into two calls or use MultiReplace if possible?
  // Standard replace is for single contiguous block.
  // The vars are at top, initState in middle, build at bottom.
  // This is non-contiguous. I must use multi_replace_file_content.
  // BUT I can't use multi_replace for "declarations + initstate + build".
  // Actually I can.

  // Let's use multi_replace_file_content.

  // ... (dispose, onItemTapped omitted for brevity) ...

  @override
  void dispose() {
    _groupPageController.dispose();
    _navAnimationController.dispose();
    super.dispose();
  }

  // 탭 이동 함수
  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    final int previousIndex = _selectedIndex;

    setState(() {
      _selectedIndex = index;
    });

    // 모집 탭(2)과 관련 있는 이동일 때만 애니메이션 실행
    // (홈/스크랩/일정/3D맵 <-> 모집)
    if (previousIndex == 2 || index == 2) {
      // 모집 탭으로 진입 시 (index == 2) 상태 초기화
      if (index == 2) {
        _groupTabIndex = 2; // 초기값: 모집 목록
        if (_groupPageController.hasClients) {
          _groupPageController.jumpToPage(2);
        }
      }

      _navAnimationController.reset();
      _navAnimationController.forward();
    }
  }

  // 모집 탭 내부 네비게이션 처리
  void _onGroupTabTapped(int index) {
    if (index == 0) {
      // 홈으로 이동
      _onItemTapped(0);
    } else {
      // 모집 탭 내부 이동
      setState(() {
        _groupTabIndex = index;
      });
      if (_groupPageController.hasClients) {
        _groupPageController.jumpToPage(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 화면 리스트
    final List<Widget> screens = [
      HomeScreen(),
      const ScrapScreen(),

      // 모집 탭: GroupRootScreen 연결
      // onGoHome 콜백 제거 -> MainNav에서 직접 관리
      GroupRootScreen(
        pageController: _groupPageController,
        onTabChanged: (index) {
          setState(() {
            _groupTabIndex = index;
          });
        },
      ),

      const CalendarScreen(),
      const MapScreen(), // Updated
    ];

    return Scaffold(
      body: screens[_selectedIndex],

      // 하단 네비게이션 바 (Stack + SlideTransition)
      // 하단 네비게이션 바 (Stack + SlideTransition)
      bottomNavigationBar: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 메인 네비게이션 바
          // 모집 탭이 아닐 때 보여야 함 (또는 퇴장 중일 때)
          if (_selectedIndex != 2 || _navAnimationController.isAnimating)
            FadeTransition(
              key: const ValueKey('FadeMain'),
              opacity: _selectedIndex != 2
                  ? _fadeInAnimation
                  : _fadeOutAnimation,
              child: MainBottomNavBar(
                key: const ValueKey('MainNavBar'),
                selectedIndex: _selectedIndex,
                onTap: _onItemTapped,
                isActive: _selectedIndex != 2,
              ),
            ),

          // 모집 네비게이션 바
          // 모집 탭일 때 보여야 함 (또는 퇴장 중일 때)
          if (_selectedIndex == 2 || _navAnimationController.isAnimating)
            FadeTransition(
              key: const ValueKey('FadeGroup'),
              opacity: _selectedIndex == 2
                  ? _fadeInAnimation
                  : _fadeOutAnimation,
              child: GroupBottomNavBar(
                key: const ValueKey('GroupNavBar'),
                selectedIndex: _groupTabIndex,
                onTap: _onGroupTabTapped,
                isActive: _selectedIndex == 2,
                shouldAnimate: _navAnimationController.isAnimating,
              ),
            ),
        ],
      ),
    );
  }
}
