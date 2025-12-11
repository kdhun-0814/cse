import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'notice_list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF2F4F6),
        title: Row(
          children: [
            const Text('홈', style: TextStyle(color: Color(0xFF191F28), fontWeight: FontWeight.bold, fontSize: 26)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFFB0B8C1), size: 28), onPressed: () {}),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalendarCard(),
                const SizedBox(height: 24),
                _buildQuickMenuGrid(context),
                const SizedBox(height: 24),
                _buildNoticeFeed(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- 색상 헬퍼 함수 (전역적으로 통일) ---
  Color _getCategoryColor(String category) {
    switch (category) {
      case "긴급": return const Color(0xFFFF8A80); // 빨강
      case "학사": return const Color(0xFF82B1FF); // 파랑
      case "장학": return const Color(0xFFFFD180); // 노랑
      case "취업": return const Color(0xFFA5D6A7); // 초록
      case "행사": return const Color(0xFFCE93D8); // 보라
      case "광고": return const Color(0xFFB0BEC5); // 회색
      default: return const Color(0xFF3182F6);   // 기본 파랑
    }
  }

  // 캘린더 위젯 (투명도 수정 적용)
  Widget _buildCalendarCard() {
    final now = DateTime.now();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("11월", style: TextStyle(fontSize: 15, color: Color(0xFFFF4E4E), fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("${now.day}일 (${_getDayName(now.weekday)})", style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF191F28))),
                const SizedBox(height: 16),
                const Text("오늘 더 이상\n이벤트 없음", style: TextStyle(fontSize: 15, color: Color(0xFF8B95A1), height: 1.5)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: now,
              calendarFormat: CalendarFormat.month,
              headerVisible: false, 
              daysOfWeekHeight: 20, 
              rowHeight: 40,
              calendarStyle: CalendarStyle(
                // ★ 캘린더 색상 투명도 조절 (Opacity)
                todayDecoration: BoxDecoration(color: const Color(0xFFFF4E4E).withOpacity(0.8), shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: const Color(0xFF3182F6).withOpacity(0.6), shape: BoxShape.circle), // 투명한 파랑
                defaultTextStyle: const TextStyle(fontSize: 13),
                weekendTextStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                outsideDaysVisible: false,
                cellMargin: EdgeInsets.zero,
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekendStyle: TextStyle(fontSize: 11, color: Colors.grey),
                weekdayStyle: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDayName(int weekday) {
    const days = ['월', '화', '수', '목', '금', '토', '일'];
    return days[weekday - 1];
  }

  Widget _buildQuickMenuGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _menuItem(context, Icons.campaign_rounded, "긴급", _getCategoryColor("긴급"), badgeCount: 2)),
            const SizedBox(width: 12),
            Expanded(child: _menuItem(context, Icons.school_rounded, "학사", _getCategoryColor("학사"), badgeCount: 5)),
            const SizedBox(width: 12),
            Expanded(child: _menuItem(context, Icons.emoji_events_rounded, "장학", _getCategoryColor("장학"))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
             Expanded(child: _menuItem(context, Icons.work_rounded, "취업", _getCategoryColor("취업"), badgeCount: 12)),
             const SizedBox(width: 12),
             Expanded(child: _menuItem(context, Icons.celebration_rounded, "행사", _getCategoryColor("행사"))),
             const SizedBox(width: 12),
             Expanded(child: _menuItem(context, Icons.storefront_rounded, "광고", _getCategoryColor("광고"))),
          ],
        )
      ],
    );
  }

  Widget _menuItem(BuildContext context, IconData icon, String label, Color bgColor, {int badgeCount = 0}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoticeListScreen(title: label, themeColor: bgColor),
          ),
        );
      },
      child: Container(
        height: 130, 
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 2, blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64, height: 64, 
                  decoration: BoxDecoration(color: bgColor.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(icon, color: bgColor, size: 32),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: 0, top: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white, width: 2)),
                      child: Center(child: Text(badgeCount > 99 ? '99+' : badgeCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333D4B)), textAlign: TextAlign.center), 
          ],
        ),
      ),
    );
  }

  // 공지 피드 (색상 매칭 적용)
  Widget _buildNoticeFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("놓치면 안 되는 중요 공지", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF191F28))),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              // ★ 여기: 카테고리 이름을 정확히 전달하여 색상 매칭
              _noticeTile("학사", "2025학년도 1학기 수강신청 안내", "11.20 ~ 11.22", isUrgent: true),
              const Divider(height: 1, color: Color(0xFFF2F4F6), indent: 20, endIndent: 20),
              _noticeTile("장학", "국가장학금 1차 신청 기간", "D-3"),
              const Divider(height: 1, color: Color(0xFFF2F4F6), indent: 20, endIndent: 20),
              _noticeTile("행사", "신입생 환영회(OT) 참여 조사", "어제"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _noticeTile(String category, String title, String date, {bool isUrgent = false}) {
    // 위에서 만든 _getCategoryColor 함수 활용
    final Color color = _getCategoryColor(category);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), 
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15), // 배경 연하게
        radius: 24,
        child: Text(category[0], style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)), // 글씨 진하게
      ),
      title: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333D4B)), overflow: TextOverflow.ellipsis)),
          if (isUrgent) Container(margin: const EdgeInsets.only(left: 6), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFFF4E4E), borderRadius: BorderRadius.circular(4)), child: const Text("NEW", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))
        ],
      ),
      subtitle: Text(date, style: const TextStyle(fontSize: 13, color: Color(0xFF8B95A1))),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D6DB)),
    );
  }
}