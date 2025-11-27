// lib/community_tab.dart
import 'package:flutter/material.dart';
import 'group_card.dart'; // 카드 UI
import 'group_create_screen.dart'; // 만들기 화면
import 'group_liked_screen.dart'; // 찜 화면
import 'main_screen.dart'; // 메인 화면으로 돌아가기 위해 필요

class CommunityTab extends StatefulWidget {
  const CommunityTab({super.key});

  @override
  State<CommunityTab> createState() => _CommunityTabState();
}

class _CommunityTabState extends State<CommunityTab> {
  int _localIndex = 2; // 기본 시작 화면: 2번 (모임 목록)

  // 하단 탭에 연결될 화면들
  final List<Widget> _subPages = [
    const SizedBox(), // 0번: 뒤로가기 (기능으로 처리)
    const GroupCreateScreen(), // 1번: 모임 만들기
    const _GroupListView(), // 2번: 모임 목록 (아래에 클래스 정의함)
    const Center(child: Text("내 모임 관리 화면 (준비중)")), // 3번: 내 모임
    const GroupLikedScreen(), // 4번: 찜한 목록
  ];

  void _onSubTabTapped(int index) {
    if (index == 0) {
      // 0번(뒤로가기)을 누르면 메인 앱의 홈으로 이동
      // MainScreen을 다시 로드하여 홈(0번 탭)으로 초기화
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } else {
      setState(() {
        _localIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold 안에 Scaffold가 들어가는 구조 (Nested Navigation)
    return Scaffold(
      body: _subPages[_localIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _localIndex,
          onTap: _onSubTabTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF3B82F6), // 선택된 색: 파랑
          unselectedItemColor: Colors.grey, // 선택 안 된 색: 회색
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.arrow_back_ios_new_rounded),
              label: '뒤로가기',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              label: '모임 만들기',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.format_list_bulleted_rounded),
              label: '모임 목록',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts_rounded),
              label: '모임 관리',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border_rounded),
              label: '찜한 목록',
            ),
          ],
        ),
      ),
    );
  }
}

// 모임 목록 화면 (CommunityTab 안에서만 쓰이므로 여기에 둠)
class _GroupListView extends StatelessWidget {
  const _GroupListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: true,
        title: const Text('모임 목록', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          TextField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: '관심 있는 스터디, 모임을 검색해보세요',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 24),
          const GroupCard(
            title: '알고리즘 코딩테스트 스터디 구합니다',
            tags: ['#스터디', '#코딩', '#알고리즘', '#Java'],
            currentMember: 6,
            deadline: 'D-4',
            isRecruiting: true,
            isLiked: false,
          ),
          const GroupCard(
            title: '같이 밥 먹을 사람~ (오늘 점심)',
            tags: ['#친목', '#점심'],
            currentMember: 4,
            deadline: '마감됨',
            isRecruiting: false,
            isLiked: true,
          ),
        ],
      ),
    );
  }
}