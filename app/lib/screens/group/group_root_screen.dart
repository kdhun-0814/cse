import 'package:flutter/material.dart';
import '../../widgets/animated_bottom_nav_item.dart'; // Import 유지 (혹시 필요할 수 있으나 하단바 제거로 안쓸수도 있음, 일단 유지)
import 'group_list_screen.dart';
import 'group_create_screen.dart';

class GroupRootScreen extends StatefulWidget {
  // 부모(Main)에서 컨트롤러와 인덱스를 주입받음
  final PageController pageController;
  final Function(int) onTabChanged;

  const GroupRootScreen({
    super.key,
    required this.pageController,
    required this.onTabChanged,
  });

  @override
  State<GroupRootScreen> createState() => _GroupRootScreenState();
}

class _GroupRootScreenState extends State<GroupRootScreen> {
  // _selectedIndex는 AppBar 타이틀 표시용으로 내부에서도 필요할 수 있으나,
  // PageView의 onPageChanged를 통해 업데이트 받아야 함.
  // 부모가 rebuild할때 같이 업데이트 되겠지만, 내부 state로도 가지고 있거나 부모로부터 받아야함.
  // 여기서는 PageView의 onPageChanged가 호출될 때 setState로 내부 인덱스를 업데이트하여 타이틀을 변경.
  int _selectedIndex = 2; // 초기값 (모집 목록)
  bool _isScrolled = false;

  final List<String> _titles = [
    "", // 0: 홈으로 이동 (이 화면에선 0번 페이지가 홈이 되지만, 실제로는 Navigator pop 또는 Main Tab 전환)
    "모집 만들기", // 1
    "모집 목록", // 2
    "내 모집 관리", // 3
    "찜한 목록", // 4
  ];

  @override
  void initState() {
    super.initState();
    // 초기 인덱스 동기화 (필요하지 않을 수 있지만 안전하게)
    // widget.pageController.initialPage를 읽을 순 없으니 기본값 유지
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
      _isScrolled = false;
    });
    // 부모에게 알림 (하단 바 업데이트용)
    widget.onTabChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F6),

      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F4F6),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
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
          if (notification.metrics.axis == Axis.vertical) {
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
          controller: widget.pageController, // 주입받은 컨트롤러 사용
          onPageChanged: _onPageChanged,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Container(), // 0: 홈 (탭 전환용 더미)
            
            // 1: 모집 만들기
            GroupCreateScreen(
              onGroupCreated: () {
                // 부모 컨트롤러를 통해 이동
                widget.pageController.jumpToPage(3);
                _onPageChanged(3);
              },
            ),

            const GroupListScreen(filterType: 'all'), // 2: 모집 목록
            const GroupListScreen(filterType: 'my'), // 3: 모집 관리
            const GroupListScreen(filterType: 'liked'), // 4: 찜한 목록
          ],
        ),
      ),
      // bottomNavigationBar 제거 (부모에서 처리)
    );
  }
}
