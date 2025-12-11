import 'package:flutter/material.dart';
import 'group_list_screen.dart';
import 'group_create_screen.dart';

class GroupRootScreen extends StatefulWidget {
  final VoidCallback onGoHome;

  const GroupRootScreen({super.key, required this.onGoHome});

  @override
  State<GroupRootScreen> createState() => _GroupRootScreenState();
}

class _GroupRootScreenState extends State<GroupRootScreen> {
  late PageController _pageController;
  int _selectedIndex = 2; // 초기값: 모집 목록
  bool _isScrolled = false; // 스크롤 상태

  final List<String> _titles = [
    "", // 0
    "모집 만들기", // 1
    "모집 목록", // 2
    "모집 관리", // 3 (이동할 목표)
    "찜한 목록", // 4
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

  void _onItemTapped(int index) {
    if (index == 0) {
      widget.onGoHome();
    } else {
      // 탭 전환 시 스크롤 상태 초기화
      setState(() {
        _selectedIndex = index;
        _isScrolled = false;
      });
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _isScrolled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F6),
        elevation: 0,
        scrolledUnderElevation: 0, // 기본 색상 변화 방지
        surfaceTintColor: Colors.transparent, // 틴트 컬러 제거
        centerTitle: true,
        automaticallyImplyLeading: false,
        shape: _isScrolled
            ? const Border(
                bottom: BorderSide(color: Color(0xFFE5E8EB), width: 1),
              )
            : null,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Text(
            _titles[_selectedIndex],
            key: ValueKey<String>(_titles[_selectedIndex]),
            style: const TextStyle(
              color: Color(0xFF191F28),
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
          ),
        ),
      ),

      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          // 수직 스크롤이고, 뎁스가 0이 아닐 수 있음 (PageView 내부 ListView)
          // PageView 자체도 스크롤러이므로 axis Check 필수
          if (notification.metrics.axis == Axis.vertical) {
            // 빈번한 상태 변경 방지를 위해 threshold 적용 (10px)
            final isScrolled = notification.metrics.pixels > 10;
            if (_isScrolled != isScrolled) {
              setState(() {
                _isScrolled = isScrolled;
              });
            }
          }
          return false;
        },
        child: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Container(), // 0: 더미
            // ★ 핵심: 콜백 연결
            GroupCreateScreen(
              onGroupCreated: () {
                // 생성이 완료되면 '모집 관리(3번)' 탭으로 이동
                _onItemTapped(3);
              },
            ),

            const GroupListScreen(filterType: 'all'), // 2
            const GroupListScreen(filterType: 'my'), // 3
            const GroupListScreen(filterType: 'liked'), // 4
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border(
            top: BorderSide(color: Color(0xFFE5E8EB), width: 1),
            left: BorderSide(color: Color(0xFFE5E8EB), width: 1),
            right: BorderSide(color: Color(0xFFE5E8EB), width: 1),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: const Color(0xFF3182F6),
            unselectedItemColor: const Color(0xFFB0B8C1),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: '홈',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                label: '모집 만들기',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_rounded),
                label: '모집 목록',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.manage_accounts_rounded),
                label: '모집 관리',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline_rounded),
                label: '찜한 목록',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
